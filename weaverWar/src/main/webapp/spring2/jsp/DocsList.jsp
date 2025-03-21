<%@page errorPage="/spring2/jsp/error.jsp"
%><%@ include file="/include.jsp"
%><%


    String pageId = ar.reqParam("pageId");
    String siteId = ar.reqParam("siteId");
    NGWorkspace ngp = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngp);
    ar.assertAccessWorkspace("Documents are available only to members");
    NGBook site = ngp.getSite();
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
    setUpLearningMethods($scope, $modal, $http);
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

    $scope.getLabelsForDoc = function(doc) {
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
            //for each document provide a complete user object
            rec.user = rec.modifier;
            console.log("FOUND USER", rec.user);
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
            templateUrl: "<%= ar.retPath%>new_assets/templates/DocumentDetail2.html<%=templateCacheDefeater%>",
            controller: 'DocumentDetailsCtrl',
            size: 'lg',
            backdrop: "static",
            resolve: {
                docId: function () {
                    return doc.id;
                },
                siteInfo: function() {
                    return $scope.siteInfo;
                },
                wsUrl: function() {
                    return $scope.wsUrl;
                }
            }
        });

        docsDialogInstance.result
        .then(function () {
            $scope.getDocumentList();
            $scope.getAllLabels();
        }, function () {
            $scope.getDocumentList();
            $scope.getAllLabels();
        });
    };
    
    $scope.navigateToCreator = function(player) {
        console.log("PLAYER:", player);
        window.open("<%= ar.retPath%>v/"+encodeURIComponent(player.key)+"/PersonShow.htm","_blank");
    }
    
    $scope.getAllLabels = function() {
        var postURL = "getLabels.json";
        $scope.showError=false;
        $http.post(postURL, "{}")
        .success( function(data) {
            console.log("All labels are gotten: ", data);
            $scope.allLabels = data.list;
            $scope.sortAllLabels();
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };
    $scope.sortAllLabels = function() {
        $scope.allLabels.sort( function(a, b){
              if (a.name.toLowerCase() < b.name.toLowerCase())
                return -1;
              if (a.name.toLowerCase() > b.name.toLowerCase())
                return 1;
              return 0;
        });
    };
    $scope.getAllLabels();

});

</script>

<div ng-cloak>

<%@include file="ErrorPanel.jsp"%>

