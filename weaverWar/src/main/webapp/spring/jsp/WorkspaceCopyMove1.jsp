<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
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
    for (NGPageIndex ngpis : cog.getAllWorkspacesInSite(siteId)) {
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
app.controller('myCtrl', function($scope, $http) {
    window.setMainPageTitle("Transfer from Workspace");
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


<div>

<%@include file="ErrorPanel.jsp"%>

    <div class="generalHeading" style="height:40px">
        <div  style="float:left;margin-top:8px;">
            Move/Copy Document/Topic/Action Item
        </div>
    </div>


    <table>
    <tr>
        <td colspan="3" class="linkWizardHeading">Select the workspace you want to copy FROM?:</td>
    </tr>

    <tr style="height:50px;padding:15px">
        <td style="padding:15px">
            To:
        </td>
        <td style="padding:15px">
            <h3>{{thisWorkspace.name}}</h3>
        </td>
    </tr>
    <tr style="height:50px;padding:15px">
        <td style="padding:15px">
            From:
        </td>
        <td style="padding:15px">
            <button ng-repeat="ws in allWorkspaces" ng-click="selectWorkspace(ws)" class="btn btn-small btn-raised">{{ws.name}}</button>
        </td>
    </tr>
    </table>
</div>
<!-- end addDocument.jsp -->
