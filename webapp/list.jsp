<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.NGBook"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.NGSection"
%><%@page import="org.socialbiz.cog.SectionDef"
%><%@page import="org.socialbiz.cog.SectionFormat"
%><%@page import="org.socialbiz.cog.SectionUtil"
%><%@page import="org.socialbiz.cog.UserProfile"
%><%@page import="org.socialbiz.cog.UtilityMethods"
%><%@page import="java.io.File"
%><%@page import="java.io.Writer"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Properties"
%><%@page import="java.util.Vector"
%><%@page import="org.w3c.dom.Element"
%><%AuthRequest ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Must be logged in to list the sites.");

    Vector<NGBook> allAccounts = NGBook.getAllSites();
    if (allAccounts==null) {
        throw new Exception("Strange, the system does not appear to be initialized.");
    }%>
<%@ include file="Header.jsp"%>

    <h1>Site List</h1>

    <div class="section">
            <div class="section_title">
                <h1 class="left">Sites at this site</h1>
                <div class="section_date right"></div>
                <div class="clearer">&nbsp;</div>
            </div>
            <div class="section_body">


            <table valign="top">
                <col width="130">
                <col width="40">
                <col width="40">
                <col width="40">
                <col width="300">
                <col width="400">

                <tr>
                    <td>Site Id</td>
                    <td>#prj</td>
                    <td>#docs</td>
                    <td>#notes</td>
                    <td>Owners</td>
                    <td>Description</td>
                </tr>
<%
    for (NGBook ngb : allAccounts)
    {
        Vector<NGPageIndex> allProjects = ar.getCogInstance().getAllProjectsInSite(ngb.key);
        List<AttachmentRecord> allDocs = ngb.getAllAttachments();
        List<NoteRecord> allNotes = ngb.getAllNotes();
        NGRole owner = ngb.getSecondaryRole();
%>
            <tr valign="top">
                <td><a href="BookPages.jsp?b=<%ar.writeHtml(ngb.getKey());%>" title="List all the projects in this account">
                    <%ar.writeHtml(ngb.getFullName());%></a></td>
                <td><%=allProjects.size()%></td>
                <td><%=allDocs.size()%></td>
                <td><%=allNotes.size()%></td>
                <td><%
                    for (AddressListEntry ale : owner.getDirectPlayers())
                    {
                        ale.writeLink(ar);
                        ar.write("<br/>");
                    }
                %></td>
                <td><%ar.writeHtml(ngb.getDescription()); %></td>
            </tr>
            <tr><td>&nbsp;</td></tr>
<%
    }
%>
            </table>
        </div>
    </div>


<%@ include file="Footer.jsp"%>
<%@ include file="functions.jsp"%>
