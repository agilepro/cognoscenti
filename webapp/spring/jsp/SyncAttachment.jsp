<%@page errorPage="/spring/jsp/error.jsp"
%><%@page import="org.socialbiz.cog.api.RemoteProject"
%><%@page import="org.socialbiz.cog.api.ProjectSync"
%><%@page import="org.socialbiz.cog.api.SyncStatus"
%><%@page import="org.socialbiz.cog.dms.FolderAccessHelper"
%><%@page import="org.socialbiz.cog.dms.ConnectionType"
%><%@page import="org.socialbiz.cog.dms.ConnectionSettings"
%><%@ include file="/spring/jsp/include.jsp"
%><%

    ar.assertLoggedIn("Must be logged in to synchronize attachments");

    String pageId  = ar.reqParam("pageId");
    String siteId  = ar.reqParam("siteId");
    NGWorkspace ngp = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngp);
    NGBook ngb = ngp.getSite();


    int countRows = 0;
    String thisPage = ar.getResourceURL(ngp,"SyncAttachment.htm");
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

// This needs to be rewritten to use Angular properly
// Need a proper example of documents from a repository

%>



<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http) {
    window.setMainPageTitle("Synchronize Documents");
//    $scope.attachInfo = <% /*attachInfo.write(out,2,4); */%>;

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };
});
</script>

<script type="text/javascript">

function onClickAction(flag){

   if(flag == "Synchronize"){
       <% if (!ngp.isFrozen()) { %>
           document.getElementById("attachmentForm").submit();
       <% }else{ %>
           openFreezeMessagePopup();
       <% } %>
   }else if(flag == "Cancel"){
       location.href = "listAttachments.htm";
   }

}

function changeIcon(id1,id2,id3){

    var position = id2.indexOf("-");
    var value = id2.substring(0,position);
    var row = id2.substring(position+1,id2.length);
    var rowId = "aid-"+row;
    var  readonlyId = "readonly-"+row;

    if(document.getElementById(readonlyId).value!='on'){
        document.getElementById(id1).style.display = "none";
        document.getElementById(id2).style.display = "block";
        document.getElementById(id3).style.display = "none";
        document.getElementById(rowId).value=value;
    }else{
        var checkinId = "checkin-"+row;
        var checkoutId = "checkout-"+row;
        var syncId = "sync-"+row;
        document.getElementById(checkinId).style.display = "none";
        if(document.getElementById(rowId).value == "checkout")
        {
            document.getElementById(rowId).value = "sync";
            document.getElementById(checkoutId).style.display = "none";
            document.getElementById(syncId).style.display = "block";
        }
        else
        {
            document.getElementById(rowId).value = "checkout";
            document.getElementById(syncId).style.display = "none";
            document.getElementById(checkoutId).style.display = "block";
        }
    }
}

</script>


<!-- MAIN CONTENT SECTION START -->
<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

    <div class="upRightOptions rightDivContent">
      <span class="dropdown">
        <button class="btn btn-default btn-raised dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
        Options: <span class="caret"></span></button>
        <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
          <li role="presentation">
              <a href="javascript:onClickAction('Synchronize')">
                  <img src="<%=ar.retPath %>assets/iconSync.gif" />
                  Synchronize Now
              </a>
          </li>
        </ul>
      </span>
    </div>

<%

