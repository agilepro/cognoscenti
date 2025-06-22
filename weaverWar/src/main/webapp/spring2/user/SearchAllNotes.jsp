<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/include.jsp"
%><%

    ar.assertLoggedIn("Must be logged in to see a list of meetings");
    
    String searchText = ar.defParam("s", "");

%>

<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http) {
    window.setMainPageTitle("Search Workspaces");
    $scope.results = [];
    $scope.query = {
        searchFilter: "<% ar.writeJS(searchText); %>",
        searchSite: "one",
        searchProject: "one"
    }

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
<div class="userPageContents">

<%@include file="../jsp/ErrorPanel.jsp"%>


    <table>
        <tr >
            <td class="gridTableColummHeader">Search For:</td>
            <td style="width:20px;"></td>
            <td><input ng-model="query.searchFilter" class="form-control" style="width:450px;"></td>
        </tr>
        <tr ><td height="10px"></td></tr>
        <tr >
            <td class="gridTableColummHeader"></td>
            <td style="width:20px;"></td>
            <td>
              <button class="btn btn-primary btn-raised" ng-click="doSearch()">Search</button>
              <button class="btn btn-default btn-raised" ng-click="clearResults()">Clear Results</button>
            </td>
        </tr>
    </table>


    <table class="table" width="100%" ng-show="actualSearch">
        <tr class="gridTableHeader">
            <td width="200px">Site/Workspace</td>
            <td width="200px">Location</td>
            <td width="100px">Updated</td>
        </tr>
        <tr ng-repeat="row in results">
            <td>{{row.siteName}} / <a href="<%=ar.retPath%>{{row.projectLink}}">{{row.projectName}}</a></td>
            <td><a href="<%=ar.retPath%>{{row.noteLink}}">{{row.noteSubject}}</a></td>
            <td>{{row.modTime |cdate}}</td>
        </tr>
        <tr ng-show="!hasResults">
           <td colspan="5">
           <div class="guideVocal" ng-hide="isSearching"> 
             Did not find any results for search string: {{actualSearch}}
           </div>
           <div class="guideVocal" ng-show="isSearching"> 
             <img src="../../../new_assets/search-spinner.gif"/> &nbsp; Searching for results for string: {{actualSearch}}
           </div>
           </td>
        </tr>
    </table>


</div>
<!-- MAIN CONTENT SECTION END -->
