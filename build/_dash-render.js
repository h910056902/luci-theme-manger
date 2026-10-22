// 把线上页面本地化，并注入真实接口数据，用于离线截图核对
const fs = require('fs');

let html = fs.readFileSync('build/dash-live.html', 'utf8');
const data = fs.readFileSync('build/status-live.json', 'utf8').trim();

// 资源改成本地相对路径
html = html.replace(/(href|src)="\/(luci-static|fontawesome|logo|router3d)\//g, (m, a, b) => `${a}="../www/${b}/`);
html = html.replace(/url\('\/(luci-static|fontawesome)\//g, "url('../www/$1/");
html = html.replace(/url\(\/(luci-static|fontawesome)\//g, "url('../www/$1/");

// 注入 mock fetch（在页面脚本之前）
const stub = `<script>
window.__KP_DATA__ = ${JSON.stringify(data)};
(function () {
  var raw = window.__KP_DATA__;
  var obj = JSON.parse(raw);
  window.fetch = function () {
    return Promise.resolve({ json: function () { return Promise.resolve(obj); } });
  };
})();
</script>`;

const marker = '<script type="text/javascript">';
const i = html.lastIndexOf(marker);
if (i < 0) throw new Error('找不到内联脚本');
html = html.slice(0, i) + stub + html.slice(i);

fs.writeFileSync('preview/dash-live.html', html, 'utf8');
console.log('written preview/dash-live.html', html.length);
