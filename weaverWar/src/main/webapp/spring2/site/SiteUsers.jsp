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
    window.setMainPageTitle("List of Users in Site");
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


    <div class="container-fluid well mx-3">
        <div class="row col-12 d-flex">
            <div ng-hide="addUserPanel">
            <p class="h6 guideVocal">This site has {{activeUserCount}} / {{siteSettings.editUserLimit}} active users who can update, and {{readOnlyCount}} / {{siteSettings.viewUserLimit}} inactive users.</p>
            <div ng-show="activeUserCount>siteSettings.editUserLimit" class="guideVocal"> 
                <p ><b>Site has too many active users.</b>  You have set a budget of  {{siteSettings.editUserLimit}} users in the site who have edit access to the site, and you have {{activeUserCount}}.  You will not be able to add any new update users to the site until you reduce the number of active edit users or you change your budget amount.</p>
            </div>
            <div ng-show="readOnlyCount>siteSettings.viewUserLimit" class="guideVocal">
                <p ><b>Site has too many observers.</b>  You are allowed {{siteSettings.viewUserLimit}} and you have {{readOnlyCount}}.<br/>Any user who has never logged in to the site directly is considered an observer. You will not be able to add any new email addresses to the site until you reduce the number of observers or raise the limit set by the Site Administrator.
                    <hr/>
                To remove a user from this list, click on the user, and use the option to 'Completely Remove This User' at the very bottom of the page.</p>
            </div>
            </div>
        </div>        
    <div class="table">
        <div class="row col-12 my-3">
         <span class="col-1 h6">Filter by Name</span>
         <span class="col-2 "> <input type="text" ng-model="filter" style="height: 25px;"/></span>
         <span class="col-3 h6">Primary Email</span>
         <span class="col-1 h6">Access</span>
         <span class="col-2 h6">Last Login</span>
         <span class="col-1 h6">Objects</span>
         <span class="col-1 h6">Workspaces</span>
        </div>
        <div class="row col-12 my-3" ng-repeat="value in findUsers()" ><hr>
        <span class="col-1 h6">&nbsp;Edit:
            <img class="rounded-5 p-0" 
          ng-click="visitUser(value.info.uid)" src="<%=ar.retPath%>icon/{{value.info.key}}.jpg" 
                 style="width:32px;height:32px;cursor: pointer;" title="Edit User: {{value.info.name}} - {{value.info.uid}}">
        </span>
        <span class="col-2">{{value.info.name}}</span>

        <span class="col-3">{{value.info.uid}}</span>
        <span class="col-1">
            <span ng-show="value.readOnly">Observer</span>
            <span class="ps-0 ms-0 fs-.5" ng-show="!value.readOnly && value.lastAccess < 100000" >No Login</span>
            <span class="ps-0 ms-0" ng-show="!value.readOnly && value.lastAccess > 100000"><b>Update</b></span>
        </span>
        <span class="col-2"><span>{{value.info.lastLogin|cdate}}</span></span>
        <span class="col-1">{{value.count}}</span>
        <span class="col-1">{{value.wscount}}</span>
        
    </div>
    </div>
</div>

    <div class="container-fluid well mx-3">
        Set to 'Observer' all users except the 
        <input ng-model="preserveCount"/> 
        users who most recently logged in.  
        <button class="btn btn-primary btn-raised" ng-click="demoteBatchUsers()">
            Demote Users</button>
    </div>

<div class="container-fluid d-flex">
    <div class="row d-flex col-12 my-3">
        <span class="col-md-6 col-sm-12 my-3">
            <p class="guideVocal h6">Statistics are calculated on a regular bases approximately every day.  If you have made a change, by removing or adding things, you can recalculate the resources that your site is using.</p>
                <button class="btn btn-primary btn-raised" ng-click="recalcStats()">Recalculate</button>
        </span>

        <span class="col-md-6 col-sm-12 my-3">
            <p class="guideVocal h6">In normal use of the site, deleting a resource only marks it as deleted, and the resource can be recovered for a period of time. <br>In order to actually cause the files to be deleted use the Garbage Collect function.  This will actually free up space on the server, and reduce the amount of resources you are using.</p>
                <button class="btn btn-primary btn-raised" ng-click="garbageCollect()">Garbage Collect</button>
        </span>

    </div>
    
    
</div>

