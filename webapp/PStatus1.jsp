<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.AttachmentRecord"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.BaseRecord"
%><%@page import="org.socialbiz.cog.NGBook"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.NGSection"
%><%@page import="org.socialbiz.cog.SectionDef"
%><%@page import="org.socialbiz.cog.SectionFormat"
%><%@page import="org.socialbiz.cog.SectionUtil"
%><%@page import="org.socialbiz.cog.StatusReport"
%><%@page import="org.socialbiz.cog.GoalRecord"
%><%@page import="org.socialbiz.cog.UserProfile"
%><%@page import="org.socialbiz.cog.UserPage"
%><%@page import="org.socialbiz.cog.UtilityMethods"
%><%@page import="org.socialbiz.cog.WatchRecord"
%><%@page import="org.socialbiz.cog.rest.TaskHelper"
%><%@page import="java.io.Writer"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Hashtable"
%><%@page import="org.w3c.dom.Element"
%><%
    ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Unable to see status report.");

    uProf = findSpecifiedUserOrDefault(ar);
    UserPage uPage = UserManager.findOrCreateUserPage(uProf.getKey());

    pageTitle = "User: "+uProf.getName();
    specialTab = "Multi-Status";

%>
<%@ include file="Header.jsp"%>

            <div class="pagenavigation">
                <div class="pagenav">
                    <div class="left"><% ar.writeHtml( uProf.getName());%> &raquo; Active Action Items </div>
                    <div class="right"></div>
                    <div class="clearer">&nbsp;</div>
                </div>
                <div class="pagenav_bottom"></div>
            </div>

 <div class="section">
    <div class="section_title">
        <h1 class="left">Multi Project Status Report</h1>
        <div class="section_date right"></div>
        <div class="clearer">&nbsp;</div>
    </div>
    <div class="section_body">
    <table>
        <col width="30">
        <col width="30">
        <col width="200">
        <tr>
           <td></td>
           <td></td>
           <td><b>Report to Edit</b></td>
        </tr>
        <tr>
            <td><form action="PStatus2.jsp">
                <input type="hidden" name="srid" value="xxx">
                <input type="submit" value="Create New"></form></td>
            <td></td>
            <td> &lt; Create New &gt; </td>
        <tr>
<%

    for (StatusReport stat : uPage.getStatusReports())
    {
        %>
        <tr>
            <td><form action="PStatus2.jsp">
                <input type="hidden" name="srid" value="<%ar.writeHtml(stat.getId());%>">
                <input type="submit" value="Edit Settings"></form></td>
            <td><form action="PStatus3.jsp">
                <input type="hidden" name="srid" value="<%ar.writeHtml(stat.getId());%>">
                <input type="submit" value="View"></form></td>
            <td><%ar.writeHtml(stat.getName());%></td>
        <tr>

        <%
    }

%>
    </table>
    </div>
</div>




<%
    out.flush();

%>


<%@ include file="Footer.jsp"%>
<%@ include file="functions.jsp"%>
