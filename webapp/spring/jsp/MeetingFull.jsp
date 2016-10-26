<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="org.socialbiz.cog.MeetingRecord"
%><%@page import="org.socialbiz.cog.LicenseForUser"
%><%@page import="org.socialbiz.cog.AccessControl"
%><%@page import="org.socialbiz.cog.MicroProfileMgr"
%><%

    String pageId      = ar.reqParam("pageId");
    NGWorkspace ngw = ar.getCogInstance().getWorkspaceByKeyOrFail(pageId);
    ar.setPageAccessLevels(ngw);
    String meetId          = ar.reqParam("id");
    MeetingRecord mRec     = ngw.findMeeting(meetId);

    //comment or uncomment depending on whether you are in development testing mode
    //String templateCacheDefeater = "";
    String templateCacheDefeater = "?t="+System.currentTimeMillis();


    if (!AccessControl.canAccessMeeting(ar, ngw, mRec)) {
        throw new Exception("Please log in to see this meeting.");
    }

    NGBook ngb = ngw.getSite();
    UserProfile uProf = ar.getUserProfile();
    boolean isLoggedIn = (uProf!=null);
    String currentUser = "";
    String currentUserName = "Unknown";
    String currentUserKey = "";
    if (isLoggedIn) {
        currentUser = uProf.getUniversalId();
        currentUserName = uProf.getName();
        currentUserKey = uProf.getKey();
    }

    String targetRole = mRec.getTargetRole();
    if (targetRole==null || targetRole.length()==0) {
        mRec.setTargetRole(ngw.getPrimaryRole().getName());
    }
    JSONObject meetingInfo = mRec.getFullJSON(ar, ngw);
    JSONArray attachmentList = new JSONArray();
    for (AttachmentRecord doc : ngw.getAllAttachments()) {
        if (doc.isDeleted()) {
            continue;
        }
        attachmentList.put(doc.getJSON4Doc(ar, ngw));
    }

    JSONArray allGoals     = ngw.getJSONGoals();

    JSONArray allRoles = new JSONArray();
    for (NGRole aRole : ngw.getAllRoles()) {
        allRoles.put(aRole.getName());
    }

    JSONArray allTopics = new JSONArray();
    for (TopicRecord aNote : ngw.getAllNotes()) {
        allTopics.put(aNote.getJSON(ngw));
    }

    JSONArray allLabels = ngw.getJSONLabels();

    String docSpaceURL = "";

    if (uProf!=null) {
        LicenseForUser lfu = new LicenseForUser(ar.getUserProfile());
        docSpaceURL = ar.baseURL +  "api/" + ngb.getKey() + "/" + ngw.getKey()
                    + "/summary.json?lic="+lfu.getId();
    }

    MeetingRecord backlog = ngw.getAgendaItemBacklog();

/* PROTOTYPE

    $scope.meeting = {
      "agenda": [
        {
          "actionItems": [
            "BKLQHEHWG@clone-c-of-clone-4@8005",
            "HFCKCQHWG@clone-c-of-clone-4@0353"
          ],
          "desc": "An autocracy vests power in one autocratic.",
          "docList": [
            "VKSSSCSRG@sec-inline-xbrl@4841",
            "HGYDQWIWG@clone-c-of-clone-4@9358"
          ],
          "duration": 14,
          "id": "1695",
          "notes": "Randy says he is interested organization.",
          "position": 1,
          "subject": "Approve Advertising Plan"
        },
        {
          "actionItems": [],
          "desc": "Many new organizational support.",
          "docList": [],
          "duration": 5,
          "id": "2695",
          "notes": "",
          "position": 2,
          "subject": "Location of New Offices"
        },
        {
          "actionItems": ["XQCTXVJWG@clone-c-of-clone-4@0938"],
          "desc": "do you like electric or gasoline?",
          "docList": [],
          "duration": 5,
          "id": "3695",
          "notes": "",
          "position": 3,
          "subject": "Discuss New Car Model"
        },
        {
          "actionItems": [],
          "desc": "A sociocratic in the future.",
          "docList": [],
          "duration": 5,
          "id": "0675",
          "notes": "",
          "position": 4,
          "subject": "Discuss Budget"
        }
      ],
      "duration": 60,
      "id": "0695",
      "meetingInfo": "Please join us in Austin, Texas 78701",
      "name": "Status Meeting",
      "startTime": 1434137400000,
      "state": 1
    };



    $scope.attachmentList = [
      {
        "attType": "FILE",
        "deleted": false,
        "description": "Original Contract from the SEC to Fujitsu",
        "id": "1002",
        "labelMap": {},
        "modifiedtime": 1391185776500,
        "modifieduser": "cparker@us.fujitsu.com",
        "name": "Contract 13-C-0113-Fujitsu.pdf",
        "public": false,
        "size": 409333,
        "universalid": "CSWSLRBRG@sec-inline-xbrl@0056",
        "upstream": true
      },

*/


%>

<style>
.meeting-icon {
   cursor:pointer;
   color:LightSteelBlue;
}

.comment-outer {
    border: 1px solid lightgrey;
    border-radius:8px;
    padding:5px;
    margin-top:15px;
    background-color:#EEE;
    cursor: pointer;
}
.comment-inner {
    border: 1px solid lightgrey;
    border-radius:6px;
    padding:5px;
    background-color:white;
}
.comment-state-draft {
    background-color:yellow;
}
.comment-state-active {
    background-color:#DEF;
}
comment-state-complete {
    background-color:#EEE;
}
</style>

<script>

