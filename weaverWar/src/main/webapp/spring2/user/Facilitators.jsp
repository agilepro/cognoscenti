<%@page errorPage="/spring/jsp/error.jsp"
%><%@include file="/include.jsp"
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
    width: 400px;
}
</style>

<!-- MAIN CONTENT SECTION START -->
<div class="userPageContents">

<%@include file="../jsp/ErrorPanel.jsp"%>

<div class="container-fluid px-5 py-2" >

    <div class="row">
        <span class="col-3">Name</span>
    </div>
    <div class="row d-flex" ng-repeat="fac in allFacilitators">
        <span class="col-4">
          <a ng-click="setRec(fac)">{{fac.name}}</a>
        </span>
   

        <span class="well col-4 m-2">
<div class="h5 mb-2">Contact Information</div>
<br/>
        <div class="h6 mb-2" >
            <label>Name</label>
            <input ng-model="selFac.name">
        </div>
        <div class="h6 mb-2" >
            <label>Email</label>
            <input ng-model="selFac.uid">
        </div>
        <div class="h6 mb-2" >
            <label>Available</label>
            <input ng-model="selFac.facilitator.isActive">
        </div>
        <div class="h6 mb-2" >
            <label>Phone</label>
            <input ng-model="selFac.facilitator.phone">
        </div>
        <div class="h6 mb-2" >
            <label>Region</label>
            <input ng-model="selFac.facilitator.region">
        </div>
        <div class="h6 mb-2" >
            <label>Key</label>
            <input ng-model="selFac.key">
        </div>
        </span>

    </div>

</div>
