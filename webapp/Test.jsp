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
Make sure config.txt has allowOffline=yes.
Select test options and click the button below to run tests.
<form name="main" action="RunTests.jsp">
<table border="0">
    <tr><td colspan="2"><b>OpenID to use for the test</b> (will not be validated)</td></tr>
    <tr><td>&nbsp;&nbsp;&nbsp;&nbsp;</td><td>
    <input type="text" size="50" name="testid" value="<%ar.writeHtml(uopenid);%>">
</table>
<br/>
<table border="0">
    <tr><td colspan="2"><b>Start Page Address</b></td></tr>
    <tr><td>&nbsp;&nbsp;&nbsp;&nbsp;</td><td>
    <input type="text" size="50" name="startPage" value="<%ar.writeHtml(startPage);%>">
</table>
<br/>
<table border="0">
    <tr><td colspan="2"><b>Crawl mode</b></td></tr>
    <tr><td>&nbsp;&nbsp;&nbsp;&nbsp;</td><td><INPUT TYPE=radio NAME="mode" VALUE="0" checked="checked">Get page using URL (faster)</input></td></tr>
    <tr><td></td><td><INPUT TYPE=radio NAME="mode" VALUE="1">Get page by clicking on link (different test, slower)</input></td></tr>
</table>
<br/>
<table border="0">
    <tr><td colspan="2"><b>Output level</b></td></tr>
    <tr><td>&nbsp;&nbsp;&nbsp;&nbsp;</td><td><INPUT TYPE=radio NAME="level" VALUE="0">Exceptions only (fastest)</input></td></tr>
    <tr><td></td><td><INPUT TYPE=radio NAME="level" VALUE="1" checked="checked">Exceptions, progress (default)</input></td></tr>
    <tr><td></td><td><INPUT TYPE=radio NAME="level" VALUE="2">Exceptions, progress, info (slowest)</input></td></tr>
</table>
<br/>
<table border="0">
    <tr><td colspan="2"><b>YUI Errors</b></td></tr>
    <tr><td>&nbsp;&nbsp;&nbsp;&nbsp;</td><td><INPUT TYPE=radio NAME="yui" VALUE="0" checked="checked">Show</input></td></tr>
    <tr><td></td><td><INPUT TYPE=radio NAME="yui" VALUE="1">Hide</input></td></tr>
</table>
<br/>
<table border="0">
    <tr><td colspan="2"><b>Time Limit</b></td></tr>
    <tr><td>&nbsp;&nbsp;&nbsp;&nbsp;</td><td><INPUT TYPE="text" NAME="timeLimit" VALUE="180"/> (seconds)</td></tr>
</table>
<input type="submit" value="Run Tests"/>
</form>

<p>Please note: there is a problem with the HtmlUnit classes.  If the page has javascript that is invoked through a time delay
and that script invokes itself through a time delay, the HtmlUnit will start a thread that runs forever.  Unable to find a solution
to this problem yet, it is the case that after running this test, you will need to restart your TomCat server, in order to
stop this continual background processing.</p>

</body>
</html>

<%@ include file="functions.jsp"%>
