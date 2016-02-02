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
%><%@page import="java.net.URLDecoder"
%><%@page import="java.util.Properties"
%><%AuthRequest ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Can't create an attachment.");

    Hashtable params = new Hashtable();
    Enumeration sElements = request.getParameterNames();
    while (sElements.hasMoreElements())
    {
        String key = (String) sElements.nextElement();
        String value = request.getParameter(key);
        params.put(key, value);
    }

    String action   = reqParamSpecial(params, "action");
    String p        = reqParamSpecial(params, "p");
    String destFolder = reqParamSpecial(params, "atype");
    String comment = ar.defParam("comment","");
    String dname = ar.defParam("name","");

    ngp = ar.getCogInstance().getProjectByKeyOrFail(p);
    ar.setPageAccessLevels(ngp);
    ar.assertMember("Unable to create attachments.");

    NGSection ngs = ngp.getSectionOrFail("Folders");

    if ("Link Document".equalsIgnoreCase(action))
    {
        String rlink =  ar.reqParam("rlink");
        String folderId =  ar.reqParam("folderId");
        ConnectionType cType = ar.getUserPage().getConnectionOrFail(folderId);
        String rlinksub = cType.getInternalPathOrFail(rlink);
        String rFilename = cType.getFileName(rlinksub);
        String displayName =  assureExtension(dname, rFilename);

        FolderAccessHelper fah = new FolderAccessHelper(ar);
        fah.attachDocument(folderId, rlinksub, ngp,comment, displayName, destFolder,"off");

    }else{
        throw new Exception("Don't understand the operation: "+ action);
    }

    ngp.saveFile(ar, "Modified attachments");
    response.sendRedirect(ar.getResourceURL(ngp,"attach.htm"));%>
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


    public String assureExtension(String dName, String fName)
    {
        if (dName==null || dName.length()==0)
        {
            return fName;
        }
        int dotPos = fName.lastIndexOf(".");
        if (dotPos<0)
        {
            return dName;
        }
        String fileExtension = fName.substring(dotPos);
        if (!dName.endsWith(fileExtension))
        {
            dName = dName + fileExtension;
        }
        return dName;
    }

%>
