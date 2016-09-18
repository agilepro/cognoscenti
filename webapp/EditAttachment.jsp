<%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page errorPage="error.jsp"
%><%@page import="org.socialbiz.cog.AttachmentRecord"
%><%@page import="org.socialbiz.cog.AttachmentVersion"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.BaseRecord"
%><%@page import="org.socialbiz.cog.HistoryRecord"
%><%@page import="org.socialbiz.cog.MimeTypes"
%><%@page import="org.socialbiz.cog.NGBook"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.NGSection"
%><%@page import="org.socialbiz.cog.SectionUtil"
%><%@page import="org.socialbiz.cog.GoalRecord"
%><%@page import="org.socialbiz.cog.UserProfile"
%><%@page import="org.socialbiz.cog.UtilityMethods"
%><%@page import="java.io.Writer"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.List"
%><%@page import="java.util.Vector"
%><%ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Can't edit an attachment.");

    String p        = ar.reqParam("p");
    String aid      = ar.reqParam("aid");

    assureNoParameter(ar, "s");

    ngp = ar.getCogInstance().getWorkspaceByKeyOrFail(p);
    ar.setPageAccessLevels(ngp);
    ar.assertMember("Unable to edit attachments in this project.");

    AttachmentRecord attachment = ngp.findAttachmentByID(aid);

    if (attachment == null) {
        throw new Exception("Unable to find the attachment with the id : " + aid);
    }


    String name     = attachment.getDisplayName();
    String type     = attachment.getType();
    String comment  = attachment.getDescription();
    String fname    = attachment.getStorageFileName();
    String muser    = attachment.getModifiedBy();
    long   mdate    = attachment.getModifiedDate();

    if (type.length() == 0)  { throw new Exception("Attachment type is not set"); }
    boolean isFile = (type.equalsIgnoreCase("FILE"));
    boolean isURL = (type.equalsIgnoreCase("URL"));


    pageTitle = ngp.getFullName() + " / "+ attachment.getNiceNameTruncated(48);%>

<%@ include file="Header.jsp"%>

