<%@page errorPage="/spring/jsp/error.jsp"
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

    $scope.purchaseCount = {user10: 0, user5: 0, ws3: 0, ws1: 0};
    let remainingUsers = $scope.siteStats.editUserCount - 10;
    while (remainingUsers > 5) {
        remainingUsers = remainingUsers - 10;
        $scope.purchaseCount.user10 = $scope.purchaseCount.user10 + 1
    }
    while (remainingUsers > 0) {
        remainingUsers = remainingUsers - 5;
        $scope.purchaseCount.user5 = $scope.purchaseCount.user5 + 1
    }
    
    
    let remainingWS = $scope.siteStats.numActive - 3;
    while (remainingWS > 2) {
        remainingWS = remainingWS - 3;
        $scope.purchaseCount.ws3 = $scope.purchaseCount.ws3 + 1
    }
    while (remainingWS > 0) {
        remainingWS = remainingWS - 1;
        $scope.purchaseCount.ws1 = $scope.purchaseCount.ws1 + 1
    }
    $scope.calc = function() {
        $scope.purchaseCost = {};
        $scope.purchaseCost.user10 = $scope.purchaseCount.user10 * 8;
        $scope.purchaseCost.user5 = $scope.purchaseCount.user5 * 5;
        $scope.purchaseCost.ws3 = $scope.purchaseCount.ws3 * 6;
        $scope.purchaseCost.ws1 = $scope.purchaseCount.ws1 * 4;
        $scope.purchaseCost.total = $scope.purchaseCost.user10 + $scope.purchaseCost.user5 + $scope.purchaseCost.ws3 + $scope.purchaseCost.ws1;
        
        $scope.purchaseUsers = {};
        $scope.purchaseUsers.user10 = $scope.purchaseCount.user10 * 10;
        $scope.purchaseUsers.user5 = $scope.purchaseCount.user5 * 5;
        $scope.purchaseUsers.ws3 = 0;
        $scope.purchaseUsers.ws1 = 0;
        $scope.purchaseUsers.total = 10 + $scope.purchaseUsers.user10 + $scope.purchaseUsers.user5 + $scope.purchaseUsers.ws3 + $scope.purchaseUsers.ws1;
        
        $scope.purchaseWS = {};
        $scope.purchaseWS.user10 = 0;
        $scope.purchaseWS.user5 = 0;
        $scope.purchaseWS.ws3 = $scope.purchaseCount.ws3 * 3;
        $scope.purchaseWS.ws1 = $scope.purchaseCount.ws1;
        $scope.purchaseWS.total = 3 + $scope.purchaseWS.user10 + $scope.purchaseWS.user5 + $scope.purchaseWS.ws3 + $scope.purchaseWS.ws1;  
        
        $scope.extraDocCount = ($scope.siteStats.sizeDocuments/1000000)-(500 * $scope.purchaseUsers.total);
        if ($scope.extraDocCount < 0) {
            $scope.extraDocCount = 0;
        }
        
        if ($scope.siteStats.editUserCount - $scope.purchaseUsers.total >= 5) {
            $scope.purchaseCount.user10 = $scope.purchaseCount.user10 + 1;
            $scope.calc();
        }
        if ($scope.siteStats.editUserCount - $scope.purchaseUsers.total >= 1) {
            $scope.purchaseCount.user5 = $scope.purchaseCount.user5 + 1;
            $scope.calc();
        }
        if ($scope.siteStats.numActive - $scope.purchaseWS.total >= 3) {
            $scope.purchaseCount.ws3 = $scope.purchaseCount.ws3 + 1;
            $scope.calc();
        }
        if ($scope.siteStats.numActive - $scope.purchaseWS.total >= 1) {
            $scope.purchaseCount.ws1 = $scope.purchaseCount.ws1 + 1;
            $scope.calc();
        }
    }
    $scope.calc();
    $scope.incr = function(name) {
        $scope.purchaseCount[name] = $scope.purchaseCount[name] + 1;
        $scope.calc();
    }
    $scope.decr = function(name) {
        if ($scope.purchaseCost[name]>0) {
            $scope.purchaseCount[name] = $scope.purchaseCount[name] - 1;
        }
        else {
            $scope.purchaseCount[name] = 0;
        }
        $scope.calc();
    }

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
        if ($scope.siteInfo.editUserLimit < 10) {
            $scope.siteInfo.editUserLimit = 10;
        }
        if ($scope.siteInfo.workspaceLimit < 3) {
            $scope.siteInfo.workspaceLimit = 3;
        }
        $scope.siteInfo.viewUserLimit = $scope.siteInfo.editUserLimit * 4;
        $scope.siteInfo.fileSpaceLimit = $scope.siteInfo.editUserLimit * 100;
        $scope.siteInfo.frozenLimit =  $scope.siteInfo.editUserLimit * 2;
            
        $scope.limitCharge = $scope.siteInfo.frozenLimit * $scope.chargeFrozen
            + $scope.siteInfo.workspaceLimit * $scope.chargeActive
            + $scope.siteInfo.viewUserLimit * $scope.chargeReader
            + ($scope.siteInfo.editUserLimit-1) * $scope.chargeCreator
            + $scope.siteInfo.fileSpaceLimit * $scope.chargeDocument;
        let charge = 16;
        $scope.siteStats.includeDocs = 5000;
        if ($scope.siteStats.editUserCount > 10) {
            charge = charge + ($scope.siteStats.editUserCount-10);
            $scope.siteStats.includeDocs = $scope.siteStats.editUserCount*500;
        }
        if ($scope.siteStats.numActive > 3) {
            charge = charge + ($scope.siteStats.numActive-3)*2;
        }
        let docMB = $scope.siteStats.sizeDocuments/1000000;
        console.log("DOC GB", docMB);
        if (docMB > $scope.siteStats.includeDocs) {
            charge = charge + (docMB-$scope.siteStats.includeDocs)/1000;
        console.log("DOC charge", (docMB-$scope.siteStats.includeDocs)/1000);
        }
        $scope.currentCharge = charge;
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
            <td>Item</td>
            <td class="numberColumn">Count</td>
            <td></td>
            <td class="numberColumn">Users</td>
            <td class="numberColumn">Workspaces</td>
            <td class="numberColumn">Cost</td>
          </tr>
          <tr>
            <td>Basic 10 users 3 workspaces @ $16</td>
            <td class="numberColumn">1</td>
            <td></td>
            <td class="numberColumn">10</td>
            <td class="numberColumn">3</td>
            <td class="numberColumn">$ {{16|number}}</td>
          </tr>
          <tr>
            <td>User 10 pack @ $8</td>
            <td class="numberColumn">{{purchaseCount.user10}}</td>
            <td>
                <button ng-click="incr('user10')">+</button>
                <button ng-click="decr('user10')">-</button>
            </td>
            <td class="numberColumn">{{purchaseUsers.user10|number}}</td>
            <td class="numberColumn">{{purchaseWS.user10|number}}</td>
            <td class="numberColumn">$ {{purchaseCost.user10|number}}</td>
          </tr>
          <tr>
            <td>User 5 pack @ $5</td>
            <td class="numberColumn">{{purchaseCount.user5}}</td>
            <td>
                <button ng-click="incr('user5')">+</button>
                <button ng-click="decr('user5')">-</button>
            </td>
            <td class="numberColumn">{{purchaseUsers.user5|number}}</td>
            <td class="numberColumn">{{purchaseWS.user5|number}}</td>
            <td class="numberColumn">$ {{purchaseCost.user5|number}}</td>
          </tr>
          <tr>
            <td>Workspace 3 Pack @ $6</td>
            <td class="numberColumn">{{purchaseCount.ws3}}</td>
            <td>
                <button ng-click="incr('ws3')">+</button>
                <button ng-click="decr('ws3')">-</button>
            </td>
            <td class="numberColumn">{{purchaseUsers.ws3|number}}</td>
            <td class="numberColumn">{{purchaseWS.ws3|number}}</td>
            <td class="numberColumn">$ {{purchaseCost.ws3|number}}</td>
          </tr>
          <tr>
            <td>Workspace Individual @ $4</td>
            <td class="numberColumn">{{purchaseCount.ws1}}</td>
            <td>
                <button ng-click="incr('ws1')">+</button>
                <button ng-click="decr('ws1')">-</button>
            </td>
            <td class="numberColumn">{{purchaseUsers.ws1|number}}</td>
            <td class="numberColumn">{{purchaseWS.ws1|number}}</td>
            <td class="numberColumn">$ {{purchaseCost.ws1|number}}</td>
          </tr>
          <tr>
            <td>Totals</td>
            <td class="numberColumn">0</td>
            <td></td>
            <td class="numberColumn">{{purchaseUsers.total|number}}</td>
            <td class="numberColumn">{{purchaseWS.total|number}}</td>
            <td class="numberColumn">$ {{purchaseCost.total|number}}</td>
          </tr>
        </table>
        
        <br/>
        <br/>
        
        <table class="spaceyTable">
            <tr class="headerRow">
                <td></td>
                <td class="numberColumn">Current Usage</td>
                <td class="numberColumn">Included</td>
                <td class="numberColumn">Extra</td>
                <td class="numberColumn">Cost</td>
            </tr>
            <tr ng-dblclick="toggleEditor('CreatorLimit')">
                <td class="labelColumn" ng-click="toggleEditor('CreatorLimit')">Active Users:</td>
                <td class="numberColumn">{{siteStats.editUserCount}}</td>
                <td class="numberColumn">{{purchaseUsers.total|number}}</td>
                <td class="numberColumn"></td>
            </tr>
            <tr>
                <td >Active Workspaces:</td>
                <td class="numberColumn">{{siteStats.numActive}}</td>
                <td class="numberColumn">{{purchaseWS.total|number}}</td>
                <td class="numberColumn"></td>
            </tr>
            <tr>
                <td>Documents:</td>
                <td class="numberColumn" ng-hide="isEditing =='DocumentLimit'">
                    {{ siteStats.sizeDocuments/1000000|number: '0'}} MB
                </td>
                <td class="numberColumn">{{500 * purchaseUsers.total|number}} MB</td>
                <td class="numberColumn" ng-show="extraDocCount>0">
                    {{extraDocCount|number: '0'}} MB
                </td>
                <td class="numberColumn" ng-show="extraDocCount>0">$ {{extraDocCount/1000|number: '0'}}</td>
            </tr>
            <tr>
                <td>Observers:</td>
                <td class="numberColumn">
                    {{siteStats.readUserCount}}
                </td>
                <td class="numberColumn">All</td>
                <td class="numberColumn"></td>
                <td class="numberColumn"></td>
            </tr>
            <tr>
                <td>Frozen Workspaces:</td>
                <td class="numberColumn">
                    {{siteStats.numFrozen}}
                </td>
                <td class="numberColumn">All</td>
                <td class="numberColumn""></td>
                <td class="numberColumn"></td>
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
