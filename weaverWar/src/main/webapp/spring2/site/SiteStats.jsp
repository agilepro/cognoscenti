<%@page errorPage="/spring2/jsp/error.jsp"
%><%@page import="com.purplehillsbooks.weaver.WorkspaceStats"
%><%@page import="com.purplehillsbooks.weaver.util.NameCounter"
%><%@ include file="/include.jsp"
%><%

    ar.assertLoggedIn("");
    Cognoscenti cog = ar.getCogInstance();
    String siteId = ar.reqParam("siteId");
    NGBook  site = ar.getCogInstance().getSiteByIdOrFail(siteId);
    JSONObject siteInfo = site.getConfigJSON();

    WorkspaceStats wStats = site.getRecentStats();

/*
{
  "serverTime": 1566429309440,
  "siteId": "anaxaman",
  "stats": {
    "anythingPerUser": {
      "kswenson@example.com": 7
    },
    "commentsPerUser": {},
    "docsPerUser": {},
    "meetingsPerUser": {},
    "numComments": 0,
    "numDecisions": 0,
    "numDocs": 0,
    "numMeetings": 0,
    "numProposals": 0,
    "numTopics": 0,
    "numUsers": 1,
    "numWorkspaces": 1,
    "proposalsPerUser": {},
    "responsesPerUser": {},
    "sizeArchives": 0,
    "sizeDocuments": 0,
    "topicsPerUser": {},
    "unrespondedPerUser": {}
  }
}
*/
%>

