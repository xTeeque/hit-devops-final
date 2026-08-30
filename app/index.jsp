<%@ page contentType="text/html; charset=UTF-8" language="java" %>
<%@ page import="java.security.MessageDigest" %>
<%@ page import="java.math.BigInteger" %>
<%@ page import="java.time.LocalDateTime" %>
<%@ page import="java.time.format.DateTimeFormatter" %>
<%!
    /* Application-wide visit counter.
       Deliberately synchronized: this is the serialization point the load test finds. */
    private static long visits = 0;
    private static synchronized long recordVisit() { return ++visits; }

    /* Stands in for real per-request business logic so the load test measures the
       application rather than the network. Roughly 1-2 ms of CPU per request. */
    private String workToken(String seed) throws Exception {
        MessageDigest md = MessageDigest.getInstance("SHA-256");
        byte[] d = seed.getBytes("UTF-8");
        for (int i = 0; i < 1200; i++) { d = md.digest(d); }
        return new BigInteger(1, d).toString(16).substring(0, 12);
    }

    /* Escape user input before rendering it back. */
    private String esc(String s) {
        if (s == null) return "";
        return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
                .replace("\"", "&quot;").replace("'", "&#39;");
    }
%>
<%
    request.setCharacterEncoding("UTF-8");
    String username  = request.getParameter("username");
    boolean submitted = request.getParameter("greet") != null;
    String result = null, error = null, token = null;

    if (submitted) {
        if (username == null || username.trim().isEmpty()) {
            error = "Please enter your name before continuing.";
        } else {
            username = username.trim();
            result   = "Hello, " + username + "!";
            token    = workToken(username);
        }
    }

    long visitNo = recordVisit();
    String now   = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>HIT DevOps Final - Asaf Arusi</title>
  <link rel="stylesheet" href="css/style.css">
</head>
<body>
  <main class="card">
    <p class="eyebrow">HIT 2026 &middot; Semester C &middot; Introduction to DevOps</p>

    <h1 id="heading">Deployed by Jenkins to Tomcat</h1>

    <p class="sub">This page was delivered from GitHub into production by a Jenkins pipeline.</p>

    <form id="greetForm" method="get" action="index.jsp" autocomplete="off">
      <label for="username">Your name</label>
      <div class="row">
        <input type="text" id="username" name="username" placeholder="e.g. Asaf"
               value="<%= esc(username) %>">
        <button type="submit" id="greetBtn" name="greet" value="1">Greet</button>
      </div>
    </form>

<% if (result != null) { %>
    <div id="result" class="result"><%= esc(result) %></div>
    <p id="token" class="token">request token: <%= token %></p>
<% } %>
<% if (error != null) { %>
    <div id="error" class="error"><%= error %></div>
<% } %>

    <p class="link-row">
      <a id="aboutLink" href="about.jsp">About this deployment &rarr;</a>
    </p>

    <footer class="meta">
      <span>served <span id="serverTime"><%= now %></span></span>
      <span>visit <span id="visitCount"><%= visitNo %></span></span>
    </footer>
  </main>
</body>
</html>
