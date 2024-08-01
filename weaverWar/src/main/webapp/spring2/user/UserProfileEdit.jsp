<%@page errorPage="/spring2/jsp/error.jsp"
%><%@ include file="/spring2/jsp/include.jsp"
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


<div>

<%@include file="../jsp/ErrorPanel.jsp"%>

<div class="container-fluid">
    <div class="row">
            <span class="col-2 m-3" style="cursor: pointer;">
                <button class="btn btn-secondary btn-raised btn-comment btn-wide py-1" ng-click="exit()">Return to Profile</button>
            </span>
        </div>
        <div class=" m-3">
        <div class="row-cols-3 d-flex  m-3">
            <span class="col-2 h5">Time Zone:</span>
            <span class="col-4 p-0 m-0">
                
                <div class="form-inline">
                    Currently set to: <b>{{profile.timeZone}}</b>
                </div>
            </span>
            <span class="col-2 align-top"><div>
                <button class="btn btn-primary btn-raised" ng-click="updatePersonal()">Update Time Zone</button>
            </div></span>
            </div>
            <div class="row-cols-2 d-flex m-3 well">
                <span class="col-6 form-inline"><span class="h6 ">
                    Filter:</span> <input ng-model="tzFilter" class="form-control mb-3" style="width:200px"/><span class="h5">
                    Enter a few letters of the time zone you need.
                </span></span>
                <span class="d-block col-6">
                    <div class="my-2 border-1 border-bottom border-secondary border-opacity-50" ng-repeat="item in filteredTimeZones()">
                    <b>{{item}}</b> <button ng-click="selectTimeZone(item)" class="btn btn-sm btn-primary btn-raised py-1">Select</button> 
                    </div>
                </span>
            </div>

            
    </div>
    <hr/>

    <% if (isSuperAdmin) { %>
    <div class="container-fluid mx-4">
    <span class="h5">Admin Only Functions</span>
        <div class="container-fluid">
            <div class="row-cols-3 d-flex  m-3">
                <span class="col-2">New Email:</span>
                <span class="col-4"><input type="text" class="form-control" ng-model="newEmail" /></span>
            </div>
            <div class="row-cols-3 d-flex  m-3">
                <span ></span>
                <span>
                    <button class="btn btn-primary btn-raised" ng-click="addEmail()">Add Email</button>
                </span>
            </div>
        </div>
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

