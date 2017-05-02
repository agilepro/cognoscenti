<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="org.socialbiz.cog.NGRole"
%><%@page import="org.socialbiz.cog.CustomRole"
%><%


    String pageId      = ar.reqParam("pageId");
    NGWorkspace ngw = ar.getCogInstance().getWorkspaceByKeyOrFail(pageId);
    ar.setPageAccessLevels(ngw);
    NGBook ngb = ngw.getSite();
    boolean isMember = ar.isMember();

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

    List<TopicRecord> aList = ngw.getAllNotes();

    JSONArray notes = new JSONArray();
    for (TopicRecord aNote : aList) {

        String discussionPhase = aNote.getDiscussionPhase();

        if (aNote.isPublic()) {
            notes.put( aNote.getJSONWithHtml(ar, ngw) );
        }
        else if (!ar.isLoggedIn()) {
            continue;
        }
        else if ("Draft".equals(discussionPhase)) {
            if (ar.getUserProfile().hasAnyId(aNote.getModUser().getUniversalId())) {
                notes.put( aNote.getJSONWithHtml(ar, ngw) );
            }
        }
        else if (isMember) {
            notes.put( aNote.getJSONWithHtml(ar, ngw) );
        }
        else {
            //run through all the roles here and see if any role
            //has access to the note
        }
    }

    JSONArray allLabels = ngw.getJSONLabels();


