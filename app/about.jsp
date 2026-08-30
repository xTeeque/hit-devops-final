<%@ page contentType="text/html; charset=UTF-8" language="java" %>
<%@ page import="java.time.LocalDateTime" %>
<%@ page import="java.time.format.DateTimeFormatter" %>
<%
    String now = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>About - HIT DevOps Final</title>
  <link rel="stylesheet" href="css/style.css">
</head>
<body>
  <main class="card">
    <p class="eyebrow">About</p>
    <h1 id="aboutHeading">How this page got here</h1>

    <ol class="steps">
      <li>Code is committed and pushed to <strong>GitHub</strong>.</li>
      <li><strong>Jenkins</strong> polls the repository and detects the new commit.</li>
      <li>The deploy job copies the application into Tomcat's <code>webapps</code> folder.</li>
      <li>Tomcat recompiles the JSP on the next request &mdash; no restart required.</li>
    </ol>

    <table class="facts">
      <tr><th>Submitted by</th><td id="authors">Asaf Arusi</td></tr>
      <tr><th>Course</th><td>Introduction to DevOps &mdash; HIT 2026, Semester C</td></tr>
      <tr><th>Servlet container</th><td id="serverInfo"><%= application.getServerInfo() %></td></tr>
      <tr><th>Servlet API</th><td><%= application.getMajorVersion() %>.<%= application.getMinorVersion() %></td></tr>
      <tr><th>Java runtime</th><td><%= System.getProperty("java.version") %></td></tr>
      <tr><th>Context path</th><td><%= request.getContextPath() %></td></tr>
      <tr><th>Rendered at</th><td><%= now %></td></tr>
    </table>

    <p class="link-row">
      <a id="homeLink" href="index.jsp">&larr; Back to the application</a>
    </p>
  </main>
</body>
</html>
