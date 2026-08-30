/*
 * Captures a real HAR of the application journey described in
 * docs/HAR-scenario.md by driving the installed Chrome over the DevTools
 * protocol. This produces the same artifact as DevTools -> Export HAR.
 *
 *   node tools/capture-har.js            -> docs/AsafArusi-app.har
 */
const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');
const CDP = require('chrome-remote-interface');
const { harFromMessages } = require('chrome-har');

const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const PORT = 9222;
const APP = 'http://localhost:8080/AsafArusi';
const OUT = path.join(__dirname, '..', 'docs', 'AsafArusi-app.har');

const OBSERVED = [
  'Page.loadEventFired', 'Page.domContentEventFired', 'Page.frameStartedLoading',
  'Page.frameAttached', 'Page.frameScheduledNavigation', 'Page.navigatedWithinDocument',
  'Network.requestWillBeSent', 'Network.requestWillBeSentExtraInfo',
  'Network.requestServedFromCache', 'Network.dataReceived',
  'Network.responseReceived', 'Network.responseReceivedExtraInfo',
  'Network.resourceChangedPriority', 'Network.loadingFinished', 'Network.loadingFailed',
];

const sleep = ms => new Promise(r => setTimeout(r, ms));

(async () => {
  const profile = fs.mkdtempSync('/tmp/har-chrome-');
  const chrome = spawn(CHROME, [
    `--remote-debugging-port=${PORT}`, `--user-data-dir=${profile}`,
    '--headless=new', '--no-first-run', '--no-default-browser-check',
    '--disable-gpu', '--window-size=1280,900',
  ], { stdio: 'ignore' });

  await sleep(2500);

  const client = await CDP({ port: PORT });
  const { Network, Page, Runtime } = client;
  const events = [];
  OBSERVED.forEach(name => client.on(name, params => events.push({ method: name, params })));

  await Network.enable();
  await Page.enable();
  await Network.clearBrowserCache();

  const nav = async url => { await Page.navigate({ url }); await Page.loadEventFired(); await sleep(400); };
  const evalJs = expression => Runtime.evaluate({ expression, awaitPromise: true });

  // 1-2. open the application (pulls index.jsp + css/style.css)
  await nav(`${APP}/index.jsp`);

  // 3-5. type a name and submit -> the expensive PBKDF2 request
  await evalJs(`document.querySelector('#username').value = 'Asaf';`);
  await nav(`${APP}/index.jsp?username=Asaf&greet=1`);

  // 6. follow the About link
  await nav(`${APP}/about.jsp`);

  // 7. back to the application
  await nav(`${APP}/index.jsp`);

  const har = harFromMessages(events, { includeTextFromResponseBody: true });
  har.log.creator = { name: 'Chrome DevTools Protocol', version: '1.3' };
  fs.writeFileSync(OUT, JSON.stringify(har, null, 2));

  const entries = har.log.entries.length;
  await client.close();
  chrome.kill();
  fs.rmSync(profile, { recursive: true, force: true });

  console.log(`wrote ${OUT}`);
  console.log(`${entries} entries:`);
  har.log.entries.forEach(e =>
    console.log(`  ${e.response.status} ${String(Math.round(e.time)).padStart(5)}ms  ${e.request.url}`));
})().catch(e => { console.error(e); process.exit(1); });
