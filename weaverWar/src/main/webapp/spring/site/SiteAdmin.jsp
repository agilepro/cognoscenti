<%@page errorPage="/spring/jsp/error.jsp"
%><%@page import="com.purplehillsbooks.weaver.NGRole"
%><%@page import="com.purplehillsbooks.weaver.License"
%><%@page import="com.purplehillsbooks.weaver.WorkspaceStats"
%><%@page import="com.purplehillsbooks.weaver.util.NameCounter"
%><%@ include file="/spring/jsp/include.jsp"
%><% 

    ar.assertLoggedIn("");
    String siteId = ar.reqParam("siteId");
    NGBook  ngb = ar.getCogInstance().getSiteByIdOrFail(siteId);
    JSONObject siteInfo = ngb.getConfigJSON();

    WorkspaceStats wStats = ngb.getRecentStats();

 
%> 

<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http) {
    window.setMainPageTitle("Site Administration");
    $scope.siteInfo = <%siteInfo.write(out,2,4);%>;
    $scope.newName = $scope.siteInfo.names[0];
    $scope.colorList = $scope.siteInfo.labelColors.join(",");

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };
    
    $scope.removeName = function(oldName) {
        $scope.siteInfo.names = $scope.siteInfo.names.filter( function(item) {
            return (item!=oldName);
        });
    }
    $scope.addName = function(newName) {
        $scope.removeName(newName);
        $scope.siteInfo.names.splice(0, 0, newName);
    }
    
    $scope.saveSiteInfo = function() {
        if ($scope.siteInfo.names.length===0) {
            alert("Site must have at least one name at all times.  Please add a name.");
            return;
        }
        var rawList = $scope.colorList.split(",");
        if (rawList.length>2) {
            var newList = [];
            rawList.forEach( function(item) {
                newList.push(item.trim());
            });
            $scope.siteInfo.labelColors = newList;
        }
        var postURL = "updateSiteInfo.json";
        var postdata = angular.toJson($scope.siteInfo);
        $scope.showError=false;
        $http.post(postURL, postdata)
        .success( function(data) {
            $scope.siteInfo = data;
            $scope.isEditing = '';
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
            $scope.isEditing = '';
        });
    };
    
    $scope.toggleEditor = function(editorName) {
        if ($scope.isEditing == editorName) {
            $scope.isEditing = "";
        }
        else {
            $scope.isEditing = editorName;
        }
    }


});

</script>


<style>
.spaceyTable tr td {
    padding:8px;
}

.helpColumn {
    max-width:400px;
}
.dataColumn {
    max-width:400px;
}
</style>


<div>

