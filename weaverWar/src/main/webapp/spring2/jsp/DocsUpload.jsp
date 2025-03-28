<%@page errorPage="/spring2/jsp/error.jsp"
%><%@ include file="/include.jsp"
%><%@page import="com.purplehillsbooks.weaver.LicenseForUser"
%><%@ include file="/functions.jsp"
%><%


    String pageId = ar.reqParam("pageId");
    String siteId = ar.reqParam("siteId");
    NGWorkspace ngp = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngp);
    ar.assertAccessWorkspace("Must be a member to upload documents");
    NGBook ngb = ngp.getSite();
    NGBook site = ngp.getSite();

    LicenseForUser lfu = new LicenseForUser(ar.getUserProfile());
    String remoteProjectLink = ar.baseURL +  "api/" + site.getKey() + "/" + ngp.getKey()
                    + "/summary.json?lic="+lfu.getId();

    JSONArray allLabels = ngp.getJSONLabels();

%>





<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal) {
    setUpLearningMethods($scope, $modal, $http);
    window.setMainPageTitle("Upload Documents");
    window.MY_SCOPE = $scope;
    $scope.allLabels = <%allLabels.write(out,2,4);%>;
    $scope.siteInfo = <%site.getConfigJSON().write(out,2,4);%>;
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
        op.doc.size = oneProgress.file.size;
        op.doc.labelMap = oneProgress.labelMap;
        var postdata = JSON.stringify(op);
        $http.post(postURL, postdata)
        .success( function(data) {
            if (data.exception || data.error) {
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
    

    initializeLabelPicker($scope, $http, $modal);    
    $scope.getAllLabels();
    $scope.openEditLabelsModal = function (item) {
        
        var attachModalInstance = $modal.open({
            animation: true,
            templateUrl: '../../../new_assets/templates/EditLabels.html',
            controller: 'EditLabelsCtrl',
            size: 'lg',
            resolve: {
                siteInfo: function () {
                  return $scope.siteInfo;
                },
            }
        });

        attachModalInstance.result
        .then(function (selectedActionItems) {
            $scope.getAllLabels();
        }, function () {
            $scope.getAllLabels();
        });
    };

    $scope.getContrastColor = function (color) {

        const tempEl = document.createElement("div");
        tempEl.style.color = color;
        document.body.appendChild(tempEl);
        const computedColor = window.getComputedStyle(tempEl).color;
        document.body.removeChild(tempEl);

        const match = computedColor.match(/\d+/g);

        if (!match) {
            console.error("Failed to parse color: ", computedColor);
            return "#39134C";
        }
        const [r, g, b] = match.map(Number);

        var yiq = ((r * 299) + (g * 587) + (b * 114)) / 1000;

        return (yiq >= 128) ? '#39134C' : '#ebe7ed';
    };

});
</script>

<div ng-cloak>

<%@include file="ErrorPanel.jsp"%>

<div class="container-fluid  override">
    <div class="row px-4">
        <div class="col-md-auto second-menu"><span class="h5"> Additional Actions</span>
        <div class="col-md-auto second-menu">
            <button class="specCaretBtn m-2" type="button" data-bs-toggle="collapse" data-bs-target="#collapseSecondaryMenu" aria-expanded="false" aria-controls="collapseSecondaryMenu">
                <i class="fa fa-arrow-down"></i>
            </button>
            <div class="collapse" id="collapseSecondaryMenu">
                <div class="col-md-auto">

                    <span class="btn second-menu-btn btn-wide" type="button"><a role="menuitem" tabindex="-1" class="nav-link" href="DocsUpload.htm" >Clear</a></span>
        <span class="btn second-menu-btn btn-wide" type="button" aria-labelledby="docsList"><a role="menuitem" tabindex="-1" class="nav-link" href="DocsList.htm" >List Document</a></span>
        </div>
            </div>
        </div>
        <hr>
        <div class="col-12">
                <div class="form-group d-flex">
                    <label class="col-md-2 control-label h6">Drop Here:</label>
                    <div class="col-md-10">
                        <div id="holder" class="nicenice">Drop Files Here</div>
                    </div>
                </div>
                <div class="form-group d-flex">
                    <label class="col-md-2 control-label h6">Labels:</label>
                    <div class="col-md-10">
                        <%@ include file="/spring2/jsp/LabelPicker.jsp" %>
                    </div>
                </div>
                <div ng-repeat="fp in fileProgress" class="form-group d-flex">
                    <div class="well col-10">
                        <div class="row d-flex">
                          <span class="col-6"><b>{{fp.file.name}}</b></span>

                          <span class="col-4 h6">{{fp.status}}</span>
                        </div>

                        <div class="h6 my-2" ng-hide="fp.done">
                             Description:<br/><br/>
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
                            <button ng-click="startUpload(fp)" class="btn btn-primary btn-raised">
                                Upload</button>
                            <button ng-click="cancelUpload(fp)" class="btn btn-primary btn-raised">
                                Cancel</button>
                        </div>
                    </div>
                </div>
            </div>
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
    if (!newFiles) {
        alert("Oh.  It looks like you are using a browser that does not support the dropping of files.  Currently we have no other solution than using Mozilla or Chrome or the latest IE for uploading files.");
        return;
    }
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


<script src="<%=ar.baseURL%>new_assets/templates/EditLabelsCtrl.js"></script>