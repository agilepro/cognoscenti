<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="com.purplehillsbooks.weaver.NGRole"
%><%@page import="com.purplehillsbooks.weaver.CustomRole"
%><%


    String pageId = ar.reqParam("pageId");
    String siteId = ar.reqParam("siteId");
    NGWorkspace ngp = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngp);
    ar.assertMember("Documents are available only to members");
    NGBook site = ngp.getSite();
    boolean isMember = ar.isMember();
    String wsUrl = ar.baseURL + ar.getResourceURL(ngp, "");

    JSONArray attachments = new JSONArray();

    UserProfile up = ar.getUserProfile();

    List<AttachmentRecord> aList = ngp.getAccessibleAttachments(up);

    for (AttachmentRecord aDoc : aList) {
        attachments.put( aDoc.getJSON4Doc(ar, ngp) );
    }

    JSONArray allLabels = ngp.getJSONLabels();
    
    String templateCacheDefeater = "";
    if ("true".equals(ar.getSystemProperty("forceTemplateRefresh"))) {
        templateCacheDefeater = "?t="+System.currentTimeMillis();
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
        "universalid": "CSWSLRBRG@sec-inline-xbrl@8699"
      },
*/

%>

<script src="../../../jscript/AllPeople.js"></script>
<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal, AllPeople) {
    window.setMainPageTitle("Document List");
    $scope.siteInfo = <%site.getConfigJSON().write(out,2,4);%>;
    $scope.atts = [];
    $scope.allLabels = <%allLabels.write(out,2,4);%>;
    $scope.filter = "";
    $scope.filterMap = {};
    $scope.dataArrived = false;
    $scope.showDeleted = false;
    $scope.showDescription = false;
    $scope.wsUrl = "<%= wsUrl %>";

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };
    

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
        $scope.atts.forEach( function(rec) {
            if (rec.deleted && !$scope.showDeleted) {
                return;
            }
            var hasLabel = true;
            $scope.allLabelFilters().map( function(val) {
                if (!rec.labelMap[val.name]) {
                    hasLabel=false;
                }
            });
            if (!hasLabel) {
                return;
            }

            if (containsOne(rec.name, filterlist)) {
                res.push(rec);
            }
            else if (containsOne(rec.description, filterlist)) {
                res.push(rec);
            }
        });
        return res;
    }
    $scope.toggleDelete = function(rec) {
        rec.deleted = !rec.deleted;
        var postURL = "docsUpdate.json?did="+rec.id;
        var postdata = angular.toJson(rec);
        $scope.showError=false;
        $http.post(postURL, postdata)
        .success( function(data) {
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
    $scope.setDocumentData = function(data) {
        console.log("GOT THIS", data);
        $scope.timerCorrection = data.serverTime - new Date().getTime();
        $scope.atts = data.docs;
        $scope.sortDocs();
        $scope.atts.forEach( function(rec) {
            if (rec.description) {
                rec.html = convertMarkdownToHtml(rec.description);
            }
        });
        $scope.dataArrived = true;
    }
    $scope.getDocumentList = function() {
        $scope.isUpdating = true;
        var postURL = "docsList.json";
        $http.get(postURL)
        .success( function(data) {
            $scope.setDocumentData(data);
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
        
    }
    $scope.getDocumentList();
    
    $scope.downloadDocument = function(doc) {
        if (doc.attType=='URL') {
             window.open(doc.url,"_blank");
        }
        else {
            window.open("a/"+doc.name,"_blank");
        }
    }
    
    $scope.openDocDialog = function (doc) {
        
        var docsDialogInstance = $modal.open({
            animation: true,
            templateUrl: "<%= ar.retPath%>templates/DocumentDetail2.html<%=templateCacheDefeater%>",
            controller: 'DocumentDetailsCtrl',
            size: 'lg',
            backdrop: "static",
            resolve: {
                docId: function () {
                    return doc.id;
                },
                allLabels: function() {
                    return $scope.allLabels;
                },
                wsUrl: function() {
                    return $scope.wsUrl;
                }
            }
        });

        docsDialogInstance.result
        .then(function () {
            $scope.getDocumentList();
        }, function () {
            $scope.getDocumentList();
            //cancel action - nothing really to do
        });
    };

});

</script>

<div>

<%@include file="ErrorPanel.jsp"%>

    <div class="upRightOptions rightDivContent">
      <span class="dropdown">
        <button class="btn btn-default btn-raised dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
        Options: <span class="caret"></span></button>
        <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
          <li role="presentation"><a role="menuitem" href="docsFolder.htm">
              Show Folders</a>
          </li>
          <li role="presentation"><a role="menuitem" tabindex="-1" href="DocsAdd.htm">
              <img src="<%= ar.retPath%>assets/iconUpload.png" width="13" height="15" alt="" /> Add Document</a>
          </li>
          <li role="presentation"><a role="menuitem" tabindex="-1" href="SendNote.htm">
              <img src="<%= ar.retPath%>assets/images/iconEmailNote.gif" width="13" height="15" alt="" /> Send Email</a>
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
        </span> &nbsp;
        <span style="vertical-align:middle"><input type="checkbox" ng-model="showDeleted"> Deleted </span> &nbsp;
        <span style="vertical-align:middle"><input type="checkbox" ng-model="showDescription"> Description </span>
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
                      <a role="menuitem" tabindex="-1" href="DocsAdd.htm"> <img src="<%= ar.retPath%>assets/iconUpload.png" width="13" height="15" alt="" /> Add Document</a></li>
                </ul>
              </div>
            </td>
            <td width="40px"></td>
            <td width="420px">Name ~ Description</td>
            <td width="40px"></td>
            <td width="80px">Date</td>
            <td width="80px">Size</td>
        </tr>
        <tr ng-repeat="rec in getRows()" ng-dblclick="openDocDialog(rec)">
            <td>
              <div class="dropdown">
                <button class="dropdown-toggle specCaretBtn" type="button"  d="menu" 
                    data-toggle="dropdown"> <span class="caret"></span> </button>
                <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
                  <li role="presentation">
                      <a role="menuitem" tabindex="-1" href="DocDetail.htm?aid={{rec.id}}">Access Document</a></li>
                  <li role="presentation" ng-show="rec.attType=='FILE'">
                      <a role="menuitem" tabindex="-1" href="DocsRevise.htm?aid={{rec.id}}">Versions</a></li>
                  <li role="presentation">
                      <a role="menuitem" tabindex="-1" ng-click="openDocDialog(rec)">Edit Document Settings</a></li>
                  <li role="presentation" class="divider"></li>
                  <li role="presentation">
                      <a role="menuitem" tabindex="-1" ng-click="toggleDelete(rec)">
                         <span ng-show="rec.deleted">Un-</span>Delete <i class="fa fa-trash"></i> Document</a></li>
                  <li role="presentation">
                      <a role="menuitem" tabindex="-1" href="SendNote.htm?att={{rec.id}}">Send By <i class="fa fa-envelope"></i> Email</a></li>
                </ul>
              </div>
            </td>
            <td style="text-align: center">
              <span ng-click="downloadDocument(rec)" ng-show="rec.attType=='URL'">
                <span class="fa fa-external-link"></span></span>
              <span ng-click="downloadDocument(rec)" ng-show="rec.attType=='FILE'">
                <span class="fa fa-download"></span></span>
            </td>
            <td>
              <div>
                <b><a href="DocDetail.htm?aid={{rec.id}}" title="{{rec.name}}">{{rec.name}}</a></b>
                <span ng-show="rec.deleted" style="color:red"> (deleted) </span>
                <span ng-repeat="label in getAllLabels(rec)">
                    <button class="labelButton" 
                        ng-click="toggleLabel(label)"
                        style="background-color:{{label.color}};">{{label.name}}
                    </button>
                </span>
              </div>
              <div ng-show="showDescription && rec.description" ng-bind-html="rec.html">
              </div>
            </td>
            <td style="text-align: center" ng-click="openDocDialog(rec)">
                <span ng-show="rec.attType=='FILE'"><img src="<%=ar.retPath%>assets/images/iconFile.png"></span>
                <span ng-show="rec.attType=='URL'"><img src="<%=ar.retPath%>assets/images/iconUrl.png"></span>
            </td>
            <td ng-click="openDocDialog(rec)">{{rec.modifiedtime|cdate}}</td>
            <td ng-click="openDocDialog(rec)"><span ng-show="rec.size>0">{{rec.size|number}}</span></td>
        </tr>
    </table>
    
    
    <div class="guideVocal" ng-show="dataArrived && atts.length==0" style="margin-top:80px">
    You have no attached documents in this workspace yet.
    You can add them using a option from the pull-down in the upper right of this page.
    They can be uploaded from your workstation, or linked from the web.
    </div>
    
    
</div>
<!--have to make room for menu on bottom line-->
<div style="height:300px"></div>

<script src="<%=ar.retPath%>templates/DocumentDetail2.js"></script>


