<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%
    ar = AuthRequest.getOrCreate(request, response, out);
    pageTitle = "Close This Browser Window";
%>
<%@ include file="Header.jsp"%>

<a href="javascript:window.close();">Close</a>

<%@ include file="Footer.jsp"%>
<%@ include file="functions.jsp"%>
<!-- Generated in <%= (System.currentTimeMillis()-ar.nowTime) %> milliseconds -->
<script>window.close();</script>
