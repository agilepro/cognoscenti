<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.SectionUtil"
%><%@page import="java.util.Vector"
%><%
    AuthRequest ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Unable to hook a link.");

    String link = ar.reqParam("p");
    String go = ar.reqParam("go");

    List v = ar.getCogInstance().getPageIndexByName(link);

    if (v.size()==0) {
        throw new Exception("Can not find any pages named '"+link+"'.  You can only hook a link to an existing page.");
    }

    session.setAttribute("hook", link);

    response.sendRedirect(go);
%>
<%@ include file="functions.jsp"%>
