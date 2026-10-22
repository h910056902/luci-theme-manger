// 以线上原始文件为基准，幂等地重建 header.htm 与主题 CSS
// 组成：原始 + 健康条（阶段二十） + 状态驾驶舱（阶段二十一）
const fs = require('fs');

const readLF = (p) => fs.readFileSync(p, 'utf8').replace(/\r\n/g, '\n');

// ---- header.htm ----
let hdr = readLF('build/remote/header.htm');
const js = readLF('build/status-bar.js');
const anchor = '\t\t// ===== 软件包页面重构：概览卡片 / 存储条 / 表格 / 实时过滤 =====';
if (!hdr.includes(anchor)) throw new Error('header: 锚点缺失');
if (hdr.includes('initStatusBar')) throw new Error('header: 原始文件里不应含健康条脚本');
hdr = hdr.replace(anchor, js + anchor);
fs.writeFileSync('usr/lib/lua/luci/view/themes/bootstrap/header.htm', hdr, 'utf8');

// ---- 主题 CSS ----
let css = readLF('build/remote/mwrt-global-custom.css');
css = css.replace(/\s*$/, '');
css += '\n' + readLF('build/status-bar.css');
css += '\n' + readLF('build/dash2.css');
fs.writeFileSync('www/luci-static/bootstrap/css/mwrt-global-custom.css', css, 'utf8');

console.log('header bytes', fs.statSync('usr/lib/lua/luci/view/themes/bootstrap/header.htm').size);
console.log('css bytes', fs.statSync('www/luci-static/bootstrap/css/mwrt-global-custom.css').size);
console.log('health blocks', (css.match(/\.st-health\{/g) || []).length);
console.log('dash blocks', (css.match(/\.dash\{/g) || []).length);
