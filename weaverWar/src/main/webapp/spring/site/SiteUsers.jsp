<%@page errorPage="/spring/jsp/error.jsp"
%><%@page import="com.purplehillsbooks.weaver.NGRole"
%><%@page import="com.purplehillsbooks.weaver.License"
%><%@ include file="/spring/jsp/include.jsp"
%><%

    ar.assertLoggedIn("");
    String siteId = ar.reqParam("siteId");
    Cognoscenti cog = ar.getCogInstance();
    NGBook site = cog.getSiteByIdOrFail(siteId);

    SiteUsers siteUsers = site.getUserMap();


%>

<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http) {
    window.setMainPageTitle("List of Users in Site");
    $scope.siteUsers = <%siteUsers.getJson().write(out,2,4);%>;
    $scope.siteSettings = <%site.getConfigJSON().write(out,2,4);%>;
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

    $scope.visitUser = function(email) {
        window.location = "SiteUserInfo.htm?userKey="+encodeURIComponent(email);
    }
    
    $scope.recountUsers = function() {
        var activeCount = 0;
        var inactiveCount = 0;
        var keys = Object.keys($scope.siteUsers);
        keys.forEach( function(key) {
            if (!$scope.siteUsers[key].readOnly && $scope.siteUsers[key].lastAccess > 100000) {
                activeCount++;
            }
            else {
                inactiveCount++;
            }
        });
        $scope.activeUserCount = activeCount;
        $scope.readOnlyCount = inactiveCount;
    }
    $scope.recountUsers();
    
    $scope.findUsers = function() {
        var keys = Object.keys($scope.siteUsers);
        var finalList = [];
        if (!$scope.filter) {
            keys.forEach( function(key) {
                finalList.push($scope.siteUsers[key]);
            });
            return finalList;
        }
        var filterlist = parseLCList($scope.filter);
        console.log("FILTER LIST", filterlist);
        keys.forEach( function(key) {
            var aUser = $scope.siteUsers[key];
            if (aUser.info) {
                if (containsOne(aUser.info.name, filterlist)) {
                    finalList.push(aUser);
                }
                else if (containsOne(aUser.info.uid, filterlist)) {
                    finalList.push(aUser);
                }
                else if (containsOne(aUser.info.key, filterlist)) {
                    finalList.push(aUser);
                }
            }
        });
        return finalList;
    }
    $scope.recalcStats = function() {
        console.log("recalcStats");
        var getURL = "SiteStatistics.json?recalc=yes";
        $scope.showError=false;
        $http.get(getURL)
        .success( function(data) {
            $scope.stats = data.stats;
            $scope.recountUsers();
            window.location.reload(false);
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };
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
          <li role="presentation"><a role="menuitem"
              ng-click="recalcStats()">Recalculate</a></li>
          <% if (ar.isSuperAdmin()) { %>
          <li role="presentation" style="background-color:yellow"><a role="menuitem"
              href="../../../v/su/SiteDetails.htm?siteKey=<%=siteId%>">Super Admin</a></li>
          <% } %>
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
  This site has {{activeUserCount}} / {{siteSettings.editUserLimit}} active users who can update, 
  and {{readOnlyCount}} / {{siteSettings.viewUserLimit}} inactive users.
  <div ng-show="activeUserCount>siteSettings.editUserLimit" class="guideVocal"> 
    <b>Site has too many active users.</b>  You are allowed {{siteSettings.editUserLimit}} in the site who have edit acess to the site, and you have {{activeUserCount}}.  You will not be able to add any new update users to the site until you reduce the number of active edit users or you change your payment plan.
  </div>
  <div ng-show="readOnlyCount>siteSettings.viewUserLimit" class="guideVocal">
    <b>Site has too many inactive users.</b>  You are allowed {{siteSettings.viewUserLimit}} and you have {{readOnlyCount}}.<br/>
    An inactive user is either a user set to read-only access, or a user who has never logged in to the site directly.   You will not be able to add any new email addresses to the site until you reduce the number of inactive users or you change your payment plan.
    <hr/>
    To remove a user from this list, click on the user, and use the option to 'Completely Remove This User' at the very bottom of the page.
  </div>
</div>
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
        <td>
            <span ng-show="value.readOnly" style="color:grey">Read Only</span>
            <span ng-show="!value.readOnly && value.lastAccess < 100000" style="color:lightblue">No Login</span>
            <span ng-show="!value.readOnly && value.lastAccess > 100000"><b>Update</b></span>
        </td>
        <td><span ng-show="value.info.lastLogin>0">{{value.info.lastLogin|cdate}}</span></td>
        <td>{{value.count}}</td>
        <td>{{value.wscount}}</td>
      </tr>
    </table>
    </div>
</div>

<div class="well">
<%
    for (String key: siteUsers.getAllUserKeys()) {
        %><div><%=key%></div><%
    }
%>
<div>PATH = <%=siteUsers.folder.getAbsolutePath()%></div>
<pre>
<%siteUsers.getJson().write(out,2,0);%>
</pre>
</div>