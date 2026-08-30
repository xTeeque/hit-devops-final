# Deliverables (j) and (l) - performance analysis

## Summary

| | |
|---|---|
| **Max limit** | **~150 users/sec (~470 requests/sec)** |
| How it was found | Stepped constant-rate runs, watching p95 and error rate |
| What defines the limit | The last rate where p95 stayed inside the response-time budget with zero errors |
| Where it breaks | 200 users/sec - p95 jumps 112x while throughput barely moves |
| Test bed | MacBook, 10 cores (6 performance + 4 efficiency), Tomcat 9.0.121 on JDK 26, Gatling 3.13.5 on the same machine |

## (j) The max limit, and how I found it

A max limit is not a single measurement, it is a search. I ran the same
scenario at increasing constant arrival rates for 30 seconds each and recorded
two signals: **p95 response time** and **error rate**. Mean response time is
deliberately not the signal - it hides the tail, and the tail is what users
feel.

| users/sec | mean | p95 | p99 | errors | req/sec |
|---:|---:|---:|---:|---:|---:|
| 50 | 5 ms | 22 ms | 33 ms | 0 | 157 |
| 100 | 7 ms | 33 ms | 34 ms | 0 | 313 |
| **150** | **14 ms** | **66 ms** | **269 ms** | **0** | **469** |
| 200 | 1,695 ms | 7,439 ms | 7,960 ms | 0 | 518 |
| 300 | 5,408 ms | 18,716 ms | 20,503 ms | 0 | 577 |
| 400 | 4,455 ms | 15,658 ms | 19,759 ms | 361 | 770 |
| 500 | 6,155 ms | 16,265 ms | 18,490 ms | 4,277 | 816 |
| 650 | 9,840 ms | 22,974 ms | 31,571 ms | 21,646 | 947 |

**150 users/sec is the limit.** It is the last level where the application
answers every request with no failures and a p95 of 66 ms. One step later, at
200, p95 is 7,439 ms - **112 times worse** - while throughput moves only from
469 to 518 requests/sec, a 10% gain.

That combination is the whole answer. If the server still had capacity,
raising arrival rate would raise throughput and leave latency alone. Instead
throughput flattens and latency explodes, which means the server is already
delivering everything it can and the extra arrivals are simply waiting.
**The latency is the queue, made visible.**

Errors do not appear until 400 users/sec. That ordering matters: the
application degrades long before it starts refusing work, so a monitor that
only checks for HTTP errors would have called it healthy at 300 users/sec while
real users waited 18 seconds for a page.

## (l) Why the graphs look the way they do

### Max limit run - the staircase
Arrival rate steps up every 20 seconds. Response time stays flat and low
through the early steps, then bends sharply upward at the knee and keeps
climbing. Throughput rises linearly with the steps at first, then flattens.
The point where the two curves diverge - throughput flat, latency rising - is
the limit.

### Load run - deliberately boring
A steady 100 users/sec, about two thirds of the limit, for three minutes. Flat
p95, zero failures, throughput exactly matching arrival rate. A healthy load
test should look uneventful; that is what "the system handles expected traffic"
looks like on a chart.

### Stress run - the hockey stick
300 users/sec, twice the limit, for three minutes. Response time climbs
steeply and stays high, throughput plateaus rather than doubling, and the error
line eventually lifts off the axis.

### The mechanism
Tomcat serves requests from a fixed worker thread pool - `maxThreads`, 200 by
default - with an `acceptCount` backlog queue behind it. Below capacity, every
request gets a thread immediately: latency is just service time. Past capacity,
requests wait in the queue for a thread, so latency becomes service time *plus*
queue time and grows without throughput improving. When the queue itself fills,
Tomcat stops accepting connections and the failures begin. That is exactly the
order the numbers show: latency degrades first (200), errors follow much later
(400).

### The honest caveat
Gatling runs on the same ten-core laptop as Tomcat. Above roughly 400 users/sec
the load generator is competing with the server for CPU, so part of the measured
ceiling is the test harness rather than the application. The knee at 150-200 is
well below that contention point and is a property of the application; the
numbers at 500 and 650 should be read as "well past broken", not as precise
measurements.

## Two problems the testing found

### 1. The application had no measurable limit
The first version served **4,300 requests/sec at a p99 of 1 ms with zero
errors**. That is not a fast application, it is an application doing nothing -
the test was measuring the loopback interface and Gatling's own overhead.

The greet endpoint now derives a session token with **PBKDF2-HMAC-SHA256 at
150,000 iterations** (about 12 ms of CPU), the same deliberately expensive key
derivation a login endpoint performs when verifying a password. It is real work
governed by a documented security parameter - OWASP recommends 600,000
iterations - not an artificial sleep, and it puts the endpoint in the cost range
of an ordinary database-backed page.

### 2. Every run poisoned the next one
Identical runs at 150 users/sec produced **p95 of 15 ms on one occasion and
5,779 ms on another**. Not thermal throttling: a heap histogram of the Tomcat
process found **252,180 live `org.apache.catalina.session.StandardSession`
objects**.

A JSP creates an `HttpSession` for every visitor unless told otherwise, and a
load test presents a brand new visitor on every request. Each session then
occupied heap for the 30-minute default timeout. The fix was `session="false"`
on both pages, since the application holds no per-user state. Tomcat had also
serialised the sessions to `work/Catalina/localhost/AsafArusi/SESSIONS.ser` on
shutdown and restored them on the next start, so that file had to be deleted
before the heap was genuinely clean.

Every number in this document was measured after both fixes, with the live
session count verified at zero after each run.
