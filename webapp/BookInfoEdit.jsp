<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.ConfigFile"
%><%@page import="org.socialbiz.cog.NGBook"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.UserProfile"
%><%@page import="java.io.File"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Properties"
%><%@page import="java.util.Vector"
%><%@page import="org.w3c.dom.Element"
%><%//constructing the AuthRequest object should always be the first thing
    //that a page does, so that everything can be set up correctly.
    ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Unable to edit account info.");


    String b = ar.reqParam("b");
    ngb = ar.getCogInstance().getSiteByIdOrFail(b);


    //search and find all the account files on disk
    ServletContext sc = session.getServletContext();
    String configPath = sc.getRealPath("/");
    File root = ar.getCogInstance().getConfig().getFolderOrFail(configPath);
    File[] children = root.listFiles();

    List<AddressListEntry> book_members  = ngb.getPrimaryRole().getDirectPlayers();

    pageTitle = "Site: "+ngb.getFullName();%>


<%@ include file="Header.jsp"%>


        <div class="pagenavigation">
            <div class="pagenav">
                <div class="left"><%ar.writeHtml(ngb.getFullName());%> &raquo; Edit Site Info</div>
                <div class="right"></div>
                <div class="clearer">&nbsp;</div>
            </div>
            <div class="pagenav_bottom"></div>
        </div>


    <div class="section">
        <div class="section_title">
            <h1 class="left">Look &amp; Feel</h1>
            <div class="section_date right"></div>
            <div class="clearer">&nbsp;</div>
        </div>
        <div class="section_body">

            <form action="BookInfoAction.jsp" method="post">
                <input type="hidden" name="b" value="<%ar.writeHtml(b);%>">
                <input type="hidden" name="go" value="BookInfo.jsp?b=<% ar.writeURLData(b); %>">
                <input type="hidden" name="encodingGuard" value="<%ar.writeHtml("\u6771\u4eac");%>"/>
                <button type="submit" id="actBtn1" name="actBtn1" value="Update Site Settings">Update Book Settings</button>
                <br/><br/>

                <table width="65%" class="Design8">
                    <col width="20%"/>
                    <col width="80%"/>
                    <tr>
                        <td>Site Key:</td>
                        <td class="odd"><%ar.writeHtml(ngb.getKey());%></td>
                    </tr>
                    <tr>
                        <td>Name:</td>
                        <td class="odd">
<input type="text" name="bookname" value="<%ar.writeHtml(ngb.getFullName());%>">
                        </td>
                    </tr>
                    <tr>
                        <td>Description:</td>
                        <td class="odd">
<textarea name="desc" rows="5" cols="80"><%ar.writeHtml(ngb.getDescription());%></textarea>
                        </td>
                    </tr>
                    <tr>
                        <td>Style Sheet:</td>
                        <td class="odd">
                            <select name="styleSheet" style="WIDTH:97%">
<%
    String style = ngb.getStyleSheet();
    for (int i=0; i<children.length; i++)
    {
        File child = children[i];
        String fileName = child.getName();
        if (!fileName.endsWith(".css"))
        {
            //ignore all files except those that are css files
            continue;
        }
        String shortName = fileName.substring(0,fileName.length()-4);
%>
        <option <%=(fileName.equals(style) ? " selected=\"selected\" " : "")%> ><%ar.writeHtml(fileName);%></option>
<%
    }
%>
                            </select>
                        </td>
                    </tr>

                    <tr>
                        <td>Logo File:</td>
                        <td class="odd">
                            <input type="text" name="logo" size="80" value="<%ar.writeHtml(ngb.getLogo());%>"/>
                        </td>
                    </tr>

                </table>
            </form>
        </div>
    </div>

    <script>
        var actBtn1 = new YAHOO.widget.Button("actBtn1");
    </script>

<div class="section">
<!-- ------------------------------------------------- -->
    <div class="section_title">
    Users of this Site
    </div>
    <div class="section_body">

<table>
<%
    if (book_members.size()==0)
    {
%>
    <tr>This account has no members, would you like to be the first member?.
        <form action="BookMemberAction.jsp" method="post">
        <input type="hidden" name="b" value="<% ar.writeHtml(b); %>">
        <input type="hidden" name="level" value="2">
        <td><input type="submit" value="Request to be First Member"></td>
        </tr>
<%
    }
    else if (!ar.isMember())
    {
%>
    <tr><form action="BookMemberAction.jsp" method="post">
        <input type="hidden" name="b" value="<% ar.writeHtml(b); %>">
        <input type="hidden" name="encodingGuard" value="<%ar.writeHtml("\u6771\u4eac");%>"/>
        <input type="hidden" name="level" value="1">
        <td><input type="submit" value="Request to be Member"></td>
        </tr>
<%
    }

    writeOutUsers(ar, book_members,  NGPage.ROLE_MEMBER,
                  "Executives ("+ngb.getFullName()+")"            ,
                  2, b);

%>
</table>

    </div>
</div>



<%@ include file="Footer.jsp"%>
<%@ include file="functions.jsp"%>
