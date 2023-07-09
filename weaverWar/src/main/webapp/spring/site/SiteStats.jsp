<%@page errorPage="/spring/jsp/error.jsp"
%><%@page import="com.purplehillsbooks.weaver.NGRole"
%><%@page import="com.purplehillsbooks.weaver.License"
%><%@page import="com.purplehillsbooks.weaver.WorkspaceStats"
%><%@page import="com.purplehillsbooks.weaver.util.NameCounter"
%><%@ include file="/spring/jsp/include.jsp"
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
<style>
.spaceyTable {
    min-width:800px;
    max-width:1000px;
}
.spaceyTable tr td {
    padding:8px;
    border-bottom: 1px solid #ddd;
}
.spaceyTable tr:hover {
    background-color: #f5f5f5;
}
.centeredCell {
    text-align:center;
}
</style>
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


    <div class="generalContent">
        <table class="spaceyTable">
        <tr>
           <td class="centeredCell"></td>
           <td class="centeredCell">Entire Site</td>
           <td class="centeredCell">Site Limit</td>
        </tr>
        <tr>
           <td>Last Change:</td>
           <td class="centeredCell">{{siteInfo.changed|cdate}}</td>
           <td class="centeredCell"></td>
        </tr>
        <tr>
           <td>Full Users:</td>
           <td class="centeredCell">{{siteStats.editUserCount}}</td>
           <td class="centeredCell">{{siteInfo.editUserLimit}}</td>
        </tr>
        <tr>
           <td>Read-only Users:</td>
           <td class="centeredCell">{{siteStats.readUserCount}}</td>
           <td class="centeredCell">{{siteInfo.viewUserLimit}}</td>
        </tr>
        <tr>
           <td>Emails / Month:</td>
           <td class="centeredCell"></td>
           <td class="centeredCell">{{siteInfo.emailLimit}}</td>
        </tr>
        <tr>
           <td>Size of Documents:</td>
           <td class="centeredCell">{{siteStats.sizeDocuments|number}}</td>
           <td class="centeredCell">{{siteInfo.fileSpaceLimit*1000000|number}}</td>
        </tr>
        <tr>
           <td>Active Workspaces:</td>
           <td class="centeredCell">{{siteStats.numActive}}</td>
           <td class="centeredCell">{{siteInfo.workspaceLimit}}</td>
        </tr>
        <tr>
           <td>Frozen Workspaces:</td>
           <td class="centeredCell">{{siteStats.numFrozen}}</td>
           <td class="centeredCell">{{siteInfo.frozenLimit}}</td>
        </tr>
        <tr>
           <td>Number of Workspaces:</td>
           <td class="centeredCell">{{stats.numWorkspaces}}</td>
           <td class="centeredCell"></td>
        </tr>
        <tr>
           <td>Number of Users:</td>
           <td class="centeredCell">{{stats.numUsers}}</td>
           <td class="centeredCell"></td>
        </tr>
        <tr>
           <td>Number of Topics:</td>
           <td class="centeredCell">{{stats.numTopics}}</td>
           <td class="centeredCell"></td>
        </tr>
        <tr>
           <td>Number of Meetings:</td>
           <td class="centeredCell">{{stats.numMeetings}}</td>
           <td class="centeredCell"></td>
        </tr>
        <tr>
           <td>Number of Decisions:</td>
           <td class="centeredCell">{{stats.numDecisions}}</td>
           <td class="centeredCell"></td>
        </tr>
        <tr>
           <td>Number of Comments:</td>
           <td class="centeredCell">{{stats.numComments}}</td>
           <td class="centeredCell"></td>
        </tr>
        <tr>
           <td>Number of Proposals:</td>
           <td class="centeredCell">{{stats.numProposals}}</td>
           <td class="centeredCell"></td>
        </tr>
        <tr>
           <td>Number of Documents:</td>
           <td class="centeredCell">{{stats.numDocs}}</td>
           <td class="centeredCell"></td>
        </tr>
        <tr>
           <td>Last WS Change:</td>
           <td class="centeredCell">{{stats.recentChange|cdate}}</td>
           <td class="centeredCell"></td>
        </tr>
        <tr>
           <td>Size of Old Versions:</td>
           <td class="centeredCell">{{stats.sizeArchives|number}} bytes</td>
           <td class="centeredCell"></td>
        </tr>
      </table>
      <table class="spaceyTable">
        <tr ng-repeat="(key, value) in stats.topicsPerUser">
           <td>Topics:</td>
           <td class="centeredCell"><a href="../../FindPerson.htm?uid={{findUserKey(key)}}">{{findFullName(key)}}</a>:
           <td class="centeredCell">{{value}}</td>
        </tr>
        <tr ng-repeat="(key, value) in stats.docsPerUser">
           <td>Documents:</td>
           <td class="centeredCell"><a href="../../FindPerson.htm?uid={{findUserKey(key)}}">{{findFullName(key)}}</a>:</td>
           <td class="centeredCell">{{value}}</td>
        </tr>
        <tr ng-repeat="(key, value) in stats.commentsPerUser">
           <td>Comments:</td>
           <td class="centeredCell"><a href="../../FindPerson.htm?uid={{findUserKey(key)}}">{{findFullName(key)}}</a>:</td>
           <td class="centeredCell">{{value}}</td>
        </tr>
        <tr ng-repeat="(key, value) in stats.meetingsPerUser">
           <td>Meetings:</td>
           <td class="centeredCell"><a href="../../FindPerson.htm?uid={{findUserKey(key)}}">{{findFullName(key)}}</a>:</td>
           <td class="centeredCell">{{value}}</td>
        </tr>
        <tr ng-repeat="(key, value) in stats.proposalsPerUser">
           <td>Proposals:</td>
           <td class="centeredCell"><a href="../../FindPerson.htm?uid={{findUserKey(key)}}">{{findFullName(key)}}</a>:</td>
           <td class="centeredCell">{{value}}</td>
        </tr>
        <tr ng-repeat="(key, value) in stats.responsesPerUser">
           <td>Responses:</td>
           <td class="centeredCell"><a href="../../FindPerson.htm?uid={{findUserKey(key)}}">{{findFullName(key)}}</a>:
           <td class="centeredCell">{{value}}</td>
        </tr>
        <tr ng-repeat="(key, value) in stats.unrespondedPerUser">
           <td>Unresponded:</td>
           <td class="centeredCell"><a href="../../FindPerson.htm?uid={{findUserKey(key)}}">{{findFullName(key)}}</a>:
           <td class="centeredCell">{{value}}</td>
        </tr>
        <tr ng-repeat="(key, value) in stats.anythingPerUser">
           <td>All Users:</td>
           <td class="centeredCell"><a href="../../FindPerson.htm?uid={{findUserKey(key)}}">{{findFullName(key)}}</a> </td>
           <td class="centeredCell"></td>
        </tr>
        <tr ng-repeat="(key, value) in stats.historyPerType">
           <td>History:</td>
           <td class="centeredCell">{{key}}:
           <td class="centeredCell">{{value}}</td>
        </tr>
        </table>
    </div>
</div>

<script src="../../../jscript/AllPeople.js"></script>
