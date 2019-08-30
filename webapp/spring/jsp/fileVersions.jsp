<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="org.socialbiz.cog.AttachmentVersion"
%><%
    ar.assertLoggedIn("Must be logged in to see anything about a user");

    String pageId = ar.reqParam("pageId");
    String siteId = ar.reqParam("siteId");
    NGWorkspace ngp = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngp);
    NGBook site = ngp.getSite();

    String aid      = ar.reqParam("aid");
    AttachmentRecord attachment = ngp.findAttachmentByID(aid);

    JSONObject attachInfo = attachment.getJSON4Doc(ar, ngp);

    List<AttachmentVersion>  versionList = attachment.getVersions(ngp);
    JSONArray allVersions = new JSONArray();
    for(AttachmentVersion aVer : versionList){
        JSONObject verObj = new JSONObject();
        verObj.put("num", aVer.getNumber());
        verObj.put("date", aVer.getCreatedDate());
        verObj.put("size", aVer.getLocalFile().length());
        verObj.put("modified", aVer.isModified());
        if ("URL".equals(attachment.getType())) {
            verObj.put("link", attachment.getStorageFileName());
        }
        else {
            verObj.put("link", "a/" + SectionUtil.encodeURLData(attachment.getNiceName())+"?version="+aVer.getNumber());
        }
        allVersions.put(verObj);
    }
    List<HistoryRecord> histRecs = ngp.getHistoryForResource(HistoryRecord.CONTEXT_TYPE_DOCUMENT,aid);
    JSONArray allHistory = new JSONArray();
    for (HistoryRecord hist : histRecs) {
        JSONObject jo = hist.getJSON(ngp, ar);
        AddressListEntry ale = new AddressListEntry(hist.getResponsible());
        jo.put("responsible", ale.getJSON() );
        UserProfile responsible = ale.getUserProfile();
        String imagePath = "assets/photoThumbnail.gif";
        if(responsible!=null) {
            String imgPath = responsible.getImage();
            if (imgPath!=null && imgPath.length() > 0) {
                imagePath = "icon/"+imgPath;
            }
        }
        jo.put("imagePath",   imagePath );
        allHistory.put(jo);
    }
    

/***** PROTOTYPE
    $scope.attachInfo = {
      "attType": "FILE",
      "deleted": false,
      "description": "Selective Validation Technical User Story - Proposed Final",
      "id": "5892",
      "labelMap": {"User Story": true},
      "modifiedtime": 1406660134125,
      "modifieduser": "rob.blake@trintech.com",
      "name": "FujitsuTrintech_SECInlineXBRLProject_SelectiveValidation_V6ProposedFinal.docx",
      "public": false,
      "size": 57775,
      "universalid": "JRNJXVMSG@sec-inline-xbrl@5214",
      "upstream": true
    };
    $scope.allVersions = [{
      "date": 1409250772993,
      "num": 1,
      "size": 57775
    }];
*/
%>



<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http) {
    window.setMainPageTitle("List Document Versions");
    $scope.siteInfo = <%site.getConfigJSON().write(out,2,4);%>;
    $scope.attachInfo = <%attachInfo.write(out,2,4);%>;
    $scope.allVersions = <%allVersions.write(out,2,4);%>;
    $scope.history = <%allHistory.write(out,2,4);%>;

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };
});
</script>

<style>
.spacey {
}
.spacey tr td {
    padding:10px;
}
</style>

<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

    <div class="upRightOptions rightDivContent">
      <span class="dropdown">
        <button class="btn btn-default btn-raised dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
        Options: <span class="caret"></span></button>
        <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
          <li role="presentation"><a role="menuitem" tabindex="-1"
              href="docinfo{{attachInfo.id}}.htm" >Access Document</a></li>
          <li role="presentation"><a role="menuitem" tabindex="-1"
              href="docsRevise.htm?aid={{attachInfo.id}}" >Upload New Version</a></li>
          <li role="presentation"><a role="menuitem" tabindex="-1"
              href="editDetails{{attachInfo.id}}.htm" >Edit Details</a></li>
          <li role="presentation"><a role="menuitem" tabindex="-1"
              href="fileVersions.htm?aid={{attachInfo.id}}">List Versions</a></li>
          <li role="presentation"><a role="menuitem"
              href="SendNote.htm?att={{attachInfo.id}}">Send Document by Email</a></li>
        </ul>
      </span>
    </div>

    <table class="spacey">
        <thead>
            <tr>
                <td>Version</td>
                <td>Modified Date</td>
                <td>File Size</td>
            </tr>
        </thead>
        <tbody>
            <tr ng-repeat="ver in allVersions">
                <td>
                    <a href="{{ver.link}}" title="Access the content of this version of the attachment">
                    {{ver.num}}: {{attachInfo.name}}
                    <span ng-show="ver.modified">(Modified)</span>
                    </a>
                </td>
                <td>{{ver.date | date}}</td>
                <td>{{ver.size | number}}</td>
            </tr>
        </tbody>
    </table>
    
    <h3>History</h3>
    <table>

        <tr ng-repeat="hist in history"  >
            <td class="projectStreamIcons" style="padding-bottom:20px;">
                <img class="img-circle" src="<%=ar.retPath%>{{hist.imagePath}}" alt="" width="50" height="50" />
            </td>
            <td class="projectStreamText" style="padding-bottom:10px;">
                {{hist.time|date}} -
                <a href="<%=ar.retPath%>{{hist.respUrl}}"><span class="red">{{hist.respName}}</span></a>
                <br/>
                {{hist.ctxType}} "<a href="<%=ar.retPath%>{{hist.contextUrl}}">{{hist.ctxName}}</a>"
                was {{hist.event}}.
                <br/>
                <i>{{hist.comments}}</i>

            </td>
        </tr>

    </table>
    
</div>
