# Deliverable (h) - the HAR scenario, in words

The HAR file (`docs/HIT-DevOps-app.har`) is a recording of one complete user
journey through the application, captured with Chrome DevTools -> Network ->
Preserve log -> Export HAR.

## The scenario, step by step

1. **Navigate** to `http://localhost:8080/AsafArusi-OmerLevi-MaorDanny/index.jsp`
   The browser requests the JSP, then the stylesheet it references
   (`css/style.css`). Two requests, one of them the HTML document.
2. **Click** into the "Your name" text box (`#username`).
3. **Type** `Asaf`.
4. **Click** the **Greet** button (`#greetBtn`).
   The form submits by GET, so this is a request to
   `index.jsp?username=Asaf&greet=1`. This is the expensive request: the server
   derives a session token with PBKDF2 before it can render the page.
5. **Read** the greeting `Hello, Asaf!` that appears in `#result`.
6. **Click** the **About this deployment** link (`#aboutLink`).
   Requests `about.jsp`, plus the stylesheet again (served from cache on a warm
   load - visible in the HAR as a 304 or a "from disk cache" entry).
7. **Click** **Back to the application** (`#homeLink`) to return to `index.jsp`.

## What the recording shows

The six entries and their timings, straight from the capture:

| # | request | time |
|---|---|---:|
| 1 | `index.jsp` | 1 ms |
| 2 | `css/style.css` | 1 ms |
| 3 | `favicon.ico` | 4 ms |
| 4 | `index.jsp?username=Asaf&greet=1` | **39 ms** |
| 5 | `about.jsp` | 1 ms |
| 6 | `index.jsp` (back) | 1 ms |

The greet request costs roughly forty times the others. That is the PBKDF2 key
derivation running server-side, and it is visible in the HAR before any load
test is involved - the recording and the performance results are describing the
same thing.

## Why this scenario

It touches every element the brief required - the link, the button and the
input text box - and it separates cheap requests from the expensive one. That
separation is what makes the performance results readable: in every Gatling
report, requests 01, 02 and 04 stay flat while request 03 ("Submit name") is
the one that degrades under load.

## How it connects to the load tests

The same journey is encoded in `gatling/simulations/BaseScenario.java`, so the
max-limit, load and stress runs replay exactly what the browser did rather than
a request invented for the test. Gatling can also import a HAR directly, via
`./mvnw gatling:recorder` in HAR mode, which is how the scenario was checked
against the recording.
