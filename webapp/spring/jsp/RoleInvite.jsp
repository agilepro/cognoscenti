<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="include.jsp"
%><%

    ar.assertLoggedIn("Must be logged in to edit roles");

    String pageId      = ar.reqParam("pageId");
    String siteId      = ar.reqParam("siteId");
    
    //page must work for both workspaces and for sites
    boolean isSite = ("$".equals(pageId));
    NGBook site;
    NGContainer ngc;
    if (isSite) {
        site = ar.getCogInstance().getSiteByKeyOrFail(siteId).getSite();
        ngc = site;
    }
    else {
        NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
        site = ngw.getSite();
        ngc = ngw;
    }
    ar.setPageAccessLevels(ngc);
    UserProfile uProf = ar.getUserProfile();
    
    JSONArray allRoles = new JSONArray();
    for (NGRole aRole : ngc.getAllRoles()) {
        allRoles.put(aRole.getName());
    }

%>

<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal, AllPeople) {
    window.setMainPageTitle("Invite Members");
    $scope.allRoles  = <%allRoles.write(out,2,2);%>;
    
    $scope.targetRole = "Members";
    $scope.invitations = [];
    $scope.newEmail = "";
    $scope.newName = "";
    $scope.newRole = "Members";
    $scope.addressing = true;    
    
    $scope.message = "Hello,\n\nYou have been asked by '<%ar.writeHtml(uProf.getName());%>' to"
                    +" participate in the workspace for '<%ar.writeHtml(ngc.getFullName());%>'."
                    +"\n\nThe links below will make registration quick and easy, and"
                    +" after that you will be able to"
                    +" participate directly with the others through the site.";

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };
    
    function getAllInvites() {
        var postURL = "invitations.json";
        $http.get(postURL)
        .success( function(data) {
            console.log("GET INVITATIONS: ", data);
            $scope.invitations = data.invitations;
            $scope.invitations.sort( function(a,b) {return b.timestamp - a.timestamp} );
        } )
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    }
    function updateInvite(invite) {
        var email = invite.email;
        var postURL = "invitationUpdate.json";
        var postdata = angular.toJson(invite);
        $http.post(postURL, postdata)
        .success( function(data) {
            var newList = [];
            $scope.invitations.forEach( function(item) {
                if (email != item.email) {
                    newList.push(item);
                }
            });
            newList.push(data);
            newList.sort( function(a,b) {return b.timestamp - a.timestamp} );
            $scope.invitations = newList;
        } )
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    }
    $scope.inviteOne = function() {
        var obj = {};
        if (!$scope.newName || $scope.newName.length==0) {
            alert("Enter a name before inviting this person");
            return;
        }
        if (!$scope.newEmail || $scope.newEmail.length==0) {
            alert("Enter a email address before inviting this person");
            return;
        }
        obj.name = $scope.newName;
        obj.email = $scope.newEmail;
        obj.role = $scope.newRole;
        obj.msg = $scope.message;
        obj.status = "New";
        obj.timestamp = new Date().getTime();
        updateInvite(obj);
        $scope.addressing = false;
        $scope.newName = "";
        $scope.newEmail = "";
    }
    $scope.refresh = function() {
        getAllInvites();
    }
    $scope.reset = function(invite) {
        $scope.newEmail = invite.email;
        $scope.newName = invite.name;
        if (invite.role) {
            $scope.newRole = invite.role;
        }
        if (invite.msg) {
            $scope.message = invite.msg;
        }
    }
    getAllInvites();
});


</script>
<script src="../../../jscript/AllPeople.js"></script>

<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

    <div class="upRightOptions rightDivContent">
      <span class="dropdown">
        <button class="btn btn-default btn-raised dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
        Options: <span class="caret"></span></button>
        <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
          <li role="presentation"><a role="menuitem" tabindex="-1"
              href="roleManagement.htm">Manage Roles</a></li>
          <li role="presentation"><a role="menuitem" tabindex="-1"
              href="RoleInvite.htm">Invite Users</a></li>
          <li role="presentation"><a role="menuitem" tabindex="-1"
              href="MultiInvite.htm">Multi-Person Invite</a></li>
        </ul>
      </span>
    </div>

    <style>
    .spacey tr th{
        padding: 8px;
    }
    .spacey tr td{
        padding: 8px;
        border-top: solid lightgrey 1px
    }
    .spacey tr:hover {
        background-color:lightgrey;
    }
    .spacey {
        width: 100%;
        max-width: 800px;
    }
    </style>


    
  <div class="well" style="max-width:500px;margin-bottom:50px">
      <div ng-show="addressing">
        <div>
        <p><i>Add people to the project by entering their email address and name.</i></p>
        </div>
        <div class="form-group">
            <label>Email Address</label>
            <input class="form-control" ng-model="newEmail"/>
        </div>
        <div class="form-group">
            <label>Full Name</label>
            <input class="form-control" ng-model="newName"/>
        </div>
        <div class="form-group">
            <label>Role</label>
            <select class="form-control" ng-model="newRole"
                    ng-options="r for r in allRoles"></select>
        </div>
        <div class="form-group">
            <label>Message</label>
            <textarea class="form-control" style="height:200px" ng-model="message"></textarea>
        </div>
        <div>
            <button ng-click="inviteOne()" class="btn btn-sm btn-primary btn-raised"/>Invite</button>
            <button ng-click="addressing=false" class="btn btn-sm btn-raised"/>Close</button>
        </div>
      </div>
      <div ng-hide="addressing">
        <button ng-click="addressing=true" class="btn btn-sm btn-primary btn-raised"/>Open to Invite Another</button>
      </div>
  </div>  
  
  <h2>Previously Invited</h2>
  
    <table class="spacey">
    <tr><th>Email</th><th>Name</th><th>Status</th><th>Date</th><th>Visited</th></tr>
    <tr ng-repeat="invite in invitations" title="Click row to copy into the send form"
        ng-click="reset(invite)">
        <td>{{invite.email}}</td>
        <td>{{invite.name}}</td>
        <td>{{invite.status}}</td>
        <td>{{invite.timestamp | date}}</td>
        <td>{{invite.joinTime | date}}</td>
    </tr>

    </table>

    <div><button class="btn btn-default btn-raised" ng-click="refresh()">Refresh List</button></div>


</div>
<script src="<%=ar.retPath%>templates/RoleModalCtrl.js"></script>
<script src="<%=ar.retPath%>templates/InviteModal.js"></script>

