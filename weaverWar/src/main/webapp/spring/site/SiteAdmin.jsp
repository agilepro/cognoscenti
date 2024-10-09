<%@page errorPage="/spring/jsp/error.jsp"
%><%@page import="com.purplehillsbooks.weaver.License"
%><%@page import="com.purplehillsbooks.weaver.WorkspaceStats"
%><%@page import="com.purplehillsbooks.weaver.util.NameCounter"
%><%@ include file="/include.jsp"
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
.spaceyTable tr td {
    padding:8px;
}

.helpColumn {
    max-width:400px;
}
.dataColumn {
    max-width:400px;
}
.numberColumn {
    width:120px;
    text-align: right;
}
p {
    max-width:600px;
}
.headerRow {
    background-color: lightskyblue;
}
.lastLine {
    border-top: 5px solid gray;
}
</style>


<div>

<%@include file="../jsp/ErrorPanel.jsp"%>

<% if (ar.isSuperAdmin()) { %>
    <div class="upRightOptions rightDivContent">
      <span class="dropdown">
        <button class="btn btn-default btn-raised dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
        Options: <span class="caret"></span></button>
        <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
          <li role="presentation"><a role="menuitem" 
              href="TemplateEdit.htm">Template Edit</a></li>
           <li role="presentation" style="background-color:yellow"><a role="menuitem"
              href="../../../v/su/SiteDetails.htm?siteKey=<%=siteId%>">Super Admin</a></li>
        </ul>
      </span>
    </div>
<% } %>

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
        </table>
        
        <div style="height:100px"></div>
        <h2>Payment Plan</h2>
       
        
        <table class="spaceyTable">
            <tr class="headerRow">
                <td></td>
                <td class="numberColumn">Your Limit</td>
                <td>Set</td>
                <td class="numberColumn">Current Usage</td>
                <td class="numberColumn">Gratis</td>
                <td class="numberColumn">Extra</td>
                <td class="numberColumn">Cost</td>
            </tr>
            <tr ng-dblclick="toggleEditor('CreatorLimit')">
                <td class="labelColumn" ng-click="toggleEditor('CreatorLimit')">Active Users:</td>
                <td class="numberColumn">{{siteInfo.editUserLimit|number}}</td>
                <td>
                    <button ng-click="changePeople(1)">+</button>
                    <button ng-click="changePeople(-1)">-</button>
                </td>
                <td class="numberColumn">{{actual.editUserCount}}</td>
                <td class="numberColumn">{{comp.editUserCount}}</td>
                <td class="numberColumn">{{overflow.editUserCount}}</td>
                <td class="numberColumn">$ {{costs.editUserCount|number: '0'}}</td>
            </tr>
            <tr>
                <td >Active Workspaces:</td>
                <td class="numberColumn">{{siteInfo.workspaceLimit|number}}</td>
                <td>
                    <button ng-click="changeWS(1)">+</button>
                    <button ng-click="changeWS(-1)">-</button>
                </td>
                <td class="numberColumn">{{actual.numActive}}</td>
                <td class="numberColumn">{{comp.numActive}}</td>
                <td class="numberColumn">{{overflow.numActive}}</td>
                <td class="numberColumn">$ {{costs.numActive|number: '0'}}</td>
            </tr>
            <tr>
                <td>Documents:</td>
                <td></td>
                <td></td>
                <td class="numberColumn">
                    {{ actual.documentLimit|number: '0'}} MB
                </td>
                <td class="numberColumn">{{included.documentLimit|number}} MB</td>
                <td class="numberColumn" ng-show="overflow.documentLimit>0">
                    {{overflow.documentLimit|number: '0'}} MB
                </td>
                <td class="numberColumn" ng-show="costs.documentLimit>0">$ {{costs.documentLimit|number: '0'}}</td>
            </tr>
            <tr>
                <td>Observers:</td>
                <td></td>
                <td></td>
                <td class="numberColumn">{{actual.observerCount}}</td>
                <td class="numberColumn">{{included.observerCount}}</td>
                <td class="numberColumn">{{overflow.observerCount}}</td>
                <td class="numberColumn" ng-show="costs.observerCount>0">$ {{costs.observerCount|number: '0'}}</td>
            </tr>
            <tr>
                <td>Frozen Workspaces:</td>
                <td></td>
                <td></td>
                <td class="numberColumn">{{actual.numFrozen}}</td>
                <td class="numberColumn">{{included.numFrozen}}</td>
                <td class="numberColumn">{{overflow.numFrozen}}</td>
                <td class="numberColumn" ng-show="costs.numFrozen>0">$ {{costs.numFrozen|number: '0'}}</td>
            </tr>
            <tr>
                <td class="lastLine">Total per Month:</td>
                <td></td>
                <td></td>
                <td class="numberColumn"></td>
                <td class="numberColumn"></td>
                <td class="numberColumn"></td>
                <td class="numberColumn lastLine">$ {{costs.total|number: '0'}}</td>
            </tr>
        </table>
        

<div style="margin:100px"></div>

<div class="guideVocal">
<p>Statistics are calculated on a regular bases approximately every day.  If you have made a change, by removing or adding things, you can recalculate the resourceses that your site is using.</p>
<button class="btn btn-primary btn-raised" ng-click="recalcStats()">Recalculate</button>
</div>

<div class="guideVocal">
<p>In normal use of the site, deleting a resource only marks it as deleted, and the resource can be recovered for a period of time.
In order to actually cause the files to be deleted use the Garbage Collect function.  This will actually free up space on the server, and reduce the amount of resources you are using.</p>
<button class="btn btn-primary btn-raised" ng-click="garbageCollect()">Garbage Collect</button>
</div>
    
            
        
        
        
        <div style="height:300px"></div>
        <hr/>
        
        <% if (ar.isSuperAdmin()) { %>
        <h3>Super Admin Only</h3>
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
