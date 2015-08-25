<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.AttachmentRecord"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.BaseRecord"
%><%@page import="org.socialbiz.cog.NGBook"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.NGSection"
%><%@page import="org.socialbiz.cog.api.RemoteProject"
%><%@page import="org.socialbiz.cog.SectionDef"
%><%@page import="org.socialbiz.cog.api.ProjectSync"
%><%@page import="org.socialbiz.cog.api.SyncStatus"
%><%@page import="org.socialbiz.cog.SectionFormat"
%><%@page import="org.socialbiz.cog.SectionUtil"
%><%@page import="org.socialbiz.cog.StatusReport"
%><%@page import="org.socialbiz.cog.GoalRecord"
%><%@page import="org.socialbiz.cog.UserPage"
%><%@page import="org.socialbiz.cog.UserProfile"
%><%@page import="org.socialbiz.cog.UtilityMethods"
%><%@page import="org.socialbiz.cog.WatchRecord"
%><%@page import="org.socialbiz.cog.rest.TaskHelper"
%><%@page import="java.io.Writer"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Hashtable"
%><%@page import="java.util.Vector"
%><%@page import="org.w3c.dom.Element"
%><%
    ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Unable to see status report.");

    String p = ar.reqParam("p");

    ngp = ar.getCogInstance().getProjectByKeyOrFail(p);
    ar.setPageAccessLevels(ngp);
    ar.assertMember("unable to synchronize this project");

    boolean isAdmin = ar.isAdmin();

    pageTitle = "Project Sync: "+ngp.getFullName();
    specialTab = "Admin";

    //randomly, get the first license record
    License lr = ngp.getLicenses().get(0);

    RemoteProject rp = new RemoteProject(ngp.getUpstreamLink());

    ProjectSync ps = new ProjectSync(ngp, rp, ar, ngp.getLicenses().get(0).getId());
    Vector<SyncStatus> ss2 = ps.getStatus();

    Vector<SyncStatus> docsNeedingDown  = ps.getToDownload(SyncStatus.TYPE_DOCUMENT);
    Vector<SyncStatus> docsNeedingUp    = ps.getToUpload(SyncStatus.TYPE_DOCUMENT);
    Vector<SyncStatus> docsEqual        = ps.getEqual(SyncStatus.TYPE_DOCUMENT);
    Vector<SyncStatus> notesNeedingDown = ps.getToDownload(SyncStatus.TYPE_NOTE);
    Vector<SyncStatus> notesNeedingUp   = ps.getToUpload(SyncStatus.TYPE_NOTE);
    Vector<SyncStatus> notesEqual       = ps.getEqual(SyncStatus.TYPE_NOTE);
    Vector<SyncStatus> goalsNeedingDown = ps.getToDownload(SyncStatus.TYPE_TASK);
    Vector<SyncStatus> goalsNeedingUp   = ps.getToUpload(SyncStatus.TYPE_TASK);
    Vector<SyncStatus> goalsEqual       = ps.getEqual(SyncStatus.TYPE_TASK);


%>
<%@ include file="Header.jsp"%>

    <div class="pagenavigation">
        <div class="pagenav">
            <div class="left"><% ar.writeHtml( ngp.getFullName());%> &raquo; Synchronize Projects </div>
            <div class="right"></div>
            <div class="clearer">&nbsp;</div>
        </div>
        <div class="pagenav_bottom"></div>
    </div>

    <p>Need to get from Upstream</p>
    <ul>
        <li><%=docsNeedingDown.size()%> Documents</li>
        <li><%=notesNeedingDown.size()%> Notes</li>
        <li><%=goalsNeedingDown.size()%> Goals</li>

    </ul>
    <p>Need to send to Upstream</p>
    <ul>
        <li><%=docsNeedingUp.size()%> Documents</li>
        <li><%=notesNeedingUp.size()%> Notes</li>
        <li><%=goalsNeedingUp.size()%> Goals</li>

    </ul>
    <p>Fully Synchronized</p>
    <ul>
        <li><%=docsEqual.size()%> Documents</li>
        <li><%=notesEqual.size()%> Notes</li>
        <li><%=goalsEqual.size()%> Goals</li>

    </ul>

    <ul>
    <form action="<%=ar.retPath%>Beam1SyncAll.jsp">
    <input type="hidden" name="p" value="<%ar.writeHtml( ngp.getKey());%>">
    <input type="submit" value=" Synchronize All ">
    </form>
    </ul>
    <br/>

<%

    writeSyncSection(ar, docsNeedingDown, "Documents to Download", p);
    writeSyncSection(ar, docsNeedingUp, "Documents to Upload", p);
    writeSyncSection(ar, docsEqual, "Documents Equal", p);
    writeSyncSection(ar, notesNeedingDown, "Notes to Download", p);
    writeSyncSection(ar, notesNeedingUp, "Notes to Upload", p);
    writeSyncSection(ar, notesEqual, "Equal Notes", p);


