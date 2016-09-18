<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.AttachmentRecord"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.NGBook"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.SectionFormat"
%><%@page import="org.socialbiz.cog.SectionUtil"
%><%@page import="org.socialbiz.cog.UserProfile"
%><%@page import="org.socialbiz.cog.UtilityMethods"
%><%@page import="org.socialbiz.cog.AttachmentVersion"
%><%@page import="java.io.File"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Enumeration"
%><%@page import="org.w3c.dom.Element"
%><%
    AuthRequest ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Unable to fix attached documents.");

    String p = ar.reqParam("p");
    String aid = ar.reqParam("aid");
    String cmd = ar.reqParam("cmd");

    NGPage ngp = ar.getCogInstance().getWorkspaceByKeyOrFail(p);
    if (ngp.isDeleted()) {
        throw new Exception("This project has been deleted, and can not be edited.  If you want to change this project contents, first 'un-delete' the project (Admin) and then you can edit the sections");
    }
    ar.setPageAccessLevels(ngp);
    ar.assertMember("You must be a member of the project to edit the Attachments.");

    AttachmentRecord att = ngp.findAttachmentByID(aid);
    String ftype = att.getType();

    if ("Add".equals(cmd)) {

        att.setType("FILE");
        AttachmentVersion aVer = att.getLatestVersion(ngp);
        if (aVer!=null) {
            File curFile = aVer.getLocalFile();
            att.setAttachTime(curFile.lastModified());
            att.setModifiedDate(curFile.lastModified());
        }
        att.setModifiedBy(ar.getBestUserId());
    }
    else if ("Remove".equals(cmd)) {

        att.setDeleted(ar);

    }
    else if ("Change Name".equals(cmd)) {

        String fname = ar.reqParam("fname");
        att.setType("FILE");
        boolean found = false;
        for (AttachmentRecord att2 : ngp.getAllAttachments()) {
            if (fname.equals(att2.getNiceName())) {
                if (!"EXTRA".equals(att2.getType())) {
                    throw new Exception("Something is wrong.  the 'New Name' option should only occur when the name is being changed to that of a newly appearing file, but file is not new.   Did something change while you were taking action?");
                }
                ngp.eraseAttachmentRecord(att2.getId());
                found = true;
            }
        }
        if (!found) {
            throw new Exception("Something is wrong.  the 'New Name' option should only occur when the name is being changed to that of a newly appearing file, but did not find such a record.   Did something change while you were taking action?");
        }
        att.setDisplayName(fname);

    }
    else {

        throw new Exception("Unable to handle the command '"+cmd+"'");
    }

    response.sendRedirect(ar.getResourceURL(ngp, "attach.htm"));

%>
