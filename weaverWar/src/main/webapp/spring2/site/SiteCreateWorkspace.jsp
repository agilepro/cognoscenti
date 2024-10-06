<%@ include file="/include.jsp"
%><%@ include file="/spring2/jsp/functions.jsp"
%><%
/*
Required parameter:

    1. siteId : This is the id of a site and used to retrieve NGBook.

*/

    String siteId = ar.reqParam("siteId");
    String parentKey = ar.defParam("parent", "");
    
    //this page should only be called when logged in and having access to the site
    ar.assertLoggedIn("Must be logged in to create a workspace");
    UserProfile curUser = ar.getUserProfile();
    
    NGBook site = ar.getCogInstance().getSiteByIdOrFail(siteId);
    ar.setPageAccessLevelsWithoutVisit(site);
    ar.assertExecutive("Must be an executive of a site to create a new workspace");
    String debugMessage = "";
    if (ar.canUpdateWorkspace()) {
        debugMessage += ar.getBestUserId() + " can update "+ar.ngp.getFullName();
    }
    else {
        debugMessage += ar.getBestUserId() + " can not update "+ar.ngp.getFullName();
    }
    debugMessage += "\nisSuperAdmin: "+ar.isSuperAdmin();
    debugMessage += "\nPRIMARY permission: "+site.primaryPermission(curUser);
    debugMessage += "\nSECONDARY permission: "+site.secondaryPermission(curUser);
    NGRole testPrimRole = site.getPrimaryRole();
    debugMessage += "\nPRIMARY ROLE   :"+testPrimRole.isExpandedPlayer(curUser,site);
    for (AddressListEntry alele : testPrimRole.getDirectPlayers() ) {
        String uid = alele.getUniversalId();
        debugMessage += "\n   - " + uid + " == " + curUser.hasAnyId(uid);
    }
    testPrimRole = site.getSecondaryRole();
    debugMessage += "\nSECONDARY ROLE   :"+testPrimRole.isExpandedPlayer(curUser,site);
    for (AddressListEntry alele : testPrimRole.getDirectPlayers() ) {
        String uid = alele.getUniversalId();
        debugMessage += "\n   - " + uid + " == " + curUser.hasAnyId(uid);
    }

    UserProfile  uProf =ar.getUserProfile();

    String desc = ar.defParam("desc", "");

    int unfrozenCount = site.countUnfrozenWorkspaces();
    int workspaceLimit = site.getWorkspaceLimit(); 
    boolean onlyAllowFrozen = (unfrozenCount >= workspaceLimit);
    boolean surplusWorkspaces = (unfrozenCount > workspaceLimit);
    
    NGPageIndex parentWorkspace = ar.getCogInstance().getWSBySiteAndKey(siteId, parentKey);
    
    JSONObject newWorkspace = new JSONObject();
    newWorkspace.put("newName", ar.defParam("pname", ""));
    newWorkspace.put("purpose", ar.defParam("purpose", ""));
    if (parentWorkspace != null) {
        newWorkspace.put("parentKey", parentWorkspace.containerKey);
        newWorkspace.put("parentName", parentWorkspace.containerName);
    }
    
    newWorkspace.put("members", new JSONArray());
    newWorkspace.put("frozen", onlyAllowFrozen);


    /*
    Data to the server is the workspace command structure
    {
        newName:"",
        purpose:"",
        parentKey: "",
        members: [],
        template:"",
        frozen: true
    }
    Data from the server is the workspace config structure
    {
      "accessState": "Live",
      "allNames": ["Darwin2"],
      "deleted": false,
      "frozen": false,
      "goal": "",
      "key": "darwin2",
      "parentKey": "",
      "parentName": "",
      "purpose": "",
      "showExperimental": false,
      "site": "goofoof"
    }
    */
%>

