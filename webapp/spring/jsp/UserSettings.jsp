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
    if(uProf.getImage().length() > 0){
        photoSrc = ar.retPath+"users/"+uProf.getImage();
    }

    String remoteProfileURL = ar.baseURL+"apu/"+uProf.getKey()+"/user.json?lic="+uProf.getLicenseToken();

%>

<script type="text/javascript">

var app = angular.module('myApp', ['ui.bootstrap']);
app.controller('myCtrl', function($scope, $http) {
    window.setMainPageTitle("Profile Settings");
    $scope.userInfo = <%userInfo.write(out,2,4);%>;

    $scope.editAgent=false;
    $scope.newAgent = {};

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
            <td class="firstcol">Email Id:</td>
            <td>
                <div ng-repeat="email in userInfo.ids">{{email}}</div>
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
<% } %>
<%} %>
    </table>

</div>
