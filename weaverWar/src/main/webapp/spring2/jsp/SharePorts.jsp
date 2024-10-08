<%@page errorPage="/spring/jsp/error.jsp"
%><%@page import="java.util.Date"
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

    JSONArray allLabels = ngw.getJSONLabels();
    boolean isFrozen = ngw.isFrozen();
    
%>

<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal) {
    setUpLearningMethods($scope, $modal, $http);
    window.setMainPageTitle("Share Ports");
    $scope.loaded = false;
    $scope.allShares = [];
    $scope.allLabels = <%allLabels.write(out,2,4);%>;
    $scope.isFrozen = <%= isFrozen %>;
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
        if ($scope.isFrozen) {
            alert("You are not able to edit share ports because this workspace is frozen");
            return;
        }

        var modalInstance = $modal.open({
          animation: true,
            templateUrl: '<%=ar.retPath%>new_assets/templates/SharePortModal.html<%=templateCacheDefeater%>',
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

<div class="container-fluid">
  <div class="row">
        <div class="col-md-auto fixed-width border-end border-1 border-secondary">
          <span class="btn btn-secondary btn-comment btn-raised m-3 pb-2 pt-0" type="button"><a class="nav-link" role="menuitem" tabindex="-1"
              ng-click="openSharePortEditor(newSharePort)">Create New Share Port</a></span>
        </div>
        </div>
        <div class="d-flex col-9">
          <div class="contentColumn">
            <div class="container-fluid">
              <div class="generalContent">
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
            </div>
          </div>
        </div>
    </div>
</div>

<script src="<%=ar.retPath%>templates/SharePortModal.js"></script>