<script>
var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, AllPeople) {
    window.setMainPageTitle("Create New Workspace");
    $scope.siteInfo = <% site.getConfigJSON().write(ar.w,2,4); %>;
    $scope.selectedTemplate = "";
    $scope.newWorkspace = <% newWorkspace.write(ar.w,2,4); %>;

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        console.log("Error: "+serverErr);
        errorPanelHandler($scope, serverErr);
    };
    console.log("WORKSPACE LIMIT; <%=workspaceLimit%>");
    console.log("WORKSPACE LIMIT", $scope.siteInfo);
    $scope.updatePlayers = function() {
        $scope.newWorkspace.members = cleanUserList($scope.newWorkspace.members);
    }
    $scope.createNewWorkspace = function() {
        if (!$scope.newWorkspace.newName) {
            alert("Please enter a name for this new workspace.");
            return;
        }
        if (<%=onlyAllowFrozen%> && !$scope.newWorkspace.frozen) {
            alert("You are only allowed to create frozen workspaces at this time.");
            return;
        }
        var urlAddress = $scope.getURLAddress();
        if (urlAddress.length < 6) {
            alert("Please specify a longer name with more than 6 alphabet characters");
            return;
        }
        $scope.newWorkspace.members.forEach( function(item) {
            if (!item.uid) {
                item.uid = item.name;
            }
        });
        var postURL = "createWorkspace.json";
        var postdata = angular.toJson($scope.newWorkspace);
        console.log("new data", $scope.newWorkspace);
        $scope.showError=false;
        $http.post(postURL, postdata)
        .success( function(data) {
            console.log("CREATED WORKSPACE: ", data);
            var newws = "../"+data.key+"/RoleManagement.htm";
            window.location = newws;
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };

    $scope.getURLAddress = function() {
        var res = "";
        var str = $scope.newWorkspace.newName;
        var isInGap = false;
        for (i=0; i<str.length; i++) {
            var ch = str[i].toLowerCase();
            var isAddable = ( (ch>='a' && ch<='z') || (ch>='0' && ch<='9') );
            if (isAddable) {
                if (isInGap) {
                    res = res + "-";
                    isInGap = false;
                }
                res = res + ch;
            }
            else {
                isInGap = res.length > 0;
            }
        }
        return res;
    }
    $scope.loadPersonList = function(query) {
        var foo = AllPeople.findMatchingPeople(query, $scope.siteInfo.key);
        console.log("loadPersonList", query, AllPeople.getSiteObject($scope.siteInfo.key));
        return foo;
    }
    console.log("WCACHE", WCACHE);

});
</script>
<script src="<%=ar.retPath%>jscript/AllPeople.js"></script>

<div>

<div ng-show="siteInfo.siteMsg">
    <div class="siteMsg">{{siteInfo.siteMsg}}</div>
</div>



<%@include file="../jsp/ErrorPanel.jsp"%>


