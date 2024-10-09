<%@page errorPage="/spring2/jsp/error.jsp"
%><%@page import="java.util.Date"
%><%@page import="com.purplehillsbooks.weaver.TaskArea"
%><%@ include file="/include.jsp"
%><%
/*
Required parameters:

    1. pageId   : This is the id of a workspace and here it is used to retrieve NGWorkspace.

*/
    //set 'forceTemplateRefresh' in config file to 'true' to get this
    String templateCacheDefeater = "";
    if ("true".equals(ar.getSystemProperty("forceTemplateRefresh"))) {
        templateCacheDefeater = "?t="+System.currentTimeMillis();
    }

    String pageId  = ar.reqParam("pageId");
    String siteId  = ar.reqParam("siteId");
    NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngw);
    ar.assertAccessWorkspace("Must be a member to see meetings");
    UserProfile uProf = ar.getUserProfile();

    JSONArray allTaskAreas = new JSONArray();
    for (TaskArea gr : ngw.getTaskAreas()) {
        allTaskAreas.put(gr.getMinJSON());
    }
    boolean isFrozen = ngw.isFrozen();



%>

<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, AllPeople, $modal) {
    setUpLearningMethods($scope, $modal, $http);
    window.setMainPageTitle("Task Areas & Work Groupings");
    $scope.siteId = "<%ar.writeJS(siteId);%>";
    $scope.loaded = false;
    $scope.allTaskAreas  = [];
    $scope.isFrozen = <%= isFrozen %>;

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
    
    $scope.moveTaskArea = function(item, isDown) {
        if ($scope.isFrozen) {
            alert("You are not able to move task areas because this workspace is frozen");
            return;
        }
        let postObject = {areaId: item.id, moveDown: isDown};
        console.log("moveTaskArea", postObject);
        var getURL = "moveTaskArea.json";
        $http.post(getURL, angular.toJson(postObject))
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

    $scope.openTaskAreaModal = function (ta) {
        if ($scope.isFrozen) {
            alert("You are not able to edit task areas because this workspace is frozen");
            return;
        }

        var modalInstance = $modal.open({
            animation: true,
            templateUrl: '<%=ar.retPath%>new_assets/templates/TaskAreaModal.html<%=templateCacheDefeater%>',
            controller: 'TaskAreaModal',
            size: 'lg',
            backdrop: "static",
            resolve: {
                id: function () {
                    return ta.id;
                },
                siteId: function() {return $scope.siteId}
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

<div>

<%@include file="ErrorPanel.jsp"%>

<div class="container-fluid">
  <div class="row">
    <div class="col-md-auto fixed-width border-end border-1 border-secondary">
        <span class="btn btn-secondary btn-comment btn-raised m-3 pb-2 pt-0" type="button">
            <a class="nav-link" ng-click="openTaskAreaModal({id:'~new~'})" >Create New Task Area</a>
        </span>
          <hr>
        <span class="btn btn-secondary btn-comment btn-raised m-3 pb-2 pt-0" type="button">
            <a class="nav-link" role="menuitem" tabindex="-1"
              href="GoalList.htm">Action Items View</a>
        </span>
              <span class="btn btn-secondary btn-comment btn-raised m-3 pb-2 pt-0" type="button"><a class="nav-link" role="menuitem" tabindex="-1"
              href="GoalStatus.htm">Status List View</a></span>

    </div>

    <div class="d-flex col-9">
        <div class="contentColumn">


  <div class="guideVocal" ng-hide="loaded">
    Fetching the data from the server . . .
  </div>

  <div ng-show="loaded">
    <div class="container-fluid col-12 ms-5">
        <div class="row d-flex border-bottom border-1">
            <span class="col-2"></span>
            <span class="col-3 h6">Name</span>
            <span class="col-2 h6">Assignee</span>
            <span class="col-2 h6" title="Red-Yellow-Green assessment of status">R-Y-G</span>
            <span class="col-2 h6">Status</span>
        </div>
      <div class="row d-flex border-bottom border-1 py-2"  ng-repeat="ta in allTaskAreas">
        <span class="col-2" style="cursor:pointer" 
            title="Edit this task area">
          <span ng-click="openTaskAreaModal(ta)" ><span class="fa fa-edit"></span></span> &nbsp;
          <span ng-click="moveTaskArea(ta, false)" ><span class="fa fa-arrow-up"></span></span> &nbsp;
          <span ng-click="moveTaskArea(ta, true)" ><span class="fa fa-arrow-down"></span></span> &nbsp;
      </span>
        <span class="col-3" ng-dblclick="openTaskAreaModal(ta)" >{{ta.name}} - {{ta.id}}</span>
        <span class="col-2" title="Click on person name to see their profile information">
            <div ng-repeat="ass in ta.assignees">
                <a href="<%=ar.retPath%>v/FindPerson.htm?key={{ass.key}}">{{ass.name}}</a></div>
                </span>
        <span class="col-2" title="Red-Yellow-Green assessment of status">
          <span>
            <img src="<%=ar.retPath%>assets/goalstate/red_off.png" ng-hide="ta.prospects=='bad'"
                 title="Red: In trouble" ng-click="setProspects(ta, 'bad')" class="stoplight">
            <img src="<%=ar.retPath%>assets/goalstate/red_on.png"  ng-show="ta.prospects=='bad'"
                 title="Red: In trouble" class="stoplight">
            <img src="<%=ar.retPath%>assets/goalstate/yellow_off.png" ng-hide="ta.prospects=='ok'"
                 title="Yellow: Warning" ng-click="setProspects(ta, 'ok')" class="stoplight">
            <img src="<%=ar.retPath%>assets/goalstate/yellow_on.png"  ng-show="ta.prospects=='ok'"
                 title="Yellow: Warning" class="stoplight">
            <img src="<%=ar.retPath%>assets/goalstate/green_off.png" ng-hide="ta.prospects=='good'"
                 title="Green: Good shape" ng-click="setProspects(ta, 'good')" class="stoplight">
            <img src="<%=ar.retPath%>assets/goalstate/green_on.png"  ng-show="ta.prospects=='good'"
                 title="Green: Good shape" class="stoplight">
          </span>
        </span>
        <span class="col-2" ng-dblclick="openTaskAreaModal(ta)" >{{ta.status}}</span>
    </div>
</div>
    
    <div class="guideVocal" ng-hide="allTaskAreas.length > 0">
      No records to show . . .
    </div>
  </div>


</div>

<script src="<%=ar.retPath%>new_assets/templates/TaskAreaModal.js"></script>


