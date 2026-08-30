# Deliverables (j) and (l) - performance analysis

## Summary

| | |
|---|---|
| **Max limit** | **250 users/sec (~820 requests/sec)** |
| How it was found | Stepped constant-rate runs on a warmed-up server, watching p95 and error rate |
| What defines the limit | The last rate where p95 stayed inside the response-time budget with zero failures |
| Where it breaks | 260 users/sec - p95 goes from 30 ms to 2,285 ms for 1% more throughput |
| Throughput ceiling | ~830-880 requests/sec |
| Test bed | MacBook, 10 cores (6 performance + 4 efficiency), Tomcat 9.0.121, Gatling 3.13.5 on the same machine |

## (j) The max limit, and how I found it

A max limit is a search, not a single measurement. I ran the same scenario at
increasing constant arrival rates and recorded **p95 response time** and
**error rate** at each level. Mean response time is deliberately not the signal:
it hides the tail, and the tail is what users actually experience.

| users/sec | p95 | p99 | errors | req/sec |
|---:|---:|---:|---:|---:|
| 160 | 26 ms | 52 ms | 0 | 525 |
| 180 | 23 ms | 27 ms | 0 | 590 |
| 200 | 53 ms | - | 0 | 656 |
| 210 | 28 ms | - | 0 | 688 |
| **250** | **30 ms** | **33 ms** | **0** | **819** |
| 260 | 2,285 ms | 2,889 ms | 0 | 828 |
| 270 | 3,159 ms | 3,503 ms | 0 | 847 |
| 280 | 5,573 ms | 6,260 ms | 0 | 840 |
| 300 | 4,954 ms | 5,487 ms | 0 | 877 |
| 350 | 11,255 ms | 12,680 ms | 0 | 887 |
| 400 | 17,299 ms | 23,719 ms | 2,193 | 760 |
| 450 | 17,040 ms | 19,121 ms | 10,035 | 771 |
| 500 | 22,148 ms | 27,909 ms | 16,124 | 841 |

**250 users/sec is the limit.** It is the last level where every request is
served with no failures and a p95 of 30 ms. Ten more users per second takes p95
to 2,285 ms - **76 times worse** - while throughput rises only from 819 to 828
requests/sec, a gain of about 1%.

That combination is the entire argument. If the server still had spare
capacity, raising the arrival rate would raise throughput and leave latency
roughly alone. Instead throughput flattens at roughly 830-880 requests/sec and
latency runs away. The server is already delivering everything it can, so extra
arrivals do not get served faster - they wait. **The latency is the queue, made
visible.**

Note the ordering: **failures do not appear until 400 users/sec**, long after
the application became unusable. At 300 users/sec every request still returns
HTTP 200, but users are waiting five seconds. A monitor that only checked for
error responses would have reported the system healthy well past the point where
it had stopped being usable - which is exactly why the availability monitor in
this project checks response time as well as status code.

## Why an earlier answer was wrong

An initial sweep put the limit near 150 users/sec, because it showed p95 jumping
to 7,439 ms at 200. Re-running the same rate on a warmed-up server gave 53 ms.
The first sweep had started minutes after a Tomcat restart, so the JVM was still
interpreting rather than running JIT-compiled code, and the early numbers
measured JVM warm-up rather than application capacity.

The lesson is part of the result: **a load test against a cold JVM measures the
JVM.** Every number in the table above was taken after the server had been
serving for some time, and the knee was confirmed twice on independent runs.

## The three submitted runs

| | Max limit (ramp 50-350) | Load (150/sec, 3 min) | Stress (500/sec, 3 min) |
|---|---:|---:|---:|
| requests | 136,000 | 112,528 | 320,080 |
| failures | 3,252 (2.4%) | **0** | **152,919 (47.8%)** |
| mean | 4,167 ms | **7 ms** | 11,692 ms |
| p95 | 20,911 ms | **32 ms** | 15,976 ms |
| p99 | 42,381 ms | **35 ms** | 22,096 ms |
| max | 58,904 ms | 486 ms | 60,047 ms |
| throughput | 624 req/sec | 568 req/sec | 1,442 req/sec (753 successful) |
| under 800 ms | 58.1% | **100%** | 3.8% |

Three numbers tell the whole story.

**The load test passed its own assertion** - p95 of 32 ms against a 2,000 ms
budget, zero failures, every single one of 112,528 requests served in under
800 ms. That is what running comfortably inside capacity looks like.

**The stress test failed almost half its requests** - 152,919 of 320,080. Note
that its raw throughput, 1,442 req/sec, is *higher* than the load test's 568.
That number is misleading and worth understanding: most of it is the server
rejecting connections quickly. Only 753 req/sec were actually served. Counting
failed requests as throughput makes an overloaded system look busier than a
healthy one, which is why throughput must always be read next to the error rate.

**The max-limit ramp shows both halves in one run** - 58% of requests completed
in under 800 ms (the early steps, below the limit) while 37% took over 1,200 ms
(the later steps, past it). The failures all cluster at a minimum of 15.5
seconds, which is the client timeout: those requests were not refused, they
waited in the queue until the load generator gave up on them.

## (l) Why the graphs look the way they do

### Max limit run - the staircase
Arrival rate steps up every 20 seconds from 50 to 350 users/sec. Response time
stays flat and low through the first four steps, bends sharply upward once the
rate passes 250, and keeps climbing. Throughput rises with each step early on,
then flattens near 880 requests/sec no matter how much more load arrives. The
point where the two curves diverge - throughput flat, latency rising - is the
limit.

### Load run - deliberately boring
A steady 150 users/sec, about 60% of the limit, for three minutes. Flat p95,
zero failures, throughput matching the arrival rate exactly. A healthy load test
should look uneventful; that flat line is what "handles expected traffic" looks
like.

### Stress run - the hockey stick
500 users/sec, twice the limit, for three minutes. Response time climbs steeply
and stays high, throughput plateaus instead of doubling, and the error line
lifts off the axis as the accept queue fills.

### The mechanism
Tomcat serves requests from a fixed worker thread pool (`maxThreads`, default
200) with an `acceptCount` backlog queue behind it. Below capacity every request
gets a worker immediately, so latency is just service time. Past capacity,
requests wait for a free worker: latency becomes service time *plus* queue time
and grows without throughput improving. When the backlog itself fills, Tomcat
stops accepting connections and failures begin. That is exactly the order the
measurements show - latency degrades at 260, failures only at 400.

### The honest caveat
Gatling runs on the same ten-core laptop as Tomcat, so above roughly 400
users/sec the load generator competes with the server for CPU and part of the
measured ceiling is the harness rather than the application. The knee at 250-260
sits well below that contention point and is a genuine property of the
application. The numbers at 450 and 500 should be read as "comfortably past
broken", not as precise measurements.

## Two problems the testing found

### 1. The application had no measurable limit
The first version served **4,300 requests/sec at a p99 of 1 ms with zero
errors**. That is not a fast application - it is an application doing nothing.
The test was measuring the loopback interface and Gatling's own overhead.

The greet endpoint now derives a session token with **PBKDF2-HMAC-SHA256 at
150,000 iterations** (about 12 ms of CPU), the same deliberately expensive key
derivation a login endpoint performs when verifying a password. It is real work
governed by a documented security parameter - OWASP recommends 600,000
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
the sessions to `work/Catalina/localhost/AsafArusi/SESSIONS.ser` on shutdown and
restored them on the next start, so that file had to be deleted before the heap
was genuinely clean.

Every number in this document was measured after both fixes, with the live
session count verified at zero.
