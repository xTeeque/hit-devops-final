# Deliverable (g) - the five validations, and why each one is there

Recorded in Selenium IDE, saved as
`selenium/AsafArusi-HIT-DevOps-Final.side`, and executed headlessly in CI by
the Jenkins job `AsafArusi-03-selenium-tests`. The same file is both the
submitted artifact and the thing CI runs, so there is nothing to drift.

## The design, in one sentence

Five validations that check five *different* things - identity, rendering,
function, error handling and navigation - rather than five variations of the
same check, and mixing `assert` with `verify` deliberately.

## assert vs verify

| | behaviour on failure | used for |
|---|---|---|
| `assert` | stops the test immediately | preconditions, and the one thing the test exists to prove |
| `verify` | records the failure and carries on | independent checks where the remaining results are still worth having |

Using `assert` everywhere throws away information: the run stops at the first
problem and you learn nothing about the rest. Using `verify` everywhere is
worse - the test carries on operating on a page that may not even be the right
page, and every later failure is noise caused by the first one.

## The five

### V1 - page identity (`assert`)
`assertTitle` on `HIT DevOps Final - Asaf Arusi`, then `assertText` on
`#heading`. **assert**, because this is a hard precondition: if we are not on
the right page, or the deployed build is not the one we expect, nothing that
follows means anything. Stopping here is the correct behaviour.

### V2 - required controls render (`verify`)
`verifyElementPresent` on `#username`, `#greetBtn` and `#aboutLink` - the input
text box, the button and the link the brief required. **verify**, because these
are three independent existence checks. If the button is missing I still want
to know whether the link is missing too; one run should report all three.

### V3 - positive path (`assert`)
Type `Asaf`, click Greet, wait for `#result`, assert it reads `Hello, Asaf!`,
and assert `#token` exists. **assert**, because this is the application's core
function - the reason the page exists. The `#token` check matters as well: it
is rendered only after the server completes the PBKDF2 derivation, so it proves
the backend actually executed rather than the page merely rendering.

### V4 - negative path (`assert` + `verify`)
Submit with the field left empty, wait for `#error`, assert it reads
`Please enter your name before continuing.`, then verify `#result` is *not*
present. **This is the negative test.** V3 only proves the app accepts good
input; without V4 an application that greets everybody, including nobody, would
pass the whole suite. The trailing `verifyElementNotPresent` closes the gap
between "showed an error" and "showed an error *and* did not also greet".

### V5 - navigation (`assert` + `verify`)
Click through to `about.jsp`, assert its title, verify `#serverInfo` rendered,
click back, assert we are home again. **assert** on both navigations because
each is a discrete pass/fail; **verify** on the server-details block because
its absence is a rendering fault rather than a navigation fault, and I would
rather see the return trip result too.

## Waits

Every check that follows a click is preceded by `waitForElementPresent` with a
5-second timeout, rather than a fixed pause. A fixed pause is either too short
(flaky) or too long (slow); an explicit wait finishes as soon as the condition
is true and fails fast when it never becomes true.
