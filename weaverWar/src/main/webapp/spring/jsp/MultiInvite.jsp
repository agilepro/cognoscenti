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

    boolean userReadOnly = site.userReadOnly(ar.getBestUserId()); 
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
        obj.ss = "Invitation to workspace '<%ar.writeHtml(ngc.getFullName());%>'";
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

<div>

<%@include file="ErrorPanel.jsp"%>

<% if (userReadOnly) { %>

<div class="guideVocal" style="margin-top:80px">
    You are not allowed to invite people to the workspace, because
    you are a passive 'read-only' user.  
    
    If you wish to invite people, speak to the administrator of this 
    workspace / site and have your membership level changed to an
    active user.
</div>

<% } else { %>

    <div class="upRightOptions rightDivContent">
      <span class="dropdown">
        <button class="btn btn-default btn-raised dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
        Options: <span class="caret"></span></button>
        <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
          <li role="presentation"><a role="menuitem" tabindex="-1"
              href="RoleManagement.htm">Manage Roles</a></li>
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
    
    <p><i>Add people (by email address) to a role of the project by entering a list of email addresses, a message, and a role.  Each email address will receive an invitation.</i></p>

  <div class="well" style="max-width:500px;margin-bottom:50px">
      <div ng-show="addressing">
    
        <div class="form-group">
            <label>Email Addresses</label>
            <textarea class="form-control" ng-model="emailList" style="height:150px;"
             placeholder="Enter list of email addresses on separate lines or separated by commas"></textarea>
        </div>
        <div class="form-group">
            <label>Message</label>
            <textarea class="form-control" style="height:200px" ng-model="message"
            placeholder="Enter a message to send to all invited people"></textarea>
        </div>
        <div class="form-group">
            <label>Role</label>
            <select class="form-control" ng-model="newRole"
                    ng-options="r for r in allRoles"></select>
        </div>
        <div>
            <button ng-click="blastIt()" class="btn btn-sm btn-primary btn-raised" 
                    ng-show="emailList"/>Send Invitations</button>
            <button ng-click="addressing=false" class="btn btn-sm btn-raised"/>Close</button>
        </div>
    </div>
    <div  ng-hide="addressing">
       <button class="btn btn-primary btn-raised" ng-click="addressing=true">Open to Send More</button>
    </div>
    </div>
    
 
<% } %> 

   <h2>Previously Invited</h2>

    <div><button class="btn btn-default btn-raised" ng-click="refresh()">Refresh List</button></div>
  
    <table class="table">
    <tr><th>Email</th><th>Name</th><th>Status</th><th>Date</th><th>Visited</th></tr>
    <tr ng-repeat="invite in invitations" title="This form only displays the invited people, go to 'Invite Users' to re-invite a person"
        ng-click="reset(invite)">
        <td>{{invite.email}}</td>
        <td>{{invite.name}}</td>
        <td>{{invite.status}}</td>
        <td>{{invite.timestamp |cdate}}</td>
        <td>{{invite.joinTime |cdate}}</td>
    </tr>

    </table>


    
</div>
<script src="<%=ar.retPath%>templates/InviteModal.js"></script>

