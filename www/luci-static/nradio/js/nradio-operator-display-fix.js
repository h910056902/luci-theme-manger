(function (window) {
    'use strict';

    var VERSION = '20260828-1';
    var INVALID_OPERATOR = /^(?:none|unknown|null|undefined|n\/a|na|-)$/i;
    var INVALID_SIM_NAME = /^(?:none|unknown|null|undefined|n\/a|na|-|nradio)$/i;
    var lastGood = {};
    var lastGoodSimName = {};

    function normalize(value) {
        var text = value === null || typeof value === 'undefined' ? '' : String(value);
        text = text.replace(/^\s+|\s+$/g, '');
        return !text || INVALID_OPERATOR.test(text) ? '' : text;
    }

    function companyFromPlmn(value) {
        var text = normalize(value);
        var plmn;
        var alias;

        if (!text) {
            return '';
        }

        if (/^\d{5,15}$/.test(text)) {
            plmn = text.substr(0, 5);
            switch (plmn) {
                case '46000':
                case '46002':
                case '46004':
                case '46007':
                case '46008':
                    return 'China Mobile';
                case '46001':
                case '46006':
                case '46009':
                    return 'China Unicom';
                case '46003':
                case '46005':
                case '46011':
                case '46012':
                    return 'China Telecom';
                case '46015':
                    return 'China Broadnet';
            }
        }

        alias = text.toUpperCase().replace(/[\s_-]+/g, '');
        if (alias === 'CHNUNICOM' || alias === 'UNICOM') {
            return 'China Unicom';
        }
        if (alias === 'CHNCT' || alias === 'CHNTELECOM' || alias === 'CTCC') {
            return 'China Telecom';
        }
        if (alias === 'CMCC' || alias === 'CHNMOBILE') {
            return 'China Mobile';
        }
        if (alias === 'CHNBROADNET' || alias === 'CBN') {
            return 'China Broadnet';
        }
        return text;
    }

    function storageKey(name) {
        return 'nradio.operator.' + String(name || 'default').replace(/[^A-Za-z0-9_.-]/g, '_');
    }

    function normalizeIccid(value) {
        var iccid = value === null || typeof value === 'undefined' ? '' : String(value);
        iccid = iccid.replace(/\D/g, '');
        return iccid.length >= 18 ? iccid : '';
    }

    function normalizeSimName(value) {
        var text = value === null || typeof value === 'undefined' ? '' : String(value);
        text = text.replace(/^\s+|\s+$/g, '');
        return !text || INVALID_SIM_NAME.test(text) ? '' : text;
    }

    function configuredSimName(iccid) {
        var map = window.NRadioSimNameMap;
        if (!iccid || !map || typeof map !== 'object') {
            return '';
        }
        return normalizeSimName(map[iccid]);
    }

    function simNameStorageKey(name, iccid) {
        var identity = iccid || name || 'default';
        var revision = String(window.NRadioSimNameMapRevision || 'empty');
        return 'nradio.sim-name.' + revision.replace(/[^A-Za-z0-9_.-]/g, '_') + '.' +
            String(identity).replace(/[^A-Za-z0-9_.-]/g, '_');
    }

    function rememberSimName(name, iccid, simName) {
        var key;
        if (!simName) {
            return;
        }
        key = simNameStorageKey(name, iccid);
        lastGoodSimName[key] = simName;
        if (!iccid) {
            return;
        }
        try {
            window.localStorage.setItem(key, simName);
        } catch (ignore) {
        }
    }

    function restoreSimName(name, iccid) {
        var key = simNameStorageKey(name, iccid);
        var simName = lastGoodSimName[key] || '';
        if (simName) {
            return simName;
        }
        if (!iccid) {
            return '';
        }
        try {
            simName = normalizeSimName(window.localStorage.getItem(key));
        } catch (ignore) {
            simName = '';
        }
        if (simName) {
            lastGoodSimName[key] = simName;
        }
        return simName;
    }

    function remember(name, operator) {
        if (!operator) {
            return;
        }
        lastGood[name] = operator;
        try {
            window.sessionStorage.setItem(storageKey(name), operator);
        } catch (ignore) {
        }
    }

    function restore(name) {
        var operator = lastGood[name] || '';
        if (operator) {
            return operator;
        }
        try {
            operator = companyFromPlmn(window.sessionStorage.getItem(storageKey(name)));
        } catch (ignore) {
            operator = '';
        }
        if (operator) {
            lastGood[name] = operator;
        }
        return operator;
    }

    function sanitizeCpeStatus(status) {
        var name;
        var operator;
        var simOperator;
        var networkOperator;
        var iccid;
        var simName;
        var nativeSimName;
        var mappedSimName;

        if (!status || typeof status !== 'object') {
            return;
        }
        name = normalize(status.name) || 'default';
        iccid = normalizeIccid(status.iccid);
        simOperator = companyFromPlmn(status.sim_company) || companyFromPlmn(status.sim_isp);
        networkOperator = companyFromPlmn(status.isp_company) || companyFromPlmn(status.isp);
        operator = simOperator || networkOperator;
        if (operator) {
            remember(name, operator);
        } else {
            operator = restore(name);
        }
        status.sim_company = simOperator || operator || '';
        status.isp_company = networkOperator || operator || '';
        status.sim_isp = status.sim_company;
        status.isp = status.isp_company;

        nativeSimName = normalizeSimName(status.sim_name);
        mappedSimName = configuredSimName(iccid);
        simName = mappedSimName || nativeSimName;
        if (simName) {
            rememberSimName(name, iccid, simName);
        } else {
            simName = restoreSimName(name, iccid);
        }
        status.sim_name = simName || '';
        status.nradio_sim_name_source = mappedSimName ? 'map' :
            (nativeSimName ? 'firmware' : (simName ? 'cache' : ''));
    }

    if (typeof window.format_isp_info === 'function' && !window.format_isp_info.nradioOperatorFix) {
        (function () {
            var originalFormatIsp = window.format_isp_info;
            var fixedFormatIsp = function (simIsp, isp) {
                var primary;
                var fallback;
                var fixedInfo;
                var key;

                if (simIsp && typeof simIsp === 'object') {
                    fixedInfo = {};
                    for (key in simIsp) {
                        if (Object.prototype.hasOwnProperty.call(simIsp, key)) {
                            fixedInfo[key] = simIsp[key];
                        }
                    }
                    primary = companyFromPlmn(simIsp.sim_company) || companyFromPlmn(simIsp.sim_isp);
                    fallback = companyFromPlmn(simIsp.isp_company) || companyFromPlmn(simIsp.isp);
                    fixedInfo.sim_company = primary || fallback || '';
                    fixedInfo.isp_company = fallback || primary || '';
                    if (!normalize(fixedInfo.sim_company_lng)) {
                        fixedInfo.sim_company_lng = fixedInfo.sim_company;
                    }
                    if (!normalize(fixedInfo.isp_company_lng)) {
                        fixedInfo.isp_company_lng = fixedInfo.isp_company;
                    }
                    return originalFormatIsp.call(this, fixedInfo);
                }

                primary = companyFromPlmn(simIsp);
                fallback = companyFromPlmn(isp);
                return originalFormatIsp.call(this, primary || '', fallback || '');
            };
            fixedFormatIsp.nradioOperatorFix = VERSION;
            window.format_isp_info = fixedFormatIsp;
        }());
    }

    if (typeof window.cpe_show === 'function' && !window.cpe_show.nradioOperatorFix) {
        (function () {
            var originalCpeShow = window.cpe_show;
            var fixedCpeShow = function (cpe) {
                var i;
                if (cpe && typeof cpe.length === 'number') {
                    for (i = 0; i < cpe.length; i += 1) {
                        sanitizeCpeStatus(cpe[i]);
                    }
                }
                return originalCpeShow.apply(this, arguments);
            };
            fixedCpeShow.nradioOperatorFix = VERSION;
            window.cpe_show = fixedCpeShow;
        }());
    }

    if (window.document && window.document.documentElement) {
        window.document.documentElement.setAttribute('data-nradio-operator-fix', VERSION);
        window.document.documentElement.setAttribute(
            'data-nradio-sim-name-map-count',
            String(Object.keys(window.NRadioSimNameMap || {}).length)
        );
        window.document.documentElement.setAttribute(
            'data-nradio-sim-name-priority',
            'map,firmware,cache'
        );
        window.document.documentElement.setAttribute(
            'data-nradio-operator-hooks',
            [
                window.format_isp_info && window.format_isp_info.nradioOperatorFix ? 'format' : '',
                window.cpe_show && window.cpe_show.nradioOperatorFix ? 'cpe' : ''
            ].filter(function (item) { return item; }).join(',')
        );
    }

    window.NRadioOperatorDisplayFix = {
        version: VERSION,
        normalize: companyFromPlmn,
        normalizeSimName: normalizeSimName,
        sanitizeCpeStatus: sanitizeCpeStatus
    };
}(window));
