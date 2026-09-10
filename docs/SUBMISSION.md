# Submission checklist

Email to **mosh.hit@gmail.com**, subject:
`Final Exercise from: Asaf Arusi, Omer Levi, Maor Danny`

Production URL: `http://localhost:8080/AsafArusi-OmerLevi-MaorDanny/`
Public URL (bonus): `http://46.224.99.46:8090/AsafArusi-OmerLevi-MaorDanny/`
Repo: https://github.com/xTeeque/hit-devops-final

| # | Deliverable | Where it is | Status |
|---|---|---|---|
| a | The JSP file | `app/index.jsp` (and `app/about.jsp`) | ready |
| b | Screenshot of GitHub with the app in it | `05-screenshots/b-github-repo.png` | ready |
| c | Screenshot of the app in Tomcat, URL visible | `05-screenshots/c-tomcat-app-page.png` | **needs your address bar** |
| d | Link to the public repo | https://github.com/xTeeque/hit-devops-final | ready |
| e | Monitor tool, what it checks, screenshot passing | UptimeRobot + Jenkins `AsafArusi-02` | **you** (see below) |
| f | Selenium IDE `.side` file | `selenium/HIT-DevOps-Final-AsafArusi-OmerLevi-MaorDanny.side` | ready |
| g | Screenshot of passed run + justification | `docs/selenium-validations.md` + `05-screenshots/g-*` | **you** (IDE screenshot) |
| h | HAR scenario in words | `docs/HAR-scenario.md` | ready |
| i | The HAR file | `docs/HIT-DevOps-app.har` | ready |
| j | Max limit + how it was found | `docs/performance-analysis.md` | ready |
| k | 3 CMD screenshots (max limit, load, stress) | `05-screenshots/k1..k3-*.png` | ready |
| l | 3 PDFs of Gatling reports + why | `docs/reports/*.pdf` + analysis | ready |
| bonus | Public URL + write-up | `docs/public-exposure.md` | ready |

## Evidence that everything ran through Jenkins

| job | builds | latest result |
|---|---|---|
| `AsafArusi-01-deploy-to-tomcat` | 19 | SUCCESS - every build triggered by pollSCM off a real commit |
| `AsafArusi-02-availability-monitor` | 2,730 | SUCCESS - running on `H/5 * * * *` |
| `AsafArusi-03-selenium-tests` | 16 | SUCCESS - 5/5, auto-triggered by the deploy job |
| `AsafArusi-04-gatling-max-limit` | 1 | SUCCESS |
| `AsafArusi-05-gatling-load-3min` | 1 | SUCCESS - assertions passed |
| `AsafArusi-06-gatling-stress-3min` | 1 | SUCCESS |

The deploy and Selenium counts keep rising: every push to `main` is picked up
within a minute and redeployed, which is the pipeline doing its job.

## What only you can produce

**(c) Tomcat with the address bar.** A headless screenshot of the page is in
`05-screenshots/c-tomcat-app-page.png`, but the brief asks to *see the URL*, and
headless Chrome has no address bar. Open
`http://localhost:8080/AsafArusi-OmerLevi-MaorDanny/`, type a name, click Greet,
then press Cmd+Shift+4 then Space and click the window.

**(e) Monitor.** The UptimeRobot monitor still points at the old
`/AsafArusi/` path, which now returns 404. Edit it to
`http://46.224.99.46:8090/AsafArusi-OmerLevi-MaorDanny/`, wait ~15 minutes for
three green checks, and screenshot the dashboard. The Jenkins monitor job needs
nothing - it already has 2,700+ green builds on the new URL.

**(g) Selenium IDE.** Open the `.side` file in the Selenium IDE Chrome
extension, click **Run all tests**, screenshot the panel showing five green.
`05-screenshots/g-selenium-jenkins-passed.png` shows the same five tests passing
in the Jenkins job, as supporting evidence that CI runs the same `.side` file.
