<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="com.purplehillsbooks.weaver.UserManager"
%><%@page import="com.purplehillsbooks.weaver.UserProfile"
%><%@page import="java.util.TimeZone"
%><%

// %)(%@ include file="functions.jsp"

    ar.assertLoggedIn("Can't edit a user's profile.");
    UserProfile uProf = findSpecifiedUserOrDefault(ar);
    UserProfile runningUser = ar.getUserProfile();
    boolean isSuperAdmin = ar.isSuperAdmin();

    //the following should be impossible since above log-in is checked.
    if (uProf == null) {
        throw new Exception("Must be logged in to edit a user's profile.");
    }
    boolean selfEdit = uProf.getKey().equals(runningUser.getKey());
    if (!selfEdit) {
        //there is one super user who is allowed to edit other user profiles
        //that user is specified in the system properties -- by KEY
        if (!isSuperAdmin) {
            throw new Exception("User "+runningUser.getName()
                +" is not allowed to edit the profile of user "+uProf.getName());
        }
    }
    
    JSONObject userObj = uProf.getFullJSON();

    String photoSource = ar.retPath+"assets/photoThumbnail.gif";
    String imagePath = uProf.getImage();
    if(imagePath!=null && imagePath.length() > 0){
        photoSource = ar.retPath+"icon/"+imagePath;
    }
    Object errMsg = session.getAttribute("error-msg");
    
    JSONArray timeZoneList = new JSONArray();
    for (String tz : TimeZone.getAvailableIDs()) {
        timeZoneList.put(tz);
    }

%>

<script type="text/javascript">
var myApp = angular.module('myApp');
myApp.controller('myCtrl', function($scope, $http) {
    window.setMainPageTitle("Edit Your Profile");
    $scope.profile = <%userObj.write(out,2,4);%>;
    $scope.timeZoneList = <%timeZoneList.write(out,2,4);%>;
    
    $scope.myTimeZone = Intl.DateTimeFormat().resolvedOptions().timeZone;

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };

    
    $scope.updatePersonal = function() {
        var newProfile = {};
        newProfile.name = $scope.profile.name;
        newProfile.description = $scope.profile.description;
        newProfile.notifyPeriod = $scope.profile.notifyPeriod;
        newProfile.timeZone = $scope.profile.timeZone;
        $scope.updateServer(newProfile);
    }
    $scope.updateServer = function(newProfile) {
        console.log("UPDATE PROFILE WITH", newProfile);
        var postURL = "updateProfile.json";
        $http.post(postURL, JSON.stringify(newProfile))
        .success( function(data) {
            //$scope.profile = data;
            window.location='UserSettings.htm';
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    }
    $scope.exit = function() {
        window.location='UserSettings.htm';
    }
    
    $scope.addEmail = function() {
        var newProfile = {};
        newProfile.preferred = $scope.newEmail;
        $scope.updateServer(newProfile);
    }
    $scope.filteredTimeZones = function() {
        if (!$scope.tzFilter) {
            return $scope.timeZoneList.slice(0,8);
        }
        var rez = [];
        var filterList = parseLCList($scope.tzFilter);
        $scope.timeZoneList.forEach( function(item) {
            var found = true;
            var lcItem = item.toLowerCase();
            filterList.forEach( function(filterTerm) {
                if (lcItem.indexOf(filterTerm)<0) {
                    found = false;
                }
            });
            if (found) {
                rez.push(item);
            }
        });
        if (rez.length>8) {
            rez = rez.slice(0,8);
        }
        return rez;
    }
    $scope.selectTimeZone = function(newTimeZone) {
        $scope.profile.timeZone = newTimeZone;
        var newProfile = {};
        newProfile.key = $scope.profile.key;
        newProfile.timeZone = newTimeZone;
        $scope.updateServer(newProfile);
    }
});

</script>


<style>
.spacey {
    max-width:600px;
}
.spacey tr td {
    padding:3px;
}
.firstcol {
    width:130px;
}
</style>


<div>

<%@include file="../jsp/ErrorPanel.jsp"%>



    <table class="spacey table">
        <tr>
            <td class="firstcol"></td>
            <td colspan="2">
                <button class="btn btn-warning btn-raised" ng-click="exit()">Return to Profile</button>
            </td>
        </tr>
        <tr>
            <td class="firstcol">Time Zone:</td>
            <td>
                <div>
                    <button class="btn btn-primary btn-raised" ng-click="updatePersonal()">Update Time Zone</button>
                </div>
                <div class="form-inline">
                    Currently set to: <b>{{profile.timeZone}}</b>
                </div>
                <div class="form-inline">
                    Filter: <input ng-model="tzFilter" class="form-control" style="width:200px"/>
                    Enter a few letters of the time zone you need.
                </div>
                <div ng-repeat="item in filteredTimeZones()">
                    <b>{{item}}</b> <button ng-click="selectTimeZone(item)" class="btn btn-sm btn-default btn-raised">Select</button> 
                </div>
            </td>
        </tr>
    </table>
    <hr/>

    <% if (isSuperAdmin) { %>
    <div class="well">
    <h1>Admin Only Functions</h1>
        <table class="spacey">
            <tr>
                <td class="firstcol">New Email:</td>
                <td><input type="text" class="form-control" ng-model="newEmail" /></td>
            </tr>
            <tr>
                <td class="firstcol"></td>
                <td>
                    <button class="btn btn-primary btn-raised" ng-click="addEmail()">Add Email</button>
                </td>
            </tr>
        </table>
    </div>
    <% } %>
</div>

<%!

    public UserProfile findSpecifiedUserOrDefault(AuthRequest ar) throws Exception {
        String userKey = ar.reqParam("userKey");
        UserProfile up = UserManager.getUserProfileByKey(userKey);
        if (up==null) {
            Thread.sleep(3000);
            throw new NGException("nugen.exception.user.not.found.invalid.key",new Object[]{userKey});
        }
        return up;
    }

%>

