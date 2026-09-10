/*
 * Deliverable (c): a screenshot of the application in Tomcat WITH THE URL VISIBLE.
 *
 * Headless Chrome has no address bar, so this drives a real visible Chrome
 * window over the DevTools protocol - genuinely typing into the input and
 * clicking Greet - and leaves it on screen for `screencapture` to photograph.
 * Its own profile and debugging port keep it away from the user's main browser.
 */
const { spawn } = require('child_process');
const fs = require('fs');
const CDP = require('chrome-remote-interface');

const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const PORT = 9422;
const APP = process.argv[2];
const sleep = ms => new Promise(r => setTimeout(r, ms));

(async () => {
  const profile = fs.mkdtempSync('/tmp/appshot-chrome-');
  const chrome = spawn(CHROME, [
    `--remote-debugging-port=${PORT}`, `--user-data-dir=${profile}`,
    '--no-first-run', '--no-default-browser-check', '--disable-features=Translate',
    '--window-position=40,60', '--window-size=1200,860', `${APP}/index.jsp`,
  ], { stdio: 'ignore', detached: true });

  await sleep(4000);
  const client = await CDP({ port: PORT });
  const { Page, Runtime, Input, DOM } = client;
  await Page.enable(); await Runtime.enable(); await DOM.enable();
  await sleep(1500);

  // Type into the name box the way a person would, so the screenshot shows a
  // real interaction rather than a URL with the parameter pasted in.
  await Runtime.evaluate({ expression: `document.querySelector('#username').focus()` });
  for (const ch of 'Asaf') {
    await Input.dispatchKeyEvent({ type: 'keyDown', text: ch });
    await Input.dispatchKeyEvent({ type: 'keyUp' });
    await sleep(120);
  }
  await sleep(400);
  await Runtime.evaluate({ expression: `document.querySelector('#greetBtn').click()` });
  await Page.loadEventFired();
  await sleep(1500);

  const { result } = await Runtime.evaluate({
    expression: `JSON.stringify({
      url: location.href,
      greeting: (document.querySelector('#result')||{}).textContent || null,
      token: (document.querySelector('#token')||{}).textContent || null
    })`, returnByValue: true });
  console.log('  page state: ' + result.value);
  console.log('  PID=' + chrome.pid + ' (left running for screencapture)');
  await client.close();
  process.exit(0);
})().catch(e => { console.error(e.message); process.exit(1); });
