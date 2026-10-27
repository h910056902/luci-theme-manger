const fs = require('fs');
const http = require('http');
const PORT = Number(process.env.CDP_PORT || 9229);

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
  await send('Emulation.setDeviceMetricsOverride', { width: 1400, height: 1100, deviceScaleFactor: 1, mobile: false });

  console.log('[1] 打开 80 端口');
  await send('Page.navigate', { url: 'http://192.168.66.1/' });
  await sleep(3500);

  const need = await send('Runtime.evaluate', { expression: '!!document.querySelector("input[type=password]")', returnByValue: true });
  if (need.result.value) {
    console.log('    需要登录，输入密码');
    await send('Runtime.evaluate', {
      expression: `(function(){
        var p=document.querySelector('input[type=password]');p.value='admin';
        p.dispatchEvent(new Event('input',{bubbles:true}));
        var u=document.querySelector('input[name=luci_username]');if(u){u.value='root';}
        var f=p.closest('form')||document.forms[0];if(f.requestSubmit)f.requestSubmit();else f.submit();return 1;})()`,
      returnByValue: true
    });
    await sleep(5000);
  }

  console.log('[2] 打开 恢复与备份 页');
  await send('Page.navigate', { url: 'http://192.168.66.1/cgi-bin/luci/admin/system/recovery' });
  await sleep(3500);

  const info = await send('Runtime.evaluate', {
    expression: `(function(){
      var t=document.title||'';
      var body=document.body?document.body.innerText:'';
      var bad=/Failed to execute|No page is registered|500 Internal/.test(body);
      var rows=document.querySelectorAll('table.kpr-tbl tbody tr').length;
      return t+' | len='+body.length+' | bad='+bad+' | tblRows='+rows+' | head='+body.replace(/\\s+/g,' ').slice(0,220);
    })()`, returnByValue: true
  });
  console.log('    ' + info.result.value);

  const shot = await send('Page.captureScreenshot', { format: 'png' });
  fs.writeFileSync(__dirname + '/verify_recovery.png', Buffer.from(shot.data, 'base64'));

  ws.close(); process.exit(0);
})().catch(e => { console.error('ERR', e.message); process.exit(1); });
