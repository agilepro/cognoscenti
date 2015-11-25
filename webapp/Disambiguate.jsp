<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGBook"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.SectionUtil"
%><%@page import="org.socialbiz.cog.UserProfile"
%><%@page import="org.socialbiz.cog.GoalRecord"
%><%@page import="org.socialbiz.cog.UtilityMethods"
%><%@page import="org.socialbiz.cog.rest.TaskHelper"
%><%@page import="java.io.Writer"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Enumeration"
%><%@page import="org.w3c.dom.Element"
%><%

    ar = AuthRequest.getOrCreate(request, response, out);

    String n = ar.reqParam("n");

    Vector pages = ar.getCogInstance().getPageIndexByName(n);

    if (pages==null) {
        throw new Exception("ar.getCogInstance().getPageIndexByName returned a null!.");
    }
    pageTitle = "Disambiguate: "+n;

%>
<%@ include file="Header.jsp"%>

    <div class="pagenavigation">
        <div class="pagenav">
            <div class="left">Disambiguation Page </div>
            <div class="right"></div>
            <div class="clearer">&nbsp;</div>
        </div>
        <div class="pagenav_bottom"></div>
    </div>

    <div class="section">
        <div class="section_title">
            <h1 class="left">Choose a page</h1>
            <div class="section_date right"></div>
            <div class="clearer">&nbsp;</div>
        </div>
        <div class="section_body">
            There are <%=pages.size()%> pages with the names that match '<%ar.writeHtml(n);%>'.  Choose below the page to navigate to.
            <br/>&nbsp;
            <table>
                <col width="150">
                <col width="150">
                <col width="400">
                <tr>
                    <td>Page Name</td>
                    <td>Last Changed</td>
                    <td>Admin(s)</td>
<%
    Enumeration ex = pages.elements();
    while (ex.hasMoreElements())
    {
        NGPageIndex ngpi = (NGPageIndex) ex.nextElement();
        String thisName = ngpi.containerName;
        if (thisName.length()>25)
        {
            thisName = thisName.substring(0,25);
        }
        %>
        <tr><td><a href="p/<%=ngpi.containerKey%>/public.htm"><%
        ar.writeHtml(thisName);
        %></a></td><td><%
        SectionUtil.nicePrintTime(ar, ngpi.lastChange, ar.nowTime);
        %></td><td><%
        for (int i=0; i<ngpi.admins.length; i++)
        {
            if (i>0)
            {
                out.write("<br/>");
            }
            %><a href="EditUserProfile.jsp?id=<%
            ar.writeURLData(ngpi.admins[i]);
            %>"><%
            ar.writeHtml(SectionUtil.cleanName(ngpi.admins[i]));
            %></a><%
        }
        %></td></tr><%
    }
%>
            </table>
            <br/>
            Note: Workspaces can have multiple names.  The first name is the current name
            (the name seen at the top of the page) but the old names can still be used
            to link to that leaf.  If the old name is no longer appropriate for that
            project, you may wish to delete the old name in order to eliminate
            duplication of projects with the same name.
        </div>
    </div>

<%
    out.flush();

%>


<%@ include file="Footer.jsp"%>
<%@ include file="functions.jsp"%>
