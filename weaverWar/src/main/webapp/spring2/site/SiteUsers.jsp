<%@page errorPage="/spring2/jsp/error.jsp"
%><%@ include file="/include.jsp"
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
    $scope.siteUsers = <%siteUsers.getJson().write(out,2,4);%>;
    var keys = Object.keys($scope.siteUsers);
    $scope.sortedUsers = [];
    keys.forEach( function(item) {$scope.sortedUsers.push($scope.siteUsers[item])} );
    $scope.sortedUsers.sort(function(a, b){return b.lastAccess-a.lastAccess});
    
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
        if (!$scope.filter) {
            return $scope.sortedUsers;
        }
        var finalList = [];
        var filterlist = parseLCList($scope.filter);
        console.log("FILTER LIST", filterlist);
        $scope.sortedUsers.forEach( function(aUser) {
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
    $scope.garbageCollect = function() {
        if (!confirm("Do you really want to delete the workspaces marked for deletion?")) {
            return;
        }
        var postURL = "GarbageCollect.json";
        $http.get(postURL)
        .success( function(data) {
            console.log("Garbage Results", data);
            alert("Success.  REFRESHING the page");
            window.location.reload();
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    }
    $scope.preserveCount = $scope.siteSettings.editUserLimit;
    $scope.demoteBatchUsers = function() {
        var countLeft = $scope.preserveCount;
        $scope.sortedUsers.forEach( function(userRecord) {
            console.log("checking", userRecord);
            if (!userRecord.readOnly) {
                if (countLeft>0) {
                    countLeft--;
                }
                else {
                    userRecord.readOnly = true;
                    $scope.updateUserMap(userRecord, ["readOnly"]);
                }
            }
        });
        // window.location.reload(false);
    }
    $scope.updateUserMap = function(userRecord, fields) {
        var userEntry = {};
        fields.forEach( function(item) {
            userEntry[item] = userRecord[item];
        });
        var postObj = {};
        postObj[userRecord.info.key] = userEntry;
        var postdata = angular.toJson(postObj);
        $scope.showError=false;
        console.log("UPDATE:", postObj);
        $http.post("SiteUserMap.json" ,postdata)
        .success( function(data) {
            console.log("RESPONSE:", data);
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

<div>

<%@include file="../jsp/ErrorPanel.jsp"%>
<div class="container-fluid override mb-4 mx-3 d-inline-flex">
    <span class="dropdown mt-1">
        <button class="btn btn-outline-secondary btn-tiny dropdown-toggle" type="button" id="dropdownInfoMenu"
            data-bs-toggle="dropdown" aria-expanded="false">
        </button>
        <ul class="dropdown-menu" aria-labelledby="dropdownInfoMenu">
            <li>
                <button class="dropdown-item" onclick="window.location.reload(true)">
                    <span class="fa fa-refresh"></span> &nbsp;Refresh
                </button>
                <span class="dropdown-item" type="button">
                    <a class="nav-link" role="menuitem" href="SiteAdmin.htm"><span class="fa fa-cogs"></span> &nbsp; Site Admin</a>
                </span>
                <span class="dropdown-item" type="button">
                    <a class="nav-link" role="menuitem" href="SiteStats.htm"><span
                    class="fa fa-line-chart"></span> &nbsp;Site Statistics</a>
                </span>
                <span class="dropdown-item" type="button">
                    <a class="nav-link" role="menuitem" href="SiteLedger.htm">
                        <span class="fa fa-money"></span> &nbsp;Site Ledger
                    </a>
                </span>
                <span class="dropdown-item" type="button">
                    <a class="nav-link" role="menuitem" tabindex="-1" href="SiteRoles.htm">
                        <span class="fa fa-group"></span> Manage Roles </a>
                </span>
                <span class="dropdown-item" type="button">
                    <a class="nav-link" role="menuitem" ng-click="recalcStats()">
                        <span class="fa fa-refresh"></span> &nbsp;Recalculate
                    </a>
                </span>
<% if (ar.isSuperAdmin()) { %>
                <span class="dropdown-item" type="button">
                    <a class="nav-link" role="menuitem" href="../../../v/su/SiteDetails.htm?siteKey=<%=siteId%>">
                        <span class="fa fa-user-secret"></span>&nbsp;Super Admin
                    </a>
                </span>
<% } %>
        </li>
        </ul>
    </span>
    <span>
        <h1 class="d-inline page-name" id="mainPageTitle">Users in Site</h1>
    </span>
</div>

    <div class="container-fluid override border-1 border-dark-subtle rounded-2 px-3 mx-3">
        <div class="row my-2 well mx-3 ">
            <div ng-hide="addUserPanel">
            <p class="h4">This site has {{activeUserCount}} / {{siteSettings.editUserLimit}} full users who can update, and {{readOnlyCount}} / {{siteSettings.viewUserLimit}} basic users.</p>
            <div ng-show="activeUserCount>siteSettings.editUserLimit" class="guideVocal"> 
                <p class="mx-2" ><b>Site has too many full users.</b>  
                    You have set a budget of  {{siteSettings.editUserLimit}} users 
                    who have full access to the site, and you have {{activeUserCount}}.  
                    You will not be able to add any new full users to the site until 
                    the users limit is raised by the Site Owner, 
                    or the number of full users is reduced.</p>
            </div>
            <div ng-show="readOnlyCount>siteSettings.viewUserLimit" class="guideVocal">
                <p  class="mx-2"><b>Site has too many basic users.</b>  
                    You are allowed {{siteSettings.viewUserLimit}} and you have {{readOnlyCount}}.<br/>
                    Any user who has never logged in to the site directly is considered an basic user. 
                    You will not be able to add any new email addresses to the site until 
                    the users limit is raised by the Site Owner.</p>
                <hr/>
                <p class="mx-2 fs-5"><em>To remove a user from this list, click on the user, and use the option to 'Completely Remove This User' at the very bottom of the page.</em></p>
            </div>
            </div>
        </div>
    </div>        
    <div class="container-fluid override border-1 border-dark-subtle rounded-2 px-5 ms-3">
        <div class="row d-flex my-3 border-1 border-dark-subtle ">
            <div class="col-1 h6">Filter by Name</div>
            <div class="col-3"><input type="text" ng-model="filter"/></div>
            <div class="col-4 h6">Primary Email</div>
            <div class="col-1 h6">Access</div>
            <div class="col-1 h6">Last Login</div>
            <div class="col-1 h6">Objects</div>
            <div class="col-1 h6">Workspaces</div>
        </div>
        <div class="row my-3" ng-repeat="value in findUsers()" ><hr>
            <div class="col-1 h6" ng-click="visitUser(value.info.uid)" >Edit:<br>
            <img class="rounded-5 p-0" src="<%=ar.retPath%>icon/{{value.info.key}}.jpg" style="width:32px;height:32px;cursor: pointer;" title="Edit User: {{value.info.name}} - {{value.info.uid}}">
        </div>
        <div class="col-3 mt-3 h6">{{value.info.name}}</div>

        <div class="col-4  mt-3">{{value.info.uid}}</div>
        <div class="col-1  mt-3">
            <span ng-show="value.readOnly">Basic User</span>
            <span class="ps-0 ms-0" ng-show="!value.readOnly"><b>Full User</b></span>
        </div>
        <div class="col-1  mt-3"><span>{{value.info.lastLogin|cdate}}</span></div>
        <div class="col-1  mt-3">{{value.count}}</div>
        <div class="col-1  mt-3">{{value.wscount}}</div>
        
    </div>
    </div>
</div>

<div class="container-fluid well mx-3">
    Set to 'Basic' all users except the 
    <input ng-model="preserveCount"/> 
    users who have most recently logged in.  
    <button class="btn btn-primary btn-raised" ng-click="demoteBatchUsers()">
        Demote Users</button>
</div>

<div class="container-fluid d-flex">
    <div class="row d-flex col-12 my-3">
        <span class="col-md-6 col-sm-12 my-3">
            <p class="guideVocal h6">Statistics are calculated on a regular bases approximately every day.  
                If you have made a change, by removing or adding things, you can recalculate the resources 
                that your site is using.</p>
            <button class="btn btn-primary btn-raised" ng-click="recalcStats()">Recalculate</button>
        </span>

        <span class="col-md-6 col-sm-12 my-3">
            <p class="guideVocal h6">In normal use of the site, deleting a resource only marks it as deleted, 
                and the resource can be recovered for a period of time. <br>In order to actually cause the 
                files to be deleted use the Garbage Collect function.  This will actually free up space on the server, 
                and reduce the amount of resources you are using.</p>
            <button class="btn btn-primary btn-raised" ng-click="garbageCollect()">Garbage Collect</button>
        </span>

    </div>
    
    
</div>

