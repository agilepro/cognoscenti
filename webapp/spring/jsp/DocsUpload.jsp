<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="org.socialbiz.cog.LicenseForUser"
%><%@ include file="functions.jsp"
%><%


    String pageId = ar.reqParam("pageId");
    String siteId = ar.reqParam("siteId");
    NGWorkspace ngp = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngp);
    ar.assertMember("Must be a member to upload documents");
    NGBook ngb = ngp.getSite();
    NGBook site = ngp.getSite();

    LicenseForUser lfu = new LicenseForUser(ar.getUserProfile());
    String remoteProjectLink = ar.baseURL +  "api/" + site.getKey() + "/" + ngp.getKey()
                    + "/summary.json?lic="+lfu.getId();

    JSONArray allLabels = ngp.getJSONLabels();

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
.spacey {
    width:100%;
}
.spacey tr td {
    padding:3px;
}
.firstcol {
    width:130px;
}
</style>



<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http) {
    window.setMainPageTitle("Upload Documents");
    window.MY_SCOPE = $scope;
    $scope.allLabels = <%allLabels.write(out,2,4);%>;
    $scope.docInfo = {description: ""};
    $scope.fileProgress = [];
    $scope.browsedFile = null;
    $scope.filterMap = {};

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
        oneProgress.loaded = 0;
        oneProgress.percent = 0;
        oneProgress.labelMap = $scope.filterMap;
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

        var xhr = new XMLHttpRequest();
        xhr.upload.addEventListener("progress", function(e){
          $scope.$apply( function(){
            if(e.lengthComputable){
              oneProgress.loaded = e.loaded;
              oneProgress.percent = Math.round(e.loaded * 100 / e.total);
              console.log("progress event: "+oneProgress.loaded+" / "+e.total+"  ==  "+oneProgress.percent+"   "+oneProgress.status);
            } else {
              oneProgress.percent = 50;
            }
          });
        }, false);
        xhr.upload.addEventListener("load", function(data) {
            $scope.nameUploadedFile(oneProgress);
        }, false);
        xhr.upload.addEventListener("error", $scope.reportError, false);
        xhr.upload.addEventListener("abort", $scope.reportError, false);
        xhr.open("PUT", oneProgress.tempFileURL);
        xhr.send(oneProgress.file);
    };
    $scope.nameUploadedFile = function(oneProgress) {
        oneProgress.status = "Finishing";
        var postURL = "<%=remoteProjectLink%>";
        var op = {operation: "newDoc"};
        op.tempFileName = oneProgress.tempFileName;
        op.doc = {};
        op.doc.description = oneProgress.description;
        op.doc.name = oneProgress.file.name;
        op.doc.labelMap = oneProgress.labelMap;
        var postdata = JSON.stringify(op);
        $http.post(postURL, postdata)
        .success( function(data) {
            if (data.exception) {
                $scope.reportError(data);
                return;
            }
            oneProgress.status = "DONE";
            oneProgress.done = true;
            oneProgress.doc = data;
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };

    $scope.$watch('browsedFile', function() {
       if ($scope.browsedFile) {
           alert('hey, browsedFile has changed!');
       }
    });

    $scope.hasLabel = function(searchName) {
        return $scope.filterMap[searchName];
    }
    $scope.toggleLabel = function(label) {
        $scope.filterMap[label.name] = !$scope.filterMap[label.name];
        $scope.showFilter=true;
    }
    $scope.allLabelFilters = function() {
        var res = [];
        $scope.allLabels.map( function(val) {
            if ($scope.filterMap[val.name]) {
                res.push(val);
            }
        });
        return res;
    }

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

    <table class="spacey">
        <tr>
            <td class="firstColumn">Drop Here:</td>
            <td>
                <div id="holder" class="nicenice">Drop Files Here</div>
            </td>
        </tr>
        <tr>
            <td class="firstColumn">Labels:</td>
            <td>
                <span class="dropdown" ng-repeat="role in allLabelFilters()">
                    <button class="labelButton" 
                       type="button" id="menu2"
                       data-toggle="dropdown" 
                       style="background-color:{{role.color}};"
                       ng-show="hasLabel(role.name)">
                       {{role.name}} <i class="fa fa-close"></i></button>
                    <ul class="dropdown-menu" role="menu" aria-labelledby="menu2">
                       <li role="presentation"><a role="menuitem" title="{{add}}"
                          ng-click="toggleLabel(role)" style="border:2px {{role.color}} solid;">
                          Remove Label:<br/>{{role.name}}</a></li>
                    </ul>
                </span>
                <span class="dropdown">
                    <button class="btn btn-sm btn-primary btn-raised labelButton" 
                       type="button" 
                       id="menu1" 
                       data-toggle="dropdown"
                       title="Add Label BEFORE you upload the file"
                       style="padding:5px 10px">
                       <i class="fa fa-plus"></i></button>
                    <ul class="dropdown-menu" role="menu" aria-labelledby="menu1" 
                        style="width:320px;left:-130px">
                         <li role="presentation" ng-repeat="rolex in allLabels" style="float:left">
                             <button role="menuitem" tabindex="-1" ng-click="toggleLabel(rolex)" class="labelButton" 
                             ng-hide="hasLabel(rolex.name)" style="background-color:{{rolex.color}}">
                                 {{rolex.name}}</button>
                         </li>
                    </ul>
                </span>
                <span style="color:lightgray"> ( before you upload )</span>
            </td>
        </tr>
        <tr>
            <td class="gridTableColummHeader"></td>
            <td>
                <div ng-repeat="fp in fileProgress" class="well">
                  <div >
                      <div style="float:left;"><b>{{fp.file.name}}</b></div>

                      <div style="float:right;">{{fp.status}}</div>
                      <div style="clear:both;"></div>
                  </div>
                  <div ng-hide="fp.done">
                     Description:<br/>
                     <textarea ng-model="fp.description" class="form-control"></textarea>
                  </div>
                  <div style="padding:5px;">
                      <div style="text-align:center">{{fp.status}}:  {{fp.loaded|number}} of {{fp.file.size|number}} bytes</div>
                      <div class="progress">
                          <div class="progress-bar progress-bar-success" role="progressbar"
                               aria-valuenow="50" aria-valuemin="0" aria-valuemax="100"
                               style="width:{{fp.percent}}%">
                          </div>
                      </div>
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
    if (!newFiles) {
        alert("Oh.  It looks like you are using a browser that does not support the dropping of files.  Currently we have no other solution than using Mozilla or Chrome or the latest IE for uploading files.");
        return;
    }
    console.log("Got newFiles", newFiles);
    if (newFiles.length==0) {
        console.log("Strange, got a drop, but no files included");
    }

    this.className = 'nicenice';
    var scope = window.MY_SCOPE;
    //scope.fileName = newFiles[0].name;

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
