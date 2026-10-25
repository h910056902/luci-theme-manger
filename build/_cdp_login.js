const fs = require('fs');
const http = require('http');

function getJson(path) {
  return new Promise((resolve, reject) => {
    http.get({ host: '127.0.0.1', port: 9222, path }, r => {
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

  console.log('[1] 打开 http://192.168.66.1/');
  await send('Page.navigate', { url: 'http://192.168.66.1/' });
  await sleep(4000);

  let t = await send('Runtime.evaluate', { expression: 'document.title + " || " + location.href', returnByValue: true });
  console.log('    url/title:', t.result.value);

  let has = await send('Runtime.evaluate', {
    expression: '!!(document.querySelector("input[name=luci_username]")||document.querySelector("#luci_username"))',
    returnByValue: true
  });
  console.log('    登录表单存在:', has.result.value);

  let shot = await send('Page.captureScreenshot', { format: 'png' });
  fs.writeFileSync(__dirname + '/shot_login.png', Buffer.from(shot.data, 'base64'));

  console.log('[2] 填写 root/admin 并提交');
  const fill = await send('Runtime.evaluate', {
    expression: `(function(){
      var u = document.querySelector('input[name=luci_username]') || document.querySelector('#luci_username');
      var p = document.querySelector('input[name=luci_password]') || document.querySelector('#luci_password');
      if (!u || !p) return 'NO_FORM';
      u.value = 'root'; p.value = 'admin';
      var f = u.closest('form') || document.forms[0];
      if (!f) return 'NO_FORM_ELEM';
      if (f.requestSubmit) f.requestSubmit(); else f.submit();
      return 'SUBMITTED';
    })()`, returnByValue: true
  });
  console.log('   ', fill.result.value);

  await sleep(6000);

  t = await send('Runtime.evaluate', { expression: 'document.title + " || " + location.href', returnByValue: true });
  console.log('    登录后 url/title:', t.result.value);

  const stillLogin = await send('Runtime.evaluate', {
    expression: '!!document.querySelector("input[name=luci_password]")',
    returnByValue: true
  });
  console.log('    页面里还有登录框:', stillLogin.result.value);

  const txt = await send('Runtime.evaluate', {
    expression: 'document.body.innerText.replace(/\\s+/g," ").slice(0,400)',
    returnByValue: true
  });
  console.log('    正文片段:', txt.result.value);

  shot = await send('Page.captureScreenshot', { format: 'png' });
  fs.writeFileSync(__dirname + '/shot_after.png', Buffer.from(shot.data, 'base64'));
  console.log('[3] 截图已保存');
  ws.close();
  process.exit(0);
})().catch(e => { console.error('ERR', e.message); process.exit(1); });
