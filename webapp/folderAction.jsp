<%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page errorPage="error.jsp"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Hashtable"
%><%@page import="java.util.Properties"
%><%@page import="java.util.StringTokenizer"
%><%
    AuthRequest ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Unable to complete request. ");

    // Return address required to return the page
    String goPage = request.getParameter("go");
    if (goPage == null || goPage.length()==0)
    {
       goPage = "UserHome.jsp?" + ar.getUserProfile().getKey();
    }
    String action = request.getParameter("action");

    //first, handle cancel operation.
    if ("Cancel".equalsIgnoreCase(action))
    {
        response.sendRedirect(goPage);
        return;
    }

    FolderAccessHelper fah = new FolderAccessHelper(ar);
    String fid = request.getParameter("fid");

    if ("Create New".equalsIgnoreCase(action))
    {
        FolderAccessHelper.updateConnection(ar);
    }
    else if ("Update".equalsIgnoreCase(action))
    {
        FolderAccessHelper.updateConnection(ar);
    }
    else if ("Delete".equalsIgnoreCase(action))
    {
        fah.deleteFolder(fid);

    }else if ("Unmount".equalsIgnoreCase(action))
    {
        throw new Exception("There is no meaning to 'Unmount'");

    }else if ("CreateSub".equalsIgnoreCase(action))
    {
        String folderName = ar.reqParam("fname").trim();
        fah.createSubFolder(fid, folderName);
    }


    response.sendRedirect(goPage);

%>
<%@ include file="functions.jsp"%>

