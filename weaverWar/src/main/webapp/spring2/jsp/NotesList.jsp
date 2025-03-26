<%@page errorPage="/spring2/jsp/error.jsp"
%><%@ include file="/include.jsp"
%><%


    String pageId = ar.reqParam("pageId");
    String siteId = ar.reqParam("siteId");
    String startMode = ar.defParam("start", "nothing");
    NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngw);
    NGBook site = ngw.getSite();
    boolean canUpdate = ar.canUpdateWorkspace();
    
    JSONObject siteInfo = site.getConfigJSON();
    siteInfo.put("frozen", site.isFrozen());
    
    JSONObject workspaceInfo = ngw.getConfigJSON();
    
    boolean isMember = ar.canUpdateWorkspace();

    //set 'forceTemplateRefresh' in config file to 'true' to get this
    String templateCacheDefeater = "";
    if ("true".equals(ar.getSystemProperty("forceTemplateRefresh"))) {
        templateCacheDefeater = "?t="+System.currentTimeMillis();
    }
    
    UserProfile up = ar.getUserProfile();
    String currentUser = "NOBODY";
    String currentUserName = "NOBODY";
    String currentUserKey = "NOBODY";
    if (up!=null) {
        //this page can be viewed when not logged in, possibly with special permissions.
        //so you can't assume that up is non-null
        currentUser = up.getUniversalId();
        currentUserName = up.getName();
        currentUserKey = up.getKey();
    }

    JSONArray allLabels = ngw.getJSONLabels();
    
    JSONArray allRoles = new JSONArray();
    for (NGRole aRole : ngw.getAllRoles()) {
        allRoles.put(aRole.getName());
    }


/* NOTES RECORD PROTOTYPE
    $scope.notes = [
      {
        "comments": [
          {
            "content": "this is a comment",
            "time": 1435036060903,
            "user": "kswenson@us.example.com"
          },
          {
            "content": "another comment",
            "time": 1435036329093,
            "user": "kswenson@example.com"
          }
        ],
        "deleted": false,
        "docList": [],
        "draft": false,
        "html": "<h1>Minutes for Meeting: Status Update for May 19\n<\/h1><p>...\n<\/p>\n",
        "id": "6314",
        "labelMap": {},
        "modTime": 1434492969035,
        "modUser": {
          "name": "Keith Swenson",
          "uid": "kswenson@example.com"
        },
        "pin": 0,
        "public": false,
        "subject": "Minutes for Meeting: Status Update for May 19",
        "universalid": "MAPZIUHWG@test-for-john@6314"
      },
*/

%>

<style>
    .meeting-icon {
       cursor:pointer;
       color:LightSteelBlue;
    }

</style>
<script src="../../../jscript/AllPeople.js"></script>


<script type="text/javascript">


