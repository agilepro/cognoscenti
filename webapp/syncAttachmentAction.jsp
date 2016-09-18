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
%><%@page import="org.socialbiz.cog.dms.FolderAccessHelper"
%><%@page import="org.socialbiz.cog.util.Upload"
%><%@page import="org.socialbiz.cog.util.UploadFiles"
%><%@page import="java.io.File"
%><%@page import="java.io.FileInputStream"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Hashtable"
%><%@page import="java.util.Properties"
%><%@page import="java.util.StringTokenizer"
%><%
    AuthRequest ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Can't create an attachment.");
%>
<%
    Hashtable params = new Hashtable();
    Enumeration sElements = request.getParameterNames();
    while (sElements.hasMoreElements())
    {
       String key = (String) sElements.nextElement();
       String value = request.getParameter(key);
       params.put(key, value);
    }

    String action   = reqParamSpecial(params, "action");

    String p   = reqParamSpecial(params, "p");
    String aid = reqParamSpecial(params, "aid");

    NGPage ngp = ar.getCogInstance().getWorkspaceByKeyOrFail(p);
    ar.setPageAccessLevels(ngp);
    ar.assertMember("Unable to Synchronize attachments.");

    NGSection ngs = ngp.getSectionOrFail("Folders");
    FolderAccessHelper fah = new FolderAccessHelper(ar);

    if ("Update to Repository".equalsIgnoreCase(action))
    {
        fah.uploadAttachment(ngp, aid);

    }else if ("Refresh from Repository".equalsIgnoreCase(action))
    {
        fah.refreshAttachmentFromRemote(ngp, aid);

    }else if ("Cancel".equalsIgnoreCase(action))
    {
       response.sendRedirect(ar.getResourceURL(ngp,"attach.htm"));
       return;
    }
    else
    {
        throw new Exception("Don't understand the operation: "+action);
    }

    ngp.saveFile(ar, "Modified attachments");
    response.sendRedirect(ar.getResourceURL(ngp,"attach.htm"));
%>
<%@ include file="functions.jsp"%>

<%!
    public String
    reqParamSpecial(Hashtable params, String paramName)
        throws Exception
    {
        String val = (String) params.get(paramName);
        if (val == null || val.length()==0) {
            throw new Exception("Page EditAttachmentAction.jsp requires a parameter named '"+paramName+"'. ");
        }
        return val;
    }

%>
