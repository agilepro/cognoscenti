<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="org.socialbiz.cog.NGRole"
%><%@page import="org.socialbiz.cog.CustomRole"
%><%


    String pageId      = ar.reqParam("pageId");
    NGPage ngp = ar.getCogInstance().getProjectByKeyOrFail(pageId);
    ar.setPageAccessLevels(ngp);
    NGBook ngb = ngp.getSite();
    boolean isMember = ar.isMember();


    UserProfile up = ar.getUserProfile();

    List<NoteRecord> aList = ngp.getAllNotes();

    JSONArray notes = new JSONArray();
    for (NoteRecord aNote : aList) {

        //when not a member (and not logged in) only include public notes
        //if (!aNote.isPublic() && !isMember) {
        //    continue;
        //}
        if (aNote.isPublic()) {
            notes.put( aNote.getJSONWithHtml(ar) );
        }
        else if (!ar.isLoggedIn()) {
            continue;
        }
        else if (isMember) {
            notes.put( aNote.getJSONWithHtml(ar) );
        }
        else {
            //run through all the roles here and see if any role
            //has access to the note
        }
    }

    //we purposefull combine both labels and roles into a single array here
    JSONArray allLabels = ngp.getJSONLabels();


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
        "html": "<h1>Minutes for Meeting: Status Update for May 19\n<\/h1><h2>1. Discuss the Weather\n<\/h2><p>\n(15 minutes) <i>hot toipc<\/i>\n<\/p>\n<p>\n<i>Notes:<\/i>\n<\/p>\n<ul>\n<li>\n No <b>thunder <\/b><i>storm <\/i>today.....\n<\/li>\n<li>\n none tomorow <b>either <\/b>klakj f\n<\/li>\n<\/ul>\n<p>\nasdflkj alsdkjf lkasjdflkj alsdfkj lasjdkf lkj klasdf\n<\/p>\n<h2>2. Discuss Barnacle Removal\n<\/h2><p>\n(15 minutes) <i>scraping required<\/i>\n<\/p>\n<p>\n<i>Notes:<\/i>\n<\/p>\n<p>\nA week from <b><i>Thursday <\/i><\/b>would be good......\n<\/p>\n<p>\nmore <b><i>info<\/i><\/b>here\n<\/p>\n<ul>\n<li>\n Action Item: <a href=\"http://kswenson-t902.corp.fc.local/cog/t/ktest/test-for-john/task9364.htm\">asdasd<\/a>\n<\/li>\n<li>\n Action Item: <a href=\"http://kswenson-t902.corp.fc.local/cog/t/ktest/test-for-john/task9985.htm\">Buy Scraping Tools<\/a>\n<\/li>\n<\/ul>\n<h2>3. Review Flag Repari\n<\/h2><p>\n(30 minutes)\n<\/p>\n<p>\n<i>Notes:<\/i>\n<\/p>\n<p>\nthese are the last notes!!!!\n<\/p>\n<ul>\n<li>\n Action Item: <a href=\"http://kswenson-t902.corp.fc.local/cog/t/ktest/test-for-john/task2317.htm\">Flag Review Work<\/a>\n<\/li>\n<\/ul>\n",
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

<link href="<%=ar.retPath%>assets/font-awesome/css/font-awesome.min.css" rel="stylesheet" data-semver="4.3.0"
data-require="font-awesome@*" />

<link href="<%=ar.retPath%>jscript/textAngular.css" rel="stylesheet" />
<script src="<%=ar.retPath%>jscript/textAngular-rangy.min.js"></script>
<script src="<%=ar.retPath%>jscript/textAngular-sanitize.min.js"></script>
<script src="<%=ar.retPath%>jscript/textAngular.min.js"></script>

<style>
    .meeting-icon {
       cursor:pointer;
       color:LightSteelBlue;
    }

</style>

<script type="text/javascript">