var app = angular.module('myApp', ['ui.bootstrap', 'ui.tinymce', 'ngSanitize','ngTagsInput']);
app.controller('myCtrl', function($scope, $http, $modal, AllPeople) {
    $scope.pageId = "<%ar.writeJS(pageId);%>";
    $scope.meetId = "<%ar.writeJS(meetId);%>";
    $scope.meeting = <%meetingInfo.write(out,2,4);%>;
    $scope.allGoals = <%allGoals.write(out,2,4);%>;
    $scope.attachmentList = [];
    $scope.allRoles = <%allRoles.write(out,2,4);%>;
    $scope.allLabels = <%allLabels.write(out,2,4);%>;
    $scope.allTopics = [];
    $scope.backlogId = "<%=backlog.getId()%>";



    $scope.newAssignee = "";
    $scope.newAttendee = "";
    $scope.newGoal = {};
    $scope.newPerson = "";
    $scope.myUserId = "<% ar.writeJS(ar.getBestUserId()); %>";
    $scope.actionItemFilter = "";
    $scope.realDocumentFilter = "";

    $scope.isRegistered = function() {
        var registered = false;
        $scope.meeting.rollCall.forEach( function(item) {
            if (item.uid == '<%ar.writeJS(currentUser);%>') {
                registered = ("Unknown" != item.attend);
            }
        });
        return registered;
    }

    //initialize based on being registered, but allow user to toggle later
    $scope.showRollCall = $scope.isRegistered();


    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        console.log("Encountered problem: ",serverErr);
        errorPanelHandler($scope, serverErr);
        window.scrollTo(0, 0);
    };

    $scope.tinymceOptions = standardTinyMCEOptions();
    $scope.tinymceOptions.height = 300;

    //control what is open and closed
    $scope.showItemMap = {};
    $scope.editMeetingInfo = false;
    $scope.editMeetingDesc = false;
    $scope.editItemDetailsMap = {};
    $scope.editItemDescMap = {};

    $scope.stopEditing =  function() {
        $scope.editMeetingInfo = false;
        $scope.editMeetingDesc = false;
        $scope.editItemDetailsMap = {};
        $scope.editItemDescMap = {};
    }


    $scope.showAll = function() {
        $scope.meeting.agenda.forEach( function(item) {
            $scope.showItemMap[item.id] = true;
        });
    }

    if (window.location.href.indexOf("#cmt")>0) {
        $scope.showAll();
    }
    $scope.getAgendaItems = function() {
        return $scope.meeting.agenda;
    }


    $scope.datePickOptions = {
        formatYear: 'yyyy',
        startingDay: 1
    };
    $scope.datePickDisable = function(date, mode) {
        return false;
    };
    $scope.dummyDate1 = new Date();
    $scope.datePickOpen = false;
    $scope.openDatePicker = function($event) {
        $event.preventDefault();
        $event.stopPropagation();
        $scope.datePickOpen = true;
    };
    $scope.datePickOpen1 = false;
    $scope.openDatePicker1 = function($event) {
        $event.preventDefault();
        $event.stopPropagation();
        $scope.datePickOpen1 = true;
    };
    $scope.sortItemsB = function() {
        $scope.meeting.agenda.sort( function(a, b){
            return a.position - b.position;
        } );
        var runTime = $scope.meetingTime;
        var runDur = 0;
        for (var i=0; i<$scope.meeting.agenda.length; i++) {
            var item = $scope.meeting.agenda[i];
            item.position = i+1;
            item.schedule = runTime;
            runDur = runDur + item.duration;
            runTime = new Date( runTime.getTime() + (item.duration*60000) );
            item.scheduleEnd = runTime;
        }
        $scope.meeting.endTime = runTime;
        $scope.meeting.totalDuration = runDur;
        return $scope.meeting.agenda;
    };
    $scope.extractDateParts = function() {
        $scope.meetingTime = new Date($scope.meeting.startTime);
        $scope.meetingHour = $scope.meetingTime.getHours();
        $scope.meetingMinutes = $scope.meetingTime.getMinutes();
        $scope.sortItemsB();
    };
    $scope.extractDateParts();

    $scope.itemHasDoc = function(item, doc) {
        var res = false;
        var found = item.docList.forEach( function(docid) {
            if (docid == doc.universalid) {
                res = true;
            }
        });
        return res;
    }
    $scope.itemDocs = function(item) {
        return $scope.attachmentList.filter( function(oneDoc) {
            return $scope.itemHasDoc(item, oneDoc);
        });
    }
    $scope.itemTopics = function(item) {
        return $scope.allTopics.filter( function(oneTopic) {
            return item.topicLink == oneTopic.universalid;
        });
    }

    $scope.itemGoals = function(item) {
        var res = [];
        for (var j=0; j<item.actionItems.length; j++) {
            var aiId = item.actionItems[j];
            for(var i=0; i<$scope.allGoals.length; i++) {
                var oneGoal = $scope.allGoals[i];
                if (oneGoal.universalid == aiId) {
                    res.push(oneGoal);
                }
            }
        }
        res.sort( function(a,b) {
            return a.duedate-b.duedate;
        });
        return res;
    }
    $scope.filterGoals = function(actionItemFilter) {
        var res = [];
        var fil = actionItemFilter.toLowerCase();
        for(var i=0; i<$scope.allGoals.length; i++) {
            var oneGoal = $scope.allGoals[i];
            if (oneGoal.state<2 || oneGoal.state>4) {
                continue;
            }
            //TODO: does synposis, need to do others, including assigneeds, and need to split filter
            if (fil.length==0 || oneGoal.synopsis.toLowerCase().indexOf(fil)>=0) {
                res.push(oneGoal);
                continue;
            }
            for(var j=0; j<oneGoal.assignTo.length; j++) {
                var ass = oneGoal.assignTo[j];
                if (ass.name.toLowerCase().indexOf(fil)>=0) {
                    res.push(oneGoal);
                    break;
                }
            }
        }
        return res;
    }
    $scope.filterGoalsForItem = function(actionItemFilter, item) {
        var filteredList = $scope.filterGoals(actionItemFilter);
        var res = []
        for(var i=0; i<filteredList.length; i++) {
            var oneGoal = filteredList[i];
            if (!$scope.itemHasGoal(item, oneGoal)) {
                res.push(oneGoal);
            }
        }
        return res;
    }
    $scope.itemHasGoal = function(item, goal) {
        for (var j=0; j<item.actionItems.length; j++) {
            if (item.actionItems[j] == goal.universalid) {
                return true;
            }
        }
        return false;
    }
    $scope.addGoalToItem = function(item, goal) {
        if (!$scope.itemHasGoal(item, goal)) {
            item.actionItems.push(goal.universalid);
        }
        $scope.saveAgendaItem(item);
    }
    $scope.removeGoalFromItem = function(item, goal) {
        var res = [];
        for (var j=0; j<item.actionItems.length; j++) {
            var aiId = item.actionItems[j];
            if (aiId != goal.universalid) {
                res.push(aiId);
            }
        }
        item.actionItems = res;
        $scope.saveAgendaItem(item);
    }

    $scope.stateName = function() {
        if ($scope.meeting.state<=1) {
            return "Planning";
        }
        if ($scope.meeting.state==2) {
            return "Running";
        }
        return "Completed";
    };
    $scope.itemStateName = function(item) {
        if (item.status<=1) {
            return "Good";
        }
        if (item.status==2) {
            return "Warnings";
        }
        return "Trouble";
    };
    $scope.goalStateName = function(goal) {
        if (goal.prospects=="good") {
            return "Good";
        }
        if (goal.prospects=="ok") {
            return "Warnings";
        }
        return "Trouble";
    };

    $scope.meetingStateStyle = function(val) {
        if (val<=1) {
            return "background-color:white";
        }
        if (val==2) {
            return "background-color:lightgreen";
        }
        if (val>2) {
            return "background-color:gray";
        }
        return "Unknown";
    }
    $scope.itemStateStyle = function(item) {
        if (item.status<=1) {
            return "background-color:lightgreen";
        }
        if (item.status==2) {
            return "background-color:yellow";
        }
        if (item.status>2) {
            return "background-color:red";
        }
        return "background-color:lavender";
    }
    $scope.goalStateStyle = function(goal) {
        if (goal.prospects=="good") {
            return "background-color:lightgreen";
        }
        if (goal.prospects=="ok") {
            return "background-color:yellow";
        }
        if (goal.prospects=="bad") {
            return "background-color:red";
        }
        return "background-color:lavender";
    }

    $scope.startEditMeetingInfo = function() {
        $scope.savePendingEdits();
        $scope.editMeetingInfo=true;
    }
    $scope.startEditDescription = function() {
        $scope.savePendingEdits();
        $scope.editMeetingDesc=true
    }
    $scope.startItemDetailEdit = function(item) {
        $scope.savePendingEdits();
        $scope.editItemDetailsMap[item.id]=true;
        $scope.showItemMap[item.id]=true;
    }
    $scope.savePendingEdits = function() {
        if ($scope.editMeetingDesc) {
            $scope.savePartialMeeting(['meetingInfo']);
            $scope.editMeetingDesc = false;
        }
        if ($scope.editMeetingInfo) {
            $scope.savePartialMeeting(['name','startTime','targetRole','duration','reminderTime','meetingType','reminderSent']);
            $scope.editMeetingInfo = false;
        }
        $scope.meeting.agenda.forEach( function(item) {
            if ($scope.editItemDetailsMap[item.id]) {
                $scope.saveAgendaItemParts(item, ['subject','duration','presenters','topicLink','isSpacer']);
                $scope.editItemDetailsMap[item.id] = false;
            }
        });
    }

    $scope.changeMeetingState = function(newState) {
        $scope.savePendingEdits();
        $scope.meeting.state = newState;
        $scope.savePartialMeeting(['state']);
    };
    $scope.changeGoalState = function(goal, newState) {
        goal.prospects = newState;
        $scope.saveGoal(goal);
    };
    $scope.saveMeeting = function() {
        $scope.meetingTime.setHours($scope.meetingHour);
        $scope.meetingTime.setMinutes($scope.meetingMinutes);
        $scope.meetingTime.setSeconds(0);
        $scope.meeting.startTime = $scope.meetingTime.getTime();

        $scope.sortItemsB();
        $scope.putGetMeetingInfo($scope.meeting);
    };
    $scope.savePartialMeeting = function(fieldList) {
        $scope.meetingTime.setHours($scope.meetingHour);
        $scope.meetingTime.setMinutes($scope.meetingMinutes);
        $scope.meetingTime.setSeconds(0);
        $scope.meeting.startTime = $scope.meetingTime.getTime();

        var saveRecord = {};
        for (var j=0; j<fieldList.length; j++) {
            saveRecord[fieldList[j]] = $scope.meeting[fieldList[j]];
        }
        $scope.putGetMeetingInfo(saveRecord);
        $scope.stopEditing();
    };
    $scope.saveAgendaItem = function(agendaItem) {
        agendaItem.clearLock = "true";
        var saveRecord = {};
        saveRecord.agenda = [agendaItem];
        $scope.putGetMeetingInfo(saveRecord);
        $scope.stopEditing();
    };
    $scope.saveAgendaItemParts = function(agendaItem, fieldList) {
        agendaItem.presenters = [];
        agendaItem.presenterList.forEach( function(user) {
            agendaItem.presenters.push(user.uid);
        });
        var itemCopy = {};
        itemCopy.id = agendaItem.id;
        if (!agendaItem.subject || agendaItem.subject.length<1) {
            alert("Please enter agenda item name and subject before saving");
            agendaItem.subject = "Agenda Item "+(new Date()).getTime();
        }
        fieldList.map( function(ele) {
            itemCopy[ele] = agendaItem[ele];
        });
        $scope.saveAgendaItem(itemCopy);
    };
    $scope.revertAllEdits = function() {
        var saveRecord = {};
        $scope.putGetMeetingInfo(saveRecord);
        $scope.stopEditing();
    };
    $scope.putGetMeetingInfo = function(readyToSave) {
        var postURL = "meetingUpdate.json?id="+$scope.meeting.id;
        if (readyToSave.id=="~new~") {
            postURL = "agendaAdd.json?id="+$scope.meeting.id;
        }
        var postdata = angular.toJson(readyToSave);
        $scope.showError=false;
        var promise = $http.post(postURL ,postdata)
        promise.success( function(data) {
            $scope.meeting = data;
            $scope.extractDateParts();
            $scope.editHead=false;
            $scope.editDesc=false;
            $scope.extractPeopleSituation();
        });
        promise.error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
        return promise;
    };
    $scope.refreshMeetingPromise = function() {
        return $scope.putGetMeetingInfo({});
    }
    $scope.createAgendaItem = function() {
        var newAgenda = {
            id:"~new~",
            duration:10,
            position:$scope.meeting.agenda.length+1,
            number: "?",
            docList:[],
            presenters:[],
            presenterList:[],
            actionItems:[]
        };
        $scope.meeting.agenda.push(newAgenda);
        $scope.startItemDetailEdit(newAgenda);
    };


    $scope.getPeople = function(query) {
        return AllPeople.findMatchingPeople(query);
    }

    $scope.createActionItem = function(item) {
        var postURL = "createActionItem.json?id="+$scope.meeting.id+"&aid="+item.id;
        var newSynop = $scope.newGoal.synopsis;
        if (newSynop == null || newSynop.length==0) {
            alert("must enter a description of the action item");
            return;
        }
        for(var i=0; i<$scope.allGoals.length; i++) {
            var oneItem = $scope.allGoals[i];
            if (oneItem.synposis == newSynop) {
                item.actionItems.push(oneItem.universalid);
                $scope.newGoal = {};
                $scope.calcAllActions();
                return;
            }
        }
        $scope.newGoal.state=2;
        $scope.newGoal.assignTo = [];
        var player = $scope.newGoal.assignee;
        if (typeof player == "string") {
            var pos = player.lastIndexOf(" ");
            var name = player.substring(0,pos).trim();
            var uid = player.substring(pos).trim();
            player = {name: name, uid: uid};
        }

        $scope.newGoal.assignTo.push(player);
        $scope.newGoal.duedate = $scope.dummyDate1.getTime();

        var postdata = angular.toJson($scope.newGoal);
        $scope.showError=false;
        $http.post(postURL ,postdata)
        .success( function(data) {
            $scope.allGoals.push(data);
            item.actionItems.push(data.universalid);
            $scope.newGoal = {};
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
        $scope.stopEditing();
    };

    $scope.replaceGoal = function(goal) {
        var newList = $scope.allGoals.filter( function(item) {
            return item.id != goal.id;
        });
        newList.push(goal);
        $scope.allGoals = newList;
    }

    $scope.saveGoal = function(goal) {
        var postURL = "updateGoal.json?gid="+goal.id;
        var objForUpdate = {};
        objForUpdate.id = goal.id;
        objForUpdate.universalid = goal.universalid;
        objForUpdate.prospects = goal.prospects;  //first thing that could have been changed
        objForUpdate.duedate = goal.duedate;      //second thing that could have been changed
        objForUpdate.status = goal.status;        //third thing that could have been changed
        var postdata = angular.toJson(objForUpdate);
        $scope.showError=false;
        $scope.editGoalInfo=false;
        $scope.showAccomplishment=false;
        $http.post(postURL, postdata)
        .success( function(data) {
            $scope.replaceGoal(data);
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };

    $scope.refresh = function() {
        if ($scope.meeting.state!=2) {
            $scope.refreshStatus = "No refresh because meeting is not being run";
            return;  //don't set of refresh unless in run mode
        }
        window.setTimeout( function() {$scope.refresh()}, 60000);
        var nowEditing = $scope.editMeetingDesc;
        Object.keys($scope.editItemDescMap).forEach( function(key) {
            if ($scope.editItemDescMap[key]==true) {
                nowEditing = true;
            }
        });
        if (nowEditing) {
            $scope.refreshStatus = "No refresh because currently editing";
            return;
        }
        if (true) {
            $scope.refreshStatus = "No refresh because it doesn't work with TinyMCE editor";
            return;
        }
        $scope.refreshStatus = "Refreshing";
        $scope.putGetMeetingInfo( {} );
        $scope.refreshCount++;
    }
    $scope.refreshCount = 0;
    $scope.refresh();

    $scope.addPresenterxxxxxx = function(item, person) {
        var notPresent = true;
        item.presenters.forEach( function(b) {
            if (b == person.uid) {
                notPresent = false;
            }
        });
        if (notPresent) {
            item.presenters.push(person.uid);
        }
    }
    $scope.removePresenterxxxxx = function(item, person) {
        var newSet = [];
        item.presenters.map( function(b) {
            if (b != person.uid) {
                newSet.push(b);
            }
        });
        item.presenters = newSet;
    }
    $scope.toggleReady = function(item) {
        if (!item.readyToGo) {
            var x = window.confirm( "Have you attached all presentations, \n and is the rest of the information \n about the agenda item up to date?  \nClick 'OK' when everything is ready.");
            if (!x) {
                return;
            }
        }
        item.readyToGo=!item.readyToGo
        $scope.saveAgendaItemParts(item, ['readyToGo']);
    }

    $scope.createMinutes = function() {
        if ($scope.meeting.state != 3) {
            alert("Put the meeting into completed mode before generating minutes.");
            return;
        }
        var postURL = "createMinutes.json?id="+$scope.meeting.id;
        var postdata = angular.toJson("");
        $scope.showError=false;
        $http.post(postURL ,postdata)
        .success( function(data) {
            $scope.meeting = data;
            $scope.showInput=false;
            $scope.extractDateParts();
            $scope.refreshTopicList();
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };
    $scope.postMinutes = function() {
        if (!$scope.meeting.minutesId) {
            alert("program logic error: don't know about any minutes to change the state of");
            return;
        }
        var topicRecord = $scope.findTopicRecord($scope.meeting.minutesId)
        if (!topicRecord) {
            alert("program logic error: can't find a topic with the id "+$scope.meeting.minutesId);
            return;
        }
        var postURL = "noteHtmlUpdate.json?nid="+topicRecord.id;
        var rec = {};
        rec.id = topicRecord.id;
        rec.universalid = topicRecord.universalid;
        rec.discussionPhase = "Freeform";
        var postdata = angular.toJson(rec);
        $scope.showError=false;
        $http.post(postURL,postdata)
        .success( function(data) {
            $scope.refreshTopicList();
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };

    $scope.refreshAttachmentList = function() {
        var getURL = "docsList.json";
        $scope.showError=false;
        $http.get(getURL)
        .success( function(data) {
            $scope.attachmentList = data.docs;
            sessionStorage.setItem("ws"+$scope.pageId+"attachList", JSON.stringify(data.docs));
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    }
    var cachedAttachmentList = sessionStorage.getItem("ws"+$scope.pageId+"attachList");
    if (cachedAttachmentList) {
        $scope.attachmentList = JSON.parse(cachedAttachmentList);
        $scope.refreshAttachmentList(); //pick up any changes
    }
    else {
        $scope.refreshAttachmentList();
    }


    $scope.findTopicRecord = function(topicId) {
        var ret = null;
        $scope.allTopics.forEach( function(oneTopic) {
            if (topicId == oneTopic.universalid) {
                ret = oneTopic;
            }
            else if (topicId == oneTopic.id) {
                ret = oneTopic;
            }
        });
        return ret;
    }
    $scope.refreshTopicList = function() {
        var getURL = "topicList.json";
        $scope.showError=false;
        $http.get(getURL)
        .success( function(data) {
            $scope.allTopics = data.topics;
            sessionStorage.setItem("ws"+$scope.pageId+"topicList", JSON.stringify(data.topics));
            $scope.minutesDraft = $scope.getMinutesIsDraft();
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    }
    var cachedTopicList = sessionStorage.getItem("ws"+$scope.pageId+"topicList");
    if (cachedTopicList) {
        $scope.allTopics = JSON.parse(cachedTopicList);
        $scope.refreshTopicList(); //pick up any changes
    }
    else {
        $scope.refreshTopicList();
    }




    $scope.getMinutesStyle = function() {
        if ($scope.meeting.minutesId) {
            if (!$scope.minutesDraft) {
                return "margin:4px;"
            }
        }
        return "margin:4px;background-color:yellow;"
    }
    $scope.getMinutesIsDraft = function() {
        var isDraft = true;
        if ($scope.meeting.minutesId) {
            var minutesTopic = $scope.findTopicRecord($scope.meeting.minutesId);
            if (minutesTopic) {
                isDraft = minutesTopic.draft;
            }
        }
        return isDraft;
    }
    $scope.minutesDraft = $scope.getMinutesIsDraft();



    $scope.startEditLockDescription = function(item) {
        var rec = {};
        rec.id = item.id;
        rec.setLock = true;
        var saveRecord = {};
        saveRecord.agenda = [rec];
        $scope.putGetMeetingInfo(saveRecord);
        $scope.showItemMap[item.id]=true;
        $scope.editItemDescMap[item.id]=true;
    }
    $scope.saveEditUnlockDesciption = function(item) {
        var rec = {};
        rec.id = item.id;
        rec.clearLock = true;
        rec.desc = item.desc;
        var saveRecord = {};
        saveRecord.agenda = [rec];
        $scope.putGetMeetingInfo(saveRecord);
        $scope.editItemDescMap[item.id]=false;
    }
    $scope.cancelEditUnlockDesciption = function(item) {
        var rec = {};
        rec.id = item.id;
        rec.clearLock = true;
        var saveRecord = {};
        saveRecord.agenda = [rec];
        $scope.putGetMeetingInfo(saveRecord);
        $scope.editItemDescMap[item.id]=false;
    }


    $scope.startNewComment = function(item, theType, cmt) {
        item.newComment = {};
        item.newComment.choices = ["Consent", "Objection"];
        item.newComment.html="";
        item.newComment.commentType=theType;
        if (cmt) {
            item.newComment.replyTo = cmt.time;
        }
        $scope.openCommentEditor(8,item.id)
    }
    $scope.saveNewComment = function(item) {
        var itemCopy = {};
        itemCopy.id = item.id;
        itemCopy.newComment = item.newComment;
        $scope.saveAgendaItem(itemCopy);
    }
    $scope.saveComment = function(item, cmt) {
        var itemCopy = {};
        itemCopy.id = item.id;
        itemCopy.comments = [];
        itemCopy.comments.push(cmt);
        $scope.saveAgendaItem(itemCopy);
    }


    $scope.stateStyle = function(cmt) {
        if (cmt.state==11) {
            return "background-color:yellow;";
        }
        if (cmt.state==12) {
            return "background-color:#DEF;";
        }
        return "background-color:#EEE;";
    }
    $scope.stateClass = function(cmt) {
        if (cmt.state==11) {
            return "comment-state-draft";
        }
        if (cmt.state==12) {
            return "comment-state-active";
        }
        return "comment-state-complete";
    }
    $scope.commentTypeName = function(cmt) {
        if (cmt.commentType==2) {
            return "Proposal";
        }
        if (cmt.commentType==3) {
            return "Round";
        }
        if (cmt.commentType==5) {
            return "Minutes";
        }
        return "Comment";
    }
    $scope.postComment = function(item, cmt) {
        cmt.state = 12;
        if (cmt.commentType == 1 || cmt.commentType == 5 ) {
            //simple comments & minutes go all the way to closed
            cmt.state = 13;
        }
        $scope.saveComment(item, cmt);
    }
    $scope.deleteComment = function(item, cmt) {
        cmt.deleteMe = true;
        $scope.saveComment(item, cmt);
    }
    $scope.closeComment = function(item, cmt) {
        cmt.state = 13;
        if (cmt.commentType>1) {
            $scope.openOutcomeEditor(item, cmt);
        }
        else {
            $scope.saveComment(item, cmt);
        }
    }

    $scope.getMyResponse = function(cmt) {
        cmt.choices = ["Consent", "Objection"]
        var selected = [];
        if (cmt.user=="<%ar.writeJS(currentUser);%>") {
            return selected;
        }
        cmt.responses.map( function(item) {
            if (item.user=="<%ar.writeJS(currentUser);%>") {
                selected.push(item);
            }
        });
        if (selected.length == 0) {
            var newResponse = {};
            newResponse.user = "<%ar.writeJS(currentUser);%>";
            cmt.responses.push(newResponse);
            selected.push(newResponse);
        }
        return selected;
    }

    $scope.navigateToDoc = function(doc) {
        window.location="docinfo"+doc.id+".htm";
    }
    $scope.navigateToTopic = function(topicId) {
        var topicRecord = $scope.findTopicRecord(topicId);
        if (topicRecord) {
            window.location="noteZoom"+topicRecord.id+".htm";
        }
        else {
            alert("Sorry, can't seem to find a discussion topic with the id: "+topicId);
        }
    }

    $scope.mySitch = [];

    $scope.extractPeopleSituation = function() {
        if (Array.isArray) {
            if (!Array.isArray($scope.allLabels)) {
                console.log("allLabels is NOT an array");
                return;
            }
        }
        else {
            console.log("NO isArray function");
        }
        var selRole = {};
        $scope.allLabels.forEach( function(item) {
            if (item.name === $scope.meeting.targetRole) {
                selRole = item;
            }
        });
        var rez = [];
        $scope.mySitch = [];
        selRole.players.forEach( function(item) {
            var current;
            $scope.meeting.rollCall.forEach( function(rc) {
                if (rc.uid === item.uid) {
                    current = rc;
                }
            });
            if (current) {
                current.name = item.name;
                current.key = item.key;
            }
            else {
                current =  {
                    uid: item.uid,
                    name: item.name,
                    key: item.key,
                    attend: "Unknown",
                    situation: ""
                };
                $scope.meeting.rollCall.push(current);
            }
            if (item.uid === "<% ar.writeJS(currentUser); %>") {
                $scope.mySitch = [current];
            }
            rez.push(current);
        });
        $scope.peopleStatus = rez;
    }

//There is a strange bug in Angular that you can't call the method directly
//so since this value does not change, storing the result here.
    $scope.extractPeopleSituation();

    $scope.showSelfRegister = function() {
        return ($scope.meeting.state <= 1 && !$scope.showRollCall);
    }
    $scope.showRollBox = function() {
        return $scope.showRollCall && $scope.meeting.state == 1
    }
    $scope.editAttendees = function() {
        return ($scope.meeting.state == 2);
    }
    $scope.toggleRollCall = function() {
        $scope.showRollCall = !$scope.showRollCall;
    }
    $scope.isCompleted = function() {
        return ($scope.meeting.state >= 3);
    }
    $scope.addYouself = function() {
        $scope.newAttendee = '<%=currentUser%>';
        $scope.addAttendee();
    }
    $scope.addAttendee = function() {
        var needAdd = true;
        if (!$scope.newAttendee) {
            return;
        }
        var promise = $scope.refreshMeetingPromise();
        promise.success( function() {
            $scope.meeting.attended.forEach( function(item) {
                if (item==$scope.newAttendee) {
                    needAdd = false;
                }
            });
            if (needAdd) {
                $scope.meeting.attended.push($scope.newAttendee);
            }
            $scope.newAttendee = "";
            $scope.savePartialMeeting(['attended']);
        });
    }
    $scope.removeAttendee  = function(person) {
        var promise = $scope.refreshMeetingPromise();
        promise.success( function() {
            if (confirm("Remove "+person.name+" from attendee list?")) {
                $scope.meeting.attended = $scope.meeting.attended.filter( function(item) {
                    return (item!=person.uid);
                });
            }
            $scope.savePartialMeeting(['attended']);
        });
    }
    $scope.getAttended = function() {
        return $scope.meeting.attended.map( function(uid) {
            return AllPeople.findPerson(uid);
        });
    }

    $scope.saveSituation = function() {
        $scope.savePartialMeeting(['rollCall']);
        $scope.showRollCall = $scope.isRegistered();
    }

    $scope.moveItemToBacklog = function(item) {
        var delId = item.id;
        var postURL = "agendaMove.json?src="+$scope.meeting.id+"&dest="+$scope.backlogId;
        var postdata = angular.toJson(item);
        $scope.showError=false;
        $http.post(postURL,postdata)
        .success( function(data) {
            $scope.refreshMeetingPromise();
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };


    $scope.openModalActionItem = function (item, goal) {

        var modalInstance = $modal.open({
          animation: false,
          templateUrl: '<%=ar.retPath%>templates/ModalActionItem.html<%=templateCacheDefeater%>',
          controller: 'ModalActionItemCtrl',
          size: 'lg',
          backdrop: "static",
          resolve: {
            item: function () {
              return item;
            },
            goal: function () {
              return goal;
            }
          }
        });

        modalInstance.result.then(function (modifiedGoal) {
            $scope.allGoals.map( function(item) {
                if (item.id == modifiedGoal.id) {
                    item.duedate = modifiedGoal.duedate;
                    item.status = modifiedGoal.status;
                }
            });
            $scope.saveGoal(modifiedGoal);
        }, function () {
          //cancel action
        });
    };

    $scope.replyToComment = function(item,cmt) {
        item.newComment = {};
        item.newComment.myReplyTo = cmt.time;
        item.newComment.myPoll = false;
    }

    $scope.findComment = function(item, timeStamp) {
        var foundComment = null;
        item.comments.forEach( function(item) {
            if ( item.time == timeStamp ) {
                foundComment = item;
            }
        });
        return foundComment;
    }
    $scope.currentTime = (new Date()).getTime();
    $scope.calcDueDisplay = function(cmt) {
        if (cmt.commentType==1 || cmt.commentType==4) {
            return "";
        }
        if (cmt.state==13) {
            return "";
        }
        var diff = Math.floor((cmt.dueDate-$scope.currentTime) / 60000);
        if (diff<0) {
            return "overdue";
        }
        if (diff<120) {
            return "due in "+diff+" minutes";
        }
        diff = Math.floor(diff / 60);
        if (diff<48) {
            return "due in "+diff+" hours";
        }
        diff = Math.floor(diff / 24);
        if (diff<8) {
            return "due in "+diff+" days";
        }
        diff = Math.trunc(diff / 7);
        return "due in "+diff+" weeks";
    }
    $scope.getResponse = function(cmt) {
        var selected = cmt.responses.filter( function(item) {
            return item.user=="<%ar.writeJS(currentUser);%>";
        });
        return selected;
    }
    $scope.noResponseYet = function(cmt) {
        if (cmt.state!=12) { //not open
            return false;
        }
        var whatNot = $scope.getResponse(cmt);
        return (whatNot.length == 0);
    }
    $scope.updateResponse = function(cmt, response) {
        var selected = cmt.responses.filter( function(item) {
            return item.user!="<%ar.writeJS(currentUser);%>";
        });
        selected.push(response);
        cmt.responses = selected;
        //should pass the agent item so we can just save it....
        $scope.saveMeeting();
    }
    $scope.moveItem = function(item,amt) {
        var thisPos = item.position;
        var otherPos = thisPos + amt;
        if (otherPos<=0) {
            return;
        }
        if (otherPos>$scope.meeting.agenda.length) {
            return;
        }
        $scope.meeting.agenda.forEach( function(x) {
            if (x.position==otherPos) {
                x.position=thisPos;
            }
        });
        item.position=otherPos;
        $scope.saveMeeting();
    }

    $scope.openResponseEditor = function (cmt) {

        if (cmt.choices.length==0) {
            cmt.choices = ["Consent", "Objection"];
            if (cmt.choices[1]=="Object") {
                cmt.choices[1]="Objection";
            }
        }

        var selected = $scope.getResponse(cmt);
        var selResponse = {};
        if (selected.length == 0) {
            selResponse.user = "<%ar.writeJS(currentUser);%>";
            selResponse.userName = "<%ar.writeJS(currentUserName);%>";
            selResponse.choice = cmt.choices[0];
            selResponse.isNew = true;
        }
        else {
            selResponse = selected[0];
        }

        var modalInstance = $modal.open({
            animation: false,
            templateUrl: '<%=ar.retPath%>templates/ResponseModal.html<%=templateCacheDefeater%>',
            controller: 'ModalResponseCtrl',
            size: 'lg',
            backdrop: "static",
            resolve: {
                response: function () {
                    return JSON.parse(JSON.stringify(selResponse));
                },
                cmt: function () {
                    return JSON.parse(JSON.stringify(cmt));
                }
            }
        });

        modalInstance.result.then(function (response) {
            var cleanResponse = {};
            cleanResponse.html = response.html;
            cleanResponse.user = response.user;
            cleanResponse.userName = response.userName;
            cleanResponse.choice = response.choice;
            $scope.updateResponse(cmt, cleanResponse);
        }, function () {
            //cancel action - nothing really to do
        });
    };

    $scope.commentItemBeingEdited = 0;
    $scope.updateComment = function(cmt) {
        $scope.saveComment($scope.commentItemBeingEdited, cmt);
    }
    $scope.loadItems = function(query) {
        return AllPeople.findMatchingPeople(query);
    }
    $scope.toggleSelectedPerson = function(tag) {
        $scope.selectedPersonShow = !$scope.selectedPersonShow;
        $scope.selectedPerson = tag;
        if (!$scope.selectedPerson.uid) {
            $scope.selectedPerson.uid = $scope.selectedPerson.name;
        }
    }
    $scope.navigateToUser = function(player) {
        window.location="<%=ar.retPath%>v/FindPerson.htm?uid="+encodeURIComponent(player.uid);
    }

    $scope.openCommentCreator = function(item, type, replyTo, defaultBody) {
        var newComment = {};
        newComment.time = new Date().getTime();
        newComment.commentType = type;
        newComment.state = 11;
        newComment.dueDate = (new Date()).getTime() + (7*24*60*60*1000);
        newComment.isNew = true;
        newComment.user = "<%ar.writeJS(currentUser);%>";
        newComment.userName = "<%ar.writeJS(currentUserName);%>";
        newComment.userKey = "<%ar.writeJS(currentUserKey);%>";
        if (replyTo) {
            newComment.replyTo = replyTo;
        }
        if (defaultBody) {
            newComment.html = defaultBody;
        }
        $scope.openCommentEditor(item, newComment);
    }

    $scope.openCommentEditor = function (item, cmt) {
        $scope.commentItemBeingEdited = item;

        var modalInstance = $modal.open({
            animation: false,
            templateUrl: '<%=ar.retPath%>templates/CommentModal.html<%=templateCacheDefeater%>',
            controller: 'CommentModalCtrl',
            size: 'lg',
            backdrop: "static",
            resolve: {
                cmt: function () {
                    return JSON.parse(JSON.stringify(cmt));
                },
                parentScope: function() {
                    return $scope;
                }
            }
        });

        modalInstance.result.then(function (returnedCmt) {
            var cleanCmt = {};
            cleanCmt.time = cmt.time;
            cleanCmt.html = returnedCmt.html;
            cleanCmt.state = returnedCmt.state;
            cleanCmt.replyTo = returnedCmt.replyTo;
            cleanCmt.commentType = returnedCmt.commentType;
            cleanCmt.dueDate = returnedCmt.dueDate;
            $scope.saveComment(item, cleanCmt);
        }, function () {
            //cancel action - nothing really to do
        });
    };

    $scope.openOutcomeEditor = function (item, cmt) {

        var modalInstance = $modal.open({
            animation: false,
            templateUrl: '<%=ar.retPath%>templates/OutcomeModal.html<%=templateCacheDefeater%>',
            controller: 'OutcomeModalCtrl',
            size: 'lg',
            backdrop: "static",
            keyboard: false,
            resolve: {
                cmt: function () {
                    return JSON.parse(JSON.stringify(cmt));
                }
            }
        });

        modalInstance.result.then(function (returnedCmt) {
            var cleanCmt = {};
            cleanCmt.time = cmt.time;
            cleanCmt.outcome = returnedCmt.outcome;
            cleanCmt.state = returnedCmt.state;
            cleanCmt.commentType = returnedCmt.commentType;
            $scope.saveComment(item, cleanCmt);
        }, function () {
            //cancel action - nothing really to do
        });
    };



    $scope.openDecisionEditor = function (item, cmt) {

        var newDecision = {
            html: cmt.html,
            labelMap: {},
            sourceId: $scope.meeting.id,
            sourceType: 7,
            sourceCmt: cmt.time
        };

        var decisionModalInstance = $modal.open({
            animation: false,
            templateUrl: '<%=ar.retPath%>templates/DecisionModal.html<%=templateCacheDefeater%>',
            controller: 'DecisionModalCtrl',
            size: 'lg',
            resolve: {
                decision: function () {
                    return JSON.parse(JSON.stringify(newDecision));
                },
                allLabels: function() {
                    return $scope.allLabels;
                }
            }
        });

        decisionModalInstance.result
        .then(function (newDecision) {
            newDecision.num="~new~";
            newDecision.sourceType = 7;
            newDecision.universalid="~new~";
            var postURL = "updateDecision.json?did=~new~";
            var postData = angular.toJson(newDecision);
            $http.post(postURL, postData)
            .success( function(data) {
                var relatedComment = data.sourceCmt;
                item.comments.map( function(cmt) {
                    if (cmt.time == relatedComment) {
                        cmt.decision = "" + data.num;
                        $scope.saveComment(item, cmt);
                    }
                });
            })
            .error( function(data, status, headers, config) {
                $scope.reportError(data);
            });
        }, function () {
            //cancel action - nothing really to do
        });
    };


    $scope.openAttachDocument = function (item) {

        var attachModalInstance = $modal.open({
            animation: true,
            templateUrl: '<%=ar.retPath%>templates/AttachDocument.html<%=templateCacheDefeater%>',
            controller: 'AttachDocumentCtrl',
            size: 'lg',
            resolve: {
                docList: function () {
                    return JSON.parse(JSON.stringify(item.docList));
                },
                attachmentList: function() {
                    return $scope.attachmentList;
                },
                docSpaceURL: function() {
                    return "<%ar.writeJS(docSpaceURL);%>";
                }
            }
        });

        attachModalInstance.result
        .then(function (docList) {
            item.docList = docList;
            $scope.saveAgendaItem(item);
        }, function () {
            //cancel action - nothing really to do
        });
    };


    $scope.openAttachTopics = function (item) {

        var attachModalInstance = $modal.open({
            animation: true,
            templateUrl: '<%=ar.retPath%>templates/AttachTopic.html<%=templateCacheDefeater%>',
            controller: 'AttachTopicCtrl',
            size: 'lg',
            resolve: {
                selectedTopic: function () {
                    return item.topicLink;
                },
                attachmentList: function() {
                    return $scope.allTopics;
                }
            }
        });

        attachModalInstance.result
        .then(function (selectedTopic, topicName) {
            item.topicLink = selectedTopic;
            $scope.allTopics.forEach( function(oneTopic) {
                if (selectedTopic == oneTopic.universalid) {
                    item.subject = oneTopic.subject;
                }
            });
            $scope.saveAgendaItem(item);
        }, function () {
            //cancel action - nothing really to do
        });
    };

    $scope.openAttachAction = function (item) {

        var attachModalInstance = $modal.open({
            animation: true,
            templateUrl: '<%=ar.retPath%>templates/AttachAction.html<%=templateCacheDefeater%>',
            controller: 'AttachActionCtrl',
            size: 'lg',
            resolve: {
                selectedActions: function () {
                    return JSON.parse(JSON.stringify(item.actionItems));
                },
                allActions: function() {
                    return $scope.allGoals;
                },
            }
        });

        attachModalInstance.result
        .then(function (selectedActionItems) {
            item.actionItems = selectedActionItems;
            $scope.saveAgendaItem(item);
        }, function () {
            //cancel action - nothing really to do
        });
    };

});



</script>
<script src="../../../jscript/AllPeople.js"></script>

<style>
[ng\:cloak], [ng-cloak], [data-ng-cloak], [x-ng-cloak], .ng-cloak, .x-ng-cloak {
  display: none !important;
}

.blankTitle {
    font-size: 130%;
    font-weight: bold;
}
.agendaTitle {
    font-size: 130%;
    font-weight: bold;
    border-style:dotted;
    border-color:white;
}
.agendaTitle:hover {
    font-size: 130%;
    font-weight: bold;
    border-style:dotted;
    border-color:lightblue;
    cursor:pointer;
}

</style>

<div ng-app="myApp" ng-controller="myCtrl" ng-cloak>

<%@include file="ErrorPanel.jsp"%>

<%if (isLoggedIn) { %>
        <div class="rightDivContent" style="margin-right:100px;">
          <span class="dropdown">
              <button class="btn btn-default btn-raised dropdown-toggle" type="button" id="menu1" data-toggle="dropdown" style="{{meetingStateStyle(meeting.state)}}">
              State: {{stateName()}} <span class="caret"></span></button>
              <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
                <li role="presentation"><a role="menuitem"
                    ng-click="changeMeetingState(1)">Plan Meeting</a></li>
                <li role="presentation"><a role="menuitem"
                    ng-click="changeMeetingState(2)">Run Meeting</a></li>
                <li role="presentation"><a role="menuitem"
                    ng-click="changeMeetingState(3)">Complete Meeting</a></li>
              </ul>
          </span>
          <span class="dropdown">
            <button class="btn btn-default btn-raised dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
            Options: <span class="caret"></span></button>
            <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
              <li role="presentation"><a role="menuitem" tabindex="-1"
                  href="#" ng-click="showAll()" >Show All Items</a></li>
              <li role="presentation"><a role="menuitem" tabindex="-1"
                  href="#" ng-click="toggleRollCall()" >Show Roll Call</a></li>
              <li role="presentation"><a role="menuitem" tabindex="-1"
                  href="#" ng-click="createAgendaItem()" >Create Agenda Item</a></li>
              <li role="presentation"><a role="menuitem" tabindex="-1"
                  href="meeting.htm?id={{meeting.id}}" >Arrange Agenda</a></li>
              <li role="presentation"><a role="menuitem"
                  href="sendNote.htm?meet={{meeting.id}}">Send Email about Meeting</a></li>
              <li role="presentation" class="divider"></li>
              <li role="presentation"><a role="menuitem"
                  ng-click="createMinutes()">Generate Minutes</a></li>
              <li role="presentation" ng-show="meeting.minutesId"><a role="menuitem"
                  href="noteZoom{{meeting.minutesLocalId}}.htm">View Minutes</a></li>
              <li role="presentation" class="divider"></li>
              <li role="presentation"><a role="menuitem" tabindex="-1"
                  href="cloneMeeting.htm?id={{meeting.id}}">Clone Meeting</a></li>
              <li role="presentation"><a role="menuitem"
                  href="meetingList.htm">List All Meetings</a></li>
            </ul>
          </span>

        </div>
<% } %>

    <table>
      <tr>
        <td style="width:100%">
          <div class="leafContent">
            <span style="font-size:150%;font-weight: bold;">
                <i class="fa fa-gavel" style="font-size:130%"></i>
                {{meeting.name}} @ {{meeting.startTime|date: "HH:mm 'on' dd-MMM-yyyy"}}
            </span>
<%if (isLoggedIn) { %>
           <span class="dropdown">
                <button class="dropdown-toggle specCaretBtn" type="button"  d="menu"
                    data-toggle="dropdown"> <span class="caret"></span> </button>
                <ul class="dropdown-menu" role="menu" aria-labelledby="menu">
                  <li role="presentation">
                      <a role="menuitem" ng-click="startEditMeetingInfo()">
                      <i class="fa fa-cogs"></i>
                      Meeting Settings</a></li>
                  <li role="presentation">
                      <a role="menuitem" ng-click="startEditDescription()">
                      <i class="fa fa-pencil-square-o"></i>
                      Edit Description</a></li>
                  <li role="presentation">
                      <a role="menuitem" href="meetingTime{{meeting.id}}.ics">
                      <i class="fa fa-book"></i>
                      Create Calendar Entry</a></li>
                </ul>
            </span>
<% } %>
          </div>
           <div class="well leafContent" ng-show="editMeetingInfo">
             <table>
                <tr><td style="height:10px"></td></tr>
                <tr id="trspath">
                    <td class="gridTableColummHeader">Type:</td>
                    <td style="width:20px;"></td>
                    <td colspan="2" class="form-inline form-group">
                        <input type="radio" ng-model="meeting.meetingType" value="1"
                            class="form-control" /> Circle Meeting   &nbsp;
                        <input type="radio" ng-model="meeting.meetingType" value="2"
                            class="form-control" /> Operational Meeting
                    </td>
                </tr>
                <tr><td style="height:10px"></td></tr>
                <tr>
                    <td class="gridTableColummHeader">Name:</td>
                    <td style="width:20px;"></td>
                    <td colspan="2"><input ng-model="meeting.name"  class="form-control"></td>
                </tr>
                <tr><td style="height:10px"></td></tr>
                <tr>
                    <td class="gridTableColummHeader">Date:</td>
                    <td style="width:20px;"></td>
                    <td colspan="2" class="form-inline form-group">

                        <input type="text"
                        style="width:150;"
                        class="form-control"
                        datepicker-popup="dd-MMMM-yyyy"
                        ng-model="meetingTime"
                        is-open="datePickOpen"
                        min-date="minDate"
                        datepicker-options="datePickOptions"
                        date-disabled="datePickDisable(date, mode)"
                        ng-required="true"
                        ng-click="openDatePicker($event)"
                        close-text="Close"/>
                        at
                        <select style="width:50;" ng-model="meetingHour" class="form-control" >
                            <option value="0">00</option>
                            <option value="1">01</option>
                            <option value="2">02</option>
                            <option value="3">03</option>
                            <option value="4">04</option>
                            <option value="5">05</option>
                            <option value="6">06</option>
                            <option value="7">07</option>
                            <option value="8">08</option>
                            <option value="9">09</option>
                            <option>10</option>
                            <option>11</option>
                            <option>12</option>
                            <option>13</option>
                            <option>14</option>
                            <option>15</option>
                            <option>16</option>
                            <option>17</option>
                            <option>18</option>
                            <option>19</option>
                            <option>20</option>
                            <option>21</option>
                            <option>22</option>
                            <option>23</option>
                        </select> :
                        <select  style="width:50;" ng-model="meetingMinutes" class="form-control" >
                            <option value="0">00</option>
                            <option>15</option>
                            <option>30</option>
                            <option>45</option>
                        </select>
                    </td>
                </tr>
                <tr><td style="height:10px"></td></tr>
                <tr>
                    <td class="gridTableColummHeader">Duration:</td>
                    <td style="width:20px;"></td>
                    <td colspan="2" class="form-inline form-group">
                        <input ng-model="meeting.duration" style="width:60px;"  class="form-control" >
                        Minutes ({{meeting.totalDuration}} currently allocated)
                    </td>
                </tr>
                <tr><td style="height:10px"></td></tr>
                <tr>
                    <td class="gridTableColummHeader">Send Reminder:</td>
                    <td style="width:20px;"></td>
                    <td colspan="2" class="form-inline form-group">
                        <input ng-model="meeting.reminderTime" style="width:60px;"  class="form-control" >
                        <span ng-show="meeting.reminderSent==0"> Minutes before the meeting</span>
                        <span ng-show="meeting.reminderSent>100"> Was sent {{meeting.reminderSent|date:'M/d/yy H:mm'}}
                        </span>
                    </td>
                </tr>
                <tr><td style="height:10px"></td></tr>
                <tr>
                    <td class="gridTableColummHeader">Target Role:</td>
                    <td style="width:20px;"></td>
                    <td colspan="2" class="form-inline form-group">
                        <select class="form-control" ng-model="meeting.targetRole" ng-options="value for value in allRoles"></select>
                    </td>
                </tr>
                <tr><td style="height:10px"></td></tr>
                <tr>
                    <td class="gridTableColummHeader"></td>
                    <td style="width:20px;"></td>
                    <td colspan="2" class="form-inline form-group">
                        <button ng-click="savePendingEdits()" class="btn btn-primary btn-raised">Save</button>
                        <button ng-click="revertAllEdits()" class="btn btn-warning btn-raised">Cancel</button>
                    </td>
                </tr>


              </table>
           </div>
        </td>
      </tr>
      <tr>
        <td ng-hide="editMeetingDesc" style="width:100%">
           <div class="leafContent">
             <div ng-bind-html="meeting.meetingInfo"></div>
           </div>
        </td>
        <td ng-show="editMeetingDesc" style="width:100%">
            <div class="well leafContent">
                <div ui-tinymce="tinymceOptions" ng-model="meeting.meetingInfo"
                     class="leafContent" style="min-height:200px;" ></div>
                <button ng-click="savePendingEdits()" class="btn btn-primary btn-raised">Save</button>
                <button ng-click="revertAllEdits()" class="btn btn-warning btn-raised">Cancel</button>
            </div>
        </td>
      </tr>
    </table>

<!-- THIS IS THE ROLL CALL SECTION -->


    <div ng-repeat="sitch in mySitch" class="comment-outer" style="margin:40px" ng-show="showSelfRegister()">
      <div><h3 style="margin:5px"><% ar.writeHtml(currentUserName); %>, will you attend?</h3></div>
      <div class="comment-inner">
        <div class="form-inline form-group" style="margin:20px">
            <select ng-model="sitch.attend" class="form-control">
                <option>Unknown</option>
                <option>Yes</option>
                <option>Maybe</option>
                <option>No</option>
            </select>
            Details:
            <input type="text" ng-model="sitch.situation" class="form-control" style="width:400px;">
            <button class="btn btn-primary btn-raised" ng-click="saveSituation()">Save</button>
        </div>

      </div>
    </div>


    <div class="comment-outer" style="margin:40px" ng-show="editAttendees()">
      <div><h2 style="margin:5px">Attendance List</h2></div>
      <div class="comment-inner">
        <div class="form-inline form-group" style="margin:20px">
           Attendees:
           <button class="btn btn-sm" ng-repeat="person in getAttended()" style="margin:3px;"
                   ng-click="removeAttendee(person)">{{person.name}}</button>
        </div>
        <div class="form-inline form-group" style="margin:20px">
            <button class="btn btn-primary btn-raised" ng-click="addYouself()">Add Yourself</button> &nbsp;
            <button class="btn btn-primary btn-raised" ng-click="addAttendee()">Add By Email Address: </button>
            <input type="text" ng-model="newAttendee" class="form-control" placeholder="Enter email address"
               typeahead="person.uid as person.name for person in getPeople($viewValue) | limitTo:12">
        </div>
      </div>
    </div>

    <div class="leafContent" ng-show="isCompleted()">
       Attendees:
       <button class="btn btn-sm" ng-repeat="person in getAttended()"
               style="margin:3px;">{{person.name}}</button>
    </div>
    <div class="leafContent" ng-show="isCompleted() && meeting.minutesId">
        <div ng-show="minutesDraft">
           Draft Minutes:
           <span class="btn btn-sm btn-default btn-raised"  style="margin:4px;background-color:yellow;"
                 ng-click="navigateToTopic(meeting.minutesLocalId)">
                 View Minutes
           </span>
           <span class="btn btn-sm btn-default btn-raised"  style="margin:4px;"
                 ng-click="postMinutes(meeting.minutesLocalId)">
                 Post Minutes as they are
           </span>
        </div>
        <div ng-hide="minutesDraft">
           Posted Minutes:
           <span class="btn btn-sm btn-default btn-raised"  style="margin:4px;"
                 ng-click="navigateToTopic(meeting.minutesLocalId)">
                 View Minutes
           </span>
        </div>
    </div>

<%if (!isLoggedIn) { %>
    <div class="leafContent">
        Log in to see more details about this meeting.
    </div>
<% } %>


    <div class="comment-outer" ng-show="showRollBox()">
      <div style="float:right" ng-click="toggleRollCall()"><i class="fa fa-close"></i></div>
      <div>Roll Call</div>
      <table class="table">
      <tr>
          <th>Name</th>
          <th style="width:20px;"></th>
          <th>Attending</th>
          <th>Situation</th>
      </tr>
      <tr class="comment-inner" ng-repeat="pers in peopleStatus">
          <td>{{pers.name}}</td>
          <td  style="width:20px;">
              <div ng-show="pers.uid=='<%ar.writeJS(currentUser);%>'" style="cursor:pointer;"
              ng-click="toggleRollCall()">
                  <i class="fa fa-edit"></i></div></td>
          <td>{{pers.attend}}</td>
          <td>{{pers.situation}}</td>
      </tr>
      </table>
    </div>

<style>
.agendaItemFull {
    border: 1px solid lightgrey;
    border-radius:10px;
    margin-top:20px;
}
.agendaItemBlank {
    background-color:lightgray;
    margin-top:20px;
}
</style>
<script>
</script>

<div ng-repeat="item in getAgendaItems()">
    <div class="agendaItemBlank" ng-show="item.isSpacer">
      <div style="padding:5px;">
        <div style="width:100%">
                <span class="blankTitle" ng-click="showItemMap[item.id]=!showItemMap[item.id]">
                    {{item.subject}} </span>  &nbsp;
<%if (isLoggedIn) { %>
                <span class="dropdown">
                    <button class="dropdown-toggle specCaretBtn" type="button"  d="menu"
                        data-toggle="dropdown"> <span class="caret"></span> </button>
                    <ul class="dropdown-menu" role="menu" aria-labelledby="menu">
                      <li role="presentation">
                          <a role="menuitem" ng-click="startItemDetailEdit(item)"><i class="fa fa-cogs"></i> Item Settings</a></li>
                      <li role="presentation">
                          <a role="menuitem" ng-click="moveItem(item,-1)"><i class="fa fa-arrow-up"></i> Move Up</a></li>
                      <li role="presentation">
                          <a role="menuitem" ng-click="moveItem(item,1)"><i class="fa fa-arrow-down"></i> Move Down</a></li>
                    </ul>
                </span>
<% } %>
                <span>
                    <i>({{item.duration}} minutes) {{item.schedule | date: 'HH:mm'}}
                      - {{item.scheduleEnd | date: 'HH:mm'}} </i>
                </span>
        </div>
          <div ng-show="editItemDetailsMap[item.id]" class="well" style="margin:20px">
            <div class="form-inline form-group" ng-hide="item.topicLink">
              Name: <input ng-model="item.subject"  class="form-control" style="width:200px;"
                           placeholder="Enter Agenda Item Name"/>
                    <input type="checkbox"  ng-model="item.isSpacer"
                             class="form-control" style="width:50px;"/>
                    Break Time
            </div>
            <div class="form-inline form-group">
              Duration: <input ng-model="item.duration"  class="form-control" style="width:50px;"/>
            </div>
            <div class="form-inline form-group">
              <button ng-click="savePendingEdits()" class="btn btn-primary btn-raised">Save</button>
              <button ng-click="revertAllEdits()" class="btn btn-warning btn-raised">Cancel</button>
            </div>
          </div>
      </div>
    </div>
    <div class="agendaItemFull"  ng-hide="item.isSpacer">
    <table style="width:100%">

                          <!--  AGENDA HEADER -->
      <tr>
        <td style="width:100%">
          <div style="padding:5px;">
            <div style="width:100%">
                <span class="agendaTitle" ng-click="showItemMap[item.id]=!showItemMap[item.id]">
                    {{item.number}}.
                    <i ng-show="item.topicLink" class="fa fa-lightbulb-o"></i>
                    {{item.subject}} </span>  &nbsp;
<%if (isLoggedIn) { %>
                <span class="dropdown">
                    <button class="dropdown-toggle specCaretBtn" type="button"  d="menu"
                        data-toggle="dropdown"> <span class="caret"></span> </button>
                    <ul class="dropdown-menu" role="menu" aria-labelledby="menu">
                      <li role="presentation">
                          <a role="menuitem" ng-click="startItemDetailEdit(item)">
                          <i class="fa fa-cogs"></i>
                          Item Settings</a></li>
                      <li role="presentation">
                          <a role="menuitem" ng-click="moveItem(item,-1)"><i class="fa fa-arrow-up"></i>
                             Move Up</a></li>
                      <li role="presentation">
                          <a role="menuitem" ng-click="moveItem(item,1)"><i class="fa fa-arrow-down"></i>
                             Move Down</a></li>
                      <li role="presentation">
                          <a role="menuitem" ng-click="startEditLockDescription(item)"><i class="fa fa-pencil-square-o"></i>   Edit Description</a></li>
                      <li role="presentation">
                          <a role="menuitem" ng-click="openAttachDocument(item)"><i class="fa fa-book"></i>
                             Docs Add/Remove</a></li>
                      <li role="presentation">
                          <a role="menuitem" ng-click="openAttachAction(item)"><i class="fa fa-flag"></i>
                             Action Items Add/Remove</a></li>
                      <li role="presentation">
                          <a role="menuitem" ng-click="toggleReady(item)"><i class="fa fa-thumbs-o-up"></i>
                             Toggle Ready Flag</a></li>
                      <li role="presentation">
                          <a role="menuitem" ng-click="openAttachTopics(item)"><i class="fa fa-lightbulb-o"></i>
                              <span ng-hide="item.topicLink">Set</span>
                              <span ng-show="item.topicLink">Change</span>
                              Discussion Topic</a></li>
                      <li role="presentation">
                          <a role="menuitem" ng-click="moveItemToBacklog(item)"><i class="fa fa-trash"></i>
                              Remove Item</a></li>

                   </ul>
                </span>
                <span style="float:right" ng-hide="item.readyToGo || isCompleted()" >
                    <img src="<%=ar.retPath%>assets/goalstate/agenda-not-ready.png"
                         ng-click="toggleReady(item)"
                         title="Indicates that the agenda item does NOT have all of the documents, presentations, and is full prepared for the meeting."
                         style="width:24px;height=24px;float:right">
                </span>
                <span style="float:right" ng-show="item.readyToGo && !isCompleted()"  >
                    <img src="<%=ar.retPath%>assets/goalstate/agenda-ready-to-go.png"
                         ng-click="toggleReady(item)"
                         title="Indicates that the agenda item has all of the documents, presentations, and is full prepared for the meeting."
                         style="width:24px;height=24px">
                </span>
<% } %>
            </div>
            <div>
                <i ng-click="startItemDetailEdit(item)">
                {{item.schedule | date: 'HH:mm'}} ({{item.duration}} minutes)<span ng-repeat="pres in item.presenterList">, {{pres.name}}</span></i>
            </div>
          </div>

          <div ng-show="editItemDetailsMap[item.id]" class="well" style="margin:20px">
            <div class="form-inline form-group">
                Linked Topic: <button ng-repeat="topic in itemTopics(item)" ng-click="visitTopic(item)"
                    class="btn btn-sm btn-default btn-raised" placeholder="Enter Agenda Item Name">
                    {{topic.subject}}</button>
                <button ng-click="openAttachTopics(item)" class="btn btn-primary btn-raised">
                    <span ng-hide="item.topicLink">Set</span>
                    <span ng-show="item.topicLink">Change</span> Topic
                </button>
            </div>
            <div class="form-inline form-group" ng-hide="item.topicLink">
              Name: <input ng-model="item.subject"  class="form-control" style="width:200px;"
                           placeholder="Enter Agenda Item Name"/>
                    <input type="checkbox"  ng-model="item.isSpacer"
                             class="form-control" style="width:50px;"/>
                    Break Time
            </div>
            <div class="form-inline form-group">
                <tags-input ng-model="item.presenterList"
                          placeholder="Enter user name or id"
                          display-property="name" key-property="uid"
                          on-tag-clicked="toggleSelectedPerson($tag)">
                    <auto-complete source="loadItems($query)"></auto-complete>
                </tags-input>
            </div>
            <div class="form-inline form-group" ng-show="selectedPersonShow">
                   for <b>{{selectedPerson.name}}</b>:
                   <button ng-click="navigateToUser(selectedPerson)" class="btn btn-info">
                       Visit Profile</button>
                   <button ng-click="selectedPersonShow=false" class="btn">
                       Hide</button>
            </div>
            <div class="form-inline form-group">
              Duration: <input ng-model="item.duration"  class="form-control" style="width:50px;"/>
            </div>
            <div class="form-inline form-group">
              <button ng-click="savePendingEdits()" class="btn btn-primary btn-raised">Save</button>
              <button ng-click="revertAllEdits()" class="btn btn-warning btn-raised">Cancel</button>
            </div>
          </div>
        </td>
      </tr>

                          <!--  AGENDA BODY -->
      <tr ng-show="showItemMap[item.id]">
        <td ng-hide="editItemDescMap[item.id] && myUserId == item.lockUser.uid" style="width:100%">
           <button ng-show="item.lockUser.uid && item.lockUser.uid.length>0" class="btn btn-sm" style="background-color:lightyellow;margin-left:20px;">
               {{item.lockUser.name}} is editing.
           </button>
           <div class="leafContent">
             <div ng-bind-html="item.desc"></div>
           </div>
        </td>
        <td ng-show="editItemDescMap[item.id] && myUserId == item.lockUser.uid" style="width:100%">
           <div class="well leafContent">
             <div ng-model="item.desc" ui-tinymce="tinymceOptions"></div>

             <button ng-click="saveEditUnlockDesciption(item)" class="btn btn-primary btn-raised">Save</button>
             <button ng-click="cancelEditUnlockDesciption(item)" class="btn btn-warning btn-raised">Cancel</button>
           </div>
        </td>
      </tr>

                          <!--  AGENDA ATTACHMENTS -->
      <tr ng-show="showItemMap[item.id] && itemTopics(item).length>0" >
        <td>
           <div style="margin:10px;">
              <b>Discussion Topic: </b>
              <span ng-repeat="topic in itemTopics(item)" class="btn btn-sm btn-default btn-raised"  style="margin:4px;"
                   ng-click="navigateToTopic(item.topicLink)">
                    <i class="fa fa-lightbulb-o" style="font-size:130%"></i> {{topic.subject}}
              </span>
           </div>
        </td>
      </tr>
      <tr ng-show="showItemMap[item.id]">
        <td>
           <div style="margin:10px;">
              <b>Attachments: </b>
              <span ng-repeat="doc in itemDocs(item)" class="btn btn-sm btn-default btn-raised"  style="margin:4px;"
                   ng-click="navigateToDoc(doc)">
                      <img src="<%=ar.retPath%>assets/images/iconFile.png"> {{doc.name}}
              </span>
<%if (isLoggedIn) { %>
              <button class="btn btn-sm btn-primary btn-raised" ng-click="openAttachDocument(item)"
                  title="Attach a document">
                  ADD </button>
<% } %>
           </div>
        </td>
      </tr>


                          <!--  AGENDA Action ITEMS -->
      <tr ng-show="showItemMap[item.id] && itemGoals(item).length>0">
        <td style="width:100%">
           <div style="height:15px"></div>
           <table class="table">
           <tr>
              <th></th>
              <th></th>
              <th>Synopsis</th>
              <th>Assignee</th>
              <th>Due</th>
              <th>Prospect</th>
              <th>Status</th>
           </tr>
           <tr ng-repeat="goal in itemGoals(item)" style="margin-left:30px;">
              <td>
                  <span class="dropdown">
                    <button class="dropdown-toggle specCaretBtn" type="button"  d="menu"
                        data-toggle="dropdown"> <span class="caret"></span> </button>
                    <ul class="dropdown-menu" role="menu" aria-labelledby="menu2">
                      <li role="presentation"><a role="menuitem"
                          ng-click="changeGoalState(goal, 'good')">Good</a></li>
                      <li role="presentation"><a role="menuitem"
                          ng-click="changeGoalState(goal, 'ok')">Warning</a></li>
                      <li role="presentation"><a role="menuitem"
                          ng-click="changeGoalState(goal, 'bad')">Trouble</a></li>
                      <li role="presentation" class="divider"></li>
                      <li role="presentation"><a role="menuitem"
                          ng-click="removeGoalFromItem(item, goal)">Remove Action Item</a></li>
                    </ul>
                  </span>
              </td>
              <td style="width:20px;">
              <a href="task{{goal.id}}.htm" class="leafContent"   >
                <img src="<%=ar.retPath%>assets/goalstate/small{{goal.state}}.gif">
              </a>
              </td>
              <td style="max-width:300px;">
              <a href="task{{goal.id}}.htm" >
                {{goal.synopsis}}
              </a>
               ~ {{goal.description}}
              </td>
              <td>
              <span ng-repeat="person in goal.assignTo"> {{person.name}}<br/></span>
              </td>
              <td ng-click="openModalActionItem(item,goal)" style="width:100px;">
              <span ng-show="goal.duedate>=0">{{goal.duedate|date}} </span>
              </td>
              <td style="width:120px;">
                  <img src="<%=ar.retPath%>assets/goalstate/green_off.png" ng-hide="goal.prospects=='good'"
                       title="Good shape" ng-click="changeGoalState(goal, 'good')">
                  <img src="<%=ar.retPath%>assets/goalstate/green_on.png"  ng-show="goal.prospects=='good'"
                       title="Good shape">
                  <img src="<%=ar.retPath%>assets/goalstate/yellow_off.png" ng-hide="goal.prospects=='ok'"
                       title="Warning" ng-click="changeGoalState(goal, 'ok')">
                  <img src="<%=ar.retPath%>assets/goalstate/yellow_on.png"  ng-show="goal.prospects=='ok'"
                       title="Warning" >
                  <img src="<%=ar.retPath%>assets/goalstate/red_off.png" ng-hide="goal.prospects=='bad'"
                       title="In trouble" ng-click="changeGoalState(goal, 'bad')">
                  <img src="<%=ar.retPath%>assets/goalstate/red_on.png"  ng-show="goal.prospects=='bad'"
                       title="In trouble" >
              </td>
              <td style="max-width:300px;" ng-click="openModalActionItem(item,goal)">
                {{goal.status}}
              </td>
           </tr>
           </table>
        </td>
      </tr>

      </table>
      </div>



                          <!--  AGENDA comments -->
      <table ng-show="showItemMap[item.id] && !item.isSpacer" >
      <tr ng-repeat="cmt in item.comments">

          <%@ include file="/spring/jsp/CommentView.jsp"%>

      </tr>
<%if (isLoggedIn) { %>
      <tr>
        <td></td>
        <td>
        <div style="margin:20px;">
            <button ng-click="openCommentCreator(item, 1)" class="btn btn-default btn-raised">
                Create New <i class="fa fa-comments-o"></i> Comment</button>
            <button ng-click="openCommentCreator(item, 2)" class="btn btn-default btn-raised">
                Create New <i class="fa fa-star-o"></i> Proposal</button>
            <button ng-click="openCommentCreator(item, 3)" class="btn btn-default btn-raised">
                Create New <i class="fa fa-question-circle"></i> Round</button>
            <button ng-click="openCommentCreator(item, 5)" class="btn btn-default btn-raised">
                Create New <i class="fa fa-file-code-o"></i> Minutes</button>
        </div>
        </td>
      </tr>
<% } %>
    </table>
    </div>

<%if (isLoggedIn) { %>
    <hr/>
    <div style="margin:20px;" ng-show="meeting.state<3">
        <button ng-click="createAgendaItem()" class="btn btn-primary btn-raised">Create New Agenda Item</button>
    </div>


    Refreshed {{refreshCount}} times.   {{refreshStatus}}<br/>

<% } %>


</div>

<script src="<%=ar.retPath%>templates/ModalActionItemCtrl.js"></script>
<script src="<%=ar.retPath%>templates/CommentModal.js"></script>
<script src="<%=ar.retPath%>templates/ResponseModal.js"></script>
<script src="<%=ar.retPath%>templates/OutcomeModal.js"></script>
<script src="<%=ar.retPath%>templates/DecisionModal.js"></script>
<script src="<%=ar.retPath%>templates/AttachDocumentCtrl.js"></script>
<script src="<%=ar.retPath%>templates/AttachTopicCtrl.js"></script>
<script src="<%=ar.retPath%>templates/AttachActionCtrl.js"></script>
