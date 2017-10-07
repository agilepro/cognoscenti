<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="include.jsp"
%><%@page import="org.socialbiz.cog.api.RemoteProject"
%><%@page import="org.socialbiz.cog.api.ProjectSync"
%><%@page import="org.socialbiz.cog.License"
%><%@page import="org.socialbiz.cog.api.SyncStatus"
%>
<%
    ar.assertLoggedIn("This VIEW only for logged in use cases");
    ar.assertMember("This VIEW only for members in use cases");
    String pageId  = ar.reqParam("pageId");
    String siteId  = ar.reqParam("siteId");
    NGWorkspace ngp = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngp);
    NGBook ngb = ngp.getSite();
    UserProfile up = ar.getUserProfile();

    String userKey = "";
    if(up!=null){
        userKey = up.getKey();
    }

    String thisPage = ar.getResourceURL(ngp,"synchronizeUpstream.htm");
    String allTasksPage = ar.getResourceURL(ngp,"projectAllTasks.htm");

    String upstreamLink = ngp.getUpstreamLink();
    Exception upstreamError = null;
    RemoteProject rp = null;
    ProjectSync ps = null;
    try {
        rp = new RemoteProject(upstreamLink);
        ps = new ProjectSync(ngp, rp, ar, ngp.getLicenses().get(0).getId());
    }
    catch (Exception uu) {
        upstreamError = uu;
        PrintWriter pw = new PrintWriter(System.out);
        uu.printStackTrace(pw);
        pw.flush();
    }

