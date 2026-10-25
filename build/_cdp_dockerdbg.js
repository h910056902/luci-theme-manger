const http = require('http');
const PORT = 9226;

function getJson(path) {
  return new Promise((resolve, reject) => {
    http.get({ host: '127.0.0.1', port: PORT, path }, r => {
      let d = ''; r.on('data', c => d += c);
      r.on('end', () => { try { resolve(JSON.parse(d)); } catch (e) { reject(e); } });
    }).on('error', reject);
  });
}
const sleep = ms => new Promise(r => setTimeout(r, ms));

(async () => {
  const list = await getJson('/json/list');
  const page = list.find(t => t.type === 'page');
  const ws = new WebSocket(page.webSocketDebuggerUrl);
  let seq = 0; const pending = new Map();
  ws.onmessage = ev => { const m = JSON.parse(ev.data); if (m.id && pending.has(m.id)) { pending.get(m.id)(m.result); pending.delete(m.id); } };
  const send = (m, p = {}) => new Promise(res => { const id = ++seq; pending.set(id, res); ws.send(JSON.stringify({ id, method: m, params: p })); });
  await new Promise(r => { ws.onopen = r; });
  await send('Page.enable'); await send('Runtime.enable');

  console.log('[1] 打开面板并登录');
  await send('Page.navigate', { url: 'http://192.168.66.1:8080/' });
  await sleep(3500);
  const needLogin = await send('Runtime.evaluate', { expression: '!!document.querySelector("input[type=password]")', returnByValue: true });
  if (needLogin.result.value) {
    await send('Runtime.evaluate', {
      expression: `(function(){var p=document.querySelector('input[type=password]');p.value='admin';
        p.dispatchEvent(new Event('input',{bubbles:true}));
        var u=document.querySelector('input[name=luci_username]');if(u){u.value='root';}
        var f=p.closest('form')||document.forms[0];if(f.requestSubmit)f.requestSubmit();else f.submit();return 'ok';})()`,
      returnByValue: true
    });
    await sleep(5000);
  }
  let t = await send('Runtime.evaluate', { expression: 'location.href', returnByValue: true });
  console.log('    当前:', t.result.value);

  console.log('[2] 打开 Docker 页');
  await send('Page.navigate', { url: 'http://192.168.66.1:8080/cgi-bin/luci/admin/status/docker' });
  await sleep(4000);
  t = await send('Runtime.evaluate', { expression: 'document.title + " | kd-state=" + (document.getElementById("kd-state")||{}).textContent', returnByValue: true });
  console.log('   ', t.result.value);

  console.log('[3] 直接 fetch info');
  const r = await send('Runtime.evaluate', {
    expression: `(async function(){
      try {
        var u = (typeof URL !== 'undefined' && URL) || location.pathname;
        var res = await fetch(location.pathname + '?action=docker&op=info&t=' + Date.now(), {credentials:'same-origin'});
        var txt = await res.text();
        return 'status=' + res.status + ' ctype=' + res.headers.get('content-type') + ' body=' + txt.slice(0,240);
      } catch(e) { return 'ERR ' + e; }
    })()`,
    awaitPromise: true, returnByValue: true
  });
  console.log('   ', r.result.value);

  ws.close(); process.exit(0);
})().catch(e => { console.error('ERR', e.message); process.exit(1); });
