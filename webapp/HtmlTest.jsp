<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.NGBook"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.NGSession"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.WikiConverter"
%><%@page import="org.socialbiz.cog.HtmlToWikiConverter"
%><%@page import="java.io.File"
%><%@page import="java.util.Properties"
%><%@page import="java.io.StringWriter"
%><%
    AuthRequest ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Can not run html converter test page");

    String html2 = ar.defParam("html2", "");


    String wiki3 = "";
    try
    {
        HtmlToWikiConverter hc = new HtmlToWikiConverter();
        wiki3 = hc.htmlToWiki(html2);
    }
    catch (Exception e)
    {
        wiki3 = e.toString();
    }



%>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<html>
    <head>
        <title>html converter test page</title>
    </head>
    <body>
    <h3>html converter test page</h3>
    <form action="HtmlTest.jsp" method="POST">
        <input type="hidden" name="encodingGuard" value="<%ar.writeHtml("\u6771\u4eac");%>"/>
        <textarea name="html2" rows="7" cols="80"><%ar.writeHtml(html2);%></textarea><br/>
        <input type="submit" value="Test">
        </form>

    <hr>

    <h3>wiki conversion</h3>

<form method="post" action="WikiTest.jsp">
<input type="hidden" name="encodingGuard" value="<%ar.writeHtml("\u6771\u4eac");%>"/>
<textarea name="wiki1" rows="7" cols="80"><%ar.writeHtml(wiki3);%></textarea><br/>
<input type="submit" value="Return to Wiki Test">
</form>

    <hr>
</body>
</html>