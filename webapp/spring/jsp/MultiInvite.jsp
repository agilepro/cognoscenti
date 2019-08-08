<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="include.jsp"
%><%

    ar.assertLoggedIn("Must be logged in to edit roles");

    String pageId      = ar.reqParam("pageId");
    String siteId      = ar.reqParam("siteId");
    String roleName    = ar.defParam("role", "Members");
    
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
    window.setMainPageTitle("Multi-Person Invite");
    $scope.allRoles  = <%allRoles.write(out,2,2);%>;
    $scope.newRole = "<%ar.writeJS(roleName);%>"
    $scope.invitations = [];
    $scope.message = "Hello,\n\nYou have been asked by '<%ar.writeHtml(uProf.getName());%>' to"
                    +" participate in the workspace for '<%ar.writeHtml(ngc.getFullName());%>'."
                    +"\n\nThe links below will make registration quick and easy, and"
                    +" after that you will be able to"
                    +" participate directly with the others through the site.";
    $scope.emailList = "";
    $scope.results = [];
    $scope.retAddr = "<%=ar.baseURL%><%=ar.getResourceURL(ngc, "frontPage.htm")%>";
    $scope.addressing = true;

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
    $scope.refresh = function() {
        getAllInvites();
    }
    getAllInvites();
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
    function inviteOne(newEmail, newName) {
        if (!newName || newName.length==0) {
            alert("Enter a name before inviting this person");
            return;
        }
        if (!newEmail || newEmail.length==0) {
            alert("Enter a email address before inviting this person");
            return;
        }
        var obj = {};
        obj.name = newName;
        obj.email = newEmail;
        obj.role = $scope.newRole;
        obj.msg = $scope.message;
        obj.status = "New";
        obj.timestamp = new Date().getTime();
        updateInvite(obj);
        $scope.newName = "";
        $scope.newEmail = "";
    }
    
    $scope.blastIt = function() {
        $scope.addressing = false;
        list = parseList($scope.emailList);
        console.log("LIST", list);
        list.forEach( function(item) {
            console.log("inviting: ", item);
            inviteOne(item, item);
        });
        $scope.emailList = "";
    }
});

function parseList(inText) {
    var outList = [];
    var oneAddress = "";
    for (var i=0; i<inText.length; i++) {
        var ch = inText.charAt(i);
        if (ch==";" || ch=="," || ch=="\n" || ch==" ") {
            var trimmed = oneAddress.trim();
            if (trimmed.length>0) {
                outList.push(trimmed);
            }
            oneAddress = "";
        }
        else if (ch==" ") {
            //ignore char
        }
        else {
            oneAddress = oneAddress + ch;
        }
    }
    var trimmed = oneAddress.trim();
    if (trimmed.length>0) {
        outList.push(trimmed);
    }
    return outList;
}
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
    .spacey tr td{
        padding: 8px;
    }
    .spacey {
        width: 100%;
        max-width: 800px;
    }
    </style>
    
    <p><i>Add people to the project by clicking on selecting a role, entering a list of email addresses, and a message to send to each as an invitation.</i></p>

    <div class="well">
    <table class="spacey" ng-show="addressing">
    
    <tr>
        <td>Role:</td>
        <td><select class="form-control" ng-model="newRole" ng-options="value for value in allRoles"></select></td>
    </tr>
    <tr>
        <td>Addresses:</td>
        <td><textarea class="form-control" ng-model="emailList" style="height:150px;"
             placeholder="Enter list of email addresses on separate lines or separated by commas"></textarea></td>
    </tr>
    <tr>
        <td>Message:</td>
        <td><textarea class="form-control" ng-model="message" style="height:150px;"
            placeholder="Enter a message to send to all invited people"></textarea></td>
    </tr>
    <tr>
        <td></td>
        <td>
            <button class="btn btn-primary btn-raised" ng-click="blastIt()" ng-show="emailList">Send Invitations</button>
            <button class="btn btn-raised" ng-click="addressing=false">Close</button>
        </td>
    </tr>
    <tr ng-show="results.length>0">
        <td></td>
        <td><div ng-repeat="res in results track by $index">Sent to: <b>{{res}}</b></div></td>
    </tr>
    </table>
    <div  ng-hide="addressing">
       <button class="btn btn-primary btn-raised" ng-click="addressing=true">Open to Send More</button>
    </div>
    </div>
    

  <h2>Invited - to see latest status: <button class="btn btn-default btn-raised" ng-click="refresh()">Refresh List</button></h2>
  
    <table class="table spacey">
    <tr><th>Email</th><th>Name</th><th>Status</th><th>Date</th><th>Visited</th></tr>
    <tr ng-repeat="invite in invitations" title="This form only displays the invited people, go to 'Invite Users' to re-invite a person"
        ng-click="reset(invite)">
        <td>{{invite.email}}</td>
        <td>{{invite.name}}</td>
        <td>{{invite.status}}</td>
        <td>{{invite.timestamp | date}}</td>
        <td>{{invite.joinTime | date}}</td>
    </tr>

    </table>

    
    
</div>
<script src="<%=ar.retPath%>templates/InviteModal.js"></script>

