<%@page errorPage="/spring2/jsp/error.jsp"
%><%@ include file="/include.jsp"
%><%

    ar.assertLoggedIn("Must be logged in to edit roles");

    String pageId      = ar.reqParam("pageId");
    String siteId      = ar.reqParam("siteId");
    
    //page must work for both workspaces and for sites
    boolean isSite = ("$".equals(pageId));
    NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    NGBook site = ngw.getSite();
    
    ar.setPageAccessLevels(ngw);
    UserProfile uProf = ar.getUserProfile();
    
    JSONArray allRoles = new JSONArray();
    for (NGRole aRole : ngw.getAllRoles()) {
        allRoles.put(aRole.getName());
    }

    boolean userReadOnly = ar.isReadOnly(); 
    boolean isFrozen = ngw.isFrozen();
%>


<script src="../../../jscript/AllPeople.js"></script>
<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal, AllPeople) {
    setUpLearningMethods($scope, $modal, $http);
    window.setMainPageTitle("Add User");
    $scope.siteInfo = <%site.getConfigJSON().write(out,2,4);%>;
    $scope.workspaceName = "<%ar.writeJS(ngw.getFullName());%>";
    $scope.allRoles  = <%allRoles.write(out,2,2);%>;
    $scope.isFrozen = <%= isFrozen %>;
    
    $scope.registryErrors = [];
    $scope.siteErrors = [];
    $scope.workspaceErrors = [];

    $scope.targetRole = "Members";
    $scope.invitations = [];
    $scope.newEmail = "";
    $scope.newName = "";
    $scope.newRole = "Members";
    $scope.addressing = true;   
    $scope.wizardStep = 0;    
    AllPeople.clearCache($scope.siteInfo.key);
    
    $scope.message = "Hello,\n\nYou have been asked by '<%ar.writeHtml(uProf.getName());%>' to"
                    +" participate in a role of the project '<%ar.writeHtml(ngw.getFullName());%>' on Weaver."
                    +"\n\nWeaver is a collaboration site that helps teams work together better.  "
                    +"You can share documents, hold a discussion, and prepare for  meetings, "
                    +"all securely shared within a workspace accessible only to members.  "
                    +"Weaver is supported by volunteers.  Join us and see how it works.\n";

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };
    
    $scope.doSearch = function() {
        if (!$scope.newEmail) {
            alert("please enter an email address");
            return;
        }
        let possibleUser = {uid: $scope.newEmail, name: $scope.newName};
        var postURL = "../../su/lookUpUser.json";
        var postdata = angular.toJson(possibleUser);
        $http.post(postURL, postdata)
        .success( function(data) {
            AllPeople.clearCache($scope.siteInfo.key);
            $scope.foundPerson = data;
            console.log("FIND RETURNED: ", data);
            $scope.wizardStep = 3;
            $scope.doSearchSite();
        })
        .error( function(data, status, headers, config) {
            console.log("FAIL TO FIND:", data);
            $scope.registryErrors = errorToList(data);
            // failure to find for any reason means to create one
            $scope.wizardStep = 2;
        });
    }
    
    
    $scope.doCreate = function() {
        if (!$scope.newName) {
            alert("please enter a Full Name for this user");
            return;
        }
        let invite = {uid: $scope.newEmail, name: $scope.newName};
        var postURL = "../$/assureUserProfile.json";
        var postdata = angular.toJson(invite);
        $http.post(postURL, postdata)
        .success( function(data) {
            alert("User Created: "+ data.name);
            AllPeople.clearCache($scope.siteInfo.key);
            $scope.foundPerson = data;
            console.log("FIND RETURNED: ", data);
            if ($scope.foundPerson) {
                $scope.wizardStep = 3;
                $scope.doSearchSite();
            }
            else {
                $scope.wizardStep = 2;
            }
        })
        .error( function(data, status, headers, config) {
            $scope.registryErrors = errorToList(data);
            $scope.wizardStep = 1;
        });
    }
    
    $scope.doSearchSite = function() {
        if (!$scope.newEmail) {
            alert("please enter an email address");
            return;
        }
        let possibleUser = {uid: $scope.foundPerson.uid, name: $scope.foundPerson.name};
        var postURL = "../$/findUserProfile.json";
        var postdata = angular.toJson(possibleUser);
        $http.post(postURL, postdata)
        .success( function(data) {
            AllPeople.clearCache($scope.siteInfo.key);
            $scope.sitePerson = data;
            console.log("FIND RETURNED: ", data);
            $scope.wizardStep = 6;
        })
        .error( function(data, status, headers, config) {
            console.log("FAIL TO FIND:", data);
            $scope.siteErrors = errorToList(data);
            // failure to find for any reason means to create one
            $scope.wizardStep = 4;
        });
    }
    
    $scope.addToSite = function() {
        if (!$scope.newEmail) {
            alert("please enter an email address");
            return;
        }
        var postURL = "../$/assureUserProfile.json";
        if ($scope.shouldBePaid) {
            $scope.foundPerson.setPaid = true;
            $scope.foundPerson.setUnPaid = false;
        } else {
            $scope.foundPerson.setPaid = false;
            $scope.foundPerson.setUnPaid = true;
        }
        var postdata = angular.toJson($scope.foundPerson);
        console.log("ADD REQUESTED: ", $scope.foundPerson);
        $http.post(postURL, postdata)
        .success( function(data) {
            AllPeople.clearCache($scope.siteInfo.key);
            $scope.sitePerson = data;
            console.log("ADD RETURNED: ", data);
            if (data.isPaid) {
                if (!$scope.shouldBePaid) {
                    alert("Should be paid but came back opposite");
                }
            }
            if (!data.isPaid) {
                if ($scope.shouldBePaid) {
                    alert("Should be UNPAID but came back opposite");
                }
            }
            $scope.shouldBePaid = data.isPaid;
            $scope.wizardStep = 6;
        })
        .error( function(data, status, headers, config) {
            console.log("FAIL TO ADD:", data);
            $scope.siteErrors = errorToList(data);
            // failure to find for any reason means to create one
            $scope.wizardStep = 5;
        });
    }
    $scope.changeToPaid = function(paidStatus) {
        $scope.shouldBePaid = paidStatus;
        $scope.addToSite();
    }
    
    
    $scope.addToRole = function(role) {
        if (!$scope.newEmail) {
            alert("please enter an email address");
            return;
        }
        var postURL = "assureRolePlayer.json";
        var record = {role: role, uid: $scope.foundPerson.uid}
        var postdata = angular.toJson(record);
        console.log("addToRole REQUESTED: ", record);
        $http.post(postURL, postdata)
        .success( function(data) {
            AllPeople.clearCache($scope.siteInfo.key);
            $scope.sitePerson = data;
            console.log("addToRole RETURNED: ", data);
            $scope.shouldBePaid = data.isPaid;
            $scope.wizardStep = 8;
        })
        .error( function(data, status, headers, config) {
            console.log("FAIL TO addToRole:", data);
            $scope.workspaceErrors = errorToList(data);
            // failure to find for any reason means to create one
            $scope.wizardStep = 7;
        });
    }
    
    function errorToList(data) {
        ret = [];
        data.error.details.forEach(function(item) {
            ret.push(item.message);
        });
        return ret;
    }
});


