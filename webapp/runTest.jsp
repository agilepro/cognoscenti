<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.workcast.streams.HTMLWriter"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGSession"
%><%@page import="java.io.File"
%><%@page import="java.io.PrintWriter"
%><%@page import="java.util.Properties"
%><%
    AuthRequest ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Can not run test page.");

    String dataFolder = ar.getSystemProperty("dataFolder");


%>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<html>
<head>
    <title>main</title>
    <link href="mystyle.css" rel="stylesheet" type="text/css"/>
</head>
<body>
<h3>NuGen Page Listing</h3>
<ul>
<%

    File thisDir = new File(dataFolder);
    File[] chilluns = thisDir.listFiles();
    int limit=5;

    for (int i=0; i<chilluns.length && limit>0; i++) {

        File chile = chilluns[i];
        if (chile.isDirectory()) {
            continue;
        }
        String cname = chile.getName();
        if (!cname.endsWith(".sp")) {
            continue;
        }
        NGPage aPage = NGPage.readPageAbsolutePath(chile);

        %>
        <li>TESTING: <a href="<%ar.writeHtml(ar.getResourceURL(aPage,""));%>"><%
            ar.writeHtml(aPage.getOldUIPermaLink());
        %></a>
        <%
        out.flush();
        Thread.sleep(999);   //wait a second so you don't max the machine

        try
        {
            aPage.testRender(ar);
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
            limit--;
            %>
            </pre>
            </ul>
            <%
        }

    }


%>
</ul>
</body>
</html>

<%@ include file="functions.jsp"%>
