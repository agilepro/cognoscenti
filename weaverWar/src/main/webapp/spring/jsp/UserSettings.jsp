<%@page errorPage="/spring/jsp/error.jsp"
%><%@include file="include.jsp"
%><%@page import="com.purplehillsbooks.weaver.IDRecord"
%><%@page import="com.purplehillsbooks.weaver.ConfigFile"
%><%

    ar.assertLoggedIn("Must be logged in to see anything about a user");

    String userKey = ar.reqParam("userKey");
    UserProfile uProf = UserManager.getUserProfileByKey(userKey);
    UserProfile runningUser = ar.getUserProfile();
    if (uProf == null) {
        throw new NGException("nugen.exception.cant.find.user",null);
    }

    boolean viewingSelf = uProf.getKey().equals(runningUser.getKey());
    boolean cantEdit = !(viewingSelf || ar.isSuperAdmin());

    JSONObject userInfo = uProf.getFullJSON();

    String photoSrc = ar.retPath+"assets/photoThumbnail.gif";
    String profImage = uProf.getImage();
    if(profImage!=null && profImage.length() > 0){
        photoSrc = ar.retPath+"icon/"+profImage;
    }

    String remoteProfileURL = ar.baseURL+"apu/"+uProf.getKey()+"/user.json?lic="+uProf.getLicenseToken();

    String templateCacheDefeater = "";
    if ("true".equals(ar.getSystemProperty("forceTemplateRefresh"))) {
        templateCacheDefeater = "?t="+System.currentTimeMillis();
    }
    
%>

