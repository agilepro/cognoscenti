<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.EmailSender"
%><%@page import="org.socialbiz.cog.UtilityMethods"
%><%@page import="org.socialbiz.cog.UserManager"
%><%@page import="org.socialbiz.cog.UserProfile"
%><%@page import="java.io.Writer"
%><%
    AuthRequest ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Can not display this email sample uness you are logged in.");

    UserProfile uProf = findSpecifiedUserOrDefault(ar);

%>
<html><body>
<form method="post" action="UserEmailSampleAction.jsp"><input type="submit" name="action" value="Send Email"> to:
<input type="text" name="to" value="<% ar.writeHtml(uProf.getPreferredEmail()); %>" size="50">
<input type="hidden" name="uid" value="<% ar.writeHtml(uProf.getPreferredEmail()); %>"></form>
<hr/>
<%
    EmailSender.formatTaskListForEmail(ar, uProf);
%>

<%@ include file="functions.jsp"%>
