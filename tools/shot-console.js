/*
 * Screenshots the Gatling summary out of a Jenkins console page - the part the
 * brief asks to see. Two things make the naive approach fail:
 *
 *   - plain --screenshot always captures the top of the page, which here is the
 *     git checkout, not the results;
 *   - the whole stage output lives inside one <span> tens of thousands of pixels
 *     tall, so that element's bounding box says nothing about where the summary
 *     text actually sits. A Range around the text node is needed instead.
 *
 * So: locate the text with a Range, then capture a clip in absolute page
 * coordinates with captureBeyondViewport, which needs no scrolling at all.
 *
 *   node tools/shot-console.js <jobName> <buildNo> <outFile> [markerText]
 */
const { spawn } = require('child_process');
const fs = require('fs');
const CDP = require('chrome-remote-interface');

const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const PORT = 9333;
const [job, build, out, marker = 'Global Information'] = process.argv.slice(2);
const WIDTH = 2100, HEIGHT = 1150;
const sleep = ms => new Promise(r => setTimeout(r, ms));

(async () => {
  const profile = fs.mkdtempSync('/tmp/shot-chrome-');
  const chrome = spawn(CHROME, [
    `--remote-debugging-port=${PORT}`, `--user-data-dir=${profile}`,
    '--headless=new', '--no-first-run', '--no-default-browser-check',
    '--disable-gpu', '--hide-scrollbars', `--window-size=${WIDTH},${HEIGHT}`,
  ], { stdio: 'ignore' });
  await sleep(2500);

  const client = await CDP({ port: PORT });
  const { Page, Runtime, Emulation } = client;
  await Page.enable();
  await Runtime.enable();
  await Emulation.setDeviceMetricsOverride({
    width: WIDTH, height: HEIGHT, deviceScaleFactor: 2, mobile: false,
  });

  await Page.navigate({ url: `http://localhost:8081/job/${job}/${build}/console` });
  await Page.loadEventFired();
  await sleep(6000);

  const { result } = await Runtime.evaluate({
    expression: `
      (() => {
        const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT);
        let n;
        while ((n = walker.nextNode())) {
          const i = n.nodeValue.indexOf(${JSON.stringify(marker)});
          if (i < 0) continue;
          const r = document.createRange();
          r.setStart(n, i);
          r.setEnd(n, i + ${JSON.stringify(marker)}.length);
          const box = r.getBoundingClientRect();
          return JSON.stringify({ y: Math.round(box.top + window.scrollY) });
        }
        return JSON.stringify({ y: null });
      })()
    `, returnByValue: true,
  });
  const { y } = JSON.parse(result.value);
  if (y === null) throw new Error(`marker "${marker}" not found in ${job}`);
  console.log(`  ${job}: "${marker}" at y=${y}`);

  const { data } = await Page.captureScreenshot({
    format: 'png',
    captureBeyondViewport: true,
    clip: { x: 0, y: Math.max(0, y - 90), width: WIDTH, height: HEIGHT, scale: 1 },
  });
  fs.writeFileSync(out, Buffer.from(data, 'base64'));

  await client.close();
  chrome.kill();
  await sleep(800);
  try { fs.rmSync(profile, { recursive: true, force: true, maxRetries: 5, retryDelay: 300 }); } catch {}
  console.log(`  wrote ${out} (${fs.statSync(out).size} bytes)`);
})().catch(e => { console.error(e.message); process.exit(1); });
