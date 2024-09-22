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


$scope.changePeople = function(amt) {
    $scope.siteInfo.editUserLimit = $scope.siteInfo.editUserLimit + amt;
    if ($scope.siteInfo.editUserLimit < 1) {
        $scope.siteInfo.editUserLimit = 1
    }
    $scope.saveSiteInfo();
}
$scope.changeWS = function(amt) {
    $scope.siteInfo.workspaceLimit = $scope.siteInfo.workspaceLimit + amt;
    if ($scope.siteInfo.workspaceLimit < 1) {
        $scope.siteInfo.workspaceLimit = 1
    }
    $scope.saveSiteInfo();
}

function positive(a,b) {
    if (a>0) {
        return a;
    }
    else {
        return null;
    }
}

$scope.calc = function() {
    $scope.comp = {
        editUserCount: 1,
        numActive: 1,
    };
    $scope.actual = {
        editUserCount: $scope.siteStats.editUserCount,
        numActive: $scope.siteStats.numActive,
        observerCount: $scope.siteStats.numActive,
        documentLimit: $scope.siteStats.sizeDocuments/1000000,
        numFrozen: $scope.siteStats.numFrozen
    };
    
    //while ($scope.actual.documentLimit > 500 * $scope.actual.editUserCount) {
    //    $scope.actual.editUserCount++;
    //}
    while ($scope.siteStats.numActive > 20 * $scope.actual.editUserCount) {
        $scope.actual.editUserCount++;
    }
    while ($scope.siteStats.numFrozen > 4 * $scope.actual.numActive) {
        $scope.actual.numActive++;
    }
    
    $scope.included = {
        editUserCount: $scope.comp.editUserCount,
        numActive: $scope.comp.numActive,
        observerCount: 20 * $scope.actual.editUserCount,
        documentLimit: 500 * $scope.actual.editUserCount,
        numFrozen: 4 * $scope.actual.numActive
    };
    $scope.overflow = {
        editUserCount: positive(
                $scope.actual.editUserCount - $scope.included.editUserCount),
        numActive: positive(
                $scope.actual.numActive - $scope.included.numActive),
        observerCount: positive(
                $scope.actual.observerCount - $scope.included.observerCount),
        documentLimit: positive(
                $scope.actual.documentLimit - $scope.included.documentLimit),
        numFrozen: positive(
                $scope.actual.numFrozen - $scope.included.numFrozen)
    };
    $scope.costs = {
        editUserCount: $scope.overflow.editUserCount,
        numActive: 2 * $scope.overflow.numActive,
        observerCount: $scope.overflow.observerCount,
        documentLimit: $scope.overflow.documentLimit/1000,
        numFrozen: $scope.overflow.numFrozen
    };
    
    $scope.costs.total = $scope.costs.editUserCount + $scope.costs.numActive + $scope.costs.observerCount + $scope.costs.documentLimit + $scope.costs.numFrozen;
}
$scope.calc();


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
    $scope.siteInfo.viewUserLimit = $scope.siteInfo.editUserLimit * 4;
    $scope.siteInfo.fileSpaceLimit = $scope.siteInfo.editUserLimit * 100;
    $scope.siteInfo.frozenLimit =  $scope.siteInfo.editUserLimit * 2;
        
    $scope.calc();
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

$scope.garbageCollect = function() {
    if (!confirm("Do you really want to delete the workspaces marked for deletion?")) {
        return;
    }
    var postURL = "GarbageCollect.json";
    $http.get(postURL)
    .success( function(data) {
        console.log("Garbage Results", data);
        alert("Success.  REFRESHING the page");
        window.location.reload();
    })
    .error( function(data, status, headers, config) {
        $scope.reportError(data);
    });
}


});
</script>


<style>
.numberColumn {
    width:120px;
    text-align: right;
}
</style>


<div ng-cloak>

<%@include file="../jsp/ErrorPanel.jsp"%>