var app = angular.module('myApp', ['ui.bootstrap', 'textAngular']);
app.controller('myCtrl', function($scope, $http) {
    $scope.notes = <%notes.write(out,2,4);%>;
    $scope.allLabels = <%allLabels.write(out,2,4);%>;
    $scope.filter = "";
    $scope.showVizPub = true;
    $scope.showVizMem = true;
    $scope.showVizDel = false;
    $scope.filterMap = {};
    $scope.openMap = {};

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
    $scope.sortNotes = function() {
        $scope.notes.sort( function(a,b) {
            return b.modTime - a.modTime;
        });
    }
    $scope.sortNotes();
    $scope.getRows = function() {
        var lcfilter = $scope.filter.toLowerCase();
        var res = [];
        $scope.notes.map( function(aNote) {
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

            if (aNote.subject.toLowerCase().indexOf(lcfilter)>=0) {
                res.push(aNote);
            }
            else if (aNote.html.toLowerCase().indexOf(lcfilter)>=0) {
                res.push(aNote);
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

});

</script>

<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

    <div class="generalHeading" style="height:40px">
        <div  style="float:left;margin-top:8px;">
            Topic List
        </div>
        <div class="rightDivContent" style="margin-right:100px;">
          <span class="dropdown">
            <button class="btn btn-default dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
            Options: <span class="caret"></span></button>
            <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
              <li role="presentation"><a role="menuitem" tabindex="-1" ng-click="showFilter=true"> Show Filter</a>
              </li>
              <li role="presentation"><a role="menuitem" tabindex="-1" href="editNote.htm?public=true"> Create New Topic </a>
              </li>
              <li role="presentation"><a role="menuitem" tabindex="-1" href="sendNote.htm">
                  <img src="<%= ar.retPath%>assets/images/iconEmailNote.gif" width="13" height="15" alt="" /> Send Email</a>
              </li>
              <li role="presentation"><a role="menuitem" href="exportPDF.htm"> Create PDF</a>
              </li>
            </ul>
          </span>
        </div>
    </div>


    <div class="well" ng-show="showFilter">
        <div style="float:right;cursor:pointer;" href="#" ng-click="showFilter=false">x</div>
        Filter <input ng-model="filter"> &nbsp;
        <span style="vertical-align:middle;" ><input type="checkbox" ng-model="showVizPub">
            <img src="<%=ar.retPath%>assets/images/iconPublic.png"> Public</span>
        <span style="vertical-align:middle;" ng-show="<%=isMember%>"><input type="checkbox" ng-model="showVizMem">
            <img src="<%=ar.retPath%>assets/images/iconMember.png"> Member-Only</span>
        <span style="vertical-align:middle;" ng-show="<%=isMember%>"><input type="checkbox" ng-model="showVizDel">
            <img src="<%=ar.retPath%>deletedLink.gif"> Deleted</span>
        <span class="dropdown" ng-repeat="role in allLabelFilters()">
            <button class="btn btn-sm dropdown-toggle labelButton" type="button" id="menu2"
               data-toggle="dropdown" style="background-color:{{role.color}};"
               ng-show="hasLabel(role.name)">{{role.name}} <i class="fa fa-close"></i></button>
            <ul class="dropdown-menu" role="menu" aria-labelledby="menu2">
               <li role="presentation"><a role="menuitem" title="{{add}}"
                  ng-click="toggleLabel(role)">Remove Filter:<br/>{{role.name}}</a></li>
            </ul>
        </span>
        <span>
             <span class="dropdown">
               <button class="btn btn-sm btn-primary dropdown-toggle" type="button" id="menu1" data-toggle="dropdown"
               title="Add Filter by Label"><i class="fa fa-filter"></i></button>
               <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
                 <li role="presentation" ng-repeat="rolex in allLabels">
                     <button role="menuitem" tabindex="-1" href="#"  ng-click="toggleLabel(rolex)" class="btn btn-sm labelButton"
                     ng-hide="hasLabel(rolex.name)" style="background-color:{{rolex.color}};">
                         {{rolex.name}}</button>
                 </li>
               </ul>
             </span>
        </span>
    </div>

    <div style="height:20px;"></div>


        <div ng-repeat="rec in getRows()">
            <div style="border: 1px solid lightgrey;border-radius:10px;margin-top:20px;padding:5px;background-color:#F8EEEE;">
                <div id="headline" >
                  <span class="dropdown">
                    <button class="btn btn-default dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
                    <span class="caret"></span></button>
                    <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
                      <li role="presentation">
                          <a role="menuitem" tabindex="-1" href="noteZoom{{rec.id}}.htm">Full Details</a></li>
                      <li role="presentation">
                          <a role="menuitem" tabindex="-1" href="editNote.htm?nid={{rec.id}}" target="_blank">Edit Topic</a></li>
                      <li role="presentation">
                          <a role="menuitem" tabindex="-1" href="sendNote.htm?noteId={{rec.id}}">Send Email</a></li>
                      <li role="presentation" ng-hide="rec.public">
                          <a role="menuitem" tabindex="-1" ng-click="toggleNoteViz(rec)">Make <img src="<%=ar.retPath%>assets/images/iconPublic.png"> Public</a></li>
                      <li role="presentation" ng-show="rec.public">
                          <a role="menuitem" tabindex="-1" ng-click="toggleNoteViz(rec)">Make <img src="<%=ar.retPath%>assets/images/iconMember.png"> Member Only</a></li>
                      <li role="presentation">
                          <a role="menuitem" tabindex="-1" ng-click="toggleNoteDel(rec)">Delete <img src="<%=ar.retPath%>deletedLink.gif"> Topic</a></li>
                    </ul>
                  </span>
                  <span style="color:#220011;">
                    <span ng-show="rec.deleted"><img src="<%=ar.retPath%>deletedLink.gif"></span>
                    <span ng-show="rec.public"><img src="<%=ar.retPath%>assets/images/iconPublic.png"></span>
                    <span ng-show="!rec.public && !rec.deleted"><img src="<%=ar.retPath%>assets/images/iconMember.png"></span>
                    <a href="noteZoom{{rec.id}}.htm" style="color:black;">
                        <b>{{rec.subject}}</b>
                        ({{rec.modUser.name}})
                        {{rec.modTime|date}}
                    </a>

                    <span ng-repeat="label in getNoteLabels(rec)">
                      <button class="btn btn-sm labelButton" style="background-color:{{label.color}};">
                      {{label.name}}
                      </button>
                    </span>
                  </span>
                  &nbsp;
                  <a class="fa fa-pencil-square-o meeting-icon" href="editNote.htm?nid={{rec.id}}" title="edit this topic"></a>
                  &nbsp;
                  <a class="fa fa-minus-square-o meeting-icon" ng-click="openMap[rec.id]=false" ng-show="openMap[rec.id]"></a>
                  <a class="fa fa-plus-square-o meeting-icon" ng-click="openMap[rec.id]=true" ng-show="!openMap[rec.id]" title="preview this topic"></a>
                </div>
                <div class="leafContent" ng-show="openMap[rec.id]" style="background-color:white;border-radius:10px;margin:5px;">
                    <div ng-bind-html="rec.html"></div>
                </div>
            </div>
        </div>

</div>




