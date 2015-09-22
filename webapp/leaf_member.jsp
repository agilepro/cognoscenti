<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.NGBook"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.NGSection"
%><%@page import="org.socialbiz.cog.NGSession"
%><%@page import="org.socialbiz.cog.SectionDef"
%><%@page import="org.socialbiz.cog.SectionFormat"
%><%@page import="org.socialbiz.cog.SectionUtil"
%><%@page import="org.socialbiz.cog.UserProfile"
%><%@page import="org.socialbiz.cog.UtilityMethods"
%><%@page import="java.io.Writer"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Vector"
%><%@page import="org.w3c.dom.Element"
%><%ar = AuthRequest.getOrCreate(request, response, out);
    ar.retPath="../../";

    /* if the parameter is not found in the parameters list, then find it out in the attributes list */
    String p = ar.reqParam("p");

    ngp = ar.getCogInstance().getProjectByKeyOrFail(p);
    ar.setPageAccessLevels(ngp);
    boolean isMember = ar.isMember();
    boolean isAdmin = ar.isAdmin();

    ngb = ngp.getSite();
    pageTitle = ngp.getFullName();
    specialTab = "Member Topics";
    newUIResource = "member.htm";

%>

<%@ include file="Header.jsp"%>
<%
        headlinePath(ar, "Member Only Section");

        if (!isMember  && !ar.isStaticSite())
        {
            if (!ar.isLoggedIn())
            {
                mustBeLoggedInMessage(ar);
            }
            else
            {
                mustBeMemberMessage(ar);
            }
        }
        else
        {
            if (!ar.isStaticSite())
            {
            %>
              <form action="<%= ar.retPath %>EditLeaflet.jsp" method="get" target="_blank">
              <input type="hidden" name="p" value="<% ar.writeHtml(p); %>">
              <input type="hidden" name="viz" value="2">
              <input type="hidden" name="go" value="<% ar.writeHtml(ar.getCompleteURL()); %>">
              <input type="submit" value="Create New Member Topic">

              </form>
            <%
            }
            writeLeaflets(ngp, ar, SectionDef.MEMBER_ACCESS);
        }

        out.flush();

%>


<%@ include file="Footer.jsp"%>
<%@ include file="functions.jsp"%>
