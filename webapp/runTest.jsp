<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.workcast.streams.HTMLWriter"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGSession"
%><%@page import="java.io.File"
%><%@page import="java.io.PrintWriter"
%><%@page import="java.util.Properties"
%><%
    AuthRequest ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Can not run test page.");

    throw new Exception("Test page needs to be rewritten for new site structure");

%>
</ul>
</body>
</html>

<%@ include file="functions.jsp"%>
