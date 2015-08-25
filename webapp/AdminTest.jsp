<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.EmailSender"
%><%@page import="org.socialbiz.cog.MimeTypes"
%><%@page import="org.socialbiz.cog.NGBook"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.rest.NGLeafServlet"
%><%@page import="org.socialbiz.cog.NGSession"
%><%@page import="org.socialbiz.cog.SuperAdminLogFile"
%><%@page import="java.io.File"
%><%@page import="java.util.Properties"
%><%@page import="javax.mail.internet.MimeUtility"
%><%AuthRequest ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Must be logged in to run Admin page");
    if (!ar.isSuperAdmin())
    {
        throw new Exception("must be site administrator to use this Site Admin page");
    }

    //clear the session setting to force re-read of config file
    //maybe this should be done only on an error.
    ar.getSession().flushConfigCache();

    String startupProblem = "";
    if (NGLeafServlet.initializationException!=null)
    {
        startupProblem = NGLeafServlet.initializationException.toString();
    }

    Runtime rt = Runtime.getRuntime();%>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<html>
    <head>
        <title>main</title>
    </head>
    <body>


    <p> This is a test:

    <%

    String tval = "abc \u6771\u4eac";
    ar.writeHtml(tval);
    ar.write("</p><p>encoding: ");
    String eval = MimeUtility.encodeText(tval, "utf-8", "Q");
    ar.writeHtml(eval);

    String oval = MimeUtility.decodeText(eval);
    ar.write("</p><p>returned: ");
    ar.writeHtml(oval);


    %>

    </p>
    </body>
    </html>
<%@ include file="functions.jsp"%>
