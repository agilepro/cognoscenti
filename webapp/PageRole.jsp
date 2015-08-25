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

    ar.assertMember("Unable to edit the roles of this page");

    NGRole role = ngp.getRole(r);

    String go = "PageRole.jsp?p="+URLEncoder.encode(p, "UTF-8")+"&r="+URLEncoder.encode(r, "UTF-8");

    pageTitle = r+" Role of "+ngp.getFullName();
    specialTab = "Permissions";
%>
<%@ include file="Header.jsp"%>

<%
    headlinePath(ar, "Role "+r);

    if (role == null)
    {

%>
<div class="section">
<!-- ------------------------------------------------- -->
    <div class="section_title">
    Non-existing Role '<%ar.writeHtml(r);%>'

    </div>
    <div class="section_body">

    <p>No role exists named '<%ar.writeHtml(r);%>', would you like to create one?</p>

    <p>Description for role '<%ar.writeHtml(r);%>':</p>
    <form action="<%=ar.retPath%>PageRoleAction.jsp" method="post">
        <input type="hidden" name="go" value="<% ar.writeHtml(go); %>">
        <input type="hidden" name="id" value="na">
        <textarea name="desc"></textarea>
        <input type="hidden" name="p" value="<%ar.writeHtml(ngp.getKey());%>">
        <input type="hidden" name="r" value="<%ar.writeHtml(r);%>"><br/>
        <input type="submit" name="op" value="Create Role">
    </form>

    </div>
</div>


<%
    }
    else
    {
%>

<div class="section">
<!-- ------------------------------------------------- -->
    <div class="section_title">
    List of Direct Players

    </div>
    <div class="section_body">
    <p>
    <table>
    <%

        List<AddressListEntry> allUsers = role.getDirectPlayers();
        for (AddressListEntry ale : allUsers)
        {
            %>
            <tr><td><%
            if (ale.isRoleRef())
            {
                %>
                <a href="PageRole.jsp?p=<%ar.writeURLData(p);%>&r=<%ar.writeURLData(ale.getInitialId());%>">
                Role: <%ar.writeHtml(ale.getInitialId());%></a></td><td>
                <%
            }
            else
            {
                ale.writeLink(ar);
                ar.write("</td><td>");
                ar.writeHtml(ale.getEmail());
            }
         %>
            </td>
            <form action="<%=ar.retPath%>PageRoleAction.jsp" method="post">
            <td>
                <input type="hidden" name="go" value="<% ar.writeHtml(go); %>">
                <input type="hidden" name="id" value="<% ar.writeHtml(ale.getStorageRepresentation()); %>">
                <input type="hidden" name="p" value="<%ar.writeHtml(ngp.getKey());%>">
                <input type="hidden" name="r" value="<%ar.writeHtml(role.getName());%>">
                <input type="submit" name="op" value="Remove">
            </td></form></tr>
        <%
        }
        %>
        </table>
            <h3>Add A User</h3><form action="<%=ar.retPath%>PageRoleAction.jsp" method="post">
                <input type="hidden" name="go" value="<% ar.writeHtml(go); %>">
                <input type="text" name="id" value="">
                <input type="hidden" name="p" value="<%ar.writeHtml(ngp.getKey());%>">
                <input type="hidden" name="r" value="<%ar.writeHtml(role.getName());%>">
                <input type="submit" name="op" value="Add">
            </form><br/>
            <h3>Add A Role</h3><form action="<%=ar.retPath%>PageRoleAction.jsp" method="post">
                <input type="hidden" name="go" value="<% ar.writeHtml(go); %>">
                <input type="text" name="id" value="">
                <input type="hidden" name="p" value="<%ar.writeHtml(ngp.getKey());%>">
                <input type="hidden" name="r" value="<%ar.writeHtml(role.getName());%>">
                <input type="submit" name="op" value="Add Role">
            </form><br/>

    </div>
</div>

<div class="section">
<!-- ------------------------------------------------- -->

    <div class="section_title">
    Details of Role
    </div>
    <div class="section_body">

    <table>
    <form action="<%=ar.retPath%>PageRoleAction.jsp" method="post">
    <input type="hidden" name="go" value="<% ar.writeHtml(go); %>">
    <input type="hidden" name="id" value="na">
    <input type="hidden" name="p" value="<%ar.writeHtml(ngp.getKey());%>">
    <input type="hidden" name="r" value="<%ar.writeHtml(role.getName());%>">
    <tr>
        <td>Name:</td>
        <td><%ar.writeHtml(r);%></td>
    </tr>
    <tr>
        <td>Description:</td>
        <td><textarea name="desc"><%ar.writeHtml(role.getDescription());%></textarea></td>
    </tr>
    <tr>
        <td>Eligibility:</td>
        <td><textarea name="reqs"><%ar.writeHtml(role.getRequirements());%></textarea></td>
    </tr>
    <tr>
        <td></td>
        <td><input type="submit" name="op" value="Update Details"></td>
    </tr>
    </form>
    </table>


    </div>
</div>

<div class="section">
<!-- ------------------------------------------------- -->

    <div class="section_title">
    Expanded List of Players
    </div>
    <div class="section_body">
        <ul>
        <%
        allUsers = role.getExpandedPlayers(ngp);
        for (AddressListEntry ale : allUsers)
        {
            ar.write("\n   <li>\"");
            ale.writeLink(ar);
            ar.write("\" &lt;");
            ar.writeHtml(ale.getEmail());
            ar.write("&gt;</li>");
        }

        ar.write("\n</ul>");
    %>
    </p>

    </div>
</div>

<%
    }
%>


<%!public void writeRole(AuthRequest ar, NGPage ngp, NGRole role)
        throws Exception
    {

    }%>
<%@ include file="Footer.jsp"%>
<%@ include file="functions.jsp"%>
