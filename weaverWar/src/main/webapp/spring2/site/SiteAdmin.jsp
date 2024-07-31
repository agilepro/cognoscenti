<%@page errorPage="/spring2/jsp/error.jsp"
%><%@page import="com.purplehillsbooks.weaver.NGRole"
%><%@page import="com.purplehillsbooks.weaver.License"
%><%@page import="com.purplehillsbooks.weaver.WorkspaceStats"
%><%@page import="com.purplehillsbooks.weaver.util.NameCounter"
%><%@ include file="/spring/jsp/include.jsp"
%><% 

    ar.assertLoggedIn("");
    Cognoscenti cog = ar.getCogInstance();
    String siteId = ar.reqParam("siteId");
    NGBook  site = ar.getCogInstance().getSiteByIdOrFail(siteId);
    JSONObject siteInfo = site.getConfigJSON();

    WorkspaceStats wStats = site.getRecentStats();

 
%> 

<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http) {
    window.setMainPageTitle("Site Administration");
    $scope.siteInfo = <%siteInfo.write(out,2,4);%>;
    $scope.siteStats = <%site.getStatsJSON(cog).write(out,2,4);%>;
    $scope.newName = $scope.siteInfo.names[0];
    $scope.colorList = $scope.siteInfo.labelColors.join(",");

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };
    
    $scope.chargeCreator = 3;
    $scope.chargeReader = 0;
    $scope.chargeActive = 0;
    $scope.chargeFrozen = 0;
    $scope.chargeDocument = 0;
    $scope.chargeEmail = 0;
    
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
            $scope.setSiteInfo(data);
            $scope.isEditing = '';
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
            $scope.isEditing = '';
        });
    };
    
    $scope.setSiteInfo = function(info) {
        $scope.siteInfo = info;
        $scope.siteInfo.workspaceLimit = $scope.siteInfo.editUserLimit;
        $scope.siteInfo.viewUserLimit = $scope.siteInfo.editUserLimit * 4;
        $scope.siteInfo.fileSpaceLimit = $scope.siteInfo.editUserLimit * 100;
        $scope.siteInfo.frozenLimit =  $scope.siteInfo.editUserLimit * 2;
            
        $scope.limitCharge = $scope.siteInfo.frozenLimit * $scope.chargeFrozen
            + $scope.siteInfo.workspaceLimit * $scope.chargeActive
            + $scope.siteInfo.viewUserLimit * $scope.chargeReader
            + ($scope.siteInfo.editUserLimit-1) * $scope.chargeCreator
            + $scope.siteInfo.fileSpaceLimit * $scope.chargeDocument;
        $scope.currentCharge = $scope.siteStats.numFrozen * $scope.chargeFrozen
            + $scope.siteStats.numActive * $scope.chargeActive
            + $scope.siteStats.readUserCount * $scope.chargeReader
            + ($scope.siteStats.editUserCount-1) * $scope.chargeCreator
            + $scope.siteStats.sizeDocuments * $scope.chargeDocument / 1000000;
    }
    $scope.setSiteInfo($scope.siteInfo);
    
    $scope.toggleEditor = function(editorName) {
        if ($scope.isEditing == editorName) {
            $scope.isEditing = "";
        }
        else {
            $scope.isEditing = editorName;
        }
    }
    $scope.recalcStats = function() {
        console.log("recalcStats");
        var getURL = "SiteStatistics.json?recalc=yes";
        $scope.showError=false;
        $http.get(getURL)
        .success( function(data) {
            $scope.setSiteInfo(data.stats);
            window.location.reload(false);
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };
    
    // auto refresh if stats are empty
    if ($scope.siteStats.editUserCount < 1) {
        console.log("Automatically recalculating statistics");
        $scope.recalcStats();
    }


});

</script>





<div ng-cloak>

<%@include file="../jsp/ErrorPanel.jsp"%>

