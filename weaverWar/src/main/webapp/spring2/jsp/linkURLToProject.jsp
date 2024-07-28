<%@page errorPage="/spring2/jsp/error.jsp"
%><%@ include file="/spring2/jsp/include.jsp"
%><%

    ar.assertLoggedIn("You need to Login to Upload a file.");
    String folderVal = ar.defParam("folder", null);
    List<String> folders = UtilityMethods.splitString(folderVal, '|');
    String pageId = ar.reqParam("pageId");
    String siteId = ar.reqParam("siteId");
    NGWorkspace ngp = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    if (ngp.isFrozen()) {
        throw new Exception("Program Logic Error: addDocument.jsp should never be invoked when the workspace is frozen.  "
           +"Please check the logic of the controller.");
    }
    
    NGBook site = ngp.getSite();
    String folderPart = "";
    if (folderVal!=null) {
        folderPart = "?folder="+URLEncoder.encode(folderVal, "UTF-8");
    }
    JSONObject folderMap = new JSONObject();
    for (String folder: folders) {
        folderMap.put( folder, true);
    }

    JSONArray allLabels = ngp.getJSONLabels();

%>

<script>
var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal) {
    setUpLearningMethods($scope, $modal, $http);
    window.setMainPageTitle("Link URL");
    $scope.allLabels = <%allLabels.write(out,2,4);%>;
    $scope.folderMap = <%folderMap.write(out,2,4);%>;
    $scope.siteInfo = <%site.getConfigJSON().write(out,2,4);%>;
    $scope.newLink = {
        id: "~new~",
        labelMap:{},
        attType:"URL"
    };

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };

    $scope.assignedLabels = function() {
        var res = [];
        $scope.allLabels.forEach( function(item) {
            if ($scope.newLink.labelMap[item.name]) {
                res.push(item);
            }
        });
        return res;
    }
    $scope.hasLabel = function(searchName) {
        return $scope.newLink.labelMap[searchName];
    }
    $scope.toggleLabel = function(label) {
        $scope.newLink.labelMap[label.name] = !$scope.newLink.labelMap[label.name];
    }

    $scope.createLink = function() {
        var postURL = "docsUpdate.json?did="+$scope.newLink.id;
        var postdata = angular.toJson($scope.newLink);
        $scope.showError=false;
        $http.post(postURL, postdata)
        .success( function(data) {
            $scope.newLink = data;
            window.location = "DocsList.htm";

        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };

    $scope.suggestName = function() {
        var url = $scope.newLink.url;
        if (!url || url.length==0) {
            return;
        }
        if ($scope.newLink.name && $scope.newLink.name.length>0) {
            return;
        }
        var pos = url.lastIndexOf("/");
        if (pos>0) {
            url = url.substring(pos+1);
        }
        $scope.newLink.name = url;
    }
    

    initializeLabelPicker($scope, $http, $modal); 
    
});
</script>


<div ng-cloak>

<%@include file="ErrorPanel.jsp"%>

<div class="container-fluid mx-3">
    <div class="contentColumn" >
        <div class="row form-group d-flex my-2">
            <span class="col-1 h6" >Type:</span>
            <span class="col-10" >
                <img src="<%=ar.retPath%>assets/images/iconUrl.png" > URL</span>
        </div>
        <div class="row form-group d-flex my-2">
            <span class="col-1 h6" >URL:</span>
            <span class="col-10" >
                <input type="text" ng-model="newLink.url" ng-blur="suggestName()" class="form-control" />
            </span>
        </div>
        <div class="col-11 d-grid d-flex my-2 justify-content-end">
            <a href="CleanAtt.htm?path={{newLink.url}}" target="_blank">
            <button class="btn btn-comment btn-secondary btn-wide me-2">View as a Text Only page</button></a>
        </div>
        <div class="row form-group d-flex my-2">
            <span class="col-1 h6" >Name:</span>
            <span class="col-10" >
                <input type="text" ng-model="newLink.name" class="form-control" />
            </span>
        </div>
        <div class="row form-group d-flex my-2">
            <span class="col-1 h6" >Description:</span>
            <span class="col-10" >
                <textarea ng-model="newLink.description"  rows="4" class="form-control"></textarea>
            </span>
        </div>
        <div class="row form-group d-flex my-2">
            <span class="col-1 h6" >Labels:</span>
            <span class="col-10" >
                <%@ include file="/spring2/jsp/LabelPicker.jsp" %>
            </span>
        </div>
        <div class="col-11 d-grid d-flex my-2 justify-content-end">
            <button class="btn btn-primary btn-raised btn-default me-2" ng-click="createLink()">Attach Web URL</button>
        </div>
    </div>
</div>


</div>