<h3>Edit Attachment</h3><br/>
<form name="attachmentForm" method="post" action="EditAttachmentAction.jsp" onSubmit="enableAllControls()">
    <input type="hidden" name="p" value="<% ar.writeHtml(p); %>">
    <input type="hidden" name="aid" value="<% ar.writeHtml(aid); %>">
    <table width="90%" class="Design8">
        <col width="20%"/>
        <col width="80%"/>
        <tr><td>Type</td>
            <td class="Odd">
                <input type="hidden" name="ftype" value="<%ar.writeHtml(type);%>">
                <%
                if (isFile)
                {
                   out.write("File");
                }
                else if (isURL)
                {
                   out.write("URL");
                }
                else
                {
                   throw new Exception("Do not understand attachment type: "+type);
                }
                %>
            </td>
        </tr>
        <tr>
            <td align="left">
                <label id="nameLbl">Access Name</label>
            </td>
            <td class="Odd"><input type="text" name="name" value="<% ar.writeHtml(name); %>" id="name" style="WIDTH:95%;"/>

            </td>
        </tr>
        <tr>
            <td>Description</td>
            <td class="Odd">
                <textarea name="comment" style="WIDTH:95%; HEIGHT:74px;"><% ar.writeHtml(comment); %></textarea>
            </td>
        </tr>
        <tr>
            <td>Last Modified By</td>
            <td class="Odd">
                <% ar.writeHtml(SectionUtil.cleanName(muser)); %>
            </td>
        </tr>
        <tr>
            <td>Last Modified Date</td>
            <td class="Odd">
                <% SectionUtil.nicePrintTime(ar, mdate, ar.nowTime); %>
            </td>
        </tr>
        <tr>
            <td>Visibility</td>
            <td class="Odd">
            <% if (attachment.isPublic()) { %>
                YES Public Access,
            <% } else { %>
                NO Public Access,
            <% } %>
            YES Member Access,
            <% if (attachment.isUpstream()) {%>
                YES Upstream
            <% } else { %>
                NO Upstream
            <% } %>
            </td>
        </tr>
        <tr>
            <td>Storage Name</td>
            <td class="Odd">
                <% ar.writeHtml(attachment.getStorageFileName()); %>
            </td>
        </tr>
        <tr>
            <td>Size</td>
            <td class="Odd">
                <%=attachment.getFileSize(ngp)%>
            </td>
        </tr>
        <tr>
            <td>Mime Type</td>
            <td class="Odd">
                <%
        String mimeType=MimeTypes.getMimeType(attachment.getNiceName());
        ar.writeHtml(mimeType);
                %>
            </td>
        </tr>
        <tr>
            <td>Remote</td>
            <td class="Odd">
                <%ar.writeHtml(attachment.getRemoteCombo().getComboString()); %>
            </td>
        </tr>
        <tr>
            <td>Universal</td>
            <td class="Odd">
                <%ar.writeHtml(attachment.getUniversalId()); %>
            </td>
        </tr>
        <tr>
            <td>Access Roles</td>
            <td class="Odd">
                <%
                String primaryRole = ngp.getPrimaryRole().getName();
                String secondRole = ngp.getSecondaryRole().getName();
                List<NGRole> roleList = attachment.getAccessRoles();

                for (NGRole aRole : ngp.getAllRoles()) {
                    String roleName = aRole.getName();
                    if (primaryRole.equals(roleName)) {
                        continue;
                    }
                    if (secondRole.equals(roleName)) {
                        continue;
                    }

                    %>  <input type="checkbox" name="accessRole" value="<%
                    ar.writeHtml(roleName);
                    if (containsRole(aRole, roleList)) {
                        %>" checked="checked<%
                    }
                    %>">&nbsp;<%
                    ar.writeHtml(roleName);
                }

                for (NGRole aRole : roleList) {
                    ar.writeHtml(" <"+aRole.getName()+"> ");
                }


                %>
            </td>
        </tr>
        <tr>
            <td>Personal Status</td>
            <td class="Odd">
                Mark Document as:
                <button type="submit" id="actBtn3" name="action" value="Accept">Read</button>
                <button type="submit" id="actBtn4" name="action" value="Reject">Needs Improvement</button>
                <button type="submit" id="actBtn5" name="action" value="Skipped">Skipped</button>
            </td>
        </tr>
    </table>
    <br/>
    <center>
        <button type="submit" id="actBtn1" name="action" value="Update">Update</button>&nbsp;
        <button type="submit" id="actBtn2" name="action" value="Cancel">Cancel</button>
        - - -
        <button type="submit" id="actBtn6" name="action" value="Remove">Delete Attachment</button>
        <input type="checkbox" name="confirmdel"/> Check to confirm delete

    </center>
    <br/>

</form>

<script>
    var actBtn1 = new YAHOO.widget.Button("actBtn1");
    var actBtn2 = new YAHOO.widget.Button("actBtn2");
    var actBtn3 = new YAHOO.widget.Button("actBtn3");
    var actBtn4 = new YAHOO.widget.Button("actBtn4");
    var actBtn5 = new YAHOO.widget.Button("actBtn5");
    var actBtn5 = new YAHOO.widget.Button("actBtn6");
</script>


<h3>History</h3>
<ul>
<%
    List<HistoryRecord> histRecs = ngp.getAllHistory();
    for (HistoryRecord hist : histRecs)
    {
        if (aid.equals(hist.getContext()))
        {
            String shortName = SectionUtil.cleanName(hist.getResponsible());
            %>
            <li><%
            ar.writeHtml(HistoryRecord.convertEventTypeToString(hist.getEventType()));
            ar.write(" by ");
            ar.writeHtml(shortName);
            ar.write(" ");
            SectionUtil.nicePrintTime(ar, hist.getTimeStamp(), ar.nowTime);
            %></li><%
        }
    }
%>
</ul>
<h3>Versions</h3>
<ul>
<%
    List<AttachmentVersion> allVersions = attachment.getVersions(ngp);
    for (AttachmentVersion av : allVersions)
    {
        %><li><%=av.getNumber()%>. <%SectionUtil.nicePrintTime(ar, av.getCreatedDate(), ar.nowTime);%>.</li><%
    }
%>
</ul>

<%@ include file="Footer.jsp"%>
<%@ include file="functions.jsp"%>

<%!

    public boolean containsRole(NGRole aRole, List<NGRole> roleList) {
        for (NGRole seeker : roleList) {
            if (aRole.getName().equals(seeker.getName())) {
                return true;
            }
        }
        return false;
    }

    %>
