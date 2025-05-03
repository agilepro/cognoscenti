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
    <div class="container-fluid override mb-4 mx-3 d-inline-flex">
        <span class="dropdown mt-1">
            <button class="btn btn-outline-secondary btn-tiny dropdown-toggle" type="button" id="dropdownInfoMenu"
                data-bs-toggle="dropdown" aria-expanded="false">
            </button>
            <ul class="dropdown-menu" aria-labelledby="dropdownInfoMenu">
                <li>
                    <button class="dropdown-item" onclick="window.location.reload(true)"><span class="fa fa-refresh"></span> &nbsp;Refresh</button>
                    <span class="dropdown-item" type="button"><a class="nav-link" role="menuitem" href="SiteAdmin.htm">
                        <span class="fa fa-cogs"></span> &nbsp; Site Admin</a></span>
                    <span class="dropdown-item" type="button">
                        <a class="nav-link" role="menuitem" href="SiteUsers.htm">
                            <span class="fa fa-users"></span> &nbsp;User List
                        </a>
                    </span>
                    <span class="dropdown-item" type="button">
                        <a class="nav-link" role="menuitem" href="SiteStats.htm">
                            <span class="fa fa-line-chart"></span> &nbsp;Site Statistics
                        </a>
                    </span>
                    <span class="dropdown-item" type="button">
                        <a class="nav-link" role="menuitem" ng-click="recalcStats()">
                            <span class="fa fa-refresh"></span> &nbsp;Recalculate
                        </a>
                    </span>
                    <% if (ar.isSuperAdmin()) { %>
                    <span class="dropdown-item" type="button">
                        <a class="nav-link" role="menuitem" href="../../../v/su/SiteDetails.htm?siteKey=<%=siteId%>">
                            <span class="fa fa-user-secret"></span> &nbsp;Super Admin
                        </a>
                    </span>
                        <% } %>
                </li>
            </ul>
        </span>
        <span>
            <h1 class="d-inline page-name">Site Ledger</h1>
        </span>
    </div>

<%@include file="../jsp/ErrorPanel.jsp"%>



<div class="container-fluid override border-1 border-dark-subtle rounded-2 px-5">
    <div class="col-12 ms-1">
        <div class="h5">Monthly Summary</div>

    
    <div class="container-fluid col-12">
    <div class="row my-2 border-bottom border-1 pb-2">
        <span class="col-3">Year / Month</span>
        <span class="col-2"></span>
        <span class="col-1">Charge</span>
        <span class="col-1">Payment</span>
        <span class="col-2">Balance</span>
    </div>
    <div class="row my-2 border-bottom border-1 pb-2" ng-repeat="month in ledgerInfo">
        <div class="row">
          <span class="col-3">
            <b>{{month.year}} / {{(month.month + "").padStart(2 ,"0")}}</b>
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
        <div class="row my-2 " ng-repeat="pay in month.payments">
          <span class="col-3">{{pay.year}} / {{(pay.month + "").padStart(2 ,"0")}} / {{(pay.day + "").padStart(2 ,"0")}}</span>
          <span class="col-2">(payment)</span>
          <span class="col-1"></span>
          <span class="col-1">{{pay.amount | currency: '$'}}</span>
        
        </div>
        <div class="row border-bottom border-1 pb-2">
          <span class="col-3">
          </span>
          <span class="col-2">(balance)</span>
          <span class="col-1">
          </span>
          <span class="col-1">
          </span>
          <span class="col-2">
            {{0.0001+month.balance | currency: '$'}}
          </span>
        </div>
    </div>
</div>

<p>
Charges accrue monthly depending upon the number of paid users and paid workspaces that you have at the time, and these charges will increase the balance.  You can make a payment at any time, and you will receive credit for the amount you pay, which will naturally reduce the balance.  If you pay more than your balance, the amount will stay in the account, and will offset future charges.
</p>
<p>
After many years of uncharges services, we started in November of 2024 to charge sites using the standard formula.  This may have caught some people off guard with people on the role they didn't need and maybe didn't want to pay for.  Change the unnecessary users to unpaid, and change the unneeded workspaces to frozen, and then write us an email explaining the situation, and we will reduce the charges to the proper amount.  
</p>
<p>
If you have been an early adopter who helped with the beta program, and submitted a review of how it worked, ask us about a special deal to reduce charges.  We appreciate the help we have received from many people, and consider you part of the foundation of the project.
</p>

<script src="../../../jscript/AllPeople.js"></script>


