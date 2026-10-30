const fs = require('fs');
const http = require('http');
const PORT = process.env.CDP_PORT || 9228;
const OC = 'http://192.168.66.1/cgi-bin/luci/admin/services/openclash/ocspeed';

function getJson(path) {
  return new Promise((resolve, reject) => {
    http.get({ host: '127.0.0.1', port: PORT, path }, r => {
      let d = '';
      r.on('data', c => d += c);
      r.on('end', () => { try { resolve(JSON.parse(d)); } catch (e) { reject(new Error('bad json')); } });
    }).on('error', reject);
  });
}
const sleep = ms => new Promise(r => setTimeout(r, ms));

(async () => {
  let list = await getJson('/json/list');
  let page = list.find(t => t.type === 'page');
  if (!page) { try { await getJson('/json/new?about:blank'); } catch (e) {} await sleep(600); list = await getJson('/json/list'); page = list.find(t => t.type === 'page'); }
  const ws = new WebSocket(page.webSocketDebuggerUrl);
  let seq = 0; const pending = new Map();
  ws.onmessage = ev => { const m = JSON.parse(ev.data); if (m.id && pending.has(m.id)) { pending.get(m.id)(m.result); pending.delete(m.id); } };
  const send = (m, p = {}) => new Promise(res => { const id = ++seq; pending.set(id, res); ws.send(JSON.stringify({ id, method: m, params: p })); });
  await new Promise(r => { ws.onopen = r; });
  await send('Page.enable'); await send('Runtime.enable');
  await send('Emulation.setDeviceMetricsOverride', { width: 1440, height: 900, deviceScaleFactor: 1, mobile: false });
  await send('Page.navigate', { url: OC }); await sleep(3200);
  const has = await send('Runtime.evaluate', { expression: '!!document.querySelector("input[name=luci_password]")', returnByValue: true });
  if (has.result.value) {
    await send('Runtime.evaluate', { expression: `(function(){var u=document.querySelector('input[name=luci_username]');var p=document.querySelector('input[name=luci_password]');u.value='root';p.value='admin';(u.closest('form')||document.forms[0]).submit();return 1})()`, returnByValue: true });
    await sleep(4500);
    await send('Page.navigate', { url: OC }); await sleep(3500);
  }
  const own = await send('Runtime.evaluate', {
    expression: `(function(){
      function cs(sel, props){var n=document.querySelector(sel);if(!n)return null;var s=getComputedStyle(n);var o={};props.forEach(function(p){o[p]=s[p]});return o;}
      return {
        wrap: cs('.ocspeed-body', ['backgroundColor','borderRadius','maxWidth','padding','color','fontFamily']),
        card: cs('.ocspeed-body .card', ['backgroundColor','borderColor','borderRadius','padding']),
        h1: cs('.ocspeed-body h1', ['fontSize','fontWeight','color']),
        big: cs('.ocspeed-body .card .big', ['fontSize']),
        btn: cs('.ocspeed-body button', ['backgroundColor','borderColor','borderRadius','color','fontSize'])
      };
    })()`, returnByValue: true
  });
  console.log(JSON.stringify(own.result.value, null, 1));
  let shot = await send('Page.captureScreenshot', { format: 'png' });
  fs.writeFileSync(__dirname + '/shot_oc_after.png', Buffer.from(shot.data, 'base64'));
  await send('Emulation.setDeviceMetricsOverride', { width: 390, height: 844, deviceScaleFactor: 1, mobile: true });
  await sleep(1200);
  shot = await send('Page.captureScreenshot', { format: 'png' });
  fs.writeFileSync(__dirname + '/shot_oc_after_mobile.png', Buffer.from(shot.data, 'base64'));
  console.log('saved shot_oc_after.png / shot_oc_after_mobile.png');
  ws.close(); process.exit(0);
})().catch(e => { console.error('ERR', e.message); process.exit(1); });
