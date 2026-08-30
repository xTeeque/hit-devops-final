import io.gatling.javaapi.core.ScenarioBuilder;
import io.gatling.javaapi.core.Simulation;

import static io.gatling.javaapi.core.CoreDsl.*;

/**
 * Step 8 - find the application's max limit.
 *
 * Arrival rate is raised in equal steps and held at each level. The max limit
 * is the highest step at which the application still answers every request
 * within its response-time budget; the step after it is where the queue builds,
 * p95 climbs sharply and failures appear.
 *
 * Run:  gatling.sh -s MaxLimitSimulation
 */
public class MaxLimitSimulation extends Simulation {

    private static final int START_RATE  = Integer.getInteger("start.rate", 50);
    private static final int STEP_RATE   = Integer.getInteger("step.rate", 50);
    private static final int STEPS       = Integer.getInteger("steps", 7);
    private static final int LEVEL_SECS  = Integer.getInteger("level.secs", 20);

    private final ScenarioBuilder scn =
            scenario("Max limit search").exec(BaseScenario.journey());

    {
        setUp(
                scn.injectOpen(
                        incrementUsersPerSec(STEP_RATE)
                                .times(STEPS)
                                .eachLevelLasting(LEVEL_SECS)
                                .separatedByRampsLasting(5)
                                .startingFrom(START_RATE)
                )
        ).protocols(BaseScenario.protocol());
    }
}