<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal) {
    window.setMainPageTitle("Profile Settings");
    $scope.userInfo = <%userInfo.write(out,2,4);%>;
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


<div>

<%@include file="ErrorPanel.jsp"%>

    <div class="upRightOptions rightDivContent">
      <span class="dropdown">
        <button class="btn btn-default btn-raised dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
        Options: <span class="caret"></span></button>
        <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
          <li role="presentation"><a role="menuitem" tabindex="-1" ng-click="goToEdit()" >
                    <img src="<%=ar.retPath%>assets/iconEditProfile.gif"/>
                    Update Settings</a></li>
          <li role="presentation"><a role="menuitem" tabindex="-1" ng-click="addingEmail=!addingEmail" >
                    Add Email Address</a></li>
          <li role="presentation" class="divider"></li>
          <li role="presentation"><a role="menuitem" ng-click="openSendEmail()" >
                    Send Email to this User</a></li>
          <li role="presentation" class="divider"></li>
          <li role="presentation"><a role="menuitem" href="UserHome.htm" >
                    Show Home</a></li>
          <li role="presentation"><a role="menuitem" href="RemoteProfiles.htm" ><!--this should be removed-->
                    Remote Profiles</a></li>
        </ul>
      </span>
    </div>

    <table class="spacey table">
        <tr ng-show="userInfo.disabled">
            <td class="firstcol">Status:</td>
            <td><span style="color:red">DISABLED</span></td>
        </tr>
        <tr>
            <td class="firstcol">Full Name:</td>
            <td>{{userInfo.name}}</td>
            <td ng-hide="helpFullName">
                <button class="btn" ng-click="helpFullName=!helpFullName">?</button>
            </td>
            <td ng-show="helpFullName" ng-click="helpFullName=!helpFullName">
              <div class="guideVocal thinnerGuide">
                The full name is what other people will see you as when you do things in Weaver.
                You should include both first and last name, because in Weaver you will
                be working with many people, some who know you, and some who don't.
                It is better to include a complete name if possible.
              </div>
            </td>
        </tr>
        <tr>
            <td class="firstcol">Icon:</td>
            <td> 
                <img src="<%ar.writeHtml(photoSrc);%>" width="50" height="50"/>
            </td>
            <td ng-hide="helpIcon">
                <button class="btn" ng-click="helpIcon=!helpIcon">?</button>
            </td>
            <td ng-show="helpIcon" ng-click="helpIcon=!helpIcon">
              <div class="guideVocal thinnerGuide">
                The icon is an image of you that is used in lists of users.
                By default you will be given a letter of the alphabet.
                In Update Settings you can upload an image of yourself.
              </div>
            </td>
        </tr>

        <tr>
            <td class="firstcol">Description:</td>
            <td>{{userInfo.description}}</td>
            <td ng-hide="helpDescription">
                <button class="btn" ng-click="helpDescription=!helpDescription">?</button>
            </td>
            <td ng-show="helpDescription" ng-click="helpDescription=!helpDescription">
              <div class="guideVocal thinnerGuide">
                Describe yourself for others to get to know you.
              </div>
            </td>
        </tr>
<% //above this is public, below this only for people logged in
if (ar.isLoggedIn()) { %>
        <tr>
            <td class="firstcol">Email Ids:</td>
            <td>
                <div ng-repeat="email in userInfo.ids">{{email}}<br/></div>
            </td>
            <td ng-hide="helpEmail">
                <button class="btn" ng-click="helpEmail=!helpEmail">?</button>
            </td>
            <td ng-show="helpEmail" ng-click="helpEmail=!helpEmail">
              <div class="guideVocal thinnerGuide">
                <div>You can associate as many email addresses as you want. 
                Email is only sent to the first email in the list, known as the preferred email address.  The other addresses are used only to identify artifacts you created when logged in as that email address.</div>
                <br/>
                <div>If you need to change the email address that you log in as, just ADD the new address here, but LEAVE the old one in the list.
                If you used to work in Weaver with an old email address, the history items will be tagged with that old address, so you need to leave that old address in this list so they are associated with you.</div>
              </div>
            </td>
        </tr>
<%if (viewingSelf){ %>
        <tr>
            <td class="firstcol"></td>
            <td ng-hide="addingEmail">
                <button class="btn btn-default btn-raised" ng-click="addingEmail=true">Add Email Id</button>
            </td>
            <td ng-show="addingEmail" class="form-group">
                <div class="well" style="max-width:500px">
                <h3>Add an email address to your profile</h3>
                <p>If you use multiple email addresses, you can add as many as you like to your profile.  
                We just need to confirm your email address before it will be added.</p>
                <input type="text" ng-model="newEmail" class="form-control" style="width:300px">
                <p>Enter an email address, a confirmation message will be sent.
                When you receive that, click the link to add the email address to your profile.</p>
                <button class="btn btn-primary btn-raised" ng-click="requestEmail()">Request Confirmation Email</button>
                <button class="btn btn-warning btn-raised" ng-click="addingEmail=false">Cancel</button>
                </div>
            </td>
            <td></td>
            <td></td>
        </tr>
<%} %>
        <tr>
            <td class="firstcol">Email Time Zone:</td>
            <td>{{userInfo.timeZone}} 
                
            </td>
            <td ng-hide="helpTimeZone">
                <button class="btn" ng-click="helpTimeZone=!helpTimeZone">?</button>
            </td>
            <td ng-show="helpTimeZone" ng-click="helpTimeZone=!helpTimeZone">
              <div class="guideVocal thinnerGuide">
                The time zone setting is used when sending email so that you see the right date and time appropriate to your normal location.  <br/>
                All dates and times displayed in the browser will be in the timezone of that browser computer.  For email, however, we don't know what the timezone of the place where the email will be delivered, so you need to set it here.
              </div>
            </td>
        </tr>
<%if (viewingSelf){ %>
        <tr ng-show="browserZone!=userInfo.timeZone">
            <td></td>
            <td>
                <div  style="color:red">Note, your browser is set to '{{browserZone}}' -- is above setting correct?</div>
                <div><button class="btn btn-default btn-raised" ng-click="setTimeZone(browserZone)">Set Time Zone to {{browserZone}}</button></div>
            </td>
            <td></td>
            <td></td>
        </tr>

    <%if (ar.isSuperAdmin()){ %>
        <tr >
            <td>Super Admin</td>
            <td style="background-color:yellow">
                You are a Super Admin
            </td>
            <td></td>
            <td></td>
        </tr>
    <% } %>

<% } %>
        <tr>
            <td class="firstcol">Last Login:</td>
            <td><%SectionUtil.nicePrintTime(ar.w, uProf.getLastLogin(), ar.nowTime); %> as <% ar.writeHtml(uProf.getLastLoginId()); %> </td>
            <td ng-hide="helpLastLogin">
                <button class="btn" ng-click="helpLastLogin=!helpLastLogin">?</button>
            </td>
            <td ng-show="helpLastLogin" ng-click="helpLastLogin=!helpLastLogin">
              <div class="guideVocal thinnerGuide">
                This just lets you know when you last logged in as a security measure to be aware if maybe someone else is logging in as you, and to let others know the last time you were active in the system.
              </div>
            </td>
        </tr>
        <tr>
            <td class="firstcol">Notify Period:</td>
            <td>{{userInfo.notifyPeriod}} days</td>
            <td ng-hide="helpNotifyPeriod">
                <button class="btn" ng-click="helpNotifyPeriod=!helpNotifyPeriod">?</button>
            </td>
            <td ng-show="helpNotifyPeriod" ng-click="helpNotifyPeriod=!helpNotifyPeriod">
              <div class="guideVocal thinnerGuide">
                If you sign up for change notifications for a workspace, this setting will determine whether you get an email every day, every week, or every month.
              </div>
            </td>
        </tr>
        <tr>
            <td class="firstcol">User Key:</td>
            <td>{{userInfo.key}}</td>
            <td ng-hide="helpKey">
                <button class="btn" ng-click="helpKey=!helpKey">?</button>
            </td>
            <td ng-show="helpKey" ng-click="helpKey=!helpKey">
              <div class="guideVocal thinnerGuide">
                This is the internal unique identifier of this user.
              </div>
            </td>
        </tr>
    </table>
<%if (viewingSelf){ %>
    <hr/>
    <table class="spacey">
        <tr>
            <td class="firstcol">Password:</td>
            <td><a href="{{providerUrl}}" target="_blank">Click Here to Change Password</a></td>
        </tr>
        <tr>
            <td class="firstcol">Remote URL:</td>
            <td><a href="<%=remoteProfileURL%>"><%=remoteProfileURL%></a></td>
        </tr>
        <tr>
            <td class="firstcol">API Token:</td>
            <td><% ar.writeHtml(uProf.getLicenseToken());%></td>
        </tr>
    </table>
<% } %>
<%} %>

</div>

<script src="<%=ar.retPath%>templates/EmailModal.js"></script>