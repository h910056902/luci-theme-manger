		// ===== 状态页健康条（KP-STATUS-API v1） =====
		// 数据来自 /admin/status/*?action=kp_status（3 秒缓存，7 页共用）
		(function initStatusBar() {
			if (location.pathname.indexOf('/admin/status/') < 0) return;

			// header.htm 在 #maincontent 之前输出，必须等 DOM 就绪再找节点
			function start() {
			// 状态子页已并入总览：侧栏里只保留「概览」
			if (document.querySelector('.dash, .d2')) {
				var navLinks = document.querySelectorAll('.main-left .nav a.menu');
				for (var n = 0; n < navLinks.length; n++) {
					var href = navLinks[n].getAttribute('href') || '';
					if (href.indexOf('/admin/status/') >= 0 && href.indexOf('/admin/status/overview') < 0) {
						var li = navLinks[n].closest ? navLinks[n].closest('li') : null;
						if (li) li.style.display = 'none';
					}
				}
				return;
			}
			var cont = document.querySelector('#maincontent > .container');
			if (!cont) return;
			var h2 = cont.querySelector(':scope > h2');
			if (!h2) return;
			if (document.getElementById('st-health')) return;

			var box = document.createElement('div');
			box.className = 'st-health';
			box.id = 'st-health';
			box.style.display = 'none';
			if (h2.nextSibling) cont.insertBefore(box, h2.nextSibling);
			else cont.appendChild(box);

			var timer = null, inflight = false;

			function num(v) { return Number(v) || 0; }
			function mb(bytes) { return (num(bytes) / 1048576); }
			function fmtPct(v) { return (v >= 100 ? 100 : v).toFixed(0) + '%'; }
			function fmtMiB(bytes) { return (num(bytes) / 1048576).toFixed(0) + ' MiB'; }

			function pick() {
				var d = null;
				try { d = arguments[0]; } catch (e) { return ''; }
				return d;
			}

			function render(d) {
				if (!d || d.code !== 0) { box.style.display = 'none'; return; }

				var loadPct = num(d.ncpu) > 0 ? num((d.load || [])[0]) / num(d.ncpu) * 100 : 0;
				var memPct = num((d.mem || {}).total) > 0
					? (num(d.mem.total) - num(d.mem.available)) / num(d.mem.total) * 100 : 0;
				var stPct = num((d.storage || {}).pct);
				var temp = 0;
				(d.thermal || []).forEach(function (t) { if (num(t) > temp) temp = num(t); });
				var ctPct = num((d.conntrack || {}).max) > 0
					? num(d.conntrack.count) / num(d.conntrack.max) * 100 : 0;
				var lg = d.log || {};
				var bad = num(lg.err) + num(lg.warn);

				function lvl(v, warn, crit) {
					return (v >= crit) ? 'is-bad' : (v >= warn ? 'is-warn' : '');
				}
				function chip(label, value, cls, title, sm) {
					return '<span class="st-item ' + cls + (sm ? ' st-sm' : '') + '" title="' + (title || '') + '">'
						+ label + ' <b>' + value + '</b></span>';
				}

				var cLoad = lvl(loadPct, 60, 85);
				var cMem = lvl(memPct, 70, 85);
				var cSt = lvl(stPct, 80, 90);
				var cTemp = lvl(temp, 70, 80);
				var cCt = lvl(ctPct, 60, 85);
				var cLog = lvl(bad, 1, 10);

				var worst = '';
				var worstLink = '';
				if (cLoad === 'is-bad' || cMem === 'is-bad' || cSt === 'is-bad' || cTemp === 'is-bad'
					|| cCt === 'is-bad' || cLog === 'is-bad') {
					worst = 'is-bad';
				} else if (cLoad || cMem || cSt || cTemp || cCt || cLog) {
					worst = 'is-warn';
				}
				if (worst === 'is-bad' || worst === 'is-warn') {
					if (cLog) worstLink = '/cgi-bin/luci/admin/status/syslog';
					else if (cMem === 'is-bad') worstLink = '/cgi-bin/luci/admin/status/processes';
					else worstLink = '/cgi-bin/luci/admin/status/realtime/load';
				}

				var verdict = worst === 'is-bad' ? '需要处理' : (worst === 'is-warn' ? '有异常' : '运行正常');
				var dotColor = worst === 'is-bad' ? '#d64545' : (worst === 'is-warn' ? '#f0a020' : '#22a06b');

				var html = '<span class="st-verdict"><i class="st-dot" style="background:' + dotColor + '"></i>'
					+ verdict + '</span><span class="st-sep">|</span>'
					+ chip('负载', fmtPct(loadPct), cLoad, '1 分钟负载 ' + num((d.load || [])[0]).toFixed(2) + ' / ' + num(d.ncpu) + ' 核')
					+ chip('内存', fmtPct(memPct), cMem, '可用 ' + fmtMiB((d.mem || {}).available) + ' / 共 ' + fmtMiB((d.mem || {}).total))
					+ chip('存储', fmtPct(stPct), cSt, '已用 ' + fmtMiB((d.storage || {}).used) + ' / 共 ' + fmtMiB((d.storage || {}).total), true)
					+ chip('温度', temp > 0 ? temp.toFixed(1) + '℃' : '--', cTemp, '多个温区取最高值', true)
					+ chip('连接', fmtPct(ctPct), cCt, num((d.conntrack || {}).count) + ' / ' + num((d.conntrack || {}).max), true)
					+ chip('异常', String(bad), cLog, '日志错误 ' + num(lg.err) + ' 条，警告 ' + num(lg.warn) + ' 条');

				html += '<span class="st-sp"></span>';
				if (worstLink) {
					html += '<a class="st-link" href="' + worstLink + '">去查看</a>';
				}
				box.innerHTML = html;
				box.className = 'st-health ' + worst;
				box.style.display = '';
			}

			function load() {
				if (inflight || document.hidden) return;
				inflight = true;
				fetch(location.pathname + '?action=kp_status&t=' + Date.now(), {
					credentials: 'same-origin',
					headers: { 'Accept': 'application/json' }
				}).then(function (r) { return r.json(); }).then(function (d) {
					inflight = false;
					render(d);
				}).catch(function () {
					inflight = false;
					box.style.display = 'none';
				});
			}

			load();
			timer = window.setInterval(load, 30000);
			document.addEventListener('visibilitychange', function () {
				if (!document.hidden) load();
			});
			window.addEventListener('beforeunload', function () {
				if (timer) window.clearInterval(timer);
			});
			}

			if (document.readyState === 'loading') {
				document.addEventListener('DOMContentLoaded', start);
			} else {
				start();
			}
		})();

