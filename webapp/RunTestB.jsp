<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="java.io.File"
%><%@page import="java.io.PrintWriter"
%><%@page import="java.util.Properties"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGSession"
%><%@page import="org.socialbiz.cog.test.TestBuildSite"
%><%@page import="org.workcast.streams.HTMLWriter"
%><%@page import="org.workcast.testframe.TestRecorder"
%><%@page import="org.workcast.testframe.TestRecorderText"
%><%
    AuthRequest ar = AuthRequest.getOrCreate(request, response, out);

    session.setAttribute("allowOffline", "yes");

    ar.assertLoggedIn("Can not run Test page");
    String uopenid = ar.getBestUserId();

    TestRecorderText tr = new TestRecorderText(new HTMLWriter(out), true, new String[0], "./");


%>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<html>
<head>
    <title>main</title>
    <link href="mystyle.css" rel="stylesheet" type="text/css"/>
</head>
<body>

<br/>
<p>Starting tests...</p>
<pre>
<%
    out.flush();

    try {
        TestBuildSite tbs = new TestBuildSite(ar.getCogInstance());
        tbs.runTests(tr);
    }
    catch (Exception e) {
        e.printStackTrace(new PrintWriter(out));
    }

    out.flush();

%>
</pre>
<p>completed</p>
<p>Summary: <%=tr.passedCount()%> passed, <%=tr.failedCount()%> failed, <%=tr.fatalCount()%> fatal errors</p>

</body>
</html>

<%@ include file="functions.jsp"%>
