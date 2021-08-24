<%@page errorPage="/spring/jsp/error.jsp"
%><%@page import="com.purplehillsbooks.weaver.AuthRequest"
%><%@page import="com.purplehillsbooks.weaver.NGBook"
%><%@page import="com.purplehillsbooks.weaver.NGPageIndex"
%><%@page import="com.purplehillsbooks.weaver.UserProfile"
%><%@page import="com.purplehillsbooks.weaver.UtilityMethods"
%><%@page import="java.io.Writer"
%><%@page import="java.net.URLEncoder"
%><%@page import="org.w3c.dom.Element"
%>
<a href="javascript:window.close();">Close</a>
<%
AuthRequest ar = AuthRequest.getOrCreate(request, response, out);
%>
<%@ include file="functions.jsp"%>
<!-- Generated in <%= (System.currentTimeMillis()-ar.nowTime) %> milliseconds -->
<script>window.close();</script>
