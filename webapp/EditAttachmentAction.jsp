<%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page errorPage="error.jsp"
%><%@page import="org.socialbiz.cog.AttachmentRecord"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.HistoryRecord"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.util.Upload"
%><%@page import="org.socialbiz.cog.util.UploadFile"
%><%@page import="org.socialbiz.cog.util.UploadFiles"
%><%@page import="java.io.File"
%><%@page import="java.io.FileInputStream"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Hashtable"
%><%@page import="java.util.Properties"
%><%AuthRequest ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Can't edit an attachment.");

    String action   = ar.reqParam("action").trim();

    String p        = ar.reqParam("p");
    String visibility  = ar.reqParam("visibility");
    assureNoParameter(ar, "section");


    ngp = ar.getCogInstance().getWorkspaceByKeyOrFail(p);
    ar.setPageAccessLevels(ngp);
    ar.assertMember("Unable to edit attachments in this project.");

    //first, handle cancel operation.
    if ("Cancel".equals(action))
    {
        response.sendRedirect(ar.getResourceURL(ngp,"attach.htm"));
        return;
    }

    // get the list of files that has to be removed.
    /*
    Vector rmFileIdVect = new Vector();
    Enumeration en = params.keys();
    while (en.hasMoreElements())
    {
        String key = (String) en.nextElement();
        if (key.startsWith("rmFileId"))
        {
            String value = (String) params.get(key);
            rmFileIdVect.add(value);
        }
    }
    String[] filesToBeRemoved = new String[rmFileIdVect.size()];
    rmFileIdVect.copyInto(filesToBeRemoved);
    boolean isRemoveOp = (filesToBeRemoved.length > 0);
    */


    String aid = null;
    AttachmentRecord attachment = null;
    if ("Update".equalsIgnoreCase(action))
    {
        aid = ar.reqParam( "aid");
        attachment = ngp.findAttachmentByID(aid);
        if (attachment == null)
        {
            throw new Exception("Unable to find the attachment with the id : " + aid);
        }
        String ftype    = ar.reqParam("ftype");
        boolean isURL = (ftype.equals("URL"));
        boolean isFile = !isURL;
        attachment.setType(ftype);
        attachment.setDescription(ar.defParam("comment", ""));
        if (visibility.equals("PUB"))
        {
            attachment.setVisibility(1);
        }
        else
        {
            attachment.setVisibility(2);
        }
        String fileName = attachment.getStorageFileName();
        if (isFile)
        {
            setDisplayName(ngp, attachment, ar.reqParam("name"));
        }
        else if (isURL)
        {
            attachment.setModifiedBy(ar.getBestUserId());
            attachment.setModifiedDate(ar.nowTime);
            attachment.setStorageFileName(ar.reqParam("taskUrl"));
            setDisplayName(ngp, attachment, ar.reqParam("name"));
        }
        else
        {
            throw new Exception("Don't understand the attachment type: "+ftype);
        }
        String[] roles = ar.multiParam("accessRole");
        Vector<NGRole> roleList = new Vector<NGRole>();
        if (roles.length==0) {
            throw new Exception("roles is supposed to be non zero!");
        }
        for (String aName : roles) {
            NGRole aRole = ngp.getRole(aName);
            if (aRole!=null) {
                roleList.add(aRole);
            }
        }
        attachment.setAccessRoles(roleList);

        attachment.createHistory(ar, ngp, HistoryRecord.EVENT_DOC_UPDATED, "");

    }
    else if ("Accept".equalsIgnoreCase(action))
    {
        aid = ar.reqParam( "aid");
        attachment = ngp.findAttachmentByID(aid);
        attachment.createHistory(ar, ngp, HistoryRecord.EVENT_DOC_APPROVED, "");
    }
    else if ("Reject".equalsIgnoreCase(action))
    {
        aid = ar.reqParam( "aid");
        attachment = ngp.findAttachmentByID(aid);
        attachment.createHistory(ar, ngp, HistoryRecord.EVENT_DOC_REJECTED, "");
    }
    else if ("Skipped".equalsIgnoreCase(action))
    {
        aid = ar.reqParam( "aid");
        attachment = ngp.findAttachmentByID(aid);
        attachment.createHistory(ar, ngp, HistoryRecord.EVENT_DOC_SKIPPED, "");
    }
    else if ("Remove".equalsIgnoreCase(action))
    {
        aid = ar.reqParam( "aid");
        String confirmdel = ar.reqParam( "confirmdel");
        ngp.deleteAttachment(aid, ar);
    }
    else
    {
        throw new Exception("Don't understand the operation: "+action);
    }


    ngp.saveFile(ar, "Modified attachments");
    response.sendRedirect(ar.getResourceURL(ngp,"attach.htm"));%>
<%@ include file="functions.jsp"%>

<%!


    public String saveUploadedFile(AuthRequest ar, UploadFiles ufs, AttachmentRecord att, String originalName)
        throws Exception
    {
        int dotPos = originalName.lastIndexOf(".");
        if (dotPos<0)
        {
            throw new Exception("Did not find a dot in the file name, and so can not determin the file extension, unable to handle this kind of file name.");
        }
        String fileExtension = originalName.substring(dotPos);

        UploadFile uf = ufs.getFile(0);
        File tempFile = File.createTempFile("~editaction",  fileExtension);
        tempFile.delete();
        uf.saveToFile(tempFile);
        FileInputStream fis = new FileInputStream(tempFile);
        att.streamNewVersion(ar, ar.ngp, fis);
        tempFile.delete();

        return fileExtension;
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


    public void setDisplayName(NGPage ngp, AttachmentRecord attachment, String proposedName)
        throws Exception
    {
        if (proposedName==null)
        {
            return;  //do nothing in this case
        }
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
