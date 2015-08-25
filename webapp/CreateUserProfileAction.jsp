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
    ar.assertLoggedIn("Can't create a user profile.");

    String userToFind = ar.reqParam("id");
    String go         = ar.reqParam("go");
    String action     = ar.reqParam("action");
    String idtype     = ar.reqParam("idtype");
    String name       = ar.reqParam("name");
    String encodingGuard       = ar.reqParam("encodingGuard");
    if (encodingGuard.length()!=2)
    {
        throw new Exception("Problem, encoding guard is: "+encodingGuard);
    }
    String desc       = ar.defParam("description", "");

    if (action.equalsIgnoreCase("CANCEL"))
    {
        response.sendRedirect(go);
        return;
    }

    if (!ar.isLoggedIn())
    {
        throw new Exception("Can't create the user profile, because you are not logged in.  Please login and then try again.");
    }

    UserProfile profile = UserManager.createUserWithId(userToFind);

    profile.setName(name);
    profile.setDescription(desc);
    profile.setLastUpdated(ar.nowTime);
    UserManager.writeUserProfilesToFile();

    response.sendRedirect(go);

%>
<%@ include file="functions.jsp"%>
