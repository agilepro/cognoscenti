<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/include.jsp"
%><%

    ar.assertLoggedIn("Must be logged in to see a list of meetings");
    
    String searchText = ar.defParam("s", "");

%>

<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal) {
    setUpLearningMethods($scope, $modal, $http);
    window.setMainPageTitle("Search Workspaces");
    $scope.results = [];
    $scope.query = {
        searchFilter: "<% ar.writeJS(searchText); %>",
        searchSite: "one",
        searchProject: "one"
    }
    $scope.searchScope = "This Workspace";

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };
    $scope.hasResults = false;
    $scope.isSearching = true;
    $scope.actualSearch = "";

    $scope.doSearch = function() {
        if (!$scope.query.searchFilter) {
            console.log("Type something in to search for")
            return;
        }
        $scope.actualSearch = $scope.query.searchFilter;
        if ($scope.searchScope=="This Workspace") {
            $scope.query.searchSite = "one";
            $scope.query.searchProject = "one";
        }
        else if ($scope.searchScope=="All Workspaces in Site") {
            $scope.query.searchSite = "one";
            $scope.query.searchProject = "all";
        }
        else {
            $scope.query.searchSite = "all";
            $scope.query.searchProject = "all";
        }
        var postURL = "searchNotes.json";
        var postdata = angular.toJson($scope.query);
        $scope.showError=false;
        $scope.isSearching = true;
        $http.post(postURL ,postdata)
        .success( function(data) {
            $scope.results = data;
            $scope.hasResults = ($scope.results.length>0);
            $scope.isSearching = false;
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };
    
    $scope.clearResults = function() {
        $scope.results = [];
        $scope.hasResults = false;
        $scope.actualSearch = "";
    }

    $scope.doSearch();
});
</script>

<!-- MAIN CONTENT SECTION START -->
<div>

<%@include file="ErrorPanel.jsp"%>

<div class="container-fluid">
    <div class="row">
        <div class="col-md-auto fixed-width border-end border-1 border-secondary">
            <span class="btn btn-raised btn-comment btn-secondary m-3 pb-2 pt-0" type="button" ng-click="clearResults()" aria-labelledby="clearResults"><a class="nav-link">Clear Results</a></span>
        </div>


    <div class="d-flex col-9"><div class="contentColumn">
    <table>
        <tr >
            <td class="gridTableColummHeader">Search For:</td>
            <td style="width:20px;"></td>
            <td><input ng-model="query.searchFilter" class="form-control" style="width:450px;"></td>
        </tr>
        <tr ><td height="10px"></td></tr>
        <tr >
            <td class="gridTableColummHeader">Workspaces:</td>
            <td style="width:20px;"></td>
            <td>
              <div class="form-inline form-group" style="margin:0px">
                  <select ng-model="searchScope" class="form-control" style="width:150px;">
                      <option value="This Workspace">This Workspace</option>
                      <option value="All Workspaces in Site">All Workspaces in Site</option>
                      <option value="All Sites">All Sites</option>
                  </select>
              </div>
            </td>
        </tr>
        <tr ><td height="10px"></td></tr>
        <tr >
            <td class="gridTableColummHeader"></td>
            <td style="width:20px;"></td>
            <td><button ng-click="doSearch()" class="btn btn-primary btn-raised">Search</button></td>
        </tr>
    </table>

    <div style="height:60px"></div>

    <table class="table" width="100%">
        <tr class="gridTableHeader">
            <td width="200px">Site/Workspace</td>
            <td width="200px">Topic</td>
            <td width="100px">Updated</td>
        </tr>
        <tr ng-repeat="row in results">
            <td>{{row.siteName}} / <a href="<%=ar.retPath%>{{row.projectLink}}">{{row.projectName}}</a></td>
            <td><a href="<%=ar.retPath%>{{row.noteLink}}">{{row.noteSubject}}</a></td>
            <td>{{row.modTime |cdate}}</td>
        </tr>
        <tr ng-hide="hasResults">
           <td colspan="5">
           <div class="guideVocal" ng-hide="isSearching"> 
             Did not find any results for search string: {{actualSearch}}
           </div>
           <div class="guideVocal" ng-show="isSearching"> 
             <img src="../../../assets/ajax-loading.gif"/> &nbsp; Searching for results for string: {{actualSearch}}
           </div>
           </td>
        </tr>
    </table>

    </div>

<!-- MAIN CONTENT SECTION END -->
