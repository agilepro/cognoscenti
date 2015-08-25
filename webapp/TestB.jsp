<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="java.io.File"
%><%@page import="java.io.PrintWriter"
%><%@page import="java.util.Properties"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGSession"
%><%@page import="org.socialbiz.cog.test.Crawler"
%><%
    AuthRequest ar = AuthRequest.getOrCreate(request, response, out);

    session.setAttribute("allowOffline", "yes");

    ar.assertLoggedIn("Can not run Test page");
    String uopenid = ar.getBestUserId();



%>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<html>
<head>
    <title>main</title>
    <link href="mystyle.css" rel="stylesheet" type="text/css"/>
</head>
<body>

<br/>
<p>This is the automated suite of tests</p>

<ul>
<li>Make sure that no site exists with the key "tst80808".
   Any such site must be manually deleted before running the test</li>
</ul>
<form name="main" action="RunTestB.jsp">

<button type="submit" name="act" value="Run">Run Tests</button>
<button type="submit" name="act" value="Clean">Clean Up</button>
</form>

</body>
</html>

<%@ include file="functions.jsp"%>