<div class="container-fluid">
    <div class="row">
      <div class="col-md-auto fixed-width border-end border-1 border-secondary">
          <span class="btn btn-secondary btn-comment btn-raised m-3 pb-2 pt-0" type="button"><a class="nav-link" role="menuitem" 
              href="SiteAdmin.htm">Site Admin</a></span>
          <span class="btn btn-secondary btn-comment btn-raised m-3 pb-2 pt-0" type="button"><a class="nav-link" role="menuitem" 
              href="SiteUsers.htm">User List</a></span>
              <span class="btn btn-secondary btn-comment btn-raised m-3 pb-2 pt-0" type="button"><a class="nav-link" role="menuitem" 
              href="SiteStats.htm">Site Statistics</a></span>
              <span class="btn btn-secondary btn-comment btn-raised m-3 pb-2 pt-0" type="button"><a class="nav-link" role="menuitem"
              href="SiteLedger.htm">Site Charges</a></span>
              <span class="btn btn-secondary btn-comment btn-raised m-3 pb-2 pt-0" type="button"><a class="nav-link" role="menuitem" 
              href="TemplateEdit.htm">Template Edit</a></span>
          <% if (ar.isSuperAdmin()) { %>
            <span class="btn btn-secondary btn-comment btn-raised m-3 pb-2 pt-0" type="button"><a class="nav-link" role="menuitem"
              href="../../../v/su/SiteDetails.htm?siteKey=<%=siteId%>">Super Admin</a></span>
          <% } %>
            </div>


            <div class="d-flex col-9"><div class="contentColumn">
