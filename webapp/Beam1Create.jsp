<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.AttachmentRecord"
%><%@page import="org.socialbiz.cog.AttachmentVersion"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.BaseRecord"
%><%@page import="org.socialbiz.cog.GoalRecord"
%><%@page import="org.socialbiz.cog.LicensedURL"
%><%@page import="org.socialbiz.cog.NGBook"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.NGSection"
%><%@page import="org.socialbiz.cog.SectionFormat"
%><%@page import="org.socialbiz.cog.SectionUtil"
%><%@page import="org.socialbiz.cog.StatusReport"
%><%@page import="org.socialbiz.cog.UserProfile"
%><%@page import="org.socialbiz.cog.WatchRecord"
%><%@page import="org.socialbiz.cog.api.ProjectSync"
%><%@page import="org.socialbiz.cog.api.RemoteProject"
%><%@page import="org.socialbiz.cog.api.SyncStatus"
%><%@page import="org.socialbiz.cog.rest.TaskHelper"
%><%@page import="org.workcast.json.JSONObject"
%><%@page import="java.io.InputStream"
%><%@page import="java.net.URL"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Hashtable"
%><%@page import="java.util.List"
%><%@page import="org.w3c.dom.Element"
%><%
    AuthRequest ar = AuthRequest.getOrCreate(request, response, out);

    ar.assertLoggedIn("Unable to see status report.");
    String p = ar.reqParam("p");
    String go = ar.reqParam("go");
    String siteLink = ar.reqParam("siteLink");
    ngp = ar.getCogInstance().getProjectByKeyOrFail(p);
    ar.setPageAccessLevels(ngp);
    ar.assertAdmin("unable to create new upstream clone of this project");

    //go ahead and get the sync status (from the remote)
    RemoteProject rp = new RemoteProject(siteLink);


    String op = ar.reqParam("op");
    if ("Create Remote Upstream Workspace".equals(op)) {
        JSONObject requestObj = new JSONObject();
        requestObj.put("operation", "createProject");

        //TODO: get rid of this name kludge
        requestObj.put("projectName", ngp.getFullName()+" Clone");

        JSONObject responseObj = rp.call(requestObj);

        String newLink = responseObj.getString("link");
        ngp.setUpstreamLink(newLink);
        ngp.save();
    }
    else {
        throw new Exception("Dont understand operation: "+op);
    }

    response.sendRedirect(go);

%><%@ include file="functions.jsp"%>
