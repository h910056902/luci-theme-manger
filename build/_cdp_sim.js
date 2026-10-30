const fs = require('fs');
const http = require('http');

const PORT = process.env.CDP_PORT || 9223;
const URL8080 = 'http://192.168.66.1:8080/cgi-bin/luci/admin/status/details';

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

  console.log('[1] 打开 8080 驾驶舱页');
  await setViewport(1440, 900, false);
  await send('Page.navigate', { url: URL8080 });
  await sleep(3500);

  let t = await send('Runtime.evaluate', { expression: 'document.title + " || " + location.href', returnByValue: true });
  console.log('    url/title:', t.result.value);

  const hasLogin = await send('Runtime.evaluate', { expression: '!!document.querySelector("input[name=luci_password]")', returnByValue: true });
  if (hasLogin.result.value) {
    console.log('[2] 需要登录，填写 root/admin');
    await send('Runtime.evaluate', {
      expression: `(function(){
        var u = document.querySelector('input[name=luci_username]');
        var p = document.querySelector('input[name=luci_password]');
        if (!u || !p) return 'NO_FORM';
        u.value = 'root'; p.value = 'admin';
        var f = u.closest('form');
        if (f.requestSubmit) f.requestSubmit(); else f.submit();
        return 'SUBMITTED';
      })()`, returnByValue: true
    });
    await sleep(5000);
    t = await send('Runtime.evaluate', { expression: 'document.title + " || " + location.href', returnByValue: true });
    console.log('    登录后:', t.result.value);
  }

  const check = await send('Runtime.evaluate', {
    expression: `(function(){
      function q(s){return !!document.querySelector(s)}
      function txt(s){var n=document.querySelector(s);return n?n.textContent.trim():'(none)'}
      var hero = document.querySelector('.hero-sig');
      return {
        hero: q('.hero-sig'),
        op: txt('[data-nradio-hero="op"]'),
        status: txt('[data-nradio-hero="status"]'),
        badge: txt('[data-nradio-hero="badge"]'),
        more: q('.h-more'),
        moreHref: (document.querySelector('.h-more')||{}).href || '(none)',
        temp: txt('[data-nradio-temp]'),
        tempVisible: (function(){var n=document.querySelector('[data-nradio-temp]');return n?getComputedStyle(n).display!=='none':'(none)'})(),
        line2: q('[data-nradio-line2]'),
        line2op: txt('[data-nradio-line2="op"]'),
        line2ip: txt('[data-nradio-line2="ip"]'),
        dft: q('.h-l2-dft'),
        guide: q('[data-nradio-guide]'),
        isNone: hero ? hero.className.indexOf('is-none')>=0 : null,
        cssV2: q('link[href*="mwrt-home-custom.css?v=2"]')
      };
    })()`, returnByValue: true
  });
  console.log('[3] 卡片检查:', JSON.stringify(check.result.value, null, 1));

  let shot = await send('Page.captureScreenshot', { format: 'png' });
  fs.writeFileSync(__dirname + '/shot_sim_desktop.png', Buffer.from(shot.data, 'base64'));
  console.log('[4] 桌面截图已保存');

  await setViewport(390, 844, true);
  await sleep(1200);
  shot = await send('Page.captureScreenshot', { format: 'png' });
  fs.writeFileSync(__dirname + '/shot_sim_mobile.png', Buffer.from(shot.data, 'base64'));
  console.log('[5] 移动端截图已保存');

  ws.close();
  process.exit(0);
})().catch(e => { console.error('ERR', e.message); process.exit(1); });
