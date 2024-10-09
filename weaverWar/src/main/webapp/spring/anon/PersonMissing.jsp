<%@page errorPage="/spring/jsp/error.jsp"
%><%@include file="/include.jsp"
%><%@page import="com.purplehillsbooks.weaver.ConfigFile"
%><%

    boolean isLoggedIn = ar.isLoggedIn();
    Cognoscenti cog = ar.getCogInstance();
    
    //this is probably an email address
    String userEmail = ar.reqParam("userKey");

    boolean viewingSelf = false;
    boolean isDisabled = false;



    String photoSrc = ar.retPath+"assets/photoThumbnail.gif";

    String templateCacheDefeater = "";
    if ("true".equals(ar.getSystemProperty("forceTemplateRefresh"))) {
        templateCacheDefeater = "?t="+System.currentTimeMillis();
    }
    
%>

<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal) {
    window.setMainPageTitle("Missing Person");
    $scope.providerUrl = SLAP.loginConfig.providerUrl;

    $scope.editAgent=false;
    $scope.newAgent = {};
    $scope.addingEmail = false;
    $scope.userEmail = "<% ar.writeJS(userEmail); %>";

    $scope.browserZone = Intl.DateTimeFormat().resolvedOptions().timeZone;
    
    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };
    $scope.goToEdit = function() {
        window.location = "UserSettings.htm";
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
    <div style="background-color:grey;margin:auto" class="photoCircle"/></div>

    <h3>{{userEmail}}</h3>


<% if (isLoggedIn) { %>
    <div>
        The person you are trying to see has not logged into the system
        <br/>
        and does not have a user profile on record, so we have 
        <br/>
        no additional information that we can show.
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