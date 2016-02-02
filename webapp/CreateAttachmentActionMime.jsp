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
%><%@page import="org.socialbiz.cog.util.UploadFile"
%><%@page import="org.socialbiz.cog.util.UploadFiles"
%><%@page import="java.io.File"
%><%@page import="java.io.FileInputStream"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Hashtable"
%><%@page import="java.util.Properties"
%><%
    AuthRequest ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Can't create an attachment.");

    //creating the bean below retrieves an object associated with the page
    //creates that object if not already existing
%>
<jsp:useBean id="myUpload" scope="page" class="org.socialbiz.cog.util.Upload"/>
<%
	//we initialize on every page, but my concern is that this object is
    //possibly shared across multiple requests which may be happening at
    //this time, so why do we use a shared object.  Should be unique to this request.
    myUpload.initialize(pageContext);

    //this reads the posted content, and parses the files out
    //returns a vector of file objects
    UploadFiles ufs = myUpload.parsePostedContent();
    int uploadSize = ufs.getCount();

    if (uploadSize==0)
    {
        throw new Exception("No file was actually uploaded for this attachment.  "
           +"When reading a file attachment, the file must be uploaded.  Check to "
           +"see if the form was filled in correctly.");
    }
    String fileName = ufs.getFile(0).getOriginalName();
    if (fileName == null || fileName.length() == 0)
    {
        throw new Exception("Internal error:  For some reason the file name "
           +"for the uploaded file is empty.");
    }


    //The myUpload bean requires that we copy parameters into a hashtable
    //for individual access, so do that here
    Hashtable params = new Hashtable();
    Enumeration sElements = myUpload.getRequest().getParameterNames();
    while (sElements.hasMoreElements())
    {
        String key = (String) sElements.nextElement();
        String value = myUpload.getRequest().getParameter(key);
        params.put(key, value);
    }

    String action   = reqParamSpecial(params, "action");
    String p        = reqParamSpecial(params, "p");
    String destFolder = reqParamSpecial(params, "destFolder");
    String reminderid = (String) params.get("reminderid");


    ngp = ar.getCogInstance().getProjectByKeyOrFail(p);
    ar.setPageAccessLevels(ngp);
    ar.assertMember("Unable to create attachments.");


    // get the list of files that has to be removed.
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

    if ("Upload Attachment File".equalsIgnoreCase(action))
    {
        String displayName = assureExtension((String)params.get("name"), fileName);
        AttachmentRecord attachment = ngp.createAttachment();
        attachment.setDisplayName(displayName);
        attachment.setDescription((String)params.get("comment"));
        attachment.setModifiedBy(ar.getBestUserId());
        attachment.setModifiedDate(ar.nowTime);
        String ftype    = reqParamSpecial(params, "ftype");
        if (!ftype.equals("FILE"))
        {
    throw new Exception("This action jsp can not handle the attachment type: "+ftype);
        }
        attachment.setType("FILE");
        if (destFolder.equals("*PUB*"))
        {
    attachment.setVisibility(1);
        }
        else
        {
    attachment.setVisibility(2);
        }
        setDisplayName(ngp, attachment, displayName);
        saveUploadedFile(ar, ufs, attachment, fileName);

    }else if ("Upload Folder File".equalsIgnoreCase(action))
    {
        String mfname = assureExtension((String)params.get("name"), fileName);

    }
    else
    {
        throw new Exception("Don't understand the operation: "+action);
    }

    //now cancel the reminder, if there is one
    if (reminderid!=null)
    {
        ReminderMgr rMgr = ngp.getReminderMgr();
        ReminderRecord rRec= rMgr.findReminderByID(reminderid);
        if (rRec!=null)
        {
    rRec.setClosed();
        }
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
