const fs = require('fs');
const http = require('http');

const PORT = Number(process.env.CDP_PORT || 9222);
const PREFIX = process.env.SHOT_PREFIX || 'shot_';

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
    await sleep(500);
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
  await send('Emulation.setDeviceMetricsOverride', { width: 1280, height: 900, deviceScaleFactor: 1, mobile: false });

  const ua = await send('Browser.getVersion');
  console.log('[UA]', ua.product + '  ' + ua.userAgent);

  console.log('[1] 打开 http://192.168.66.1/');
  await send('Page.navigate', { url: 'http://192.168.66.1/' });
  await sleep(4000);

  let t = await send('Runtime.evaluate', { expression: 'document.title + " || " + location.href', returnByValue: true });
  console.log('    url/title:', t.result.value);

  let has = await send('Runtime.evaluate', {
    expression: '!!(document.querySelector("input[name=luci_password]")||document.querySelector("#luci_password"))',
    returnByValue: true
  });
  console.log('    密码框存在:', has.result.value);

  let shot = await send('Page.captureScreenshot', { format: 'png' });
  fs.writeFileSync(__dirname + '/' + PREFIX + 'login.png', Buffer.from(shot.data, 'base64'));

  console.log('[2] 输入密码 admin 并提交');
  const fill = await send('Runtime.evaluate', {
    expression: `(function(){
      var p = document.querySelector('input[name=luci_password]') || document.querySelector('#luci_password');
      if (!p) return 'NO_PASSWORD_FIELD';
      p.value = 'admin';
      p.dispatchEvent(new Event('input', {bubbles:true}));
      var u = document.querySelector('input[name=luci_username]') || document.querySelector('#luci_username');
      if (u) { u.value = 'root'; u.dispatchEvent(new Event('input', {bubbles:true})); }
      var f = p.closest('form') || document.forms[0];
      if (!f) return 'NO_FORM';
      if (f.requestSubmit) f.requestSubmit(); else f.submit();
      return 'SUBMITTED' + (u ? '(with-user)' : '(password-only)');
    })()`, returnByValue: true
  });
  console.log('   ', fill.result.value);

  await sleep(6000);

  t = await send('Runtime.evaluate', { expression: 'document.title + " || " + location.href', returnByValue: true });
  console.log('    登录后 url/title:', t.result.value);

  const still = await send('Runtime.evaluate', {
    expression: '!!document.querySelector("input[name=luci_password]")',
    returnByValue: true
  });
  console.log('    仍有登录框:', still.result.value);

  const txt = await send('Runtime.evaluate', {
    expression: 'document.body.innerText.replace(/\\s+/g," ").slice(0,300)',
    returnByValue: true
  });
  console.log('    正文:', txt.result.value);

  shot = await send('Page.captureScreenshot', { format: 'png' });
  fs.writeFileSync(__dirname + '/' + PREFIX + 'after.png', Buffer.from(shot.data, 'base64'));
  console.log('[3] 截图已保存:', PREFIX + 'login.png / ' + PREFIX + 'after.png');
  ws.close();
  process.exit(0);
})().catch(e => { console.error('ERR', e.message); process.exit(1); });
