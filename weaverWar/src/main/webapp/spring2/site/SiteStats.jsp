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

<div class="container-fluid override mb-4 mx-3 d-inline-flex">
   <span class="dropdown mt-1">
      <button class="btn btn-outline-secondary btn-tiny dropdown-toggle" type="button" id="dropdownInfoMenu"
         data-bs-toggle="dropdown" aria-expanded="false">
      </button>
      <ul class="dropdown-menu" aria-labelledby="dropdownInfoMenu">
         <li>
            <button class="dropdown-item" onclick="window.location.reload(true)"><span class="fa fa-refresh"></span>
               &nbsp;Refresh</button>
            <span class="dropdown-item" type="button"><a class="nav-link" role="menuitem" href="SiteAdmin.htm">
                  <span class="fa fa-cogs"></span> &nbsp; Site Admin</a></span>
            <span class="dropdown-item" type="button">
               <a class="nav-link" role="menuitem" href="SiteUsers.htm">
                  <span class="fa fa-users"></span> &nbsp;User List </a>
            </span>
            <span class="dropdown-item" type="button">
               <a class="nav-link" role="menuitem" href="SiteLedger.htm">
                  <span class="fa fa-money"></span> &nbsp;Site Ledger </a>
            </span>
            <span class="dropdown-item" type="button">
               <a class="nav-link" role="menuitem" ng-click="recalcStats()">
                  <span class="fa fa-refresh"></span> &nbsp;Recalculate </a>
            </span>
            <% if (ar.isSuperAdmin()) { %>
               <span class="dropdown-item" type="button">
                  <a class="nav-link" role="menuitem" href="../../../v/su/SiteDetails.htm?siteKey=<%=siteId%>">
                     <span class="fa fa-user-secret"></span> &nbsp;Super Admin </a>
               </span>
               <% } %>
         </li>
      </ul>
   </span>
   <span>
      <h1 class="d-inline page-name">Site Statistics</h1>
   </span>
