# Deliverables (j) and (l) - performance analysis

All three runs were executed **by Jenkins jobs**, not from a terminal:
`AsafArusi-04-gatling-max-limit`, `AsafArusi-05-gatling-load-3min` and
`AsafArusi-06-gatling-stress-3min`. Console output is in
`docs/gatling-console-*.txt`, the exported reports in `docs/reports/`.

## Summary

| | |
|---|---|
| **Max limit** | **375 users/sec (~1,250 requests/sec)** |
| How it was found | Independent constant-rate runs on a warm JVM, raising the rate until the response-time budget broke |
| What defines the limit | The highest rate serving every request with zero failures and p95 of 23 ms |
| Where it breaks | 400 users/sec - p95 goes from 23 ms to 16,142 ms and throughput *falls* |
| Test bed | MacBook, 10 cores, Tomcat 9.0.121, Gatling 3.13.5, load generator on the same machine |

## (j) The max limit, and how I found it

A max limit is a search, not a single measurement. I ran the same journey at
increasing constant arrival rates, each held for 45 seconds on an already-warm
server, and recorded **p95 response time**, **error count** and **throughput**
at each level. Mean response time is deliberately not the signal - it hides the
tail, and the tail is what users actually experience.

| users/sec | requests | failures | p95 | p99 | throughput | under 800 ms |
|---:|---:|---:|---:|---:|---:|---:|
| 175 | 36,780 | 0 | 13 ms | 24 ms | 584 req/s | 100% |
| 200 | 42,028 | 0 | 13 ms | 14 ms | 667 req/s | 100% |
| 225 | 47,280 | 0 | 13 ms | 14 ms | 750 req/s | 100% |
| 250 | 52,528 | 0 | 14 ms | 15 ms | 834 req/s | 100% |
| 300 | 63,028 | 0 | 16 ms | 17 ms | 1,000 req/s | 100% |
| 350 | 73,528 | 0 | 23 ms | 217 ms | 1,167 req/s | 100% |
| **375** | **78,780** | **0** | **23 ms** | **35 ms** | **1,250 req/s** | **100%** |
| 400 | 84,028 | 2,947 | 16,142 ms | 18,300 ms | 857 req/s | 39.1% |
| 450 | 94,528 | 1,470 | 12,801 ms | 19,753 ms | 1,006 req/s | 45.0% |

**375 users/sec is the limit.** It is the highest level where every one of
78,780 requests was served, none failed, and p95 stayed at 23 ms.

The argument is in the two columns either side of it. Up to 375, **throughput
rises exactly in step with the arrival rate** - 584, 667, 750, 834, 1,000,
1,167, 1,250 - and latency barely moves. The journey issues four requests, and
1,250 / 375 is almost exactly 3.3, so the server is absorbing everything sent
to it.

At 400 that stops. Throughput does not merely flatten, it **falls to 857
req/sec** - *below* what the same server sustained at 350. p95 rises by a
factor of 700. Getting 6.7% more load produced 32% less useful work.

That is the distinction worth making: this is not saturation, it is
**congestion collapse**. A saturated server plateaus - extra arrivals queue and
throughput holds at the ceiling. A collapsing one spends its capacity on work
that never completes: connections waiting in the accept queue until the client
gives up, so the CPU is busy while goodput drops. 450 users/sec confirms it -
still broken, still worse than 350.

**Failures appear only at the collapse, not before it.** At 350 the p99 of
217 ms is the first hint of strain while p95 is still 23 ms - a small number of
requests waiting behind a busy worker. Nothing fails. That is why a status-code
monitor is not enough, and why the monitor in this project checks response time
too.

## The stepped ramp reports a different number, and that is not a contradiction

The Jenkins max-limit job runs a *staircase*: twelve 20-second levels from 50 to
325 users/sec. Read per level, it looks like the app breaks at 225:

| level | 50-200/sec | 225 | 250 | 275 | 300 | 325 |
|---|---|---|---|---|---|---|
| p95 | 12-14 ms | 296 ms | 654 ms | 531 ms | 19 ms | 114 ms |
| active users | tracks arrivals | 720 | 942 | 1,209 | 903 | 1,004 |

Two different things are being measured.

**In a staircase, each level inherits the backlog of the one before it.** The
active-user count gives it away: through 200/sec it tracks arrivals exactly
(144, 226, 301, 376, 452, 527, 602 - about three seconds of arrivals in flight,
which is the journey's own think time). From 225 it detaches and climbs to
1,209. Users are accumulating faster than they finish, so each level starts
already behind. The staircase measures *how the system degrades under a rising
load*, which is a real and useful thing to know - but it is not the steady-state
capacity.

**The last two levels are an artefact of the harness, not a recovery.** p95
drops back to 19 ms at a nominal 300/sec, which is impossible if the server were
genuinely overloaded. What actually happened is that Gatling - running on the
same laptop, already managing 2,000+ in-flight users - could not create new ones
fast enough, so the real arrival rate fell below the nominal one and the backlog
drained. This is the clearest single illustration in the whole exercise of the
tip in the brief: **the graphs reflect what really happened, not what the script
said.** The script said 300 users/sec. The system delivered fewer.

So: **375/sec is the capacity figure**, measured the way capacity should be
measured. The staircase is kept because it shows the shape of the degradation
and, unintentionally, the limits of the measuring instrument.

## The three submitted runs

| | Max limit (50-325 ramp) | Load (225/sec, 3 min) | Stress (750/sec, 3 min) |
|---|---:|---:|---:|
| requests | 221,228 | 168,780 | 480,080 |
| failures | **0** | **0** | **340,735 (70.97%)** |
| mean | 81 ms | **7 ms** | 14,029 ms |
| p95 | 747 ms | **29 ms** | 28,436 ms |
| p99 | 2,654 ms | **55 ms** | 61,042 ms |
| max | 3,616 ms | 801 ms | 89,903 ms |
| throughput | 742 req/s | 852 req/s | 1,765 req/s (**512 successful**) |
| under 800 ms | 96.1% | **100%** | 8.2% |

### (l) Why the graphs look the way they do

**Max limit - the staircase.** Response time is a flat line at 12-14 ms across
the first seven levels, then steps up sharply. Throughput climbs with each
level early on and stops tracking the arrival rate after 200/sec. Zero failures
across the entire run: nothing was ever refused, requests simply waited. The
run is 96.1% under 800 ms because two thirds of it was spent at rates the
server handles comfortably.

**Load - deliberately boring.** A steady 225 users/sec, 60% of the limit, for
three minutes. Flat p95 at 29 ms, zero failures, and **168,779 of 168,780
requests under 800 ms** - a single request touched 801 ms. Throughput matches
the arrival rate exactly. The job's own assertions (p95 < 2,000 ms, failures
< 1%) passed, which is why the Jenkins build is green. A healthy load test
should look uneventful, and this flat line is what "handles expected traffic"
means.

