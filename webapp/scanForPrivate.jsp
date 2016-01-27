<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="java.io.File"
%><%@page import="java.io.PrintWriter"
%><%@page import="java.io.FileInputStream"
%><%@page import="java.io.FileOutputStream"
%><%@page import="java.io.OutputStreamWriter"
%><%@page import="java.util.Properties"
%><%@page import="org.socialbiz.cog.AttachmentRecord"
%><%@page import="org.socialbiz.cog.AttachmentVersion"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGSession"
%><%AuthRequest ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Can not run test page.");

    String dataFolder = ar.getSystemProperty("dataFolder");%>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<html>
<head>
    <title>Check for private notes</title>
    <link href="mystyle.css" rel="stylesheet" type="text/css"/>
</head>
<body>
<h3>Check for private topics</h3>
<ul>
<%
    File thisDir = new File(dataFolder);
    File[] chilluns = thisDir.listFiles();




%>
</ul>
</body>
</html>

<%@ include file="functions.jsp"%>
