<%@page errorPage="/spring/jsp/error.jsp"
%><%@include file="include.jsp"
%><%@page import="org.socialbiz.cog.IDRecord"
%><%@page import="org.socialbiz.cog.ConfigFile"
%><%@page import="org.socialbiz.cog.MicroProfileRecord"
%><%@page import="org.socialbiz.cog.MicroProfileMgr"
%><%

    String uid = ar.reqParam("uid");

    MicroProfileRecord mpr = MicroProfileMgr.findMicroProfileById(uid);

    JSONObject microProfile = new JSONObject();

    microProfile.put("uid", uid);
    if (mpr!=null) {
        microProfile.put("name", mpr.getDisplayName());
    }

%>

<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http) {
    window.setMainPageTitle("Find Person");
    $scope.userId = "<%ar.writeJS(uid);%>";
    $scope.microProfile = <%microProfile.write(ar.w,2,2);%>;
    $scope.userName = $scope.microProfile.name;

    $scope.saveMicro = function() {
        var postURL = "updateMicroProfile.json";
        var postdata = angular.toJson($scope.microProfile);
        $scope.showError=false;
        $http.post(postURL, postdata)
        .success( function(data) {
            $scope.microProfile = data;
            $scope.userName = data.name;
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    }

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };
});
</script>

<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

    <div>
       <p>The user with email address <b>{{userId}}</b> has never logged into the system, so we don't have a profile on record for them.</p>

       <p ng-show="userName">We have a name on record of {{userName}}, please update if that is not correct.</p>
    </div>

<style>
   .spacy tr td {
       padding:10px;
   }
   .spacy tr td input {
       width:400px;
   }
</style>

    <div class="panel panel-default" style="margin:50px;">
      <div class="panel-heading">
        Is this the right name?
      </div>
      <div class="panel-body">
        <table class="spacy">
          <tr>
            <td>
               Email Address:
            </td>
            <td>
               <input ng-model="microProfile.uid" class="form-control" disabled="true">
            </td>
          </tr>
          <tr>
            <td>
               Name:
            </td>
            <td>
               <input ng-model="microProfile.name" class="form-control">
            </td>
          </tr>
          <tr>
            <td>
            </td>
            <td>
               <button ng-click="saveMicro()" class="btn btn-primary btn-raised">Update Name</button>
            </td>
          </tr>
        </table>
      </div>
    </div>

</div>
