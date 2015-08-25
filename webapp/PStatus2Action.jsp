<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.BaseRecord"
%><%@page import="org.socialbiz.cog.LicensedURL"
%><%@page import="org.socialbiz.cog.NGBook"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.NGSection"
%><%@page import="org.socialbiz.cog.ProjectLink"
%><%@page import="org.socialbiz.cog.SectionFormat"
%><%@page import="org.socialbiz.cog.SectionUtil"
%><%@page import="org.socialbiz.cog.StatusReport"
%><%@page import="org.socialbiz.cog.GoalRecord"
%><%@page import="org.socialbiz.cog.UserProfile"
%><%@page import="org.socialbiz.cog.WatchRecord"
%><%@page import="org.socialbiz.cog.rest.TaskHelper"
%><%@page import="java.io.StringWriter"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Hashtable"
%><%@page import="java.util.List"
%><%@page import="java.util.Vector"
%><%@page import="org.w3c.dom.Element"
%><%
    AuthRequest ar = AuthRequest.getOrCreate(request, response, out);

    UserProfile uProf = findSpecifiedUserOrDefault(ar);
    UserPage uPage = UserPage.findOrCreateUserPage(uProf.getKey());

    String[] selected = ar.multiParam("watch");
    String statName = ar.reqParam("statName");
    String statDesc = ar.reqParam("statDesc");
    String srid = ar.reqParam("srid");
    boolean isCreateCase = srid.equals("xxx");

    StatusReport stat;
    if (isCreateCase) {
        stat = uPage.createStatusReport();
    }
    else {
        stat = uPage.findStatusReportOrFail(srid);
    }
    stat.setName(statName);
    stat.setDescription(statDesc);
    List<ProjectLink> projects = stat.getProjects();
    for (String s : selected) {
        boolean found = false;
        for (ProjectLink pl : projects) {
            if (s.equals(pl.getKey())) {
                pl.touchFlag = true;
                found = true;
            }
        }
        if (!found) {
            stat.getOrCreateProject(s);
        }
    }
    for (ProjectLink pl : projects) {
        if (!pl.touchFlag) {
            stat.deleteProject(pl.getKey());
        }
    }
    //save these updates now
    uPage.saveFile(ar, "Change to status report "+stat.getId());
    response.sendRedirect("PStatus3.jsp?srid="+stat.getId());

%>
<%@ include file="functions.jsp"%>
