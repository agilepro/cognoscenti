<%@ include file="/include.jsp"
%><%@ include file="/functions.jsp"
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

    <div class="container-fluid override mb-4 mx-3 d-inline-flex">
        <span class="dropdown mt-1">
            <button class="btn btn-outline-secondary btn-tiny dropdown-toggle" type="button" id="dropdownInfoMenu"
                data-bs-toggle="dropdown" aria-expanded="false">
            </button>
            <ul class="dropdown-menu" aria-labelledby="dropdownInfoMenu">
                <li>
                    <button class="dropdown-item" onclick="window.location.reload(true)"><span class="fa fa-refresh"></span> &nbsp;Refresh</button>
                    <span class="dropdown-item" type="button"><a class="nav-link" role="menuitem" href="SiteAdmin.htm"><span class="fa fa-cogs"></span> &nbsp;Site Admin</a></span>
                    <span class="dropdown-item" type="button"><a class="nav-link" role="menuitem" href="SiteUsers.htm"><span class="fa fa-users"></span> &nbsp;User List</a></span>
                    <span class="dropdown-item" type="button"><a class="nav-link" role="menuitem" href="SiteStats.htm">
                        <span class="fa fa-line-chart"></span> &nbsp;Site Statistics</a></span>
                        <span class="dropdown-item" type="button" aria-labelledby="siteLedger">
                            <a class="nav-link" role="menuitem" href="SiteLedger.htm"><span class="fa fa-money"></span> &nbsp;Site Ledger </a>
                        </span>

                    <% if (ar.isSuperAdmin()) { %>
                        <span class="dropdown-item" type="button"><a class="nav-link" role="menuitem"
                                href="../../../v/su/SiteDetails.htm?siteKey=<%=siteId%>"><span class="fa fa-user-secret"></span> &nbsp;Super
                                Admin</a></span>
                        <% } %>
                </li>
            </ul>
        </span>
        <span>
            <h1 class="d-inline page-name">Create New Workspace</h1>
        </span>
    </div>

<div ng-show="siteInfo.siteMsg">

</div>



<%@include file="../jsp/ErrorPanel.jsp"%>


<div class="container-fluid mx-0" ng-hide="siteInfo.isDeleted || siteInfo.frozen || siteInfo.offLine">
    