if (ps!=null) {
    List<SyncStatus> upDocs = ps.getToUpload(SyncStatus.TYPE_DOCUMENT);
    List<SyncStatus> downDocs = ps.getToDownload(SyncStatus.TYPE_DOCUMENT);


    %>
    <div class="pageHeading">Upstream Synchronization</div>
    <div class="pageSubHeading">
        Documents to synchronize with upstream workspace.
    </div>
    <br/>
    <form action="<%=ar.retPath%>Beam1SyncAll.jsp" method="post">
        <input type="hidden" name="go" value="<%ar.writeHtml(thisPage);%>">
        <input type="hidden" name="p" value="<%ar.writeHtml(ngp.getKey());%>">
        <input type="hidden" value="Upload All" name="op">
        <button type="submit" name="docsUp" value="yes" class="btn btn-primary btn-raised">Send Documents Upstream</button>
        to workspace: <b><%ar.writeHtml(rp.getName());%></b>
    </form>
    <br/>
    <ul>
    <%
    int i=0;
    if (upDocs.size()==0) {
        %> <i>no documents need sending.</i> <%
    }
    else {
        for (SyncStatus upDoc : upDocs) {
            i++;
            %><li><%=i%>. <b><%ar.writeHtml(upDoc.nameLocal);%></b>
            (local ~ <%SectionUtil.nicePrintTime(ar.w,upDoc.timeLocal,ar.nowTime);%>)
            (remote ~ <%if (upDoc.timeLocal<=0) {%><i>none</i><%} else {SectionUtil.nicePrintTime(ar.w,upDoc.timeRemote,ar.nowTime);}%>)</li><%
        }
    }
    %>
    </ul>
    <br/>
    <form action="<%=ar.retPath%>Beam1SyncAll.jsp" method="post">
        <input type="hidden" name="go" value="<%ar.writeHtml(thisPage);%>">
        <input type="hidden" name="p" value="<%ar.writeHtml(ngp.getKey());%>">
        <input type="hidden" value="Download All" name="op">
        <button type="submit" name="docsDown" value="yes" class="btn btn-primary btn-raised">Fetch Documents from Upstream</button>
        to workspace: <b><%ar.writeHtml(rp.getName());%></b>
    </form>
    <br/>
    <ul>
    <%
    i=0;
    if (downDocs.size()==0) {
        %> <i>no documents need fetching.</i> <%
    }
    else {
        for (SyncStatus downDoc : downDocs) {
            i++;
            String newName = downDoc.nameRemote;
            String error = "";
            if (!downDoc.isLocal) {
                AttachmentRecord otherFileWithSameName = ngp.findAttachmentByName(newName);
                if (otherFileWithSameName!=null) {
                    error = "A local file exists with a conflicting name, and so this file can not be synchronized";
                }
            }
            else {
                AttachmentRecord localAtt = ngp.findAttachmentByID(newName);
                if (localAtt!=null && !localAtt.isUpstream()) {
                    error = "Local version has been marked to NOT synchronize, and so this file can not be synchronized";
                }
                if (localAtt!=null && localAtt.isDeleted()) {
                    error = "Local version has been deleted, and so this file can not be synchronized";
                }
            }
            %><li><%=i%>. <b><%ar.writeHtml(downDoc.nameRemote);%></b>
            (local ~ <%if (downDoc.timeLocal<=0) {%><i>none</i><%} else {SectionUtil.nicePrintTime(ar.w,downDoc.timeLocal,ar.nowTime);}%>)
            (remote ~ <%SectionUtil.nicePrintTime(ar.w,downDoc.timeRemote,ar.nowTime);%>)
            <span style="color:red"><%ar.writeHtml(error);%></span></li><%
        }
    }
    %>
    </ul>
    <br/>
    <%
}
%>



    <form name="attachmentForm" id="attachmentForm" action="Synchronize.form" method="post">
        <div id="paging"></div>
       <div id="listofpagesdiv<%=SectionDef.PUBLIC_ACCESS %>">
           <table id="pagelist">
               <tbody>
               <%
               countRows = attachmentDisplay(ar, (NGWorkspace) ngp);
               %>
               </tbody>
           </table>
       </div>
       <input type="hidden" name="countRows" id="countRows" value="<%ar.writeHtml(String.valueOf(countRows)); %>">
       <input type="hidden" name="p" id="p" value="<%ar.writeHtml(ngp.getKey()); %>">
    </form>
</div>
</div>
</div>





<%!

