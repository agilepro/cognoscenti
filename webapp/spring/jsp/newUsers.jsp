<%@page errorPage="/spring/jsp/error.jsp"
%><%@page import="org.socialbiz.cog.SuperAdminLogFile"
%><%@ include file="/spring/jsp/include.jsp"
%><%

    ar.assertLoggedIn("New Users page should never be accessed when not logged in");
    if (!ar.isSuperAdmin()) {
        throw new Exception("New Users page should only be accessed by Super Admin");
    }
    List<UserProfile> newUsers = ar.getSuperAdminLogFile().getAllNewRegisteredUsers();
    JSONArray allNewUsers = new JSONArray();
    for (UserProfile user : newUsers) {
        JSONObject jo = new JSONObject();
        jo.put("name", user.getName());
        jo.put("lastLogin", user.getLastLogin());
        jo.put("email", user.getPreferredEmail());
        allNewUsers.put(jo);
    }

%>
<script type="text/javascript">

var app = angular.module('myApp', ['ui.bootstrap']);
app.controller('myCtrl', function($scope, $http) {
    $scope.allNewUsers = <%allNewUsers.write(out,2,4);%>;

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


    <div class="generalHeading" style="height:40px">
        <div  style="float:left;margin-top:8px;">
            New Users
        </div>
        <div class="rightDivContent" style="margin-right:100px;">
          <span class="dropdown">
            <button class="btn btn-default dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
            Options: <span class="caret"></span></button>
            <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
              <li role="presentation"><a role="menuitem" tabindex="-1"
                  href="#" ng-click="">Do Nothing</a></li>
            </ul>
          </span>

        </div>
    </div>

        <div id="newUserDiv">
            <table class="table">
                <thead>
                    <tr>
                        <th>User Name</th>
                        <th>Registration Date</th>
                        <th>Email Id</th>

                    </tr>
                </thead>
                <tbody>
                    <tr ng-repeat="rec in allNewUsers">
                        <td>{{rec.name}}</td>
                        <td>{{rec.lastLogin | date}}</td>
                        <td>{{rec.email}}</td>
                    </tr>
                </tbody>
            </table>
        </div>
    </div>
</div>