<div class="container-fluid override mx-2">
    <div class="form-group fs-5 d-flex py-2">
        <label class="col-2 fixed-width-md bold labelColumn btn btn-outline-primary mt-2 text-start">
            New Workspace Name 
        </label>
        <span class="col-9 mt-2">
            <input type="text" class="form-control rounded-2" ng-model="newWorkspace.newName" placeholder="Enter a name for this new workspace"/>
            <span class="d-flex">
            <span class="guideVocal" >Pick a short clear name that would be useful to people that don't already know about the group using the workspace. You can change the <b>display name</b> at any time. </span>
            
            </span>
        </span>
    </div>
    <div class="form-group fs-5 d-flex border-bottom border-1 py-2">
        <label class="col-2 fixed-width-md bold labelColumn btn btn-outline-primary mt-2 text-start">
            URL Address:
        </label>
        <span class="col-9 mt-2">
            <span class="d-flex">
            &nbsp; {{getURLAddress()}}</span>
            <span class="guideVocal text-secondary-emphasis col-5">Note: The first name you pick will set the <b>URL address</b> for
            the workspace. That will be permanent; the URL can not be changed later.</span>
        </span>
    </div>
    <div class="form-group py-2 guideVocal" ng-show="showNameHelp" ng-click="showNameHelp=!showNameHelp">
        
    </div>
    <div class="form-group fs-5 d-flex border-bottom border-1 py-2">
        <label class="col-2 fixed-width-md bold labelColumn btn btn-outline-primary mt-2 text-start" ng-click="showPurposeHelp=!showPurposeHelp">
            Workspace Aim
        </label>
        <span class="col-9 mt-2">
            <textarea class="form-control rounded-2" ng-model="newWorkspace.purpose" placeholder="Describe the aim of the workspace"></textarea>
            <span class="d-flex">
                <span class="guideVocal">Describe in a sentence or two the <b>aim</b> (or purpose) of the workspace in a way that people who are not yet part of the workspace will understand, and to help them know whether they should or should not be part of that workspace. This description will be available to the public if the workspace ever appears in a public list of workspaces.</span>
            </span>
        </span>
    </div>
    
    <div class="form-group fs-5 d-flex border-bottom border-1 py-2">
        <label class="col-2 fixed-width-md bold labelColumn btn btn-outline-primary mt-2 text-start" ng-click="showFrozenHelp=!showFrozenHelp">
            Frozen Workspace
        </label>
        <div class="col-9">
            <input type="checkbox" ng-model="newWorkspace.frozen"/> Frozen
            <% if (onlyAllowFrozen) { %> (only frozen allowed, already 
                <%=workspaceLimit%><% if (surplusWorkspaces) {%>+<%}%> active workspaces) <% } %><br/>
            <span class="d-flex">
                <span class="guideVocal">A frozen workspace is one that is not active.  It can be used to represent a workspace that is no longer active, or to represent a workspace that is not yet active.  You can create as many frozen workspaces as you like, but only <b><%=workspaceLimit%> </b>active workspaces.</span>
            </span>
        </div>
    </div>
    <div class="form-group fs-5 d-flex border-bottom border-1 py-2">
        <div class="col-1 fixed-width-md"></div>
        <div class="container well guideVocal m-3 col-9"> Workspaces can be active, frozen or deleted. Only active workspaces can support
        organizational work. <br /> This site is limited to <b> {{siteInfo.workspaceLimit}} </b> active workspaces according
        to the current payment plan. <br /> You are allowed unlimited frozen workspaces to represent an accurate
        organizational hierarchy. <br />***<br /> If you find you can only create a frozen workspace, go ahead and create it
        frozen, and then go to the other projects and sort out which ones need to be active, or change your plan to allow
        for more. </div>
    </div>
    <div class="form-group fs-5 d-flex border-bottom border-1 py-2">
        <label class="col-2 fixed-width-md bold labelColumn btn btn-outline-primary mt-2 text-start" >
            Initial Members
        </label>
        <span class="col-9">
            <tags-input ng-model="newWorkspace.members" placeholder="Enter email/name of members for this workspace" display-property="name" key-property="uid" replace-spaces-with-dashes="false" add-on-space="true" add-on-comma="true" on-tag-added="updatePlayers()" on-tag-removed="updatePlayers()" class="rounded-2">
                <auto-complete source="loadPersonList($query)" min-length="1"></auto-complete>
            </tags-input>
            <span class="d-flex">
                <span class="guideVocal">Members are allowed to access the workspace. You can enter their email address if they have not accessed the system
                before. If not novices, type three letters to get a list of known users that match. Later, you can add and remove
                members whenever needed.<br />*** <br /> After the workspace is created go to each <b>novice</b> user and send them an
                invitation to join.</span>
            </span>
        </span>
    </div>
    <div class="form-group fs-5 d-flex border-bottom border-1 py-2" ng-show="newWorkspace.parentName">
        <label class="col-2 fixed-width-md bold labelColumn btn btn-outline-primary mt-2 text-start" ng-click="showParentHelp=!showParentHelp">
            Initial Parent  
        </label>
        <span class="col-9 mt-2 form-inline form-group">
            <input class="form-control rounded-2 mt-2" disabled ng-model="newWorkspace.parentName"/>
            <span class="d-flex">
                <span class="guideVocal">Workspaces can be arranged into a tree, with child workspaces nested below parent workspaces. <br /> To change the
                structure of the tree, this parent can be changed at any time after the workspace is created.</span>
            </span>
        </span>
    </div>





    <div class="form-group pb-5">
        <button class="btn btn-primary btn-default btn-raised" ng-click="createNewWorkspace()">
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
        <p>If you would like some guidance in how to create a workspace, and how sites and workspaces work, please check the tutorial on the discussion of <a href="https://s06.circleweaver.com/Tutorial02.html">Sites &amp; Workspaces</a>
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