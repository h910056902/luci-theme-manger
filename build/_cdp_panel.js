const fs = require('fs');
const http = require('http');

const PORT = Number(process.env.CDP_PORT || 9224);
const PREFIX = process.env.SHOT_PREFIX || 'panel_';
const TARGET = process.env.TARGET_URL || 'http://192.168.66.1:8080/';

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
  const ws = new WebSocket(page.webSocketDebuggerUrl);
  let seq = 0;
  const pending = new Map();
  ws.onmessage = ev => {
    const m = JSON.parse(ev.data);
    if (m.id && pending.has(m.id)) { pending.get(m.id)(m.result); pending.delete(m.id); }
  };
  const send = (method, params = {}) => new Promise(res => {
    const id = ++seq; pending.set(id, res);
    ws.send(JSON.stringify({ id, method, params }));
  });

  await new Promise(r => { ws.onopen = r; });
  await send('Page.enable');
  await send('Runtime.enable');
  await send('Emulation.setDeviceMetricsOverride', { width: 1360, height: 900, deviceScaleFactor: 1, mobile: false });

  console.log('[1] 打开', TARGET);
  await send('Page.navigate', { url: TARGET });
  await sleep(4500);

  let t = await send('Runtime.evaluate', { expression: 'document.title + " || " + location.href', returnByValue: true });
  console.log('    url/title:', t.result.value);

  const fields = await send('Runtime.evaluate', {
    expression: `JSON.stringify(Array.from(document.querySelectorAll('input')).map(i => (i.name||i.id||i.type)+':'+i.type))`,
    returnByValue: true
  });
  console.log('    表单字段:', fields.result.value);

  let shot = await send('Page.captureScreenshot', { format: 'png' });
  fs.writeFileSync(__dirname + '/' + PREFIX + 'login.png', Buffer.from(shot.data, 'base64'));

  console.log('[2] 填密码并提交');
  const fill = await send('Runtime.evaluate', {
    expression: `(function(){
      var p = document.querySelector('input[name=luci_password]') || document.querySelector('input[type=password]');
      if (!p) return 'NO_PASSWORD';
      p.value = 'admin';
      p.dispatchEvent(new Event('input',{bubbles:true}));
      var u = document.querySelector('input[name=luci_username]');
      if (u) { u.value='root'; u.dispatchEvent(new Event('input',{bubbles:true})); }
      var f = p.closest('form') || document.forms[0];
      if (!f) return 'NO_FORM';
      if (f.requestSubmit) f.requestSubmit(); else f.submit();
      return 'SUBMITTED';
    })()`, returnByValue: true
  });
  console.log('   ', fill.result.value);

  await sleep(6000);
  t = await send('Runtime.evaluate', { expression: 'document.title + " || " + location.href', returnByValue: true });
  console.log('    登录后:', t.result.value);

  const txt = await send('Runtime.evaluate', {
    expression: 'document.body.innerText.replace(/\\s+/g," ").slice(0,240)', returnByValue: true
  });
  console.log('    正文:', txt.result.value);

  shot = await send('Page.captureScreenshot', { format: 'png' });
  fs.writeFileSync(__dirname + '/' + PREFIX + 'after.png', Buffer.from(shot.data, 'base64'));
  console.log('[3] 截图:', PREFIX + 'login.png / ' + PREFIX + 'after.png');
  ws.close();
  process.exit(0);
})().catch(e => { console.error('ERR', e.message); process.exit(1); });