<div class="container-fluid override mx-2">
    <div class="col-md-auto second-menu d-flex">
            <button type="button" data-bs-toggle="collapse" data-bs-target="#collapseSecondaryMenu" aria-expanded="false" aria-controls="collapseSecondaryMenu">
                <i class="fa fa-bars"></i>
            </button>
            <div class="collapse" id="collapseSecondaryMenu">
                <div class="col-md-auto">
                    <span class="btn second-menu-btn btn-wide" type="button"><a class="nav-link" href="DocsFolder.htm">Show Folders</a></span>
                    <span class="btn second-menu-btn btn-wide" type="button" aria-labelledby="addDocument"><a class="nav-link" href="DocsAdd.htm">
                        <img src="<%= ar.retPath%>assets/iconUpload.png" width="15" height="13" alt="" /> Add Document</a>
                    </span>
                    <span class="btn second-menu-btn btn-wide" type="button" aria-labelledby="sendEmail"><a class="nav-link" href="SendNote.htm">
                        <img src="<%= ar.retPath%>assets/images/iconEmailNote.gif" width="15" height="13" alt="" /> Send Email</a>
                    </span>
                    <span class="btn second-menu-btn btn-wide" type="button" aria-labelledby="SharePorts"><a class="nav-link" href="SharePorts.htm">Share Ports</a>
                    </span>
                    
                </div>
            </div>
      </div><hr>


      <div class="d-flex col-12 m-2"><div class="contentColumn">
            <div class="well">Filter <input ng-model="filter"> &nbsp;
                <span class="dropdown mb-0" ng-repeat="role in allLabelFilters()">
            <button class="labelButton " ng-click="toggleLabel(role)" style="background-color:{{role.color}};" ng-show="hasLabel(role.name)">{{role.name}} <i class="fa fa-close"></i></button>
        </span>
        <span class="dropdown nav-item mb-0">
            <button class="specCaretBtn dropdown" type="button" id="menu2" data-toggle="dropdown" title="Add Filter by Label"><i class="fa fa-filter"></i></button>
                <ul class="dropdown-menu" role="menu" aria-labelledby="menu1" 
                       style="width:320px;left:-130px;margin-top:-2px;">
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

    <div class="col-12">

        <div class="row mx-3">
            <span class="col-7 h6">Name ~ Description</span>
            <span class="col-2 h6">Date</span>
            <span class="col-2 h6">Size</span>
        </div>
        <div class="row my-3" ng-repeat="rec in getRows()" ng-dblclick="openDocDialog(rec)">
            <span class="col-5">
                <ul type="button" class="btn-tiny btn btn-outline-secondary m-2"  >
                    <li class="nav-item dropdown"><a class=" dropdown-toggle" id="docsList" role="button" data-bs-toggle="dropdown" aria-expanded="false"><span class="caret"></span> </a>
                        <ul class="dropdown-menu" role="menu" aria-labelledby="docsList">
                            <li><a class="dropdown-item" role="menuitem" tabindex="0" href="DocDetail.htm?aid={{rec.id}}">Access Document</a></li>
                            <li ng-show="rec.attType=='FILE'">
                                <a class="dropdown-item" role="menuitem" tabindex="-1" href="DocsRevise.htm?aid={{rec.id}}">Versions</a></li>
                            <li><a class="dropdown-item" role="menuitem" tabindex="-1" ng-click="openDocDialog(rec)">Edit Document Settings</a></li>
                            <hr>
                            <li><a class="dropdown-item" role="menuitem" tabindex="-1" ng-click="toggleDelete(rec)">
                                <span ng-show="rec.deleted">Un-</span>Delete <i class="fa fa-trash"></i> Document</a></li>
                            <li><a class="dropdown-item" role="menuitem" tabindex="-1" href="SendNote.htm?att={{rec.id}}">Send By <i class="fa fa-envelope"></i> Email</a>
                            </li>
                        </ul>
                    </li>
                </ul>
                <span style="text-align: center">
                <span ng-click="downloadDocument(rec)" ng-show="rec.attType=='URL'">
                <span class="fa fa-external-link"></span></span>
                <span ng-click="downloadDocument(rec)" ng-show="rec.attType=='FILE'">
                <span class="fa fa-download"></span></span>
                </span>

                <b><a href="DocDetail.htm?aid={{rec.id}}" title="{{rec.name}}">{{rec.name}}</a></b>
                <span ng-show="rec.deleted" style="color:red"> (deleted) </span>
                <span ng-repeat="label in getLabelsForDoc(rec)">
                    <button class="labelButton" 
                        ng-click="toggleLabel(label)"
                        style="background-color:{{label.color}};">{{label.name}}
                    </button>
                </span>
            
              <div ng-show="showDescription && rec.description" ng-bind-html="rec.html">
              </div>
            </span>
            <span class="col-1">
              <span class="dropdown nav-item" >
                <span id="user" data-bs-toggle="dropdown">
                <img class="rounded-5" 
                     ng-src="<%=ar.retPath%>icon/{{rec.user.uid}}.jpg" 
                     style="width:32px;height:32px" >
                </span>
                <ul class="dropdown-menu" role="menu" aria-labelledby="user">
                  <li role="presentation" style="background-color:lightgrey"><a class="dropdown-item" role="menuitem" 
                      tabindex="-1">
                      {{rec.user.name}}<br/>{{rec.user.uid}}</a></li>
                  <li role="presentation" style="cursor:pointer"><a class="dropdown-item" role="menuitem" tabindex="-1"
                      ng-click="navigateToCreator(rec.user)">
                      <span class="fa fa-user"></span> Visit Profile</a></li>
                </ul>
              </span>
            </span>
            <span class="col-1" style="text-align: center" ng-click="openDocDialog(rec)">
                <span ng-show="rec.attType=='FILE'"><img src="<%=ar.retPath%>assets/images/iconFile.png"></span>
                <span ng-show="rec.attType=='URL'"><img src="<%=ar.retPath%>assets/images/iconUrl.png"></span>
            </span>
            <span class="col-2" ng-click="openDocDialog(rec)">{{rec.modifiedtime|cdate}}</span>
            <span class="col-2" ng-click="openDocDialog(rec)"><span ng-show="rec.size>0">{{rec.size|number}}</span></span>
        </div>
    </div>
    
    
    <div class="guideVocal" ng-show="dataArrived && atts.length==0" style="margin-top:80px">
    You have no attached documents in this workspace yet.
    You can add them using a option from the pull-down in the upper right of this page.
    They can be uploaded from your workstation, or linked from the web.
    </div>
    
    
                </div>
            </div>
        </div>
    </div>

<!--have to make room for menu on bottom line-->
<div style="height:300px"></div>
    <!--room at bottom to show white space so it is clear page is ended-->
    <div style="height:200px"></div>    
</div>


<script src="<%=ar.retPath%>new_assets/templates/DocumentDetail2.js"></script>
<script src="<%=ar.baseURL%>new_assets/templates/EditLabelsCtrl.js"></script>