<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, AllPeople) {
    window.setMainPageTitle("Site Statistics");
    $scope.siteInfo = <%siteInfo.write(out,2,4);%>;
    $scope.siteStats = <%site.getStatsJSON(cog).write(out,2,4);%>;
    $scope.newName = $scope.siteInfo.names[0];

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };

    $scope.getStats = function() {
        var getURL = "SiteStatistics.json";
        console.log("Getting Site Statistics");
        $scope.showError=false;
        $http.get(getURL)
        .success( function(data) {
            $scope.stats = data.stats;
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };
    $scope.recalcStats = function() {
        console.log("recalcStats");
        var getURL = "SiteStatistics.json?recalc=yes";
        $scope.showError=false;
        $http.get(getURL)
        .success( function(data) {
            $scope.stats = data.stats;
            AllPeople.clearCache($scope.siteInfo.key);
            window.location.reload(false);
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };
    $scope.findFullName = function(key) {
        return AllPeople.findFullName(key, $scope.siteInfo.key);
    }
    $scope.findUserKey = function(key) {
        return AllPeople.findUserKey(key, $scope.siteInfo.key);
    }

    $scope.getStats();

});

</script>

<div>

<%@include file="../jsp/ErrorPanel.jsp"%>

<div class="container-fluid">
   <div class="row">
        <div class="col-md-auto fixed-width border-end border-1 border-secondary">
            <span class="btn btn-secondary btn-comment btn-raised m-3 pb-2 pt-0" type="button"><a class="nav-link" role="menuitem" 
             href="SiteAdmin.htm">Site Admin</a></span>
            <span class="btn btn-secondary btn-comment btn-raised m-3 pb-2 pt-0" type="button"><a class="nav-link" role="menuitem" 
             href="SiteUsers.htm">User List</a></span>
            <span class="btn btn-secondary btn-comment btn-raised m-3 pb-2 pt-0" type="button"><a class="nav-link" role="menuitem" 
             href="SiteStats.htm">Site Statistics</a></span>
            <span class="btn btn-secondary btn-comment btn-raised m-3 pb-2 pt-0" type="button"><a class="nav-link" role="menuitem"
             href="SiteLedger.htm">Site Ledger</a></span>
          <span class="btn btn-secondary btn-comment btn-raised m-3 pb-2 pt-0" type="button"><a class="nav-link" role="menuitem"
              ng-click="recalcStats()">Recalculate</a></span>
          <% if (ar.isSuperAdmin()) { %>
          <span class="btn btn-warning btn-comment btn-raised m-3 pb-2 pt-0" type="button" ><a class="nav-link" role="menuitem"
              href="../../../v/su/SiteDetails.htm?siteKey=<%=siteId%>">Super Admin</a></span>
          <% } %>
          </div>
    		<div class="d-flex col-9">
            <div class="contentColumn">
               <div class="container-fluid">
                      <div class="generalContent">
        <div class="row-cols-3 d-flex my-2 border-bottom border-1">
           <span class="col-4"></span>
           <span class="col-2 h6">Entire Site</span>
        </div>
        <div class="row-cols-3 d-flex my-2 border-bottom border-1">
           <span class="col-4 h6">Last Change:</span>
           <span class="col-2">{{siteInfo.changed|cdate}}</span>
           </div>
        <div class="row-cols-3 d-flex my-2 border-bottom border-1">
           <span class="col-4 h6">Full Users:</span>
           <span class="col-2">{{siteStats.editUserCount}}</span>
           </div>
        <div class="row-cols-3 d-flex my-2 border-bottom border-1">
           <span class="col-4 h6">Observers:</span>
           <span class="col-2">{{siteStats.readUserCount}}</span>
           </div>
        <div class="row-cols-3 d-flex my-2 border-bottom border-1">
           <span class="col-4 h6">Emails / Month:</span>
           <span class="col-2"></span>
        </div>
        <div class="row-cols-3 d-flex my-2 border-bottom border-1">
           <span class="col-4 h6">Size of Documents:</span>
           <span class="col-2">{{siteStats.sizeDocuments|number}}</span>
           </div>
        <div class="row-cols-3 d-flex my-2 border-bottom border-1">
           <span class="col-4 h6">Active Workspaces:</span>
           <span class="col-2">{{siteStats.numActive}}</span>
        </div>
        <div class="row-cols-3 d-flex my-2 border-bottom border-1">
           <span class="col-4 h6">Frozen Workspaces:</span>
           <span class="col-2">{{siteStats.numFrozen}}</span>
        </div>
        <div class="row-cols-3 d-flex my-2 border-bottom border-1">
           <span class="col-4 h6">Number of Workspaces:</span>
           <span class="col-2">{{stats.numWorkspaces}}</span>
        </div>
        <div class="row-cols-3 d-flex my-2 border-bottom border-1">
           <span class="col-4 h6">Number of Users:</span>
           <span class="col-2">{{stats.numUsers}}</span>
        </div>
        <div class="row-cols-3 d-flex my-2 border-bottom border-1">
           <span class="col-4 h6">Number of Discussions:</span>
           <span class="col-2">{{stats.numTopics}}</span>
        </div>
        <div class="row-cols-3 d-flex my-2 border-bottom border-1">
           <span class="col-4 h6">Number of Meetings:</span>
           <span class="col-2">{{stats.numMeetings}}</span>
        </div>
        <div class="row-cols-3 d-flex my-2 border-bottom border-1">
           <span class="col-4 h6">Number of Decisions:</span>
           <span class="col-2">{{stats.numDecisions}}</span>
        </div>
        <div class="row-cols-3 d-flex my-2 border-bottom border-1">
           <span class="col-4 h6">Number of Comments:</span>
           <span class="col-2">{{stats.numComments}}</span>
        </div>
        <div class="row-cols-3 d-flex my-2 border-bottom border-1">
           <span class="col-4 h6">Number of Proposals:</span>
           <span class="col-2">{{stats.numProposals}}</span>
        </div>
        <div class="row-cols-3 d-flex my-2 border-bottom border-1">
           <span class="col-4 h6">Number of Files:</span>
           <span class="col-2">{{stats.numDocs}}</span>
        </div>
        <div class="row-cols-3 d-flex my-2 border-bottom border-1">
           <span class="col-4 h6">Last WS Change:</span>
           <span class="col-2">{{stats.recentChange|cdate}}</span>
        </div>
        <div class="row-cols-3 d-flex my-2 border-bottom border-2">
           <span class="col-4 h6">Size of Old Versions:</span>
           <span class="col-2">{{stats.sizeArchives|number}} bytes</span>
        </div>

        <div class="row-cols-3 d-flex my-2 border-bottom border-1">
         <span class="col-2"></span>
         <span class="col-6 h6">User Link</span>
         <span class="col-2 h6">Amount</span>
      </div>

         <div class="row-cols-3 d-flex my-2 border-bottom border-1" ng-repeat="(key, value) in stats.topicsPerUser">
            <span class="col-2 h6">Discussions:</span>
            <span class="col-6"><a href="../../FindPerson.htm?uid={{findUserKey(key)}}">{{findFullName(key)}}</a>:</span>
            <span class="col-2">{{value}}</span>
         </div>
        <div class="row-cols-3 d-flex my-2 border-bottom border-1" ng-repeat="(key, value) in stats.docsPerUser">
           <span class="col-2 h6">Files:</span>
           <span class="col-6"><a href="../../FindPerson.htm?uid={{findUserKey(key)}}">{{findFullName(key)}}</a>:</span>
           <span class="col-2">{{value}}</span>
        </div>
        <div class="row-cols-3 d-flex my-2 border-bottom border-1" ng-repeat="(key, value) in stats.commentsPerUser">
           <span class="col-2 h6">Comments:</span>
           <span class="col-6"><a href="../../FindPerson.htm?uid={{findUserKey(key)}}">{{findFullName(key)}}</a>:</span>
           <span class="col-2">{{value}}</span>
        </div>
        <div class="row-cols-3 d-flex my-2 border-bottom border-1" ng-repeat="(key, value) in stats.meetingsPerUser">
           <span class="col-2 h6">Meetings:</span>
           <span class="col-6"><a href="../../FindPerson.htm?uid={{findUserKey(key)}}">{{findFullName(key)}}</a>:</span>
           <span class="col-2">{{value}}</span>
        </div>
        <div class="row-cols-3 d-flex my-2 border-bottom border-1" ng-repeat="(key, value) in stats.proposalsPerUser">
           <span class="col-2 h6">Proposals:</span>
           <span class="col-6"><a href="../../FindPerson.htm?uid={{findUserKey(key)}}">{{findFullName(key)}}</a>:</span>
           <span class="col-2">{{value}}</span>
        </div>
        <div class="row-cols-3 d-flex my-2 border-bottom border-1" ng-repeat="(key, value) in stats.responsesPerUser">
           <span class="col-2 h6">Responses:</span>
           <span class="col-6"><a href="../../FindPerson.htm?uid={{findUserKey(key)}}">{{findFullName(key)}}</a>:</span>
           <span class="col-2">{{value}}</span>
        </div>
        <div class="row-cols-3 d-flex my-2 border-bottom border-1" ng-repeat="(key, value) in stats.unrespondedPerUser">
           <span class="col-2 h6">Unresponded:</span>
           <span class="col-6"><a href="../../FindPerson.htm?uid={{findUserKey(key)}}">{{findFullName(key)}}</a>:</span>
           <span class="col-2">{{value}}</span>
        </div>
        <div class="row-cols-3 d-flex my-2 border-bottom border-1" ng-repeat="(key, value) in stats.anythingPerUser">
           <span class="col-2 h6">All Users:</span>
           <span class="col-6"><a href="../../FindPerson.htm?uid={{findUserKey(key)}}">{{findFullName(key)}}</a> </span>
           <span class="col-2"></span>
        </div>
        <div class="row-cols-3 d-flex my-2 border-bottom border-1" ng-repeat="(key, value) in stats.historyPerType">
           <span class="col-2 h6">History:</span>
           <span class="col-6">{{key}}:</span>
           <span>{{value}}</span>
        </div>
      </div>
    </div>
</div>

<script src="../../../jscript/AllPeople.js"></script>
