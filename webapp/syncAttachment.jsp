<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.NGBook"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.NGSection"
%><%@page import="org.socialbiz.cog.SectionFormat"
%><%@page import="org.socialbiz.cog.SectionUtil"
%><%@page import="org.socialbiz.cog.UserProfile"
%><%@page import="org.socialbiz.cog.UtilityMethods"
%><%@page import="java.net.URLEncoder"
%><%@page import="org.w3c.dom.Element"
%><%ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Can't edit this section.");

    String p = ar.reqParam("p");
    String aid = ar.reqParam("aid");

    ngp = ar.getCogInstance().getProjectByKeyOrFail(p);
    if (ngp.isDeleted())
    {
        throw new Exception("This page has been deleted, and can not be edited.  If you want to change this page contents, first 'un-delete' the page (Admin) and then you can edit the sections");
    }
    ar.setPageAccessLevels(ngp);

    NGSection secToEdit = ngp.getSectionOrFail("Attachments");


    NGSection ngs = ngp.getSectionOrFail("Folders");
    FolderAccessHelper fdah = new FolderAccessHelper(ar);

    String lModifed = "false";
    String rModifed = "false";
    AttachmentRecord attch = ngp.findAttachmentByID(aid);
    String rLink = attch.getRemoteCombo().getComboString();


    String rfileName = rLink.substring(rLink.lastIndexOf('/') + 1);

    String lfileName = attch.getDisplayName();

    long mTime = attch.getModifiedDate();
    long rCTime = attch.getAttachTime();
    long rlmTime = attch.getFormerRemoteTime();
    long rslmTime = fdah.getLastModified(rLink);
    if(mTime != rCTime)
    {
        lModifed = "true";
    }
    if(rlmTime != rslmTime)
    {
        rModifed = "true";
    }

    ngb = ngp.getSite();
    pageTitle = ngp.getFullName();
    boolean isMember = ar.isMember();%>

<%@ include file="Header.jsp"%>

<%

if (!ar.isLoggedIn())
{
    %>
    <div class="pagenavigation">
        <div class="pagenav">
            <div class="left">
            In order to manipulate the values of the <%ar.writeHtml(secToEdit.getName());%> section of
            the project, you need to be a
            logged in, and you need to have permissions to edit that section.
            </div>
            <div class="right"></div>
            <div class="clearer">&nbsp;</div>
        </div>
        <div class="pagenav_bottom"></div>
    </div>
    <%

}
else if (!ar.isMember())
{
    %>
    <div class="pagenavigation">
        <div class="pagenav">
            <div class="left">
            In order to manipulate the values of the <%ar.writeHtml(secToEdit.getName()); %> section of the project,
            you need to have permissions to edit that section.  Permissions are based on
            your role as a member or admin, and the requirements of that
            particular section.
            </div>
            <div class="right"></div>
            <div class="clearer">&nbsp;</div>
        </div>
        <div class="pagenav_bottom"></div>
    </div>
    <%

}
else
{
    ar.assertMember("You can not edit section '"+ secToEdit.getName() +"' at this time.  ");

}

%>
<br/><b>Synchronize Attachment <%ar.writeHtml(lfileName);%>.</b><br/><br/>
<table width="80%" class="Design8" ><col width="20%"/><col width="80%"/>
<thead>
    <tr>
        <th allign>Location</th>
        <th class="odd">Name</th>
        <th class="odd">Current</th>
        <th class="odd">Former</th>
        <th class="odd">Modified</th>
    </tr>
</thead>
<tbody>
<tr>
    <td class="odd">Local</td>
    <td class="odd"><%ar.writeHtml(lfileName);%></td>
    <td class="odd"><%SectionUtil.nicePrintDateAndTime(ar.w, mTime);%></td>
    <td class="odd"><%SectionUtil.nicePrintDateAndTime(ar.w, rCTime);%></td>
    <td class="odd"><%=lModifed%></td>
</tr>
<tr>
    <td class="odd">Remote</td>
    <td class="odd"><%ar.writeHtml(rfileName);%></td>
    <td class="odd"><%SectionUtil.nicePrintDateAndTime(ar.w, rslmTime);%></td>
    <td class="odd"><%SectionUtil.nicePrintDateAndTime(ar.w, rlmTime);%></td>
    <td class="odd"><%=rModifed%></td>
</tr>
<tr>
    <td colspan="5"><%ar.writeHtml(rLink);%></td>
</tr>
</tbody>
</table><br/>

<form action="syncAttachmentAction.jsp" method="post">
<input type="hidden" name="encodingGuard" value="<%ar.writeHtml("\u6771\u4eac");%>"/>
<input type="hidden" name="p"       value="<%ar.writeHtml(p);%>"/>
<input type="hidden" name="aid"       value="<%ar.writeHtml(aid);%>"/>
<input type="submit" id="actBtn1" name="action" value="Update to Repository"/>
<input type="submit" id="actBtn1" name="action" value="Refresh from Repository"/>
<input type="submit" id="actBtn2" name="action" value="Cancel">
</form>

<br/><br/>
<%@ include file="Footer.jsp"%>
<%@ include file="functions.jsp"%>
