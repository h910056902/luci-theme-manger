const fs = require('fs');
const http = require('http');

const PORT = process.env.CDP_PORT || 9225;
const URLS = {
  network: 'http://192.168.66.1:8080/cgi-bin/luci/admin/network_guide/network',
};

function getJson(path) {
  return new Promise((resolve, reject) => {
    http.get({ host: '127.0.0.1', port: PORT, path }, r => {
      let d = '';
      r.on('data', c => d += c);
      r.on('end', () => { try { resolve(JSON.parse(d)); } catch (e) { reject(new Error('bad json: ' + d.slice(0, 120))); } });
    }).on('error', reject);
  });
}
const sleep = ms => new Promise(r => setTimeout(r, ms));

(async () => {
  let list = await getJson('/json/list');
  let page = list.find(t => t.type === 'page');
  if (!page) {
    try { await getJson('/json/new?about:blank'); } catch (e) {}
    await sleep(600);
    list = await getJson('/json/list');
    page = list.find(t => t.type === 'page');
  }
  if (!page) throw new Error('no page target');

  const ws = new WebSocket(page.webSocketDebuggerUrl);
  let seq = 0;
  const pending = new Map();
  ws.onmessage = ev => {
    const m = JSON.parse(ev.data);
    if (m.id && pending.has(m.id)) { pending.get(m.id)(m.result); pending.delete(m.id); }
  };
  const send = (method, params = {}) => new Promise(res => {
    const id = ++seq;
    pending.set(id, res);
    ws.send(JSON.stringify({ id, method, params }));
  });
  await new Promise(r => { ws.onopen = r; });
  await send('Page.enable');
  await send('Runtime.enable');
  const setViewport = (w, h, mobile) => send('Emulation.setDeviceMetricsOverride', { width: w, height: h, deviceScaleFactor: 1, mobile });

  console.log('[1] 打开设置向导');
  await setViewport(1440, 900, false);
  await send('Page.navigate', { url: URLS.network });
  await sleep(3500);

  const hasLogin = await send('Runtime.evaluate', { expression: '!!document.querySelector("input[name=luci_password]")', returnByValue: true });
  if (hasLogin.result.value) {
    console.log('[2] 登录');
    await send('Runtime.evaluate', {
      expression: `(function(){
        var u = document.querySelector('input[name=luci_username]');
        var p = document.querySelector('input[name=luci_password]');
        u.value = 'root'; p.value = 'admin';
        var f = u.closest('form');
        if (f.requestSubmit) f.requestSubmit(); else f.submit();
        return 'SUBMITTED';
      })()`, returnByValue: true
    });
    await sleep(5000);
  }

  const info = await send('Runtime.evaluate', {
    expression: `(function(){
      return {
        url: location.href,
        title: document.title,
        appHtmlLen: (document.getElementById('app')||{innerHTML:''}).innerHTML.length,
        text: document.body.innerText.replace(/\\s+/g,' ').slice(0, 900),
        inputs: Array.prototype.map.call(document.querySelectorAll('#app input, #app select'), function(n){return (n.tagName+'['+(n.type||'')+'] '+(n.placeholder||n.name||''))}).slice(0,20),
        buttons: Array.prototype.map.call(document.querySelectorAll('#app button, #app .btn, #app a'), function(n){return n.textContent.trim().slice(0,18)}).filter(Boolean).slice(0,25)
      };
    })()`, returnByValue: true
  });
  console.log('[3] 页面信息:', JSON.stringify(info.result.value, null, 1));

  let shot = await send('Page.captureScreenshot', { format: 'png' });
  fs.writeFileSync(__dirname + '/shot_wizard_1.png', Buffer.from(shot.data, 'base64'));
  console.log('[4] 向导截图已保存');
  ws.close();
  process.exit(0);
})().catch(e => { console.error('ERR', e.message); process.exit(1); });