**Stress - the collapse.** 750 users/sec, twice the limit. Response time climbs
into the tens of seconds and stays there; p99 is 61 seconds; the worst request
took 89.9 seconds. Nearly 71% of requests failed.

The error breakdown says exactly *how* it failed:

| error | count | share |
|---|---:|---:|
| `j.n.ConnectException: Operation timed out` | 314,002 | 92.15% |
| `j.n.SocketException: Resource temporarily unavailable` | 20,798 | 6.10% |
| `Request timeout ... after 60000 ms` | 5,894 | 1.73% |
| `j.i.IOException: Premature close` | 41 | 0.01% |

92% are **connection** timeouts, not response timeouts. Those requests never
reached the application: they sat in the TCP accept queue until the client gave
up. Only 1.7% got a connection and then timed out waiting for a reply. The
bottleneck is the front door, not the work behind it.

**The trap in the stress numbers:** raw throughput reads 1,765 req/sec, *higher*
than the load test's 852. That number is worthless on its own - only 512
req/sec were actually served, and the other 1,253 are failures being counted as
throughput. Failing is cheap, so an overloaded system can look busier than a
healthy one. **Throughput must always be read next to the error rate.**

### The mechanism

Tomcat serves requests from a fixed worker thread pool (`maxThreads`, default
200) with an `acceptCount` backlog queue behind it. Below capacity every request
gets a worker immediately and latency is just service time - the ~12 ms of
PBKDF2. Past capacity, requests wait for a free worker: latency becomes service
time *plus* queue time, and grows without throughput improving. When the backlog
itself fills, the OS stops completing handshakes and new connections time out
before they are ever accepted.

That is exactly the order the measurements show: latency intact to 375, then
connection-level failure at 400 once the queue in front of the workers
overflows.

### The honest caveat

Gatling runs on the same ten-core laptop as Tomcat, so past roughly 400
users/sec the load generator competes with the server for CPU, and some of the
measured ceiling is the harness. The knee at 375-400 is sharp and reproducible
and sits below the point where the generator visibly falls behind (which the
staircase run exposes at 300+), so I am confident it is a property of the
application. The 450 numbers should be read as "comfortably past broken", not
as precise measurements.

## Two problems the testing found

### 1. The application had no measurable limit
The first version served **4,300 requests/sec at a p99 of 1 ms with zero
errors**. That is not a fast application, it is an application doing nothing -
the test was measuring the loopback interface and Gatling's own overhead.

The greet endpoint now derives a session token with **PBKDF2-HMAC-SHA256 at
150,000 iterations** (~12 ms of CPU, measured), the same deliberately expensive
key derivation a login endpoint performs when verifying a password. It is real
work governed by a documented security parameter - OWASP recommends 600,000
iterations - not an artificial sleep, and it puts the endpoint in the cost range
of an ordinary database-backed page.

### 2. Every run poisoned the next one
Identical runs at the same rate produced **p95 of 15 ms on one occasion and
5,779 ms on another**. A heap histogram of the Tomcat process found **252,180
live `org.apache.catalina.session.StandardSession` objects**.

A JSP creates an `HttpSession` for every visitor unless told otherwise, and a
load test presents a brand new visitor on every request. Each session then held
heap for the 30-minute default timeout. The fix was `session="false"` on both
pages, since the application holds no per-user state. Tomcat had also serialised
the sessions to `work/Catalina/localhost/<app>/SESSIONS.ser` on shutdown and
restored them on the next start, so that file had to be deleted before the heap
was genuinely clean.

Both fixes were in place for every number in this document, and the JVM was
warmed with several hundred requests before each measurement - an earlier sweep
against a cold JVM produced a limit of ~150 users/sec, which was measuring JIT
compilation rather than application capacity.

## A finding from the monitor

The availability monitor ran on its normal 5-minute cron straight through the
stress test. Both probes inside that window **passed**:

| build | time | status | response |
|---|---|---|---|
| #2726 | 13:26:54Z | 200 | 1.2 ms |
| #2727 | 13:31:54Z | 200 | 1.5 ms |

At that moment 71% of real traffic was failing. The monitor was not broken - it
asks for the cheap `index.jsp` without the PBKDF2 parameter, and its single
connection won a slot in the accept queue that thousands of concurrent ones
could not.

The lesson is about synthetic monitoring generally: **one probe from one place
proves that one request worked.** It says nothing about the 340,735 that did
not. Useful availability monitoring needs either real user monitoring or a probe
that exercises the expensive path - which is why a green dashboard should never
be the only evidence a system is healthy.
