<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.License"
%><%@page import="org.socialbiz.cog.LicensedURL"
%><%@page import="org.socialbiz.cog.NGBook"
%><%@page import="org.socialbiz.cog.NGRole"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.NGSection"
%><%@page import="org.socialbiz.cog.NGSession"
%><%@page import="org.socialbiz.cog.SectionDef"
%><%@page import="org.socialbiz.cog.SectionFormat"
%><%@page import="org.socialbiz.cog.SectionUtil"
%><%@page import="org.socialbiz.cog.UserManager"
%><%@page import="org.socialbiz.cog.UserProfile"
%><%@page import="org.socialbiz.cog.UtilityMethods"
%><%@page import="java.io.Writer"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Iterator"
%><%@page import="java.util.List"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Vector"
%><%@page import="org.w3c.dom.Element"
%><%
    ar = AuthRequest.getOrCreate(request, response, out);

    String p = ar.reqParam("p");
    String r = ar.reqParam("r");

    ngp = ar.getCogInstance().getProjectByKeyOrFail(p);
    ar.setPageAccessLevels(ngp);

    NGRole role = ngp.getRoleOrFail(r);

    String go = "PageRole.jsp?p="+URLEncoder.encode(p, "UTF-8")+"&r="+URLEncoder.encode(r, "UTF-8");

    pageTitle = "Join the "+r+" Role of "+ngp.getFullName();
    specialTab = "Permissions";
%>
<%@ include file="Header.jsp"%>

<%
    headlinePath(ar, "Role "+r);

%>

<div class="section">
<!-- ------------------------------------------------- -->
    <div class="section_title">
    Request to Join Role

    </div>
    <div class="section_body">
    <p>
    <table >
    <col width="120">
    <col width="600">


    <tr valign="top">
      <td>Role:</td>
      <td><b><%ar.writeHtml(role.getName());%></b></td>
    </tr>
    <tr valign="top">
      <td>Description:</td>
      <td><%ar.writeHtml(role.getDescription());%><br/>&nbsp;</td>
    </tr>
    <tr valign="top">
      <td>Eligibility:</td>
      <td><%ar.writeHtml(role.getRequirements());%><br/>&nbsp;</td>
    </tr>
    <tr valign="top">
      <td>Reason:</td>
      <td><textarea name=""></textarea></td>
    </tr>
    <tr valign="top">
      <td></td>
      <td><input type="submit" value="Request to Join Role"/></td>
    </tr>
    </table>
    </div>
</div>

<p></p>
<p></p>
<p></p>

<%@ include file="Footer.jsp"%>
<%@ include file="functions.jsp"%>
