<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="org.socialbiz.cog.AttachmentVersion"
%><%
    ar.assertLoggedIn("Must be logged in to see anything about a user");

    String pageId      = ar.reqParam("pageId");
    NGPage ngp = ar.getCogInstance().getWorkspaceByKeyOrFail(pageId);
    ar.setPageAccessLevels(ngp);
    NGBook ngb = ngp.getSite();

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

var app = angular.module('myApp', ['ui.bootstrap']);
app.controller('myCtrl', function($scope, $http) {
    $scope.attachInfo = <%attachInfo.write(out,2,4);%>;
    $scope.allVersions = <%allVersions.write(out,2,4);%>;

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };
});
</script>



<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

    <div class="generalHeading" style="height:40px">
        <div  style="float:left;margin-top:8px;">
            Attachment Versions
        </div>
        <div class="rightDivContent" style="margin-right:100px;">
          <span class="dropdown">
            <button class="btn btn-default dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
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
                  href="sendNote.htm?att={{attachInfo.id}}">Send Document by Email</a></li>
            </ul>
          </span>

        </div>
    </div>

    <table class="gridTable2" width="100%">
        <thead>
            <tr class="gridTableHeader">
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
</div>
