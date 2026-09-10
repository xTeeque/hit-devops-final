# Bonus (brief step 5) - exposing the application to the internet

**Public URL: http://46.224.99.46:8090/AsafArusi-OmerLevi-MaorDanny/**

## What was built

Production stays on the laptop. A VPS acts only as a public front door, with a
reverse SSH tunnel carrying traffic back to Tomcat.

```
internet -> 46.224.99.46:8090 (VPS)
                |
                |  reverse SSH tunnel, laptop dials out
                v
         laptop 127.0.0.1:8080  -> Tomcat -> webapps/AsafArusi-OmerLevi-MaorDanny
```

The laptop opens the connection outbound, so nothing needs to be forwarded on
the home router and the laptop never accepts an inbound connection from the
internet. The VPS is the only machine with an open port.

## How it was set up

**1. A dedicated SSH key** (`~/.ssh/hit-devops-vps`), used only for this tunnel,
rather than reusing a general-purpose key.

**2. On the VPS**, a reversible drop-in at
`/etc/ssh/sshd_config.d/60-hit-devops-tunnel.conf`:

```
GatewayPorts clientspecified
```

By default `sshd` binds a reverse forward to loopback only, so nothing outside
the VPS could reach it. `clientspecified` lets the client choose the bind
address, rather than `yes` which would force every forward on the box to be
public. The change was validated with `sshd -t` and applied with
`systemctl reload ssh` - a reload rather than a restart, so existing sessions
survive and a bad config cannot lock you out.

**3. On the laptop**, a launchd agent (`local.hit-devops-tunnel`) running:

```
ssh -N -T -o ExitOnForwardFailure=yes -o ServerAliveInterval=30 \
    -R 0.0.0.0:8090:127.0.0.1:8080 root@46.224.99.46
```

`ServerAliveInterval` detects a dead link, `ExitOnForwardFailure` makes ssh exit
rather than sit there with no working forward, and launchd's `KeepAlive`
restarts it. Together those mean the tunnel heals itself.

## Why port 8090 and not 80

The VPS provider's firewall allows only 22, 80 and 443 inbound. Ports 80, 81
and 443 are already taken by an nginx-proxy-manager instance serving other
sites on that machine, so the application uses 8090, opened specifically for it.

The alternative, kept as a later improvement, is to add a proxy host in
nginx-proxy-manager pointing `devops.asafarusi.co.il` at `127.0.0.1:8090`,
which would serve the app over HTTPS on port 443 with a Let's Encrypt
certificate.

## Effect on the performance results

Measured from the laptop, single request:

| | response time |
|---|---|
| `http://localhost:8080/AsafArusi-OmerLevi-MaorDanny/` | 0.6 ms |
| `http://46.224.99.46:8090/AsafArusi-OmerLevi-MaorDanny/` | 319 ms |

I also ran Gatling through the public URL to see what the tunnel actually costs
under load:

| users/sec | p95 | failures | throughput |
|---:|---:|---:|---:|
| 10 | 223 ms | 0 | 34 req/s |
| 25 | 206 ms | 0 | 84 req/s |
| 75 | 176 ms | 0 | 250 req/s |
| 150 | 178 ms | 0 | 500 req/s |

The result corrected an assumption I had written down before measuring. I had
expected the tunnel to **saturate** - one shared TCP connection, so throughput
should hit a wall early. It does not: it carried 500 req/sec with no failures
and no rise in latency, and I never found its ceiling within the range tested.

What it actually does is add a **fixed latency floor of roughly 160-180 ms** and
hold it flat regardless of rate. That is a round trip to the VPS and back down
the tunnel, and it is constant because it is distance, not contention.

That floor is still the reason **the submitted runs for steps 8-10 target
`localhost`**. The application's own p95 inside its limit is 23 ms. Through the
tunnel every measurement would sit on top of a 170 ms constant, so the app's
response time would be about 12% of the number and the knee at 375 users/sec
would be invisible - buried under network latency that has nothing to do with
Tomcat. Testing localhost measures the application; testing the public URL
measures Israel-to-VPS-and-back.

Both sets of numbers are above. The localhost graphs answer "what can this
application do"; this table answers "what does this deployment topology cost",
and the gap between them - 0.6 ms against 319 ms - is the tunnel.
