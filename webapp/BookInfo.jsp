<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.ConfigFile"
%><%@page import="org.socialbiz.cog.NGBook"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.NGSection"
%><%@page import="org.socialbiz.cog.UserProfile"
%><%@page import="org.socialbiz.cog.util.StringCounter"
%><%@page import="java.io.File"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Properties"
%><%@page import="org.w3c.dom.Element"
%><%//constructing the AuthRequest object should always be the first thing
    //that a page does, so that everything can be set up correctly.
    ar = AuthRequest.getOrCreate(request, response, out);


    String b = ar.reqParam("b");
    ngb = ar.getCogInstance().getSiteByIdOrFail(b);


    //search and find all the sites files on disk
    ServletContext sc = session.getServletContext();
    String configPath = sc.getRealPath("/");
    File root = ar.getCogInstance().getConfig().getFolderOrFail(configPath);
    File[] children = root.listFiles();

    List<AddressListEntry> book_members  = ngb.getPrimaryRole().getDirectPlayers();

    pageTitle = "Site: "+ngb.getFullName();%>


<%@ include file="Header.jsp"%>

        <div class="pagenavigation">
            <div class="pagenav">
                <div class="left"><%ar.writeHtml(ngb.getFullName());%> &raquo; Site Info</div>
                <div class="right"></div>
                <div class="clearer">&nbsp;</div>
            </div>
            <div class="pagenav_bottom"></div>
        </div>


    <div class="section">
        <div class="section_title">
            <h1 class="left">Look &amp; Feel</h1>
            <div class="section_date right"><a href="BookInfoEdit.jsp?b=<%ar.writeURLData(ngb.getKey());%>">Edit</a></div>
            <div class="clearer">&nbsp;</div>
        </div>
        <div class="section_body">

            <table width="65%" class="Design8">
                <col width="20%"/>
                <col width="80%"/>
                <tr>
                    <td>Site Key:</td>
                    <td class="odd"><%ar.writeHtml(ngb.getKey());%></td>
                </tr>
                <tr>
                    <td>Name:</td>
                    <td class="odd"><%ar.writeHtml(ngb.getFullName());%></td>
                </tr>
                <tr>
                    <td>Description:</td>
                    <td class="odd"><%ar.writeHtml(ngb.getDescription());%></td>
                </tr>
                <tr>
                    <td>Style Sheet:</td>
                    <td class="odd"><%ar.writeHtml(ngb.getStyleSheet());%></td>
                </tr>

                <tr>
                    <td>Logo File:</td>
                    <td class="odd"><%ar.writeHtml(ngb.getLogo());%></td>
                </tr>

                <tr>
                    <td>Preferred Location:</td>
                    <td class="odd"><%ar.writeHtml(ngb.getSiteRootFolder().toString());%></td>
                </tr>
            </table>
            <br/>
        </div>
    </div>


<style>
.mytable tr td {
    padding:5px;
}
</style>

<div class="section">
<!-- ------------------------------------------------- -->
    <div class="section_title">
    Users of this Site
    </div>
    <div class="section_body">

<table>
<%
    if (!ar.isLoggedIn())
    {
%>
    <tr><td>Please log in to see members.</td>
        </tr>
<%
    }
    else if (book_members.size()==0)
    {
%>
    <tr>This account has no executives, would you like to be the first executive?.
        <form action="BookMemberAction.jsp" method="post">
        <input type="hidden" name="userid" value="<% ar.writeHtml(ar.getBestUserId()); %>">
        <input type="hidden" name="encodingGuard" value="<%ar.writeHtml("\u6771\u4eac");%>"/>
        <input type="hidden" name="b" value="<% ar.writeHtml(b); %>">
        <input type="hidden" name="level" value="2">
        <td><input type="submit" value="Request to be First Executive"></td>
        </form>
        </tr>
<%
    }

    writeOutUsers(ar, book_members,  NGPage.ROLE_MEMBER,
                  "Executives ("+ngb.getFullName()+")"            ,
                  2, b);

    %><p>List of all identifiers in site</p>
    <table class="mytable"><%

    StringCounter scnt = new StringCounter();
    List<NGPageIndex> allOfEm = ar.getCogInstance().getAllProjectsInSite(b);
    for (NGPageIndex ngpi : allOfEm) {
        NGPageIndex.clearLocksHeldByThisThread();
        NGPage ngp = ngpi.getPage();
        ngp.countIdentifiersInWorkspace(scnt);
    }

    for (String sid : scnt.keySet() ) {
        UserProfile upx = UserManager.findUserByAnyId(sid);
        boolean isDisabled = false;
        boolean hasProfile = (upx!=null);
        if (hasProfile) {
            isDisabled = upx.getDisabled();
        }
        String shortSid = sid;
        if (sid.length()>30) {
            shortSid = sid.substring(0,30);
        }
        %><tr><td><% 
        ar.writeHtml(shortSid); 
        %>:</td>
        <td><%=scnt.getCount(sid)%></td>
        <td><% if (isDisabled) {%> <img src="warning.gif" title="Disabled User"> <%}%> </td>
        <td><% 
            if (!hasProfile) {
                %> - no profile - <%
            } else {
                %> <a href="UserProfile.jsp?u=<%=upx.getKey()%>"><% 
                ar.writeHtml(upx.getName()); 
                %></a> <%
            }
            %> </td>
        </tr><%
    }
    %></table><%

    if (ar.isMember() || ar.isSuperAdmin())
    {
%>
    <tr>
        <form action="<%=ar.retPath%>BookMemberAction.jsp" method="post">
        <input type="hidden" name="encodingGuard" value="<%ar.writeHtml("\u6771\u4eac");%>"/>
        <td colspan="3">
            <br/>
            <input type="submit" value="Add New Executive:">
            <input type="text" size="40" name="userid">
            <input type="hidden" name="encodingGuard" value="<%ar.writeHtml("\u6771\u4eac");%>"/>
            <input type="hidden" name="level" value="2">
            <input type="hidden" name="b" value="<%ar.writeHtml(b);%>">
        </td></form>
    </tr>
<%
    }
%>
</table>

    </div>
</div>



<%@ include file="Footer.jsp"%>
<%@ include file="functions.jsp"%>
