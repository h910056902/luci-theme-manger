const http = require('http');
const PORT = Number(process.env.CDP_PORT || 9228);

function getJson(path) {
  return new Promise((resolve, reject) => {
    http.get({ host: '127.0.0.1', port: PORT, path }, r => {
      let d = ''; r.on('data', c => d += c);
      r.on('end', () => { try { resolve(JSON.parse(d)); } catch (e) { reject(e); } });
    }).on('error', reject);
  });
}
const sleep = ms => new Promise(r => setTimeout(r, ms));

const PAGES = [
  ['概览', 'admin/status/details'],
  ['蜂窝', 'admin/status/cellular'],
  ['设备', 'admin/status/device'],
  ['短信', 'admin/status/sms'],
  ['终端', 'admin/status/terminal'],
  ['Docker', 'admin/docker'],
];

(async () => {
  const list = await getJson('/json/list');
  const page = list.find(t => t.type === 'page');
  const ws = new WebSocket(page.webSocketDebuggerUrl);
  let seq = 0; const pending = new Map();
  ws.onmessage = ev => { const m = JSON.parse(ev.data); if (m.id && pending.has(m.id)) { pending.get(m.id)(m.result); pending.delete(m.id); } };
  const send = (m, p = {}) => new Promise(res => { const id = ++seq; pending.set(id, res); ws.send(JSON.stringify({ id, method: m, params: p })); });
  await new Promise(r => { ws.onopen = r; });
  await send('Page.enable'); await send('Runtime.enable');

  await send('Page.navigate', { url: 'http://192.168.66.1:8080/' });
  await sleep(3500);
  const need = await send('Runtime.evaluate', { expression: '!!document.querySelector("input[type=password]")', returnByValue: true });
  if (need.result.value) {
    await send('Runtime.evaluate', {
      expression: `(function(){var p=document.querySelector('input[type=password]');p.value='admin';
        p.dispatchEvent(new Event('input',{bubbles:true}));
        var u=document.querySelector('input[name=luci_username]');if(u){u.value='root';}
        var f=p.closest('form')||document.forms[0];if(f.requestSubmit)f.requestSubmit();else f.submit();return 1;})()`,
      returnByValue: true
    });
    await sleep(4500);
  }

  for (const [label, path] of PAGES) {
    await send('Page.navigate', { url: 'http://192.168.66.1:8080/cgi-bin/luci/' + path });
    await sleep(2500);
    const r = await send('Runtime.evaluate', {
      expression: `(function(){
        var t = document.title || '';
        var body = (document.body ? document.body.innerText : '');
        var bad = /Failed to execute template|runtime error|No page is registered|500 Internal/.test(body);
        return t + ' | len=' + body.length + ' | bad=' + bad;
      })()`, returnByValue: true
    });
    console.log('  ' + label + '  ' + r.result.value);
  }
  ws.close(); process.exit(0);
})().catch(e => { console.error('ERR', e.message); process.exit(1); });
