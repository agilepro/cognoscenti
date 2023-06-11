<%@page errorPage="/spring/jsp/error.jsp"
%><%@page import="com.purplehillsbooks.weaver.NGRole"
%><%@page import="com.purplehillsbooks.weaver.License"
%><%@ include file="/spring/jsp/include.jsp"
%><%

    ar.assertLoggedIn("");
    String siteId = ar.reqParam("siteId");
    Cognoscenti cog = ar.getCogInstance();
    NGBook site = cog.getSiteByIdOrFail(siteId);

    SiteUsers userMap = site.getUserMap();


%>

<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http) {
    window.setMainPageTitle("List of Users in Site");
    $scope.userMap = <%userMap.getJson().write(out,2,4);%>;
    $scope.sourceUser = "";
    $scope.destUser = "";
    $scope.replaceConfirm = false;
    $scope.filter = "";

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };

    $scope.replaceUsers = function() {
        if (!$scope.replaceConfirm) {
            alert("If you want to replace the email ids, please check the confirm box");
            return;
        }
        var postObj = {};
        postObj.sourceUser = $scope.sourceUser
        postObj.destUser = $scope.destUser
        var postdata = angular.toJson(postObj);
        $scope.showError=false;
        $http.post("replaceUsers.json" ,postdata)
        .success( function(data) {
            console.log(JSON.stringify(data));
            alert("operation changed "+data.updated+" places.");
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    }
    $scope.addUser = function() {
        window.location = "SiteUserInfo.htm?userKey="+encodeURIComponent($scope.newEmail);
    }
    $scope.visitUser = function(email) {
        window.location = "SiteUserInfo.htm?userKey="+encodeURIComponent(email);
    }
    
    $scope.updateCount = function() {
        var count = 0;
        var keys = Object.keys($scope.userMap);
        keys.forEach( function(key) {
            if (!$scope.userMap[key].readOnly && $scope.userMap[key].hasProfile) {
                count++;
            }
        });
        return count;
    }
    $scope.readOnlyCount = function() {
        var count = 0;
        var keys = Object.keys($scope.userMap);
        keys.forEach( function(key) {
            if ($scope.userMap[key].readOnly || !$scope.userMap[key].hasProfile) {
                count++;
            }
        });
        return count;
    }
    $scope.findUsers = function() {
        var keys = Object.keys($scope.userMap);
        var finalList = [];
        if (!$scope.filter) {
            keys.forEach( function(key) {
                finalList.push($scope.userMap[key]);
            });
            return finalList;
        }
        var filterlist = parseLCList($scope.filter);
        console.log("FILTER LIST", filterlist);
        keys.forEach( function(key) {
            var aUser = $scope.userMap[key];
            if (containsOne(aUser.info.name, filterlist)) {
                finalList.push(aUser);
            }
            else if (containsOne(aUser.info.uid, filterlist)) {
                finalList.push(aUser);
            }
        });
        return finalList;
    }    
});
app.filter('encode', function() {
  return window.encodeURIComponent;
});
</script>

<div>

<%@include file="../jsp/ErrorPanel.jsp"%>


    <div class="upRightOptions rightDivContent">
      <span class="dropdown">
        <button class="btn btn-default btn-raised dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
        Options: <span class="caret"></span></button>
        <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
          <li role="presentation"><a role="menuitem"
              href="SiteAdmin.htm">Site Admin</a></li>
          <li role="presentation"><a role="menuitem"
              href="SiteUsers.htm">User List</a></li>
          <li role="presentation"><a role="menuitem"
              href="SiteStats.htm">Site Statistics</a></li>
          <li role="presentation"><a role="menuitem"
              href="SiteLedger.htm">Site Charges</a></li>
        </ul>
      </span>
    </div>

<style>
.table tr {
    cursor:pointer;
}
.table tr:hover{
    background-color:#F7E0FF;;
}
</style>

<div ng-hide="addUserPanel">
  <button class="btn btn-raised" ng-click="addUserPanel=true">Add User</button>
  &nbsp; This site has {{updateCount()}} users who can update, and {{readOnlyCount()}} read-only users.
</div>
<div class="well" ng-show="addUserPanel">
   <input type="text" ng-model="newEmail" class="form-control"/>
   <button class="btn btn-primary btn-raised" ng-click="addUser()">Create User With This Email</button>
   <button class="btn btn-raised" ng-click="addUserPanel=false">Cancel</button>
   
</div>
{{filter}}
    <div>
    <table class="table">
      <tr>
         <th></th>
         <th>Name <input type="text" ng-model="filter"/></th>
         <th>Primary Email</th>
         <th>Access</th>
         <th>Last Login</th>
         <th>Objects</th>
         <th>Workspaces</th>
      </tr>
      <tr ng-repeat="value in findUsers()" 
          ng-click="visitUser(value.info.uid)">
        <td>
            <img class="img-circle" src="<%=ar.retPath%>icon/{{value.info.key}}.jpg" 
                 style="width:32px;height:32px" title="{{value.info.name}} - {{value.info.uid}}">
        </td>
        <td>{{value.info.name}}</td>
        <td>{{value.info.uid}}</td>
        <td><span ng-hide="value.readOnly || !value.hasProfile"><b>Update</b></span>
            <span ng-show="value.readOnly || !value.hasProfile" style="color:grey">Read Only</span>
        </td>
        <td><span ng-show="value.info.lastLogin>0">{{value.info.lastLogin|cdate}}</span></td>
        <td>{{value.count}}</td>
        <td>{{value.wscount}}</td>
      </tr>
    </table>
    </div>
</div>

