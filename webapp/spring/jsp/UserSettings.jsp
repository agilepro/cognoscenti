<%@page errorPage="/spring/jsp/error.jsp"
%><%@include file="include.jsp"
%><%@page import="org.socialbiz.cog.IDRecord"
%><%@page import="org.socialbiz.cog.ConfigFile"
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
        photoSrc = ar.retPath+"users/"+profImage;
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
        window.location = "editUserProfile.htm";
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
</style>


<div ng-app="myApp" ng-controller="myCtrl">

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
          <li role="presentation"><a role="menuitem" href="RemoteProfiles.htm" >
                    Remote Profiles</a></li>
          <li role="presentation"><a role="menuitem" href="userRemoteTasks.htm" >
                    Remote Action Items</a></li>
          <li role="presentation"><a role="menuitem" href="Agents.htm" >
                    Personal Assistant</a></li>
        </ul>
      </span>
    </div>

    <table class="spacey">
        <tr ng-show="userInfo.disabled">
            <td class="firstcol">Status:</td>
            <td><span style="color:red">DISABLED</span></td>
        </tr>
        <tr>
            <td class="firstcol">Full Name:</td>
            <td>{{userInfo.name}}</td>
        </tr>
        <tr>
            <td class="firstcol">Icon:</td>
            <td> 
                <img src="<%ar.writeHtml(photoSrc);%>" width="50" height="50"/>
            </td>
        </tr>

        <tr>
            <td class="firstcol">Description:</td>
            <td>{{userInfo.description}}</td>
        </tr>
<% //above this is public, below this only for people logged in
if (ar.isLoggedIn()) { %>
        <tr><td style="height:10px"></td></tr>
        <tr>
            <td class="firstcol">Email Ids:</td>
            <td>
                <div ng-repeat="email in userInfo.ids">{{email}}<br/></div>
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
        </tr>
<%} %>
        <tr>
            <td class="firstcol">Email Time Zone:</td>
            <td>{{userInfo.timeZone}} 
                
            </td>
        </tr>
        <tr ng-show="browserZone!=userInfo.timeZone">
            <td></td>
            <td>
                <span  style="color:red">Note, your browser is set to '{{browserZone}}' -- is above setting correct?</span>
            </td>
        </tr>
        <tr>
            <td class="firstcol">Last Login:</td>
            <td><%SectionUtil.nicePrintTime(ar.w, uProf.getLastLogin(), ar.nowTime); %> as <% ar.writeHtml(uProf.getLastLoginId()); %> </td>
        </tr>
        <tr>
            <td class="firstcol">Notify Period:</td>
            <td>{{userInfo.notifyPeriod}} days</td>
        </tr>
        <tr>
            <td class="firstcol">User Key:</td>
            <td>{{userInfo.key}}</td>
        </tr>
    </table>
<%if (viewingSelf){ %>
    <hr/>
    <table class="spacey">
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