%>
</div>

<%@ include file="Footer.jsp"%>
<%@ include file="functions.jsp"%>


<%!

public void writeSyncSection(AuthRequest ar, Vector<SyncStatus> ss1, String title, String p) throws Exception {

    ar.write("<div class=\"section\">");
    ar.write("  <div class=\"section_title\">");
    ar.write("    <h1 class=\"left\">");
    ar.writeHtml(title);
    ar.write("    </h1>");
    ar.write("    <div class=\"section_date right\"></div>");
    ar.write("    <div class=\"clearer\">&nbsp;</div>");
    ar.write("  </div>");
    ar.write("<div class=\"section_body\">");
    ar.write("<table>");
    ar.write("    <col width=\"300\">");
    ar.write("    <col width=\"150\">");
    ar.write("    <col width=\"25\">");
    ar.write("    <col width=\"25\">");
    ar.write("    <col width=\"25\">");
    ar.write("    <col width=\"150\">");
    ar.write("    <tr>");
    ar.write("       <td></td>");
    ar.write("       <td>Local</td>");
    ar.write("       <td></td>");
    ar.write("       <td></td>");
    ar.write("       <td></td>");
    ar.write("       <td>Remote</td>");
    ar.write("    </tr>");


    for (SyncStatus stat : ss1) {

        boolean isEqual = (stat.isLocal && stat.isRemote && stat.timeLocal == stat.timeRemote && stat.sizeLocal == stat.sizeRemote);

        boolean couldDown = (!stat.isLocal || stat.timeLocal < stat.timeRemote ||
             (stat.timeLocal == stat.timeRemote  && stat.sizeLocal != stat.sizeRemote)  );

        boolean couldUp   = (!stat.isRemote || stat.timeLocal > stat.timeRemote ||
             (stat.timeLocal == stat.timeRemote  && stat.sizeLocal != stat.sizeRemote)  );

        String urlUp = ar.retPath + "Beam1Action.jsp?cmd=Up&p="+URLEncoder.encode(p, "UTF-8")+"&i="+stat.universalId;
        String urlDn = ar.retPath + "Beam1Action.jsp?cmd=Dn&p="+URLEncoder.encode(p, "UTF-8")+"&i="+stat.universalId;

        ar.write("\n<tr><td>");
        String bestName = stat.nameLocal;
        if (bestName==null || bestName.length()==0) {
            bestName = stat.nameRemote;
        }
        ar.writeHtml(bestName);
        if (stat.isLocal) {
            ar.write("\n (<a href=\"");
            ar.write(stat.urlLocal);
            ar.write("\">loc</a>)");
        }
        if (stat.isRemote) {
            ar.write("\n (<a href=\"");
            ar.write(stat.urlRemote);
            ar.write("\">rem</a>)");
        }
        ar.write("\n</td><td>");
        if (stat.isLocal) {
            SectionUtil.nicePrintTimestamp(ar.w, stat.timeLocal);
            ar.write("\n<br/>");
            ar.write(Long.toString(stat.sizeLocal));
        }
        else {
            ar.write("\n<a href=\"");
            ar.write(urlDn);
            ar.write("\">Download</a>");
        }
        ar.write("\n</td><td>");
        if (couldDown) {
            ar.write("\n<a href=\"");
            ar.write(urlDn);
            ar.write("\"><img src=\"");
            ar.write(ar.retPath);
            ar.write("assets/iconArrowDownLeft.png\"></a>");
        }
        ar.write("\n</td><td>");
        if (isEqual) {
            ar.write("<img src=\"");
            ar.write(ar.retPath);
            ar.write("assets/iconEqualTo.gif\">");
        }
        ar.write("\n</td><td>");
        if (couldUp) {
            ar.write("\n<a href=\"");
            ar.write(urlUp);
            ar.write("\"><img src=\"");
            ar.write(ar.retPath);
            ar.write("assets/iconArrowUpRight.png\"></a>");
        }
        ar.write("\n</td><td>");
        if (stat.isRemote) {
            SectionUtil.nicePrintTimestamp(ar.w, stat.timeRemote);
            ar.write("<br/>");
            ar.write(Long.toString(stat.sizeRemote));
        }
        else {
            ar.write("\n<a href=\"");
            ar.write(urlUp);
            ar.write("\">Upload</a>");
        }
        ar.write("\n</td></tr>");

    }
    ar.write("  </table>");
    ar.write("</div>");
    ar.write("</div>");
    ar.flush();
}

%>