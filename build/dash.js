(function () {
	'use strict';

	var API = '<%=pcdata(disp.build_url("admin", "status", "overview"))%>';
	var BOOT_UPTIME = <%= tonumber(uptime) or 0 %>;
	var bootAt = Date.now() - BOOT_UPTIME * 1000;

	var $ = function (id) { return document.getElementById(id); };
	function num(v) { return Number(v) || 0; }
	function mib(b) { return (num(b) / 1048576); }
	function pct(a, b) { return b > 0 ? a * 100 / b : 0; }
	function clamp(v) { return v > 100 ? 100 : (v < 0 ? 0 : v); }
	function pad(x) { return (x < 10 ? '0' : '') + x; }

	function dur(s) {
		s = Math.floor(num(s));
		var d = Math.floor(s / 86400), h = Math.floor((s % 86400) / 3600), m = Math.floor((s % 3600) / 60);
		if (d > 0) return d + ' 天 ' + h + ' 小时';
		if (h > 0) return h + ' 小时 ' + m + ' 分';
		return m + ' 分';
	}
	function level(v, warn, crit) { return v >= crit ? 'is-bad' : (v >= warn ? 'is-warn' : ''); }

	function setKpi(key, text, ratio, cls) {
		var el = document.querySelector('.dash-kpi[data-k="' + key + '"]');
		if (!el) return;
		el.querySelector('b').innerHTML = text;
		el.querySelector('u').style.width = clamp(ratio) + '%';
		el.className = 'dash-kpi ' + (cls || '');
	}

	function ispName(code) {
		var map = { '46000': '中国移动', '46002': '中国移动', '46004': '中国移动', '46007': '中国移动', '46008': '中国移动',
			'46001': '中国联通', '46006': '中国联通', '46009': '中国联通',
			'46003': '中国电信', '46005': '中国电信', '46011': '中国电信', '46015': '中国广电' };
		return map[code] || code || '无服务';
	}

	function render(d) {
		if (!d || d.code !== 0) return;
		var cpu = num(d.ncpu) || 1;
		var loadPct = num((d.load || [])[0]) / cpu * 100;
		var mem = d.mem || {};
		var memPct = pct(num(mem.total) - num(mem.available), num(mem.total));
		var stPct = num((d.storage || {}).pct);
		var temp = 0;
		(d.thermal || []).forEach(function (t) { if (num(t) > temp) temp = num(t); });
		var ctPct = pct(num((d.conntrack || {}).count), num((d.conntrack || {}).max));
		var lg = d.log || {};
		var bad = num(lg.err) + num(lg.warn);

		setKpi('load', loadPct.toFixed(0) + '<small>%</small>', loadPct, level(loadPct, 60, 85));
		setKpi('mem', memPct.toFixed(0) + '<small>%</small>', memPct, level(memPct, 70, 85));
		setKpi('store', stPct + '<small>%</small>', stPct, level(stPct, 80, 90));
		setKpi('temp', temp + '<small>℃</small>', temp, level(temp, 70, 80));
		setKpi('conn', ctPct.toFixed(1) + '<small>%</small>', ctPct, level(ctPct, 60, 85));
		setKpi('log', String(bad), Math.min(bad * 10, 100), bad > 10 ? 'is-bad' : (bad > 0 ? 'is-warn' : ''));

		var worst = '';
		['load', 'mem', 'store', 'temp', 'conn', 'log'].forEach(function (k) {
			var el = document.querySelector('.dash-kpi[data-k="' + k + '"]');
			if (!el) return;
			if (el.className.indexOf('is-bad') >= 0) worst = 'is-bad';
			else if (el.className.indexOf('is-warn') >= 0 && worst !== 'is-bad') worst = 'is-warn';
		});
		var v = $('verdict');
		if (v) {
			v.className = 'dash-verdict ' + worst;
			v.innerHTML = (worst === 'is-bad' ? '<i class="fas fa-exclamation-circle"></i>需要处理'
				: (worst === 'is-warn' ? '<i class="fas fa-exclamation-triangle"></i>有异常'
					: '<i class="fas fa-check-circle"></i>运行正常'));
		}

		// 上行
		var c = d.cell || {};
		if (c.mode) {
			$('v-cell').textContent = ispName(c.isp) + ' · ' + c.mode + (c.band ? ' · n' + c.band : '');
			$('t-cell').innerHTML = '<span class="dash-tag on">已注册</span>';
			if (c.rsrp) {
				$('v-sig').textContent = c.rsrp + ' dBm' + (c.sinr ? ' · SINR ' + c.sinr + ' dB' : '');
				var snr = num(c.sinr);
				var sigCls = (num(c.rsrp) >= -95) ? 'on' : ((num(c.rsrp) >= -105) ? 'warn' : 'warn');
				$('t-sig').innerHTML = '<span class="dash-tag ' + sigCls + '">' + (num(c.rsrp) >= -95 ? '良好' : (num(c.rsrp) >= -105 ? '一般' : '较弱')) + '</span>';
			}
		} else {
			$('v-cell').textContent = d.route && d.route.dev ? ('无蜂窝数据 · 上行 ' + d.route.dev) : '无蜂窝数据';
			$('t-cell').innerHTML = '<span class="dash-tag warn">未注册</span>';
		}

		var r = d.route || {};
		$('v-route').textContent = r.gw ? (r.gw + ' via ' + r.dev) : (r.default || '无默认路由');
		$('t-route').innerHTML = r.gw ? '<span class="dash-tag on">可达</span>' : '<span class="dash-tag warn">缺失</span>';

		var ip = d.ip || {};
		$('v-ip').textContent = (ip.v4 || '-') + ' / ' + (ip.v6 || '-');

		var w = d.wifi || {};
		$('v-clients').textContent = num(w.total) + ' 台无线';
		$('t-arp').textContent = 'ARP ' + num(d.arp) + ' 条';

		// 资源
		var p = d.proc || {}, tops = p.top_mem || [];
		var maxRss = 1;
		tops.forEach(function (t) { if (t.rss > maxRss) maxRss = t.rss; });
		var html = '';
		tops.slice(0, 3).forEach(function (t) {
			html += '<div class="it"><span class="nm">' + t.cmd + '</span>'
				+ '<span class="bar"><i style="width:' + (t.rss / maxRss * 100).toFixed(0) + '%"></i></span>'
				+ '<span class="vl">' + mib(t.rss).toFixed(0) + ' MiB</span></div>';
		});
		$('dash-proc').innerHTML = html || '<div class="dash-empty">暂无数据</div>';
		$('v-proc').textContent = num(p.total) + ' 个';
		$('v-zombie').textContent = num(p.zombie) + ' 个';
		$('mem-note').textContent = '可用 ' + mib(mem.available).toFixed(0) + ' MiB · 缓存 '
			+ mib(mem.cached).toFixed(0) + ' MiB（缓存可回收，不计入真实占用）';

		// 日志与安全
		$('v-log').textContent = '共 ' + num(lg.total) + ' 行 · 异常 ' + bad + ' 条';
		$('t-log').innerHTML = bad ? '<span class="dash-tag warn">需关注</span>' : '<span class="dash-tag on">干净</span>';
		var top = (lg.top || [])[0];
		$('v-top').textContent = top ? (top.src + ' × ' + top.n) : '—';
		$('t-top').textContent = top ? '占比 ' + Math.round(top.n * 100 / Math.max(num(lg.total), 1)) + '%' : '';
		var fw = d.fw || {};
		$('v-fw').textContent = num(fw.rules) + ' 条规则 · INPUT ' + (fw.input || '?');
		$('t-fw').innerHTML = (fw.input === 'ACCEPT')
			? '<span class="dash-tag warn">策略宽松</span>' : '<span class="dash-tag on">策略收紧</span>';
		$('log-note').textContent = bad === 0
			? '当前没有错误或警告；排查时可在系统日志中切到「全部」。'
			: '存在 ' + bad + ' 条异常，建议到系统日志查看异常优先列表。';

		// 连接与设备
		$('v-wifi').textContent = num(w.total) + ' 台';
		$('t-wifi').textContent = (w.bands || []).map(function (b) { return b.dev + ' ' + b.n + ' 台'; }).join(' · ');
		$('v-arp').textContent = num(d.arp) + ' 条';
		$('v-ct').textContent = num((d.conntrack || {}).count) + ' / ' + num((d.conntrack || {}).max);
		$('t-ct').textContent = ctPct.toFixed(1) + '% 已用';
		$('v-up').textContent = dur(d.uptime);

		// 下钻角标
		$('l-route').textContent = num(d.arp) + ' ARP';
		$('l-fw').textContent = num(fw.rules) + ' 规则';
		$('l-log').textContent = num(lg.total) + ' 行';
		$('l-proc').textContent = num(p.total) + ' 进程';

		// 顶部运行时间同步
		var upEl = document.getElementById('dash-uptime');
		if (upEl) upEl.textContent = '已运行 ' + dur(d.uptime);

		var t = new Date();
		$('dash-updated').textContent = '已更新 ' + pad(t.getHours()) + ':' + pad(t.getMinutes())
			+ ':' + pad(t.getSeconds()) + ' · 每 10 秒自动刷新';
	}

	var inflight = false;
	function load() {
		if (inflight || document.hidden) return;
		inflight = true;
		fetch(API + '?action=kp_status&t=' + Date.now(), { credentials: 'same-origin' })
			.then(function (r) { return r.json(); })
			.then(function (d) { inflight = false; render(d); })
			.catch(function () { inflight = false; });
	}

	function tick() {
		var el = document.getElementById('dash-uptime');
		if (el && BOOT_UPTIME) el.textContent = '已运行 ' + dur((Date.now() - bootAt) / 1000);
	}

	load();
	tick();
	window.setInterval(load, 10000);
	window.setInterval(tick, 30000);
	document.addEventListener('visibilitychange', function () { if (!document.hidden) load(); });
})();
