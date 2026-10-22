// 组装状态驾驶舱：样式抽取 + 视图生成（幂等）
const fs = require('fs');
const read = (p) => fs.readFileSync(p, 'utf8').replace(/\r\n/g, '\n');

/* 1) 从预览页抽取驾驶舱样式 */
let prev = read('preview/status-dashboard.html');
const m = prev.match(/<style>([\s\S]*?)<\/style>/);
if (!m) throw new Error('预览页缺少 <style>');
let css = m[1]
  .replace(/\/\* 预览角标[\s\S]*?\*\//, '')
  .replace(/\.kpc-preview-flag[^}]*}/g, '')
  .trim();
fs.writeFileSync('build/dash.css', css + '\n', 'utf8');

/* 2) 生成视图 */
let view = read('build/dash-view.htm');
if (!view.includes('<!--KPC-DASH-JS-->')) throw new Error('视图缺少 JS 占位符');
const js = read('build/dash.js');
view = view.replace('<!--KPC-DASH-JS-->', js);
if (!fs.existsSync('usr/lib/lua/luci/view/admin_status')) {
  throw new Error('目标视图目录不存在');
}
fs.writeFileSync('usr/lib/lua/luci/view/admin_status/index.htm', view, 'utf8');

/* 3) 主题 CSS 追阶段二十一的样式（先删旧块） */
const cssPath = 'www/luci-static/bootstrap/css/mwrt-global-custom.css';
let theme = read(cssPath);
theme = theme.replace(/\n\/\* ===== 状态驾驶舱（阶段二十一）=====[\s\S]*$/, '');
theme = theme.replace(/\s*$/, '') + '\n' + css + '\n';
fs.writeFileSync(cssPath, theme, 'utf8');

/* 4) 自检 */
const t = (view.match(/<%/g) || []).length;
const tc = (view.match(/%>/g) || []).length;
console.log('view bytes', fs.statSync('usr/lib/lua/luci/view/admin_status/index.htm').size);
console.log('template tags', t, tc, t === tc ? 'OK' : 'MISMATCH');
console.log('theme css bytes', fs.statSync(cssPath).size);
console.log('dash css bytes', fs.statSync('build/dash.css').size);
