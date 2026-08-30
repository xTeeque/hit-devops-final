import io.gatling.javaapi.core.ScenarioBuilder;
import io.gatling.javaapi.core.Simulation;

import static io.gatling.javaapi.core.CoreDsl.*;

/**
 * Step 10 - three minute STRESS test.
 *
 * Pushes past the max limit on purpose to see how the application degrades and
 * whether it recovers. Expect throughput to plateau while response time climbs
 * (requests queueing for a Tomcat worker thread), then failures once the accept
 * queue is full. No assertions here: failing is the point of the exercise.
 *
 * Run:  gatling.sh -s StressSimulation
 */
public class StressSimulation extends Simulation {

    private static final int RATE     = Integer.getInteger("stress.rate", 500);
    private static final int DURATION = Integer.getInteger("duration.secs", 180);

    private final ScenarioBuilder scn =
            scenario("Stress test - beyond capacity").exec(BaseScenario.journey());

    {
        setUp(
                scn.injectOpen(
                        rampUsersPerSec(1).to(RATE).during(20),
                        constantUsersPerSec(RATE).during(DURATION - 40),
                        rampUsersPerSec(RATE).to(1).during(20)
                )
        ).protocols(BaseScenario.protocol());
    }
}