var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal) {
    setUpLearningMethods($scope, $modal, $http);
    window.setMainPageTitle("Discussion Topics");
    $scope.siteProxy = getSiteProxy("<%ar.writeJS(ar.baseURL);%>", "<%ar.writeJS(siteId);%>");
    $scope.wsProxy = $scope.siteProxy.getWorkspaceProxy("<%ar.writeJS(pageId);%>", $scope);
    $scope.startMode = "<%ar.writeJS(startMode);%>";
    $scope.siteInfo = <%siteInfo.write(out,2,4);%>;
    $scope.workspaceInfo = <%workspaceInfo.write(out,2,4);%>;
    $scope.allLabels = <%allLabels.write(out,2,4);%>;
    $scope.allRoles  = <%allRoles.write(out,2,2);%>;
    $scope.filter = "";
    $scope.showVizPub = true;
    $scope.showVizMem = true;
    $scope.showVizDel = false;
    $scope.filterMap = {};
    $scope.openMap = {};
    $scope.showFilter = <%=ar.isLoggedIn()%>;
    $scope.initialFetchDone = false;
    $scope.canUpdate = <%=canUpdate%>;

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };


    $scope.notes = [];
    $scope.fetchTopics = function(rec) {
        var postURL = "getTopics.json"
        var postdata = angular.toJson(rec);
        $scope.showError=false;
        $http.get(postURL, postdata)
        .success( function(data) {
            $scope.notes = data;
            $scope.sortNotes();
            $scope.initialFetchDone = true;
            console.log("Topics", $scope.notes);
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };
    $scope.fetchTopics();


    $scope.allLabels.sort( function(a,b) {
        if (a.name < b.name) {
            return -1;
        }
        if (a.name > b.name) {
            return 1;
        }
        return 0;
    });
    $scope.sortNotes = function() {
        $scope.notes.sort( function(a,b) {
            return b.modTime - a.modTime;
        });
    }
    $scope.sortNotes();
    $scope.getRows = function() {
        var src = $scope.notes;
        var res = [];
        src.map( function(aNote) {
            if (aNote.deleted && !$scope.showVizDel) {
                return;
            }
            var hasLabel = true;
            $scope.allLabels.map( function(val) {
                if ($scope.filterMap[val.name] && !aNote.labelMap[val.name]) {
                    hasLabel=false;
                }
            });
            if (!hasLabel) {
                return;
            }
            res.push(aNote);
        });
        src = res;
        
        var filterlist = parseLCList($scope.filter);
        for (var j=0; j<filterlist.length; j++) {
            var res = [];
            var lcfilter = filterlist[j].toLowerCase();
            src.map( function(aNote) {
                if (containsOne(aNote.subject, filterlist)) {
                    res.push(aNote);
                }
            });
            src = res;
        }
        $scope.lastDisplayedSetSize = src.length;
        return src;
    }
    $scope.hasLabel = function(searchName) {
        return $scope.filterMap[searchName];
    }
    $scope.toggleLabel = function(label) {
        $scope.filterMap[label.name] = !$scope.filterMap[label.name];
        $scope.showFilter=true;
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
    $scope.getNoteLabels = function(note) {
        var res = [];
        $scope.allLabels.map( function(val) {
            if (note.labelMap[val.name]) {
                res.push(val);
            }
        });
        return res;
    }
    $scope.toggleNoteDel = function(rec) {

        if (!$scope.canUpdate) {
            alert("You are not able to update this discussion because you are an unpaid user");
            return;
        }        newRec = {};
        newRec.id = rec.id;
        newRec.universalid = rec.universalid;
        newRec.deleted = !rec.deleted;
        $scope.updateNote(newRec);
    }
    $scope.updateNote = function(rec) {

        if (!$scope.canUpdate) {
            alert("You are not able to update this discussion because you are an unpaid user");
            return;
        }
        var postURL = "updateNote.json?nid="+rec.id;
        var postdata = angular.toJson(rec);
        $scope.showError=false;
        $http.post(postURL, postdata)
        .success( function(data) {
            $scope.removeEntry(rec.id);
            $scope.notes.push(data);
            $scope.sortNotes();
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };
    $scope.removeEntry = function(searchId) {
        var res = [];
        $scope.notes.map( function(rec) {
            if (searchId!=rec.id) {
                res.push(rec);
            }
        });
        $scope.notes = res;
    }

    $scope.openTopicCreator = function() {
        
        if (!$scope.canUpdate) {
            alert("You are not able to create a discussion because you are an unpaid user");
            return;
        }
        if ($scope.workspaceInfo.frozen) {
            alert("Sorry, this workspace is frozen by the administrator\nNew discussion can not be created in a frozen workspace.");
            return;
        }

        var modalInstance = $modal.open({
            animation: true,
            templateUrl: '<%=ar.retPath%>new_assets/templates/CreateTopicModal.html<%=templateCacheDefeater%>',
            controller: 'CreateTopicModalCtrl',
            size: 'lg',
            backdrop: "static",
            resolve: {
            }
        });

        modalInstance.result.then(function (createdTopic) {
            var newTopic = {}
            newTopic.id = "~new~";
            newTopic.wiki = HTML2Markdown(createdTopic.html);
            newTopic.subject = createdTopic.subject;
            newTopic.discussionPhase = createdTopic.phase;
            newTopic.modUser = {};
            newTopic.modUser.uid = "<%ar.writeJS(currentUser);%>";
            newTopic.modUser.name = "<%ar.writeJS(currentUserName);%>";
            newTopic.modUser.key = "<%ar.writeJS(currentUserKey);%>";
            var postURL = "noteHtmlUpdate.json?nid=~new~";
            var postdata = angular.toJson(newTopic);
            $scope.showError=false;
            $http.post(postURL ,postdata)
            .success( function(data) {
                window.location = "noteZoom"+data.id+".htm";
            })
            .error( function(data, status, headers, config) {
                $scope.reportError(data);
            });
        }, function () {
            //cancel action - nothing really to do
        });
    }

    $scope.getTopicStyle = function(note) {
        if (note.discussionPhase=="Draft") {
            return "draftTopic";
        }
        if (note.deleted) {
            return "trashTopic";
        }
        else {
            return "regularTopic";
        }
    }
    $scope.navigateToUser = function(player) {
        window.location="<%=ar.retPath%>v/"+encodeURIComponent(player.key)+"/PersonShow.htm";
    }
    $scope.sendNoteByMail = function(note) {
        if ("Draft" == note.discussionPhase) {
            alert("Before sending by email you need to POST the note (possibly sending email at that time)");
            return;
        }
        if ("Trash" == note.discussionPhase) {
            alert("This discussion has been deleted (in Trash).  Undelete it before sending by email.");
            return;
        }
        window.location = "SendNote.htm?noteId="+note.id;
    }
    if ($scope.startMode=="create") {
        $scope.openTopicCreator();
        $scope.startMode="nothing";
    }
});

</script>

<div>

<%@include file="ErrorPanel.jsp"%>
<div class="container-fluid override mx-2">
    <div class="col-md-auto second-menu d-flex">
            <button type="button" data-bs-toggle="collapse" data-bs-target="#collapseSecondaryMenu" aria-expanded="false" aria-controls="collapseSecondaryMenu">
                <i class="fa fa-bars"></i></button>
            <div class="collapse" id="collapseSecondaryMenu">
                <div class="col-md-auto">
                    <span class="btn second-menu-btn btn-wide" type="button" ng-click="openTopicCreator()" aria-labelledby="createNewTopic"><a class="nav-link" >Create New Topic</a>
                    </span>

                    <span class="btn second-menu-btn btn-wide" type="button" aria-labelledby="sendEmail"><a class="nav-link" href="SendNote.htm" >
                        <img src="<%= ar.retPath%>assets/images/iconEmailNote.gif" width="15" height="13" alt="" /> Send Email</a>
                    </span>
                    <span class="btn second-menu-btn btn-wide" type="button" aria-labelledby="createPDF"><a class="nav-link" href="PDFExport.htm" > Create PDF</a>
                    </span>
                    <span class="btn second-menu-btn btn-wide" type="button" aria-labelledby="createPDF"><a class="nav-link" href="searchAllNotes.htm" >Search All Topics </a>
                    </span>
                </div>
            </div>
        </div>
<hr>
    <div class="d-flex col-12">
        <div class="contentColumn">
            <div class="container-fluid">    
                <div class="generalContent">
                    <div class="well">Filter <input ng-model="filter"> &nbsp;
                        <span class="dropdown mb-0" ng-repeat="role in allLabelFilters()">
                <button class="labelButton " ng-click="toggleLabel(role)" style="background-color:{{role.color}};" ng-show="hasLabel(role.name)">{{role.name}} <i class="fa fa-close"></i></button>
                        </span>
                        <span class="dropdown nav-item mb-0">
                <button class="specCaretBtn dropdown" type="button" id="menu2" data-toggle="dropdown" title="Add Filter by Label"><i class="fa fa-filter"></i></button>
                    <ul class="dropdown-menu" role="menu" aria-labelledby="menu1" 
                           style="width:320px;left:-130px;margin-top:-2px;">
                         <li role="presentation" ng-repeat="rolex in allLabels" style="float:left">
                             <button role="menuitem" tabindex="-1" ng-click="toggleLabel(rolex)" class="btn labelButton" 
                             ng-hide="hasLabel(rolex.name)" style="background-color:{{rolex.color}}">
                                 {{rolex.name}}</button>
                         </li>
                       </ul>
                        </span> &nbsp;
                        <span style="vertical-align:middle"><input type="checkbox" ng-model="showDeleted"> Deleted </span> &nbsp;
                        <span style="vertical-align:middle"><input type="checkbox" ng-model="showDescription"> Description </span>
                    </div>
                    <div class="col-12">
                        <div class="my-3" ng-repeat="rec in getRows()">
                        <div class="{{getTopicStyle(rec)}}">
                            <div id="headline" >
                                <ul type="button" class="btn-tiny btn btn-outline-secondary m-2"  > 
                                    <li class="nav-item dropdown"><a class=" dropdown-toggle" id="ForumList" role="button" data-bs-toggle="dropdown" aria-expanded="false"><span class="caret"></span> </a>
                                        <ul class="dropdown-menu">
                                            <li><a class="dropdown-item" href="noteZoom{{rec.id}}.htm">Full Details</a></li>
                                            <li><a class="dropdown-item" ng-click="sendNoteByMail(rec)">Send Email</a></li>
                                            <li ng-hide="rec.deleted">
                                                <a class="dropdown-item" ng-click="toggleNoteDel(rec)">Trash <i class="fa fa-trash"></i> Topic</a></li>
                                            <li ng-show="rec.deleted"><a class="dropdown-item" ng-click="toggleNoteDel(rec)">Untrash <i class="fa fa-trash"></i> Topic</a>
                                            </li>
                                        </ul>
                                    </li>
                                </ul>
                                <span style="color:#220011;">
                                    <span ng-show="rec.deleted"><i class="fa fa-trash"></i></span>

                                    <a href="noteZoom{{rec.id}}.htm" style="color:black;">
                                    <b>{{rec.subject}}</b>
                                    ({{rec.modUser.name}})
                                    {{rec.modTime|cdate}}
                                    </a> &nbsp;

                    <span ng-repeat="label in getNoteLabels(rec)">
                      <button class="btn labelButton" style="background-color:{{label.color}};" ng-click="toggleLabel(label)"
                              title="click to filter/unfilter all discussions by this label">
                      {{label.name}}
                      </button>
                    </span>
                  </span>
                  &nbsp;
                  <a class="text-primary fa fa-minus-square-o meeting-icon" ng-click="openMap[rec.id]=false" ng-show="openMap[rec.id]" 
                     title="close the info"></a>
                  <a class="text-secondary fa fa-plus-square-o meeting-icon" ng-click="openMap[rec.id]=true" ng-show="!openMap[rec.id]" 
                     title="info of this discussion"></a>
                   <span ng-show="rec.discussionPhase=='Draft'"> <b>-DRAFT-</b> </span>
                </div>
                <div class="leafContent" ng-show="openMap[rec.id]" style="background-color:white;border-radius:10px;margin:5px;">
                    <div>
                    <div class="infoRow">
                      <span class="h6">Last Update by:</span> 
                      <span>
                        <span class="nav-item dropdown">
                            <span id="menu_1" data-toggle="dropdown">
                            <img class="rounded-5" src="<%=ar.retPath%>icon/{{rec.modUser.key}}.jpg" 
                                 style="width:32px;height:32px" title="{{rec.modUser.name}} - {{rec.modUser.uid}}">
                            </span>
                            <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
                              <li role="presentation" style="background-color:lightgrey"><a class="dropdown-item" role="menuitem" 
                                  tabindex="-1" ng-click="" style="text-decoration: none;text-align:center">
                                  {{rec.modUser.name}}<br/>{{rec.modUser.uid}}</a></li>
                              <li role="presentation" style="cursor:pointer"><a class="dropdown-item" role="menuitem" tabindex="-1"
                                  ng-click="navigateToUser(rec.modUser)">
                                  <span class="fa fa-user"></span> Visit Profile</a></li>
                            </ul>
                        </span>
                        {{rec.modUser.name}}
                      </span>
                    </div>
                    <div class="infoRow">
                      <span class="h6">Last Modified:</span>
                      <td>{{rec.modTime|date:"MMM dd, yyyy 'at' HH:mm:ss"}}</td>
                    </div>
                    <div class="infoRow">
                      <span class="h6">Discussion Phase:</span>
                      <span>{{rec.discussionPhase}}</span>
                    </div>
                    <div class="infoRow">
                      <span class="h6">Subscribers:</span>
                      <span>
                        <span ng-repeat="person in rec.subscribers">
                          <span class="nav-item dropdown">
                            <span id="menu_2" data-toggle="dropdown">
                            <img class="rounded-5" src="<%=ar.retPath%>icon/{{person.key}}.jpg" 
                                 style="width:32px;height:32px" title="{{person.name}} - {{person.uid}}">
                            </span>
                            <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
                              <li role="presentation" style="background-color:lightgrey"><a class="dropdown-item" role="menuitem" 
                                  tabindex="0" ng-click="" style="text-decoration: none;text-align:center">
                                  {{person.name}}<br/>{{person.uid}}</a></li>
                              <li role="presentation" style="cursor:pointer"><a class="dropdown-item" role="menuitem" tabindex="0"
                                  ng-click="navigateToUser(person)">
                                  <span class="fa fa-user"></span> Visit Profile</a></li>
                            </ul>
                          </span>
                        </span>
                      </span>
                    </div>
                    <div class="infoRow">
                      <span class="h6">Responses:</span>
                      <span>Needed: {{rec.responsesNeeded}},  Made: {{rec.responsesMade}}</span>
                    </div>
                </div>
                </div>
            </div>
                        </div>
                    </div>

        
    <div class="instruction" ng-show="!initialFetchDone" style="margin-top:80px">
    Fetching discussions . . .
    </div>
    <div class="guideVocal" ng-show="notes.length==0 && initialFetchDone" style="margin-top:80px">
    You have no discussions in this workspace yet.
    You can add them using a option from the pull-down in the upper right of this page.
    </div>
    <div class="guideVocal" ng-show="notes.length>0 && initialFetchDone && lastDisplayedSetSize==0" style="margin-top:80px">
    None of the {{notes.length}} discussions match the filter conditions you have chosen.
    </div>
    
    
       
</div>
<div style="height:200px"></div>

<script src="<%=ar.retPath%>new_assets/templates/CreateTopicModal.js"></script>
