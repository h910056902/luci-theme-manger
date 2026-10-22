// 把状态页样式拆到独立文件：
//   mwrt-global-custom.css 保持原样（只在 light 模式加载）
//   mwrt-status-custom.css  新增，无 media 限制，dark/light 都生效
const fs = require('fs');
const read = (p) => fs.readFileSync(p, 'utf8').replace(/\r\n/g, '\n');

/* 1) 独立样式文件 */
const statusCss = read('build/status-bar.css') + '\n' + read('build/dash2.css');
fs.writeFileSync('www/luci-static/bootstrap/css/mwrt-status-custom.css', statusCss, 'utf8');

/* 2) 主样式文件恢复原样（去掉我们追加的段落） */
const globalPath = 'www/luci-static/bootstrap/css/mwrt-global-custom.css';
let globalCss = read(globalPath);
globalCss = globalCss.replace(/\n\/\* ==== 阶段二十[\s\S]*$/, '');
globalCss = globalCss.replace(/\n\/\* ==== 阶段二十二[\s\S]*$/, '');
fs.writeFileSync(globalPath, globalCss.replace(/\s*$/, '') + '\n', 'utf8');

/* 3) header 里挂载（无 media 属性，避免深色系统下整份样式被跳过） */
const hdrPath = 'usr/lib/lua/luci/view/themes/bootstrap/header.htm';
let hdr = read(hdrPath);
hdr = hdr.replace(/\n\t<link rel="stylesheet" href="<%=media%>\/css\/mwrt-status-custom\.css[^"]*">/g, '');
const anchor = '\t<link rel="stylesheet" href="<%=media%>/css/mwrt-global-custom.css?v=20261020" media="(prefers-color-scheme: light)">';
if (!hdr.includes(anchor)) throw new Error('header: 找不到 global css 挂载点');
hdr = hdr.replace(anchor, anchor + '\n\t<link rel="stylesheet" href="<%=media%>/css/mwrt-status-custom.css?v=20261020">');
fs.writeFileSync(hdrPath, hdr, 'utf8');

console.log('status css bytes', fs.statSync('www/luci-static/bootstrap/css/mwrt-status-custom.css').size);
console.log('global css bytes', fs.statSync(globalPath).size, '| 残留增强段', globalCss.includes('阶段二十'));
console.log('header link', hdr.includes('mwrt-status-custom.css'));
