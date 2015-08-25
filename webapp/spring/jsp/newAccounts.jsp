<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%ar.assertLoggedIn("New Site page should never be accessed when not logged in");
    if (!ar.isSuperAdmin()) {
        throw new Exception("New Site page should only be accessed by Super Admin");
    }
    List<NGBook> newAccounts = ar.getSuperAdminLogFile().getAllNewSites(ar.getCogInstance());
    if (newAccounts==null) {
        throw new Exception("Program Logic Error: The 'newAccounts' object must be set up for newAccounts.jsp");
    }
    UserProfile uProf = ar.getUserProfile();

    if (uProf==null) {
        throw new Exception("Program Logic Error: The 'uProf' object must be set up for newAccounts.jsp");
    }
    JSONArray allAccount = new JSONArray();
    for (NGBook newOne : newAccounts) {
        JSONObject jo = new JSONObject();
        jo.put("name", newOne.getFullName());
        jo.put("desc", newOne.getDescription());
        allAccount.put(jo);
    }

%>
<script type="text/javascript">

var app = angular.module('myApp', ['ui.bootstrap']);
app.controller('myCtrl', function($scope, $http) {
    $scope.allAccount = <%allAccount.write(out,2,4);%>;

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
            List of newly created Sites
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

        <div id="newAccountContainer">
            <table class="table">
                <thead>
                    <tr>
                        <th>No</th>
                        <th>Site Name</th>
                        <th>Site Description</th>
                    </tr>
                </thead>
                <tbody>
                    <%
                    int i = 0;
                    for (NGBook site : newAccounts) {
                        if (site==null) {
                            throw new Exception("how did I get a null from a collection for sites?");
                        }
                        i++;
                        String accountLink = ar.baseURL + "v/" + site.getKey() + "/$/accountListProjects.htm";
                    %>
                    <tr ng-repeat="rec in allAccount">
                        <td>No</td>
                        <td><a href="link to account" title="navigate to the site">
                            {{rec.name}}
                        </a></td>
                        <td>
                            {{rec.desc}}
                        </td>
                    </tr>
                    <%
                    }
                    %>
                </tbody>
            </table>
        </div>

</div>

