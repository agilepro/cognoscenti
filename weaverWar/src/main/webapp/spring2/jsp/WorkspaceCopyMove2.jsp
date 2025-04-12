<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/include.jsp"
%><%
    ar.assertLoggedIn("You need to Login to Upload a file.");
    Cognoscenti cog = ar.getCogInstance();
    String pageId = ar.reqParam("pageId");
    String from = ar.reqParam("from");
    String folderVal = ar.defParam("folder", null);
    List<String> folders = UtilityMethods.splitString(folderVal, '|');
    String siteId = ar.reqParam("siteId");
    NGWorkspace ngp = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    if (ngp.isFrozen()) {
        throw new Exception("Program Logic Error: WorkspaceMoveCopy1.jsp should never be invoked when the"
           +" workspace is frozen.   Please check the logic of the controller.");
    }

    NGPageIndex thisWS = null;
    NGPageIndex fromWS = null;
    for (NGPageIndex ngpis : cog.getNonDelWorkspacesInSite(siteId)) {
        if (ngpis.containerKey.equals(pageId)) {
            thisWS = ngpis;
            continue;
        }
        if (ngpis.containerKey.equals(from)) {
            fromWS = ngpis;
            continue;
        }
    }
    
    if (fromWS==null) {
        throw new Exception("Workspace Copy/Move page is not able to find a workspace with key="+from);
    }
    if (thisWS==null) {
        throw new Exception("Workspace Copy/Move page is not able to find a workspace with key="+pageId);
    }
    JSONObject thisWorkspace = thisWS.getJSON4List();
    JSONObject fromWorkspace = fromWS.getJSON4List();
    NGWorkspace fromWorkspaceObj = fromWS.getWorkspace();
    ar.setPageAccessLevels(fromWorkspaceObj);
    ar.assertAccessWorkspace("Must be a member of the workspace you want to copy or move from");

    JSONArray allLabels = ngp.getJSONLabels();
    
    JSONArray allAttachments = fromWorkspaceObj.getJSONAttachments(ar);
   
    JSONArray allActionItems = new JSONArray();
    for (GoalRecord goal : fromWorkspaceObj.getAllGoals()) {
        int state = goal.getState();
        if (state==GoalRecord.STATE_COMPLETE || state==GoalRecord.STATE_SKIPPED 
            || state==GoalRecord.STATE_DELETED) {
            continue;
        }
        allActionItems.put(goal.getJSON4Goal(fromWorkspaceObj));
    }
%>

<script>
var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal) {
    setUpLearningMethods($scope, $modal, $http);
    window.setMainPageTitle("Transfer Step 2");
    $scope.allLabels = <%allLabels.write(out,2,4);%>;
    $scope.fromWorkspace = <%fromWorkspace.write(out,2,4);%>;
    $scope.thisWorkspace = <%thisWorkspace.write(out,2,4);%>;
    $scope.allAttachments = <%allAttachments.write(out,2,4);%>;
    $scope.allActionItems = <%allActionItems.write(out,2,4);%>;
    
    

    $scope.findLabels = function() {
        var res = [];
        $scope.allLabels.map( function(item) {
            if ($scope.folderMap[item.name]) {
                res.push(item);
            }
        });
        return res;
    }
    
    $scope.selectWorkspace = function(ws) {
        var url = "WorkspaceCopyMove2.htm?from="+encodeURIComponent(ws.pageKey);
        location.href=url;
    }
    
    $scope.copyDoc = function(doc) {
        if (!confirm("Are you sure you want to copy document \n'"+doc.name+"'\n into this workspace?")) {
            return;
        }
        let postURL = "copyDocument.json";
        var postObj = {
            "from": $scope.fromWorkspace.comboKey,
            "id": doc.id
        }
        var postdata = angular.toJson(postObj);
        $http.post(postURL, postdata)
        .success( function(data) {
            console.log("SUCCESS");
            doc.hideThis = true;
        })
        .error( function(data, status, headers, config) {
            console.log("FAILURE", data);
            $scope.reportError(data);
        });
    }
    $scope.moveDoc = function(doc) {
        if (!confirm("Are you sure you want to permanently move document \n'"
                     +doc.name+"'\n into this workspace?")) {
            return;
        }
        let postURL = "moveDocument.json";
        var postObj = {
            "from": $scope.fromWorkspace.comboKey,
            "id": doc.id
        }
        var postdata = angular.toJson(postObj);
        $http.post(postURL, postdata)
        .success( function(data) {
            console.log("SUCCESS");
            doc.hideThis = true;
        })
        .error( function(data, status, headers, config) {
            console.log("FAILURE", data);
            $scope.reportError(data);
        });
    }
    $scope.moveActionItem = function(goal) {
        if (!confirm("Are you sure you want to permanently move action item \n'"
                     +goal.synopsis+"'\n into this workspace?")) {
            return;
        }
        let postURL = "moveActionItem.json";
        var postObj = {
            "from": $scope.fromWorkspace.comboKey,
            "id": goal.id
        }
        var postdata = angular.toJson(postObj);
        $http.post(postURL, postdata)
        .success( function(data) {
            console.log("SUCCESS");
            goal.hideThis = true;
        })
        .error( function(data, status, headers, config) {
            console.log("FAILURE", data);
            $scope.reportError(data);
        });
    }
    $scope.rowStyle = function(row) {
        if (row.hideThis) {
            return {"background-color":"black","color":"grey"};
        }
        return {"background-color":"white"};
    }
});
</script>

