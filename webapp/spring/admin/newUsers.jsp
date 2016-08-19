<%@page errorPage="/spring/jsp/error.jsp"
%><%@page import="org.socialbiz.cog.SuperAdminLogFile"
%><%@page import="java.io.FileInputStream"
%><%@page import="org.workcast.streams.StreamHelper"
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

    File userFolder =  ar.getCogInstance().getConfig().getFileFromRoot("users");
    for (AddressListEntry ale : UserManager.getAllUsers()) {
        UserProfile anyone = ale.getUserProfile();
        if (anyone==null) {
            continue;
        }
        String key = anyone.getKey();
        File imageFile = new File(userFolder, key+".jpg");
        if (!imageFile.exists()) {
            String lc = anyone.getName().toLowerCase();
            char ch = lc.charAt(0);
            int i=1;
            while (i<lc.length() && (ch<'a'||ch>'z')) {
                ch = lc.charAt(i);
                i++;
            }
            File fakeFile = new File(userFolder, "fake-"+ch+".jpg");
            FileInputStream is = new FileInputStream(fakeFile);
            StreamHelper.copyStreamToFile(is, imageFile);
            is.close();
        }
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


    <div class="h1">
            New Users
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

