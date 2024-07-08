<%@page errorPage="/spring/jsp/error.jsp"
%><%@include file="/spring/jsp/include.jsp"
%><%@page import="com.purplehillsbooks.weaver.WatchRecord"
%><%@page import="com.purplehillsbooks.weaver.UserCacheMgr"
%><%

    Cognoscenti cog = ar.getCogInstance();
    JSONArray allFacilitators = new JSONArray();
    UserCacheMgr userCacheMgr = cog.getUserCacheMgr();
    for (UserProfile uProf : cog.getUserManager().getAllUserProfiles() ) {
        if (uProf.isFacilitator()) {
            
            UserCache uc = userCacheMgr.getCache(uProf.getKey());
            JSONObject obj = uProf.getJSON();
            obj.put("facilitator", uc.getFacilitatorFields());
            allFacilitators.put(obj);
        }
    }


%>

<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http) {
    window.setMainPageTitle("Facilitator List");
    $scope.allFacilitators = <%allFacilitators.write(out,2,4);%>;
    $scope.selFac = {};

    $scope.showInput = false;
    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };
    
    $scope.setRec = function(fac) {
        $scope.selFac = fac;
    }

});

</script>

<style>
label {
    width: 100px;
}
input {
    width: 300px;
}
</style>

<!-- MAIN CONTENT SECTION START -->
<div class="userPageContents">

<%@include file="../jsp/ErrorPanel.jsp"%>

<div class="col col-lg-6 col-md-6 col-sm-12" style="height:600px;overflow: auto">

    <table class="table" width="100%">
        <tr>
            <td>Name</td>
        </tr>
        <tr ng-repeat="fac in allFacilitators">
            <td>
              <a ng-click="setRec(fac)">{{fac.name}}</a>
            </td>
        </tr>
    </table>

</div>
<div class="col col-lg-6 col-md-6 col-sm-12" style="height:600px;overflow: auto">

    <div class="well">

        <div>
            <label>Name</label>
            <input ng-model="selFac.name">
        </div>
        <div>
            <label>Email</label>
            <input ng-model="selFac.uid">
        </div>
        <div>
            <label>Available</label>
            <input ng-model="selFac.facilitator.isActive">
        </div>
        <div>
            <label>Phone</label>
            <input ng-model="selFac.facilitator.phone">
        </div>
        <div>
            <label>Region</label>
            <input ng-model="selFac.facilitator.region">
        </div>
        <div>
            <label>Key</label>
            <input ng-model="selFac.key">
        </div>
    </div>

</div>

</div>
