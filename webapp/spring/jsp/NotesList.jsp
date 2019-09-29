<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="org.socialbiz.cog.NGRole"
%><%@page import="org.socialbiz.cog.CustomRole"
%><%


    String pageId = ar.reqParam("pageId");
    String siteId = ar.reqParam("siteId");
    NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngw);
    NGBook ngb = ngw.getSite();
    
    JSONObject siteInfo = ngb.getConfigJSON();
    siteInfo.put("frozen", ngb.isFrozen());
    
    JSONObject workspaceInfo = ngw.getConfigJSON();
    
    boolean isMember = ar.isMember();

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


var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal) {
    window.setMainPageTitle("Discussion Topics");
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
        newRec = {};
        newRec.id = rec.id;
        newRec.universalid = rec.universalid;
        newRec.deleted = !rec.deleted;
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
        
        if ($scope.workspaceInfo.frozen) {
            alert("Sorry, this workspace is frozen by the administrator\nNew discussion topics can not be created in a frozen workspace.");
            return;
        }

        var modalInstance = $modal.open({
            animation: false,
            templateUrl: '<%=ar.retPath%>templates/CreateTopicModal.html<%=templateCacheDefeater%>',
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
    $scope.imageName = function(player) {
        if (player.key) {
            return player.key+".jpg";
        }
        else {
            var lc = player.uid.toLowerCase();
            var ch = lc.charAt(0);
            var i =1;
            while(i<lc.length && (ch<'a'||ch>'z')) {
                ch = lc.charAt(i); i++;
            }
            return "fake-"+ch+".jpg";
        }
    }
    $scope.navigateToUser = function(player) {
        window.location="<%=ar.retPath%>v/FindPerson.htm?uid="+encodeURIComponent(player.key);
    }
    $scope.sendNoteByMail = function(note) {
        if ("Draft" == note.discussionPhase) {
            alert("Before sending by email you need to POST the note (possibly sending email at that time)");
            return;
        }
        if ("Trash" == note.discussionPhase) {
            alert("This topic has been deleted (in Trash).  Undelete it before sending by email.");
            return;
        }
        window.location = "SendNote.htm?noteId="+note.id;
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
          <li role="presentation"><a role="menuitem" ng-click="openTopicCreator()">
              Create New Topic</a>
          </li>

          <li role="presentation"><a role="menuitem" href="SendNote.htm">
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
     
    <div class="well">
        Filter <input ng-model="filter"> &nbsp;
        <span style="vertical-align:middle;" ><input type="checkbox" ng-model="showVizDel">
            Deleted</span> &nbsp;
        <span class="dropdown" ng-repeat="role in allLabelFilters()">
            <button class="labelButton" type="button" id="menu2"
               data-toggle="dropdown" style="background-color:{{role.color}};"
               ng-show="hasLabel(role.name)">{{role.name}} <i class="fa fa-close"></i></button>
            <ul class="dropdown-menu" role="menu" aria-labelledby="menu2">
               <li role="presentation"><a role="menuitem" title="{{add}}"
                  ng-click="toggleLabel(role)">Remove Filter:<br/>{{role.name}}</a></li>
            </ul>
        </span>
        <span>
             <span class="dropdown">
               <button class="btn btn-sm btn-primary btn-raised dropdown-toggle" type="button" id="menu2" data-toggle="dropdown"
                       title="Add Filter by Label"><i class="fa fa-filter"></i></button>
               <ul class="dropdown-menu" role="menu" aria-labelledby="menu1" 
                   style="width:320px;left:-130px">
                 <li role="presentation" ng-repeat="rolex in allLabels" style="float:left">
                     <button role="menuitem" tabindex="-1" ng-click="toggleLabel(rolex)" class="labelButton" 
                     ng-hide="hasLabel(rolex.name)" style="background-color:{{rolex.color}}">
                         {{rolex.name}}</button>
                 </li>
               </ul>
             </span>
        </span>
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
    .infoRow {
        min-height:35px;
        padding:5px;
    }
    .infoRow td {
        padding:5px 10px;
    }

    </style>

    <div style="height:20px;"></div>

    <% if (isMember) { %>
        <div>
            <button class="btn btn-primary btn-raised" ng-click="openTopicCreator()">
			    <i class="fa fa-plus"></i> Create New Topic
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
                          <a role="menuitem" tabindex="-1" ng-click="sendNoteByMail(rec)">Send Email</a></li>
                      <li role="presentation" ng-hide="rec.deleted">
                          <a role="menuitem" tabindex="-1" ng-click="toggleNoteDel(rec)">Trash <i class="fa fa-trash"></i> Topic</a></li>
                      <li role="presentation" ng-show="rec.deleted">
                          <a role="menuitem" tabindex="-1" ng-click="toggleNoteDel(rec)">Untrash <i class="fa fa-trash"></i> Topic</a></li>
                    </ul>
                  </span>
                  <span style="color:#220011;">
                    <span ng-show="rec.deleted"><i class="fa fa-trash"></i></span>

                    <a href="noteZoom{{rec.id}}.htm" style="color:black;">
                        <b>{{rec.subject}}</b>
                        ({{rec.modUser.name}})
                        {{rec.modTime|date}}
                    </a>

                    <span ng-repeat="label in getNoteLabels(rec)">
                      <button class="labelButton" style="background-color:{{label.color}};" ng-click="toggleLabel(label)"
                              title="click to filter/unfilter all topics by this label">
                      {{label.name}}
                      </button>
                    </span>
                  </span>
                  &nbsp;
                  <a class="fa fa-minus-square-o meeting-icon" ng-click="openMap[rec.id]=false" ng-show="openMap[rec.id]" 
                     title="close the info"></a>
                  <a class="fa fa-plus-square-o meeting-icon" ng-click="openMap[rec.id]=true" ng-show="!openMap[rec.id]" 
                     title="info of this topic"></a>
                   <span ng-show="rec.discussionPhase=='Draft'"> <b>-DRAFT-</b> </span>
                </div>
                <div class="leafContent" ng-show="openMap[rec.id]" style="background-color:white;border-radius:10px;margin:5px;">
                    <table>
                    <tr class="infoRow">
                      <td>Last Update by:</td> 
                      <td>
                        <span class="dropdown">
                            <span id="menu1" data-toggle="dropdown">
                            <img class="img-circle" src="<%=ar.retPath%>icon/{{imageName(rec.modUser)}}" 
                                 style="width:32px;height:32px" title="{{rec.modUser.name}} - {{rec.modUser.uid}}">
                            </span>
                            <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
                              <li role="presentation" style="background-color:lightgrey"><a role="menuitem" 
                                  tabindex="-1" ng-click="" style="text-decoration: none;text-align:center">
                                  {{rec.modUser.name}}<br/>{{rec.modUser.uid}}</a></li>
                              <li role="presentation" style="cursor:pointer"><a role="menuitem" tabindex="-1"
                                  ng-click="navigateToUser(rec.modUser)">
                                  <span class="fa fa-user"></span> Visit Profile</a></li>
                            </ul>
                        </span>
                        {{rec.modUser.name}}
                      </td>
                    </tr>
                    <tr class="infoRow">
                      <td>Last Modified:</td>
                      <td>{{rec.modTime|date:"MMM dd, yyyy 'at' HH:mm:ss"}}</td>
                    </tr>
                    <tr class="infoRow">
                      <td>Discussion Phase:</td>
                      <td>{{rec.discussionPhase}}</td>
                    </tr>
                    <tr class="infoRow">
                      <td>Subscribers:</td>
                      <td>
                        <span ng-repeat="person in rec.subscribers">
                          <span class="dropdown">
                            <span id="menu1" data-toggle="dropdown">
                            <img class="img-circle" src="<%=ar.retPath%>icon/{{imageName(person)}}" 
                                 style="width:32px;height:32px" title="{{person.name}} - {{person.uid}}">
                            </span>
                            <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
                              <li role="presentation" style="background-color:lightgrey"><a role="menuitem" 
                                  tabindex="-1" ng-click="" style="text-decoration: none;text-align:center">
                                  {{person.name}}<br/>{{person.uid}}</a></li>
                              <li role="presentation" style="cursor:pointer"><a role="menuitem" tabindex="-1"
                                  ng-click="navigateToUser(person)">
                                  <span class="fa fa-user"></span> Visit Profile</a></li>
                            </ul>
                          </span>
                        </span>
                      </td>
                    </tr>
                    </table>
                </div>
            </div>
        </div>

        
    <div class="instruction" ng-show="!initialFetchDone" style="margin-top:80px">
    Fetching topics . . .
    </div>
    <div class="guideVocal" ng-show="notes.length==0 && initialFetchDone" style="margin-top:80px">
    You have no discussion topics in this workspace yet.
    You can add them using a option from the pull-down in the upper right of this page.
    </div>
    <div class="guideVocal" ng-show="notes.length>0 && initialFetchDone && lastDisplayedSetSize==0" style="margin-top:80px">
    None of the {{notes.length}} topics match the filter conditions you have chosen.
    </div>
    
    
       
</div>

<script src="<%=ar.retPath%>templates/CreateTopicModal.js"></script>
