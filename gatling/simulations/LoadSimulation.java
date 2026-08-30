import io.gatling.javaapi.core.ScenarioBuilder;
import io.gatling.javaapi.core.Simulation;

import static io.gatling.javaapi.core.CoreDsl.*;

/**
 * Step 9 - three minute LOAD test.
 *
 * A steady arrival rate deliberately kept below the max limit, to show how the
 * application behaves under expected traffic. A healthy load test is boring:
 * flat response times, zero failures, throughput equal to the arrival rate.
 *
 * Run:  gatling.sh -s LoadSimulation
 */
public class LoadSimulation extends Simulation {

    private static final int RATE     = Integer.getInteger("load.rate", 150);
    private static final int DURATION = Integer.getInteger("duration.secs", 180);

    private final ScenarioBuilder scn =
            scenario("Load test - normal traffic").exec(BaseScenario.journey());

    {
        setUp(
                scn.injectOpen(
                        rampUsersPerSec(1).to(RATE).during(15),
                        constantUsersPerSec(RATE).during(DURATION)
                )
        ).protocols(BaseScenario.protocol())
         .assertions(
                 global().failedRequests().percent().lt(1.0),
                 global().responseTime().percentile3().lt(2000)
         );
    }
}