public int attachmentDisplay(AuthRequest ar, NGWorkspace ngp) throws Exception
{
    int countRows = 0;
    ngp.scanForNewFiles();
    FolderAccessHelper fdah = new FolderAccessHelper(ar);
    for(AttachmentRecord attachment : ngp.getAllAttachments())
    {
        if (attachment.isDeleted())
        {
            continue;
        }

        String rLink = attachment.getRemoteCombo().getComboString();
        if(!attachment.hasRemoteLink()) {
            continue;
        }

        String id = attachment.getId();
        String displayName = attachment.getNiceNameTruncated(48);
        NGWorkspace page = ngp;
        AttachmentRecord attch = page.findAttachmentByID(id);

        ar.write("\n<tr>");
        ar.write("\n<td width=\"250px\">");
        ar.writeHtml(displayName);
        ar.write("</td>");

        long mTime = attch.getModifiedDate();       // modified time of local attachment
        long rCTime = attch.getAttachTime();        // creation time of attachment saved in *.sp file
        long rlmTime = attch.getFormerRemoteTime(); // recently modified remote time saved in *.sp file
        String readonly = "off";
        if((attch.getReadOnlyType()!=null) && (attch.getReadOnlyType().length()>0))
        {
            readonly = attch.getReadOnlyType();
        }

        try
        {
            long rslmTime = fdah.getLastModified(rLink);// recently modified remote fetched from sharepoint
            RemoteLinkCombo rlc = attachment.getRemoteCombo();
            String folderId = rlc.folderId;
            UserPage up = rlc.getUserPage();
            ConnectionType cType = up.getConnectionOrNull(folderId);
            if(cType == null){
                throw new ProgramLogicError("Can not find a connection with id '"+folderId+"' for user '"+rlc.userKey+"'.");
            }
            ConnectionSettings cSet = up.getConnectionSettingsOrNull(folderId);
            if(cSet == null){
                throw new ProgramLogicError("Public Web Access can not be synchronized.");
            }
            if(cSet.isDeleted()){
                throw new ProgramLogicError("Connection have been deleted.");
            }
            boolean lModifed = false;
            boolean rModifed = false;

            //note that times are not always accurate to millisecond, and there may be error
            //should compare if these are within a few seconds of each other, that is close enough
            if(mTime != rCTime){
                lModifed = true;
            }
            if(rlmTime != rslmTime){
                rModifed = true;
            }

            ar.write("\n<td>");
            SectionUtil.nicePrintTime(ar.w,attachment.getModifiedDate(), ar.nowTime);
            if(lModifed && !rModifed){
                ar.write("<img src=\"");
                ar.write(ar.retPath);
                ar.write("assets/iconChanged.jpg\" title=\"Modified\">");
            }
            ar.write("</td>");
            ar.write("\n<td>");
            ar.write("<input type=\"hidden\" name=\"readonly-"+id+"\" id=\"readonly-"+id+"\" value="+readonly+">");
            if(lModifed && rModifed){
                ar.write("<img src=\"");
                ar.write(ar.retPath);
                ar.write("assets/iconWarning.png\" id=\"warning-"+id+"\" title=\"Conflict\" style=\"display:block\" onclick=\"changeIcon('warning-"+id+"','checkin-"+id+"','checkout-"+id+"');\">");
                ar.write("<img src=\"");
                ar.write(ar.retPath);
                ar.write("assets/iconArrowUpRight.png\" id=\"checkin-"+id+"\" title=\"Update Repository\" style=\"display:none\" value=\"1\" onclick=\"changeIcon('checkin-"+id+"','checkout-"+id+"','warning-"+id+"');\">");
                ar.write("<img src=\"");
                ar.write(ar.retPath);
                ar.write("assets/iconArrowDownLeft.png\" id=\"checkout-"+id+"\" title=\"Update Local\" style=\"display:none\" value=\"2\" onclick=\"changeIcon('checkout-"+id+"','warning-"+id+"','checkin-"+id+"');\">");
                ar.write("<input type=\"hidden\" name=\"aid-"+id+"\" id=\"aid-"+id+"\" value=\"warning\">");
            }
            else if(lModifed && !rModifed){
                ar.write("<img src=\"");
                ar.write(ar.retPath);
                ar.write("assets/iconEqualTo.gif\" id=\"sync-"+id+"\" title=\"Synchronized Document\" style=\"display:none\" onclick=\"changeIcon('sync-"+id+"','checkin-"+id+"','checkout-"+id+"');\">");
                ar.write("<img src=\"");
                ar.write(ar.retPath);
                ar.write("assets/iconArrowUpRight.png\" id=\"checkin-"+id+"\" title=\"Update Repository\" style=\"display:block\" onclick=\"changeIcon('checkin-"+id+"','checkout-"+id+"','sync-"+id+"');\">");
                ar.write("<img src=\"");
                ar.write(ar.retPath);
                ar.write("assets/iconArrowDownLeft.png\" id=\"checkout-"+id+"\" title=\"Update Local\" style=\"display:none\" onclick=\"changeIcon('checkout-"+id+"','sync-"+id+"','checkin-"+id+"');\">");
                ar.write("<input type=\"hidden\" name=\"aid-"+id+"\" id=\"aid-"+id+"\" value=\"checkin\">");
            }
            else if(!lModifed && rModifed){
                ar.write("<img src=\"");
                ar.write(ar.retPath);
                ar.write("assets/iconEqualTo.gif\" id=\"sync-"+id+"\" title=\"Synchronized Document\" style=\"display:none\" onclick=\"changeIcon('sync-"+id+"','checkin-"+id+"','checkout-"+id+"');\">");
                ar.write("<img src=\"");
                ar.write(ar.retPath);
                ar.write("assets/iconArrowUpRight.png\" id=\"checkin-"+id+"\" title=\"Update Repository\" style=\"display:none\" onclick=\"changeIcon('checkin-"+id+"','checkout-"+id+"','sync-"+id+"');\">");
                ar.write("<img src=\"");
                ar.write(ar.retPath);
                ar.write("assets/iconArrowDownLeft.png\" id=\"checkout-"+id+"\" title=\"Update Local\" style=\"display:block\" onclick=\"changeIcon('checkout-"+id+"','sync-"+id+"','checkin-"+id+"');\">");
                ar.write("<input type=\"hidden\" name=\"aid-"+id+"\" id=\"aid-"+id+"\" value=\"checkout\">");
            }
            else {
                ar.write("<img src=\"");
                ar.write(ar.retPath);
                ar.write("assets/iconEqualTo.gif\" id=\"sync-"+id+"\" title=\"Synchronized Document\">");
                ar.write("<input type=\"hidden\" name=\"aid-"+id+"\" id=\"aid-"+id+"\" value=\"sync\">");
            }
            ar.write("</td>");
            ar.write("\n<td>");
            SectionUtil.nicePrintTime(ar.w, rslmTime, ar.nowTime);
            if(!lModifed && rModifed){
                ar.write("<img src=\"");
                ar.write(ar.retPath);
                ar.write("assets/iconChanged.jpg\" title=\"Modified\">");
            }
            ar.write("</td>");

        }
        catch(Exception e){
            ar.write("\n<td>");
            SectionUtil.nicePrintTime(ar.w,attachment.getModifiedDate(), ar.nowTime);
            ar.write("</td>");
            ar.write("\n<td>");
            String pageLink = ar.baseURL+"t/"+page.getSite().getKey()+"/"+page.getKey()+"/problemDiagnosePage.htm?id="+id;
            ar.write("<img src=\"");
            ar.write(ar.retPath);
            ar.write("assets/iconError.png\" title=\"Error in connection\">");
            ar.write("</td>");
            ar.write("\n<td><a title=\"");
            ar.writeHtml(e.toString());
            ar.write("\" href=\"");
            if(ngp.isFrozen()){
                ar.write("#\" onclick=\"javascript:return openFreezeMessagePopup();\">");
            }else{
                ar.writeHtml(pageLink);
                ar.write("\">");
            }
            ar.write("Problem with Link</a>");
            ar.write("</td>");

        }

        ar.write("<td>");
        ar.writeHtml(id);
        ar.write("</td>");
        ar.write("\n<td>");
        long diff = (ar.nowTime - attachment.getModifiedDate())/1000;
        ar.writeHtml(String.valueOf(diff));
        ar.write("</td>");
        ar.write("<td>"+attachment.isPublic()+"</td>");
        ar.write("</tr>");
        countRows++;
    }
    return countRows;
}
%>
