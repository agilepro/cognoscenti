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
%><%ar = AuthRequest.getOrCreate(request, response, out);
    ar.retPath="../../";

    String p = ar.reqParam("p");

    ngp = ar.getCogInstance().getProjectByKeyOrFail(p);
    ar.setPageAccessLevels(ngp);
    boolean isMember = ar.isMember();
    boolean isAdmin = ar.isAdmin();

    String[] names = ngp.getPageNames();

    ngb = ngp.getSite();
    if (ngb==null)
    {
        throw new Exception("Logic Error, should never get a null value from getAccount");
    }
    String go = ar.getCompleteURL();

    String userAccessLimit = (String) session.getAttribute("userAccessLimit");
    int maxLevel = 4;
    if (userAccessLimit!=null && userAccessLimit.length()==1)
    {
        maxLevel = userAccessLimit.charAt(0)-'0';
    }

    pageTitle = ngp.getFullName();
    specialTab = "Permissions";
    newUIResource = "permission.htm";%>
<%@ include file="Header.jsp"%>

<%
        headlinePath(ar, "Permissions");
%>

<%
if (!ar.isLoggedIn())
{
    mustBeLoggedInMessage(ar);
}
else if (!isMember)
{
    mustBeMemberMessage(ar);
}
else
{
%>

<div class="section">
<!-- ------------------------------------------------- -->
    <div class="section_title">
    Roles
    </div>
    <div class="section_body">
    <p>
    <%
        writeAllRolesX(ar, ngp);

    %>
    </p>

    </div>
</div>



<div class="section">
<!-- ------------------------------------------------- -->
    <div class="section_title">
    Licenses
    </div>
    <div class="section_body">

<% if (ar.isMember()) { %>

<table>
<col width="200">
<col width="200">
<col width="200">
<%
    for (License lr : ngp.getLicenses())
    {
        // add one so that the license is valid until it is zero
        // when there is a fraction of a day left, it will still show "1"
        // and when it goes to zero, the license is no longer valid.
        int days = (int)((lr.getTimeout() - ar.nowTime)/24000/3600) + 1;
        if (days<0)
        {
            days=0;
        }

        LicensedURL fullPath = new LicensedURL(ar.baseURL + ar.getResourceURL(ngp,""), null, lr.getId());
        LicensedURL projectPath = new LicensedURL(ar.baseURL + ar.getResourceURL(ngp,"leaf.xml"), null, lr.getId());
        LicensedURL processPath = new LicensedURL(ar.baseURL + ar.getResourceURL(ngp,"process.wfxml"), null, lr.getId());

        UserProfile creatorUser = UserManager.findUserByAnyId(lr.getCreator());

%>
    <tr><td><%

            if (creatorUser==null) {
                ar.writeHtml("?"+lr.getCreator()+"?");
            }
            else {
                creatorUser.writeLink(ar);
            }

        %> / <% ar.writeHtml(SectionUtil.cleanName(lr.getRole()));%> </td>
        <td><%=days%> days</td>
        <td><a href="<%ar.writeHtml(fullPath.getCombinedRepresentation());%>">Licensed Link</a>,
            <a href="<%ar.writeHtml(projectPath.getCombinedRepresentation());%>">Project</a>,
            <a href="<%ar.writeHtml(processPath.getCombinedRepresentation());%>">Process</a></td></tr><%
    }
%>
</table>

<form action="<%=ar.retPath%>LicenseAction.jsp" method="post">
<input type="hidden" name="encodingGuard" value="<%ar.writeHtml("\u6771\u4eac");%>"/>
<input type="hidden" name="go" value="<%ar.writeHtml(go);%>">
<input type="hidden" name="p" value="<%ar.writeHtml(p);%>">
<input type="submit" name="action" value="Create License"> for
<input type="text" name="duration" value="60" size="5"> days for role:
<select name="role">
    <%for (NGRole aRole : ngp.getAllRoles()) {%>
    <option value="<%ar.writeHtml(aRole.getName());%>"><%ar.writeHtml(aRole.getName());%></option>
    <% } %>
</select>
</form>

<% } else { %>

    Licenses are available only to members

<% } %>
    </div>
</div>


<%
}    //end of the main access control block
%>

<%!public void writeAllRolesX(AuthRequest ar, NGPage ngp)
        throws Exception
    {
        for (NGRole aRole : ngp.getAllRoles())
        {
            String r = aRole.getName();
            ar.write("\n<br/><h2>");
            ar.writeHtml(r);
            ar.write(" - <a href=\"");
            ar.write(ar.retPath);
            ar.write("PageRole.jsp?p=");
            ar.writeURLData(ngp.getKey());
            ar.write("&r=");
            ar.writeURLData(r);
            ar.write("\">Edit</a>");
            ar.write(" - <a href=\"");
            ar.write(ar.retPath);
            ar.write("InvitePlayers.jsp?p=");
            ar.writeURLData(ngp.getKey());
            ar.write("&r=");
            ar.writeURLData(r);
            ar.write("\">Invite</a>");
            if (aRole.isPlayer(ar.getUserProfile()))
            {
                ar.write(" (You are a player)");
            }
            ar.write("</h2>");
            ar.write("\n<table>");

            ar.write("\n<table><col width=\"200\"><col width=\"20\"><col width=\"200\"><tr><td>");

            List <AddressListEntry> allUsers = aRole.getExpandedPlayers(ngp);
            for (AddressListEntry ale : allUsers)
            {
                ale.writeLink(ar);
                ar.write("<br/>");
            }

            ar.write("\n</td><td>&nbsp;</td><td>");
            for (AddressListEntry ale : allUsers)
            {
                ar.writeHtml(ale.getEmail());
                ar.write("<br/>");
            }


            ar.write("\n</td></tr></table>");
        }
    }%>
<%@ include file="Footer.jsp"%>
<%@ include file="functions.jsp"%>