<style>
.spacey td {
    padding:5px;
}
.form-group {
    margin-top:25px;
}
</style>
<div class="container" ng-hide="siteInfo.isDeleted || siteInfo.frozen || siteInfo.offLine">

    <div class="form-group">
        <label ng-click="showNameHelp=!showNameHelp">
            New Workspace Name &nbsp; <i class="fa fa- fa-question-circle-o"></i>
        </label>
        <input type="text" class="form-control" ng-model="newWorkspace.newName"/>
    </div>
    <div>
        <label>
            URL Address:
        </label>
        &nbsp; {{getURLAddress()}}
    </div>
    <div class="guideVocal" ng-show="showNameHelp" ng-click="showNameHelp=!showNameHelp">
        Pick a short clear name that would be useful to people that don't already know
        about the group using the workspace.  You can change the <b>display name</b> at any time.
        <br/>
        The first name you pick will set the <b>URL address</b> for the workspace.  
        That will be permanent; the URL can not be changed later.
    </div>
    <div class="form-group">
        <label ng-click="showPurposeHelp=!showPurposeHelp">
            Workspace Aim &nbsp; <i class="fa fa- fa-question-circle-o"></i>
        </label>
        <textarea class="form-control" ng-model="newWorkspace.purpose"></textarea>
    </div>
    <div class="guideVocal" ng-show="showPurposeHelp" ng-click="showPurposeHelp=!showPurposeHelp">
        Describe in a sentence or two the <b>aim</b> (or purpose) of the workspace in a way that
        people who are not yet part of the workspace will understand,
        and to help them know whether they should or should not be
        part of that workspace. 
        <br/>
        This description will be available to the public if the workspace
        ever appears in a public list of workspaces.
    </div>
    <div class="form-group">
        <label ng-click="showFrozenHelp=!showFrozenHelp">
            Frozen Workspace &nbsp; <i class="fa fa- fa-question-circle-o"></i>
        </label>
        <div>
            <input type="checkbox" ng-model="newWorkspace.frozen"/> Frozen
            <% if (onlyAllowFrozen) { %> (only frozen allowed, already 
                <%=workspaceLimit%><% if (surplusWorkspaces) {%>+<%}%> active workspaces) <% } %>
        </div>
    </div>
    <div class="guideVocal" ng-show="showFrozenHelp" ng-click="showFrozenHelp=!showFrozenHelp">
        Workspaces can be active, frozen or deleted.  Only active workspaces can 
        support organizational work.
        <br/><br/>
        This site is limited to <b> {{siteInfo.workspaceLimit}} </b> active workspaces according
        to the current payment plan.
        <br/><br/>       
        You are allowed unlimited frozen workspaces to represent an accurate organizational hierarchy.
        <br/><br/>
        If you find you can only create a frozen workspace, go ahead and create it frozen, and then 
        go to the other projects and sort out which ones need to be active, or change your plan
        to allow for more.
    </div>
    <div class="form-group">
        <label ng-click="showMembersHelp=!showMembersHelp">
            Initial Members &nbsp; <i class="fa fa- fa-question-circle-o"></i>
        </label>
          <tags-input ng-model="newWorkspace.members" placeholder="Enter email/name of members for this workspace"
                      display-property="name" key-property="uid"
                      replace-spaces-with-dashes="false" add-on-space="true" add-on-comma="true"
                      on-tag-added="updatePlayers()"
                      on-tag-removed="updatePlayers()">
              <auto-complete source="loadPersonList($query)" min-length="1"></auto-complete>
          </tags-input>
    </div>
    <div class="guideVocal" ng-show="showMembersHelp" ng-click="showMembersHelp=!showMembersHelp">
        Members are allowed to access the workspace.
        You can enter their email address if they have not accessed the system before.
        If not novices, type three letters to get a list of known users that match.
        Later, you can add and remove members whenever needed.<br/>
        <br/>
        After the workspace is created go to each <b>novice</b> user and send them an
        invitation to join.
    </div>
    <div class="form-group" ng-show="newWorkspace.parentName">
        <label ng-click="showParentHelp=!showParentHelp">
            Initial Parent &nbsp; <i class="fa fa- fa-question-circle-o"></i>  
        </label>
        <div>
            <input class="form-control" disabled ng-model="newWorkspace.parentName"/>
        </div>
    </div>
    <div class="guideVocal" ng-show="showParentHelp" ng-click="showParentHelp=!showParentHelp">
        Workspaces can be arranged into a tree, with child workspaces nested
        below parent workspaces.  
        <br/>
        To change the structure of the tree, this parent can be changed at any time after 
        the workspace is created.
    </div>




    <div class="form-group">
        <button class="btn btn-primary btn-raised ms-auto" ng-click="createNewWorkspace()">
            Create Workspace</button>
    </div>

</div>

<div style="max-width:500px" ng-show="siteInfo.isDeleted">
    <div class="guideVocal">This site is marked as deleted and will automatically disappear at a point of time in the future.</div>
</div>
<div style="max-width:500px" ng-show="siteInfo.frozen">
    <div class="guideVocal">This site is frozen and no new workspaces can be created in it.</div>
</div>
<div style="max-width:500px" ng-show="siteInfo.offLine">
    <div class="guideVocal">This site is off line and no workspaces can be created in it at this time.</div>
</div>
<div class="container my-2">
    <div class="guideVocal">
        <p>
       If you would like some guidance in how to create a workspace, and how sites and workspaces work,
       please check the tutorial on the discussion of <a href="https://s06.circleweaver.com/Tutorial02.html">Sites &amp; Workspaces</a>
       for a complete walk through on how to do this.
       </p>
       <p>
       <a href="https://s06.circleweaver.com/Tutorial02.html"   target="Tutorials">
           <img src="https://s06.circleweaver.com/tutorial-files/Tutorial02-thumb.png"
                class="tutorialThumbnail"/>
       </a>
       </p>
    </div></div>

</div>