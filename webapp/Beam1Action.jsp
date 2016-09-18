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
%><%@page import="org.w3c.dom.Element"
%><%AuthRequest ar = AuthRequest.getOrCreate(request, response, out);

    ar.assertLoggedIn("Unable to see status report.");
    String p = ar.reqParam("p");
    String cmd = ar.reqParam("cmd");
    ngp = ar.getCogInstance().getWorkspaceByKeyOrFail(p);
    ar.setPageAccessLevels(ngp);
    ar.assertMember("unable to synchronize this project");

    //go ahead and get the sync status (from the remote)
    RemoteProject rp = new RemoteProject(ngp.getUpstreamLink());
    ProjectSync ps = new ProjectSync(ngp, rp, ar, ngp.getLicenses().get(0).getId());


    if ("Up".equals(cmd)) {
        throw new Exception("Upload not implemented yet");
    }
    else if ("Dn".equals(cmd)) {
        String id = ar.reqParam("i");
        boolean found=false;
        for (SyncStatus stat : ps.getStatus()) {

            if (id.equals(stat.universalId)) {

                if (stat.type == SyncStatus.TYPE_DOCUMENT) {
                    AttachmentRecord newAtt;
                    if (stat.isLocal) {
                        newAtt = ngp.findAttachmentByID(stat.idLocal);
                    }
                    else {
                        newAtt = ngp.createAttachment();
                        newAtt.setUniversalId(stat.universalId);
                    }
                    newAtt.setDisplayName(stat.nameRemote);
                    URL link = new URL(stat.urlRemote);
                    InputStream is = link.openStream();
                    AttachmentVersion av = newAtt.streamNewVersion(ar, ngp, is);
                    newAtt.setModifiedDate(stat.timeRemote);
                    ngp.saveFile(ar, "Downloaded a file from beamUp project");
                    found=true;
                    break;
                }
                else if (stat.type == SyncStatus.TYPE_NOTE) {
                    TopicRecord note;
                    if (stat.isLocal) {
                        note = ngp.getNote(stat.idLocal);
                    }
                    else {
                        note = ngp.createNote();
                        note.setUniversalId(stat.universalId);
                    }
                    note.setSubject(stat.nameRemote);
                    note.setWiki(stat.urlRemote);
                    note.setLastEdited(stat.timeRemote);
                    ngp.saveFile(ar, "Downloaded a Topic from beamUp project");
                    found=true;
                    break;
                }

            }
        }

        if (!found) {
            throw new Exception("Unable to find a remote attachment with ID = "+id);
        }
    }



    response.sendRedirect(ar.getResourceURL(ngp, "beam1.htm"));%><%@ include file="functions.jsp"%>
