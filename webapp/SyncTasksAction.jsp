<%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.NGBook"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.NGSection"
%><%@page import="org.socialbiz.cog.NGSession"
%><%@page import="org.socialbiz.cog.rest.RssServlet"
%><%@page import="org.socialbiz.cog.SectionDef"
%><%@page import="org.socialbiz.cog.SectionFormat"
%><%@page import="org.socialbiz.cog.SectionUtil"
%><%@page import="org.socialbiz.cog.SectionUtil"
%><%@page import="org.socialbiz.cog.UserProfile"
%><%@page import="org.socialbiz.cog.UtilityMethods"
%><%@page import="org.socialbiz.cog.rest.TaskHelper"
%><%@page import="java.io.Writer"
%><%@page import="java.net.URLEncoder"
%><%
    AuthRequest ar = null;
    String goUrl = "";
    String pageTitle = null;
    String newUIResource = "public.htm";
    UserProfile uProf = null;
    String specialTab = "";


    ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Can't synchronize Task list.");

    String go = ar.reqParam("go");
    uProf = ar.getUserProfile();
    UserPage uPage = UserPage.findOrCreateUserPage(uProf.getKey());

    TaskHelper th = new TaskHelper(uProf.getUniversalId(), "");
    th.scanAllTask(ar.getCogInstance());
    th.syncTasksToProfile(uPage, ar.getCogInstance());

    uPage.saveFile(ar,"Synchronize Action Items from Workspaces");

    response.sendRedirect(go);

%>
<%@ include file="functions.jsp"%>
