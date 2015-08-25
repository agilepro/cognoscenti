<%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page errorPage="error.jsp"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.dms.FolderAccessHelper"
%><%@page import="org.socialbiz.cog.util.Upload"
%><%@page import="org.socialbiz.cog.util.UploadFiles"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Hashtable"
%><%@page import="java.util.Properties"
%><%@page import="java.util.StringTokenizer"
%><%
    AuthRequest ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Unable to add a file. ");

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
    long uploadSize = ufs.getSize();
    String fileName = ufs.getFile(0).getOriginalName();


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

    String action   = reqParamSpecial(params, "action").trim();

    if (!ar.isLoggedIn())
    {
        throw new Exception("Can't edit an folder, because you are not logged in.  Go back to the previous page, log in, and then try again.");
    }

    boolean isCreateNewOp = "Create New".equalsIgnoreCase(action);

    String fid  = reqParamSpecial(params, "fid");
    String go = (String)params.get("go");

    if (go == null || go.length()==0)
    {
        go = "UserHome.jsp?" + ar.getUserProfile().getKey();
    }

    if ("Cancel".equalsIgnoreCase(action))
    {
        response.sendRedirect(go);
        return;
    }
    if(!isCreateNewOp){
        throw new Exception("Don't understand the operation: "+action);
    }

    FolderAccessHelper fah = new FolderAccessHelper(ar);
    fah.createNewFolderFile(fid, fileName, ufs);
    response.sendRedirect(go);
%>
<%@ include file="functions.jsp"%>

<%!
    public String
    reqParamSpecial(Hashtable params, String paramName)
        throws Exception
    {
        String val = (String) params.get(paramName);
        if (val == null || val.length()==0) {
            throw new Exception("Page addFileAction.jsp requires a parameter named '"+paramName+"'. ");
        }
        return val;
    }
%>
