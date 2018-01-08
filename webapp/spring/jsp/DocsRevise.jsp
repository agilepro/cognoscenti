<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="org.socialbiz.cog.LicenseForUser"
%><%@ include file="functions.jsp"
%><%


    String aid         = ar.reqParam("aid");    
    String pageId = ar.reqParam("pageId");
    String siteId = ar.reqParam("siteId");
    NGWorkspace ngp = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngp);
    ar.assertMember("Must be a member to upload documents");
    NGBook site = ngp.getSite();

    AttachmentRecord attachRec = ngp.findAttachmentByIDOrFail(aid);
    JSONObject docInfo = attachRec.getJSON4Doc(ar, ngp);

    LicenseForUser lfu = new LicenseForUser(ar.getUserProfile());
    String remoteProjectLink = ar.baseURL +  "api/" + site.getKey() + "/" + ngp.getKey()
                    + "/summary.json?lic="+lfu.getId();

%>

<style>
.lvl-over {
    background-color: yellow;
}
.nicenice {
    border: 2px dashed #bbb;
    border-radius: 5px;
    padding: 25px;
    text-align: center;
    font: 20pt bold Georgia,Tahoma,sans-serif;
    color: #bbb;
    margin-bottom: 20px;
    width:500px;
}
div[dropzone] {
    border: 2px dashed #bbb;
    border-radius: 5px;
    padding: 25px;
    text-align: center;
    font: 20pt bold;
    color: #bbb;
    margin-bottom: 20px;
}
</style>



<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http) {
    window.setMainPageTitle("Upload Revised Document");
    window.MY_SCOPE = $scope;
    $scope.siteInfo = <%site.getConfigJSON().write(out,2,4);%>;
    $scope.docInfo = <% docInfo.write(ar.w, 2,4); %>;
    $scope.fileProgress = [];

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };
    $scope.cancelUpload = function(oneProgress) {
        oneProgress.done = true;
        oneProgress.status = "Cancelled";
    }
    $scope.startUpload = function(oneProgress) {
        oneProgress.status = "Starting";
        var postURL = "<%=remoteProjectLink%>";
        var postdata = '{"operation": "tempFile"}';
        $scope.showError=false;
        $http.post(postURL, postdata)
        .success( function(data) {
            oneProgress.tempFileName = data.tempFileName;
            oneProgress.tempFileURL = data.tempFileURL;
            $scope.actualUpload(oneProgress);
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };
    $scope.actualUpload = function(oneProgress) {
        oneProgress.status = "Uploading";
        var postURL = "<%=remoteProjectLink%>";
        $http.put(oneProgress.tempFileURL, oneProgress.file)
        .success( function(data) {
            $scope.nameUploadedFile(oneProgress);
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };
    $scope.nameUploadedFile = function(oneProgress) {
        oneProgress.status = "Finishing";
        var postURL = "<%=remoteProjectLink%>";
        var op = {operation: "updateDoc"};
        op.tempFileName = oneProgress.tempFileName;
        op.doc = {};
        op.doc.description = $scope.docInfo.description;
        op.doc.name        = $scope.docInfo.name;
        op.doc.id          = $scope.docInfo.id;
        op.doc.universalid = $scope.docInfo.universalid;
        var postdata = JSON.stringify(op);
        $http.post(postURL, postdata)
        .success( function(data) {
            oneProgress.status = "DONE";
            oneProgress.done = true;
            oneProgress.doc = data;
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };
});
</script>

<div ng-app="myApp" ng-controller="myCtrl" id="myDomElement">

<%@include file="ErrorPanel.jsp"%>

    <div class="upRightOptions rightDivContent">
      <span class="dropdown">
        <button class="btn btn-default btn-raised dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
        Options: <span class="caret"></span></button>
        <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
          <li role="presentation"><a role="menuitem" tabindex="-1"
              href="docsUpload.htm" >Clear</a></li>
          <li role="presentation"><a role="menuitem" tabindex="-1"
              href="listAttachments.htm" >List Document</a></li>
        </ul>
      </span>
    </div>

    <div id="TheNewDocument">
        <div>
            <table>
                <tr>
                    <td class="gridTableColummHeader">Attachment:</td>
                    <td style="width:20px;"></td>
                    <td>
                        {{docInfo.name}}
                    </td>
                </tr>
                <tr><td style="height:10px"></td></tr>
                <tr>
                    <td class="gridTableColummHeader">Drop Here:</td>
                    <td style="width:20px;"></td>
                    <td>
                        <div id="holder" class="nicenice">Drop "{{docInfo.name}}" File Here</div>
                    </td>
                </tr>
                <tr><td style="height:10px"></td></tr>
                <tr>
                    <td class="gridTableColummHeader"></td>
                    <td style="width:20px;"></td>
                    <td>
                        <div ng-repeat="fp in fileProgress" class="well">
                          <div >
                              <div style="float:left;">{{fp.file.name}}</div>

                              <div style="float:right;">{{fp.file.size}} bytes
                              {{fp.status}}</div>
                              <div style="clear:both;"></div>
                          </div>
                          <div ng-show="fp.file.name!=docInfo.name">
                              <span style="color:red;">Uploading as </span><b>{{docInfo.name}}</b>
                          </div>
                          <div ng-hide="fp.done">
                             Description:<br/>
                             <textarea ng-model="docInfo.description" class="form-control"></textarea>
                          </div>
                          <div ng-hide="fp.done">
                              <button ng-click="startUpload(fp)" class="btn btn-primary btn-raised">Upload</button>
                              <button ng-click="cancelUpload(fp)" class="btn btn-primary btn-raised">Cancel</button>
                          </div>
                        </div>
                    </td>
                </tr>
            </table>
        </div>
    </div>



</div>
<script>
var holder = document.getElementById('holder');
holder.ondragenter = function (e) {
    e.preventDefault();
    this.className = 'nicenice lvl-over';
    return false;
};
holder.ondragleave = function () {
    this.className = 'nicenice';
    return false;
};
holder.ondragover = function (e) {
    e.preventDefault()
}
holder.ondrop = function (e) {
    e.preventDefault();

    var newFiles = e.dataTransfer.files;

    this.className = 'nicenice';
    var scope = window.MY_SCOPE;
    scope.fileName = newFiles[0].name;

    for (var i=0; i<newFiles.length; i++) {
        var newProgress = {};
        newProgress.file = newFiles[i];
        newProgress.status = "Preparing";
        newProgress.done = false;
        scope.fileProgress.push(newProgress);
    }
    scope.$apply();
};
</script>