</div>
   <div class="row d-flex mx-2">
    	<div class="col-5 container-fluid override border-1 border-dark-subtle rounded-2 well px-5" style="height: fit-content;">
        <div class="row my-2 border-bottom border-1 pb-2">
           <span class="col-5"></span>
           <span class="col-7 h6">Entire Site</span>
        </div>
        <div class="row my-2 border-bottom border-1 pb-2">
           <span class="col-5 h6">Last Change:</span>
           <span class="col-5">{{siteInfo.changed|cdate}}</span>
           </div>
        <div class="row my-2 border-bottom border-1 pb-2">
           <span class="col-5 h6">Full Users:</span>
           <span class="col-5">{{siteStats.editUserCount}}</span>
           </div>
        <div class="row my-2 border-bottom border-1 pb-2">
           <span class="col-5 h6">Basic Users:</span>
           <span class="col-5">{{siteStats.readUserCount}}</span>
           </div>
        <div class="row my-2 border-bottom border-1 pb-2">
           <span class="col-5 h6">Emails / Month:</span>
           <span class="col-5"></span>
        </div>
        <div class="row my-2 border-bottom border-1 pb-2">
           <span class="col-5 h6">Size of Documents:</span>
           <span class="col-5">{{siteStats.sizeDocuments|number}}</span>
        </div>
        <div class="row my-2 border-bottom border-1 pb-2">
           <span class="col-5 h6">Active Workspaces:</span>
           <span class="col-5">{{siteStats.numActive}}</span>
        </div>
        <div class="row my-2 border-bottom border-1 pb-2">
           <span class="col-5 h6">Frozen Workspaces:</span>
           <span class="col-5">{{siteStats.numFrozen}}</span>
        </div>
        <div class="row my-2 border-bottom border-1 pb-2">
           <span class="col-5 h6">Number of Workspaces:</span>
           <span class="col-5">{{stats.numWorkspaces}}</span>
        </div>
        <div class="row my-2 border-bottom border-1 pb-2">
           <span class="col-5 h6">Number of Users:</span>
           <span class="col-5">{{stats.numUsers}}</span>
        </div>
        <div class="row my-2 border-bottom border-1 pb-2">
           <span class="col-5 h6">Number of Discussions:</span>
           <span class="col-5">{{stats.numTopics}}</span>
        </div>
        <div class="row my-2 border-bottom border-1 pb-2">
           <span class="col-5 h6">Number of Meetings:</span>
           <span class="col-5">{{stats.numMeetings}}</span>
        </div>
        <div class="row my-2 border-bottom border-1 pb-2">
           <span class="col-5 h6">Number of Decisions:</span>
           <span class="col-5">{{stats.numDecisions}}</span>
        </div>
        <div class="row my-2 border-bottom border-1 pb-2">
           <span class="col-5 h6">Number of Comments:</span>
           <span class="col-5">{{stats.numComments}}</span>
        </div>
        <div class="row my-2 border-bottom border-1 pb-2">
           <span class="col-5 h6">Number of Proposals:</span>
           <span class="col-5">{{stats.numProposals}}</span>
        </div>
        <div class="row my-2 border-bottom border-1 pb-2">
           <span class="col-5 h6">Number of Files:</span>
           <span class="col-5">{{stats.numDocs}}</span>
        </div>
        <div class="row my-2 border-bottom border-1 pb-2">
           <span class="col-5 h6">Last WS Change:</span>
           <span class="col-5">{{stats.recentChange|cdate}}</span>
        </div>
        <div class="row my-2">
           <span class="col-5 h6">Size of Old Versions:</span>
           <span class="col-5">{{stats.sizeArchives|number}} bytes</span>
        </div>
      </div>
      <div class="col-6 container-fluid override">
         <div class="container border-1 border-dark-subtle rounded-2 well px-5 me-2">  
         <div class="row-cols-3 d-flex my-2 border-bottom border-1">
            <span class="col-3"></span>
            <span class="col-6 h6">User Link</span>
            <span class="col-2 h6 centered">Amount</span>
         </div>

         <div class="row-cols-3 d-flex my-2 border-bottom border-1" ng-repeat="(key, value) in stats.topicsPerUser">
            <span class="col-3 h6">Discussions:</span>
            <span class="col-7"><a href="../../FindPerson.htm?uid={{findUserKey(key)}}">{{findFullName(key)}}</a>:</span>
            <span class="col-2">{{value}}</span>
         </div>
        <div class="row-cols-3 d-flex my-2 border-bottom border-1" ng-repeat="(key, value) in stats.docsPerUser">
           <span class="col-3 h6">Files:</span>
           <span class="col-7"><a href="../../FindPerson.htm?uid={{findUserKey(key)}}">{{findFullName(key)}}</a>:</span>
           <span class="col-2">{{value}}</span>
        </div>
        <div class="row-cols-3 d-flex my-2 border-bottom border-1" ng-repeat="(key, value) in stats.commentsPerUser">
           <span class="col-3 h6">Comments:</span>
           <span class="col-7"><a href="../../FindPerson.htm?uid={{findUserKey(key)}}">{{findFullName(key)}}</a>:</span>
           <span class="col-2">{{value}}</span>
        </div>
        <div class="row-cols-3 d-flex my-2 border-bottom border-1" ng-repeat="(key, value) in stats.meetingsPerUser">
           <span class="col-3 h6">Meetings:</span>
           <span class="col-7"><a href="../../FindPerson.htm?uid={{findUserKey(key)}}">{{findFullName(key)}}</a>:</span>
           <span class="col-2">{{value}}</span>
        </div>
        <div class="row-cols-3 d-flex my-2 border-bottom border-1" ng-repeat="(key, value) in stats.proposalsPerUser">
           <span class="col-3 h6">Proposals:</span>
           <span class="col-7"><a href="../../FindPerson.htm?uid={{findUserKey(key)}}">{{findFullName(key)}}</a>:</span>
           <span class="col-2">{{value}}</span>
        </div>
        <div class="row-cols-3 d-flex my-2 border-bottom border-1" ng-repeat="(key, value) in stats.responsesPerUser">
           <span class="col-3 h6">Responses:</span>
           <span class="col-7"><a href="../../FindPerson.htm?uid={{findUserKey(key)}}">{{findFullName(key)}}</a>:</span>
           <span class="col-2">{{value}}</span>
        </div>
        <div class="row-cols-3 d-flex my-2 border-bottom border-1" ng-repeat="(key, value) in stats.unrespondedPerUser">
           <span class="col-3 h6">Unresponded:</span>
           <span class="col-7"><a href="../../FindPerson.htm?uid={{findUserKey(key)}}">{{findFullName(key)}}</a>:</span>
           <span class="col-2">{{value}}</span>
        </div>
         </div>
         <div class="container border-1 border-dark-subtle rounded-2 well px-5 me-2">
<!-- Do we need a list of users?
            <div class="row-cols-3 d-flex my-2 border-bottom border-1" ng-repeat="(key, value) in stats.anythingPerUser">
         <span class="col-3 h6">All Users:</span>
         <span class="col-7"><a href="../../FindPerson.htm?uid={{findUserKey(key)}}">{{findFullName(key)}}</a> </span>
         <span class="col-2"></span>
            </div>-->
            <div class="row-cols-3 d-flex my-2 border-bottom border-1">
               <span class="col-3"></span>
               <span class="col-6 h6">User Link</span>
               <span class="col-2 h6 centered">Amount</span>
            </div>
            <div class="row-cols-3 d-flex my-2 border-bottom border-1" ng-repeat="(key, value) in stats.historyPerType">
         <span class="col-3 h6">History:</span>
         <span class="col-7">{{key}}:</span>
         <span>{{value}}</span>
         </div>
      </div>
      </div>
   </div>   
</div>
<script src="../../../jscript/AllPeople.js"></script>
