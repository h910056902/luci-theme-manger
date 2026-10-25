const fs = require('fs');
const http = require('http');

const PORT = Number(process.env.CDP_PORT || 9225);

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

const CASES = [
  {
    name: 'docker_page',
    start: 'http://192.168.66.1:8080/',
    after: 'http://192.168.66.1:8080/cgi-bin/luci/admin/docker',
    shot: 'verify_docker.png'
  }
];

(async () => {
  const list = await getJson('/json/list');
  const page = list.find(t => t.type === 'page');
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
  await send('Emulation.setDeviceMetricsOverride', { width: 1400, height: 900, deviceScaleFactor: 1, mobile: false });

  for (const c of CASES) {
    console.log('===== ' + c.name + ' =====');
    await send('Page.navigate', { url: c.start });
    await sleep(4000);

    let t = await send('Runtime.evaluate', { expression: 'location.href + " | " + document.title', returnByValue: true });
    console.log('  打开: ' + t.result.value);

    const needLogin = await send('Runtime.evaluate', {
      expression: '!!document.querySelector("input[type=password]")', returnByValue: true
    });

    if (needLogin.result.value) {
      console.log('  检测到登录框，执行登录');
      const r = await send('Runtime.evaluate', {
        expression: `(function(){
          var p = document.querySelector('input[type=password]');
          if (!p) return 'NO_PWD';
          p.value='admin';
          p.dispatchEvent(new Event('input',{bubbles:true}));
          var u = document.querySelector('input[name=luci_username]');
          if (u) { u.value='root'; u.dispatchEvent(new Event('input',{bubbles:true})); }
          var f = p.closest('form') || document.forms[0];
          if (!f) return 'NO_FORM';
          if (f.requestSubmit) f.requestSubmit(); else f.submit();
          return 'SUBMITTED';
        })()`, returnByValue: true
      });
      console.log('  ' + r.result.value);
      await sleep(6000);
    } else {
      console.log('  无需登录（已带会话）');
    }

    await send('Page.navigate', { url: c.after });
    await sleep(5000);

    t = await send('Runtime.evaluate', { expression: 'location.href + " | " + document.title', returnByValue: true });
    console.log('  结果页: ' + t.result.value);

    const still = await send('Runtime.evaluate', {
      expression: '!!document.querySelector("input[type=password]")', returnByValue: true
    });
    console.log('  仍有登录框: ' + still.result.value);

    const txt = await send('Runtime.evaluate', {
      expression: 'document.body.innerText.replace(/\\s+/g," ").slice(0,260)', returnByValue: true
    });
    console.log('  正文: ' + txt.result.value);

    const shot = await send('Page.captureScreenshot', { format: 'png' });
    fs.writeFileSync(__dirname + '/' + c.shot, Buffer.from(shot.data, 'base64'));
    console.log('  截图: ' + c.shot);
    console.log('');
  }

  ws.close();
  process.exit(0);
})().catch(e => { console.error('ERR', e.message); process.exit(1); });
