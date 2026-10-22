(function (window, document) {
    'use strict';

    var VERSION = '20260912-6';
    var cpuTemperature = '';
    var cpuPercent = '';
    var memoryPercent = '';
    var temperatureModes = Object.create(null);
    var temperatureStates = Object.create(null);
    var installed = false;
    var installAttempts = 0;
    var runtimeUrl = findRuntimeUrl();
    var runtimeRequest = null;
    var runtimeRequestSequence = 0;
    var runtimeAppliedSequence = 0;
    var runtimeRevision = 0;
    var runtimeUpdatedAt = 0;
    var storageKey = 'nradio.home-temperature.modes.v1';

    function restoreTemperatureModes() {
        var saved;
        var name;
        try {
            saved = JSON.parse(window.localStorage.getItem(storageKey) || '{}');
            if (!saved || typeof saved !== 'object') {
                return;
            }
            for (name in saved) {
                if (Object.prototype.hasOwnProperty.call(saved, name) &&
                    (saved[name] === 'cpu' || saved[name] === 'cpe')) {
                    temperatureModes[name] = saved[name];
                }
            }
        } catch (error) {
            // Storage may be unavailable; the current page still keeps its choice.
        }
    }

    function saveTemperatureModes() {
        try {
            window.localStorage.setItem(storageKey, JSON.stringify(temperatureModes));
        } catch (error) {
            // Switching does not depend on browser storage being writable.
        }
    }

    function findRuntimeUrl() {
        var script = document.currentScript;
        var scripts;
        var index;
        var source;
        var url;
        if (script) {
            url = script.getAttribute('data-runtime-url');
            if (url) {
                return String(url);
            }
        }
        scripts = document.getElementsByTagName('script');
        for (index = scripts.length - 1; index >= 0; index -= 1) {
            source = String(scripts[index].getAttribute('src') || '');
            if (source.indexOf('/nradio-home-temperature-switch.js') !== -1) {
                url = scripts[index].getAttribute('data-runtime-url');
                return url ? String(url) : '';
            }
        }
        return '';
    }

    function refreshRuntimeNow() {
        var request;
        var sequence;
        var revision;
        var separator;
        var requestUrl;

        if (!runtimeUrl || typeof window.XMLHttpRequest !== 'function') {
            return;
        }
        if (runtimeRequest && runtimeRequest.readyState !== 4) {
            return;
        }

        sequence = runtimeRequestSequence + 1;
        runtimeRequestSequence = sequence;
        revision = runtimeRevision;
        separator = runtimeUrl.indexOf('?') === -1 ? '?' : '&';
        requestUrl = runtimeUrl + separator + '_nrht=' +
            String(new Date().getTime()) + '-' + String(sequence);
        request = new window.XMLHttpRequest();
        runtimeRequest = request;
        request.onreadystatechange = function () {
            var data;
            if (request.readyState !== 4) {
                return;
            }
            if (runtimeRequest === request) {
                runtimeRequest = null;
            }
            if (request.status < 200 || request.status >= 300 ||
                sequence < runtimeAppliedSequence || revision !== runtimeRevision) {
                return;
            }
            try {
                data = JSON.parse(request.responseText || '{}');
            } catch (error) {
                return;
            }
            if (!data || !data.result) {
                return;
            }
            runtimeAppliedSequence = sequence;
            if (typeof window.stats_info === 'function') {
                window.stats_info(data);
            }
        };
        request.onerror = request.ontimeout = request.onabort = function () {
            if (runtimeRequest === request) {
                runtimeRequest = null;
            }
        };
        try {
            request.open('GET', requestUrl, true);
            request.timeout = 8000;
            request.send(null);
        } catch (error) {
            if (runtimeRequest === request) {
                runtimeRequest = null;
            }
        }
    }

    function installSpeedRefresh() {
        var originalSpeedShow = window.speed_show;
        var samples = Object.create(null);
        var jquery = window.jQuery;
        var staleAfter = 4000;

        if (window.low_cpu || typeof originalSpeedShow !== 'function' ||
            typeof window.get_speed_data !== 'function' || typeof jquery !== 'function' ||
            typeof window.nradio_rate_format !== 'function') {
            return;
        }

        function sampleTime() {
            return window.performance && typeof window.performance.now === 'function' ?
                window.performance.now() : new Date().getTime();
        }

        function renderSpeed(wanItem, sample) {
            var prefix = '.box_wans_' + wanItem.name;
            var up = window.nradio_rate_format(sample.upRate).split(' ');
            var down = window.nradio_rate_format(sample.downRate).split(' ');
            jquery(prefix + ' .speedup_data').text(up[0]);
            jquery(prefix + ' .speedup_unit').text(up[1] || 'bps');
            jquery(prefix + ' .speeddown_data').text(down[0]);
            jquery(prefix + ' .speeddown_unit').text(down[1] || 'bps');
            wanItem.ulbytes = sample.upload;
            wanItem.dlbytes = sample.download;
        }

        // The OEM ready handler uses this interval to start its existing timer.
        window.speed_interval = 1;
        window.speed_show = function (wanItem, uploadBytes, downloadBytes, interval) {
            var now = sampleTime();
            var upload = Number(uploadBytes);
            var download = Number(downloadBytes);
            var sample;
            var elapsed;
            if (!wanItem) {
                return originalSpeedShow.apply(this, arguments);
            }
            if (uploadBytes == null || downloadBytes == null ||
                !isFinite(upload) || !isFinite(download) || upload < 0 || download < 0) {
                return;
            }
            sample = samples[wanItem.name];
            if (!sample || upload < sample.upload || download < sample.download || now < sample.at) {
                sample = { upload: upload, download: download, at: now, upRate: 0, downRate: 0 };
                samples[wanItem.name] = sample;
            } else if (upload !== sample.upload || download !== sample.download) {
                elapsed = (now - sample.at) / 1000;
                if (elapsed <= 0) {
                    return;
                }
                sample.upRate = (upload - sample.upload) * 8 / elapsed;
                sample.downRate = (download - sample.download) * 8 / elapsed;
                sample.upload = upload;
                sample.download = download;
                sample.at = now;
            } else if (now - sample.at >= staleAfter) {
                sample.upRate = 0;
                sample.downRate = 0;
            }
            // infocd returns the same cached counters between its 2-second
            // samples. Keep the last measured rate and its original baseline.
            sample.seen = now;
            renderSpeed(wanItem, sample);
        };

        window.reset_box_speed = function (wans) {
            var now = sampleTime();
            var index;
            var item;
            var sample;
            for (index = 0; index < wans.length; index += 1) {
                item = wans[index];
                sample = samples[item.name];
                if (item.disabled === '1') {
                    delete samples[item.name];
                    originalSpeedShow.call(window, item, 0, 0, 1);
                } else if (sample) {
                    if (now - sample.seen >= staleAfter) {
                        sample.upRate = 0;
                        sample.downRate = 0;
                    }
                    // Runtime/layout refreshes must not clear active rates.
                    renderSpeed(item, sample);
                } else {
                    originalSpeedShow.call(window, item, 0, 0, 1);
                }
            }
        };

        function sampleNow() {
            window.get_speed_data();
        }
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', function () {
                window.setTimeout(sampleNow, 0);
            }, false);
        } else {
            window.setTimeout(sampleNow, 0);
            window.setTimeout(sampleNow, 1000);
        }
    }

    function validTemperature(value) {
        var number;
        if (value === null || value === undefined || value === '') {
            return '';
        }
        number = Number(value);
        if (!isFinite(number) || number <= 0 || number > 300) {
            return '';
        }
        return Math.round(number);
    }

    function validPercent(value) {
        var number;
        if (value === null || value === undefined || value === '') {
            return '';
        }
        number = Number(value);
        if (!isFinite(number) || number < 0 || number > 100) {
            return '';
        }
        return Math.round(number);
    }

    function rememberCpe(status) {
        var name;
        if (!status || typeof status !== 'object') {
            return;
        }
        name = String(status.name || '');
        if (!name) {
            return;
        }
        temperatureStates[name] = {
            modelTemperature: validTemperature(
                status.model_temp !== undefined ? status.model_temp : status.temperature
            ),
            nrcap: String(status.nrcap === undefined ? '' : status.nrcap),
            disabled: String(status.disabled === undefined ? '' : status.disabled)
        };
    }

    function captureRuntime(data) {
        var result;
        var globalInfo;
        var cpes;
        var index;
        var fallbackCpu;

        if (!data || !data.result) {
            return;
        }
        runtimeRevision += 1;
        runtimeUpdatedAt = new Date().getTime();
        result = data.result;
        globalInfo = result.global || {};
        cpuPercent = validPercent(globalInfo.cpu_percent);
        memoryPercent = validPercent(globalInfo.mem_percent);
        cpuTemperature = validTemperature(globalInfo.device_temp);
        if (cpuTemperature === '') {
            fallbackCpu = validTemperature(globalInfo.cpu_temp);
            cpuTemperature = fallbackCpu;
        }

        cpes = result.cpe;
        if (!cpes || typeof cpes !== 'object') {
            return;
        }
        // Each CPE list is a snapshot. Retain source preferences separately,
        // but discard runtime entries for lines absent from this response.
        temperatureStates = Object.create(null);
        if (typeof cpes.length === 'number') {
            for (index = 0; index < cpes.length; index += 1) {
                rememberCpe(cpes[index]);
            }
            return;
        }
        for (index in cpes) {
            if (Object.prototype.hasOwnProperty.call(cpes, index)) {
                rememberCpe(cpes[index]);
            }
        }
    }

    function temperatureAvailable(value) {
        return value !== '' && value !== null && value !== undefined;
    }

    function isSecondary5G(name) {
        return String(name || '') === 'cpe1';
    }

    function secondary5GIsOnlyEnabledLine(name) {
        var stateName;
        var state;
        var foundSecondary = false;
        if (!isSecondary5G(name)) {
            return false;
        }
        for (stateName in temperatureStates) {
            if (!Object.prototype.hasOwnProperty.call(temperatureStates, stateName)) {
                continue;
            }
            state = temperatureStates[stateName] || {};
            if (state.disabled === '1') {
                continue;
            }
            if (stateName !== name) {
                return false;
            }
            foundSecondary = true;
        }
        return foundSecondary;
    }

    function secondary5GIsFixed(name) {
        return isSecondary5G(name) && !secondary5GIsOnlyEnabledLine(name);
    }

    function effectiveMode(name) {
        var state = temperatureStates[name] || {};
        var requested = temperatureModes[name];
        if (secondary5GIsFixed(name)) {
            return 'cpe';
        }
        if (isSecondary5G(name) && requested !== 'cpu' && requested !== 'cpe' &&
            temperatureAvailable(state.modelTemperature)) {
            return 'cpe';
        }
        if (requested === 'cpu' && temperatureAvailable(cpuTemperature)) {
            return 'cpu';
        }
        if (requested === 'cpe' && temperatureAvailable(state.modelTemperature)) {
            return 'cpe';
        }
        if (temperatureAvailable(cpuTemperature)) {
            return 'cpu';
        }
        if (temperatureAvailable(state.modelTemperature)) {
            return 'cpe';
        }
        return requested === 'cpe' ? 'cpe' : 'cpu';
    }

    function synchronizeLegacyTemperatureModes() {
        var legacyModes = window.nr_temp_modes;
        var name;
        if (!legacyModes || typeof legacyModes !== 'object') {
            return;
        }
        for (name in temperatureStates) {
            if (Object.prototype.hasOwnProperty.call(temperatureStates, name)) {
                legacyModes[name] = effectiveMode(name);
            }
        }
    }

    function cpeTemperatureLabel(state) {
        return state && (state.nrcap === '0' || state.nrcap === '') ? '4G温度' : '5G温度';
    }

    function updateTemperatureButton(button, name, mode, label, active, disabled) {
        button.type = 'button';
        button.className = 'nr-home-temp-choice' + (active && !disabled ? ' active' : '');
        button.setAttribute('data-name', name);
        button.setAttribute('data-mode', mode);
        button.setAttribute('aria-pressed', active && !disabled ? 'true' : 'false');
        button.setAttribute('aria-disabled', disabled ? 'true' : 'false');
        button.title = label + (disabled ? '：暂无数据' : '');
        button.setAttribute('aria-label', button.title);
        button.disabled = disabled;
        if (button.getAttribute('data-temperature-label') !== label) {
            button.textContent = mode === 'cpu' ? 'CPU' : label.slice(0, 2);
            button.setAttribute('data-temperature-label', label);
        }
    }

    function markTemperatureCard(node) {
        var card = node.parentNode;
        var classes;
        var group;
        while (card && card !== document) {
            classes = ' ' + (card.className || '') + ' ';
            if (classes.indexOf(' pc_box ') !== -1 && classes.indexOf(' pc_box1 ') !== -1) {
                card.setAttribute('data-nradio-home-temp-card', '1');
                group = card.parentNode;
                if (group && (' ' + (group.className || '') + ' ').indexOf(' speedflow_combine_box ') !== -1) {
                    group.setAttribute('data-nradio-home-temp-grid', '1');
                }
                return;
            }
            card = card.parentNode;
        }
    }

    function renderTemperatureLabel(node, name, mode, state) {
        var switcher = node.nradioTemperatureSwitcher;
        var buttons;
        var index = 0;
        var cpuDisabled = !temperatureAvailable(cpuTemperature);
        var cpeDisabled = !temperatureAvailable(state.modelTemperature);
        var secondaryFixed = secondary5GIsFixed(name);
        markTemperatureCard(node);
        if (!switcher) {
            switcher = document.createElement('span');
            switcher.className = 'nr-home-temp-switch';
            switcher.setAttribute('data-temperature-name', name);
            switcher.setAttribute('role', 'group');
            switcher.setAttribute('aria-label', '温度来源');
            node.nradioTemperatureSwitcher = switcher;
        }
        buttons = switcher.querySelectorAll('button');
        if (buttons.length !== (secondaryFixed ? 1 : 2)) {
            while (switcher.firstChild) {
                switcher.removeChild(switcher.firstChild);
            }
            if (!secondaryFixed) {
                switcher.appendChild(document.createElement('button'));
            }
            switcher.appendChild(document.createElement('button'));
            buttons = switcher.querySelectorAll('button');
        }
        if (!secondaryFixed) {
            updateTemperatureButton(buttons[index], name, 'cpu', 'CPU温度',
                mode === 'cpu', cpuDisabled);
            index += 1;
        }
        updateTemperatureButton(buttons[index], name, 'cpe',
            secondaryFixed ? '5G温度' : cpeTemperatureLabel(state),
            mode === 'cpe', cpeDisabled);
        if (node.firstChild !== switcher) {
            while (node.firstChild) {
                node.removeChild(node.firstChild);
            }
            node.appendChild(switcher);
        }
    }

    function formattedTemperature(value) {
        if (typeof window.format_temp_val === 'function') {
            return window.format_temp_val(value);
        }
        return temperatureAvailable(value) ? String(value) + '℃' : '-';
    }

    function formattedTemperatureDescription(value) {
        if (!temperatureAvailable(value)) {
            return '暂无温度数据';
        }
        if (typeof window.format_temp_des === 'function') {
            return window.format_temp_des(value);
        }
        return '';
    }

    function renderUsageValue(root, selector, value) {
        var nodes = root.querySelectorAll(selector);
        var text = value === '' ? '-' : String(value) + '%';
        var index;
        for (index = 0; index < nodes.length; index += 1) {
            nodes[index].textContent = text;
        }
    }

    function renderUsageDescription(root, selector, value, formatter) {
        var nodes = root.querySelectorAll(selector);
        var text = value === '' || typeof formatter !== 'function' ? '' : formatter(value);
        var index;
        for (index = 0; index < nodes.length; index += 1) {
            nodes[index].textContent = text;
        }
    }

    function renderPrimaryLineUsage() {
        var primaryBoxes = document.getElementsByClassName('box_wans_cpe');
        var index;

        for (index = 0; index < primaryBoxes.length; index += 1) {
            renderUsageValue(primaryBoxes[index], '.cpu_data', cpuPercent);
            renderUsageValue(primaryBoxes[index], '.mem_data', memoryPercent);
            renderUsageDescription(primaryBoxes[index], '.cpu_des', cpuPercent, window.format_cpu_val);
            renderUsageDescription(primaryBoxes[index], '.mem_des', memoryPercent, window.format_mem_val);
        }
    }

    function renderTemperatureGauge(gauge, id, value) {
        // The OEM gauge drops updates during animation. Settle its previous
        // value before updating, then draw the selected source synchronously.
        if (gauge && typeof gauge.drawProgressAnimate === 'function') {
            gauge.animation = false;
            gauge.percentage = gauge.progress;
            gauge.isEnd = true;
        }
        gauge = window.canvas_val_show(
            gauge, id, value, 125, window.temp_range, window.temp_lang, '℃'
        );
        if (gauge && typeof gauge.drawProgressAnimate === 'function') {
            gauge.animation = false;
            gauge.drawProgressAnimate();
        }
        return gauge;
    }

    function renderVisibleTemperatureGauge(gauge, id, value, mode) {
        var node = document.getElementById(id);
        var cached;
        var canvas;
        if (!node) {
            return gauge;
        }
        cached = node.nradioTemperatureGaugeState;
        if (document.hidden || !node.getClientRects().length) {
            if (cached) {
                cached.visible = false;
            }
            return gauge;
        }
        canvas = node.querySelector('canvas');
        // A recreated card must own its gauge, even if the WAN item still
        // references the canvas from the removed card.
        if (!canvas || (gauge && gauge.ctx && gauge.ctx.canvas !== canvas)) {
            gauge = null;
        }
        if (cached && cached.visible && cached.gauge === gauge &&
            cached.canvas === canvas && cached.value === value && cached.mode === mode &&
            cached.width === node.offsetWidth && cached.height === node.offsetHeight) {
            return gauge;
        }
        gauge = renderTemperatureGauge(gauge, id, value);
        node.nradioTemperatureGaugeState = {
            gauge: gauge,
            canvas: node.querySelector('canvas'),
            value: value,
            mode: mode,
            width: node.offsetWidth,
            height: node.offsetHeight,
            visible: true
        };
        return gauge;
    }

    function updateTemperatureGauge(name, value, mode) {
        var wanItem;
        var singleId = 'tempprogress-container-' + name + 'single';
        var multiId = 'tempprogress-container-' + name + 'multi';

        if (typeof window.get_wans_item !== 'function' ||
            typeof window.canvas_val_show !== 'function' ||
            !window.wans_data) {
            return;
        }
        wanItem = window.get_wans_item(name, window.wans_data);
        if (!wanItem) {
            return;
        }
        wanItem.arcProgressTempSingle = renderVisibleTemperatureGauge(
            wanItem.arcProgressTempSingle, singleId, value, mode
        );
        wanItem.arcProgressTempMulti = renderVisibleTemperatureGauge(
            wanItem.arcProgressTempMulti, multiId, value, mode
        );
    }

    function renderTemperature(name) {
        var state = temperatureStates[name] || {modelTemperature: '', nrcap: '', disabled: ''};
        var mode = effectiveMode(name);
        var value = mode === 'cpu' ? cpuTemperature : state.modelTemperature;
        var boxes = document.getElementsByClassName('box_wans_' + name);
        var boxIndex;
        var nodeIndex;
        var labels;
        var values;
        var descriptions;

        for (boxIndex = 0; boxIndex < boxes.length; boxIndex += 1) {
            labels = boxes[boxIndex].querySelectorAll('.rtemp_label');
            for (nodeIndex = 0; nodeIndex < labels.length; nodeIndex += 1) {
                renderTemperatureLabel(labels[nodeIndex], name, mode, state);
            }
            values = boxes[boxIndex].querySelectorAll('.model_temp');
            for (nodeIndex = 0; nodeIndex < values.length; nodeIndex += 1) {
                values[nodeIndex].textContent = formattedTemperature(value);
            }
            descriptions = boxes[boxIndex].querySelectorAll('.temp_des');
            for (nodeIndex = 0; nodeIndex < descriptions.length; nodeIndex += 1) {
                descriptions[nodeIndex].textContent = formattedTemperatureDescription(value);
            }
        }
        updateTemperatureGauge(name, value, mode);
    }

    function renderAllTemperatures() {
        var name;
        var count = 0;
        for (name in temperatureStates) {
            if (Object.prototype.hasOwnProperty.call(temperatureStates, name)) {
                renderTemperature(name);
                count += 1;
            }
        }
        if (document.documentElement) {
            document.documentElement.setAttribute('data-nradio-home-temperature-switch', VERSION);
            document.documentElement.setAttribute('data-nradio-home-temperature-count', String(count));
        }
    }

    function installStyle() {
        var style;
        if (document.getElementById('nr-home-temperature-switch-style')) {
            return;
        }
        style = document.createElement('style');
        style.id = 'nr-home-temperature-switch-style';
        style.textContent =
            'body [data-nradio-home-temp-card]>.panel-heading{padding:8px 8px 0}' +
            '[data-nradio-home-temp-card]>.panel-heading>.row{margin:0}' +
            '[data-nradio-home-temp-card]>.panel-heading>.row>div{display:flex;flex-direction:column;align-items:center;gap:4px;width:100%;padding:0}' +
            '[data-nradio-home-temp-card] .pre_info{font-size:12px;line-height:18px;min-height:18px}' +
            '[data-nradio-home-temp-card] .pre_info:empty{display:none}' +
            '[data-nradio-home-temp-card] .rtemp_label{display:block;width:100%;max-width:100%;text-align:center;line-height:0}' +
            '[data-nradio-home-temp-card] .model_temp{font-variant-numeric:tabular-nums}' +
            '.nr-home-temp-switch{display:inline-grid;grid-auto-flow:column;grid-auto-columns:minmax(0,1fr);align-items:stretch;gap:8px;width:96px;max-width:100%;box-sizing:border-box;padding:0;border:0;border-radius:0;background:transparent;vertical-align:top}' +
            '.nr-home-temp-switch>.nr-home-temp-choice{display:grid;grid-template-rows:20px;align-content:center;justify-items:center;min-width:0;box-sizing:border-box;appearance:none;-webkit-appearance:none;border:0;border-bottom:2px solid transparent;border-radius:0;background:transparent;color:#99aab4;cursor:pointer;font-family:inherit;font-size:12px;font-weight:500;line-height:20px;height:28px;min-height:28px;margin:0;padding:3px 6px;outline:none;box-shadow:none;white-space:nowrap;touch-action:manipulation;transition:border-color .15s,color .15s}' +
            '.nr-home-temp-switch>.nr-home-temp-choice.active{border-bottom-color:#71c3cc;color:#c6eff2}' +
            '.nr-home-temp-switch>.nr-home-temp-choice:hover:not(:disabled){color:#d3f4f6}' +
            '.nr-home-temp-switch>.nr-home-temp-choice:focus{outline:none;box-shadow:none}' +
            '.nr-home-temp-switch>.nr-home-temp-choice:focus-visible{box-shadow:inset 0 0 0 2px #78cdd5}' +
            '.nr-home-temp-choice:disabled{cursor:not-allowed;opacity:.45}' +
            '@media(max-width:767px){' +
            'body [data-nradio-home-temp-grid]{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:12px;float:none;width:100%;height:auto;min-height:0;margin:0 0 20px}' +
            'body [data-nradio-home-temp-grid]>.pc_box{float:none;width:auto;min-width:0;height:auto;min-height:159px;margin:0;box-sizing:border-box}' +
            '[data-nradio-home-temp-card]>.panel-body{padding:0 8px 8px}' +
            '[data-nradio-home-temp-card] [id^="tempprogress-container-"]{width:100%;max-width:130px;margin:0 auto!important}' +
            '[data-nradio-home-temp-card] canvas{display:block;max-width:100%;height:auto!important;margin:0 auto}' +
            '.nr-home-temp-switch{width:112px}' +
            '.nr-home-temp-switch>.nr-home-temp-choice{height:44px;min-height:44px;padding:4px 2px}' +
            '}';
        (document.head || document.documentElement).appendChild(style);
    }

    function findTemperatureButton(target) {
        while (target && target !== document) {
            if (target.nodeType === 1 &&
                (' ' + target.className + ' ').indexOf(' nr-home-temp-choice ') !== -1) {
                return target;
            }
            target = target.parentNode;
        }
        return null;
    }

    function handleTemperatureClick(event) {
        var button = findTemperatureButton(event.target);
        var name;
        var mode;
        if (!button || button.disabled) {
            return;
        }
        name = String(button.getAttribute('data-name') || '');
        mode = String(button.getAttribute('data-mode') || '');
        if (!name || (mode !== 'cpu' && mode !== 'cpe')) {
            return;
        }
        event.preventDefault();
        event.stopPropagation();
        if (temperatureModes[name] === mode) {
            return;
        }
        temperatureModes[name] = mode;
        saveTemperatureModes();
        if (window.nr_temp_modes && typeof window.nr_temp_modes === 'object') {
            window.nr_temp_modes[name] = effectiveMode(name);
        }
        renderTemperature(name);
        if (new Date().getTime() - runtimeUpdatedAt >= 5000) {
            refreshRuntimeNow();
        }
    }

    function installTemperatureSwitch() {
        var originalStatsInfo;
        var wrappedStatsInfo;

        if (installed) {
            return;
        }
        originalStatsInfo = window.stats_info;
        if (typeof originalStatsInfo !== 'function') {
            installAttempts += 1;
            if (installAttempts <= 40) {
                window.setTimeout(installTemperatureSwitch, 50);
            } else if (document.documentElement) {
                document.documentElement.setAttribute('data-nradio-home-temperature-switch', 'unsupported');
            }
            return;
        }

        restoreTemperatureModes();
        wrappedStatsInfo = function (data) {
            var focused = findTemperatureButton(document.activeElement);
            var result;
            var originalCanvasValShow = window.canvas_val_show;
            captureRuntime(data);
            synchronizeLegacyTemperatureModes();
            // Defer only managed temperature gauges during the OEM refresh.
            // Paint once below, after it has finished changing card visibility.
            if (typeof originalCanvasValShow === 'function') {
                window.canvas_val_show = function (gauge, id) {
                    var match = /^tempprogress-container-(.+)(single|multi)$/.exec(String(id));
                    if (match && Object.prototype.hasOwnProperty.call(temperatureStates, match[1])) {
                        return gauge;
                    }
                    return originalCanvasValShow.apply(this, arguments);
                };
            }
            try {
                result = originalStatsInfo.apply(this, arguments);
            } finally {
                window.canvas_val_show = originalCanvasValShow;
            }
            renderPrimaryLineUsage();
            renderAllTemperatures();
            if (focused && document.documentElement.contains(focused) &&
                document.activeElement !== focused &&
                (!document.activeElement || document.activeElement === document.body)) {
                focused.focus();
            }
            return result;
        };
        wrappedStatsInfo.nradioHomeTemperatureSwitch = VERSION;
        window.stats_info = wrappedStatsInfo;
        document.addEventListener('click', handleTemperatureClick, true);
        window.addEventListener('resize', renderAllTemperatures, false);
        document.addEventListener('visibilitychange', renderAllTemperatures, false);
        installStyle();
        installSpeedRefresh();
        installed = true;
        window.NRadioHomeTemperatureSwitch = {
            version: VERSION,
            render: renderAllTemperatures,
            refresh: refreshRuntimeNow
        };
        if (document.documentElement) {
            document.documentElement.setAttribute('data-nradio-home-temperature-switch', VERSION);
        }
        window.setTimeout(refreshRuntimeNow, 0);
    }

    installTemperatureSwitch();
}(window, document));