<div class="container-fluid">
                <div class="generalContent">
                    <div class="spaceyTable">
                       <div class="row" ng-dblclick="toggleEditor('NewName')">
                           <span class="col-2 labelColumn" ng-click="toggleEditor('NewName')" title="click to change site name">Site Name:</span>
                           <span class="col-2 dataColumn" ng-show="isEditing =='NewName'">
                               <input type="text" class="form-control mb-2" ng-model="newName">
                               <button ng-click="addName(newName)" class="btn btn-primary btn-raised">Change Name</button>
                           </span>
                           <span class="col-2 dataColumn" ng-hide="isEditing =='NewName'">
                               <b>{{newName}}</b>
                           </span>
                           <span class="col-2 helpColumn" ng-hide="isEditing =='NewName'"></span>
                           <span ng-show="isEditing =='NewName'" class="helpColumn guideVocal">
                               If you change the display name of a site, it will display with the new name wherever the site is listed, but the key to access the site (in the URL) will not change.
                           </span>
                       </div>
                       <div class="row"  >
                           <span class="col-2 labelColumn" ng-click="toggleEditor('SiteDescription')" title="click to change site description">Site Description:</span>
                           <span class="col-6 dataColumn" ng-hide="isEditing =='SiteDescription'">
                              {{siteInfo.description}}
                           </span>
                           <span class="col-6 dataColumn" ng-show="isEditing =='SiteDescription'">
                               <textarea  class="form-control markDownEditor mb-2" rows="4" ng-model="siteInfo.description"
                               title="The description appears in places where the user needs to know a little more about the purpose and background of the site itself."></textarea>
                               <button ng-click="saveSiteInfo()" class="justify-content-end btn btn-primary btn-raised">Save</button>
                           </span>
                           <span class="col-2 helpColumn" ng-hide="isEditing =='SiteDescription'"></span>
                           <span class="col-2 helpColumn guideVocal" ng-show="isEditing =='SiteDescription'" >
                               The description of the site appears in lists of sites to help others know what the 
                               purpose of the site is.
                           </span>
                       </div>
                       <div class="row" >
                           <span class="col-2 labelColumn" ng-click="toggleEditor('SiteMessage')">Site Message:</span>
                           <span class="col-6 dataColumn" ng-hide="isEditing =='SiteMessage'">
                               {{siteInfo.siteMsg}}
                           </span>
                           <span class="col-6 dataColumn" ng-show="isEditing =='SiteMessage'">
                               <textarea  class="form-control mb-2" rows="2" ng-model="siteInfo.siteMsg"
                               title="This message appears on every page of every workspace.  Use for urgent updates and changes in site status."></textarea>
                               <button ng-click="saveSiteInfo()" class="btn btn-primary btn-raised">Save</button>
                           </span>
                           <span ng-hide="isEditing =='SiteMessage'" class="col-2 helpColumn"></span>
                           <div ng-show="isEditing =='SiteMessage'" class="col-2 helpColumn guideVocal">
                               Set a message and it will show on every page of every workspace in the site.</div>
                       </div>
                       <div class="row" ng-dblclick="toggleEditor('LabelColors')">
                           <span class="col-2 labelColumn" ng-click="toggleEditor('LabelColors')">Label Colors:</span>
                           <span class="col-6 dataColumn" ng-hide="isEditing =='LabelColors'">
                               <textarea disabled class="form-control mb-2 col-5" rows="2" ng-model="colorList"
                               title="A comma separated list of standard color names."></textarea>
                           </span>
                           <span class="col-6 dataColumn" ng-show="isEditing =='LabelColors'">
                               <textarea  class="form-control mb-2"  rows="2" ng-model="colorList"
                               title="A comma separated list of standard color names."></textarea>
                               <button ng-click="saveSiteInfo()" class="btn btn-primary btn-raised">Save</button>
                           </span>
                           <span ng-hide="isEditing =='LabelColors'" class="col-2 helpColumn"></span>
                           <span ng-show="isEditing =='LabelColors'" class="col-2 helpColumn guideVocal">
                               Use web standard color names to create the set of colors that you can set on labels.
                           </span>
                       </div>


        </div>
        
        <div style="height:100px"></div>
        <span class="h5">Your Budget</span>
        
        <div class="spaceyTable">
            <div class="row">
                <span class="col-2"></span>
                <span class="col-2 numberColumn">Current Usage</span>
                <span class="col-2 numberColumn">Your Limits</span>
                <span class="col-4 helpColumn"></span>
            </div>
            <div class="row" ng-click="toggleEditor('CreatorLimit')">
                <span class="col-2 labelColumn" ng-click="toggleEditor('CreatorLimit')">Purchased Users:</span>
                <span class="col-2 numberColumn">
                    {{siteStats.editUserCount}}
                </span>
                <span class="col-2 numberColumn" ng-hide="isEditing =='CreatorLimit'">
                    {{siteInfo.editUserLimit}}
                </span>
                <span class="col-4 dataColumn" ng-show="isEditing =='CreatorLimit'">
                    <input type="text" ng-model="siteInfo.editUserLimit"  style="width:50px">
                    <button ng-click="saveSiteInfo()" class="btn btn-secondary btn-sm btn-wide">Save</button>
                </span>
                <span ng-hide="isEditing =='CreatorLimit'" class="helpColumn"></span>
                <span ng-show="isEditing =='CreatorLimit'" class="helpColumn guideVocal">
                    <p>A site owner can set a limit to the number of purchased (Update) users that the site is allowed to have.  This allows the site owner to control costs by preventing more update users from being added to the site.
                    The charge is $ {{chargeCreator|number}} per creator user.  The first user (the founder) is free.  We only charge for actual users that you have beyond the founder.</p>
                </span>
            </div>
            <div class="row" >
                <span class="col-2 labelColumn" ng-click="toggleEditor('ReaderLimit')">Observers:</span>
                <span class="col-2 numberColumn" ng-hide="isEditing =='ReaderLimit'">
                    {{siteStats.readUserCount}}
                </span>
                <span class="col-2 numberColumn" ng-hide="isEditing =='ReaderLimit'">
                    {{siteInfo.viewUserLimit}}
                </span>
                <span class="col-4" ng-show="isEditing =='ReaderLimit'" >
                    <input type="text" ng-model="siteInfo.viewUserLimit">
                    <button ng-click="saveSiteInfo()" class="btn btn-secondary btn-sm btn-wide">Save</button>
                </span>
                <span ng-hide="isEditing =='CreatorLimit'" class="helpColumn"></span>
                <span ng-show="isEditing =='CreatorLimit'" class="helpColumn guideVocal">
                    For each purchased update user, you can have 4 additional guest observer users.
                </span>
            </div>
            <div class="row" >
                <span class="col-2 labelColumn" ng-click="toggleEditor('WorkspaceLimit')">Active Workspaces:</span>
                <span class="col-2 numberColumn" ng-hide="isEditing =='WorkspaceLimit'">
                    {{siteStats.numActive}}
                </span>
                <span class="col-2 numberColumn" ng-hide="isEditing =='WorkspaceLimit'">
                    {{siteInfo.workspaceLimit}}
                </span>
                <span class="col-4" ng-show="isEditing =='WorkspaceLimit'">
                    <input type="text" ng-model="siteInfo.workspaceLimit">
                    <button ng-click="saveSiteInfo()" class="btn btn-secondary btn-sm btn-wide">Save</button>
                </span>
                <span ng-hide="isEditing =='CreatorLimit'" class="helpColumn"></span>
                <span ng-show="isEditing =='CreatorLimit'" class="helpColumn guideVocal">
                    For each purchased update user, you can have 1 active workspace.
                </span>
            </div>
            <div class="row" >
                <span class="col-2 labelColumn" ng-click="toggleEditor('FrozenLimit')"> Frozen Workspaces:</span>
                <span class="col-2 numberColumn" ng-hide="isEditing =='FrozenLimit'">
                    {{siteStats.numFrozen}}
                </span>
                <span class="col-2 numberColumn" ng-hide="isEditing =='FrozenLimit'">
                    {{siteInfo.frozenLimit}}
                </span>
                <span class="col-4" ng-show="isEditing =='FrozenLimit'" colspan="2">
                    <input type="text" ng-model="siteInfo.frozenLimit">
                    <button ng-click="saveSiteInfo()" class="btn btn-secondary btn-sm btn-wide">Save</button>
                </span>
                <span ng-hide="isEditing =='CreatorLimit'" class="helpColumn"></span>
                <span ng-show="isEditing =='CreatorLimit'" class="helpColumn guideVocal">
                    For each purchased update user, you can have 2 additional frozen (archived) workspaces.
                </span>
            </div>
            <div class="row" >
                <span class="col-2 labelColumn" ng-click="toggleEditor('DocumentLimit')">Documents:</span>
                <span class="col-2 numberColumn" ng-hide="isEditing =='DocumentLimit'">
                    {{ (siteStats.sizeDocuments/1000000)|number: '0'}} MB
                </span>
                <span class="col-2 numberColumn" ng-hide="isEditing =='DocumentLimit'">
                    {{siteInfo.fileSpaceLimit|number}} MB
                </span>
                <span class="col-2" ng-show="isEditing =='DocumentLimit'" colspan="2">
                    <input type="text" ng-model="siteInfo.fileSpaceLimit">
                    <button ng-click="saveSiteInfo()" class="btn btn-secondary btn-sm btn-wide">Save</button>
                </span>
                <span ng-hide="isEditing =='CreatorLimit'" class="helpColumn"></span>
                <span ng-show="isEditing =='CreatorLimit'" class="helpColumn guideVocal">
                    For each purchased update user, you can have 100 MB of documents.
                </span>
            </div>
            <div class="row" >
                <span class="col-2 labelColumn" style="cursor: text;">Charges / Month:</span>
                <span class="col-2 numberColumn">
                    $ {{currentCharge | number: '2'}}
                </span>
                <span class="col-2 numberColumn">
                    $ {{limitCharge | number: '2'}}
                </span>
                <span class="col-4 helpColumn"></span>
                    
            </div>
        </div>
        
        <div class="row col-10 justify-content-end my-3"><button ng-click="recalcStats()" class="col-2 btn btn-primary btn-wide">Recalculate Current Usage</button></div>
        <p>Weaver only charges for the resources that you actually use.  The charge on the limit you set is the most you you will be changed in a given month where that limit is set.  If you keep your resource usage under the limit you will keep your charges under that amount.  Create your own balance of resources as you need.</p>
        
        <p>As part of our effort to support small organizations, Circle Weaver will then donate an amount to your cause, subtracting up to $6 from the total to produce the amount due.  If this brings the amount to less than zero, then you owe nothing.   If you keep the resources low enough, you can use Weaver for free.   Forever.  </p>
        
        <p>Weaver will help you stay under the limits, by preventing addition of new resources over the limits that you set.  You can change the limits at any time.  If you raise the limit you can immediately add resources.  The limit does not automatically reduce your resource usage.  If you lower the limit, you must remove the excess resources yourself.  Again, Weaver will only charge you for the resources you actually use.</p>
        
        
        
        
        <div style="height:300px"></div>
        <hr/>
        
        <% if (ar.isSuperAdmin()) { %>
        <div class="h5">Super Admin Only</div>
        <table class="spaceyTable">
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
            <tr>
                <td class="labelColumn">Site Key:</td>
                <td>{{siteInfo.key}}</td>
            </tr>
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
        </table>
        <% } %>
    </div>
    <div style="height:400px"></div>
</div>
