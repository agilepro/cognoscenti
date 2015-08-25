<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.AttachmentRecord"
%><%@page import="org.socialbiz.cog.AttachmentVersion"
%><%@page import="org.socialbiz.cog.BaseRecord"
%><%@page import="org.socialbiz.cog.LicensedURL"
%><%@page import="org.socialbiz.cog.NGBook"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.NGSection"
%><%@page import="org.socialbiz.cog.api.ProjectSync"
%><%@page import="org.socialbiz.cog.api.RemoteProject"
%><%@page import="org.socialbiz.cog.SectionFormat"
%><%@page import="org.socialbiz.cog.SectionUtil"
%><%@page import="org.socialbiz.cog.StatusReport"
%><%@page import="org.socialbiz.cog.api.SyncStatus"
%><%@page import="org.socialbiz.cog.GoalRecord"
%><%@page import="org.socialbiz.cog.UserProfile"
%><%@page import="org.socialbiz.cog.WatchRecord"
%><%@page import="org.socialbiz.cog.rest.TaskHelper"
%><%@page import="java.io.InputStream"
%><%@page import="java.net.URL"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Hashtable"
%><%@page import="java.util.List"
%><%@page import="java.util.Vector"
%><%@page import="org.w3c.dom.Element"
%><%
    AuthRequest ar = AuthRequest.getOrCreate(request, response, out);

    ar.assertLoggedIn("Unable to see status report.");
    String p = ar.reqParam("p");
    String go = ar.reqParam("go");
    ngp = ar.getCogInstance().getProjectByKeyOrFail(p);
    ar.setPageAccessLevels(ngp);
    ar.assertMember("unable to synchronize this project");

    //go ahead and get the sync status (from the remote)
    RemoteProject rp = new RemoteProject(ngp.getUpstreamLink());
    ProjectSync ps = new ProjectSync(ngp, rp, ar, ngp.getLicenses().get(0).getId());

    String op = ar.reqParam("op");
    if ("Download All".equals(op)) {
        ps.downloadAll();
    }
    else if ("Upload All".equals(op)) {
        ps.uploadAll();
    }
    else if ("Ping".equals(op)) {
        ps.pingUpstream();
    }
    else {
        throw new Exception("Dont understand operation; "+op);
    }

    response.sendRedirect(go);

%><%@ include file="functions.jsp"%>