/* NOTES RECORD PROTOTYPE
    $scope.notes = [
      {
        "comments": [
          {
            "content": "this is a comment",
            "time": 1435036060903,
            "user": "kswenson@us.fujitsu.com"
          },
          {
            "content": "another comment",
            "time": 1435036329093,
            "user": "kswenson@us.fujitsu.com"
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
          "uid": "kswenson@us.fujitsu.com"
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

<script type="text/javascript">
function httpGet(theUrl)
{
    var xmlHttp = new XMLHttpRequest();
    xmlHttp.open( "GET", theUrl, false ); // false for synchronous request
    xmlHttp.send( null );
    return JSON.parse(xmlHttp.responseText);
}


var app = angular.module('myApp', ['ui.bootstrap', 'ui.tinymce', 'ngSanitize']);
app.controller('myCtrl', function($scope, $http, $modal) {
    window.setMainPageTitle("Discussion Topics");
    $scope.allLabels = <%allLabels.write(out,2,4);%>;
    $scope.filter = "";
    $scope.showVizPub = true;
    $scope.showVizMem = true;
    $scope.showVizDel = false;
    $scope.filterMap = {};
    $scope.openMap = {};
    $scope.showFilter = <%=ar.isLoggedIn()%>;
    $scope.allowPrivate = <%=ngb.getAllowPrivate()%>;

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
            if (aNote.public && !aNote.deleted && !$scope.showVizPub) {
                return;
            }
            if (!aNote.public && !aNote.deleted && !$scope.showVizMem) {
                return;
            }
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
        var filterlist = $scope.filter.split(" ");
        for (var j=0; j<filterlist.length; j++) {
            var res = [];
            var lcfilter = filterlist[j].toLowerCase();
            src.map( function(aNote) {
                if (aNote.subject.toLowerCase().indexOf(lcfilter)>=0) {
                    res.push(aNote);
                }
                else if (aNote.html.toLowerCase().indexOf(lcfilter)>=0) {
                    res.push(aNote);
                }
            });
            src = res;
        }
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
        newRec = {};
        newRec.id = rec.id;
        newRec.universalid = rec.universalid;
        newRec.deleted = !rec.deleted;
        $scope.updateNote(newRec);
    }
    $scope.toggleNoteViz = function(rec) {
        newRec = {};
        newRec.id = rec.id;
        newRec.universalid = rec.universalid;
        newRec.public = !rec.public;
        $scope.updateNote(newRec);
    }
    $scope.updateNote = function(rec) {
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

        var modalInstance = $modal.open({
            animation: false,
            templateUrl: '<%=ar.retPath%>templates/CreateTopicModal.html?t=<%=System.currentTimeMillis()%>',
            controller: 'CreateTopicModalCtrl',
            size: 'lg',
            backdrop: "static",
            resolve: {
            }
        });

        modalInstance.result.then(function (createdTopic) {
			var newTopic = {}
            newTopic.id = "~new~";
			newTopic.html = createdTopic.html;
			newTopic.subject = createdTopic.subject;
			newTopic.discussionPhase = createdTopic.phase;
            newTopic.public = !$scope.allowPrivate;
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

});

</script>

<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

    <div class="upRightOptions rightDivContent">
      <span class="dropdown">
        <button class="btn btn-default btn-raised dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
                Options: <span class="caret"></span></button>
        <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
          <!--li role="presentation"><a role="menuitem" ng-click="showFilter=true">
              Show Filter</a>
          </li-->
          <li role="presentation"><a role="menuitem" ng-click="openTopicCreator()">
              Create New Topic</a>
          </li>

          <li role="presentation"><a role="menuitem" href="sendNote.htm">
              <img src="<%= ar.retPath%>assets/images/iconEmailNote.gif" width="13" height="15" alt="" />
              Send Email</a>
          </li>
          <li role="presentation"><a role="menuitem" href="exportPDF.htm">
              Create PDF</a>
          </li>
          <li role="presentation"><a role="menuitem" href="searchAllNotes.htm">
              Search All Topics </a>
          </li>
        </ul>
      </span>
     </div>

    <div class="well fluid-container" ng-show="showFilter">
        <!--div style="float:right;cursor:pointer;" href="#" ng-click="showFilter=false">x</div-->
      <div class="row">
        <div class="col-md-3">
          Filter
          <input ng-model="filter">
        </div>
        <div class="togglebutton col-md-2">
          <label>
            <input type="checkbox" ng-model="showVizPub"> Public
          </label>
        </div>
        <div class="togglebutton col-md-2">
          <label>
            <input type="checkbox" ng-model="showVizMem"> Members-Only
          </label>
        </div>
        <div class="togglebutton col-md-3">
          <label>
            <input type="checkbox" ng-model="showVizDel"> Include deleted
          </label>
        </div>
        <div class="col-md-2">
          <span class="dropdown">
            <button class="btn btn-sm btn-primary btn-raised dropdown-toggle" type="button" data-toggle="dropdown"
            title="Add Filter by Label">Filter by Label</button>
            <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
              <li role="presentation" ng-repeat="rolex in allLabels">
                  <button role="menuitem" tabindex="-1" href="#"  ng-click="toggleLabel(rolex)" class="btn btn-sm labelButton"
                  ng-hide="hasLabel(rolex.name)" style="background-color:{{rolex.color}};">
                      {{rolex.name}}</button>
              </li>
            </ul>
          </span>
        </div>
      </div>
    </div>

    <style>
    .regularTopic {
        border: 1px solid lightgrey;
        border-radius:10px;
        margin-top:20px;
        padding:5px;
        background-color:#F8EEEE;
    }
    .draftTopic {
        border: 1px solid lightgrey;
        border-radius:10px;
        margin-top:20px;
        padding:5px;
        background-color:yellow;
    }
    .trashTopic {
        border: 1px solid lightgrey;
        border-radius:10px;
        margin-top:20px;
        padding:5px;
        background-color:pink;
    }

    </style>

    <div style="height:20px;"></div>

    <% if (isMember) { %>
        <div>
            <button class="btn btn-default btn-raised" ng-click="openTopicCreator()">
			    Create New Topic
            </button>
        </div>
    <% } %>
    
        <div ng-repeat="rec in getRows()">
            <div class="{{getTopicStyle(rec)}}">
                <div id="headline" >
                  <span class="dropdown">
                    <button class="dropdown-toggle specCaretBtn" type="button"  d="menu"
                        data-toggle="dropdown"> <span class="caret"></span> </button>
                    <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
                      <li role="presentation">
                          <a role="menuitem" tabindex="-1" href="noteZoom{{rec.id}}.htm">Full Details</a></li>
                      <li role="presentation">
                          <a role="menuitem" tabindex="-1" href="sendNote.htm?noteId={{rec.id}}">Send Email</a></li>
                      <li role="presentation" ng-hide="rec.public || rec.deleted">
                          <a role="menuitem" tabindex="-1" ng-click="toggleNoteViz(rec)">Make <img src="<%=ar.retPath%>assets/images/iconPublic.png"> Public</a></li>
                      <li role="presentation" ng-show="rec.public && allowPrivate">
                          <a role="menuitem" tabindex="-1" ng-click="toggleNoteViz(rec)">Make <img src="<%=ar.retPath%>assets/images/iconMember.png"> Member Only</a></li>
                      <li role="presentation" ng-hide="rec.deleted">
                          <a role="menuitem" tabindex="-1" ng-click="toggleNoteDel(rec)">Trash <i class="fa fa-trash"></i> Topic</a></li>
                      <li role="presentation" ng-show="rec.deleted">
                          <a role="menuitem" tabindex="-1" ng-click="toggleNoteDel(rec)">Untrash <i class="fa fa-trash"></i> Topic</a></li>
                    </ul>
                  </span>
                  <span style="color:#220011;">
                    <span ng-show="rec.deleted"><i class="fa fa-trash"></i></span>
                    <span ng-show="rec.public"><img src="<%=ar.retPath%>assets/images/iconPublic.png"></span>
                    <span ng-show="!rec.public && !rec.deleted"><img src="<%=ar.retPath%>assets/images/iconMember.png"></span>
                    <a href="noteZoom{{rec.id}}.htm" style="color:black;">
                        <b>{{rec.subject}}</b>
                        ({{rec.modUser.name}})
                        {{rec.modTime|date}}
                    </a>

                    <span ng-repeat="label in getNoteLabels(rec)">
                      <button class="labelButton" style="background-color:{{label.color}};" ng-click="toggleLabel(label)">
                      {{label.name}}
                      </button>
                    </span>
                  </span>
                  &nbsp;
                  <a class="fa fa-minus-square-o meeting-icon" ng-click="openMap[rec.id]=false" ng-show="openMap[rec.id]"></a>
                  <a class="fa fa-plus-square-o meeting-icon" ng-click="openMap[rec.id]=true" ng-show="!openMap[rec.id]" title="preview this topic"></a>
                   <span ng-show="rec.discussionPhase=='Draft'"> <b>-DRAFT-</b> </span>
                </div>
                <div class="leafContent" ng-show="openMap[rec.id]" style="background-color:white;border-radius:10px;margin:5px;">
                    <div ng-bind-html="rec.html"></div>
                </div>
            </div>
        </div>

</div>

<script src="<%=ar.retPath%>templates/CreateTopicModal.js"></script>
