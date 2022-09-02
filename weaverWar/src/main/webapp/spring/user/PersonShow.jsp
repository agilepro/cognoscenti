<%@page errorPage="/spring/jsp/error.jsp"
%><%@include file="include.jsp"
%><%@page import="com.purplehillsbooks.weaver.ConfigFile"
%><%

    boolean isLoggedIn = ar.isLoggedIn();
    Cognoscenti cog = ar.getCogInstance();
    
    String userKey = ar.reqParam("userKey");
    UserProfile uProf = cog.getUserManager().getUserProfileOrFail(userKey);
    UserCache uc = cog.getUserCacheMgr().getCache(userKey);

    boolean viewingSelf = false;
    boolean isDisabled = uProf.getDisabled();
    JSONObject userInfo = uProf.getFullJSON();
    if (isLoggedIn) {
        UserProfile runningUser = ar.getUserProfile();
        viewingSelf = uProf.getKey().equals(runningUser.getKey());
    }
    else {
        JSONObject publicInfo = new JSONObject();
        publicInfo.put("key", userInfo.getString("key"));
        publicInfo.put("name", userInfo.getString("name"));
        publicInfo.put("timeZone", userInfo.getString("timeZone"));
        publicInfo.put("image", userInfo.getString("image"));
        publicInfo.put("description", userInfo.getString("description"));
        userInfo = publicInfo;
    }


    String photoSrc = ar.retPath+"assets/photoThumbnail.gif";
    String profImage = uProf.getImage();
    if(profImage!=null && profImage.length() > 0){
        photoSrc = ar.retPath+"icon/"+profImage;
    }

    String templateCacheDefeater = "";
    if ("true".equals(ar.getSystemProperty("forceTemplateRefresh"))) {
        templateCacheDefeater = "?t="+System.currentTimeMillis();
    }
    
%>

<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal) {
    window.setMainPageTitle("Weaver User");
    $scope.userInfo = <%userInfo.write(out,2,4);%>;
    $scope.isDisabled = <%=isDisabled%>;
    console.log("USER CACHE: ", $scope.userCache);
    $scope.providerUrl = SLAP.loginConfig.providerUrl;

    $scope.editAgent=false;
    $scope.newAgent = {};
    $scope.addingEmail = false;
    $scope.newEmail = "";

    $scope.browserZone = Intl.DateTimeFormat().resolvedOptions().timeZone;
    
    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };
    $scope.goToEdit = function() {
        window.location = "UserProfileEdit.htm";
    }
    $scope.requestEmail = function() {
        var url="addEmailAddress.htm?newEmail="+encodeURIComponent($scope.newEmail);
        promise = $http.get(url)
        .success( function(data) {
            console.log("EMAIL: ", data);
            $scope.addingEmail=false;
            alert("Email has been sent to '"+$scope.newEmail+"'.  Find that email in your mailbox "+
                  "and click on the link to add the email to your profile.");
        })
        .error( function(data) {
            $scope.reportError(data);
        });
        
    }
    $scope.openSendEmail = function (item) {

        var attachModalInstance = $modal.open({
            animation: true,
            templateUrl: "<%=ar.retPath%>templates/EmailModal.html<%=templateCacheDefeater%>",
            controller: 'EmailModalCtrl',
            size: 'lg',
            backdrop: "static",
            resolve: {
                userInfo: function () {
                    return $scope.userInfo;
                }
            }
        });

        attachModalInstance.result
        .then(function (selectedTopic, topicName) {
            //nothing really to do
        }, function () {
            //cancel action - nothing really to do
        });
    };
    $scope.setTimeZone = function(newTimeZone) {
        var newProfile = {};
        newProfile.key = $scope.userInfo.key;
        newProfile.timeZone = newTimeZone;
        $scope.updateServer(newProfile);
    }
    $scope.updateServer = function(newProfile) {
        console.log("UPDATE PROFILE WITH", newProfile);
        var postURL = "updateProfile.json";
        $http.post(postURL, JSON.stringify(newProfile))
        .success( function(data) {
            $scope.userInfo = data;
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    }
        
    $scope.updateFacilitator = function() {
        console.log("USER CACHE: ", $scope.userCache);
        var postURL = "UpdateFacilitatorInfo.json?key="+$scope.userInfo.key;
        //postURL = "QueryUserEmail.json";
        if (!$scope.userCache.facilitator) {
            $scope.userCache.facilitator = {};
        }
        var body = JSON.stringify($scope.userCache.facilitator);
        console.log("UpdateFacilitatorInfo", body, $scope.userCache);
        $http.post(postURL, body)
        .success( function(data) {
            console.log("UpdateFacilitatorInfo RECEIVED", data);
            $scope.userCache.facilitator = data;
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
       
    }
    
    $scope.saveChanges = function(field) {
        var newProfile = {};
        newProfile[field] = $scope.userInfo[field];
        $scope.updateServer(newProfile);
        $scope.editField="";
    }
    $scope.updateServer = function(newProfile) {
        console.log("UPDATE PROFILE WITH", newProfile);
        var postURL = "updateProfile.json";
        $http.post(postURL, JSON.stringify(newProfile))
        .success( function(data) {
            $scope.userInfo = data;
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    }
    
});
</script>

<style>
.fullWidth {
    width:100%;
    margin: 50px;
}
.center {
  text-align: center;
  max-width: 800px;
}
.photoCircle {
    border-radius:50%;
    height: 200px;
    width: 200px;
}
</style>


<div class="fullWidth" ng-cloak  >

<%@include file="../jsp/ErrorPanel.jsp"%>
    

<div class="center">
    <img src="<%ar.writeHtml(photoSrc);%>" alt="user photo" class="photoCircle"/>

    <h3>{{userInfo.name}}</h3>

    <p>Timezone: {{userInfo.timeZone}}</p>

    <div ng-show="isDisabled">
        Status: <span style="color:red">DISABLED</span>
    </div>


<% if (isLoggedIn) { %>
    <div>
      <a class="btn btn-default btn-raised" ng-click="goToEdit()" >
                <img src="<%=ar.retPath%>assets/iconEditProfile.gif"/>
                Update Settings</a>
      <a class="btn btn-default btn-raised" ng-click="openSendEmail()" >
                Send Email to this User</a>
      <a class="btn btn-default btn-raised" href="UserHome.htm" >
                Show Home</a>
    </div>
<% } else { %>
    <div>
        Please  
        <button class="btn btn-primary btn-raised" ng-click="login()">
            Login
        </button>
        to find out more.
    </div>

<% } %>    
</div>

</div>



<script src="<%=ar.retPath%>templates/EmailModal.js"></script>