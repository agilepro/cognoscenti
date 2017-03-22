<%@page errorPage="/spring/jsp/error.jsp"
%><%@page import="java.io.FileInputStream"
%><%@page import="org.workcast.streams.StreamHelper"
%><%@ include file="/spring/jsp/include.jsp"
%><%

    ar.assertLoggedIn("New Users page should never be accessed when not logged in");
    if (!ar.isSuperAdmin()) {
        throw new Exception("New Users page should only be accessed by Super Admin");
    }
    JSONArray allNewUsers = new JSONArray();
    for (UserProfile user : UserManager.getStaticUserManager().getAllUserProfiles()) {
        allNewUsers.put(user.getFullJSON());
    }

    File userFolder =  ar.getCogInstance().getConfig().getFileFromRoot("users");
    for (UserProfile anyone : UserManager.getStaticUserManager().getAllUserProfiles()) {
        String key = anyone.getKey();
        File imageFile = new File(userFolder, key+".jpg");
        if (!imageFile.exists()) {
            String lc = anyone.getName().toLowerCase();
            char ch = ' ';
            int i=0;
            while (i<lc.length() && (ch<'a'||ch>'z')) {
                ch = lc.charAt(i);
                i++;
            }
            if (ch<'a'||ch>'z') {
                //this will be the name of the question mark image
                ch = '~';
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
    
    $scope.updateServer = function(newProfile) {
        console.log("UPDATE PROFILE WITH", newProfile);
        var postURL = "../"+newProfile.key+"/updateProfile.json";
        $http.post(postURL, JSON.stringify(newProfile))
        .success( function(data) {
            var newList = [];
            $scope.allNewUsers.forEach( function(item) {
                if (item.key == newProfile.key) {
                    newList.push(data);
                }
                else {
                    newList.push(item);
                }
            });
            $scope.allNewUsers = newList;
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    }
    
    $scope.toggleDisabled = function(profile) {
        var newProfile = {};
        newProfile.key = profile.key;
        newProfile.disabled = !profile.disabled;
        $scope.updateServer(newProfile);
    }

});

</script>
<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

    <div class="h1">
            All Users
    </div>
    
    <div>
        <table class="table">
            <thead>
                <tr>
                    <th>User Name</th>
                    <th>Registration Date</th>
                    <th>Email</th>
                    <th>Disabled</th>
                    <th>Key</th>
                </tr>
            </thead>
            <tbody>
                <tr ng-repeat="rec in allNewUsers" ng-click="window.alert(rec)">
                    <td><a href="../../v/FindPerson.htm?uid={{rec.uid}}">{{rec.name}}</a></td>
                    <td>{{rec.lastLogin | date}}</td>
                    <td>{{rec.uid}}</td>
                    <td>
                        <button ng-hide="rec.disabled" style="background-color:lightgreen" ng-click="toggleDisabled(rec)">Disable</span>
                        <button ng-show="rec.disabled" style="background-color:pink" ng-click="toggleDisabled(rec)">Reenable</span>
                    </td>
                    <td>{{rec.key}}</td>
                </tr>
            </tbody>
        </table>
    </div>
</div>

