<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="include.jsp"
%><%@page import="org.socialbiz.cog.EmailListener"
%><%@page import="org.socialbiz.cog.License"
%><%@page import="java.util.Date"
%>
<%
    String pageId  = ar.reqParam("pageId");
    String siteId  = ar.reqParam("siteId");
    NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngp);
    ar.assertLoggedIn("Must be logged in to see anything about a user");
    ar.assertMember("This VIEW only for members in use cases");

    NGBook ngb = ngp.getSite();

    UserProfile up = ar.getUserProfile();

    String thisPage = ar.getResourceURL(ngp,"streamingLinks.htm");

%>



<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

    <div>
    Email Address: <% ar.writeHtml(EmailListener.getEmailProperties().getProperty("mail.smtp.from")); %><br/>
    Token:  [cog:<% ar.writeHtml(ngp.getKey()); %>] - include this in the subject to address this workspace.
    </div>

    <div style="height:30px">&nbsp;</div>
    <div class="generalHeading">Workspace Streaming Links</div>

    <table width="600" border="0">
        <col width="150">
        <col width="150">
        <col width="100">
        <col width="150">
        <col width="150">
        <tr>
          <td><b>View / Role</b></td>
          <td align="center"><b>Days Left</b></td>
          <td align="center"><b>Readonly</b></td>
          <td align="center"><b>Link</b></td>
          <td align="center"><b>User</b></td>
        </tr>
<%
    for (License lr : ngp.getLicenses())
    {
        if (!up.hasAnyId(lr.getCreator())) {
            continue;
        }

        // add one so that the license is valid until it is zero
        // when there is a fraction of a day left, it will still show "1"
        // and when it goes to zero, the license is no longer valid.
        int days = (int)((lr.getTimeout() - ar.nowTime)/24000/3600) + 1;
        if (days<0) {
            days=0;
        }
        String readWrite = "";
        if (lr.isReadOnly()) {
            readWrite = "X";
        }

        String rightUrl = ar.baseURL + "api/" + ngb.getKey() + "/" + ngp.getKey() + "/summary.json";
        LicensedURL projectPath = new LicensedURL(rightUrl, null, lr.getId());
        AddressListEntry ale = new AddressListEntry(lr.getCreator());

        %>
            <tr>
            <td><% ar.writeHtml(SectionUtil.cleanName(lr.getRole()));%> </td>
            <td align="center"><%=days%> days</td>
            <td align="center"><%=readWrite%></td>
            <td align="center"><a href="<%ar.writeHtml(projectPath.getCombinedRepresentation());%>">Copy This Link</a>
            </td>
            <td align="center"><% ale.writeLink(ar); %></td>
            </tr><%

    } %>

</table>

<div style="height=30px;"> </div>


<table style="margin-top:30px;width:600px;">
    <tr>
      <td><b>View / Role</b></td>
      <td align="center"><b>Days</b></td>
      <td align="center"><b>Readonly</b></td>
      <td align="center"></td>
      <td align="center"></td>
    </tr>

<form action="<%=ar.retPath%>LicenseAction.jsp" method="post">
    <input type="hidden" name="encodingGuard" value="<%ar.writeHtml("\u6771\u4eac");%>"/>
    <input type="hidden" name="go" value="<%ar.writeHtml(thisPage);%>">
    <input type="hidden" name="p" value="<%ar.writeHtml(pageId);%>">
    <tr>
        <td>
        <select name="role" class="form-control">
            <%for (NGRole aRole : ngp.getAllRoles()) {%>
            <option value="<%ar.writeHtml(aRole.getName());%>"><%ar.writeHtml(aRole.getName());%></option>
            <% } %>
        </select>
        </td>
        <td align="center">
            <input type="text" name="duration" value="60" size="5" class="form-control">
        </td>
        <td>
            <input type="checkbox" name="readOnly" value="yes" class="form-control">
        </td>
        <td colspan="2">
            <input type="submit" name="action" value="Create New Streaming Link" class="btn btn-primary btn-raised">
        </td>
    </tr>
</form>

          </table>
      </div>

</div>