<div class="container-fluid override mb-4 mx-3 d-inline-flex">
    <span class="dropdown mt-1">
        <button class="btn btn-outline-secondary btn-tiny dropdown-toggle" type="button" id="dropdownInfoMenu"
            data-bs-toggle="dropdown" aria-expanded="false">
        </button>
        <ul class="dropdown-menu" aria-labelledby="dropdownInfoMenu">
            <li>
                <button class="dropdown-item" onclick="window.location.reload(true)">
                    Refresh</button>
            </li>
        </ul>
    </span>
    <span>
        <h1 class="d-inline page-name" id="mainPageTitle">Transfer Step 2</h1>
    </span>
</div>
<div ng-cloak>

<%@include file="ErrorPanel.jsp"%>

    <div class="generalHeading" style="height:40px">
        <div class="container-fluid col-12 p-3 m-3">
            <h3>
            Move or Copy Documents, Discussions, and Action Item</h3>

            <div class="container-fluid col-12 p-3">
                <h4 class=" m-3">{{fromWorkspace.name}} <i class="fa fa-arrow-circle-o-right"></i> {{thisWorkspace.name}}</h4>
    <h5 class="mx-4">Select Artifacts to copy or move:</h5>
    
    <hr>
    <h4>Documents:</h4>
    <div class="container-fluid">
    <div class="row border-2 border-bottom">
       <span class="col-4 h5">Document Name</span>
       <span class="col-4 h5">Modified</span>
       <span class="col-2 h5">Size</span>
       <span class="col-2 h5"></span>
    </div>
    <div class="row border-1 border-bottom" ng-repeat="doc in allAttachments" ng-style="rowStyle(doc)">
       <span class="col-4">{{doc.name}}</span>
       <span class="col-4">{{doc.modifiedtime|cdate}}</span>
       <span class="col-2" ng-show="doc.size>=0">{{doc.size|number}} bytes</span>
       <span class="col-2" ng-hide="doc.size>=0">Web URL</span>
       <span class="col-2" ng-hide="doc.hideThis">
           <button class="btn btn-comment btn-wide btn-raised" ng-click="copyDoc(doc)">Copy</button>
           <button class="btn btn-comment btn-wide btn-raised" ng-click="moveDoc(doc)">Move</button>
       </span>
       <span class="col-2" ng-show="doc.hideThis">
           
       </span>
    </div>
    <div class="row">
        <span class="col-3 linkWizardHeading"></span>
    </div>
    </div>
    
    <h4>Action Items</h4>
    <div class="container-fluid">
        <div class="row border-2 border-bottom">
            <span class="col-4 h5">Synopsis</span>
            <span class="col-2 h5"></span>
        </div>

    <div class="row border-1 border-bottom" ng-repeat="goal in allActionItems" ng-style="rowStyle(goal)">
        <span class="col-10">{{goal.synopsis}}</span>
       <span class="col-2" ng-hide="goal.hideThis">
           <button class="btn btn-wide btn-comment btn-raised" ng-click="moveActionItem(goal)">Move</button>
       </span>
       <span class="col-2 h5" ng-show="goal.hideThis">
           
       </span>
    </div>
    <div class="row">
        <td class="l col-3 inkWizardHeading"></td>
    </div>
    </div>
</div>
</div>
<!-- end addDocument.jsp -->
