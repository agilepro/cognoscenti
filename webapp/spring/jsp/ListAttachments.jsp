<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="org.socialbiz.cog.NGRole"
%><%@page import="org.socialbiz.cog.CustomRole"
%><%


    String pageId = ar.reqParam("pageId");
    String siteId = ar.reqParam("siteId");
    NGWorkspace ngp = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngp);
    NGBook site = ngp.getSite();
    boolean isMember = ar.isMember();

    JSONArray attachments = new JSONArray();

    UserProfile up = ar.getUserProfile();

    List<AttachmentRecord> aList = ngp.getAccessibleAttachments(up);

    for (AttachmentRecord aDoc : aList) {
        attachments.put( aDoc.getJSON4Doc(ar, ngp) );
    }

    JSONArray allLabels = ngp.getJSONLabels();
    
    String showLimitedMessage = "";
    if (!ar.isLoggedIn()) {
        showLimitedMessage = "You are not logged in.  You might see more documents if you log in and if you are a member of the workspace.";
    }
    else if (!isMember) {
        showLimitedMessage = "You are not a member of this workspace.  You might see more documents if you were a member of the workspace.";
    }


/* DOC RECORD PROTOTYPE
      {
        "attType": "FILE",
        "deleted": false,
        "description": "Highlight Story V3",
        "id": "9312",
        "modifiedtime": 1391791699968,
        "modifieduser": "rob.blake@trintech.com",
        "name": "FujitsuTrintech_SECInlineXBRLProject_CBE_HighlightUserStory_V3.docx",
        "size": 246419,
        "universalid": "CSWSLRBRG@sec-inline-xbrl@8699",
        "upstream": true
      },
*/

%>


<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http) {
    window.setMainPageTitle("Documents");
    $scope.siteInfo = <%site.getConfigJSON().write(out,2,4);%>;
    $scope.atts = <%attachments.write(out,2,4);%>;
    $scope.allLabels = <%allLabels.write(out,2,4);%>;
    $scope.filter = "";
    $scope.filterMap = {};

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };
    
    $scope.showLimitedMessage = "<% ar.writeJS(showLimitedMessage); %>";

    $scope.allLabels.sort( function(a,b) {
        if (a.name < b.name) {
            return -1;
        }
        if (a.name > b.name) {
            return 1;
        }
        return 0;
    });

    $scope.sortDocs = function() {
        $scope.atts.sort( function(a,b) {
            return (b.modifiedtime - a.modifiedtime);
        });
    }
    $scope.sortDocs();

    $scope.getRows = function() {
        var filterlist = parseLCList($scope.filter);
        var res = [];
        var last = $scope.atts.length;
        for (var i=0; i<last; i++) {
            var rec = $scope.atts[i];
            var hasLabel = true;
            $scope.allLabelFilters().map( function(val) {
                if (!rec.labelMap[val.name]) {
                    hasLabel=false;
                }
            });
            if (!hasLabel) {
                continue;
            }

            if (containsOne(rec.name, filterlist)) {
                res.push(rec);
            }
            else if (containsOne(rec.description, filterlist)) {
                res.push(rec);
            }
        }
        return res;
    }
    $scope.removeEntry = function(searchId) {
        var res = [];
        $scope.atts.map( function(rec) {
            if (searchId!=rec.id) {
                res.push(rec);
            }
        });
        $scope.atts = res;
    }
    $scope.deleteDoc = function(rec) {
        rec.deleted = true;
        var postURL = "docsUpdate.json?did="+rec.id;
        var postdata = angular.toJson(rec);
        $scope.showError=false;
        $http.post(postURL, postdata)
        .success( function(data) {
            $scope.removeEntry(rec.id);
            $scope.sortDocs();
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };

    $scope.getAllLabels = function(doc) {
        var res = [];
        $scope.allLabels.map( function(val) {
            if (doc.labelMap[val.name]) {
                res.push(val);
            }
        });
        return res;
    }

    $scope.hasLabel = function(searchName) {
        return $scope.filterMap[searchName];
    }
    $scope.toggleLabel = function(label) {
        $scope.filterMap[label.name] = !$scope.filterMap[label.name];
    }
    $scope.toggleLabel = function(label) {
        $scope.filterMap[label.name] = !$scope.filterMap[label.name];
    }
    $scope.allLabelFilters = function() {
        var res = [];
        $scope.allLabels.map( function(val) {
            if ($scope.filterMap[val.name]) {
                res.push(val);
            }
        });
        return res;
    }

});

</script>

<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

    <div class="upRightOptions rightDivContent">
      <span class="dropdown">
        <button class="btn btn-default btn-raised dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
        Options: <span class="caret"></span></button>
        <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
          <li role="presentation"><a role="menuitem" href="docsFolder.htm">
              Show Folders</a>
          </li>
          <li role="presentation"><a role="menuitem" tabindex="-1" href="docsAdd.htm">
              <img src="<%= ar.retPath%>assets/iconUpload.png" width="13" height="15" alt="" /> Add Document</a>
          </li>
          <li role="presentation"><a role="menuitem" tabindex="-1" href="SendNote.htm">
              <img src="<%= ar.retPath%>assets/images/iconEmailNote.gif" width="13" height="15" alt="" /> Send Email</a>
          </li>
          <li role="presentation"><a role="menuitem" href="SyncAttachment.htm">
              <img src="<%= ar.retPath%>assets/iconSync.gif" width="13" height="15" alt="" /> Synchronize</a>
          </li>
          <li role="presentation"><a role="menuitem" href="docsDeleted.htm">
              List Deleted Docs</a>
          </li>
          <li role="presentation"><a role="menuitem" href="sharePorts.htm">
              Share Ports</a>
          </li>
          
        </ul>
      </span>
    </div>
    
