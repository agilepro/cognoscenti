<%@page errorPage="/spring/jsp/error.jsp"
%><%@page import="java.util.Date"
%><%@page import="org.socialbiz.cog.NGRole"
%><%@page import="java.text.SimpleDateFormat"
%><%@page import="org.socialbiz.cog.MicroProfileMgr"
%><%@page import="org.socialbiz.cog.TaskArea"
%><%@ include file="/spring/jsp/include.jsp"
%><%
/*
Required parameters:

    1. pageId   : This is the id of a workspace and here it is used to retrieve NGPage.

*/

    String pageId      = ar.reqParam("pageId");
    NGWorkspace ngw = ar.getCogInstance().getWorkspaceByKeyOrFail(pageId);
    ar.setPageAccessLevels(ngw);
    ar.assertMember("Must be a member to see meetings");
    UserProfile uProf = ar.getUserProfile();

    JSONArray allTaskAreas = new JSONArray();
    for (TaskArea gr : ngw.getTaskAreas()) {
        allTaskAreas.put(gr.getMinJSON());
    }



%>

<script type="text/javascript">

var app = angular.module('myApp', ['ui.bootstrap','ngTagsInput']);
app.controller('myCtrl', function($scope, $http, AllPeople,  $modal) {
    window.setMainPageTitle("Task Areas & Work Groupings");
    $scope.loaded = false;
    $scope.allTaskAreas  = [];

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };

    
    $scope.getTaskAreas = function() {
        console.log("getting TaskAreas")
        var getURL = "taskAreas.json";
        $http.get(getURL)
        .success( function(data) {
            console.log("received TaskAreas", data);
            $scope.allTaskAreas = data.taskAreas;
            $scope.loaded = true;
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    }
    
    $scope.getTaskAreas();

    $scope.openTaskAreaEditor = function (ta) {

        var modalInstance = $modal.open({
            animation: false,
            templateUrl: '<%=ar.retPath%>templates/TaskAreaModal.html?t='+(new Date()).getTime(),
            controller: 'TaskAreaCtrl',
            size: 'lg',
            backdrop: "static",
            resolve: {
                id: function () {
                    return ta.id;
                }
            }
        });

        modalInstance.result.then(function (modifiedTaskArea) {
            $scope.getTaskAreas();
        }, function () {
            $scope.getTaskAreas();
        });
    };
    
    
});


</script>
<script src="../../../jscript/AllPeople.js"></script>

<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

    <div class="upRightOptions rightDivContent">
      <span class="dropdown">
        <button class="btn btn-default btn-raised dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
        Options: <span class="caret"></span></button>
        <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
          <li role="presentation"><a role="menuitem" tabindex="-1"
              ng-click="openTaskAreaEditor({id:'~new~'})">Create New Task Area</a></li>
        </ul>
      </span>
    </div>


  <div class="guideVocal" ng-hide="loaded">
    Fetching the data from the server . . .
  </div>

  <div ng-show="loaded">


    <table class="table">
      <col width="50px">
      <tr>
        <th></th>
        <th>Name</th>
        <th>Assignee</th>
        <th>Prospect</th>
        <th>Status</th>
      </tr>
      <tr ng-repeat="ta in allTaskAreas">
        <td style="cursor:pointer" ng-click="openTaskAreaEditor(ta)"><span class="fa fa-edit"></span></td>
        <td>{{ta.name}}</td>
        <td>{{ta.assignees}}</td>
        <td>{{ta.prospect}}</td>
        <td>{{ta.status}}</td>
      </tr>
    </table>
    
    <div class="guideVocal" ng-hide="allTaskAreas.length > 0">
      No records to show . . .
    </div>
  </div>


</div>

<script src="<%=ar.retPath%>templates/TaskAreaModal.js"></script>


