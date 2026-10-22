(function () {
	'use strict';

	var API = '<%=pcdata(disp.build_url("admin", "status", "overview"))%>';

	function $(id) { return document.getElementById(id); }
	function num(v) { return Number(v) || 0; }
	function mib(b) { return (num(b) / 1048576); }
	function gib(b) { return (num(b) / 1073741824); }
	function pct(a, b) { return b > 0 ? a * 100 / b : 0; }
	function clamp(v) { return v > 100 ? 100 : (v < 0 ? 0 : v); }
	function pad(x) { return (x < 10 ? '0' : '') + x; }
	function esc(s) {
		return String(s == null ? '' : s).replace(/&/g, '&amp;').replace(/</g, '&lt;')
			.replace(/>/g, '&gt;').replace(/"/g, '&quot;');
	}
	function dur(s) {
		s = Math.floor(num(s));
		var d = Math.floor(s / 86400), h = Math.floor((s % 86400) / 3600), m = Math.floor((s % 3600) / 60);
		if (d > 0) return d + ' 天 ' + h + ' 小时';
		if (h > 0) return h + ' 小时 ' + m + ' 分';
		return m + ' 分';
	}
	function bytes(n) {
		n = num(n);
		if (n >= 1073741824) return gib(n).toFixed(2) + ' GiB';
		if (n >= 1048576) return mib(n).toFixed(1) + ' MiB';
		if (n >= 1024) return Math.round(n / 1024) + ' KiB';
		return n + ' B';
	}
	function ispName(code) {
		var m = { '46000': '中国移动', '46001': '中国联通', '46003': '中国电信', '46015': '中国广电' };
		return m[code] || code || '无服务';
	}
	function lvl(v, w, c) { return v >= c ? 'is-bad' : (v >= w ? 'is-warn' : ''); }

	function row(k, v, cls, t) {
		return '<div class="d2-row"><span class="k">' + k + '</span><span class="v ' + (cls || '') + '">'
			+ v + '</span>' + (t ? '<span class="t">' + t + '</span>' : '') + '</div>';
	}

	function render(d) {
		if (!d || d.code !== 0) return;
		var cpu = num(d.ncpu) || 1;
		var la = d.load || [0, 0, 0];
		var loadPct = num(la[0]) / cpu * 100;
		var mem = d.mem || {};
		var memPct = pct(num(mem.total) - num(mem.available), num(mem.total));
		var stPct = num((d.storage || {}).pct);
		var temp = 0;
		(d.thermal || []).forEach(function (t) { if (num(t) > temp) temp = num(t); });
		var ct = d.conntrack || {};
		var ctPct = pct(num(ct.count), num(ct.max));
		var lg = d.log || {};
		var bad = num(lg.err) + num(lg.warn);
		var proc = d.proc || {};

		/* ---- 顶部判定 ---- */
		var worst = '';
		[['load', loadPct, 60, 85], ['mem', memPct, 70, 85], ['st', stPct, 80, 90],
			['temp', temp, 70, 80], ['ct', ctPct, 60, 85], ['log', bad, 1, 10]].forEach(function (x) {
			var s = lvl(x[1], x[2], x[3]);
			if (s === 'is-bad') worst = 'is-bad';
			else if (s === 'is-warn' && worst !== 'is-bad') worst = 'is-warn';
		});
		var top = $('d2-top');
		top.className = 'd2-top ' + worst;
		$('d2-verdict').innerHTML = '<i class="d2-dot"></i>'
			+ (worst === 'is-bad' ? '需要处理' : (worst === 'is-warn' ? '有异常' : '运行正常'));

		function kpi(label, val, s) {
			return '<span class="d2-kpi ' + s + '">' + label + ' <b>' + val + '</b></span>';
		}
		$('d2-kpis').innerHTML =
			kpi('负载', loadPct.toFixed(0) + '%', lvl(loadPct, 60, 85)) +
			kpi('内存', memPct.toFixed(0) + '%', lvl(memPct, 70, 85)) +
			kpi('存储', stPct + '%', lvl(stPct, 80, 90)) +
			kpi('温度', temp + '℃', lvl(temp, 70, 80)) +
			kpi('连接', ctPct.toFixed(1) + '%', lvl(ctPct, 60, 85)) +
			kpi('进程', num(proc.total), '') +
			kpi('终端', (d.wifi || {}).total || 0, '') +
			kpi('异常', bad, lvl(bad, 1, 10));

		var t = new Date();
		$('d2-updated').textContent = '已更新 ' + pad(t.getHours()) + ':' + pad(t.getMinutes()) + ':' + pad(t.getSeconds());
		$('d2-uptime').textContent = dur(d.uptime);

		/* ---- 设备与上行 ---- */
		var c = d.cell || {}, ip = d.ip || {}, r = d.route || {};
		var h = '';
		h += row('蜂窝', c.mode ? (ispName(c.isp) + ' · ' + esc(c.mode) + (c.band ? ' · n' + esc(c.band) : ''))
			: '无服务', '', c.simno ? ('卡 ' + esc(c.simno) + '/' + esc(c.simcount)) : '');
		h += row('信号', c.rsrp ? (esc(c.rsrp) + ' dBm · SINR ' + esc(c.sinr) + ' dB · RSRQ ' + esc(c.rsrq) + ' dB')
			: '—', '', c.pci ? ('PCI ' + esc(c.pci)) : '');
		h += row('频点', c.earfcn ? esc(c.earfcn) : '—', 'mono', '');
		h += row('IPv4', ip.v4 ? esc(ip.v4) : '—', 'mono', '');
		h += row('IPv6', ip.v6 ? esc(ip.v6) : '—', 'mono', '');
		h += row('DNS', ip.dns ? esc(ip.dns) : '—', 'mono', '');
		var nw = d.net || {};
		if (nw.dev) {
			h += row('实时速率', '↓ ' + bytes(nw.rx_bps) + '/s · ↑ ' + bytes(nw.tx_bps) + '/s', 'mono',
				'累计 ↓ ' + bytes(nw.rx_total) + ' / ↑ ' + bytes(nw.tx_total));
		}
		h += row('默认路由', r.gw ? (esc(r.gw) + ' via ' + esc(r.dev)) : '缺失', 'mono',
			r.gw ? '<span class="d2-tag on">可达</span>' : '<span class="d2-tag warn">缺失</span>');
		$('d2-device').innerHTML = h;

		/* ---- 资源 ---- */
		var swap = num(mem.swap_total) > 0 ? (mib(mem.swap_free).toFixed(0) + ' / ' + mib(mem.swap_total).toFixed(0) + ' MiB') : '未启用';
		h = '';
		h += row('负载 1/5/15', num(la[0]).toFixed(2) + ' / ' + num(la[1]).toFixed(2) + ' / ' + num(la[2]).toFixed(2),
			'', cpu + ' 核');
		var cp = d.cpu || null;
		h += row('CPU 利用率', cp ? (num(cp.pct) + '%') : '—', cp ? lvl(num(cp.pct), 70, 90) : '', '');
		h += row('内存', mib(mem.total - mem.available).toFixed(0) + ' / ' + mib(mem.total).toFixed(0) + ' MiB',
			'', memPct.toFixed(0) + '%');
		h += row('其中缓存', mib(mem.cached).toFixed(0) + ' MiB（可回收）', '', '');
		h += row('可用内存', mib(mem.available).toFixed(0) + ' MiB', '', '');
		h += row('存储', gib((d.storage || {}).used).toFixed(1) + ' / ' + gib((d.storage || {}).total).toFixed(1) + ' GiB',
			'', stPct + '%');
		h += row('温度', (d.thermal || []).join(' / ') + ' ℃', '', '');
		h += row('连接跟踪', num(ct.count) + ' / ' + num(ct.max), '', ctPct.toFixed(1) + '%');
		h += row('进程 / 僵尸', num(proc.total) + ' / ' + num(proc.zombie),
			num(proc.zombie) > 0 ? 'd2-bad' : '', mib(proc.rss).toFixed(0) + ' MiB');
		h += row('Swap', swap, '', '');
		$('d2-res').innerHTML = h;

		/* ---- 无线与终端 ---- */
		h = '';
		var ssids = d.ssids || [];
		if (ssids.length) {
			ssids.forEach(function (s) {
				h += row(esc(s.dev), (s.ssid ? esc(s.ssid) : '未启用') + (s.ch ? ' · ch' + esc(s.ch) : '')
					+ (s.sig ? ' · ' + esc(s.sig) + ' dBm' : ''),
					'mono', s.n + ' 台');
			});
		} else {
			h += row('无线', '无数据', '', '');
		}
		var dhcp = d.dhcp || [];
		if (dhcp.length) {
			h += '<div class="d2-row"><span class="k">DHCP</span><span class="v">' + dhcp.length + ' 条租约</span></div>';
			dhcp.slice(0, 4).forEach(function (l) {
				h += row('', esc(l.ip) + ' · ' + esc(l.host || l.mac), 'mono', '');
			});
		} else {
			h += row('DHCP', '无租约', '', '');
		}
		(d.arp_top || []).slice(0, 2).forEach(function (a) {
			h += row('ARP', esc(a.mac) + ' × ' + a.n, 'mono', '');
		});
		$('d2-wifi').innerHTML = h;

		/* ---- 路由 ---- */
		var routes = d.routes || [];
		if (routes.length) {
			var th = '<table class="d2-tbl"><thead><tr><th>目标</th><th>网关</th><th>接口</th><th>metric</th></tr></thead><tbody>';
			routes.forEach(function (x) {
				th += '<tr class="' + (x.dest === 'default' ? 'is-default' : (x.down ? 'is-down' : '')) + '">'
					+ '<td class="mono">' + esc(x.dest) + '</td>'
					+ '<td class="mono">' + (x.gw ? esc(x.gw) : '—') + '</td>'
					+ '<td class="mono">' + esc(x.dev) + '</td>'
					+ '<td>' + (x.metric || '0') + '</td></tr>';
			});
			$('d2-routes').innerHTML = '<div class="d2-scroll">' + th + '</tbody></table></div>';
		} else {
			$('d2-routes').innerHTML = '<div class="d2-empty">无路由</div>';
		}

		/* ---- 防火墙 ---- */
		var fw = d.fw || {};
		var fh = '<div class="d2-rows">' + row('规则总数', num(fw.total || fw.rules) + ' 条', '',
			(fw.input === 'ACCEPT') ? '<span class="d2-tag warn">INPUT 宽松</span>' : '<span class="d2-tag on">INPUT 收紧</span>') + '</div>';
		var chs = fw.chains || [];
		if (chs.length) {
			var t2 = '<table class="d2-tbl"><thead><tr><th>链</th><th>策略</th><th>规则</th></tr></thead><tbody>';
			chs.slice(0, 4).forEach(function (x) {
				var pol = x.policy || '-';
				if (x.refs) pol += ' <span class="d2-note">(' + x.refs + ' 引用)</span>';
				t2 += '<tr><td class="mono">' + esc(x.name) + '</td><td>' + pol
					+ '</td><td>' + x.rules + '</td></tr>';
			});
			fh += t2 + '</tbody></table>';
		}
		var tops = fw.top || [];
		if (tops.length) {
			var t3 = '<table class="d2-tbl"><thead><tr><th>命中规则</th><th>包</th><th>流量</th></tr></thead><tbody>';
			tops.slice(0, 4).forEach(function (x) {
				t3 += '<tr><td class="mono">' + esc(x.chain) + ' → ' + esc(x.target) + '</td><td>'
					+ x.pkts + '</td><td>' + bytes(x.bytes) + '</td></tr>';
			});
			fh += '<div class="d2-note" style="padding-top:8px">命中 Top</div>' + t3 + '</tbody></table>';
		}
		$('d2-fw').innerHTML = fh;

		/* ---- 进程 ---- */
		var pm = proc.top_mem || [];
		if (pm.length) {
			var max = 1;
			pm.forEach(function (x) { if (x.rss > max) max = x.rss; });
			var t4 = '<table class="d2-tbl"><thead><tr><th>PID</th><th>进程</th><th>内存</th><th style="width:38%">占比</th></tr></thead><tbody>';
			pm.slice(0, 8).forEach(function (x) {
				t4 += '<tr><td>' + x.pid + '</td><td class="mono">' + esc(x.cmd) + '</td><td>'
					+ mib(x.rss).toFixed(0) + ' MiB</td><td><span style="display:inline-block;height:5px;border-radius:3px;'
					+ 'background:linear-gradient(90deg,#388087,#2bffc6);width:' + (x.rss / max * 100).toFixed(0) + '%"></span></td></tr>';
			});
			$('d2-proc').innerHTML = t4 + '</tbody></table>';
		} else {
			$('d2-proc').innerHTML = '<div class="d2-empty">无数据</div>';
		}

		/* ---- 系统日志 ---- */
		var recent = lg.recent || [];
		if (recent.length) {
			var lh = '';
			recent.forEach(function (x) {
				lh += '<div class="d2-line lv-' + esc(x.lv) + '"><span class="ts">' + esc(x.ts || '')
					+ '</span><span class="lv">' + esc(x.lv) + '</span><span class="msg">' + esc(x.msg) + '</span></div>';
			});
			$('d2-log').innerHTML = lh;
		} else {
			$('d2-log').innerHTML = '<div class="d2-empty">无日志</div>';
		}

		/* ---- 内核日志 ---- */
		var kl = d.klog || [];
		if (kl.length) {
			$('d2-klog').innerHTML = kl.map(function (x) {
				return '<div class="d2-line lv-' + esc(x.lv) + '"><span class="ts">+' + Math.floor(x.t) + 's</span>'
					+ '<span class="msg">' + esc(x.msg) + '</span></div>';
			}).join('');
		} else {
			$('d2-klog').innerHTML = '<div class="d2-empty">无内核日志</div>';
		}

		/* ---- 计数角标 ---- */
		$('cnt-routes').textContent = routes.length;
		$('cnt-fw').textContent = num(fw.total || fw.rules) + ' 条';
		$('cnt-proc').textContent = num(proc.total) + ' 个';
		$('cnt-log').textContent = num(lg.total) + ' 行';
		$('cnt-klog').textContent = kl.length;
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

	load();
	window.setInterval(load, 10000);
	document.addEventListener('visibilitychange', function () { if (!document.hidden) load(); });
})();
