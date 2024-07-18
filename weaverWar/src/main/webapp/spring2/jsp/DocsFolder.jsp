<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="com.purplehillsbooks.weaver.NGRole"
%><%


    String pageId = ar.reqParam("pageId");
    String siteId = ar.reqParam("siteId");
    NGWorkspace ngp = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngp);
    NGBook ngb = ngp.getSite();

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
    $scope.atts = [
      {
        "attType": "FILE",
        "comments": [],
        "deleted": false,
        "description": "Original Contract from the SEC to example",
        "id": "1002",
        "labelMap": {},
        "modifiedtime": 1391185776500,
        "modifieduser": "cparker@example.com",
        "name": "Contract 13-C-0113-example.pdf",
        "size": 409333,
        "universalid": "CSWSLRBRG@sec-inline-xbrl@0056"
      },
    $scope.allLabels = [
      {
        "color": "yellow",
        "name": "User Story"
      },
      {
        "color": "magenta",
        "description": "Members of a project can see and edit any of roles.",
        "expandedPlayers": [
          {
            "name": "Keith (local) Test",
            "uid": "kswenson@example.com"
          },
          {
            "name": "Jack Landry",
            "uid": "jack@example.com"
          }
        ],
        "name": "Members",
        "players": [
          {
            "name": "Keith (local) Test",
            "uid": "kswenson@example.com"
          },
          {
            "name": "Jack Landry",
            "uid": "jack@landry.com"
          }
        ],
        "requirements": ""
      },

*/

%>

<style>
   .folderLine {
       margin:5px;
   }
</style>

<script src="../../../jscript/AllPeople.js"></script>
<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal, AllPeople) {
    setUpLearningMethods($scope, $modal, $http);
    window.setMainPageTitle("Document Folders");
    $scope.atts = <%attachments.write(out,2,4);%>;
    $scope.allLabels = <%allLabels.write(out,2,4);%>;
    $scope.filter = "";
    $scope.showVizPub = true;
    $scope.showVizMem = true;
    $scope.filterMap = {};
    $scope.folderPath = [];

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
        var lcfilter = $scope.filter.toLowerCase();
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

            if (rec.name.toLowerCase().indexOf(lcfilter)>=0) {
                res.push(rec);
            }
            else if (rec.description.toLowerCase().indexOf(lcfilter)>=0) {
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
    $scope.addFolderPath = function(label) {
        $scope.folderPath.push(label);
        $scope.filterMap[label.name] = true;
    }
    $scope.removeFolderPath = function(label) {
        var res = [];
        $scope.folderPath.map( function(item) {
            if (label.name != item.name) {
                res.push(item);
            }
        });
        $scope.folderPath = res;
        $scope.filterMap[label.name] = false;
    }
    $scope.trimFolderPath = function(index) {
        var res = [];
        var count = 0;
        $scope.folderPath.map( function(item) {
            if (count<index) {
                res.push(item);
                $scope.filterMap[item.name] = true;
            }
            else {
                $scope.filterMap[item.name] = false;
            }
            count++;
        });
        $scope.folderPath = res;
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
    $scope.getAvailableFolders = function() {
        var currPool = $scope.getRows();
        var labelMap = {};
        currPool.map( function(doc) {
            $scope.allLabels.map( function(val) {
                if (doc.labelMap[val.name]) {
                    labelMap[val.name] = true;
                }
            });
        });
        $scope.folderPath.map( function(folder) {
            labelMap[folder.name] = false;
        });
        var labelList = [];
        $scope.allLabels.map( function(val) {
            if (labelMap[val.name]) {
                labelList.push(val);
            }
        });
        labelList.sort( function(a,b) {
            if (a.name>b.name) {
                return 1;
            }
            else {
                return -1;
            }
        })
        return labelList.sort();
    }
    $scope.getUnmarked = function() {
        var avail = $scope.getAvailableFolders();
        var doclist = $scope.getRows();
        var res = [];
        doclist.map( function(doc) {
            var ok = true;
            avail.map( function(folder) {
                if (doc.labelMap[folder.name]) {
                    ok = false;
                }
            });
            if (ok) {
                res.push(doc);
            }
        });
        return res;
    }
    $scope.folderPathList = function() {
        var res = "";
        var needComma = false;
        $scope.folderPath.map( function(item) {
            if (needComma) {
                res += "|";
            }
            res += item.name;
            needComma = true;
        });
        return encodeURI(res);
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

<div ng-cloak>

<%@include file="ErrorPanel.jsp"%>

<div class="container-fluid">
    <div class="row">
        <div class="col-md-auto fixed-width border-end border-1 border-secondary">
      
        <span class="btn btn-raised btn-comment btn-secondary m-3 pb-2 pt-0" type="button" ng-click="openTopicCreator()" aria-labelledby="createNewTopic"><a class="nav-link" role="menuitem" href="DocsList.htm">
              Show Without Folders</a>
        </span>
          <span class="btn btn-raised btn-comment btn-secondary m-3 pb-2 pt-0" type="button" aria-labelledby="addDocs"><a class="nav-link" role="menuitem" tabindex="-1" href="DocsAdd.htm?folder={{folderPathList()}}">
              <img src="<%= ar.retPath%>assets/iconUpload.png" width="13" height="15" alt="" /> Add Document</a>
          </span>
          <span class="btn btn-raised btn-comment btn-secondary m-3 pb-2 pt-0" type="button" aria-labelledby="sendEmail"><a class="nav-link" role="menuitem" tabindex="-1" href="SendNote.htm">
              <img src="<%= ar.retPath%>assets/images/iconEmailNote.gif" width="13" height="15" alt="" /> Send Email</a>
          </span>
        </div>

    <div class="d-flex col-9">
        <div class="contentColumn">
            <div class=" bg-secondary-subtle p-3" id="allthefolders" >

                <div class="folderLine bg-secondary-subtle p-3" style="cursor:pointer">
                    <span class="fs-5 fw-bold" ng-click="trimFolderPath(0)">
                <img src="<%=ar.retPath%>assets/iconFolder.gif" style="130%">
                <img src="<%=ar.retPath%>assets/images/collapseIcon.gif"> Workspace
                    </span>
                </div>
                <div class="folderLine" style="margin-left:{{$index*15+15}}px;cursor:pointer" ng-repeat="folder in folderPath">
                    <span ng-click="trimFolderPath($index+1)">
                        <img src="<%=ar.retPath%>assets/iconFolder.gif">
                        <img src="<%=ar.retPath%>assets/images/collapseIcon.gif">
                        <button class="labelButton" style="background-color:{{folder.color}};">{{folder.name}}
                        </button>
                    </span>
                </div>
                <div class="well" ng-show="getAvailableFolders().length>0"> Choose Folder: 
                    <span class="folderLine" style="cursor:pointer" ng-repeat="folder in getAvailableFolders()">
                        <span ng-click="addFolderPath(folder)">
                    <button class="labelButton"
                        style="background-color:{{folder.color}};">{{folder.name}}
                    </button>
                        </span>
                    </span>
                </div>
            </div>

    <table class="table" width="100%">
        <tr class="gridTableHeader">
            <td width="50px">
                

            </td>
            <td width="80px"></td>
            <td width="420px"><h2 class="text-secondary fs-5">Documents ~ Description</h2></td>
            <td width="80px"><span class="text-secondary fs-5">Date</span></td>
        </tr>
        <tr ng-repeat="rec in getUnmarked()" ng-dblclick="openDocDialog(rec)">
            <td>
                <ul type="button" class="btn-tiny btn btn-outline-secondary m-2"  > 
                    <li class="nav-item dropdown"><a class=" dropdown-toggle" id="docsFolders" role="button" data-bs-toggle="dropdown" aria-expanded="false"><span class="caret"></span> </a>
                        <ul class="dropdown-menu" role="menu" aria-labelledby="docFolderList">
                            <li><a class="dropdown-item" role="menuitem" tabindex="-1" href="DocDetail.htm?aid={{rec.id}}">Access Document</a></li>
                            <li ng-show="rec.attType=='FILE'">
                                <a class="dropdown-item" role="menuitem" tabindex="-1" href="DocsRevise.htm?aid={{rec.id}}">Versions</a> </li>
                            <li><a class="dropdown-item" role="menuitem" tabindex="-1" ng-click="openDocDialog(rec)">Document Settings</a></li>
                            <hr>
                            <li><a class="dropdown-item" role="menuitem" tabindex="-1" ng-click="deleteDoc(rec)">Delete <i class="fa fa-trash"></i> Document</a></li>
                            <li><a class="dropdown-item" role="menuitem" tabindex="-1" href="SendNote.htm?att={{rec.id}}">Send Document By Email</a></li>
                        </ul>
                    </li>
                </ul>
            <td>
                <span ng-show="rec.attType=='FILE'" ng-click="openDocDialog(rec)">
                   <img src="<%=ar.retPath%>assets/images/iconFile.png"></span>
                <span ng-show="rec.attType=='URL'" ng-click="openDocDialog(rec)">
                   <img src="<%=ar.retPath%>assets/images/iconUrl.png"></span>
                <span ng-show="rec.deleted" style="color:red"> <i class="fa fa-trash"></i></span>
            </td>
            <td >
                <b><a href="DocDetail.htm?aid={{rec.id}}" title="{{rec.name}}">{{rec.name}}</a></b>
                ~ {{rec.description}}
                <span ng-repeat="label in getAllLabels(rec)"><button class="labelButton"
                    style="background-color:{{label.color}};">{{label.name}}
                    </button>
                </span>
            </td>
            <td>{{rec.modifiedtime|cdate}}</td>
        </tr>
    </table>
    
    
    <div class="guideVocal" ng-show="atts.length==0" style="margin-top:80px">
    You have no attached documents in this workspace yet.
    You can add them using a option from the pull-down in the upper right of this page.
    They can be uploaded from your workstation, or linked from the web.
    </div>
    
</div>
</div>
</div>


<script src="<%=ar.retPath%>new_assets/templates/DocumentDetail2.js"></script>
