<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.EmailListener"
%><%@page import="org.socialbiz.cog.NGBook"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.NGSection"
%><%@page import="org.socialbiz.cog.SectionUtil"
%><%@page import="org.socialbiz.cog.GoalRecord"
%><%
    request.setCharacterEncoding("UTF-8");
    long starttime = System.currentTimeMillis();
    boolean createNewSubPage = false;

    AuthRequest ar = AuthRequest.getOrCreate(request, response, out);

    String action = request.getParameter("action");

%>

<html>
<body>
<h3>Sending Email</h3>
<hr/>
<%


    if ("Send Email".equals(action))
    {
        throw new Exception("Can not Send Email any more, can ONLY use the background scheduled email sender");
    }
    else if ("Pick Up Emails".equals(action))
    {
        %>Reading Email<br/><%
        EmailListener el = new EmailListener(ar);
        el.handleMailsUsingPOP3();
        %>Done Reading Email<br/><%
    }
    else
    {
        throw new Exception("No idea what the action '"+action+"' is supposed to do.");
    }
%>

<hr/>

<%@ include file="functions.jsp"%>
