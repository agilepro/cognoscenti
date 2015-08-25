<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.NGBook"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.NGSection"
%><%@page import="org.socialbiz.cog.NGSession"
%><%@page import="org.socialbiz.cog.ProcessRecord"
%><%@page import="org.socialbiz.cog.SectionUtil"
%><%@page import="org.socialbiz.cog.GoalRecord"
%><%@page import="org.socialbiz.cog.UserManager"
%><%
    AuthRequest ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Can't use administration functions.");
    if (!ar.isSuperAdmin())
    {
        throw new Exception("Can only be performed by super admin");
    }
    String go = ar.reqParam("go");
    String u  = ar.reqParam("u");
    String action = ar.reqParam("action");

    UserProfile uProf = findSpecifiedUserOrDefault(ar);


    if (action.equals("Disable User"))
    {
        uProf.setDisabled(true);
        UserManager.writeUserProfilesToFile();
    }

    response.sendRedirect(go);

%>




<%@ include file="functions.jsp"%>
