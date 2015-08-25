<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.workcast.streams.HTMLWriter"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGSession"
%><%@page import="org.socialbiz.cog.test.Crawler"
%><%@page import="java.io.File"
%><%@page import="java.io.PrintWriter"
%><%@page import="java.util.Properties"
%><%
    AuthRequest ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Can not run test page.");

    //this used to be a hack to allow test programs to log in easily
    //TODO: see if this still is necessary.
    session.setAttribute("allowOffline", "yes");

    int mode=0; // default = URL
    int level=1;// default = Exceptions, progress
    int yui=1;  // default = Hide

    String modeStr = ar.reqParam("mode");
    if (modeStr != null)
    {
        mode = Integer.parseInt(modeStr);
    }
    String modeMsg = null;
    if      (mode == 0) modeMsg = "Get page using URL";
    else if (mode == 1) modeMsg = "Get page by clicking on link";
    else                modeMsg = "unknown mode!";

    String levelStr = ar.reqParam("level");
    if (levelStr != null)
    {
        level = Integer.parseInt(levelStr);
    }
    String levelMsg = null;
    if      (level == 0) levelMsg = "Exceptions only";
    else if (level == 1) levelMsg = "Exceptions, progress";
    else if (level == 2) levelMsg = "Exceptions, progress, info";
    else                 levelMsg = "unknown level!";

    String uopenid = ar.getBestUserId();
    uopenid = ar.defParam("testid", uopenid);

    String yuiStr = ar.reqParam("yui");
    if (yuiStr != null)
    {
        yui = Integer.parseInt(yuiStr);
    }
    String yuiMsg = null;
    if      (yui == 0) yuiMsg = "Show";
    else if (yui == 1) yuiMsg = "Hide";
    else               yuiMsg = "unknown yui errors setting!!";

    //180 seconds is the default time limit
    int timeLimit = defParamInt(ar, "timeLimit", 180);

%>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<html>
<head>
    <title>main</title>
    <link href="mystyle.css" rel="stylesheet" type="text/css"/>
</head>
<body>
<%
    try {
        %><pre><%

        PrintWriter pw = new java.io.PrintWriter(out);

        String reqUrl = ar.getRequestURL();
        String servPath = request.getServletPath();
        String baseUrl = reqUrl.substring(0,reqUrl.indexOf(servPath));
        String startPage = ar.defParam("startPage", baseUrl);
        baseUrl += "/";
        pw.print("baseUrl = ");
        pw.println(baseUrl);
        pw.print("startPage = ");
        pw.println(startPage);
        pw.print("openid = ");
        pw.println(uopenid);
        pw.print("mode = ");
        pw.print(mode);
        pw.print(" (");
        pw.print(modeMsg);
        pw.println(")");
        pw.print("level = ");
        pw.print(level);
        pw.print(" (");
        pw.print(levelMsg);
        pw.println(")");
        pw.print("yui = ");
        pw.print(yui);
        pw.print(" (");
        pw.print(yuiMsg);
        pw.println(")");
        pw.print("timeout = ");
        pw.println(Integer.toString(timeLimit));

        Crawler crawler = new Crawler(baseUrl, uopenid, pw, mode, level, yui, timeLimit);
        crawler.setStartPage(startPage);
        crawler.runTests();
        pw.flush();
        %></pre><%
    }
    catch (Exception e)
    {
        %>
        <ul>
        <li>EXCEPTION: <% ar.writeHtml( e.toString()); %>
        <pre>
        <%
        PrintWriter pw = new PrintWriter(new HTMLWriter(out));
        e.printStackTrace(pw);
        pw.flush();
        %>
        </pre>
        </ul>
        <%
    }

%>
</ul>
<hr/>
<p>Return to <a href="Test.jsp">Test Page</a></p>
</body>
</html>

<%@ include file="functions.jsp"%>
