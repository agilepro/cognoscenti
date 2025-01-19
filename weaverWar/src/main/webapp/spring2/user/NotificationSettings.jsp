<%@page errorPage="/spring2/jsp/error.jsp"
%><%@ include file="/include.jsp"
%><%

    UserProfile uProf = (UserProfile)request.getAttribute("userProfile");
    if (uProf == null) {
        throw WeaverException.newBasic("Can not find that user profile to display.");
    }

    UserProfile  operatingUser =null;
    boolean viewingSelf = false;
    if (ar.hasSpecialSessionAccess("Notifications:"+uProf.getKey())) {
        operatingUser = uProf;
        viewingSelf = true;
    }
    else {
        ar.assertLoggedIn("Must be logged in to see anything about user "+uProf.getKey());
        operatingUser =ar.getUserProfile();
        viewingSelf = uProf.getKey().equals(operatingUser.getKey());
    }

    if (operatingUser==null) {
        //this should never happen, and if it does it is not the users fault
        throw WeaverException.newBasic("user profile setting is null.  No one appears to be logged in.");
    }

    JSONArray partProjects = new JSONArray();
    List<NGPageIndex> projectsUserIsPartOf = ar.getCogInstance().getWorkspacesUserIsIn(uProf);
    
    NGPageIndex.sortInverseChronological(projectsUserIsPartOf);
    for(NGPageIndex ngpi : projectsUserIsPartOf){
        NGWorkspace ngp = ngpi.getWorkspace();
        NGBook ngb = ngp.getSite();
        JSONObject workspace = new JSONObject();
        workspace.put("key", ngp.getKey());
        workspace.put("siteKey", ngb.getKey());
        workspace.put("updated", ngp.getLastModifyTime());
        workspace.put("fullName", ngp.getFullName());
        workspace.put("aim", ngp.getProcess().getDescription());
        JSONArray roleList = new JSONArray();
        workspace.put("roles", roleList);
        
        for (NGRole ngr : ngp.getAllRoles()) {
            if (ngr.isExpandedPlayer(uProf,ngp)) {
                JSONObject jo = new JSONObject();
                jo.put("role", ngr.getName());
                jo.put("desc", ngr.getDescription());
                roleList.put(jo);
           }
        }
        if (roleList.length()>0) {
            partProjects.put(workspace);
        }
    }

%>

<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http) {
    window.setMainPageTitle("Notification Settings");
    $scope.partProjects = <%partProjects.write(out,2,4);%>;

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };

    $scope.hideNote = false;

    $scope.stopRole = function(workspace, role) {
        var conf = confirm('Confirm that you would like to withdraw from the\n   Role: '
              +role.role+'\nof the\n   Workspace: '+workspace.fullName);
        if (conf) {
            var postURL = "../removeMe.json?p="+encodeURIComponent(workspace.key)
                    +"&role="+encodeURIComponent(role.role);
            $http.get(postURL)
            .success( function(data) {
                console.log("REMOVED from role="+role.role+" of workspace="+workspace.fullName);
                var shorter = [];
                workspace.roles.forEach( function(item) {
                    if (item.role != role.role) {
                        shorter.push(item);
                    }
                });
                workspace.roles = shorter;
            })
            .error( function(data, status, headers, config) {
                $scope.reportError(data);
            });
        }
    }

});
</script>



<!-- MAIN CONTENT SECTION START -->
<div class="userPageContents">

<%@include file="../jsp/ErrorPanel.jsp"%>


<div class="d-flex">
    <div class="contentColumn">
        <div class="container-fluid">
            <div class="generalContent">
          
<div class="well ms-2 col-8" ng-hide="hideNote" ng-click="hideNote=true">
    <span class="guideVocal">
    <p>The purpose of this page is to allow you to see all of the roles in all of the projects 
    that you play.  It allows you an easy way to withdraw from those roles that you no longer 
    want to play.  Removing yourself from all roles of a workspace, will remove you from the
    workspace, and you will no longer get alerts or updates about that workspace.</p>
    
    Please note: when you withdraw from a <b>'Members'</b> role of a workspace, you will stop receiving email when meetings are called, when discussions are create, and when comments are made. ALSO, you will no longer have any access to the workspace. Withdrawing from a Members role means you are effectively leaving the group that runs the workspace.</span>
</div>
<div class="row-cols-3 d-flex m-2 border-bottom border-1 border-secondary border-opacity-25">
    <div class="col-xs-12 col-sm-6 col-md-3 padded">
        <b>Workspace</b>
    </div>
    <div class="col-xs-12 col-sm-6 col-md-3 padded">
        <b>Role</b>
    </div>
    <div class="col-xs-12 col-md-6 padded">
        <b>Description</b>
    </div>
</div>
<div class="row d-flex m-2 border-bottom border-1 border-secondary border-opacity-25" ng-repeat="prjrole in partProjects">
        <div class="row padded"  style="margin-bottom:20px">
            <div class="col-xs-12 col-md-6 padded">
            <!-- for some reason the b or string tag causes a new line here, it shouldn't -->
                <a href="../../t/{{prjrole.siteKey}}/{{prjrole.key}}/RoleManagement.htm">
                    <i class="fa  fa-external-link"></i>
                    <strong>{{prjrole.fullName}}</strong></a>
                - Updated: {{prjrole.updated|cdate}}
            </div>
            <div class="col-xs-12 col-md-6 padded">
                {{prjrole.aim}}
            </div>
        </div>
        <div class="row padded" ng-repeat="role in prjrole.roles"  style="margin-bottom:20px">
            <div class="col-xs-12 col-sm-6 col-md-3 padded">
                
            </div>
            <div class="col-xs-12 col-sm-6 col-md-3 padded">
                <strong>{{role.role}}</strong> <br/>
                <button ng-click="stopRole(prjrole, role)" class="btn btn-danger btn-wide ">Withdraw</button>
            </div>
            <div class="col-xs-12 col-md-6 padded">
                {{role.desc}}
            </div>
        </div>
</div>
            </div>
        </div>
    </div>
</div>