</script>

<div class="container-fluid override mb-4 mx-3 d-inline-flex">
    <span class="dropdown mt-1">
        <button class="btn btn-outline-secondary btn-tiny dropdown-toggle" type="button" id="dropdownInfoMenu"
            data-bs-toggle="dropdown" aria-expanded="false">
        </button>
        <ul class="dropdown-menu" aria-labelledby="dropdownInfoMenu">
            <li>
                <button class="dropdown-item" onclick="window.location.reload(true)">Refresh</button>
                <span class="dropdown-item" type="button"><a class="nav-link" role="menuitem" tabindex="-1"
                        href="RoleManagement.htm"><span class="fa fa-users"></span>&nbsp;Manage Roles</a></span>
                <span class="dropdown-item" type="button"><a class="nav-link" role="menuitem" tabindex="-1"
                        href="MultiInvite.htm"><span class="fa fa-envelope"></span>&nbsp;Multi-Person Invite</a></span>
            </li>
        </ul>
    </span>
    <span>
        <h1 class="d-inline page-name" id="mainPageTitle"></h1>
    </span>
</div>

<%@include file="ErrorPanel.jsp"%>

<% if (userReadOnly) { %>

<div class="guideVocal" style="margin-top:80px">
    You are not allowed to invite people to the workspace, because
    you are not playing an update role in the workspace.  
    
    If you wish to invite people, speak to a steward of this 
    workspace to be added to an update role.
</div>

<% } else { %>

    <div>Wizard Step = {{wizardStep}}</div>

    <div class="container-fluid override m-3"> 
        <div class="d-flex col-12 m-3">
            <div class="contentColumn">
                
    <h2>Weaver User Registration</h2>
    <div class="well col-12 m-2" ng-show="wizardStep < 1">
        <span class="h6">
            <i>Add people to the workspace, start by entering their email address.</i>
        </span>

        <div class="row d-flex my-3">
            <span class="col-2">
                <label class="h6">Email Address</label>
            </span>
            <span class="col-10"><input class="form-control" ng-model="newEmail"/>
            </span>
        </div>

        
        <div>
            <button ng-click="doSearch()" class="btn btn-primary btn-wide btn-raised">Search Weaver</button>
        </div>
    </div>
                
                
    <div class="well col-12 m-2" ng-show="wizardStep==1">

        <div class="row d-flex my-3">
            <span class="col-2">
                <label class="h6">Email Address</label>
            </span>
            <span class="col-10">{{newEmail}}
            </span>
        </div>
        <span class="h6">
            <i>Error Creating the User in Weaver Registration</i></span>
        <div ng-repeat="err in registryErrors"> {{err}} </div>
        
        <div>
            <button ng-click="wizardStep=0" class="btn btn-primary btn-wide btn-raised">Try Again</button>
        </div>
    </div>
    
    <div class="well col-12 m-2" ng-show="wizardStep==2">

        <div class="row d-flex my-3">
            <span class="col-2">
                <label class="h6">Email Address</label>
            </span>
            <span class="col-10">{{newEmail}}
            </span>
        </div>
        <span class="h6">
            <i>Person was not found in Weaver.  Enter Name to Create user in Weaver</i></span>
        <div class="row d-flex my-3">
            <span class="col-2">
                <label class="h6">Full Name</label>
            </span>
            <span class="col-10"><input class="form-control" ng-model="newName"/>
            </span>
        </div>

        <div>
            <button ng-click="doCreate()" class="btn btn-primary btn-wide btn-raised">Create User</button>
        </div>
    </div>
    
    <div class="well col-12 m-2" ng-show="wizardStep>2">
        <div class="row d-flex my-3">
            <span class="col-2">
                <label class="h6">Email Address</label>
            </span>
            <span class="col-10">{{foundPerson.uid}}</span>
            
        </div>
        <div class="row d-flex my-3">
            <span class="col-2">
                <label class="h6">Full Name</label>
            </span>
            <span class="col-10">{{foundPerson.name}}
            </span>
        </div>
    </div>    
    <h2>Site: {{siteInfo.names[0]}}</h2>  
    <div class="well col-12 m-2" ng-show="wizardStep==3">
        <span class="h6"><i>Person exists in Weaver, check if they are in this site?</i></span>

        <div>
            <button ng-click="doSearchSite()" class="btn btn-primary btn-wide btn-raised">Check in Site</button>
        </div>
    </div>
    <div class="well col-12 m-2" ng-show="wizardStep==4">
        <span class="h6"><i>Person does not exist in site, add them?</i></span>

        <div class="row d-flex my-3">
            <span class="col-2">
                <label class="h6">Paid</label></span>
            <span class="col-10">
                <input type="radio" ng-model="shouldBePaid" value="true"></input> Full User, 
                <input type="radio" ng-model="shouldBePaid" value="false"></input> Basic User
            </span>
        </div>
        <div>
            <button ng-click="addToSite()" class="btn btn-primary btn-wide btn-raised">Add To Site</button>
        </div>
    </div>
    <div class="well col-12 m-2" ng-show="wizardStep==5">
        <span class="h6"><i>Something went wrong with that.</i></span>

        <div ng-repeat="err in siteErrors"> {{err}} </div>
        <div>
            <button ng-click="wizardStep=4" class="btn btn-primary btn-wide btn-raised">Try Again</button>
        </div>
    </div>
    <div class="well col-12 m-2" ng-show="wizardStep>5">
        <span class="h6" ng-hide="sitePerson.isPaid"><i>User exists in site as a Basic user</i></span>
        <span class="h6" ng-show="sitePerson.isPaid"><i>User exists in site as a Full user</i></span>
        <div ng-hide="sitePerson.isPaid">
            <button ng-click="changeToPaid(true)" class="btn btn-primary btn-wide btn-raised">Change to Full user</button>
        </div>
        <div ng-show="sitePerson.isPaid">
            <button ng-click="changeToPaid(false)" class="btn btn-primary btn-wide btn-raised">Change to Basic user</button>
        </div>
    </div>
    
    
    <h2>Workspace: {{workspaceName}}</h2>  
    <div class="well col-12 m-2" ng-show="wizardStep==6">
        <span class="h6"><i>What role in workspace?</i></span>

        <div class="row d-flex my-3">
            <span class="col-2">
                <label class="h6">Role</label></span>
            <span class="col-10">
                <select class="form-control" ng-model="newRole" ng-options="r for r in allRoles"></select></span>
        </div>
        <div>
            <button ng-click="addToRole(newRole)" class="btn btn-primary btn-wide btn-raised">Place into Role</button>
        </div>
    </div>
    <div class="well col-12 m-2" ng-show="wizardStep==7">
        <span class="h6"><i>Something went wrong with that.</i></span>

        <div ng-repeat="err in workspaceErrors"> {{err}} </div>
        <div>
            <button ng-click="wizardStep=6" class="btn btn-primary btn-wide btn-raised">Try Again</button>
        </div>
    </div>
    
    
    <div class="well col-12 m-2" ng-show="wizardStep>7">
        <span class="h6"><i>Person is now playing the role {{newRole}}</i></span>

        <div>
            <button ng-click="alert('not implemented yet')" class="btn btn-primary btn-wide btn-raised">Send Invite (not implemented yet)</button>
        </div>
    </div>
    
    
    
    
                <div class="well col-12 m-2" ng-hide="true">
                    <div ng-show="addressing">
                        <div class="row d-flex my-3">
                            <span class="col-2">
                            <label class="h6">Full Name</label></span>
                            <span class="col-10"><input class="form-control" ng-model="newName"/>
                            </span>
                        </div>
                        <div class="row d-flex my-3">
                            <span class="col-2">
                                <label class="h6">Role</label></span>
                            <span class="col-10">
                                <select class="form-control" ng-model="newRole" ng-options="r for r in allRoles"></select></span>
                        </div>
                        <div class="row d-flex my-3">
                            <span class="col-2">
                                <label class="h6">Message</label></span>
                            <span class="col-10">
                                <textarea class="form-control" style="height:200px" ng-model="message"></textarea></span>
                    </div>
                    <div class="d-flex my-3">
                        <button ng-click="addressing=false" class="btn btn-danger btn-default btn-raised">Close</button>
                        <button ng-click="inviteOne()" class="btn btn-primary btn-raised btn-default ms-auto">Send Invitation (not implemented yet)</button>
                        
                    </div>
                </div>
                <div ng-hide="addressing">
                    <button ng-click="addressing=true" class="btn btn-primary btn-wide btn-raised">Open to Invite Another</button>
                </div>
            </div>  
            <div class="well" style="max-width:500px;margin-bottom:50px" ng-show="isFrozen">
                You can't invite anyone because this workspace is frozen or deleted.
            </div>  
<% } %> 
  


</div>
<script src="<%=ar.retPath%>new_assets/templates/InviteModal.js"></script>

