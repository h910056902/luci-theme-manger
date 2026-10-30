const fs = require('fs');
const http = require('http');

const PORT = process.env.CDP_PORT || 9226;
const BASE = 'http://192.168.66.1/cgi-bin/luci';
const OCSPEED = BASE + '/admin/services/openclash/ocspeed';
const REF = BASE + '/admin/services/openclash';
const REF2 = BASE + '/admin/status/overview';

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

  async function login(url) {
    await send('Page.navigate', { url });
    await sleep(3200);
    const has = await send('Runtime.evaluate', { expression: '!!document.querySelector("input[name=luci_password]")', returnByValue: true });
    if (has.result.value) {
      console.log('[login] 需要登录');
      await send('Runtime.evaluate', {
        expression: `(function(){
          var u = document.querySelector('input[name=luci_username]');
          var p = document.querySelector('input[name=luci_password]');
          u.value = 'root'; p.value = 'admin';
          var f = u.closest('form');
          if (f.requestSubmit) f.requestSubmit(); else f.submit();
          return 'ok';
        })()`, returnByValue: true
      });
      await sleep(4500);
    }
  }

  await setViewport(1440, 900, false);

  console.log('[1] 参考页：OpenClash 概览');
  await login(REF);
  let t = await send('Runtime.evaluate', { expression: 'document.title + " | " + location.href', returnByValue: true });
  console.log('    ', t.result.value);
  const theme = await send('Runtime.evaluate', {
    expression: `(function(){
      function cs(sel, props){
        var n = document.querySelector(sel); if(!n) return null;
        var s = getComputedStyle(n); var o = {};
        props.forEach(function(p){ o[p] = s[p]; });
        return o;
      }
      return {
        body: cs('body', ['backgroundColor','color','fontFamily','fontSize']),
        content: cs('#maincontent, .main-right, .content', ['backgroundColor','padding']),
        panel: cs('.cbi-section, .panel, .card', ['backgroundColor','borderColor','borderRadius','boxShadow','borderWidth']),
        h2: cs('h2, .cbi-section legend, .panel-heading', ['color','fontSize','fontWeight']),
        btn: cs('.cbi-button, .btn', ['backgroundColor','color','borderRadius','borderColor','fontSize','padding']),
        table: cs('table', ['backgroundColor','borderColor','fontSize']),
        a: cs('a', ['color'])
      };
    })()`, returnByValue: true
  });
  console.log('[2] 主题计算样式:', JSON.stringify(theme.result.value, null, 1));
  let shot = await send('Page.captureScreenshot', { format: 'png' });
  fs.writeFileSync(__dirname + '/shot_oc_ref.png', Buffer.from(shot.data, 'base64'));

  console.log('[3] 自动测速页');
  await send('Page.navigate', { url: OCSPEED });
  await sleep(4000);
  t = await send('Runtime.evaluate', { expression: 'document.title + " | " + location.href', returnByValue: true });
  console.log('    ', t.result.value);
  const own = await send('Runtime.evaluate', {
    expression: `(function(){
      function cs(sel, props){
        var n = document.querySelector(sel); if(!n) return null;
        var s = getComputedStyle(n); var o = {};
        props.forEach(function(p){ o[p] = s[p]; });
        return o;
      }
      return {
        body: cs('body', ['backgroundColor','color','fontSize']),
        wrap: cs('.ocspeed-body', ['backgroundColor','color','padding','maxWidth']),
        card: cs('.ocspeed-body .card, .ocspeed-body .oc-card, .ocspeed-body section', ['backgroundColor','borderColor','borderRadius']),
        textLen: (document.querySelector('.ocspeed-body')||{innerText:''}).innerText.length,
        shellDark: (function(){var b=getComputedStyle(document.body).backgroundColor;return b;})()
      };
    })()`, returnByValue: true
  });
  console.log('[4] 测速页计算样式:', JSON.stringify(own.result.value, null, 1));
  shot = await send('Page.captureScreenshot', { format: 'png' });
  fs.writeFileSync(__dirname + '/shot_oc_before.png', Buffer.from(shot.data, 'base64'));
  console.log('[5] 截图已保存: shot_oc_ref.png / shot_oc_before.png');
  ws.close();
  process.exit(0);
})().catch(e => { console.error('ERR', e.message); process.exit(1); });
