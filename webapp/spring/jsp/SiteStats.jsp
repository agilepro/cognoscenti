<%@page errorPage="/spring/jsp/error.jsp"
%><%@page import="org.socialbiz.cog.NGRole"
%><%@page import="org.socialbiz.cog.License"
%><%@page import="org.socialbiz.cog.WorkspaceStats"
%><%@page import="org.socialbiz.cog.util.NameCounter"
%><%@ include file="/spring/jsp/include.jsp"
%><%

    ar.assertLoggedIn("");
    String accountId = ar.reqParam("siteId");
    NGBook  ngb = ar.getCogInstance().getSiteByIdOrFail(accountId);
    JSONObject siteInfo = ngb.getConfigJSON();

    WorkspaceStats wStats = ngb.getRecentStats(ar.getCogInstance());

/*
{
  "serverTime": 1566429309440,
  "siteId": "anaxaman",
  "stats": {
    "anythingPerUser": {
      "kswenson@us.fujitsu.com": 7
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
        var getURL = "SiteStatistics.json?recalc=yes";
        $scope.showError=false;
        $http.get(getURL)
        .success( function(data) {
            $scope.stats = data.stats;
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
<style>
.spacey tr td {
    padding: 4px;
}
</style>
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
              href="SiteUsers.htm">User Migration</a></li>
          <li role="presentation"><a role="menuitem"
              href="SiteStats.htm">Site Statistics</a></li>
          <li role="presentation"><a role="menuitem"
              ng-click="recalcStats()">Recalculate</a></li>
        </ul>
      </span>
    </div>


    <div class="generalContent">
        <table class="table">
        <tr>
           <td>Number of Topics:</td>
           <td>{{stats.numTopics}}</td>
        </tr>
        <tr>
           <td>Number of Meetings:</td>
           <td>{{stats.numMeetings}}</td>
        </tr>
        <tr>
           <td>Number of Decisions:</td>
           <td>{{stats.numDecisions}}</td>
        </tr>
        <tr>
           <td>Number of Comments:</td>
           <td>{{stats.numComments}}</td>
        </tr>
        <tr>
           <td>Number of Proposals:</td>
           <td>{{stats.numProposals}}</td>
        </tr>
        <tr>
           <td>Number of Documents:</td>
           <td>{{stats.numDocs}}</td>
        </tr>
        <tr>
           <td>Size of Documents:</td>
           <td>{{stats.sizeDocuments|number}}</td>
        </tr>
        <tr>
           <td>Number of Old Versions:</td>
           <td>{{stats.sizeArchives|number}}</td>
        </tr>
        <tr>
           <td>Topics:</td>
           <td>
               <table class="spacey">
                 <tr ng-repeat="(key, value) in stats.topicsPerUser">
                   <td><a href="../../FindPerson.htm?uid={{findUserKey(key)}}">{{findFullName(key)}}</a>:
                   <td>{{value}}</td>
                 </tr>
               </table>
           </td>
        </tr>
        </tr>
        <tr>
           <td>Documents:</td>
           <td>
               <table class="spacey">
                 <tr ng-repeat="(key, value) in stats.docsPerUser">
                   <td><a href="../../FindPerson.htm?uid={{findUserKey(key)}}">{{findFullName(key)}}</a>:
                   <td>{{value}}</td>
                 </tr>
               </table>
           </td>
        </tr>
        </tr>
        <tr>
           <td>Comments:</td>
           <td>
               <table class="spacey">
                 <tr ng-repeat="(key, value) in stats.commentsPerUser">
                   <td><a href="../../FindPerson.htm?uid={{findUserKey(key)}}">{{findFullName(key)}}</a>:
                   <td>{{value}}</td>
                 </tr>
               </table>
           </td>
        </tr>
        <tr>
           <td>Meetings:</td>
           <td>
               <table class="spacey">
                 <tr ng-repeat="(key, value) in stats.meetingsPerUser">
                   <td><a href="../../FindPerson.htm?uid={{findUserKey(key)}}">{{findFullName(key)}}</a>:
                   <td>{{value}}</td>
                 </tr>
               </table>
           </td>
        </tr>
        <tr>
           <td>Proposals:</td>
           <td>
               <table class="spacey">
                 <tr ng-repeat="(key, value) in stats.proposalsPerUser">
                   <td><a href="../../FindPerson.htm?uid={{findUserKey(key)}}">{{findFullName(key)}}</a>:
                   <td>{{value}}</td>
                 </tr>
               </table>
           </td>
        </tr>
        <tr>
           <td>Responses:</td>
           <td>
               <table class="spacey">
                 <tr ng-repeat="(key, value) in stats.responsesPerUser">
                   <td><a href="../../FindPerson.htm?uid={{findUserKey(key)}}">{{findFullName(key)}}</a>:
                   <td>{{value}}</td>
                 </tr>
               </table>
           </td>
        </tr>
        <tr>
           <td>Unresponded:</td>
           <td>
               <table class="spacey">
                 <tr ng-repeat="(key, value) in stats.unrespondedPerUser">
                   <td><a href="../../FindPerson.htm?uid={{findUserKey(key)}}">{{findFullName(key)}}</a>:
                   <td>{{value}}</td>
                 </tr>
               </table>
           </td>
        </tr>
        <tr>
           <td>All Users:</td>
           <td>
               <table class="spacey">
                 <tr ng-repeat="(key, value) in stats.anythingPerUser">
                   <td><a href="../../FindPerson.htm?uid={{findUserKey(key)}}">{{findFullName(key)}}</a>: </td>
                   <td>{{value}}</td>
                 </tr>
               </table>
           </td>
        </tr>
        </table>
    </div>
</div>

<script src="../../../jscript/AllPeople.js"></script>
