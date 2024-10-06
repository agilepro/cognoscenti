<%@page errorPage="/spring2/jsp/error.jsp"
%><%@include file="include.jsp"
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
            templateUrl: "<%=ar.retPath%>new_assets/templates/EmailModal.html<%=templateCacheDefeater%>",
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

<div class="userPageContents">

<%@include file="../jsp/ErrorPanel.jsp"%>
    
<div class="container-fluid">
    <div class="row-cols-2 d-flex">
            <span class="col-2 labelColumn ps-2" style="cursor: text;">Facilitator:</span>
            <span class="col-1 p-0 m-0" >
                <div>
                  <input type="checkbox" ng-model="userCache.facilitator.isActive" ng-click="updateFacilitator()"/> 
                </div>
            </span>
            <span class="col-5 p-0 m-0" ng-hide="helpFacilitator">
                <button class="btn" ng-click="helpFacilitator=!helpFacilitator"><i class="fa fa-question-circle-o" aria-hidden="true"></i></button>
            </span>
            <span class="col-5 p-0 m-0"  ng-show="helpFacilitator" ng-click="helpFacilitator=!helpFacilitator">
              <div class="guideVocal thinnerGuide">
                This indicates that you are a facilitator, and would like to be contacted
                by people looking for a facilitator.
              </div>
            </span>
        </div>
        <div class="row-cols-3 d-flex " >
            <span class="col-2 labelColumn ps-2" ng-click="showIntroEditor=true">Intro:</span>
            <span class="col-3 p-2 m-0" ng-hide="showIntroEditor">
                <div ng-bind-html="userCache.facilitator.intro|wiki"></div>
            </span>
            <span class="col-3 p-2 m-0" ng-show="showIntroEditor">
                <div class="mce-tinymce" ng-model="userCache.facilitator.intro">
                  make an editor appear here.   
                  <button class="btn btn-primary btn-raised" 
                          ng-click="showIntroEditor=false">Save</button>
                </div>
            </span>
            <span class="col-5 p-2 m-0" ng-hide="helpFacilitator">
                <button class="btn" ng-click="helpFacilitator=!helpFacilitator"><i class="fa fa-question-circle-o" aria-hidden="true"></i></button>
            </span>
            <span class="col-5 p-2 m-0" ng-show="helpFacilitator" ng-click="helpFacilitator=!helpFacilitator">
              <div class="guideVocal thinnerGuide">
                This is a long description with everything that you want prospective clients to know about you.
              </div>
            </span>
        </div>
    </div>

</div>

<script src="<%=ar.retPath%>new_assets/templates/EmailModal.js"></script>