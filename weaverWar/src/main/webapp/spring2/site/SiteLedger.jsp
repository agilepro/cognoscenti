<%@page errorPage="/spring2/jsp/error.jsp"
%><%@page import="com.purplehillsbooks.weaver.WorkspaceStats"
%><%@page import="com.purplehillsbooks.weaver.util.NameCounter"
%><%@page import="com.purplehillsbooks.weaver.Ledger"
%><%@ include file="/include.jsp"
%><%

    ar.assertLoggedIn("");
    String siteId = ar.reqParam("siteId");
    NGBook site = ar.getCogInstance().getSiteByIdOrFail(siteId);
    JSONObject siteInfo = site.getConfigJSON();

    Ledger ledger = site.getLedger();
    JSONArray ledgerInfo = ledger.getInfoForAllMonths();

    
%>

<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, AllPeople) {
    window.setMainPageTitle("Site Ledger");
    $scope.siteInfo = <%siteInfo.write(out,2,4);%>;
    $scope.newName = $scope.siteInfo.names[0];
    $scope.ledgerInfo = <%ledgerInfo.write(out,2,4);%>;

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
<div>

<%@include file="../jsp/ErrorPanel.jsp"%>

<div class="container-fluid override mx-3">
    <span class="btn second-menu-btn btn-wide" type="button"><a class="nav-link" role="menuitem"
            href="SiteAdmin.htm"><span class="fa fa-cogs"></span> &nbsp; Site Admin</a></span>
    <span class="btn second-menu-btn btn-wide" type="button"><a class="nav-link" role="menuitem"
            href="SiteUsers.htm"><span class="fa fa-users"></span> &nbsp;User List</a></span>
    <span class="btn second-menu-btn btn-wide" type="button"><a class="nav-link" role="menuitem"
            href="SiteStats.htm"><span class="fa fa-line-chart"></span> &nbsp;Site Statistics</a></span>
    <span class="btn second-menu-btn btn-wide" type="button"><a class="nav-link" role="menuitem"
            ng-click="recalcStats()"><span class="fa fa-refresh"></span> &nbsp;Recalculate</a></span>
    <% if (ar.isSuperAdmin()) { %>
        <span class="btn second-menu-btn btn-wide" type="button"><a class="nav-link" role="menuitem"
                href="../../../v/su/SiteDetails.htm?siteKey=<%=siteId%>"><span class="fa fa-user-secret"></span>
                &nbsp;Super Admin</a></span>
        <% } %>
            <hr class="mx-3">
</div>

<div class="container-fluid override border-1 border-dark-subtle rounded-2 px-5">
    <div class="col-12 well ms-1">
        <div class="h5">Monthly Summary</div>

    
    <div class="container-fluid col-12">
    <div class="row my-2 border-bottom border-1 pb-2">
        <span class="col-3">Year / Month</span>
        <span class="col-3">Plan</span>
        <span class="col-2"></span>
        <span class="col-1">Charge</span>
        <span class="col-1">Payment</span>
        <span class="col-2">Balance</span>
    </div>
    <div class="row my-2 border-bottom border-1 pb-2" ng-repeat="month in ledgerInfo">
      <span class="col-3">
        <b>{{month.year}} / {{(month.month + "").padStart(2 ,"0")}}</b>
      </span>
      <span class="col-3">
        {{month.plan}}
      </span>
      <span class="col-2">(charge)</span>
      <span class="col-1">
        {{0.0001+month.chargeAmt | currency: '$'}}
      </span>
      <span class="col-1">
        
      </span>
      <span class="col-2">
      </span>
    </div>
    <div class="row my-2 border-bottom border-1 pb-2" ng-repeat="pay in month.payments">
            <span class="col-3">
            </span>
                <span class="col-3">
                </span>

      <span class="col-3">{{pay.year}} / {{(pay.month + "").padStart(2 ,"0")}} / {{(pay.day + "").padStart(2 ,"0")}}</span>
      <span class="col-3">{{pay.amount | currency: '$'}}</span>
    
      </div>
    <div class="row my-2 border-bottom border-1 pb-2">
      <span class="col-3"></span>
      <span class="col-3"></span>
      <span class="col-2">(balance)</span>
      <span class="col-1"></span>
      <span class="col-1"></span>
      <span class="col-2">{{month.balance | currency: '$' }}</span>
    </div>
</div>

<script src="../../../jscript/AllPeople.js"></script>


