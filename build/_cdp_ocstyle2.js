const fs = require('fs');
const http = require('http');
const PORT = process.env.CDP_PORT || 9227;
const REF = 'http://192.168.66.1/cgi-bin/luci/admin/services/openclash';

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
  await send('Page.navigate', { url: REF }); await sleep(3500);
  const has = await send('Runtime.evaluate', { expression: '!!document.querySelector("input[name=luci_password]")', returnByValue: true });
  if (has.result.value) {
    await send('Runtime.evaluate', { expression: `(function(){var u=document.querySelector('input[name=luci_username]');var p=document.querySelector('input[name=luci_password]');u.value='root';p.value='admin';(u.closest('form')||document.forms[0]).submit();return 1})()`, returnByValue: true });
    await sleep(4500);
  }
  const info = await send('Runtime.evaluate', {
    expression: `(function(){
      var out = { cards: [], buttons: [], header: null, tabs: [] };
      function sig(n){
        var s = getComputedStyle(n);
        return { cls: (n.className||'').toString().slice(0,40), bg: s.backgroundColor, bd: s.borderColor, bw: s.borderWidth, r: s.borderRadius, pad: s.padding, fs: s.fontSize, col: s.color, w: Math.round(n.getBoundingClientRect().width), h: Math.round(n.getBoundingClientRect().height) };
      }
      var seen = {};
      document.querySelectorAll('div,section').forEach(function(n){
        var s = getComputedStyle(n);
        var bg = s.backgroundColor;
        if (!bg || bg === 'rgba(0, 0, 0, 0)') return;
        var key = bg + '|' + s.borderRadius;
        if (seen[key]) return; seen[key] = 1;
        var r = n.getBoundingClientRect();
        if (r.width < 120 || r.height < 40) return;
        out.cards.push(sig(n));
      });
      document.querySelectorAll('button, .btn, input[type=button], .cbi-button').forEach(function(n){
        var s = getComputedStyle(n);
        if (s.backgroundColor === 'rgba(0, 0, 0, 0)') return;
        out.buttons.push(sig(n));
      });
      var hdr = document.querySelector('.openclash-header, #maincontent h2, .cbi-map h2');
      if (hdr) out.header = sig(hdr);
      return out;
    })()`, returnByValue: true
  });
  console.log(JSON.stringify(info.result.value, null, 1).slice(0, 4000));
  ws.close(); process.exit(0);
})().catch(e => { console.error('ERR', e.message); process.exit(1); });
