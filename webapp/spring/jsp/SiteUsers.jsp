<%@page errorPage="/spring/jsp/error.jsp"
%><%@page import="org.socialbiz.cog.NGRole"
%><%@page import="org.socialbiz.cog.License"
%><%@ include file="/spring/jsp/include.jsp"
%><%

    ar.assertLoggedIn("");
    String siteId = ar.reqParam("siteId");
    NGBook  ngb = ar.getCogInstance().getSiteByIdOrFail(siteId);
    String pageAddress = ar.getResourceURL(ngb,"personal.htm");

    JSONObject userMap = new JSONObject();
    List<NGPageIndex> allWorkspaces = ar.getCogInstance().getAllProjectsInSite(siteId);
    for (NGPageIndex ngpi : allWorkspaces) {
        NGWorkspace ngw = ngpi.getWorkspace();
        for (CustomRole ngr : ngw.getAllRoles()) {
            for (AddressListEntry ale : ngr.getDirectPlayers()) {
                String uid = ale.getUniversalId();
                UserProfile user = ale.getUserProfile();

                JSONObject userInfo = null;
                JSONObject wsMap = null;
                if (userMap.has(uid)) {
                    userInfo = userMap.getJSONObject(uid);
                    wsMap = userInfo.getJSONObject("wsMap");
                    userInfo.put("count", userInfo.getInt("count")+1);
                }
                else {
                    userInfo = new JSONObject();
                    userMap.put(uid, userInfo);
                    wsMap = new JSONObject();
                    userInfo.put("wsMap", wsMap);
                    if (user==null) {
                        userInfo.put("info", ale.getJSON());
                    }
                    else {
                        userInfo.put("info", user.getFullJSON());
                    }
                    userInfo.put("count", 1);
                }
                String wsKey = ngw.getKey();
                if (!wsMap.has(wsKey)) {
                    wsMap.put(wsKey, ngw.getFullName());
                }
                userInfo.put("wscount", wsMap.length());
            }
        }
    }


%>

<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http) {
    window.setMainPageTitle("List of Users in Site");
    $scope.userMap = <%userMap.write(out,2,4);%>;
    $scope.sourceUser = "";
    $scope.destUser = "";
    $scope.replaceConfirm = false;

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
        window.location = "SiteUserInfo.htm?userKey="+$scope.newEmail;
    }
});
app.filter('encode', function() {
  return window.encodeURIComponent;
});
</script>

<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>


    <div class="upRightOptions rightDivContent">
      <span class="dropdown">
        <button class="btn btn-default btn-raised dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
        Options: <span class="caret"></span></button>
        <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
          <li role="presentation"><a role="menuitem"
              href="SiteAdmin.htm">Site Admin</a></li>
          <li role="presentation"><a role="menuitem"
              href="roleRequest.htm">Role Requests</a></li>
          <li role="presentation"><a role="menuitem"
              href="SiteUsers.htm">User List</a></li>
          <li role="presentation"><a role="menuitem"
              href="SiteStats.htm">Site Statistics</a></li>
        </ul>
      </span>
    </div>

<style>
.paddedCell {
    padding:8px;
}
.workspaceButton {
    border: 2px solid white;
    border-radius: 6px;
    background-color: lightgray;
    padding: 5px;
    padding-left: 10px;
    padding-right: 10px;
}
.workspaceButton:hover {
    background-color: lightskyblue;
}
</style>

<div ng-hide="addUserPanel">
  <button class="btn btn-raised" ng-click="addUserPanel=true">Add User</button>
</div>
<div class="well" ng-show="addUserPanel">
   <input type="text" ng-model="newEmail" class="form-control"/>
   <button class="btn btn-primary btn-raised" ng-click="addUser()">Create User With This Email</button>
   <button class="btn btn-raised" ng-click="addUserPanel=false">Cancel</button>
</div>

    <div>
    <table class="table">
      <tr>
         <th>Primary Email</th>
         <th>Name</th>
         <th>Last Login</th>
         <th>Objects</th>
         <th>Workspaces</th>
      </tr>
      <tr ng-repeat="(key, value) in userMap">
         <td><a href="SiteUserInfo.htm?siteId=<%=siteId%>&userKey={{value.info.key|encode}}">{{value.info.name}}</a></td>
         <td>{{value.info.uid}}</td>
         <td>{{value.info.lastLogin|date}}</td>
         <td>{{value.count}}</td>
         <td>{{value.wscount}}</td>
      </tr>
    </table>
    </div>
</div>

