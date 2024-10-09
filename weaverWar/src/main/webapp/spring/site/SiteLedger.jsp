<%@page errorPage="/spring/jsp/error.jsp"
%><%@page import="com.purplehillsbooks.weaver.License"
%><%@page import="com.purplehillsbooks.weaver.WorkspaceStats"
%><%@page import="com.purplehillsbooks.weaver.util.NameCounter"
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


    <h2>Monthly Summary</h2>
    <table class="table">
    <tr>
        <td>Year / Month</td>
        <td>Plan</td>
        <td></td>
        <td>Charge</td>
        <td>Payment</td>
        <td>Balance Owed</td>
    </tr>
    <tbody ng-repeat="month in ledgerInfo">
      <tr>
        <td><b>{{month.year}} / {{(month.month + "").padStart(2 ,"0")}}</b></td>
        <td>{{month.plan}}</td>
        <td>(charge)</td>
        <td>{{0.0001+month.chargeAmt | currency: '$'}}</td>
        <td></td>
        <td></td>
      </tr>
      <tr ng-repeat="pay in month.payments">
        <td></td>
        <td></td>
        <td>{{pay.year}} / {{(pay.month + "").padStart(2 ,"0")}} / {{(pay.day + "").padStart(2 ,"0")}}</td>
        <td></td>
        <td>{{pay.amount | currency: '$'}}</td>
        <td></td>
      </tr>
      <tr>
        <td></td>
        <td></td>
        <td>(balance)</td>
        <td></td>
        <td></td>
        <td>{{month.balance | currency: '$' }}</td>
      </tr>
    </tbody>
    </table>


<pre>
{{ledgerInfo|json}}
</pre>
</div>
<script src="../../../jscript/AllPeople.js"></script>


