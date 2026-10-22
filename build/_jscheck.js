const fs = require('fs');
const p = process.argv[2] || 'usr/lib/lua/luci/view/admin_status/index.htm';
const s = fs.readFileSync(p, 'utf8');
const m = s.match(/<script type="text\/javascript">([\s\S]*?)<\/script>/);
if (!m) { console.log('no script block'); process.exit(1); }
const js = m[1]
  .replace(/<%=[\s\S]*?%>/g, '0')
  .replace(/<%[\s\S]*?%>/g, '')
  .replace(/\/\/<!\[CDATA\[/, '')
  .replace(/\/\/\]\]>/, '');
try {
  new Function(js);
  console.log('JS OK');
} catch (e) {
  console.log('JS FAIL ->', e.message);
}
