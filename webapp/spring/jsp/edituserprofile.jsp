<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="org.socialbiz.cog.SectionUtil"
%><%@page import="org.socialbiz.cog.ValueElement"
%><%@page import="org.socialbiz.cog.UtilityMethods"
%><%@page import="org.socialbiz.cog.UserManager"
%><%@page import="org.socialbiz.cog.UserProfile"
%><%@page import="org.socialbiz.cog.IDRecord"
%><%@page import="java.util.TimeZone"
%><%@ include file="functions.jsp"
%><%

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
        photoSource = ar.retPath+"users/"+imagePath;
    }
    Object errMsg = session.getAttribute("error-msg");
    
    JSONArray timeZoneList = new JSONArray();
    for (String tz : TimeZone.getAvailableIDs()) {
        timeZoneList.put(tz);
    }

%>

<script type="text/javascript">

var app = angular.module('myApp', ['ui.bootstrap']);
app.controller('myCtrl', function($scope, $http) {
    window.setMainPageTitle("Edit Your Profile");
    $scope.profile = <%userObj.write(out,2,4);%>;
    $scope.timeZoneList = <%timeZoneList.write(out,2,4);%>;

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
            window.location='userSettings.htm';
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    }
    
    $scope.makePreferred = function(email) {
        var newProfile = {};
        newProfile.preferred = email;
        $scope.updateServer(newProfile);
    }
    $scope.deleteEmail = function(email) {
        var newProfile = {};
        newProfile.removeId = email;
        $scope.updateServer(newProfile);
    }
    $scope.addEmail = function() {
        var newProfile = {};
        newProfile.preferred = $scope.newEmail;
        $scope.updateServer(newProfile);
    }
});

</script>

<fmt:setBundle basename="messages"/>
<script>

    function updateProfile(op){
        document.getElementById('action').value=op;
        document.getElementById('updateUserProfile').action ="EditUserProfileAction.form";
        document.getElementById('updateUserProfile').submit();
    }

    function removeId(op,modid){
        var reply = confirm("Do you want to remove ID?");
        if(reply){
            document.getElementById('delconf').value='yes';
            document.getElementById('modid').value=modid;
            document.getElementById('action').value=op;
            document.getElementById('updateUserProfile').action = "EditUserProfileAction.form";
            document.getElementById('updateUserProfile').submit();
        }
    }

    var isOpenid = false;

    var removeUserIdResult = {
        success: function(o) {
                        var respText = o.responseText;
                        var json = eval('(' + respText+')');
                        if(json.msgType == "success"){
                            //removeTD(json.modid);
                            if(isOpenid){
                                alert("Open Id has been deleted successfully.");
                            }else{
                                alert("Email Id has been deleted successfully.");
                            }
                            window.location.reload();
                        }else{
                            showErrorMessage("Result", json.msg , json.comments );
                        }
         },
         failure: function(o) {
                    alert("deleteUserId.ajax Error:" +o.responseText);
         }
     }

    function removeTD(removeVal)
    {
        var myTD=document.getElementById(removeVal);
        myTD.parentNode.removeChild(myTD);
    }

    function uploadUserPhoto(){
        if(document.getElementById('fname').value.length <1 ){
            alert('Please upload a photo');
        }else{
            document.getElementById('upload_user').submit();
        }
    }

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


<div ng-app="myApp" ng-controller="myCtrl" id="myDomElement">

<%@include file="ErrorPanel.jsp"%>


    <form id="upload_user" action="uploadImage.form" method="post" enctype="multipart/form-data" >
        <input type="hidden" name="action" id="actionUploadPhoto" value='' />
        <table class="spacey">
            <tr>
                <td width="148" class="firstcol">Profile Photo:</td>
                <td style="width:50px;"><img src="<%ar.writeHtml(photoSource);%>" width="47" height="47" alt="" /></td>
                <td valign="bottom"><input type="file" name="fname" id="fname" /></td>
            </tr>
            <tr>
                <td class="firstcol"></td>
                <td colspan="2"><input type="button" class="btn btn-primary btn-raised" value="Upload Photo"
                    onclick="javascript:uploadUserPhoto();"/></td>
            </tr>
        </table>
    </form>
    <hr/>

    <table class="spacey">
        <tr>
            <td class="firstcol">Full Name:</td>
            <td><input type="text" class="form-control" ng-model="profile.name" /></td>
        </tr>
        <tr>
            <td class="firstcol">Description:</td>
            <td><textarea rows="4" class="form-control" ng-model="profile.description"></textarea></td>
        </tr>
        <tr>
            <td class="firstcol">Notify Period:</td>
            <td>
                <input type="radio" value="1"  ng-model="profile.notifyPeriod" /> Daily
                <input type="radio" value="7"  ng-model="profile.notifyPeriod" /> Weekly
                <input type="radio" value="30"  ng-model="profile.notifyPeriod" /> Monthly
            </td>
        </tr>
        <tr>
            <td class="firstcol">Time Zone:</td>
            <td>
                <select ng-model="profile.timeZone" ng-options="item for item in timeZoneList"></select>
            </td>
        </tr>
        <tr>
            <td class="firstcol"></td>
            <td colspan="2"><button class="btn btn-primary btn-raised" ng-click="updatePersonal()">Update Personal Details</button></td>
        </tr>
        <tr><td>&nbsp;</td></tr>
        <tr ng-repeat="email in profile.ids">
            <td class="firstcol">Email Id:</td>
            <td>{{email}}
                <span class="labelButton" style="background-color:yellow" ng-show="email==profile.preferred"
                    title="This is where all email notifications from Weaver will be sent">Preferred</span>
                <span class="btn btn-sm btn-primary btn-raised" ng-hide="email==profile.preferred"
                    ng-click="makePreferred(email)">Make Preferred</span>
                <span class="btn btn-sm btn-primary btn-raised" ng-hide="email==profile.preferred"
                    ng-click="deleteEmail(email)">Delete</span>
            </td>
        </tr>
    </table>
    <hr/>

    <table class="spacey">
        <tr>
            <td class="firstcol"></td>
            <td>
                <button class="btn btn-raised" onclick="window.location='userSettings.htm'">Done</button>
            </td>
        </tr>
    </table>

    <hr/>

    <% if (isSuperAdmin) { %>
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