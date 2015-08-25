<%@page errorPage="/spring/jsp/error.jsp"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.NGBook"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.UserProfile"
%><%@page import="org.socialbiz.cog.UtilityMethods"
%><%@page import="java.io.Writer"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Vector"
%><%@page import="org.w3c.dom.Element"
%>
<a href="javascript:window.close();">Close</a>
<%
AuthRequest ar = AuthRequest.getOrCreate(request, response, out);
%>
<%@ include file="functions.jsp"%>
<!-- Generated in <%= (System.currentTimeMillis()-ar.nowTime) %> milliseconds -->
<script>window.close();</script>
