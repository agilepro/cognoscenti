<%@page errorPage="/spring/jsp/error.jsp"
%><%@page import="org.socialbiz.cog.NGRole"
%><%@page import="org.socialbiz.cog.License"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="org.socialbiz.cog.BookInfoRecord"
%><%

    ar.assertLoggedIn("");
    String accountId = ar.reqParam("accountId");
    NGBook  ngb = ar.getCogInstance().getSiteByIdOrFail(accountId);
    String pageAddress = ar.getResourceURL(ngb,"personal.htm");
    JSONObject siteInfo = new JSONObject();

%>

<script type="text/javascript">

var app = angular.module('myApp', ['ui.bootstrap']);
app.controller('myCtrl', function($scope, $http) {
    $scope.siteInfo = <%siteInfo.write(out,2,4);%>;
    $scope.sourceUser = "";
    $scope.destUser = "";
    $scope.replaceConfirm = false;

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };

    $scope.replaceUsers = function() {
        if (!$scope.replaceConfirm) {
            alert("If you want to replace the email ids, please check the confirm box");
            return;
        }
        var postObj = {};
        postObj.sourceUser = $scope.sourceUser
        postObj.destUser = $scope.destUser
        var postdata = angular.toJson(postObj);
        $scope.showError=false;
        $http.post("replaceUsers.json" ,postdata)
        .success( function(data) {
            console.log(JSON.stringify(data));
            alert("operation changed "+data.updated+" places.");
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    }
});

</script>

<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>


    <div class="generalHeading" style="height:40px">
        <div  style="float:left;margin-top:8px;">
            Site User Management
        </div>
        <div class="rightDivContent" style="margin-right:100px;">
          <span class="dropdown">
            <button class="btn btn-default dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
            Options: <span class="caret"></span></button>
            <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
              <li role="presentation"><a role="menuitem" tabindex="-1"
                  href="#" ng-click="">No Options at this Time</a></li>
            </ul>
          </span>

        </div>
    </div>

<style>
.paddedCell {
    padding:8px;
}
</style>

    <div>
        <h1>User Migration</h1>

        <table >
          <tr>
            <td class="paddedCell">Find This Email ID:</td>
            <td class="paddedCell"><input ng-model="sourceUser" class="form-control"></td>
          </tr>
          <tr>
            <td class="paddedCell">Replace With:</td>
            <td class="paddedCell"><input ng-model="destUser" class="form-control"></td>
          </tr>
          <tr>
            <td class="paddedCell"></td>
            <td class="paddedCell">
                <button ng-click="replaceUsers()" class="btn btn-primary">Replace First With Second</button>
                <input type="checkbox" ng-model="replaceConfirm"> Check here to confirm, there is no way to UNDO this change
            </td>
          </tr>
        </table>
    </div>
</div>