<%@include file="../jsp/ErrorPanel.jsp"%>

    <div class="upRightOptions rightDivContent">
      <span class="dropdown">
        <button class="btn btn-default btn-raised dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
        Options: <span class="caret"></span></button>
        <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
          <li role="presentation"><a role="menuitem" 
              href="SiteAdmin.htm">Site Admin</a></li>
          <li role="presentation"><a role="menuitem" 
              href="SiteUsers.htm">User List</a></li>
          <li role="presentation"><a role="menuitem" 
              href="SiteStats.htm">Site Statistics</a></li>
          <li role="presentation"><a role="menuitem"
              href="SiteLedger.htm">Site Charges</a></li>
          <li role="presentation"><a role="menuitem" 
              href="TemplateEdit.htm">Template Edit</a></li>
          <% if (ar.isSuperAdmin()) { %>
          <li role="presentation" style="background-color:yellow"><a role="menuitem"
              href="../../../v/su/SiteDetails.htm?siteKey=<%=siteId%>">Super Admin</a></li>
          <% } %>
        </ul>
      </span>
    </div>


    <div class="generalContent">
         <table class="spaceyTable">
            <tr ng-dblclick="toggleEditor('NewName')">
                <td class="labelColumn" ng-click="toggleEditor('NewName')">New Name:</td>
                <td class="form-inline dataColumn" ng-show="isEditing =='NewName'">
                    <input type="text" class="form-control" ng-model="newName">
                    <button ng-click="addName(newName)" class="btn btn-primary btn-raised">Change Name</button>
                </td>
                <td class="form-inline dataColumn" ng-hide="isEditing =='NewName'">
                    <b>{{newName}}</b>
                </td>
                <td ng-hide="isEditing =='NewName'" class="helpColumn"></td>
                <td ng-show="isEditing =='NewName'" class="helpColumn guideVocal">
                    If you change the display name of a site, it will display with the new name wherever the site is listed, but the key to access the site (in the URL) will not change.
                </td>
            </tr>
            <tr ng-dblclick="toggleEditor('SiteDescription')">
                <td class="labelColumn" ng-click="toggleEditor('SiteDescription')">Site Description:</td>
                <td class=" dataColumn" ng-hide="isEditing =='SiteDescription'">
                   {{siteInfo.description}}
                </td>
                <td class=" dataColumn" ng-show="isEditing =='SiteDescription'">
                    <textarea  class="form-control markDownEditor" rows="4" ng-model="siteInfo.description"
                    title="The description appears in places where the user needs to know a little more about the purpose and background of the site itself."></textarea>
                    <button ng-click="saveSiteInfo()" class="btn btn-primary btn-raised">Save</button>
                </td>
                <td ng-hide="isEditing =='SiteDescription'" class="helpColumn"></td>
                <td ng-show="isEditing =='SiteDescription'" class="helpColumn guideVocal">
                    The description of the site appears in lists of sites to help others know what the 
                    purpose of the site is.
                </td>
            </tr>
            <tr ng-dblclick="toggleEditor('SiteMessage')">
                <td class="labelColumn" ng-click="toggleEditor('SiteMessage')">Site Message:</td>
                <td class=" dataColumn" ng-hide="isEditing =='SiteMessage'">
                    {{siteInfo.siteMsg}}
                </td>
                <td class=" dataColumn" ng-show="isEditing =='SiteMessage'">
                    <textarea  class="form-control" rows="2" ng-model="siteInfo.siteMsg"
                    title="This message appears on every page of every workspace.  Use for urgent updates and changes in site status."></textarea>
                    <button ng-click="saveSiteInfo()" class="btn btn-primary btn-raised">Save</button>
                </td>
                <td ng-hide="isEditing =='SiteMessage'" class="helpColumn"></td>
                <td ng-show="isEditing =='SiteMessage'" class="helpColumn guideVocal">
                    Set a message and it will show on every page of every workspace in the site.</td>
            </tr>
            <tr ng-dblclick="toggleEditor('LabelColors')">
                <td class="labelColumn" ng-click="toggleEditor('LabelColors')">Label Colors:</td>
                <td class=" dataColumn" ng-hide="isEditing =='LabelColors'">
                    <textarea disabled class="form-control" rows="2" ng-model="colorList"
                    title="A comma separated list of standard color names."></textarea>
                </td>
                <td class=" dataColumn" ng-show="isEditing =='LabelColors'">
                    <textarea  class="form-control" rows="2" ng-model="colorList"
                    title="A comma separated list of standard color names."></textarea>
                    <button ng-click="saveSiteInfo()" class="btn btn-primary btn-raised">Save</button>
                </td>
                <td ng-hide="isEditing =='LabelColors'" class="helpColumn"></td>
                <td ng-show="isEditing =='LabelColors'" class="helpColumn guideVocal">
                    Use web standard color names to create the set of colors that you can set on labels.
                </td>
            </tr>
            <tr ng-dblclick="toggleEditor('CreatorLimit')">
                <td class="labelColumn" ng-click="toggleEditor('CreatorLimit')">Creator User Limit:</td>
                <td class=" dataColumn" ng-hide="isEditing =='CreatorLimit'">
                    {{siteInfo.editUserLimit}}
                </td>
                <td class=" dataColumn" ng-show="isEditing =='CreatorLimit'">
                    <input type="text" ng-model="siteInfo.editUserLimit">
                    <button ng-click="saveSiteInfo()" class="btn btn-primary btn-raised">Save</button>
                </td>
                <td ng-hide="isEditing =='CreatorLimit'" class="helpColumn"></td>
                <td ng-show="isEditing =='CreatorLimit'" class="helpColumn guideVocal">
                    A site owner can set a limit to the number of creator users that the site is allowed to have.  This allows the site owner to control costs by preventing more creator users from being added to the site.
                </td>
            </tr>
            <tr ng-dblclick="toggleEditor('ReaderLimit')">
                <td class="labelColumn" ng-click="toggleEditor('ReaderLimit')">Reader User Limit:</td>
                <td ng-hide="isEditing =='ReaderLimit'">
                    {{siteInfo.viewUserLimit}}
                </td>
                <td ng-show="isEditing =='ReaderLimit'">
                    <input type="text" ng-model="siteInfo.viewUserLimit">
                    <button ng-click="saveSiteInfo()" class="btn btn-primary btn-raised">Save</button>
                </td>
                <td ng-hide="isEditing =='ReaderLimit'" class="helpColumn"></td>
                <td ng-show="isEditing =='ReaderLimit'" class="helpColumn guideVocal">
                    A site owner can set a limit to the number of read-only users that the site is allowed to have.  This allows the site owner to control costs by preventing more reader users from being added to the site.
                </td>
            </tr>
            <tr ng-dblclick="toggleEditor('WorkspaceLimit')">
                <td class="labelColumn" ng-click="toggleEditor('WorkspaceLimit')">Active Workspace Limit:</td>
                <td ng-hide="isEditing =='WorkspaceLimit'">
                    {{siteInfo.workspaceLimit}}
                </td>
                <td ng-show="isEditing =='WorkspaceLimit'">
                    <input type="text" ng-model="siteInfo.workspaceLimit">
                    <button ng-click="saveSiteInfo()" class="btn btn-primary btn-raised">Save</button>
                </td>
                <td ng-hide="isEditing =='WorkspaceLimit'" class="helpColumn"></td>
                <td ng-show="isEditing =='WorkspaceLimit'" class="helpColumn guideVocal">
                    A site owner can set a limit to the number of active workspace that the site is allowed to have.  This allows the site owner to control costs by preventing more workspaces from being added to the site.  When this limit is reached in the site, you will need to either freeze or delete a workspace before you can add a new one.
                </td>
            </tr>
            <tr ng-dblclick="toggleEditor('FrozenLimit')">
                <td class="labelColumn" ng-click="toggleEditor('FrozenLimit')">Frozen Workspace Limit:</td>
                <td ng-hide="isEditing =='FrozenLimit'">
                    {{siteInfo.frozenLimit}}
                </td>
                <td ng-show="isEditing =='FrozenLimit'">
                    <input type="text" ng-model="siteInfo.frozenLimit">
                    <button ng-click="saveSiteInfo()" class="btn btn-primary btn-raised">Save</button>
                </td>
                <td ng-hide="isEditing =='FrozenLimit'" class="helpColumn"></td>
                <td ng-show="isEditing =='FrozenLimit'" class="helpColumn guideVocal">
                    A site owner can set a limit to the number of frozen workspace that the site is allowed to have.  This allows the site owner to control costs by preventing more workspaces from being added to the site.  When this limit is reached in the site, you will need to delete a workspace before you another workspace can be frozen.
                </td>
            </tr>
            <tr ng-dblclick="toggleEditor('DocumentLimit')">
                <td class="labelColumn" ng-click="toggleEditor('DocumentLimit')">Document Limit:</td>
                <td ng-hide="isEditing =='DocumentLimit'">
                    {{siteInfo.fileSpaceLimit}} Megabytes
                </td>
                <td ng-show="isEditing =='DocumentLimit'">
                    <input type="text" ng-model="siteInfo.fileSpaceLimit">
                    <button ng-click="saveSiteInfo()" class="btn btn-primary btn-raised">Save</button>
                </td>
                <td ng-hide="isEditing =='DocumentLimit'" class="helpColumn"></td>
                <td ng-show="isEditing =='DocumentLimit'" class="helpColumn guideVocal">
                    A site owner can set a limit to the total size (in megabytes) for all documents the site is allowed to have.  This allows the site owner to control costs by preventing more documents from being added to the site.  When this limit is reached in the site, you will need to delete some documents before you another document can be added.
                </td>
            </tr>
        <% if (ar.isSuperAdmin()) { %>
            <tr ng-dblclick="toggleEditor('Flags')">
                <td class="labelColumn"  ng-click="toggleEditor('Flags')">Flags:</td>
                <td class=" dataColumn" ng-hide="isEditing =='Flags'">
                    <input type="checkbox" ng-model="siteInfo.showExperimental"> Show Experimental &nbsp; &nbsp; 
                    <input type="checkbox" ng-model="siteInfo.frozen"> Frozen &nbsp; &nbsp; 
                    <input type="checkbox" ng-model="siteInfo.isDeleted"> isDeleted &nbsp; &nbsp; 
                    <input type="checkbox" ng-model="siteInfo.offLine"> offLine
                </td>
                <td class=" dataColumn" ng-show="isEditing =='Flags'">
                    <input type="checkbox" ng-model="siteInfo.showExperimental"> Show Experimental &nbsp; &nbsp; 
                    <input type="checkbox" ng-model="siteInfo.frozen"> Frozen &nbsp; &nbsp; 
                    <input type="checkbox" ng-model="siteInfo.isDeleted"> isDeleted &nbsp; &nbsp; 
                    <input type="checkbox" ng-model="siteInfo.offLine"> offLine
                    <br/>
                    <button ng-click="saveSiteInfo()" class="btn btn-primary btn-raised">Save</button>
                </td>
                <td ng-show="isEditing =='Flags'" class="helpColumn guideVocal">
                    Super admin only.  John, you know who you are.</td>
                <td ng-hide="isEditing =='Flags'" class="helpColumn"></td>
            </tr>
        <% } %>
            <tr>
                <td class="labelColumn">Site Key:</td>
                <td>{{siteInfo.key}}</td>
            </tr>
        <% if (ar.isSuperAdmin()) { %>
            <tr ng-dblclick="toggleEditor('CurrentNames')">
                <td class="labelColumn" valign="top">Current Names:</td>
                 
                <td class=" dataColumn">
                    <div ng-repeat="name in siteInfo.names">
                        {{name}}
                        <img src="<%=ar.retPath%>/assets/iconDelete.gif" ng-click="removeName(name)">
                    </div>
                </td>
                <td ng-show="showHelpNames" ng-click="showHelpNames = !showHelpNames" class="helpColumn guideVocal">
                    Sites can have more than one names, but you can ignore that.</td>
                <td ng-hide="showHelpNames" ng-click="showHelpNames = !showHelpNames" class="helpColumn"></td>
            </tr>
        <% } %>
        </table>
    </div>
    <div style="height:400px"></div>
</div>
