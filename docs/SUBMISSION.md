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
| c | Screenshot of the app in Tomcat, URL visible | `05-screenshots/c-tomcat-url-visible.png` | ready |
| d | Link to the public repo | https://github.com/xTeeque/hit-devops-final | ready |
| e | Monitor tool, what it checks, screenshot passing | `05-screenshots/e-uptimerobot-*.png` + Jenkins `AsafArusi-02` | ready |
| f | Selenium IDE `.side` file | `selenium/HIT-DevOps-Final-AsafArusi-OmerLevi-MaorDanny.side` | ready |
| g | Screenshot of passed run + justification | `docs/selenium-validations.md` + `05-screenshots/g-*` | ready (see note) |
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

## Note on (g): the Selenium IDE GUI does not exist any more

The `.side` file is submitted as asked. A screenshot of the IDE *window* is not,
because the IDE cannot be run on this machine:

- The **Chrome extension** is blocked by Google's Manifest V3 enforcement - it
  was built on MV2, so Chrome marks it unsupported and disables it.
- The **desktop app** (`4.0.1-beta.14`, July 2024, the last release) exits
  immediately on this macOS with no window and no crash report.

The run evidence is `selenium-side-runner`, the official Selenium IDE
command-line runner from the same project, executing the same `.side` file:
`g-selenium-runner-terminal.png` (5/5 in a terminal) and
`g-selenium-jenkins-passed.png` (the same 5/5 in Jenkins on every deploy).
