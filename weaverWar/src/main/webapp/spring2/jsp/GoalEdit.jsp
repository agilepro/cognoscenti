<%@page errorPage="/spring2/jsp/error.jsp"
%><%@page import="java.util.Date"
%><%@page import="com.purplehillsbooks.weaver.LicenseForUser"
%><%@page import="com.purplehillsbooks.weaver.AgendaItem"
%><%@ include file="/include.jsp"
%><%
/*
Required parameters:

    1. pageId   : This is the id of an Workspace and here it is used to retrieve NGWorkspace.
    3. taskId   : This parameter is id of a task and here it is used to get current task detail (GoalRecord)
                  and to pass current task id value when submitted.


*/

    //set 'forceTemplateRefresh' in config file to 'true' to get this
    String templateCacheDefeater = "";
    if ("true".equals(ar.getSystemProperty("forceTemplateRefresh"))) {
        templateCacheDefeater = "?t="+System.currentTimeMillis();
    }

    String pageId = ar.reqParam("pageId");
    String siteId = ar.reqParam("siteId");
    NGWorkspace ngp = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngp);
    ar.assertAccessWorkspace("Must be a member to see this task");
    boolean canUpdate = ar.canUpdateWorkspace();

    String taskId = ar.reqParam("taskId");
    GoalRecord currentTaskRecord=ngp.getGoalOrFail(taskId);
    NGBook site = ngp.getSite();

    UserProfile uProf = ar.getUserProfile();

    List<HistoryRecord> histRecs = currentTaskRecord.getTaskHistory(ngp);
    JSONArray allHist = new JSONArray();
    for (HistoryRecord history : histRecs) {
        allHist.put(history.getJSON(ngp, ar));
    }


    JSONObject goalInfo = currentTaskRecord.getJSON4Goal(ngp);
    JSONArray allLabels = ngp.getJSONLabels();

    JSONObject stateName = new JSONObject();
    stateName.put("0", BaseRecord.stateName(0));
    stateName.put("1", BaseRecord.stateName(1));
    stateName.put("2", BaseRecord.stateName(2));
    stateName.put("3", BaseRecord.stateName(3));
    stateName.put("4", BaseRecord.stateName(4));
    stateName.put("5", BaseRecord.stateName(5));
    stateName.put("6", BaseRecord.stateName(6));
    stateName.put("7", BaseRecord.stateName(7));
    stateName.put("8", BaseRecord.stateName(8));
    stateName.put("9", BaseRecord.stateName(9));

    JSONArray subGoals = new JSONArray();
    for (GoalRecord child : currentTaskRecord.getSubGoals()) {
        subGoals.put(child.getJSON4Goal(ngp));
    }

    JSONArray linkedTopics = new JSONArray();
    String goalUniversalId = currentTaskRecord.getUniversalId();
    for (TopicRecord aNote : ngp.getAllDiscussionTopics()) {
        for (String linkedAction : aNote.getActionList()) {
            if (linkedAction.equals(goalUniversalId)) {
                linkedTopics.put(aNote.getJSON(ngp));
            }
        }
    }

    JSONArray linkedMeetings = new JSONArray();
    for (MeetingRecord meet : ngp.getMeetings()) {
        for (AgendaItem ai : meet.getAgendaItems()) {
            for (String actionId : ai.getActionItems()) {
                if (actionId.equals(goalUniversalId)) {
                    linkedMeetings.put(meet.getListableJSON(ar));
                }
            }
        }
    }

    JSONArray attachmentList = ngp.getJSONAttachments(ar);

    LicenseForUser lfu = new LicenseForUser(ar.getUserProfile());
    String docSpaceURL = ar.baseURL +  "api/" + site.getKey() + "/" + ngp.getKey()
                    + "/summary.json?lic="+lfu.getId();

    JSONArray taskAreaList = new JSONArray();
    for (TaskArea ta : ngp.getTaskAreas()) {
        taskAreaList.put(ta.getMinJSON());
    }
    taskAreaList.put(new JSONObject().put("name", "Unspecified"));


/*** PROTOTYPE

    $scope.goalInfo  = {
      "assignTo": [{
        "name": "Alex Demo",
        "uid": "alex@kswenson.oib.com"
      }],
      "description": "test",
      "duedate": 0,
      "duration": 0,
      "enddate": 0,
      "id": "9270",
      "modifiedtime": 0,
      "modifieduser": "",
      "priority": 0,
      "projectKey": "facility-1-wellness-circle",
      "projectname": "Facility 1 Wellness Circle",
      "rank": 40,
      "siteKey": "socio",
      "sitename": "Sociocracy Prototype",
      "startdate": 0,
      "state": 2,
      "status": "",
      "synopsis": "asdfasdfasdf",
      "universalid": "MHYDHNLWG@facility-1-wellness-circle@9270"
    };

*/

%>



