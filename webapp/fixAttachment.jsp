<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.NGBook"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.NGSection"
%><%@page import="org.socialbiz.cog.SectionFormat"
%><%@page import="org.socialbiz.cog.SectionUtil"
%><%@page import="org.socialbiz.cog.UserProfile"
%><%@page import="org.socialbiz.cog.UtilityMethods"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Vector"
%><%@page import="org.w3c.dom.Element"
%><%ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Unable to fix attached documents.");

    String p = ar.reqParam("p");
    String aid = ar.reqParam("aid");

    ngp = ar.getCogInstance().getProjectByKeyOrFail(p);
    if (ngp.isDeleted()) {
        throw new Exception("This project has been deleted, and can not be edited.  If you want to change this project contents, first 'un-delete' the project (Admin) and then you can edit the sections");
    }
    ar.setPageAccessLevels(ngp);
    ar.assertMember("You must be a member of the project to edit the Attachments.");

    ngb = ngp.getSite();

    AttachmentRecord att = ngp.findAttachmentByID(aid);
    pageTitle = "Adjust Attachment: "+att.getDisplayName();
    String ftype = att.getType();%>

<%@ include file="Header.jsp"%>


<h2>Adjust Attachment: <b><%ar.writeHtml(att.getDisplayName());%>.</b></h2>

<%
    if ("GONE".equals(ftype)) {

        %>
        <p>This document had been attached to the project in the past, but right now it is missing
        from the project folder.</p>

        <h2>Options</h2>

        <form action="fixAttachmentAction.jsp">
        <p>
        <input type="hidden" name="p" value="<%ar.writeHtml(p);%>">
        <input type="hidden" name="aid" value="<%ar.writeHtml(aid);%>">
        <input type="submit" name="cmd" value="Remove">
        Use this if you really meant to delete the document.
        This option will mark it in the project as being deleted.
        <p>
        </form>
        <%

        for (AttachmentRecord att2 : ngp.getAllAttachments()) {
            if (!"EXTRA".equals(att2.getType())) {
                continue;
            }

            %>
            <form action="fixAttachmentAction.jsp">
            <p>
            <input type="hidden" name="p" value="<%ar.writeHtml(p);%>">
            <input type="hidden" name="aid" value="<%ar.writeHtml(aid);%>">
            <input type="hidden" name="fname" value="<%ar.writeHtml(att2.getNiceName());%>">
            <input type="submit" name="cmd" value="Change Name">
            to <b><%ar.writeHtml(att2.getNiceName());%></b>.  An extra document has been found with this name.
            Did you rename the document to <%ar.writeHtml(att.getDisplayName());%>?  Use this option to
            record this name change within the project.
            <p>
            </form>

            <%

        }
    }
    else if ("EXTRA".equals(ftype)) {

        %>
        <p>This document has been found in the folder, but the project does not know anything about it.</p>

        <h2>Options</h2>

        <form action="fixAttachmentAction.jsp">
        <p>
        <input type="hidden" name="p" value="<%ar.writeHtml(p);%>">
        <input type="hidden" name="aid" value="<%ar.writeHtml(aid);%>">
        <input type="submit" name="cmd" value="Add">
        Use this if you really meant to add this as a new document to the project.
        This option will mark it as part of the project, track changes, and allow others to access it.
        <p>
        </form>
        <%

        for (AttachmentRecord att2 : ngp.getAllAttachments()) {
            if (!"GONE".equals(att2.getType())) {
                continue;
            }

            %>
            <form action="fixAttachmentAction.jsp">
            <p>
            <input type="hidden" name="p" value="<%ar.writeHtml(p);%>">
            <input type="hidden" name="aid" value="<%ar.writeHtml(aid);%>">
            <input type="hidden" name="fname" value="<%ar.writeHtml(att2.getNiceName());%>">
            <input type="submit" name="cmd" value="Adopt Name">
            for old <b><%ar.writeHtml(att2.getNiceName());%></b> documents.  Project used to have a document with the
            name <%ar.writeHtml(att.getDisplayName());%> which is now missing.  Did you rename this
            document, and would you like the project to use this new name for all the old versions?
            <p>
            </form>

            <%
        }

        for (AttachmentRecord att2 : ngp.getAllAttachments()) {
            if (!"FILE".equals(att2.getType())) {
                continue;
            }

            %>
            <form action="fixAttachmentAction.jsp">
            <p>
            <input type="hidden" name="p" value="<%ar.writeHtml(p);%>">
            <input type="hidden" name="aid" value="<%ar.writeHtml(aid);%>">
            <input type="hidden" name="fname" value="<%ar.writeHtml(att.getNiceName());%>">
            <input type="submit" name="cmd" value="New Version">
            of <b><%ar.writeHtml(att2.getNiceName());%></b>.  Did you mean for this new
            document to simply be a new version of this other existing document?  Use this option
            to link these documents together, and make this new document simply be the latest
            version of the existing document line.
            <p>
            </form>

            <%
        }

    }
%>



<br/><br/>
<%@ include file="Footer.jsp"%>
<%@ include file="functions.jsp"%>
