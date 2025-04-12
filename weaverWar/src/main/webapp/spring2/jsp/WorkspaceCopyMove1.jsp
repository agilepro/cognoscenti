<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/include.jsp"
%><%
    ar.assertLoggedIn("You need to Login to Upload a file.");
    Cognoscenti cog = ar.getCogInstance();
    String pageId = ar.reqParam("pageId");
    String folderVal = ar.defParam("folder", null);
    List<String> folders = UtilityMethods.splitString(folderVal, '|');
    String siteId = ar.reqParam("siteId");
    NGWorkspace ngp = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    if (ngp.isFrozen()) {
        throw new Exception("Program Logic Error: WorkspaceMoveCopy1.jsp should never be invoked when the"
           +" workspace is frozen.   Please check the logic of the controller.");
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

    JSONArray allLabels = ngp.getJSONLabels();
%>

<script>
var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal) {
    setUpLearningMethods($scope, $modal, $http);
    window.setMainPageTitle("Transfer Step 1");
    $scope.allLabels = <%allLabels.write(out,2,4);%>;
    $scope.allWorkspaces = <%allWorkspaces.write(out,2,4);%>;
    $scope.thisWorkspace = <%thisWorkspace.write(out,2,4);%>;
    

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
        <h1 class="d-inline page-name" id="mainPageTitle">Transfer Step 1</h1>
    </span>
</div>
<div ng-cloak>

<%@include file="ErrorPanel.jsp"%>

    <div class="generalHeading" style="height:40px">
        <div class="container-fluid col-12 p-3">
            <span class="h4">
            Move or Copy Documents Discussions and Action Item</span>
        


    <div class="row d-flex">
        <label for="toto" class=" col-auto h5 m-3">To copy/transfer to this workspace:</label>
        <span class="col-auto h5 m-3 text-secondary border border-2 rounded-2 px-2 pb-1" id="toto" aria-describedby="emailHelp" placeholder="Name of the current workspace">
            {{thisWorkspace.name}}</span>
    </div>
    
     <div class="row d-flex">
        <label for="fromfrom" class="col-auto h5 m-3">Select the workspace you want to copy from:</label>
        <div class="container-fluid mx-3" id="fromfrom" aria-describedby="emailHelp" placeholder="Name of the current workspace">
             <button ng-repeat="ws in allWorkspaces" ng-click="selectWorkspace(ws)" class="btn btn-wide btn-comment btn-raised">{{ws.name}}</button></div>
    </div>
   
 </div></div>
    </div>
<!-- end addDocument.jsp -->
