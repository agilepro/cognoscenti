<%@page errorPage="/spring/jsp/error.jsp"
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
    $scope.updateServer = function(newProfile, refresh) {
        console.log("UPDATE PROFILE WITH", newProfile);
        var postURL = "updateProfile.json";
        $http.post(postURL, JSON.stringify(newProfile))
        .success( function(data) {
            $scope.userInfo = data;
            console.log("REFRESH is ", refresh);
            if (refresh) {
                window.location.reload();
            }
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

    $scope.queryMailStatus = function() {
        var postURL = "MailProblemsUser.json";
        $http.get(postURL)
        .success( function(data) {
            console.log("MailProblemsUser.json RECEIVED", data);
            $scope.mailBlockers = data.blocks;
            $scope.mailBounces = data.bounces;
            $scope.mailSpams = data.spams;
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    }
    $scope.makePreferred = function(email) {
        var newProfile = {};
        newProfile.preferred = email;
        $scope.updateServer(newProfile);
        $scope.editField='';
    }
    
    $scope.switchToOldUI = function() {
        var newProfile = {};
        newProfile.useNewUI = false;
        $scope.updateServer(newProfile, true);
    }

    
});
</script>

<div class="userPageContents" ng-cloak>

<%@include file="../jsp/ErrorPanel.jsp"%>
<div class="container-fluid">
    <div class="row">
      	<div class="col-md-auto fixed-width border-end border-1 border-secondary">
            <span class="btn btn-secondary btn-comment btn-raised m-3 pb-2 pt-0" type="button">
                <a class="nav-link" ng-click="goToEdit()" >
                <img src="<%=ar.retPath%>assets/iconEditProfile.gif"/>
                Update Settings</a></span>
            <span class="btn btn-secondary btn-comment btn-raised m-3 pb-2 pt-0" type="button">
                <a class="nav-link" ng-click="openSendEmail()" >
                Send Email to this User</a></span>
            <span class="btn btn-secondary btn-comment btn-raised m-3 pb-2 pt-0" type="button">
                <a class="nav-link" href="UserHome.htm" >
                Show Home</a></span>
        </div>
        <div class="d-flex col-9">
			<div class="contentColumn">
				<div class="container-fluid">
                	<div class="generalContent">
<div class="table d-grid g-1">
    <div class="row d-flex" ng-show="userInfo.disabled">
        <span class="col">Status:</span>
        <span><span style="color:red">DISABLED</span></span>
    </div>
    <div class="row-cols-3 d-flex ">
        <span class="col-2  labelColumn ps-2" style="cursor: pointer;" ng-click="editField='name'">Full Name:</span>
        <span class="col-5 p-0 m-0" ng-dblclick="editField='name'" style="cursor: pointer;">
            <div ng-hide="editField=='name'">{{userInfo.name}}</div>
            <div ng-show="editField=='name'">
                <input class="form-control" ng-model="userInfo.name"/>
                <button class="my-2 btn btn-primary btn-raised btn-comment btn-sm" ng-click="saveChanges('name');editField=''">Save</button>
            </div>
        </span>
        <span class="col-5 p-0 m-0" ng-click="helpFullName=!helpFullName">
            <div ng-hide="helpFullName">
                <button class="btn"><i class="fa fa-question-circle-o" aria-hidden="true"></i></button>
            </div>
            <div class="well guideVocal thinnerGuide" ng-show="helpFullName">
                The full name is what other people will see you as when you do things in Weaver.
                You should include both first and last name, because in Weaver you will
                be working with many people, some who know you, and some who don't.
                It is better to include a complete name if possible.
                <hr/>
                Click in the left-most column to change your name.
            </div>
        </span>
    </div>
    <div class="row-cols-3 d-flex">
            <span class="col-2  labelColumn ps-2" style="cursor: pointer;"  ng-click="editField='icon'">Icon:</span>
            <span class="col-5 p-0 m-0" ng-dblclick="editField='icon'">
                <div>
                <img src="<%ar.writeHtml(photoSrc);%>" width="100" height="100" alt="user photo" />
                &nbsp; &nbsp;
                <img src="<%ar.writeHtml(photoSrc);%>" class="rounded-5" style="width:50px;height:50px" alt="user photo" />
                &nbsp; &nbsp;
                <img src="<%ar.writeHtml(photoSrc);%>" class="rounded-5" style="width:32px;height:32px" alt="user photo" />
                </div>
                <div ng-show="editField=='icon'">
                    <form id="upload_user" action="uploadImage.form" method="post" enctype="multipart/form-data" >
                    <input type="hidden" name="go" value="UserSettings.htm" />
                    <div class="col-12">
                        <div class="row d-flex">
                            <span class="col-2 h6">Profile Photo:</span>
                            <span class="col-5" valign="bottom">
                                <input type="file" name="fname" id="fname" class="btn btn-default btn-raised"/>
                            </span>
                            <span class="col-5">You must upload a JPG file.</br>Please choose one around 100x100 pixels if possible</span>
                        </div>
                        <div class="row d-flex">
                            <span class="col-2" ></span>
                            <span class="col-2">
                                <button class="my-2 btn btn-primary btn-raised btn-wide btn-sm"
                                onclick="javascript:uploadUserPhoto();">Upload Photo</button></span>
                        </div>
                    </div>
                    </form>
                </div>
            </span>
            <span class="col-5 p-0 m-0" ng-click="helpIcon=!helpIcon">
              <div ng-hide="helpIcon">
                <button class="btn"><i class="fa fa-question-circle-o fa-md" aria-hidden="true"></i></button>
              </div>
              <div class="guideVocal thinnerGuide" ng-show="helpIcon">
                The icon is an image of you that is used in lists of users.
                By default you will be given a letter of the alphabet.
                In Update Settings you can upload an image of yourself.
                <hr/>
                Click in the leftmost column to upload a new image.
              </div>
            </span>
    </div>
    <div class="row-cols-3 d-flex ">
            <span class="col-2  labelColumn ps-2" style="cursor: pointer;" ng-click="editField='description'">Description:</span>
            <span class="col-5 p-0 m-0"  ng-dblclick="editField='description'">
              <div ng-hide="editField=='description'"><div ng-bind-html="userInfo.description|wiki"></div></div>
              <div ng-show="editField=='description'">
                <textarea class="form-control" ng-model="userInfo.description"></textarea>
                <button class="my-2 btn btn-primary btn-raised btn-comment btn-sm" ng-click="saveChanges('description');editField=''">Save</button>
              </div>
            </span>
            <span class="col-5 p-0 m-0"  ng-click="helpDescription=!helpDescription">
              <div ng-hide="helpDescription">
                <button class="btn"><i class="fa fa-question-circle-o" aria-hidden="true"></i></button>
              </div>
              <div class="guideVocal thinnerGuide" ng-show="helpDescription">
                Describe yourself for others to get to know you.
                <hr/>
                Click in the leftmost column to change the description.
              </div>
            </span>
    </div>
<% //above this is public, below this only for people logged in
if (ar.isLoggedIn()) { %>
    <div class="row-cols-3 d-flex ">
        <span class="col-2  labelColumn ps-2" style="cursor: pointer;" ng-click="editField='email'">Email Ids:</span>
        <span class="col-5 p-0 m-0" ng-dblclick="editField='email'"  ng-hide="editField=='email'">
                <div ng-repeat="email in userInfo.ids">
                    {{email}}
                </div>
        </span>
        <span class="col-5 p-0 m-0" ng-show="editField=='email'">
            <div ng-repeat="email in userInfo.ids">
                <button class="btn btn-raised btn-comment"
                            ng-show="email==userInfo.preferred">Preferred Email:</button>
                <button class="btn btn-primary btn-raised" ng-click="makePreferred(email)" 
                            ng-hide="email==userInfo.preferred">Make Preferred</button>
                    {{email}}
            </div>
            <div ng-show="editField=='email'" class="form-group">
                <div class="well" style="max-width:500px">
                        <span class="h5">Add an email address to your profile</span>
                        <p>If you use multiple email addresses, you can add as many as you like to your profile.  We just need to confirm your email address before it will be added.</p>
                        <input type="text" ng-model="newEmail" class="form-control" style="width:300px">
                        <p>Enter an email address, a confirmation message will be sent. When you receive that, click the link to add the email address to your profile.</p>
                        <div class="d-flex">
                            
                            <button class="btn btn-danger btn-comment btn-wide btn-sm btn-raised" ng-click="editField=''">Cancel</button>
                            <button class="ms-auto btn btn-primary btn-raised btn-comment btn-wide btn-sm px-2" ng-click="requestEmail()">Request Confirmation Email</button>
                        </div>
                </div>
            </div>
            <span class="col-5 p-0 m-0" ng-click="helpEmail=!helpEmail">
                <div ng-hide="helpEmail">
                <button class="btn"><i class="fa fa-question-circle-o" aria-hidden="true"></i></button>
                </div>
                <div class="guideVocal thinnerGuide" ng-show="helpEmail">
                    <div>You can associate as many email addresses as you want. Email is only sent to the first email in the list, known as the preferred email address.  The other addresses are used only to identify artifacts you created when logged in as that email address.</div><br/>
                    <div>If you need to change the email address that you log in as, just ADD the new address here, but LEAVE the old one in the list. If you used to work in Weaver with an old email address, the history items will be tagged with that old address, so you need to leave that old address in this list so they are associated with you.</div>
                </div>
            </span>
        </span>
    </div>
    <div class="row-cols-3 d-flex ">
        <span class="col-2 labelColumn ps-2" style="cursor: pointer;" ng-click="goToEdit()">Time Zone:</span>
        <span class="col-5 ps-1 m-0">{{userInfo.timeZone}} 
        </span>
        <span class="col-5 p-0 m-0" ng-hide="helpTimeZone" ng-click="helpTimeZone=!helpTimeZone">
            <button class="btn" ><i class="fa fa-question-circle-o" aria-hidden="true"></i></button>
        </span>
        <span class="col-5 p-0 m-0" ng-show="helpTimeZone" ng-click="helpTimeZone=!helpTimeZone">
            <div class="guideVocal thinnerGuide">The time zone setting is used when sending email so that you see the right date and time appropriate to your normal location.  <br/>All dates and times displayed in the browser will be in the timezone of that browser computer.  For email, however, we don't know what the timezone of the place where the email will be delivered, so you need to set it here.
            </div>
        </span>
    </div>

<%if (viewingSelf){ %>
        <div class="row d-flex " ng-show="browserZone!=userInfo.timeZone">
            <span>
                <div style="color:red">
                Note, your browser is set to '{{browserZone}}' 
                <br/>
                While your profile is set to '{{userInfo.timeZone}}'
                <br/>
                is above setting correct?
                </div>
                <div><button class="my-2 btn btn-primary btn-raised btn-wide btn-sm" ng-click="setTimeZone(browserZone)">Set Your Time Zone to {{browserZone}}</button></div>
            </span>
            
        </div>
<% } %>
        <div class="row-cols-3 d-flex " >
            <span class="col-2 labelColumn ps-2" style="cursor: pointer;" ng-click="editField='notifyPeriod'">Notify Period:</span>
            <span class="col-5 ps-1 m-0" ng-dblclick="editField='notifyPeriod'">
              <div ng-hide="editField=='notifyPeriod'">
                {{userInfo.notifyPeriod}} days
              </div>
              <div ng-show="editField=='notifyPeriod'">
                <input type="radio" value="1"  ng-model="userInfo.notifyPeriod" /> Daily
                <input type="radio" value="7"  ng-model="userInfo.notifyPeriod" /> Weekly
                <input type="radio" value="30"  ng-model="userInfo.notifyPeriod" /> Monthly
                <button class="my-2 btn btn-primary btn-raised btn-wide btn-sm" ng-click="saveChanges('notifyPeriod')">Save</button>
              </div>
            </span>
            <span class="col-5 p-0 m-0" ng-click="helpNotifyPeriod=!helpNotifyPeriod">
                <div ng-hide="helpNotifyPeriod">
                <button class="btn"><i class="fa fa-question-circle-o" aria-hidden="true"></i></button>
                </div>
            
                <div class="guideVocal thinnerGuide" ng-show="helpNotifyPeriod" >
                If you sign up for change notifications for a workspace, this setting will determine whether you get an email every day, every week, or every month.
                </div>
            </span>
            
        </div>
        <div class="row-cols-3 d-flex " >
            <span class="col-2 labelColumn ps-2" style="cursor: text;" >Facilitator</span>
            <span class="col-5 ps-1 m-0">
                <div>
                  <input type="checkbox" ng-model="userCache.facilitator.isActive" ng-click="updateFacilitator()"/> 
                </div>
                <div>
                  <a href="FacSettings.htm" ng-show="userCache.facilitator.isActive"><button class="my-2 btn btn-primary btn-raised btn-wide btn-sm py-1">Configure Settings</button></a>
                </div>
            </span>
            <span class="col-5 p-0 m-0" ng-hide="helpFacilitator" ng-click="helpFacilitator=!helpFacilitator">
                <button class="btn" ><i class="fa fa-question-circle-o" aria-hidden="true"></i></button>
            </span>
            <span class="col-5 ps-0 m-0" ng-show="helpFacilitator" ng-click="helpFacilitator=!helpFacilitator">
              <div class="guideVocal thinnerGuide">
                This indicates that you are a facilitator, and would like to be contacted
                by people looking for a facilitator.
              </div>
            </span>
        </div>
<%if (viewingSelf){ %>
    <%if (ar.isSuperAdmin()){ %>
        <div class="row-cols-2 d-flex " >
            <span class="col-2 labelColumn ps-2" >Super Admin</span>
            <span class="col-5 p-2 m-0" style="background-color:rgb(216, 216, 125)">
                You are a Super Admin
            </span>
        </div>
    <% } %>
        <div class="row-cols-3 d-flex ">
            <span class="col-2 labelColumn ps-2">UI Mode:</span>
            <span class="col-5 p-2 m-0">You are currently viewing the NEW user interface<br/>
                <div class="m-0 p-0"><button class="btn btn-primary btn-raised btn-wide btn-sm py-1 my-3" ng-click="switchToOldUI()">Switch back to OLD UI</button></div></span>
            <span class="col-5 p-0 m-0" ng-hide="helpUI" ng-click="helpUI=!helpUI">
                <button class="btn"><i class="fa fa-question-circle-o" aria-hidden="true"></i></button>
            </span>
            <span class="col-5 p-2 m-0" ng-show="helpUI" ng-click="helpUI=!helpUI">
              <div class="guideVocal thinnerGuide">
                Click this to switch to the OLDER tried and true UI
              </div>
            </span>
        </div>
    

<% } %>
        <div class="row-cols-3 d-flex ">
            <span class="col-2 labelColumn ps-2">Last Login:</span>
            <span class="col-5 p-2 m-0"><%SectionUtil.nicePrintTime(ar.w, uProf.getLastLogin(), ar.nowTime); %> as <% ar.writeHtml(uProf.getLastLoginId()); %> </span>
            <span class="col-5 p-2 m-0" ng-hide="helpLastLogin" ng-click="helpLastLogin=!helpLastLogin">
                <button class="btn" ><i class="fa fa-question-circle-o" aria-hidden="true"></i></button>
            </span>
            <span class="col-5 p-2 m-0" ng-show="helpLastLogin" ng-click="helpLastLogin=!helpLastLogin">
              <div class="guideVocal thinnerGuide">
                This just lets you know when you last logged in as a security measure to be aware if maybe someone else is logging in as you, and to let others know the last time you were active in the system.
              </div>
            </span>
        </div>
        <div class="row-cols-3 d-flex ">
            <span class="col-2 labelColumn ps-2">User Key:</span>
            <span class="col-5 p-2 m-0">{{userInfo.key}}</span>
            <span class="col-5 p-2 m-0" ng-hide="helpKey" ng-click="helpKey=!helpKey">
                <button class="btn"><i class="fa fa-question-circle-o" aria-hidden="true"></i></button>
            </span>
            <span class="col-5 p-2 m-0" ng-show="helpKey" ng-click="helpKey=!helpKey">
              <div class="guideVocal thinnerGuide">
                This is the internal unique identifier of this user.
                You can not change this, this is permanent in order 
                to tie everything you do together even if you change 
                your email address.
              </div>
            </span>
        </div>
    </div>
    
    
    
<%if (viewingSelf){ %>
    <hr/>
    <div class="table" >
        <div class="row-cols-2 d-flex ">
            <span class="col-2 labelColumn ps-2">Password:</span>
            <span class="col-5 p-2 m-0"><a href="{{providerUrl}}" target="_blank">Click Here to Change Password</a></span>
        </div>
    </div>
<% } %>
<%} %>
    </div>

</div>

<script src="<%=ar.retPath%>new_assets/templates/EmailModal.js"></script>