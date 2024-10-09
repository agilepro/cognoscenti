<%@page errorPage="/spring/jsp/error.jsp"
%><%@include file="/include.jsp"
%><%@page import="com.purplehillsbooks.weaver.ConfigFile"
%><%

    ar.assertLoggedIn("Must be logged in to see anything about a user");
    Cognoscenti cog = ar.getCogInstance();
    
    String userKey = ar.reqParam("userKey");
    UserProfile uProf = cog.getUserManager().getUserProfileByKey(userKey);
    UserCache uc = cog.getUserCacheMgr().getCache(userKey);
    UserProfile runningUser = ar.getUserProfile();
    if (uProf == null) {
        throw WeaverException.newBasic("Can not find that user profile to display.");
    }

    boolean viewingSelf = uProf.getKey().equals(runningUser.getKey());
    boolean cantEdit = !(viewingSelf || ar.isSuperAdmin());

    JSONObject userInfo = uProf.getFullJSON();

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
    window.setMainPageTitle("Facilitator Settings");
    $scope.userInfo = <%userInfo.write(out,2,4);%>;
    $scope.userCache = <%uc.getAsJSON().write(out,2,4);%>;
    if (!$scope.userCache.facilitator) {
        $scope.userCache.facilitator = {isActive: false};
    }
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
        if (<%=cantEdit%>) {
            alert("User <% ar.writeHtml(runningUser.getName()); %> is not allowed to edit the profile for <% ar.writeHtml(uProf.getName()); %>");
            return;
        }
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
    
});
</script>

<style>
.spacey {
    width:100%;
}
.spacey tr td {
    padding:3px;
}
.firstcol {
    width:130px;
}
.thinnerGuide {
    margin:2px;
    width:400px;
}
</style>


<div class="userPageContents">

<%@include file="../jsp/ErrorPanel.jsp"%>
    

    <table class="spacey table">
        <tr>
            <td class="firstcol">Facilitator:</td>
            <td>
                <div>
                  <input type="checkbox" ng-model="userCache.facilitator.isActive" ng-click="updateFacilitator()"/> 
                </div>
            </td>
            <td ng-hide="helpFacilitator">
                <button class="btn" ng-click="helpFacilitator=!helpFacilitator">?</button>
            </td>
            <td ng-show="helpFacilitator" ng-click="helpFacilitator=!helpFacilitator">
              <div class="guideVocal thinnerGuide">
                This indicates that you are a facilitator, and would like to be contacted
                by people looking for a facilitator.
              </div>
            </td>
        </tr>
        <tr>
            <td class="firstcol" ng-click="showIntroEditor=true">Intro:</td>
            <td ng-hide="showIntroEditor">
                <div ng-bind-html="userCache.facilitator.intro|wiki"></div>
            </td>
            <td ng-show="showIntroEditor">
                <div>
                  make an editor appear here.   
                  <button class="btn btn-primary btn-raised" 
                          ng-click="showIntroEditor=false">Save</button>
                </div>
            </td>
            <td ng-hide="helpFacilitator">
                <button class="btn" ng-click="helpFacilitator=!helpFacilitator">?</button>
            </td>
            <td ng-show="helpFacilitator" ng-click="helpFacilitator=!helpFacilitator">
              <div class="guideVocal thinnerGuide">
                This is a long description with everything that you want prospective clients to know about you.
              </div>
            </td>
        </tr>
    </table>

</div>

<script src="<%=ar.retPath%>templates/EmailModal.js"></script>