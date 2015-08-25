<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%

    ar.assertLoggedIn("Must be logged in to see a list of meetings");

%>

<script type="text/javascript">

var app = angular.module('myApp', ['ui.bootstrap']);
app.controller('myCtrl', function($scope, $http) {
    $scope.results = [];
    $scope.query = {
        searchFilter: "",
        searchSite: "all",
        searchProject: "all"
    }

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };

    $scope.doSearch = function() {
        var postURL = "searchNotes.json";
        var postdata = angular.toJson($scope.query);
        $scope.showError=false;
        $http.post(postURL ,postdata)
        .success( function(data) {
            $scope.results = data;
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };

});
</script>

<!-- MAIN CONTENT SECTION START -->
<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

    <div class="generalHeading" style="height:40px">
        <div  style="float:left;margin-top:8px;">
            Search All Notes
        </div>
        <div class="rightDivContent" style="margin-right:100px;">
          <span class="dropdown">
            <button class="btn btn-default dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
            Options: <span class="caret"></span></button>
            <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
              <li role="presentation"><a role="menuitem" tabindex="-1"
                  ng-click="results = []">Clear Results</a></li>
            </ul>
          </span>

        </div>
    </div>

    <table class="">
        <tr ng-hide="editGoalInfo">
            <td class="gridTableColummHeader">Search For:</td>
            <td style="width:20px;"></td>
            <td><input ng-model="query.searchFilter" class="form-control" style="width:450px;"></td>
        </tr>
        <tr ng-hide="editGoalInfo"><td height="10px"></td></tr>
        <tr ng-hide="editGoalInfo">
            <td class="gridTableColummHeader">Sites:</td>
            <td style="width:20px;"></td>
            <td>
              <div class="form-inline form-group">
                  <select ng-model="query.searchSite" class="form-control" style="width:150px;">
                      <option value="one">This Site</option>
                      <option value="all">All Sites</option>
                  </select>
                  Projects:
                  <select ng-model="query.searchProject" class="form-control" style="width:150px;">>
                      <option value="all">All Projects</option>
                      <option value="member">Member Projects</option>
                      <option value="owner">Owned Projects</option>
                  </select>
              </div>
            </td>
        </tr>
        <tr ng-hide="editGoalInfo">
            <td class="gridTableColummHeader"></td>
            <td style="width:20px;"></td>
            <td><button ng-click="doSearch()" class="btn btn-primary">Search</button></td>
        </tr>
    </table>

    <div style="height:30px"></div>

    <table class="gridTable2" width="100%">
        <tr class="gridTableHeader">
            <td width="200px">Site/Project</td>
            <td width="200px">Note</td>
            <td width="100px">Updated</td>
        </tr>
        <tr ng-repeat="row in results">
            <td>{{row.siteName}} / <a href="<%=ar.retPath%>{{row.projectLink}}">{{row.projectName}}</a></td>
            <td><a href="<%=ar.retPath%>{{row.noteLink}}">{{row.noteSubject}}</a></td>
            <td>{{row.modTime | date}}</td>
        </tr>
    </table>


</div>
<!-- MAIN CONTENT SECTION END -->
