// 把工作区里的 header.htm / 主题 CSS 归一到「原始 + 当前增强」，幂等
const fs = require('fs');
const read = (p) => fs.readFileSync(p, 'utf8').replace(/\r\n/g, '\n');

/* ---- header.htm ---- */
const hdrPath = 'usr/lib/lua/luci/view/themes/bootstrap/header.htm';
let hdr = read(hdrPath);
const bar = read('build/status-bar.js');
const anchor = '\t\t// ===== 软件包页面重构：概览卡片 / 存储条 / 表格 / 实时过滤 =====';
// 先移除旧的健康条块（从注释到该 IIFE 结束）
hdr = hdr.replace(/\t\t\/\/ ===== 状态页健康条[\s\S]*?\n\t\t\}\)\(\);\n\n/, '');
if (!hdr.includes(anchor)) throw new Error('header: 锚点缺失');
hdr = hdr.replace(anchor, bar + anchor);
fs.writeFileSync(hdrPath, hdr, 'utf8');

/* ---- 主题 CSS ---- */
const cssPath = 'www/luci-static/bootstrap/css/mwrt-global-custom.css';
let css = read(cssPath);
// 去掉此前追加的所有增强段（阶段二十 / 二十一 / 二十二）
css = css.replace(/\n\/\* ==== 阶段二十[\s\S]*$/, '');
css = css.replace(/\n\/\* ==== 阶段二十二[\s\S]*$/, '');
css = css.replace(/\s*$/, '');
css += '\n' + read('build/status-bar.css');
css += '\n' + read('build/dash2.css');
fs.writeFileSync(cssPath, css, 'utf8');

console.log('header bytes', fs.statSync(hdrPath).size, '| bar blocks', (hdr.match(/initStatusBar/g) || []).length);
console.log('css bytes', fs.statSync(cssPath).size, '| d2 blocks', (css.match(/\.d2\{/g) || []).length);