<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal, AllPeople) {
    setUpLearningMethods($scope, $modal, $http);
    window.setMainPageTitle("Action Item Details");
    $scope.siteId = "<%ar.writeJS(siteId);%>";
    $scope.siteInfo = <%site.getConfigJSON().write(out,2,4);%>;
    $scope.goalInfo  = <%goalInfo.write(out,2,4);%>;
    $scope.fullDocList = [];
    $scope.allLabels = <%allLabels.write(out,2,4);%>;
    $scope.stateName = <%stateName.write(out,2,4);%>;
    $scope.subGoals  = <%subGoals.write(out,2,4);%>;
    $scope.allHist   = <%allHist.write(out,2,4);%>;
    $scope.linkedTopics = <%linkedTopics.write(out,2,4);%>;
    $scope.linkedMeetings = <%linkedMeetings.write(out,2,4);%>;
    $scope.attachmentList = <%attachmentList.write(out,2,4);%>;
    $scope.taskAreaList = <%taskAreaList.write(out,2,4);%>;
    $scope.docSpaceURL = "<%ar.writeJS(docSpaceURL);%>";
    $scope.canUpdate = <%=canUpdate%>;

    $scope.newPerson = "";
    $scope.selectedPersonShow = false;
    $scope.selectedPerson = "";
    $scope.dropdownStates = {};

    $scope.inviteMsg = "Hello,\n\nYou have been asked by '<%ar.writeHtml(uProf.getName());%>' to"
                    +" participate in an action item of the project '<%ar.writeHtml(ngp.getFullName());%>'."
                    +"\n\nThe links below will make registration quick and easy, and after that you will be able to"
                    +" participate directly with the others through the site.";

    $scope.tagEntry = [];
    $scope.updateTagEntry = function() {
        var newList = [];
        $scope.goalInfo.assignTo.forEach( function(item) {
           var nix = {};
           nix.name = item.name;
           nix.uid  = item.uid;
           nix.key  = item.key;
           newList.push(nix)
        });
        $scope.tagEntry = newList;
    }
    function goalMatchedFilter(rec, lcFilterList) {
        var recentTime = (new Date()).getTime() - 7*24*60*60*1000;
        if ($scope.mineOnly) {
            var found = false;
            rec.assignees.forEach( function(ass) {
                var lcAss = ass.toLowerCase();
                $scope.allEmail.forEach( function(currentUserId) {
                    if (ass == currentUserId) {
                        found = true;
                    }
                });
            });
            if (!found) {
                return false;
            }
        }
        let isRecent = ($scope.showRecent && (rec.modifiedtime > recentTime || rec.startdate > recentTime || rec.enddate > recentTime));
        if (!isRecent && !$scope.showActive && rec.state>=2 && rec.state<=4) {
            return false;
        }
        if (!isRecent && !$scope.showFuture && rec.state==1) {
            return false;
        }
        if (!isRecent && !$scope.showCompleted && rec.state>=5) {
            return false;
        }
        if ($scope.filter.length==0) {
            return true;
        }
        if (containsOne(rec.synopsis.toLowerCase(),lcFilterList)) {
            return true;
        }
        if (containsOne(rec.description.toLowerCase(),lcFilterList)) {
            return true;
        }
        for (var i=rec.assignees.length-1; i>=0; i--) {
            if (containsOne(rec.assignees[i].toLowerCase(),lcFilterList)) {
                return true;
            }
        }
        return false;
    }

    $scope.makeState = function(rec, newState) {
        if (!$scope.canUpdate) {
            alert("Unable to update action item because you are an unpaid user");
            return;
        }
        var newRec = {};
        newRec.id = rec.id;
        newRec.universalid = rec.universalid;
        newRec.state = newState;
        newRec.modifiedtime = new Date().getTime();
        newRec.modifieduser = SLAP.loginInfo.userId;

        var postURL = "updateGoal.json?gid="+rec.id;
        var postdata = angular.toJson(newRec);
        $http.post(postURL, postdata)
        .success( function(data) {
            rec.state = data.state;
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    }
    $scope.updateTagEntry();
    $scope.copyTagsToRecord = function() {
        var newList = [];
        $scope.tagEntry.forEach( function(item) {
            var nix = {};
            if (item.uid) {
                nix.name = item.name;
                nix.uid  = item.uid;
                nix.key  = item.key;
            }
            else {
                nix.name = item.name;
                nix.uid  = item.name;
            }
           newList.push(nix)
        });
        var hasChanged = ($scope.goalInfo.assignTo.length != newList.length);
        $scope.goalInfo.assignTo = newList;
        if (hasChanged) {
            $scope.saveGoal();
        }
    }
    $scope.$watch(function(scope) {
        return $scope.tagEntry.length;
    }, function() {
        $scope.copyTagsToRecord();
    });
    $scope.loadPersonList = function(query) {
        return AllPeople.findMatchingPeople(query, $scope.goalInfo.siteKey);
    }
    $scope.toggleSelectedPerson = function(tag) {
        $scope.selectedPersonShow = !$scope.selectedPersonShow;
        $scope.selectedPerson = tag;
    }

    $scope.editGoalInfo = false;
    $scope.showCreateSubProject = false;

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };
    $scope.setState = function(newState) {
        $scope.goalInfo.state=newState;
        $scope.saveGoal();
    }
    $scope.startEdit = function(startMode) {
        $scope.openModalActionItem(startMode);
    }
    $scope.constructCheckItems = function() {
        var list = [];
        if ($scope.goalInfo.checklist) {
            var lines = $scope.goalInfo.checklist.split("\n");
            var idx = 0;
            lines.forEach( function(item) {
                item = item.trim();
                if (item && item.length>0) {
                    if (item.indexOf("x ")==0) {
                        list.push( {name: item.substring(2), checked:true, index: idx} );
                        idx++;
                    }
                    else {
                        list.push( {name: item, checked:false, index: idx} );
                        idx++;
                    }
                }
            });
        }
        $scope.checkitems = list;
    }
    $scope.toggleCheckItem = function(changeIndex) {
        if (!$scope.canUpdate) {
            alert("Unable to update meeting because you are an unpaid user");
            return;
        }
        $scope.checkitems.forEach( function(item) {
            if (item.index==changeIndex) {
                item.checked = !item.checked;
            }
        });
        var newList = [];
        $scope.checkitems.forEach( function(item) {
            if (item.checked) {
                newList.push("x " + item.name);
            }
            else {
                newList.push(item.name);
            }
        });
        $scope.goalInfo.checklist = newList.join("\n");
        $scope.saveGoal();
    }
    $scope.constructCheckItems();
    $scope.saveGoal = function() {
        if (!$scope.canUpdate) {
            alert("Unable to update meeting because you are an unpaid user");
            return;
        }
        var postURL = "updateGoal.json?gid="+$scope.goalInfo.id;
        var postdata = angular.toJson($scope.goalInfo);
        $scope.showError=false;
        $scope.editGoalInfo=false;
        $http.post(postURL, postdata)
        .success( function(data) {
            setGoalData(data);
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };
    $scope.refreshActionItem = function() {
        var postURL = "fetchGoal.json?gid="+$scope.goalInfo.id;
        $scope.showError=false;
        $scope.editGoalInfo=false;
        $http.get(postURL)
        .success( function(data) {
            setGoalData(data);
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };
    function setGoalData(newGoal) {
        let tempList = [];
        newGoal.docLinks.forEach( function(docid) {
            tempList.push($scope.getFullDoc(docid));
        });
        $scope.fullDocList = tempList;
        $scope.goalInfo = newGoal;
        $scope.constructCheckItems();
        $scope.refreshHistory();
    }


    $scope.saveAccomplishment = function() {
        if (!$scope.canUpdate) {
            alert("Unable to update meeting because you are an unpaid user");
            return;
        }
        $scope.goalInfo.newAccomplishment = $scope.newAccomplishment;
        $scope.saveGoal();
    }
    $scope.addPerson = function() {
        if (!$scope.canUpdate) {
            alert("Unable to update meeting because you are an unpaid user");
            return;
        }
        var player = $scope.newPerson;
        if (typeof player == "string") {
            var pos = player.lastIndexOf(" ");
            var name = player.substring(0,pos).trim();
            var uid = player.substring(pos).trim();
            player = {name: name, uid: uid};
        }
        $scope.goalInfo.assignTo.push(player);
        $scope.saveGoal();
    }
    $scope.updatePlayers = function() {
        $scope.tagEntry = cleanUserList($scope.tagEntry);
    }
    $scope.removePerson = function(person) {
        if (!$scope.canUpdate) {
            alert("Unable to update meeting because you are an unpaid user");
            return;
        }
        var res = $scope.goalInfo.assignTo.filter( function(one) {
            return (person.uid != one.uid);
        });
        $scope.goalInfo.assignTo = res;
        $scope.saveGoal();
    }
    $scope.visitPlayer = function(player) {
        window.location = "<%=ar.retPath%>v/"+encodeURIComponent(player.key)+"/PersonShow.htm";
    }
    $scope.bestName = function(person) {
        if (person.name) {
            return person.name;
        }
        return person.uid;
    }
    $scope.refreshHistory = function() {
        var postURL = "getGoalHistory.json?gid="+$scope.goalInfo.id;
        $scope.showError=false;
        $http.get(postURL)
        .success( function(data) {
            $scope.allHist = data;
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    }
    $scope.changeRYG = function(newRAG) {
        if (!$scope.canUpdate) {
            alert("Unable to update meeting because you are an unpaid user");
            return;
        }
        $scope.goalInfo.prospects = newRAG;
        $scope.saveGoal();
        $scope.refreshHistory();
    }

    $scope.onTimeSet = function (newDate, param) {
        $scope.goalInfo[param] = newDate.getTime();
    }

    $scope.hasLabel = function(searchName) {
        return $scope.goalInfo.labelMap[searchName];
    }
    $scope.toggleLabel = function(label) {
        $scope.goalInfo.labelMap[label.name] = !$scope.goalInfo.labelMap[label.name];
    }
    $scope.getGoalLabels = function(goal) {
        var res = [];
        $scope.allLabels.map( function(val) {
            if (goal.labelMap[val.name]) {
                res.push(val);
            }
        });
        return res;
    }
    $scope.getTaskArea = function() {
                console.log("$scope.taskAreaList", $scope.taskAreaList);
        for (val of $scope.taskAreaList) {
                console.log("Trying", val);
            if ($scope.goalInfo.taskArea === val.id) {
                console.log("FOUND", val);
                return val.name;
            }
        }
        return "unknown";
    }
    $scope.navigateToTopic = function(oneTopic) {
        window.location="noteZoom"+encodeURIComponent(oneTopic.id)+".htm";
    }
    $scope.navigateToMeeting = function(meet) {
        window.location="MeetingHtml.htm?id="+encodeURIComponent(meet.id);
    }
    $scope.navigateToUser = function(player) {
        window.location="<%=ar.retPath%>v/"+encodeURIComponent(player.key)+"/PersonShow.htm";
    }

    $scope.itemHasDoc = function(doc) {
        var res = false;
        var found = $scope.goalInfo.docLinks.forEach( function(docid) {
            if (docid == doc.universalid) {
                res = true;
            }
        });
        return res;
    }

    $scope.getDocs = function() {
        return $scope.attachmentList.filter( function(oneDoc) {
            return $scope.itemHasDoc(oneDoc);
        });
    }

    $scope.getFullDoc = function(docId) {
        var doc = {};
        $scope.attachmentList.filter( function(item) {
            if (item.universalid == docId) {
                doc = item;
            }
        });
        return doc;
    }
    $scope.navigateToDoc = function(doc) {
        window.location="DocDetail.htm?aid="+doc.id;
    }
    $scope.sendDocByEmail = function(doc) {
        window.location="SendNote.htm?att="+doc.id;
    }
    $scope.downloadDocument = function(doc) {
        window.location="a/"+doc.name;
    }
    $scope.unattachDocFromItem = function(docId) {
        if (!$scope.canUpdate) {
            alert("Unable to update meeting because you are an unpaid user");
            return;
        }
        var newList = [];
        $scope.goalInfo.docLinks.forEach( function(iii) {
            if (iii != docId) {
                newList.push(iii);
            }
        });
        $scope.goalInfo.docLinks = newList;
        $scope.saveGoal(['docLinks']);
    }
    $scope.openAttachDocument = function () {
        if (!$scope.canUpdate) {
            alert("Unable to update meeting because you are an unpaid user");
            return;
        }

        var attachModalInstance = $modal.open({
            animation: true,
            templateUrl: '<%=ar.retPath%>new_assets/templates/AttachDocument.html<%=templateCacheDefeater%>',
            controller: 'AttachDocumentCtrl',
            size: 'lg',
            resolve: {
                containingQueryParams: function() {
                    return "goal="+$scope.goalInfo.id;
                },
                docSpaceURL: function() {
                    return $scope.docSpaceURL;
                }
            }
        });

        attachModalInstance.result
        .then(function (docList) {
            $scope.goalInfo.docLinks = docList;
            $scope.saveGoal(['docLinks']);
        }, function () {
            $scope.refreshActionItem();
        });
    };

    $scope.openInviteSender = function (player) {
        if (!$scope.canUpdate) {
            alert("Unable to update meeting because you are an unpaid user");
            return;
        }

        var modalInstance = $modal.open({
            animation: true,
            templateUrl: '<%=ar.retPath%>new_assets/templates/InviteModal.html<%=templateCacheDefeater%>',
            controller: 'InviteModalCtrl',
            size: 'lg',
            backdrop: "static",
            resolve: {
                email: function () {
                    return player.uid;
                },
                msg: function() {
                    return $scope.inviteMsg;
                }
            }
        });

        modalInstance.result.then(function (message) {
            $scope.inviteMsg = message.msg;
            message.userId = player.uid;
            message.name = player.name;
            message.return = "<%=ar.baseURL%><%=ar.getResourceURL(ngp, "FrontPage.htm")%>";
            $scope.sendEmailLoginRequest(message);
        }, function () {
            $scope.refreshActionItem();
        });
    };


    $scope.openModalActionItem = function (startMode) {
        if (!$scope.canUpdate) {
            alert("Unable to update meeting because you are an unpaid user");
            return;
        }

        var modalInstance = $modal.open({
          animation: true,
          templateUrl: '<%=ar.retPath%>new_assets/templates/ActionItem.html<%=templateCacheDefeater%>',
          controller: 'ActionItemCtrl',
          size: 'xl',
          backdrop: "static",
          resolve: {
            goal: function () {
              return $scope.goalInfo;
            },
            taskAreaList: function () {
              return $scope.taskAreaList;
            },
            allLabels: function () {
              return $scope.allLabels;
            },
            startMode: function () {
              return startMode;
            },
            siteInfo: function () {
              return $scope.siteInfo;
            }
          }
        });

        modalInstance.result.then(function (modifiedGoal) {
            $scope.goalInfo = modifiedGoal;
            $scope.constructCheckItems();
        }, function () {
            $scope.refreshActionItem();
        });
    };
    $scope.refreshActionItem();

});

function addvalue() {
    if(flag==false){
        document.getElementById("projectname").value=projectNameTitle;
    }
}
    $scope.getContrastColor = function (color) {

        const tempEl = document.createElement("div");
        tempEl.style.color = color;
        document.body.appendChild(tempEl);
        const computedColor = window.getComputedStyle(tempEl).color;
        document.body.removeChild(tempEl);

        const match = computedColor.match(/\d+/g);

        if (!match) {
            console.error("Failed to parse color: ", computedColor);
            return "#39134C";
        }
        const [r, g, b] = match.map(Number);

        var yiq = ((r * 299) + (g * 587) + (b * 114)) / 1000;

        return (yiq >= 128) ? '#39134C' : '#ebe7ed';
    };

</script>

<script src="../../../jscript/AllPeople.js"></script>

<div class="container-fluid override mb-4 mx-3 d-inline-flex">
    <span class="dropdown mt-1">
        <button class="btn btn-outline-secondary btn-tiny dropdown-toggle" type="button" id="dropdownInfoMenu"
            data-bs-toggle="dropdown" aria-expanded="false">
        </button>
        <ul class="dropdown-menu" aria-labelledby="dropdownInfoMenu">
            <li>
                <button class="dropdown-item" onclick="window.location.reload(true)">
                    Refresh</button>
                <span class="dropdown-item" type="button">
                    <a class="nav-link" role="menuitem" tabindex="-1"
                        href="GoalList.htm">
                        List Action Items</a></span>
                <span class="dropdown-item" type="button">
                    <a class="nav-link" role="menuitem" tabindex="-1"
                        ng-click="startEdit('details')">
                        Edit Details</a>
                </span>
            </li>
        </ul>
    </span>
    <span>
        <h1 class="d-inline page-name" id="mainPageTitle">Action Item - Details</h1>
    </span>
</div>
<div ng-cloak>

<%@include file="ErrorPanel.jsp"%>

        <div class="container-fluid col-12 override m-3"><!-- ng-hide="editGoalInfo">-->

                <!--State and Title start-->
                <div class="row d-flex my-2" ng-dblclick="startEdit('assignee')">
                    <span class="col-auto"
                          title="This action item is in {{stateName[goalInfo.state]}} state">
                        <span style="padding:10px;">
                            <button class="no-btn" id="changeStatus" ng-click="dropdownStates['status'] = !dropdownStates['status']"
                            aria-expanded="{{dropdownStates['status']}}"><img ng-src="<%=ar.retPath%>new_assets/assets/goalstate/large{{goalInfo.state}}.gif"/></button>
                            <ul class="dropdown-menu" ng-class="{'show': dropdownStates['status']}" role="menu"
                            aria-labelledby="changeState">
                                <li class="nav-item dropdown btn btn-wide py-0 px-2" role="presentation">
                                    <a class="dropdown-item" role="menuitem" tabindex="-1" href="#" ng-click="setState(1); dropdownStates['status'] = false">Mark <img src="<%=ar.retPath%>new_assets/assets/goalstate/small1.gif"> Unstarted
                                    </a>
                                </li>
                                <li class="nav-item dropdown btn btn-wide py-0 px-2" role="presentation">
                                    <a class="dropdown-item" role="menuitem" tabindex="-1" href="#" ng-click="setState(2);dropdownStates['status'] = false">Mark <img src="<%=ar.retPath%>new_assets/assets/goalstate/small2.gif"> Offered
                                    </a>
                                </li>
                                <li class="nav-item dropdown btn btn-wide py-0 px-2" role="presentation">
                                    <a class="dropdown-item" role="menuitem" tabindex="-1" href="#" ng-click="setState(3);dropdownStates['status'] = false">Mark <img src="<%=ar.retPath%>new_assets/assets/goalstate/small3.gif"> Accepted
                                    </a>
                                </li>
                                <li class="nav-item dropdown btn btn-wide py-0 px-2" role="presentation">
                                    <a class="dropdown-item" role="menuitem" tabindex="-1" href="#" ng-click="setState(5);dropdownStates['status'] = false">Mark <img src="<%=ar.retPath%>new_assets/assets/goalstate/small5.gif"> Completed
                                    </a>
                                </li>
                                <li class="nav-item dropdown btn btn-wide py-0 px-2" role="presentation">
                                    <a class="dropdown-item" role="menuitem" tabindex="-1" href="#" ng-click="setState(6);dropdownStates['status'] = false">Mark <img src="<%=ar.retPath%>new_assets/assets/goalstate/small6.gif"> Skipped
                                    </a>
                                </li>
                            </ul>
                        </span>
                    </span>
                    <span class="col-10 h4"
                        title="This is the synopsis of the action item"><span style="color:#755d82;">
                        {{stateName[goalInfo.state]}} </span>&nbsp;<i class="fa fa-caret-right"></i> &nbsp;&nbsp;{{goalInfo.synopsis}}
                    </span>
                </div>

                <!--State and Title end-->

                <!--State Start-->
            <div class="row d-flex my-2 py-2 border-bottom border-1">

                    <span class="col-5 ">
                        <button class="btn-wide btn-comment btn-raised mx-1" ng-click="setState(2)" ng-show="goalInfo.state<2">Mark <img src="<%=ar.retPath%>new_assets/assets/goalstate/small2.gif"> Offered</button>
                        <button class=" btn-wide btn-comment btn-raised mx-1" ng-click="setState(3)" ng-show="goalInfo.state<3">Mark <img src="<%=ar.retPath%>new_assets/assets/goalstate/small3.gif"> Accepted</button>
                        <button class=" btn-wide btn-comment btn-raised mx-1" ng-click="setState(5)" ng-show="goalInfo.state<5">Mark <img src="<%=ar.retPath%>new_assets/assets/goalstate/small5.gif"> Completed</button>
                    </span>
                    <span class="col-5 p-1">
                        <span class="h5">Task Area:</span>
                        <span class="h5"><b>{{getTaskArea()}}</b></span>
                    </span>
                                </div>
            <!--State End-->
                <!--Assigned To Start-->
                <div class="row d-flex my-2 py-2 border-bottom border-1" title="The action item can be assigned to any number of people who will receive reminders until it is completed." >
                    <span class="col-auto clickable h6 mx-2 pt-1" ng-click="startEdit('assignee')" >Assigned To:

                    </span>
                    <span class="col-9 d-flex">
                        <div class="mx-2" ng-repeat="player in goalInfo.assignTo" >
                            <button class="no-btn" ng-click="dropdownStates[player.uid] = !dropdownStates[player.uid]"
                                aria-expanded="{{dropdownStates[player.uid]}}">
                                <img
                                class="rounded-5"
                                ng-src="<%=ar.retPath%>icon/{{player.key}}.jpg" style="width:32px;height:32px"
                                title="{{player.name}} - {{player.uid}}"/>
                                </button>
                                <ul class="dropdown-menu list-inline"
                                ng-class="{'show': dropdownStates[player.uid]}"
                                role="menu" aria-labelledby="user">
                                    <li role="presentation" style="background-color:lightgrey">
                                        <a
                                        class="dropdown-item"
                                        role="menuitem"
                                        tabindex="-1"
                                        ng-click=""
                                        style="text-decoration: none;">{{player.name}}<br/>{{player.uid}}
                                                </a>
                                            </li>
                                            <li role="presentation" style="cursor:pointer">
                                                <a
                                                class="dropdown-item" role="menuitem" tabindex="-1"
                                                ng-click="navigateToUser(player)">
                                                    <span class="fa fa-user"></span>
                                                    Visit Profile
                                                </a>
                                            </li>
                                </ul>
                        </div>
                    </span>
                </div>
                    <!--Assigned To End-->
                    <!--Description Start-->
                    <div class="row d-flex my-2 py-2 border-bottom border-1" title="Click here to update the description of this action item" >
                        <span class="col-auto clickable h6 mx-2 pt-1" ng-click="startEdit('details')" >Description:</span>
                        <span class="col-9 d-flex"><div ng-bind-html="goalInfo.description|wiki"></div></span>
                    </div>
                    <!--Description End-->
                    <!--checklist Start-->
                <div class="row d-flex my-2 py-2 border-bottom border-1"
                title="Manage the check list of items to do for this action">
                    <span class="col-auto clickable h6 mx-2 pt-1" ng-click="startEdit('status')" >Checklist:</span>
                    <span class="col-9">

                        <div ng-repeat="ci in checkitems" ng-click="toggleCheckItem(ci.index)">
                            <span ng-show="ci.checked"><i class="fa  fa-check-square-o"></i></span>
                            <span ng-hide="ci.checked"><i class="fa  fa-square-o"></i></span>
                        &nbsp; {{ci.name}}
                        </div>
                        <span ng-hide="checkitems.length>0" class="instruction" ng-click="startEdit('status')"><em>
                        Click here to create a checklist</em></span>
                    </span>
                </div>
                    <!--checklist End-->

                    <!--status Start-->
                <div class="row d-flex my-2 py-2 border-bottom border-1">
                    <div class="form-group" title="status is a freeform text statement about your current progress on action item">
                        <label for="synopsis" class="clickable h6 col-auto mx-2" ng-click="startEdit()">Status:</label>

                    <!--R-Y-G Start-->


                        <span class="col-2 h6" title="Red-Yellow-Green is a high-level status saying how things are going generally">
                                <img src="<%=ar.retPath%>assets/goalstate/red_off.png" ng-hide="goalInfo.prospects=='bad'" title="In trouble" ng-click="changeRYG('bad')">
                                <img src="<%=ar.retPath%>assets/goalstate/red_on.png"  ng-show="goalInfo.prospects=='bad'" title="In trouble">
                                <img src="<%=ar.retPath%>assets/goalstate/yellow_off.png" ng-hide="goalInfo.prospects=='ok'" title="Warning" ng-click="changeRYG('ok')">
                                <img src="<%=ar.retPath%>assets/goalstate/yellow_on.png"  ng-show="goalInfo.prospects=='ok'" title="Warning">
                                <img src="<%=ar.retPath%>assets/goalstate/green_off.png" ng-hide="goalInfo.prospects=='good'" title="Good shape" ng-click="changeRYG('good')">
                                <img src="<%=ar.retPath%>assets/goalstate/green_on.png"  ng-show="goalInfo.prospects=='good'" title="Good shape">
                            </span>

                    <!--R-Y-G End-->

                        <!--<textarea ng-hide="goalInfo.status" ng-model="goal.status" class="form-control"  placeholder="Enter text describing the current status" ></textarea>  -->
                        <span ng-click="startEdit('status')" ><i class="clickable" placeholder="Enter text describing the current status"></i></span>
                        <span class="col-9 mx-2" ng-show="goalInfo.status" >{{goalInfo.status}}
                        </span>
                    </div>
                </div>
                    <!--status End-->
                    <!--Timeframe Start-->
            <div class="well m-2">
                <div class="row d-flex">

                    <span class="col-auto clickable h5" ng-click="startEdit('details')" >
                        <b>Timeframe:</b></span>
                        <span class="d-flex clickable" ng-show="goalInfo.duedate>0 || goalInfo.startdate>0 || goalInfo.enddate>0" title="Click here to update the dates of this action item" ng-click="startEdit('details')">
                            <span class="col-auto h6 mx-3" ng-show="goalInfo.duedate>0">
                                Due:   </span>
                            <span class="col-2" ng-show="goalInfo.duedate>0">{{goalInfo.duedate|cdate}}  </span>
                            <span class="col-auto h6 mx-3" ng-show="goalInfo.startdate>0" ng-click="startEdit('details')">
                            Start:</span>
                            <span class="col-2" ng-show="goalInfo.startdate>0">
                            {{goalInfo.startdate|cdate}}</span>

                            <span class="col-auto h6 mx-3" ng-show="goalInfo.enddate>0" ng-click="startEdit('details')">End:</span>

                            <span class="col-2" ng-show="goalInfo.enddate>0">
                            {{goalInfo.enddate|cdate}}  </span>
                        </span>
                    </div>
            </div>
            <!--Timeframe End-->
                    <!--Labels Start-->
                <div class="row d-flex my-2 py-2 border-bottom border-3">
                    <span class="col-auto clickable h6 mx-2 pt-1" ng-click="startEdit()" style="cursor: pointer;">Labels:</span>
                    <!--<span class="nav-item dropdown d-inline">

                      <button class="specCaretBtn dropdown">
                        <i class="fa fa-plus"></i></button>
                          <ul class="dropdown-menu mb-0 p-2" role="menu" aria-labelledby="selectLabel"
                        style="width:320px;left:-130px;top:15px">
                          <li role="presentation" ng-repeat="rolex in allLabels" style="float:left">
                          <button role="menuitem" tabindex="0" ng-click="toggleLabel(rolex)" class="labelButton"
                          ng-hide="hasLabel(rolex.name)" style="background-color:{{rolex.color}}">
                              {{rolex.name}}</button>
                      </li>
                      <div class="dropdown-divider" style="float:clear"></div>
                      <li role="presentation" style="float:right">
                        <button role="menuitem" ng-click="openEditLabelsModal()" class="labelButtonAdd btn-comment h6 ">
                            Add/Remove Labels</button>
                      </li>
                    </ul>
                  </span>-->
                    <span class="col-auto ">
                        <span class="dropdown m-0 p-0" ng-repeat="role in allLabels">
                            <button class="btn btn-wide" ng-click="toggleLabel(role)" style="background-color:{{role.color}};" ng-show="hasLabel(role.name)" ng-style="{ color: getContrastColor(role.color) }">{{role.name}} <i class="fa fa-close"></i></button>
                        </span>
                    </span>

                  </div>
                <!--Labels End-->

                    <!--Attachments Start-->
                <div class="row col-12 d-flex my-2 py-2 border-bottom border-1" >
                    <span class="col-auto clickable h6 mx-2 pt-1" ng-click="openAttachDocument()">Attachments:</span>
                    <span class="col-9 py-0 my-0" ng-click="openAttachDocument()">
                <div ng-repeat="doc in fullDocList" style="vertical-align: top">
                  <span ng-show="doc.attType=='FILE'">
                      <span ng-click="navigateToDoc(doc)"><img src="<%=ar.retPath%>assets/images/iconFile.png"></span>
                      &nbsp;
                      <span ng-click="downloadDocument(doc)"><span class="fa fa-download"></span></span>
                  </span>
                  <span  ng-show="doc.attType=='URL'">
                      <span ng-click="navigateToDoc(doc)"><img src="<%=ar.retPath%>assets/images/iconUrl.png"></span>
                      &nbsp;
                      <span ng-click="navigateToLink(doc)"><span class="fa fa-external-link"></span></span>
                  </span>
                  &nbsp;
                  <span ng-click="sendDocByEmail(doc)"><span class="fa fa-envelope-o"></span></span>&nbsp;
                  &nbsp; {{doc.name}}
                </div>
                <div ng-hide="fullDocList && fullDocList.length>0" class="clickable doubleClickHint">
                    Click to add / remove attachments
                </div>
            </span>
        </div>

                    <!--Attachments End-->

<!--Linked Topics Start-->
        <div class="row col-12 d-flex my-2 py-2 border-bottom border-1" >
            <span class="col-auto clickable h6 mx-2 pt-1" title="On the discussion page, you can link action items, and those discussions will appear here">Linked Topics:</span>
            <span class="col-9 py-0 my-0" title="On the discussion page, you can link action items, and those discussions will appear here">
                <span ng-repeat="topic in linkedTopics" class="btn btn-comment btn-raised"  style="margin:4px;"
                    ng-click="navigateToTopic(topic)">
                    <i class="fa fa-lightbulb-o" style="font-size:130%"></i> {{topic.subject}}
                </span>
                <span ng-show="!linkedTopics || linkedTopics.length==0">
                    <i>No discussions have links to this action item.</i>
                </span>
            </span>
        </div>
<!--Linked Topics End-->
<!--Linked Meetings Start-->
<div class="row col-12 d-flex my-2 py-2 border-bottom border-1" >
    <span class="col-auto clickable h6 mx-2 pt-1" title="On the meeting page, you can link action items, and those meetings will appear here">
                Linked Meetings:</span>
            <span class="col-auto" title="On the meeting page, you can link action items, and those meetings will appear here">
                <span ng-repeat="meet in linkedMeetings" class="btn btn-outline-secondary btn-raised py-1"  style="margin:4px;"
                    ng-click="navigateToMeeting(meet)">
                    <i class="fa fa-gavel" style="font-size:130%"></i> {{meet.name}}
                </span>
                <span ng-show="!linkedMeetings || linkedMeetings.length==0" style="color:lightgray">
                    No meetings have links to this action item.
                </span>
            </span>
        </div>
<!--Linked Meetings End-->

<!--

    <div class="container-fluid col-12 ">
        <div class="row col-12 m-2" ng-show="subGoals.length>0">
            <span class="col-2 h6" >Sub Action Items:</span>
            <span class="col-10" >
                <div ng-repeat="sub in subGoals">
                    <a href="task{{sub.id}}.htm">
                        <img ng-src="<%=ar.retPath%>assets/goalstate/small{{sub.state}}.gif">
                        {{sub.synopsis}} ~ {{sub.description}}
                    </a>
                </div>
            </span>
        </div>
    </div>-->
</div>

<script>
function updateVal(){
  flag=true;
}
</script>


        <!-- ========================================================================= -->
        <div class="container-fluid col-12 m-2" >
            <div class="mx-3 h5 my-3">History &amp; Accomplishments
        </div>
                    <div class="row col-12 ms-5 my-2 py-2" ng-repeat="rec in allHist">
                        <span class="col-1 projectStreamIcons" >
                            <img class="rounded-5" src="<%=ar.retPath%>icon/{{rec.responsible.key}}.jpg"
                                 alt="" width="50" height="50" /></span>
                        <span class="col-10 projectStreamText">
                            {{rec.time|cdate}} -
                            <a href="<%=ar.retPath%>v/{{rec.responsible.key}}/UserSettings.htm" title="access the profile of this user, if one exists">
                             <span class="red">{{rec.responsible.name}}</span>
                            </a>
                            <br/>
                            {{rec.ctxType}} -
                            <a href="">{{rec.ctxName}}</a> was {{rec.event}} - {{rec.comment}}
                            <br/>

                        </span>
                    </div>
                </div>




    <script type="text/javascript">

        var isfreezed = '<%=ngp.isFrozen()%>';
        var flag=false;
        var emailflag=false;
        var taskNameRequired = 'Action item name is required.';
        var taskName = 'Enter an action item name';
        var emailadd='Enter email address'
        var goToUrl  ='<%=ar.getRequestURL()%>'+'?taskId='+<%=taskId%>;

        function createProject(){
        <%if (!ngp.isFrozen()) {%>
            document.forms["projectform"].submit();
        <%}else{%>
            return openFreezeMessagePopup();
        <%}%>
        }

        var callbackprocess = {
           success: function(o) {
               var respText = o.responseText;
               var json = eval('(' + respText+')');
               if(json.msgType != "success"){
                   showErrorMessage("Result", json.msg , json.comments );
              }
           },
           failure: function(o) {
                   alert("callbackprocess Error:" +o.responseText);
           }
        }

    function updateAssigneeVal(){
        emailflag=true;
    }


    function createSubTask(){
        if(isfreezed == 'false'){
            var taskname =  document.getElementById("taskname");
            var assignto =  document.getElementById("assignto_SubTask");

            if(taskname.value=='' || taskname.value==null){
                alert(taskNameRequired);
                    return false;
            }

            if(assignto.value==emailadd){
                document.getElementById("assignto_SubTask").value="";
            }
            document.forms["createSubTaskForm"].elements["assignto"].value = assignto.value;
            document.forms["createSubTaskForm"].submit();
        }else{
            return openFreezeMessagePopup();
        }
    }

    function updateTaskVal(){
        flagSubTask=true;
    }

    function clearField(elementName) {
        var task=document.getElementById(elementName).value;
        if(task==taskName){
            document.getElementById(elementName).value="";
            document.getElementById(elementName).style.color="black";
        }
    }

    function defaultTaskValue(elementName) {
        var task=document.getElementById(elementName).value;
        if(task==""){
            flag=false;
            document.getElementById(elementName).value=taskName;
            document.getElementById(elementName).style.color = "gray";
        }
    }

</script>


</div>

<script src="<%=ar.retPath%>new_assets/templates/ActionItemCtrl.js"></script>
<script src="<%=ar.retPath%>new_assets/templates/AttachDocumentCtrl.js"></script>
<script src="<%=ar.retPath%>new_assets/templates/InviteModal.js"></script>
<script src="<%=ar.baseURL%>new_assets/templates/EditLabelsCtrl.js"></script>


