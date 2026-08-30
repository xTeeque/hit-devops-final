# Submission checklist

Email to **mosh?hit@gmail.com** (address as printed in the brief), subject:
`Final Exercise from: Asaf Arusi`

| # | Deliverable | Where it is | Status |
|---|---|---|---|
| a | The JSP file | `app/index.jsp` (and `app/about.jsp`) | ready |
| b | Screenshot of GitHub with the app in it | https://github.com/xTeeque/hit-devops-final | **you** |
| c | Screenshot of the app in Tomcat, URL visible | http://localhost:8080/AsafArusi/ | **you** |
| bonus | Public URL + write-up | http://46.224.99.46:8090/AsafArusi/ , `docs/public-exposure.md` | ready |
| d | Link to the public repo | https://github.com/xTeeque/hit-devops-final | ready |
| e | Monitor tool, what it checks, screenshot passing | `jenkins/Jenkinsfile.monitor`, job `AsafArusi-02` | **you** (screenshot) |
| f | Selenium IDE `.side` file | `selenium/AsafArusi-HIT-DevOps-Final.side` | ready |
| g | Screenshot of passed run + justification | `docs/selenium-validations.md` | **you** (screenshot) |
| h | HAR scenario in words | `docs/HAR-scenario.md` | ready |
| i | The HAR file | `docs/AsafArusi-app.har` | see below |
| j | Max limit + how it was found | `docs/performance-analysis.md` | ready |
| k | 3 CMD screenshots (max limit, load, stress) | `docs/gatling-console-*.txt` | **you** (screenshot) |
| l | 3 PDFs of Gatling reports + why | `docs/reports/*.pdf`, analysis in `docs/performance-analysis.md` | ready |

## What only you can produce

Four screenshots and the HAR need a real browser session on your machine:

**(b) GitHub** - open the repo, make sure `app/index.jsp` is visible in the file
list, screenshot the whole browser window.

**(c) Tomcat** - open `http://localhost:8080/AsafArusi/`, type a name, click
Greet so the greeting shows, and screenshot **with the address bar visible** -
the brief explicitly asks to see the URL.

**(e) Monitor** - Jenkins at `http://localhost:8081`, open
`AsafArusi-02-availability-monitor`, screenshot the build history showing a
column of blue/green runs five minutes apart.

**(g) Selenium IDE** - install the Selenium IDE extension in Chrome, open
`selenium/AsafArusi-HIT-DevOps-Final.side`, click **Run all tests**, and
screenshot the panel showing all five green.

**(i) HAR** - Chrome DevTools -> Network -> tick **Preserve log** -> perform the
scenario in `docs/HAR-scenario.md` -> right-click the request list ->
**Save all as HAR with content** -> save as `docs/AsafArusi-app.har`.

**(k) CMD screenshots** - the saved console output is in `docs/`, but the brief
asks for screenshots of the terminal. Re-run each job from Jenkins, or run
locally and screenshot the terminal:

```
./gatling/run.sh MaxLimitSimulation
./gatling/run.sh LoadSimulation
./gatling/run.sh StressSimulation
```