%>
<!-- MAIN CONTENT SECTION START -->
<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>


                <%
                if (upstreamLink==null || upstreamLink.length()==0) {
                    %><i>Set an Upstream link (above) in order to synchronize with an upstream workspace,<br/>
                    <br/>or..... enter a link to a remote site to create a new clone of this workspace.</i>


                  <form action="<%=ar.retPath%>Beam1Create.jsp" method="post">
                      <input type="hidden" name="go" value="<%ar.writeHtml(thisPage);%>">
                      <input type="hidden" name="p" value="<%ar.writeHtml(pageId);%>">
                      <input type="text" name="siteLink" value="" size="50" class="inputGeneral">
                      <input type="submit" name="op" value="Create Remote Upstream Workspace"  class="btn btn-primary btn-raised">
                  </form>

                    <%
                }
                else if (upstreamError!=null)  {
                    %><p><i>Encountered an error accessing the upstream workspace:
                         <%ar.writeHtml(upstreamError.toString());%></i></p>
                      <p>An error of this type usually means that there is a problem with
                         the upstream link URL.  Is the link correct?  Another possibility
                         is that the upstream server may be offline, or may not be reachable
                         from this server at this time.  </p>
                      <p>Upstream URL: <a href="<%ar.writeHtml(upstreamLink);%>">
                         <%ar.writeHtml(upstreamLink);%></a></p>
                      <p>The upstream link can be changed from this workspace's
                         <button class="btn btn-primary btn-raised" onclick="window.location='admin.htm'"
                         type="button">Admin</button> page.</p>
                    <%
                }
                else {

                    License lic = rp.getLicense();
                    long timeout = lic.getTimeout();
                    int days = (int) ( (timeout-ar.nowTime)/1000/60/60/24 );

                    int docsNeedingDown  = ps.getToDownload(SyncStatus.TYPE_DOCUMENT).size();
                    int docsNeedingUp    = ps.getToUpload(SyncStatus.TYPE_DOCUMENT).size();
                    int docsEqual        = ps.getEqual(SyncStatus.TYPE_DOCUMENT).size();
                    int notesNeedingDown = ps.getToDownload(SyncStatus.TYPE_NOTE).size();
                    int notesNeedingUp   = ps.getToUpload(SyncStatus.TYPE_NOTE).size();
                    int notesEqual       = ps.getEqual(SyncStatus.TYPE_NOTE).size();
                    int goalsNeedingDown = ps.getToDownload(SyncStatus.TYPE_TASK).size();
                    int goalsNeedingUp   = ps.getToUpload(SyncStatus.TYPE_TASK).size();
                    int goalsEqual       = ps.getEqual(SyncStatus.TYPE_TASK).size();
                %>
                <p>Link to workspace <a href="<%ar.writeHtml(rp.getUIAddress());%>"><%ar.writeHtml(rp.getName());%></a>
                    (<a href="<%ar.writeHtml(upstreamLink);%>">api</a>)
                    on the remote site <a href="<%ar.writeHtml(rp.getSiteUIAddress());%>"><%ar.writeHtml(rp.getSiteName());%></a>
                    (<a href="<%ar.writeHtml(rp.getSiteURL());%>">api</a>)
                    is valid for <%=days%> more day as long as
                    <% ar.writeHtml(lic.getCreator()); %> remains in the
                    <% ar.writeHtml(lic.getRole()); %> role in that workspace</p>

                <table width="720px">
                  <form action="<%=ar.retPath%>Beam1SyncAll.jsp" method="post">
                  <input type="hidden" name="go" value="<%ar.writeHtml(thisPage);%>">
                  <input type="hidden" name="p" value="<%ar.writeHtml(pageId);%>">
                    <tr>
                        <td class="gridTableColummHeader_2"></td>
                        <td style="width:20px;"></td>
                        <td style="width:40px;">Upload</td>
                        <td style="width:20px;"></td>
                        <td style="width:40px;">Download</td>
                        <td style="width:20px;"></td>
                        <td >In Synch</td>
                    </tr>
                    <tr>
                        <td class="gridTableColummHeader_2">Documents:</td>
                        <td style="width:20px;"></td>
                        <td style="width:40px;">
                            <input type="checkbox" name="docsUp" value="yes" <%if(docsNeedingUp>0){%>checked="checked"<%}%>>
                            <%=docsNeedingUp%></td>
                        <td style="width:20px;"></td>
                        <td style="width:40px;">
                            <input type="checkbox" name="docsDown" value="yes" <%if(docsNeedingDown>0){%>checked="checked"<%}%>>
                            <%=docsNeedingDown%></td>
                        <td style="width:20px;"></td>
                        <td ><%=docsEqual%></td>
                    </tr>
                    <tr>
                        <td class="gridTableColummHeader_2">Topics:</td>
                        <td style="width:20px"></td>
                        <td style="width:40px;">
                            <input type="checkbox" name="notesUp" value="yes" <%if(notesNeedingUp>0){%>checked="checked"<%}%>>
                            <%=notesNeedingUp%> </td>
                        <td style="width:20px;"></td>
                        <td style="width:40px;">
                            <input type="checkbox" name="notesDown" value="yes" <%if(notesNeedingDown>0){%>checked="checked"<%}%>>
                            <%=notesNeedingDown%> </td>
                        <td style="width:20px;"></td>
                        <td ><%=notesEqual%></td>
                    </tr>
                    <tr>
                        <td class="gridTableColummHeader_2">Action Items:</td>
                        <td style="width:20px;"></td>
                        <td style="width:40px;">
                            &nbsp; &nbsp;
                            <%=goalsNeedingUp%> </td>
                        <td style="width:20px;"></td>
                        <td style="width:40px;">
                            &nbsp; &nbsp;
                            <%=goalsNeedingDown%> </td>
                        <td style="width:20px;"></td>
                        <td ><%=goalsEqual%></td>
                    </tr>
                    <tr>
                        <td class="gridTableColummHeader_2"></td>
                        <td style="width:20px;"></td>
                        <td> <input type="submit" value="Upload All" name="op" class="btn btn-primary btn-raised"> </td>
                        <td style="width:20px;"></td>
                        <td> <input type="submit" value="Download All" name="op" class="btn btn-primary btn-raised"> </td>
                        <td style="width:20px;"></td>
                        <td> <input type="submit" value="Ping" name="op" class="btn btn-primary btn-raised"> </td>
                    </tr>
                  </form>
                </table>
                <% } %>
</div>
