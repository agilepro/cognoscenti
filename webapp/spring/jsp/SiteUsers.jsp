<%@page errorPage="/spring/jsp/error.jsp"
%><%@page import="org.socialbiz.cog.NGRole"
%><%@page import="org.socialbiz.cog.License"
%><%@ include file="/spring/jsp/include.jsp"
%><%

    ar.assertLoggedIn("");
    String accountId = ar.reqParam("accountId");
    NGBook  ngb = ar.getCogInstance().getSiteByIdOrFail(accountId);
    String pageAddress = ar.getResourceURL(ngb,"personal.htm");

    JSONObject userMap = new JSONObject();
    List<NGPageIndex> allWorkspaces = ar.getCogInstance().getAllProjectsInSite(accountId);
    for (NGPageIndex ngpi : allWorkspaces) {
        NGWorkspace ngw = ngpi.getPage();
        for (CustomRole ngr : ngw.getAllRoles()) {
            for (AddressListEntry ale : ngr.getDirectPlayers()) {
                String uid = ale.getUniversalId();

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
                    userInfo.put("count", 1);
                }
                String wsKey = ngw.getKey();
                if (!wsMap.has(wsKey)) {
                    wsMap.put(wsKey, ngw.getFullName());
                }
            }
        }
    }


%>

<script type="text/javascript">

var app = angular.module('myApp', ['ui.bootstrap']);
app.controller('myCtrl', function($scope, $http) {
    window.setMainPageTitle("Site Users");
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

});
app.filter('encode', function() {
  return window.encodeURIComponent;
});
</script>

<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>


    <div class="generalHeading" style="height:40px">
        <div  style="float:left;margin-top:8px;">
            Site User Management
        </div>
        <div class="rightDivContent" style="margin-right:100px;">
          <span class="dropdown">
            <button class="btn btn-default btn-raised dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
            Options: <span class="caret"></span></button>
            <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
              <li role="presentation"><a role="menuitem"
                  href="SiteAdmin.htm">Site Admin</a></li>
              <li role="presentation"><a role="menuitem"
                  href="roleRequest.htm">Role Requests</a></li>
              <li role="presentation"><a role="menuitem"
                  href="SiteUsers.htm">User Migration</a></li>
              <li role="presentation"><a role="menuitem"
                  href="SiteStats.htm">Site Statistics</a></li>
            </ul>
          </span>

        </div>
    </div>

<style>
.paddedCell {
    padding:8px;
}
</style>

    <div class="well">
        <h1>User Migration</h1>

        <table >
          <tr>
            <td class="paddedCell">Find This Email ID:</td>
            <td class="paddedCell"><input ng-model="sourceUser" class="form-control"></td>
          </tr>
          <tr>
            <td class="paddedCell">Replace With:</td>
            <td class="paddedCell"><input ng-model="destUser" class="form-control"></td>
          </tr>
          <tr>
            <td class="paddedCell"></td>
            <td class="paddedCell">
                <button ng-click="replaceUsers()" class="btn btn-primary btn-raised">Replace First With Second</button>
                <input type="checkbox" ng-model="replaceConfirm"> Check here to confirm, there is no way to UNDO this change
            </td>
          </tr>
        </table>
    </div>

<style>
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
<hr/>
    <div>
    <h1>List of users in workspaces</h1>
    <table class="table">
      <tr ng-repeat="(key, value) in userMap">
         <td><a href="../../FindPerson.htm?uid={{key|encode}}">{{key}}</a></td>
         <td>{{value.count}}</td>
         <td><span ng-repeat="(wsKey,wsName) in value.wsMap">
             <a href="../{{wsKey}}/frontPage.htm" class="workspaceButton">{{wsName}}</a>, </span></td>
      </tr>
    </table>
    </div>
</div>

