<%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page errorPage="error.jsp"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.NGSection"
%><%@page import="org.socialbiz.cog.util.Upload"
%><%@page import="org.socialbiz.cog.util.UploadFiles"
%><%@page import="java.io.File"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Hashtable"
%><%@page import="java.util.Properties"
%><%AuthRequest ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Can't delete a project.");

    String p        = ar.reqParam("p");
    String action   = ar.reqParam("action");
    ngp = ar.getCogInstance().getProjectByKeyOrFail(p);
    ar.setPageAccessLevels(ngp);
    ar.assertAdmin("Unable to delete this page. ");

    //first, handle cancel operation.
    if ("Delete Workspace".equals(action))
    {
        ngp.markDeleted(ar);
    }
    else if ("Un-Delete Workspace".equals(action))
    {
        ngp.markUnDeleted(ar);
    }
    else
    {
        throw new Exception("Don't understand that action: '"+action+"'");
    }
    ngp.saveFile(ar, action);
    response.sendRedirect(ar.getResourceURL(ngp,"admin.htm"));%>
<%@ include file="functions.jsp"%>
