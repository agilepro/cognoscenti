<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.AttachmentRecord"
%><%@page import="org.socialbiz.cog.AttachmentVersion"
%><%@page import="org.socialbiz.cog.AuthDummy"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.workcast.streams.HTMLWriter"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGSession"
%><%@page import="org.socialbiz.cog.util.UnclosableWriter"
%><%@page import="org.socialbiz.cog.spring.SpringServletWrapper"
%><%@page import="java.io.File"
%><%@page import="java.io.FileInputStream"
%><%@page import="java.io.FileOutputStream"
%><%@page import="java.io.OutputStreamWriter"
%><%@page import="java.io.PrintWriter"
%><%@page import="java.util.Properties"
%><%@page import="org.apache.jasper.runtime.JspWriterImpl"
%><%
    AuthRequest ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Can not run test page.");
    
    throw new Exception("This needs to be rewritter for new site strcture");

%>