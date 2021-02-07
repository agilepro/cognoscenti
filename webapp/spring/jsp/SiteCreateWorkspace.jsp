<%@ include file="/spring/jsp/include.jsp"
%><%@ include file="/spring/jsp/functions.jsp"
%><%!
    String pageTitle="";
%><%
/*
Required parameter:

    1. accountId : This is the id of a site and used to retrieve NGBook.

*/

    String accountKey = ar.reqParam("siteId");
    
    //this page should only be called when logged in and having access to the site
    ar.assertLoggedIn("Must be logged in to create a workspace");
    UserProfile curUser = ar.getUserProfile();
    
    NGBook site = ar.getCogInstance().getSiteByIdOrFail(accountKey);
    ar.setPageAccessLevelsWithoutVisit(site);
    ar.assertMember("Must be an executive of a site to create a new workspace");
    String debugMessage = "";
    if (ar.isMember()) {
        debugMessage += ar.getBestUserId() + " is a member of "+ar.ngp.getFullName();
    }
    else {
        debugMessage += ar.getBestUserId() + " is NOT a member of "+ar.ngp.getFullName();
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
    List<NGPageIndex> templates = uProf.getValidTemplates(ar.getCogInstance());
    JSONArray templateList = new JSONArray();

    JSONObject newWorkspace = new JSONObject();
    newWorkspace.put("newName", ar.defParam("pname", ""));
    newWorkspace.put("purpose", ar.defParam("purpose", ""));
    newWorkspace.put("parent", ar.defParam("parent", ""));
    newWorkspace.put("members", new JSONArray());

    for (NGPageIndex ngpi : templates) {
        JSONObject jo = new JSONObject();
        jo.put("key", ngpi.containerKey);
        jo.put("name", ngpi.containerName);
        templateList.put(jo);
    }

    String desc = ar.defParam("desc", "");


    /*
    Data to the server is the workspace command structure
    {
        newName:"",
        purpose:"",
        parent: "",
        members: [],
        template:""
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
    $scope.accountKey = "<%ar.writeJS(accountKey);%>";
    $scope.templateList = <% templateList.write(ar.w,2,4); %>;
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

    $scope.updatePlayers = function() {
        $scope.newWorkspace.members = cleanUserList($scope.newWorkspace.members);
    }
    $scope.createNewWorkspace = function() {
        if (!$scope.newWorkspace.newName) {
            alert("Please enter a name for this new workspace.");
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
            var newws = "../"+data.key+"/roleManagement.htm";
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

<div ng-app="myApp" ng-controller="myCtrl">

<div ng-show="siteInfo.siteMsg">
    <div class="siteMsg">{{siteInfo.siteMsg}}</div>
</div>



<%@include file="ErrorPanel.jsp"%>


<style>
.spacey td {
    padding:5px;
}
</style>
<div style="max-width:500px" ng-hide="siteInfo.isDeleted || siteInfo.frozen || siteInfo.offLine">

    <div class="form-group" ng-show="newWorkspace.parent">
        <label ng-click="showNameHelp=!showNameHelp">
            Parent
        </label>
        <input disabled="disabled" class="form-control" ng-model="newWorkspace.parent"/>
    </div>
    <div class="form-group">
        <label ng-click="showNameHelp=!showNameHelp">
            New Workspace Name &nbsp; <i class="fa fa- fa-question-circle-o"></i>
        </label>
        <input type="text" class="form-control" ng-model="newWorkspace.newName"/>
    </div>
    <div class="form-group">
        <label>
            URL Address:
        </label>
        &nbsp; {{getURLAddress()}}
    </div>
    <div class="guideVocal" ng-show="showNameHelp" ng-click="showNameHelp=!showNameHelp">
        Pick a short clear name that would be useful to people that don't already know
        about the group using the workspace.  You can change the name at any time,
        however the first name you pick will set the URL address and that can not be
        changed later.
    </div>
    <div class="form-group">
        <label ng-click="showPurposeHelp=!showPurposeHelp">
            Workspace Purpose &nbsp; <i class="fa fa- fa-question-circle-o"></i>
        </label>
        <textarea class="form-control" ng-model="newWorkspace.purpose"></textarea>
    </div>
    <div class="guideVocal" ng-show="showPurposeHelp" ng-click="showPurposeHelp=!showPurposeHelp">
        Describe in a sentence or two the <b>purpose</b> of the workspace in a way that
        people who are not (yet) part of the workspace will understand,
        and to help them know whether they should or should not be
        part of that workspace. <br/>
        This description will be available to the public if the workspace
        ever appears in a public list of workspaces.
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


    <div class="form-group">
        <button class="btn btn-primary btn-raised" ng-click="createNewWorkspace()">
            Create Workspace</button>
    </div>
    <!--div class="form-group" ng-show="templateList && templateList.length>0">
        <label >Select Template (optional)</label>
        <select class="form-control" ng-model="newWorkspace.template"
                ng-options="tmp.name for tmp in templateList">
                <option value="">-- no template --</option>
        </select>
    </div-->
    
    <!--pre>
    < debugMessage >
    </pre-->

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


</div>