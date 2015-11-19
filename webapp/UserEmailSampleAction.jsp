<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.UtilityMethods"
%><%@page import="org.socialbiz.cog.UserManager"
%><%@page import="org.socialbiz.cog.UserProfile"
%><%@page import="java.io.Writer"
%><%@page import="java.io.StringWriter"
%><%
    AuthRequest ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Can not display this email sample uness you are logged in.");

    String to = ar.reqParam("to");

    UserProfile uProf = findSpecifiedUserOrDefault(ar);

    StringWriter bodyWriter = new StringWriter();
    AuthRequest clone = new AuthDummy(ar.getUserProfile(), bodyWriter, ar.getCogInstance());

    EmailSender.formatTaskListForEmail(bodyWriter, uProf, ar.baseURL);

    EmailSender.quickEmail(new AddressListEntry(to), null, subject, bodyWriter.toString());

    response.sendRedirect("UserAlerts.jsp?u="+uProf.getKey());

%><%@ include file="functions.jsp"%>
