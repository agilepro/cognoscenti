<%@page errorPage="/spring2/jsp/error.jsp"
%><%@ include file="/include.jsp"
%><%

    ar.assertLoggedIn("Must be logged in to edit roles");

    String pageId      = ar.reqParam("pageId");
    String siteId      = ar.reqParam("siteId");
    String roleName    = ar.defParam("role", "Members");
    
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

<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal, AllPeople) {
    setUpLearningMethods($scope, $modal, $http);
    window.setMainPageTitle("Multi-Person Invite");
    $scope.allRoles  = <%allRoles.write(out,2,2);%>;
    $scope.newRole = "<%ar.writeJS(roleName);%>"
    $scope.isFrozen = <%= isFrozen %>;
    $scope.invitations = [];

    $scope.message = "Hello,\n\nYou have been asked by '<%ar.writeHtml(uProf.getName());%>' to"
                    +" participate in a role of the project '<%ar.writeHtml(ngw.getFullName());%>' on Weaver."
                    +"\n\nWeaver is a collaboration site that helps teams work together better.  "
                    +"You can share documents, hold a discussion, and prepare for  meetings, "
                    +"all securely shared within a workspace accessible only to members.  "
                    +"Weaver is supported by volunteers.  Join us and see how it works.\n";
    $scope.emailList = "";
    $scope.results = [];
    $scope.retAddr = "<%=ar.baseURL%><%=ar.getResourceURL(ngw, "FrontPage.htm")%>";
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
        obj.ss = "Invitation to workspace '<%ar.writeHtml(ngw.getFullName());%>'";
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
                <span class="dropdown-item" type="button" ng-click="openTopicCreator()"
                    aria-labelledby="createNewSingleInvite"><a class="nav-link" role="menuitem" tabindex="-1" href="RoleInvite.htm">
                        <span class="fa fa-envelope"></span> &nbsp;Invite Users</a></span>
            </li>
        </ul>
    </span>
    <span>
        <h1 class="d-inline page-name" id="mainPageTitle">Multi-Person Invite</h1>
    </span>
</div>

<%@include file="ErrorPanel.jsp"%>

<% if (userReadOnly) { %>

<div class="guideVocal" style="margin-top:80px">
    You are not allowed to invite people to the workspace, because
    you are not playing an update role in the workspace.  
    
    If you wish to invite people, speak to the administrator of this 
    workspace / site and have your membership level changed to an
    active user.
</div>

<% } else { %>

    <div class="container-fluid override m-3">
        <div class="d-flex col-12 m-3">
            <div class="contentColumn">
                <span class="h6"><i>Add people (by email address) to a role of the project by entering a list of email addresses, a message, and a role.  Each email address will receive an invitation.</i></span>

                <div class="well col-12 m-2" ng-hide="isFrozen">
                    <div ng-show="addressing">
                        <div class="row d-flex my-3">
                            <span class="col-2">
                            <label class="h6">Email Addresses</label></span>
                            <span class="col-10">
                                <textarea class="form-control" ng-model="emailList" placeholder="Enter list of email addresses on separate lines or separated by commas"></textarea>
                            </span>
                        </div>
                        <div class="row d-flex my-3">
                            <span class="col-2">
                            <label class="h6">Role</label></span>
                            <span class="col-10">
                            <select class="form-control" ng-model="newRole"
                                    ng-options="r for r in allRoles"></select>
                            </span>
                        </div>
                        <div class="row d-flex my-3">
                            <span class="col-2">
                            <label class="h6">Message</label></span>
                            <span class="col-10"><textarea class="form-control" style="height:200px" ng-model="message"
                            placeholder="Enter a message to send to all invited people"></textarea></span>
                        </div>
                        <div class="d-flex my-3">
                            <button ng-click="addressing=false" class="btn btn-danger btn-default btn-raised">Close</button>
                            <button ng-click="blastIt()" class="btn btn-primary btn-raised btn-default ms-auto" 
                                    ng-show="emailList">Send Invitations</button>
                            
                        </div>
                    </div>
                    <div ng-hide="addressing">
                        <button class="btn btn-primary btn-wide btn-raised" ng-click="addressing=true">Open to Send More</button>
                    </div>
                </div>  
                <div class="well" style="max-width:500px;margin-bottom:50px" ng-show="isFrozen">
                You can't invite anyone because this workspace is frozen or deleted.
                </div> 
    
 
<% } %> 

   <h2 class="h4 m-3">Previously Invited</h2>

    <div><button class="btn btn-default btn-secondary btn-raised m-3" ng-click="refresh()">Refresh List</button></div>
  
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
<script src="<%=ar.retPath%>new_assets/templates/InviteModal.js"></script>

