<%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page errorPage="error.jsp"
%><%@page import="org.socialbiz.cog.AttachmentRecord"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.HistoryRecord"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.NGSection"
%><%@page import="org.socialbiz.cog.ReminderMgr"
%><%@page import="org.socialbiz.cog.ReminderRecord"
%><%@page import="org.socialbiz.cog.util.Upload"
%><%@page import="org.socialbiz.cog.util.UploadFiles"
%><%@page import="java.io.File"
%><%@page import="java.io.FileInputStream"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Hashtable"
%><%@page import="java.util.Properties"
%><%@page import="java.util.StringTokenizer"
%><%AuthRequest ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Can't edit an attachment.");

    String action   = ar.reqParam("action");
    String p        = ar.reqParam("p");
    String section  = "Attachments";
    String destFolder = ar.reqParam("destFolder");

    assureNoParameter(ar, "s");


    ngp = ar.getCogInstance().getProjectByKeyOrFail(p);
    ar.setPageAccessLevels(ngp);
    ar.assertMember("Can not create attachment.");

    //first, handle cancel operation.
    if ("Cancel".equals(action))
    {
        response.sendRedirect(ar.getResourceURL(ngp,"attach.htm"));
        return;
    }

    String aid = null;
    AttachmentRecord attachment = null;
    if ("Attach Web URL".equalsIgnoreCase(action))
    {
        String comment = ar.reqParam("comment");
        String taskUrl = ar.reqParam("taskUrl");
        String ftype   = ar.reqParam("ftype");
        attachment = ngp.createAttachment();
        attachment.setDescription(comment);
        attachment.setType(ftype);
        attachment.setModifiedBy(ar.getBestUserId());
        attachment.setModifiedDate(ar.nowTime);
        if (destFolder.equals("PUB"))
        {
            attachment.setVisibility(1);
        }
        else
        {
            attachment.setVisibility(2);
        }
        attachment.setStorageFileName(taskUrl);
    }
    else if ("Create Email Reminder".equalsIgnoreCase(action))
    {
        String comment = ar.reqParam("comment");
        String pname = ar.defParam("pname", "");
        String assignee = ar.reqParam("assignee");
        String instruct = ar.reqParam("instruct");
        String subj = ar.reqParam("subj");

        ReminderMgr rMgr = ngp.getReminderMgr();
        ReminderRecord rRec = rMgr.createReminder(ngp.getUniqueOnPage());
        rRec.setFileDesc(comment);
        rRec.setInstructions(instruct);
        rRec.setAssignee(assignee);
        rRec.setFileName(pname);
        rRec.setSubject(subj);
        rRec.setModifiedBy(ar.getBestUserId());
        rRec.setModifiedDate(ar.nowTime);
        rRec.setDestFolder(destFolder);
    }
    else
    {
        throw new Exception("Don't understand the operation: "+action);
    }

    ngp.saveFile(ar, "Modified attachments");
    response.sendRedirect(ar.getResourceURL(ngp,"attach.htm"));%>
<%@ include file="functions.jsp"%>

<%!

    public void setDisplayName(NGPage ngp, AttachmentRecord attachment, String proposedName)
        throws Exception
    {
        String currentName = attachment.getDisplayName();
        if (currentName.equals(proposedName))
        {
            return;   //nothing to do
        }
        if (attachment.equivalentName(proposedName))
        {
            attachment.setDisplayName(proposedName);
            return;
        }
        String trialName = proposedName;
        int iteration = 0;
        int dotPos = proposedName.lastIndexOf(".");
        while (ngp.findAttachmentByName(trialName)!=null)
        {
            trialName = proposedName.substring(0,dotPos)+ "-" + Integer.toString(++iteration)
                        + proposedName.substring(dotPos);
            if (currentName.equals(trialName))
            {
                return;   //nothing to do
            }
            if (attachment.equivalentName(trialName))
            {
                attachment.setDisplayName(trialName);
                return;
            }
        }
        //if we get here, then there exists no other attachment with the trial name
        attachment.setDisplayName(trialName);
    }

%>
