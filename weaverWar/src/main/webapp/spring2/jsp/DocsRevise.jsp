<%@page errorPage="/spring2/jsp/error.jsp"
%><%@ include file="/include.jsp"
%><%@page import="com.purplehillsbooks.weaver.LicenseForUser"
%><%@page import="com.purplehillsbooks.weaver.AttachmentVersion"
%><%@ include file="/functions.jsp"
%><%


    String aid         = ar.reqParam("aid");    
    String pageId = ar.reqParam("pageId");
    String siteId = ar.reqParam("siteId");
    NGWorkspace ngp = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngp);
    ar.assertAccessWorkspace("Must be a member to upload documents");
    NGBook site = ngp.getSite();
    boolean canUpdate = ar.canUpdateWorkspace();

    AttachmentRecord attachRec = ngp.findAttachmentByIDOrFail(aid);
    JSONObject docInfo = attachRec.getJSON4Doc(ar, ngp);

    LicenseForUser lfu = new LicenseForUser(ar.getUserProfile());
    String remoteProjectLink = ar.baseURL +  "api/" + site.getKey() + "/" + ngp.getKey()
                    + "/summary.json?lic="+lfu.getId();
    List<AttachmentVersion>  versionList = attachRec.getVersions(ngp);
    JSONArray allVersions = new JSONArray();
    for(AttachmentVersion aVer : versionList){
        allVersions.put(aVer.getJSON());
    }
    List<HistoryRecord> histRecs = ngp.getHistoryForResource(HistoryRecord.CONTEXT_TYPE_DOCUMENT,aid);
    JSONArray allHistory = new JSONArray();
    for (HistoryRecord hist : histRecs) {
        JSONObject jo = hist.getJSON(ngp, ar);
        AddressListEntry ale = AddressListEntry.findOrCreate(hist.getResponsible());
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
    String templateCacheDefeater = "";
    if ("true".equals(ar.getSystemProperty("forceTemplateRefresh"))) {
        templateCacheDefeater = "?t="+System.currentTimeMillis();
    }

%>





<script src="../../../jscript/AllPeople.js"></script>
<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal, AllPeople) {
    setUpLearningMethods($scope, $modal, $http);
    window.setMainPageTitle("Document Versions");
    window.MY_SCOPE = $scope;
    $scope.siteInfo = <%site.getConfigJSON().write(out,2,4);%>;
    $scope.attachInfo = <% docInfo.write(ar.w, 2,4); %>;
    $scope.allVersions = <%allVersions.write(out,2,4);%>;
    $scope.history = <%allHistory.write(out,2,4);%>;
    $scope.fileProgress = [];
    $scope.docId = "<%ar.writeHtml(aid);%>";
    $scope.canUpdate = <%=canUpdate%>;

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
        op.doc.description = $scope.attachInfo.description;
        op.doc.name        = $scope.attachInfo.name;
        op.doc.id          = $scope.attachInfo.id;
        op.doc.universalid = $scope.attachInfo.universalid;
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
    $scope.getDocumentInfo = function() {
        if (!$scope.canAccess) {
            //avoid generating error if the user does not have access
            return;
        }
        $scope.isUpdating = true;
        var postURL = "docInfo.json?did="+$scope.docId;
        $http.get(postURL)
        .success( function(data) {
            $scope.setDocumentData(data);
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    }
    $scope.getDocumentInfo();
    $scope.openDocDialog = function (doc) {
        if (!$scope.canUpdate) {
            alert("Unable to update document because you are not playing an update role in this workspace.");
            return;
        }
        var docsDialogInstance = $modal.open({
            animation: true,
            templateUrl: "<%= ar.retPath%>new_assets/templates/DocumentDetail2.html<%=templateCacheDefeater%>",
            controller: 'DocumentDetailsCtrl',
            size: 'lg',
            backdrop: "static",
            resolve: {
                docId: function () {
                    return doc.id;
                },
                allLabels: function() {
                    return $scope.allLabels;
                },
                siteInfo: function() {
                    return $scope.siteInfo;
                },
                wsUrl: function() {
                    return $scope.wsUrl;
                }
            }
        });

        docsDialogInstance.result
        .then(function () {
            $scope.getDocumentList();
        }, function () {
            $scope.getDocumentList();
            //cancel action - nothing really to do
        });
    };    
    $scope.navigateToCreator = function(player) {
        window.location="<%=ar.retPath%>v/"+encodeURIComponent(player.key)+"/PersonShow.htm";
    }
});
</script>
<script src="../../../jscript/AllPeople.js"></script>

<div class="container-fluid override mb-4 mx-3 d-inline-flex">
    <span class="dropdown mt-1">
        <button class="btn btn-outline-secondary btn-tiny dropdown-toggle" type="button" id="dropdownInfoMenu"
            data-bs-toggle="dropdown" aria-expanded="false">
        </button>
        <ul class="dropdown-menu" aria-labelledby="dropdownInfoMenu">
            <li>
                <button class="dropdown-item" onclick="window.location.reload(true)">
                    Refresh</button>
                <span class="dropdown-item" type="button">
                    <a class="nav-link" role="menuitem" tabindex="-1" href="DocDetail.htm?aid={{docId}}">
                        Document Access</a></span>
                <span class="dropdown-item" type="button">
                    <a class="nav-link" role="menuitem" tabindex="-1" href="DocsList.htm">
                        List View</a></span>
            </li>
        </ul>
    </span>
    <span>
        <h1 class="d-inline page-name" id="mainPageTitle">Document - Versions</h1>
    </span>
</div>

<div ng-cloak>

<%@include file="ErrorPanel.jsp"%>

<div class="container-fluid override mx-3">
    
        <div class="d-flex col-12">
            <div class="container-fluid">
                <div class="generalContent">
                    <div id="TheNewDocument" class="well col-lg-6 col-md-12" ng-show="canUpdate">
                        <div>
            <table>
                <tr>
                    <td></td>
                    <td style="width:20px;"></td>
                    <td style="width:600px;">
                        Create a new version of {{attachInfo.name}}:
                    </td>
                </tr>
                <tr><td style="height:10px"></td></tr>
                <tr>
                    <td class="gridTableColummHeader">Drop Here:</td>
                    <td style="width:20px;"></td>
                    <td style="width:600px;">
                        <div id="holder" class="nicenice">Drop Revised File Here</div>
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
                          <div ng-show="fp.file.name!=attachInfo.name">
                              <span style="color:red;">Uploading as </span><b>{{attachInfo.name}}</b>
                          </div>
                          <div ng-hide="fp.done">
                             Description:<br/>
                             <textarea ng-model="attachInfo.description" class="form-control"></textarea>
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


                    <table class="table">
        <thead>
            <tr>
                <td>Version</td>
                <td>Name</td>
                <td>Modified Date</td>
                <td>File Size</td>
            </tr>
        </thead>
        <tbody>
            <tr ng-repeat="ver in allVersions">
                <td>{{ver.num}}</td>
                <td>
                    <a href="{{ver.link}}" title="Access the content of this version of the attachment">
                    {{attachInfo.name}}
                    <span ng-show="ver.modified">(Modified)</span>
                    </a>
                </td>
                <td>{{ver.date | cdate}}</td>
                <td>{{ver.size | number}}</td>
            </tr>
        </tbody>
                    </table>
    
                    <h3>History</h3>
                    <table>

        <tr ng-repeat="hist in history"  >
            <td class="projectStreamIcons" style="padding:10px;">
              <span class="dropdown" >
                <span id="menu1" data-toggle="dropdown">
                <img class="rounded-5" 
                     ng-src="<%=ar.retPath%>icon/{{hist.responsible.uid}}.jpg" 
                     style="width:32px;height:32px" 
                     title="{{hist.responsible.name}} - {{hist.responsible.uid}}">
                </span>
                <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
                  <li role="presentation" style="background-color:lightgrey"><a role="menuitem" 
                      tabindex="-1" style="text-decoration: none;text-align:center">
                      {{hist.responsible.name}}<br/>{{hist.responsible.uid}}</a></li>
                  <li role="presentation" style="cursor:pointer"><a role="menuitem" tabindex="-1"
                      ng-click="navigateToCreator(hist.responsible)">
                      <span class="fa fa-user"></span> Visit Profile</a></li>
                </ul>
              </span>
            </td>
            <td class="projectStreamText" style="padding:10px;">
                {{hist.time|cdate}} -
                <a href="<%=ar.retPath%>{{hist.respUrl}}"><span class="red">{{hist.respName}}</span></a>
                <br/>
                {{hist.ctxType}} "<b>{{hist.ctxName}}</b>"
                was {{hist.event}}.
                <br/>
                <i>{{hist.comments}}</i>

            </td>
        </tr>

                    </table>
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
<!--have to make room for menu on bottom line-->
<div style="height:300px"></div>

<script src="<%=ar.retPath%>templates/DocumentDetail2.js"></script>


