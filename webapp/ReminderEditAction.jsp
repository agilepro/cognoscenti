<%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page errorPage="error.jsp"
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
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Hashtable"
%><%@page import="java.util.Properties"
%><%AuthRequest ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Can't edit an reminder.");

    String action      = ar.reqParam("action");
    String p           = ar.reqParam("p");
    String rid         = ar.reqParam("rid");
    String comment     = ar.defParam("comment", "");
    String instructions = ar.defParam("instructions", "");


    ngp = ar.getCogInstance().getProjectByKeyOrFail(p);
    ar.setPageAccessLevels(ngp);

    //first, handle cancel operation.
    if ("Cancel".equals(action))
    {
        response.sendRedirect(ar.getResourceURL(ngp,"attach.htm"));
        return;
    }

    ReminderMgr rMgr = ngp.getReminderMgr();
    ReminderRecord rRec= rMgr.findReminderByID(rid);
    if (rRec==null)
    {
        throw new Exception("Can't find a reminder with id: "+rid);
    }

    if ("Update".equals(action))
    {
        rRec.setFileDesc(comment);
        rRec.setInstructions(instructions);
        rRec.setModifiedBy(ar.getBestUserId());
        rRec.setModifiedDate(ar.nowTime);
        rRec.setAssignee(ar.reqParam("assignee"));
        rRec.setSubject(ar.reqParam("subject"));

        HistoryRecord.createHistoryRecord(ngp, rid, HistoryRecord.CONTEXT_TYPE_DOCUMENT,
            ar.nowTime, HistoryRecord.EVENT_DOC_UPDATED, ar, "Edited Reminder");
    }
    else if ("Delete Reminder".equals(action))
    {
        rRec.setClosed();

        HistoryRecord.createHistoryRecord(ngp, rid, HistoryRecord.CONTEXT_TYPE_DOCUMENT,
            ar.nowTime, HistoryRecord.EVENT_DOC_UPDATED, ar, "Closed and discarded reminder");
    }
    else
    {
        throw new Exception("Don't understand the operation: "+action);
    }

    ngp.saveFile(ar, "Modified attachments");
    response.sendRedirect(ar.getResourceURL(ngp,"attach.htm"));%>
<%@ include file="functions.jsp"%>

