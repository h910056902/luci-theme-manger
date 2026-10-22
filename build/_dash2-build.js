// 组装单页状态总览：视图 + 预览（幂等）
const fs = require('fs');
const read = (p) => fs.readFileSync(p, 'utf8').replace(/\r\n/g, '\n');

/* ---------- 1) 视图 ---------- */
let view = read('build/dash2-view.htm');
if (!view.includes('<!--KPC-DASH2-JS-->')) throw new Error('缺少 JS 占位符');
view = view.replace('<!--KPC-DASH2-JS-->', read('build/dash2.js'));
fs.writeFileSync('usr/lib/lua/luci/view/admin_status/index.htm', view, 'utf8');

/* ---------- 2) 预览页 ---------- */
let body = view
  .replace(/^<%\+header%>\n/, '')
  .replace(/<link rel="stylesheet" href="\/fontawesome\/all.min.css\?v=1">\n/, '')
  .replace(/<script>document\.body\.classList\.add\('kpc-dash'\);<\/script>\n/, '')
  .replace(/<%\n[\s\S]*?\n-%>\n/, '')                       // 顶部 Lua 数据块
  .replace(/<%=pcdata\(model\)%>/g, 'HC-WT9500')
  .replace(/<%=pcdata\(hostname\)%>/g, 'nradio.in')
  .replace(/<%=pcdata\(ver\.distversion or "-"\)%>/g, '2.3.0.n0.c1')
  .replace(/<%=pcdata\(kernel\)%>/g, '5.4.281')
  .replace(/<%=dur\(sys\.uptime\(\)\)%>/g, '1 天 17 小时')
  .replace(/<%=pcdata\(disp\.build_url\("admin", "status", "overview"\)\)%>/g, '/cgi-bin/luci/admin/status/overview')
  .replace(/<%\+footer%>\n?/, '');

const head = `<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>预览 · 状态总览</title>
<link rel="stylesheet" href="../www/luci-static/bootstrap/css/cascade.css">
<link rel="stylesheet" href="../www/luci-static/bootstrap/css/fonts.css">
<link rel="stylesheet" href="../www/luci-static/bootstrap/css/mwrt-global-custom.css">
<link rel="stylesheet" href="../www/luci-static/bootstrap/css/mwrt-status-custom.css">
<link rel="stylesheet" href="../www/fontawesome/all.min.css">
<style>body{background:#fff}.kpc-shell{display:flex;min-height:100vh}.kpc-side{width:210px;flex:0 0 210px;background:#0d1117;padding:14px 0}.kpc-side a{display:block;padding:9px 16px;color:#c9d1d9;font-size:13px;text-decoration:none}.kpc-side a.on{color:#2bffc6;background:rgba(43,255,198,.07)}.kpc-main{flex:1;min-width:0}.kpc-top{display:flex;align-items:center;height:52px;padding:0 18px;border-bottom:1px solid #eef1f4}.kpc-top b{font-size:15px;color:#16202c}.kpc-flag{position:fixed;right:14px;bottom:14px;z-index:99;padding:6px 12px;border-radius:999px;background:rgba(16,24,40,.86);color:#fff;font-size:11px}</style>
</head>
<body class="node-status-overview kpc-dash">
<div class="kpc-shell">
	<div class="kpc-side"><a class="on" href="#">首页 · 状态总览</a><a href="#">网络设置向导</a><a href="#">iStore</a><a href="#">服务</a><a href="#">网络</a></div>
	<div class="kpc-main"><div class="kpc-top"><b>NRadio</b></div><div id="maincontent"><div class="container" style="padding:0 18px">`;

const mock = read('build/dash2-mock.json');
const stub = `<script>
window.__D2__ = ${mock};
window.fetch = function () {
  var o = window.__D2__;
  return Promise.resolve({ json: function () { return Promise.resolve(o); } });
};
</script>`;

const tail = `</div></div></div>
<div class="kpc-flag">设计预览 · 数据为模拟</div>
</body>
</html>`;

// 把 stub 插到页面唯一的内联脚本之前
const idx = body.lastIndexOf('<script type="text/javascript">');
if (idx < 0) throw new Error('预览：找不到内联脚本');
body = body.slice(0, idx) + stub + body.slice(idx);

fs.writeFileSync('preview/status-dashboard2.html', head + body + tail, 'utf8');

/* ---------- 3) 自检 ---------- */
const t = (view.match(/<%/g) || []).length, tc = (view.match(/%>/g) || []).length;
console.log('view bytes', fs.statSync('usr/lib/lua/luci/view/admin_status/index.htm').size, '| tags', t, tc, t === tc ? 'OK' : 'BAD');
console.log('preview bytes', fs.statSync('preview/status-dashboard2.html').size);
