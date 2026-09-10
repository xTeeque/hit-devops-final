# HIT DevOps 2026 - Final Project

Introduction to DevOps, HIT 2026 Semester C. Lecturer: Moshe Mamia.
Submitted by: **Asaf Arusi, Omer Levi, Maor Danny**

A JSP web application delivered from development into production by a CI/CD
pipeline, then monitored, functionally tested, and performance tested.

## Pipeline

```
laptop  ->  GitHub  ->  Jenkins (:8081)  ->  Tomcat 9 (:8080)  ->  public URL
                              |
                              +-- availability-monitor   every 5 minutes
                              +-- selenium-tests         5 validations
                              +-- gatling-*              max limit / load / stress
```

| Layer | Choice | Where |
|---|---|---|
| SCM | Git + GitHub | this repo |
| CI/CD | Jenkins LTS 2.568.1 | `http://localhost:8081` |
| Production | Apache Tomcat 9.0.121 | `http://localhost:8080/AsafArusi-OmerLevi-MaorDanny/` |
| Monitoring | UptimeRobot + Jenkins cron job | `jenkins/Jenkinsfile.monitor` |
| Functional tests | Selenium IDE + selenium-side-runner | `selenium/` |
| Performance | Gatling | `gatling/` |

## Layout

```
app/         the deployed application (index.jsp, about.jsp, css/)
jenkins/     pipeline definitions for all six Jenkins jobs
selenium/    Selenium IDE project (.side) and the runner script
gatling/     Gatling simulations for max-limit, load and stress
docs/        submission notes and written explanations
```

## Deployment

Jenkins polls this repository. On a new commit the deploy job copies `app/`
into Tomcat's `webapps/AsafArusi-OmerLevi-MaorDanny/`. No Tomcat restart is needed: Tomcat
compiles a JSP into a servlet on first request and recompiles it when the
file's modification time changes.

## Note on the workload in index.jsp

`index.jsp` contains a synchronized visit counter and a PBKDF2-HMAC-SHA256 key
derivation at 150,000 iterations. Both are deliberate. They give the
application a realistic per-request cost (~12 ms of CPU, the work a login
endpoint does to verify a password) and a real serialization point, so the
Gatling results measure the application rather than the loopback network.

Both pages set `session="false"`. A JSP otherwise creates an `HttpSession` per
visitor, and a load test is a new visitor on every request - that leak once put
252,180 live session objects in the Tomcat heap and made consecutive runs
uncomparable.

## Results

| | |
|---|---|
| Max limit | **375 users/sec (~1,250 req/sec)**, p95 23 ms, zero failures |
| Breaks at | 400 users/sec - p95 16 s and throughput *falls* to 857 req/sec |
| Load test | 225 users/sec for 3 min: 168,780 requests, 0 failures, p95 29 ms |
| Stress test | 750 users/sec for 3 min: 480,080 requests, 71% failed, p95 28 s |

Full write-up in [docs/performance-analysis.md](docs/performance-analysis.md).
