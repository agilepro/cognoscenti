<%@page errorPage="/spring2/jsp/error.jsp"
%><%@ include file="/spring2/jsp/include.jsp"
%><%@page import="com.purplehillsbooks.weaver.NGLabel"
%><%@page import="com.purplehillsbooks.weaver.LabelRecord"
%><%


    ar.assertLoggedIn("You need to Login to manipulate labels.");
    Cognoscenti cog = ar.getCogInstance();
    String pageId = ar.reqParam("pageId");
    String siteId = ar.reqParam("siteId");
    NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngw);
    ar.assertAccessWorkspace("Must be a member to see meetings");
    NGBook site = ngw.getSite();

    JSONArray labelList = new JSONArray();
    for (NGLabel label : ngw.getAllLabels()) {
        if (label instanceof LabelRecord) {
            labelList.put(label.getJSON());
        }
    }
    
    String templateCacheDefeater = "";
    if ("true".equals(ar.getSystemProperty("forceTemplateRefresh"))) {
        templateCacheDefeater = "?t="+System.currentTimeMillis();
    }
    
    JSONArray allWorkspaces = new JSONArray();
    JSONObject thisWorkspace = null;
    for (NGPageIndex ngpis : cog.getNonDelWorkspacesInSite(siteId)) {
        if (ngpis.isDeleted) {
            continue;
        }
        if (ngpis.containerKey.equals(pageId)) {
            thisWorkspace = ngpis.getJSON4List();
            continue;
        }
        allWorkspaces.put(ngpis.getJSON4List());
    }
    

%>


<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal) {
    setUpLearningMethods($scope, $modal, $http);
    window.setMainPageTitle("Labels");
    $scope.siteInfo = <%site.getConfigJSON().write(out,2,4);%>;
    $scope.allWorkspaces = <%allWorkspaces.write(out,2,4);%>;
    $scope.thisWorkspace = <%thisWorkspace.write(out,2,4);%>;
    $scope.selectedWS = {};
    $scope.newLabelsCreated = [];

    
    $scope.openEditLabelsModal = function (item) {
        
        var attachModalInstance = $modal.open({
            animation: true,
            templateUrl: '<%=ar.retPath%>new_assets/templates/EditLabels.html<%=templateCacheDefeater%>',
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
            //not sure what to do here
        }, function () {
            //cancel action - nothing really to do
        });
    };

    $scope.selectWorkspace = function(ws) {
        $scope.selectedWS = ws;
        $scope.newLabelsCreated = [];
        console.log("SELECTED", ws);
    }
    $scope.cancelCopy = function() {
        $scope.selectedWS = {};
        console.log("SELECTED", "none");
    }
    $scope.copyLabels = function() {
        let postURL = "copyLabels.json";
        var postObj = {
            "from": $scope.selectedWS.comboKey,
        }
        var postdata = angular.toJson(postObj);
        $http.post(postURL, postdata)
        .success( function(data) {
            $scope.newLabelsCreated = data.list;
            console.log("SUCCESS");
        })
        .error( function(data, status, headers, config) {
            console.log("FAILURE", data);
            $scope.reportError(data);
        });
        $scope.selectedWS = {};        
    }

});

</script>

<!-- MAIN CONTENT SECTION START -->
<div ng-cloak>

<%@include file="ErrorPanel.jsp"%>



        <div class="container-fluid">
            <div class="row">
                <div class="col-md-auto fixed-width border-end border-1 border-secondary">
                    <span class="btn btn-raised btn-comment btn-secondary m-3 pb-2 pt-0" type="button" ng-click="openEditLabelsModal()"  aria-labelledby="createNewLabels">
                        <a class="nav-link">Create or Delete Labels</a>
                    </span>
                    
    </div>
    
    <div class="d-flex col-9"><div class="contentColumn">
    <h2 class="text-secondary fs-3">Copy Labels from another Workspace</h2>
    <div class="row col-12">
    <div class="bg-weaver-white p-2" ng-hide="selectedWS.name">
        <div class="ms-3 fs-4 fw-bold ">
            From:
        </div>
        <span class="p-3">
            <button class="btn btn-wide btn-flex btn-outline-secondary btn-raised shadow-sm mx-2 my-0" ng-repeat="ws in allWorkspaces" ng-click="selectWorkspace(ws)">{{ws.name}}</button>
        </span>
    
    <span class="p-2" ng-show="selectedWS.name">
        <span class="p-2">
            Confirm:
        </span>
        <span class="p-2">
            <button ng-click="copyLabels()" class="btn btn-small btn-warning btn-raised">Add all labels from --{{selectedWS.name}}-- to this workspace.</button>
            <button ng-click="cancelCopy()" class="btn btn-small btn-default btn-raised">Cancel</button>
        </span>
    </span>
    <span class="p-2" ng-show="newLabelsCreated.length>0">
        <span class="p-2">
            Created:
        </span>
        <span class="p-2">
            <div ng-repeat="lab in newLabelsCreated">
            <button style="background-color:{{lab.color}};" class="labelButton">{{lab.name}}</button>
            </div>
        </span>
    </span>
    </div>
</div>  
    </div>    
</div>


<script src="<%=ar.baseURL%>new_assets/templates/EditLabelsCtrl.js"></script>