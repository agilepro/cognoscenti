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
        for (NGRole ngr : ngp.getAllRoles()) {
            if (ngr.isExpandedPlayer(uProf,ngp)) {
                JSONObject jo = new JSONObject();
                jo.put("siteKey", ngb.getKey());
                jo.put("key", ngp.getKey());
                jo.put("updated", ngp.getLastModifyTime());
                jo.put("fullName", ngp.getFullName());
                jo.put("role", ngr.getName());
                jo.put("desc", ngr.getDescription());
                partProjects.put(jo);
           }
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

    $scope.stopRole = function(prjrole) {
        var conf = confirm('Confirm that you would like to withdraw from the '
              +prjrole.role+' role of the '+prjrole.fullName+' workspace.');
        if (conf) {
            var postURL = "../removeMe.json?p="+encodeURIComponent(prjrole.key)
                    +"&role="+encodeURIComponent(prjrole.role);
            $http.get(postURL)
            .success( function(data) {
                var shorter = [];
                $scope.partProjects.forEach( function(item) {
                    if (item.key != prjrole.key  || item.role != prjrole.role) {
                        shorter.push(item);
                    }
                });
                $scope.partProjects = shorter;
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


<div class="d-flex col-9">
    <div class="contentColumn">
        <div class="container-fluid">
            <div class="generalContent">
<div class="well ms-2 col-8" ng-hide="hideNote" ng-click="hideNote=true">
    <span class="guideVocal">Please note: when you withdraw from a <b>'Members'</b> role of a workspace, you will stop receiving email when meetings are called, when discussions are create, and when comments are made. ALSO, you will no longer have any access to the workspace. Withdrawing from a Members role means you are effectively leaving the group that runs the workspace.</span>
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
<div class="row-cols-3 d-flex m-2 border-bottom border-1 border-secondary border-opacity-25" ng-repeat="prjrole in partProjects">
        <div class="col-xs-12 col-sm-6 col-md-3 padded">
            <b>{{prjrole.fullName}}</b><br/>
            Updated: {{prjrole.updated|cdate}}
        </div>
        <div class="col-xs-12 col-sm-6 col-md-3 padded">
            <b>{{prjrole.role}}</b> <br/>
            <button ng-click="stopRole(prjrole)" class="btn btn-danger btn-wide ">Withdraw</button>
        </div>
        <div class="col-xs-12 col-md-6 padded">
            {{prjrole.desc}}
        </div>
</div>
            </div>
        </div>
    </div>
</div>