# HIT DevOps 2026 - Final Project

Introduction to DevOps, HIT 2026 Semester C. Lecturer: Moshe Mamia.
Submitted by: **Asaf Arusi**

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
| Production | Apache Tomcat 9.0.121 | `http://localhost:8080/AsafArusi/` |
| Monitoring | UptimeRobot + Jenkins cron job | `jenkins/Jenkinsfile.monitor` |
| Functional tests | Selenium IDE + selenium-side-runner | `selenium/` |
| Performance | Gatling | `gatling/` |

## Layout

```
app/         the deployed application (index.jsp, about.jsp, css/)
jenkins/     pipeline definitions for all four Jenkins jobs
selenium/    Selenium IDE project (.side) and the runner script
gatling/     Gatling simulations for max-limit, load and stress
docs/        submission notes and written explanations
```

## Deployment

Jenkins polls this repository. On a new commit the deploy job copies `app/`
into Tomcat's `webapps/AsafArusi/`. No Tomcat restart is needed: Tomcat
compiles a JSP into a servlet on first request and recompiles it when the
file's modification time changes.

## Note on the workload in index.jsp

`index.jsp` contains a synchronized visit counter and a small repeated-hash
computation. Both are deliberate. They give the application a realistic
per-request cost and a real serialization point, so the Gatling results
measure the application rather than the loopback network.