<style>
.checkButton {
    vertical-align:middle;
    border: none;
    border-radius:2px;
    box-shadow: 2px 2px 5px #CCCCCC;
    padding:5px 10px;
    cursor:pointer;
}
.gridTable2 tr td {
    border-bottom: 1px solid lightgray;
    padding-bottom: 3px;
    padding-top: 3px;
}
</style>


    <div class="well">Filter <input ng-model="filter"> &nbsp;
        <span class="dropdown" ng-repeat="role in allLabelFilters()">
            <button class="labelButton" type="button" id="menu2"
               data-toggle="dropdown" style="background-color:{{role.color}};"
               ng-show="hasLabel(role.name)">{{role.name}} <i class="fa fa-close"></i></button>
            <ul class="dropdown-menu" role="menu" aria-labelledby="menu2">
               <li role="presentation"><a role="menuitem" title="{{add}}"
                  ng-click="toggleLabel(role)">Remove Filter:<br/>{{role.name}}</a></li>
            </ul>
        </span>
        <span class="dropdown">
           <button class="btn btn-sm btn-primary btn-raised dropdown-toggle" 
                   type="button" id="menu1" data-toggle="dropdown"
                   style="padding: 2px 5px;font-size: 11px;" 
                   title="Add Filter by Label">
                <i class="fa fa-filter"></i></button>
           <ul class="dropdown-menu" role="menu" aria-labelledby="menu1" 
           style="width:320px;left:-130px">
             <li role="presentation" ng-repeat="rolex in allLabels" style="float:left">
                 <button role="menuitem" tabindex="-1" ng-click="toggleLabel(rolex)" class="labelButton" 
                 ng-hide="hasLabel(rolex.name)" style="background-color:{{rolex.color}}">
                     {{rolex.name}}</button>
             </li>
           </ul>
        </span>
    </div>

    <div style="height:20px;"></div>

    <table class="gridTable2" width="100%">
        <tr class="gridTableHeader">
            <td width="50px">
              <div class="dropdown">
                <button class="dropdown-toggle specCaretBtn" type="button"  d="menu" 
                    data-toggle="dropdown"> <span class="caret"></span> </button>
                <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
                  <li role="presentation">
                      <a role="menuitem" tabindex="-1" href="docsAdd.htm"> <img src="<%= ar.retPath%>assets/iconUpload.png" width="13" height="15" alt="" /> Add Document</a></li>
                </ul>
              </div>
            </td>
            <td width="80px"></td>
            <td width="420px">Name ~ Description</td>
            <td width="80px">Date</td>
        </tr>
        <tr ng-repeat="rec in getRows()">
            <td>
              <div class="dropdown">
                <button class="dropdown-toggle specCaretBtn" type="button"  d="menu" 
                    data-toggle="dropdown"> <span class="caret"></span> </button>
                <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
                  <li role="presentation">
                      <a role="menuitem" tabindex="-1" href="docinfo{{rec.id}}.htm">Access Document</a></li>
                  <li role="presentation" ng-show="rec.attType=='FILE'">
                      <a role="menuitem" tabindex="-1" href="docsRevise.htm?aid={{rec.id}}">Upload Revised Document</a></li>
                  <li role="presentation">
                      <a role="menuitem" tabindex="-1" href="editDetails{{rec.id}}.htm">Edit Document Details</a></li>
                  <li role="presentation">
                      <a role="menuitem" tabindex="-1" href="fileVersions.htm?aid={{rec.id}}">List Versions</a></li>
                  <li role="presentation" class="divider"></li>
                  <li role="presentation">
                      <a role="menuitem" tabindex="-1" ng-click="deleteDoc(rec)">Delete <i class="fa fa-trash"></i> Document</a></li>
                  <li role="presentation">
                      <a role="menuitem" tabindex="-1" href="SendNote.htm?att={{rec.id}}">Send By <i class="fa fa-envelope"></i> Email</a></li>
                </ul>
              </div>
            </td>
            <td>
                <a href="editDetails{{rec.id}}.htm">
                    <span ng-show="rec.deleted"><i class="fa fa-trash"></i></span>
                    <span ng-show="rec.upstream"><img src="<%=ar.retPath%>assets/images/iconUpstream.png"></span>
                    <span ng-show="rec.attType=='FILE'"><img src="<%=ar.retPath%>assets/images/iconFile.png"></span>
                    <span ng-show="rec.attType=='URL'"><img src="<%=ar.retPath%>assets/images/iconUrl.png"></span>
                </a>
            </td>
            <td>
                <b><a href="docinfo{{rec.id}}.htm" title="{{rec.name}}">{{rec.name}}</a></b>
                ~ {{rec.description}}
                <span ng-repeat="label in getAllLabels(rec)">
                    <button class="labelButton" 
                        ng-click="toggleLabel(label)"
                        style="background-color:{{label.color}};">{{label.name}}
                    </button>
                </span>
            </td>
            <td>{{rec.modifiedtime|date}}</td>
        </tr>
        <tr ng-show="showLimitedMessage">
            <td colspan="5">
                <div class="guideVocal">{{showLimitedMessage}}</div>
            </td>
        </tr>
    </table>
    
    
    <div class="guideVocal" ng-show="atts.length==0" style="margin-top:80px">
    You have no attached documents in this workspace yet.
    You can add them using a option from the pull-down in the upper right of this page.
    They can be uploaded from your workstation, or linked from the web.
    </div>
    
    
</div>




