import io.gatling.javaapi.core.ChainBuilder;
import io.gatling.javaapi.http.HttpProtocolBuilder;

import static io.gatling.javaapi.core.CoreDsl.*;
import static io.gatling.javaapi.http.HttpDsl.*;

/**
 * Shared protocol and request chain for all three simulations.
 *
 * The chain replays the same journey that was captured in the HAR file:
 * open the app, load its stylesheet, submit a name, then visit the About page.
 * Keeping it in one place means the max-limit, load and stress runs are
 * measuring identical work and their graphs can be compared directly.
 */
public final class BaseScenario {

    /** Override with -Dapp.base=https://... to test the public URL instead. */
    public static final String BASE_URL =
            System.getProperty("app.base", "http://localhost:8080/AsafArusi");

    private BaseScenario() { }

    public static HttpProtocolBuilder protocol() {
        return http
                .baseUrl(BASE_URL)
                .acceptHeader("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8")
                .acceptLanguageHeader("en-US,en;q=0.9")
                .acceptEncodingHeader("gzip, deflate")
                .userAgentHeader("Gatling/HIT-DevOps-Final")
                .shareConnections();
    }

    public static ChainBuilder journey() {
        return exec(
                http("01 Open application")
                        .get("/index.jsp")
                        .check(status().is(200))
                        .check(substring("id=\"heading\"").exists())
        ).exec(
                http("02 Load stylesheet")
                        .get("/css/style.css")
                        .check(status().is(200))
        ).pause(1).exec(
                http("03 Submit name")
                        .get("/index.jsp?username=Asaf&greet=1")
                        .check(status().is(200))
                        .check(substring("Hello, Asaf!").exists())
        ).pause(1).exec(
                http("04 Open about page")
                        .get("/about.jsp")
                        .check(status().is(200))
                        .check(substring("id=\"serverInfo\"").exists())
        );
    }
}