<div class="container-fluid">
    <div class="row">
      <div class="col-md-auto fixed-width border-end border-1 border-secondary">
          <span class="btn btn-secondary btn-comment btn-raised m-3 pb-2 pt-0" type="button"><a class="nav-link" role="menuitem" 
              href="LabelList.htm">Site Labels</a></span>
          <span class="btn btn-secondary btn-comment btn-raised m-3 pb-2 pt-0" type="button"><a class="nav-link" role="menuitem" 
              href="../$/SiteCreateWorkspace.htm?parent={{workspaceConfig.key}}">New Workspace</a></span>
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
                               <button ng-click="addName(newName)" class="btn btn-sm btn-primary  btn-raised">Change Name</button>
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
                               <button ng-click="saveSiteInfo()" class="btn btn-sm btn-primary  btn-raised">Save</button>
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
                               <button ng-click="saveSiteInfo()" class="btn btn-sm btn-primary  btn-raised">Save</button>
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
                           <span class="col-6 dataColumn mb-2" ng-show="isEditing =='LabelColors'">
                               <textarea  class="form-control mb-2"  rows="2" ng-model="colorList"
                               title="A comma separated list of standard color names."></textarea>
                               <button ng-click="saveSiteInfo()" class="btn btn-sm btn-primary  btn-raised ">Save</button>
                           </span>
                           <span ng-hide="isEditing =='LabelColors'" class="col-2 helpColumn"></span>
                           <span ng-show="isEditing =='LabelColors'" class="col-2 helpColumn guideVocal">
                               Use web standard color names to create the set of colors that you can set on labels.
                           </span>
                       </div>


        </div>
        
        <div style="height:100px"></div>
        <span class="h5">Payment Plan</span>
        
        <div class="spaceyTable">
            <div class="row">
                <span class="col-2 "></span>
                <span class="col-1 numberColumn h6">Your Limit</span>
                <span class="col-1 h6" >Set</span>
                <span class="col-1 numberColumn h6">Current Usage</span>
                <span class="col-1 numberColumn h6">Gratis</span>
                <span class="col-1 numberColumn h6">Charged</span>
                <span class="col-1 numberColumn h6">Cost</span>
            </div>
            <div class="row" ng-click="toggleEditor('CreatorLimit')">
                <span class="col-2 h6" ng-click="toggleEditor('CreatorLimit')">Active Users:</span>
                <span class="col-1 numberColumn">
                    {{siteInfo.editUserLimit|number}}
                </span>
                <span class="col-1 numberColumn">
                    <button class="specCaretBtn" ng-click="changePeople(1)">+</button>
                    <button class="specCaretBtn" ng-click="changePeople(-1)">-</button>
                </span>
                <span class="col-1 numberColumn">
                    {{actual.editUserCount}}
                </span>
                <span class="col-1 numberColumn">
                    {{comp.editUserCount}}
                </span>
                <span class="col-1 numberColumn">
                    {{overflow.editUserCount}}
                </span>
                <span class="col-1 numberColumn">
                    $ {{costs.editUserCount|number: '0'}}
                </span>
            </div>

            <div class="row">
                <span class="col-2 h6">Active Workspaces:</span>
                <span class="col-1 numberColumn">
                    {{siteInfo.workspaceLimit|number}}
                </span>
                <span class="col-1 numberColumn">
                    <button class="specCaretBtn" ng-click="changeWS(1)">+</button>
                    <button class="specCaretBtn" ng-click="changeWS(-1)">-</button>
                </span>
                <span class="col-1 numberColumn">
                    {{actual.numActive}}
                </span>
                <span class="col-1 numberColumn">
                    1
                </span>
                <span class="col-1 numberColumn">
                    {{overflow.numActive}}
                </span>
                <span class="col-1 numberColumn">
                    $ {{costs.numActive|number: '0'}}
                </span>
            </div>
            <div class="row">
                <span class="col-2 h6">Document MB:</span>
                <span class="col-1 numberColumn">
                    
                </span>
                <span class="col-1 numberColumn">
                    
                </span>
                <span class="col-1 numberColumn" >
                    {{ actual.documentLimit|number: '0'}}
                </span>
                <span class="col-1 numberColumn">
                    {{included.documentLimit|number}}
                </span>
                <span class="col-1 numberColumn" ng-show="overflow.documentLimit>0">
                    {{overflow.documentLimit|number: '0'}}
                </span>
                <span class="col-1 numberColumn" ng-show="costs.documentLimit>0">
                    $ {{costs.documentLimit|number: '0'}}
                </span>
            </div>

            <div class="row">
                <span class="col-2 h6">Frozen Workspaces:</span>
                <span class="col-1 numberColumn">
                    
                </span>
                <span class="col-1 numberColumn">
                    
                </span>
                <span class="col-1 numberColumn" >
                    {{actual.numFrozen}}
                </span>
                <span class="col-1 numberColumn">
                    {{included.numFrozen}}
                </span>
                <span class="col-1 numberColumn">
                    {{overflow.numFrozen}}
                </span>
                <span class="col-1 numberColumn" ng-show="costs.numFrozen>0">
                    $ {{costs.numFrozen|number: '0'}}
                </span>
            </div>
<hr>
            <div class="row">
                <span class="col-2 h6">Total per Month:</span>
                <span class="col-1 numberColumn">
                    
                </span>
                <span class="col-1 numberColumn">
                    
                </span>
                <span class="col-1 numberColumn" >
                    
                </span>
                <span class="col-1 numberColumn">
                    
                </span>
                <span class="col-1 numberColumn">
                    
                </span>
                <span class="col-1 numberColumn h6" >
                    $ {{costs.total|number: '0'}}
                </span>
            </div>

<hr>
           
        
        <div class="row col-10 justify-content-end my-3 well">
        <p>Statistics are calculated on a regular bases approximately every day. If you have made a change, by removing or adding things, you can recalculate the resourceses that your site is using.</p><button ng-click="recalcStats()" class="col-2 btn btn-primary btn-wide">Recalculate Current Usage</button></div>
        
        <div class="row col-10 justify-content-end my-3 well">
            <p>In normal use of the site, deleting a resource only marks it as deleted, and the resource can be recovered for a period of time. In order to actually cause the files to be deleted use the Garbage Collect function. This will actually free up space on the server, and reduce the amount of resources you are using.</p><button  class="col-2 btn btn-primary btn-wide" ng-click="garbageCollect()">Garbage Collect</button></div>
        
        
        
        
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
