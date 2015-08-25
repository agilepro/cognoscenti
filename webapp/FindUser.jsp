<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.SectionUtil"
%><%@page import="org.socialbiz.cog.UtilityMethods"
%><%@page import="org.socialbiz.cog.UserManager"
%><%@page import="org.socialbiz.cog.UserProfile"
%><%@page import="java.io.Writer"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Vector"
%><%
    AuthRequest ar = AuthRequest.getOrCreate(request, response, out);

    // the purpose of this page is
    // that you have an id, either an email addres, or an openid
    // and you want to look at the profile for that user.  This will
    // find the user profile, and redirect the browser to display it.
    String userToFind = ar.defParam("id", null);


    UserProfile up = UserManager.findUserByAnyId(userToFind);
    if (up!=null)
    {
        response.sendRedirect("UserHome.jsp?u="+up.getKey());
        return;
    }

    response.sendRedirect("CreateUserProfile.jsp?id="+URLEncoder.encode(userToFind, "UTF-8"));

%>
<%@ include file="functions.jsp"%>
