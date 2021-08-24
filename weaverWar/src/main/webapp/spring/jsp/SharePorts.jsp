<%@page errorPage="/spring/jsp/error.jsp"
%><%@page import="java.util.Date"
%><%@page import="com.purplehillsbooks.weaver.NGRole"
%><%@page import="java.text.SimpleDateFormat"
%><%@page import="com.purplehillsbooks.weaver.MicroProfileMgr"
%><%@ include file="/spring/jsp/include.jsp"
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
    ar.assertMember("Must be a member to see meetings");

    JSONArray allLabels = ngw.getJSONLabels();
    
%>

<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal) {
    window.setMainPageTitle("Share Ports");
    $scope.loaded = false;
    $scope.allShares = [];
    $scope.allLabels = <%allLabels.write(out,2,4);%>;
    $scope.filter = "";
    $scope.filterMap = {};
    $scope.newSharePort = {id:"~new~",universalid:"~new~"};

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };

    
    $scope.getSharePorts = function() {
        console.log("getting share ports")
        var getURL = "sharePorts.json";
        $http.get(getURL)
        .success( function(data) {
            console.log("received share ports", data);
            $scope.allShares = data.shares;
            $scope.loaded = true;
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    }
    
    $scope.getSharePorts();

    $scope.openSharePortEditor = function (sharePort) {

        var modalInstance = $modal.open({
            animation: false,
            templateUrl: '<%=ar.retPath%>templates/SharePortModal.html<%=templateCacheDefeater%>',
            controller: 'SharePortCtrl',
            size: 'lg',
            backdrop: "static",
            resolve: {
                id: function () {
                    return sharePort.id;
                },
                allLabels: function () {
                    return $scope.allLabels;
                }
            }
        });

        modalInstance.result.then(function (modifiedDecision) {
            $scope.getSharePorts();
        }, function () {
            $scope.getSharePorts();
        });
    };
    
    $scope.hasLabel = function(sharePort, role) {
        var hasIt = false;
        sharePort.labels.forEach( function(item) {
            if (item == role.name) {
                hasIt = true;
            }
        });
        return hasIt;
    }

    $scope.goToSharePort = function (sharePort) {
        window.location = "share/"+sharePort.id+".htm";
    }
});


</script>

<div>

<%@include file="ErrorPanel.jsp"%>

    <div class="upRightOptions rightDivContent">
      <span class="dropdown">
        <button class="btn btn-default btn-raised dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
        Options: <span class="caret"></span></button>
        <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
          <li role="presentation"><a role="menuitem" tabindex="-1"
              ng-click="openSharePortEditor(newSharePort)">Create New Share Port</a></li>
        </ul>
      </span>
    </div>


  <div class="guideVocal" ng-hide="loaded">
    Fetching the data from the server . . .
  </div>

  <div ng-show="loaded">


    <table class="table">
      <col width="50px">
      <col width="50px">
      <tr>
        <th></th>
        <th></th>
        <th>Name</th>
        <th>Purpose</th>
        <th>Active</th>
        <th>Filter</th>
        <th>Labels</th>
      </tr>
      <tr ng-repeat="port in allShares">
        <td style="cursor:pointer" ng-click="openSharePortEditor(port)"><span class="fa fa-edit"></span></td>
        <td style="cursor:pointer" ng-click="goToSharePort(port)"><span class="fa fa-eye"></span></td>
        <td>{{port.name}}</td>
        <td>{{port.purpose}}</td>
        <td>{{port.isActive}}</td>
        <td>{{port.filter}}</td>
        <td>
          <span class="dropdown" ng-repeat="role in allLabels">
            <button class="dropdown-toggle labelButton" 
               style="background-color:{{role.color}};"
               ng-show="hasLabel(port, role)">{{role.name}}</button>
          </span>        
        </td>
      </tr>
    </table>
    
    <div class="guideVocal" ng-hide="allShares.length > 0">
      No records to show . . .
    </div>
  </div>



</div>

<script src="<%=ar.retPath%>templates/SharePortModal.js"></script>



