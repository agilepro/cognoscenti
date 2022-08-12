<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
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
    for (NGPageIndex ngpis : cog.getAllProjectsInSite(siteId)) {
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
    window.setMainPageTitle("Labels");
    $scope.siteInfo = <%site.getConfigJSON().write(out,2,4);%>;
    $scope.allWorkspaces = <%allWorkspaces.write(out,2,4);%>;
    $scope.thisWorkspace = <%thisWorkspace.write(out,2,4);%>;
    $scope.selectedWS = {};
    $scope.newLabelsCreated = [];

    
    $scope.openEditLabelsModal = function (item) {
        
        var attachModalInstance = $modal.open({
            animation: true,
            templateUrl: '<%=ar.retPath%>templates/EditLabels.html<%=templateCacheDefeater%>',
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

<style>
.btn-sm {
    margin:0;
}
.spacey {
}
.spacey tr td {
    padding:8px;
}
</style>


 
    
    <div class="well">
        <h2>Add and Remove Labels</h2>
        <button class="btn btn-sm btn-primary btn-raised" ng-click="openEditLabelsModal()">Pop Up</button>
                    
    </div>
    
    <div class="well">
    <h2>Copy Labels from another Workspace</h2>
    <table>
    <tr style="height:50px;padding:15px" ng-hide="selectedWS.name">
        <td style="padding:15px">
            From:
        </td>
        <td style="padding:15px">
            <button ng-repeat="ws in allWorkspaces" ng-click="selectWorkspace(ws)" class="btn btn-small btn-raised">{{ws.name}}</button>
        </td>
    </tr>
    <tr style="height:50px;padding:15px" ng-show="selectedWS.name">
        <td style="padding:15px">
            Confirm:
        </td>
        <td style="padding:15px">
            <button ng-click="copyLabels()" class="btn btn-small btn-warning btn-raised">Add all labels from --{{selectedWS.name}}-- to this workspace.</button>
            <button ng-click="cancelCopy()" class="btn btn-small btn-default btn-raised">Cancel</button>
        </td>
    </tr>
    <tr style="height:50px;padding:15px" ng-show="newLabelsCreated.length>0">
        <td style="padding:15px">
            Created:
        </td>
        <td style="padding:15px">
            <div ng-repeat="lab in newLabelsCreated">
            <button style="background-color:{{lab.color}};" class="labelButton">{{lab.name}}</button>
            </div>
        </td>
    </tr>
    </table>  
    </div>    
</div>


<script src="<%=ar.baseURL%>templates/EditLabelsCtrl.js"></script>