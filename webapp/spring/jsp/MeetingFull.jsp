<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="org.socialbiz.cog.MeetingRecord"
%><%@page import="org.socialbiz.cog.LicenseForUser"
%><%@page import="org.socialbiz.cog.AccessControl"
%><%@page import="org.socialbiz.cog.MicroProfileMgr"
%><%

    String pageId      = ar.reqParam("pageId");
    NGWorkspace ngw = ar.getCogInstance().getProjectByKeyOrFail(pageId);
    ar.setPageAccessLevels(ngw);
    String meetId          = ar.reqParam("id");
    MeetingRecord mRec     = ngw.findMeeting(meetId);

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
    for (NoteRecord aNote : ngw.getAllNotes()) {
        allTopics.put(aNote.getJSON(ngw));
    }

    JSONArray allLabels = ngw.getJSONLabels();

    JSONArray allPeople = UserManager.getUniqueUsersJSON();

    String docSpaceURL = "";

    if (uProf!=null) {
        LicenseForUser lfu = new LicenseForUser(ar.getUserProfile());
        docSpaceURL = ar.baseURL +  "api/" + ngb.getKey() + "/" + ngw.getKey()
                    + "/summary.json?lic="+lfu.getId();
    }

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
    }
    .comment-inner {
        border: 1px solid lightgrey;
        border-radius:6px;
        padding:5px;
        background-color:white;
    }
</style>

<script>

var app = angular.module('myApp', ['ui.bootstrap', 'ui.tinymce', 'ngSanitize']);
app.controller('myCtrl', function($scope, $http, $modal) {
    $scope.meeting = <%meetingInfo.write(out,2,4);%>;
    $scope.allGoals = <%allGoals.write(out,2,4);%>;
    $scope.attachmentList = <%attachmentList.write(out,2,4);%>;
    $scope.allPeople = <%allPeople.write(out,2,4);%>;
    $scope.allRoles = <%allRoles.write(out,2,4);%>;
    $scope.allLabels = <%allLabels.write(out,2,4);%>;
    $scope.allTopics = <%allTopics.write(out,2,4);%>;


    $scope.newAssignee = "";
    $scope.newAttendee = "";
    $scope.newGoal = {};
    $scope.newPerson = "";
    $scope.myUserId = "<% ar.writeJS(ar.getBestUserId()); %>";
    $scope.actionItemFilter = "";
    $scope.realDocumentFilter = "";
    $scope.showRollCall = false;

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };

    $scope.tinymceOptions = standardTinyMCEOptions();
    $scope.tinymceOptions.height = 300;

    $scope.showItemMap = {};
    $scope.nowEditing = "nothing";
    $scope.editComment = false;

    $scope.showAll = function() {
        $scope.meeting.agenda.map( function(item) {
            $scope.showItemMap[item.id] = true;
        });
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
            item.isBlank = false;
            if (item.subject=="BREAK" || item.subject=="LUNCH" || item.subject=="DINNER") {
                item.isBlank = true;
            }
            runDur = runDur + item.duration;
            runTime = new Date( runTime.getTime() + (item.duration*60000) );
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


    $scope.changeMeetingState = function(newState) {
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
        var itemCopy = {};
        itemCopy.id = agendaItem.id;
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
        console.log("SAVE MEETING: ", readyToSave);
        var postdata = angular.toJson(readyToSave);
        $scope.showError=false;
        var promise = $http.post(postURL ,postdata)
        promise.success( function(data) {
            console.log("---- SERVER: ", data);
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
    $scope.createAgendaItemImmediate = function() {
        var newAgenda = {subject: "New Agenda Item",duration: 10,position:9999,docList:[], actionItems:[]};

        postURL = "agendaAdd.json?id="+$scope.meeting.id;
        var postdata = angular.toJson(newAgenda);
        $scope.showError=false;
        $http.post(postURL ,postdata)
        .success( function(data) {
            $scope.meeting.agenda.push(data);
            $scope.nowEditing=data.id+"x2";
            $scope.editHead=false;
            $scope.editDesc=false;
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };
    $scope.createAgendaItem = function() {
        var newAgenda = {
            subject: "New Agenda Item",
            id:"~new~",
            duration:10,
            position:$scope.meeting.agenda.length+1,
            docList:[],
            presenters:[],
            actionItems:[]
        };
        $scope.meeting.agenda.push(newAgenda);
        $scope.nowEditing=newAgenda.id+"x2";
    };


    $scope.getPeople = function(viewValue) {
        var newVal = [];
        var viewValueLC = viewValue.toLowerCase();
        $scope.allPeople.forEach( function(onePeople) {
            if (onePeople.uid.toLowerCase().indexOf(viewValueLC)>=0) {
                newVal.push(onePeople);
            }
            else if (onePeople.name.toLowerCase().indexOf(viewValueLC)>=0) {
                newVal.push(onePeople);
            }
        });
        return newVal;
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

    $scope.toggleEditor = function(whichone, itemid) {
        var combo = itemid+"x"+whichone;
        if ($scope.nowEditing == combo) {
            $scope.nowEditing = "nothing";
            return;
        }
        if ($scope.nowEditing == "nothing") {
            $scope.nowEditing = combo;
            return;
        }
        $scope.nowEditing = combo;
    }
    $scope.stopEditing =  function() {
        $scope.nowEditing = "nothing";
    }

    $scope.isEditing = function(whichone, itemid) {
        var combo = itemid+"x"+whichone;
        return $scope.nowEditing == combo;
    }

    $scope.refresh = function() {
        if ($scope.meeting.state!=2) {
            $scope.refreshStatus = "No refresh because meeting is not being run";
            return;  //don't set of refresh unless in run mode
        }
        window.setTimeout( function() {$scope.refresh()}, 60000);
        if ($scope.nowEditing != "nothing") {
            $scope.refreshStatus = "No refresh because currently editing";
            return;   //don't refresh when editing
        }
        if ($scope.editComment) {
            $scope.refreshStatus = "No refresh because currently making a comment";
            return;   //don't refresh when editing
        }
        if (true) {
            $scope.refreshStatus = "No refresh because it doesn't work with TinyMCE editor";
            return;   //don't refresh when editing
        }
        $scope.refreshStatus = "Refreshing";
        $scope.putGetMeetingInfo( {} );
        $scope.refreshCount++;
    }
    $scope.refreshCount = 0;
    $scope.refresh();

    $scope.getPresenters = function(item) {
        var res = [];
        $scope.allPeople.map( function(a) {
            item.presenters.map( function(b) {
                if (b == a.uid) {
                    res.push(a);
                }
            });
        });
        return res;
    }
    $scope.addPresenter = function(item, person) {
        var notPresent = true;
        item.presenters.map( function(b) {
            if (b == person.uid) {
                notPresent = false;
            }
        });
        if (notPresent) {
            item.presenters.push(person.uid);
        }
    }
    $scope.removePresenter = function(item, person) {
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

    $scope.findPersonName = function(email) {
        var person = {name: email};
        $scope.allPeople.map( function(item) {
            if (item.uid == email) {
                person = item;
            }
        });
        return person.name;
    }
    $scope.findPerson = function(email) {
        return $scope.allPeople.find( function(item) {
            return (item.uid == email)
        });
    }

    $scope.createMinutes = function() {
        var postURL = "createMinutes.json?id="+$scope.meeting.id;
        var postdata = angular.toJson("");
        $scope.showError=false;
        $http.post(postURL ,postdata)
        .success( function(data) {
            $scope.meeting = data;
            $scope.showInput=false;
            $scope.extractDateParts();
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };

    $scope.startEdit = function(item) {
        var rec = {};
        rec.id = item.id;
        rec.setLock = true;
        var saveRecord = {};
        saveRecord.agenda = [rec];
        $scope.putGetMeetingInfo(saveRecord);
        $scope.nowEditing=item.id+"x1"
    }
    $scope.cancelEdit = function(item) {
        var rec = {};
        rec.id = item.id;
        rec.clearLock = true;
        var saveRecord = {};
        saveRecord.agenda = [rec];
        $scope.putGetMeetingInfo(saveRecord);
        $scope.nowEditing="nothing";
    }
    $scope.startNewComment = function(item, theType, cmt) {
        item.newComment = {};
        item.newComment.choices = ["Consent", "Object"];
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
        if (cmt.commentType == 1) {
            //simple comments go all the way to closed
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
        cmt.choices = ["Consent", "Object"]
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
        var localId = null;
        $scope.allTopics.forEach( function(oneTopic) {
            if (topicId == oneTopic.universalid) {
                localId = oneTopic.id;
            }
            else if (topicId == oneTopic.id) {
                localId = oneTopic.id;
            }
        });
        if (localId) {
            window.location="noteZoom"+localId+".htm";
        }
        else {
            alert("Sorry, can't seem to find a discussion topic with the id: "+topicId);
        }
    }

    $scope.mySitch = [];

    $scope.extractPeopleSituation = function() {
        var selRole = $scope.allLabels.find( function(item) {
            return item.name === $scope.meeting.targetRole;
        });
        var rez = [];
        $scope.mySitch = [];
        selRole.players.forEach( function(item) {
            var current = $scope.meeting.rollCall.find( function(rc) {
                return rc.uid === item.uid;
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
        return ($scope.mySitch.length>0 && $scope.meeting.state <= 1);
    }
    $scope.editAttendees = function() {
        return ($scope.meeting.state == 2);
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
        return $scope.meeting.attended.map( function(item) {
            return $scope.findPerson(item);
        });
    }

    $scope.saveSituation = function() {
        $scope.savePartialMeeting(['rollCall']);
    }

    $scope.openModalActionItem = function (item, goal) {

        var modalInstance = $modal.open({
          animation: false,
          templateUrl: '<%=ar.retPath%>templates/ModalActionItem.html',
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
        return item.comments.find( function(item) {
            return item.time == timeStamp;
        });
    }

    $scope.getResponse = function(cmt) {
        var selected = cmt.responses.filter( function(item) {
            return item.user=="<%ar.writeJS(currentUser);%>";
        });
        return selected;
    }
    $scope.noResponseYet = function(cmt) {
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
        console.log("swapping "+thisPos+" with "+otherPos+"");
        $scope.meeting.agenda.forEach( function(x) {
            if (x.position==otherPos) {
                x.position=thisPos;
            }
        });
        item.position=otherPos;
        $scope.saveMeeting();
    }

    $scope.openResponseEditor = function (cmt) {

        console.log("ITEM COMMENT", cmt);
        if (cmt.choices.length==0) {
            console.log("This comment has no choices on it!");
            cmt.choices = ["Consent", "Object"];
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
            templateUrl: '<%=ar.retPath%>templates/ResponseModal.html?d='+new Date().getTime(),
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

    $scope.openCommentCreator = function(item, type, replyTo, defaultBody) {
        var newComment = {};
        newComment.time = -1;
        newComment.commentType = type;
        newComment.state = 11;
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

        var modalInstance = $modal.open({
            animation: false,
            templateUrl: '<%=ar.retPath%>templates/CommentModal.html?t=<%=System.currentTimeMillis()%>',
            controller: 'CommentModalCtrl',
            size: 'lg',
            backdrop: "static",
            resolve: {
                cmt: function () {
                    return JSON.parse(JSON.stringify(cmt));
                }
            }
        });

        modalInstance.result.then(function (returnedCmt) {
            var cleanCmt = {};
            cleanCmt.time = cmt.time;
            cleanCmt.html = returnedCmt.html;
            cleanCmt.state = returnedCmt.state;
            cleanCmt.commentType = returnedCmt.commentType;
            if (cleanCmt.state==12) {
                if (cleanCmt.commentType==1 || cleanCmt.commentType==5) {
                    cleanCmt.state=13;
                }
            }
            cleanCmt.replyTo = returnedCmt.replyTo;
            $scope.saveComment(item, cleanCmt);
        }, function () {
            //cancel action - nothing really to do
        });
    };

    $scope.openOutcomeEditor = function (item, cmt) {

        var modalInstance = $modal.open({
            animation: false,
            templateUrl: '<%=ar.retPath%>templates/OutcomeModal.html?t=<%=System.currentTimeMillis()%>',
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
            templateUrl: '<%=ar.retPath%>templates/DecisionModal.html',
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
            templateUrl: '<%=ar.retPath%>templates/AttachDocument.html?t=<%=System.currentTimeMillis()%>',
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
            templateUrl: '<%=ar.retPath%>templates/AttachTopic.html',
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
            templateUrl: '<%=ar.retPath%>templates/AttachAction.html?t=<%=System.currentTimeMillis()%>',
            controller: 'AttachActionCtrl',
            size: 'lg',
            resolve: {
                selectedActions: function () {
                    return JSON.parse(JSON.stringify(item.actionItems));
                },
                allActions: function() {
                    return $scope.allGoals;
                },
                allPeople: function() {
                    return $scope.allPeople;
                }
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

    <div class="generalHeading" style="height:40px">
<%if (isLoggedIn) { %>    
        <div  style="float:left">
            <span class="dropdown">
                <button class="btn btn-default dropdown-toggle" type="button" id="menu1" data-toggle="dropdown" style="{{meetingStateStyle(meeting.state)}}">
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
        </div>
        <div class="rightDivContent" style="margin-right:100px;">
          <span class="dropdown">
            <button class="btn btn-default dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
            Options: <span class="caret"></span></button>
            <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
              <li role="presentation"><a role="menuitem" tabindex="-1"
                  href="#" ng-click="showAll()" >Show All Items</a></li>
              <li role="presentation"><a role="menuitem" tabindex="-1"
                  href="#" ng-click="showRollCall=!showRollCall" >Show Roll Call</a></li>
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
              <li role="presentation" ng-show="meeting.minutesId"><a role="menuitem"  target="_blank"
                  href="<%=ar.retPath%>t/editNote.htm?pid=<%ar.writeURLData(pageId);%>&nid={{meeting.minutesLocalId}}">Edit Minutes</a></li>
              <li role="presentation" class="divider"></li>
              <li role="presentation"><a role="menuitem" tabindex="-1"
                  href="cloneMeeting.htm?id={{meeting.id}}">Clone Meeting</a></li>
              <li role="presentation"><a role="menuitem"
                  href="meetingList.htm">List All Meetings</a></li>
            </ul>
          </span>

        </div>
<% } %>        
    </div>


    <table>
      <tr>
        <td style="width:100%">
          <div class="leafContent">
            <span style="font-size:150%;font-weight: bold;">
                <i class="fa fa-gavel" style="font-size:130%"></i>
                {{meeting.name}} @ {{meeting.startTime|date: "h:mma 'on' dd-MMM-yyyy"}}
            </span>
<%if (isLoggedIn) { %>
            <span ng-show="meeting.state<3">
                (
                <i class="fa fa-cogs meeting-icon" ng-click="toggleEditor(5,'0')"></i>
                <i class="fa fa-pencil-square-o meeting-icon" ng-click="toggleEditor(6,'0')"></i>
                )
            </span>
<% } %>            
          </div>
           <div class="well leafContent" ng-show="isEditing(5,'0')">
             <table>
                <tr><td style="height:10px"></td></tr>
                <tr id="trspath">
                    <td class="gridTableColummHeader">Type:</td>
                    <td style="width:20px;"></td>
                    <td colspan="2" class="form-inline form-group">
                        <input type="radio" ng-model="meeting.meetingType" value="1"
                            class="form-control" /> Circle Meeting   &nbsp
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
                        <span ng-show="meeting.reminderSent==0">Minutes before the meeting</span>
                        <span ng-hide="meeting.reminderSent==0">Was sent {{meeting.reminderSent|date:'M/d/yy H:mm'}}
                            <button ng-click="meeting.reminderSent=0" class="btn btn-default">Send Again</button>
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
                        <button ng-click="savePartialMeeting(['name','startTime','targetRole','duration','reminderTime','meetingType','reminderSent'])" class="btn btn-danger">Save</button>
                        <button ng-click="revertAllEdits()" class="btn btn-danger">Cancel</button>
                    </td>
                </tr>


              </table>
           </div>
        </td>
      </tr>
      <tr>
        <td ng-hide="isEditing(6,'0')" style="width:100%">
           <div class="leafContent">
             <div ng-bind-html="meeting.meetingInfo"></div>
           </div>
        </td>
        <td ng-show="isEditing(6,'0')" style="width:100%">
            <div class="well leafContent">
                <div ui-tinymce="tinymceOptions" ng-model="meeting.meetingInfo"
                     class="leafContent" style="min-height:200px;" ></div>
                <button ng-click="savePartialMeeting(['meetingInfo'])" class="btn btn-danger">Save</button>
                <button ng-click="revertAllEdits()" class="btn btn-danger">Cancel</button>
            </div>
        </td>
      </tr>
    </table>

<!-- THIS IS THE ROLL CALL SECTION -->


    <div class="comment-outer" style="margin:40px" ng-show="showSelfRegister()">
      <div><h2 style="margin:5px"><% ar.writeHtml(currentUserName); %>, will you attend?</h2></div>
      <div ng-repeat="sitch in mySitch" class="comment-inner">
        <div class="form-inline form-group" style="margin:20px">
            <select ng-model="sitch.attend" class="form-control">
                <option>Unknown</option>
                <option>Yes</option>
                <option>Maybe</option>
                <option>No</option>
            </select>
            Details:
            <input type="text" ng-model="sitch.situation" class="form-control" style="width:400px;">
            <button class="btn btn-primary" ng-click="saveSituation()">Save</button>
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
            <button class="btn btn-primary" ng-click="addYouself()">Add Yourself</button> &nbsp;
            <button class="btn btn-primary" ng-click="addAttendee()">Add By Email Address: </button>
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
       Official Minutes:
      <span class="btn btn-sm btn-default"  style="margin:4px;" ng-click="navigateToTopic(meeting.minutesLocalId)">
           Minutes
      </span>
    </div>

<%if (!isLoggedIn) { %>
    <div class="leafContent">
        Log in to see more details about this meeting.
    </div>
<% } %>


    <div class="comment-outer" ng-show="showRollCall">
      <div style="float:right" ng-click="showRollCall=false"><i class="fa fa-close"></i></div>
      <div>Roll Call</div>
      <table class="table">
      <tr>
          <th>Name</th>
          <th>Attending</th>
          <th>Situation</th>
      </tr>
      <tr class="comment-inner" ng-repeat="pers in peopleStatus">
          <td>{{pers.name}}</td>
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

<div ng-repeat="item in meeting.agenda">
    <div class="agendaItemBlank" ng-show="item.isBlank">
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
                          <a role="menuitem" ng-click="toggleEditor(2,item.id)"><i class="fa fa-cogs"></i> Item Settings</a></li>
                      <li role="presentation">
                          <a role="menuitem" ng-click="moveItem(item,-1)"><i class="fa fa-arrow-up"></i> Move Up</a></li>
                      <li role="presentation">
                          <a role="menuitem" ng-click="moveItem(item,1)"><i class="fa fa-arrow-down"></i> Move Down</a></li>
                    </ul>
                </span>
<% } %>
                <span>
                    <i>{{item.schedule | date: 'hh:mm'}} ({{item.duration}} minutes)</i>
                </span>
        </div>
      </div>
    </div>
    <div class="agendaItemFull"  ng-hide="item.isBlank">
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
                          <a role="menuitem" ng-click="toggleEditor(2,item.id)"><i class="fa fa-cogs"></i> Item Settings</a></li>
                      <li role="presentation">
                          <a role="menuitem" ng-click="moveItem(item,-1)"><i class="fa fa-arrow-up"></i> Move Up</a></li>
                      <li role="presentation">
                          <a role="menuitem" ng-click="moveItem(item,1)"><i class="fa fa-arrow-down"></i> Move Down</a></li>
                      <li role="presentation">
                          <a role="menuitem" ng-click="startEdit(item)"><i class="fa fa-pencil-square-o"></i> Edit Description</a></li>
                      <li role="presentation">
                          <a role="menuitem" ng-click="openAttachDocument(item)"><i class="fa fa-book"></i> Docs Add/Remove</a></li>
                      <li role="presentation">
                          <a role="menuitem" ng-click="openAttachAction(item)"><i class="fa fa-flag"></i> Action Items Add/Remove</a></li>
                      <li role="presentation">
                          <a role="menuitem" ng-click="toggleReady(item)"><i class="fa fa-thumbs-o-up"></i> Toggle Ready Flag</a></li>
                      <li role="presentation">
                          <a role="menuitem" ng-click="openAttachTopics(item)"><i class="fa fa-lightbulb-o"></i> Set Discussion Topic</a></li>

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
                <i>{{item.schedule | date: 'hh:mm'}} ({{item.duration}} minutes)</i><span ng-repeat="pres in getPresenters(item)">, {{pres.name}}</span>
            </div>
          </div>

          <div ng-show="isEditing(2,item.id)" class="well" style="margin:20px">
            <div class="form-inline form-group">
                Linked Topic: <button ng-repeat="topic in itemTopics(item)" ng-click="visitTopic(item)" class="btn btn-sm btn-default">
                    {{topic.subject}}</button>
                <button ng-click="openAttachTopics(item)" class="btn btn-primary">Change Topic</button>
            </div>
            <div class="form-inline form-group" ng-hide="item.topicLink">
              Name: <input ng-model="item.subject"  class="form-control" style="width:200px;"/>
            </div>
            <div class="form-inline form-group">
              Presenters:
                  <span class="dropdown" ng-repeat="person in getPresenters(item)">
                    <button class="btn btn-sm dropdown-toggle" type="button" id="menu1"
                       data-toggle="dropdown" style="margin:2px;padding: 2px 5px;font-size: 11px;">
                       {{person.name}}</button>
                    <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
                       <li role="presentation"><a role="menuitem" title="{{person.name}} {{person.uid}}"
                          ng-click="removePresenter(item, person)">Remove Presenter:<br/>{{person.name}}<br/>{{person.uid}}</a></li>
                    </ul>
                  </span>
                  <span >
                    <button class="btn btn-sm btn-primary" ng-click="showAddPresenter=!showAddPresenter"
                        style="margin:2px;padding: 2px 5px;font-size: 11px;">+</button>
                  </span>
            </div>
            <div class="form-inline form-group" ng-show="showAddPresenter">
                <button ng-click="addPresenter(item,newPerson);showAddPresenter=false" class="form-control btn btn-primary">
                    Add This Presenter</button>
                <input type="text" ng-model="newPerson"  class="form-control"
                    placeholder="Enter Email Address" style="width:350px;"
                    typeahead="person as person.name for person in getPeople($viewValue) | limitTo:12">
            </div>
            <div class="form-inline form-group">
              Duration: <input ng-model="item.duration"  class="form-control" style="width:50px;"/>
            </div>
            <div class="form-inline form-group">
              <button ng-click="saveAgendaItemParts(item, ['subject','duration','presenters'])" class="btn btn-danger">Save</button>
              <button ng-click="revertAllEdits()" class="btn btn-danger">Cancel</button>
            </div>
          </div>
        </td>
      </tr>

                          <!--  AGENDA BODY -->
      <tr ng-show="showItemMap[item.id] || isEditing(1,item.id)">
        <td ng-hide="isEditing(1,item.id) && myUserId == item.lockUser.uid" style="width:100%">
           <button ng-show="item.lockUser.uid && item.lockUser.uid.length>0" class="btn btn-sm" style="background-color:lightyellow;margin-left:20px;">
               {{item.lockUser.name}} is editing.
           </button>
           <div class="leafContent">
             <div ng-bind-html="item.desc"></div>
           </div>
        </td>
        <td ng-show="isEditing(1,item.id) && myUserId == item.lockUser.uid" style="width:100%">
           <div class="well leafContent">
             <div ng-model="item.desc" ui-tinymce="tinymceOptions"></div>

             <button ng-click="saveAgendaItemParts(item, ['desc'])" class="btn btn-danger">Save</button>
             <button ng-click="cancelEdit(item)" class="btn btn-danger">Cancel</button>
           </div>
        </td>
      </tr>

                          <!--  AGENDA ATTACHMENTS -->
      <tr ng-show="showItemMap[item.id] && !isEditing(2,item.id)" >
        <td>
           <div style="margin:10px;">
              <b>Discussion Topic: </b>
              <span ng-repeat="topic in itemTopics(item)" class="btn btn-sm btn-default"  style="margin:4px;"
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
              <span ng-repeat="doc in itemDocs(item)" class="btn btn-sm btn-default"  style="margin:4px;"
                   ng-click="navigateToDoc(doc)">
                      <img src="<%=ar.retPath%>assets/images/iconFile.png"> {{doc.name}}
              </span>
<%if (isLoggedIn) { %>
              <button class="btn btn-sm btn-primary" ng-click="openAttachDocument(item)"
                  title="Attach a document">
                  ADD </button>
<% } %>
           </div>
        </td>
      </tr>


                          <!--  AGENDA Action ITEMS -->
      <tr ng-show="showItemMap[item.id] && itemGoals(item).length>0">
        <td ng-hide="isEditing(4,item.id)" style="width:100%">
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
        <td ng-show="isEditing(4,item.id)" style="width:100%">
            <div class="well generalSettings">
                <table>
                   <tr>
                        <td class="gridTableColummHeader">Synopsis:</td>
                        <td style="width:20px;"></td>
                        <td colspan="2">
                            <input type="text" ng-model="newGoal.synopsis" class="form-control" placeholder="What should be done">
                        </td>
                   </tr>
                   <tr><td style="height:10px"></td></tr>
                   <tr>
                        <td class="gridTableColummHeader">Assignee:</td>
                        <td style="width:20px;"></td>
                        <td colspan="2">
                            <input type="text" ng-model="newGoal.assignee" class="form-control" placeholder="Who should do it"
                               typeahead="person as person.name for person in getPeople($viewValue) | limitTo:12">
                        </td>
                    </tr>
                    <tr><td style="height:10px"></td></tr>
                    <tr>
                        <td class="gridTableColummHeader">Description:</td>
                        <td style="width:20px;"></td>
                        <td colspan="2">
                            <textarea type="text" ng-model="newGoal.description" class="form-control"
                                style="width:450px;height:100px" placeholder="Details"></textarea>
                        </td>
                    </tr>
                    <tr><td style="height:10px"></td></tr>
                    <tr>
                        <td class="gridTableColummHeader">Due Date:</td>
                        <td style="width:20px;"></td>
                        <td colspan="2">
                            <input type="text"
                                style="width:150;margin-top:10px;"
                                class="form-control"
                                datepicker-popup="dd-MMMM-yyyy"
                                ng-model="dummyDate1"
                                is-open="datePickOpen1"
                                min-date="minDate"
                                datepicker-options="datePickOptions"
                                date-disabled="datePickDisable(date, mode)"
                                ng-required="true"
                                ng-click="openDatePicker1($event)"
                                close-text="Close"/>
                        </td>
                    </tr>
                    <tr><td style="height:10px"></td></tr>
                    <tr>
                        <td class="gridTableColummHeader"></td>
                        <td style="width:20px;"></td>
                        <td colspan="2">
                            <button class="btn btn-primary" ng-click="createActionItem(item)">Create New Action Item</button>
                            <button class="btn btn-primary" ng-click="revertAllEdits()">Cancel</button>
                        </td>
                    </tr>
                </table>
            </div>
        </td>
      </tr>

      </table>
      </div>

                          <!--  AGENDA comments -->
      <table ng-show="showItemMap[item.id] && !item.isBlank" >
      <tr ng-repeat="cmt in item.comments">
           <td style="width:50px;vertical-align:top;padding:15px;">
               <img id="cmt{{cmt.time}}" class="img-circle" style="height:35px;width:35px;" src="<%=ar.retPath%>/users/{{cmt.userKey}}.jpg">
           </td>
           <td>
               <div class="comment-outer"  style="{{stateStyle(cmt)}}">
                   <div>
                       <div class="dropdown" style="float:left">
                           <button class="dropdown-toggle specCaretBtn" type="button"  d="menu"
                               data-toggle="dropdown"> <span class="caret"></span> </button>
                           </button>
                           <ul class="dropdown-menu" role="menu" aria-labelledby="menu">
                              <li role="presentation" ng-show="cmt.user=='<%ar.writeJS(currentUser);%>'">
                                  <a role="menuitem" ng-click="openCommentEditor(item,cmt)">Edit Your {{commentTypeName(cmt)}}</a></li>
                              <li role="presentation" ng-show="cmt.commentType==2 || cmt.commentType==3">
                                  <a role="menuitem" ng-click="openResponseEditor(cmt)">Create/Edit Response:</a></li>
                              <li role="presentation" ng-show="cmt.state==11 && cmt.user=='<%ar.writeJS(currentUser);%>'">
                                  <a role="menuitem" ng-click="postComment(item, cmt)">Post Your {{commentTypeName(cmt)}}</a></li>
                              <li role="presentation" ng-show="cmt.state==11 && cmt.user=='<%ar.writeJS(currentUser);%>'">
                                  <a role="menuitem" ng-click="deleteComment(item, cmt)">Delete Your {{commentTypeName(cmt)}}</a></li>
                              <li role="presentation" ng-show="cmt.state==12 && cmt.user=='<%ar.writeJS(currentUser);%>'">
                                  <a role="menuitem" ng-click="closeComment(item, cmt)">Close Your {{commentTypeName(cmt)}}</a></li>
                              <li role="presentation" ng-show="cmt.commentType==1">
                                  <a role="menuitem" ng-click="openCommentCreator(item,1,cmt.time)">Reply</a></li>
                              <li role="presentation" ng-show="cmt.commentType==2 || cmt.commentType==3">
                                  <a role="menuitem" ng-click="openCommentCreator(item,2,cmt.time,cmt.html)">Make Modified Proposal</a></li>
                              <li role="presentation" ng-show="cmt.commentType==2">
                                  <a role="menuitem" ng-click="openDecisionEditor(item, cmt)">Create New Decision</a></li>
                           </ul>
                       </div>

                       <span ng-show="cmt.commentType==1"><i class="fa fa-comments-o" style="font-size:130%"></i></span>
                       <span ng-show="cmt.commentType==2"><i class="fa fa-star-o" style="font-size:130%"></i></span>
                       <span ng-show="cmt.commentType==3"><i class="fa fa-question-circle" style="font-size:130%"></i></span>
                      <span ng-show="cmt.commentType==5"><i class="fa fa-file-code-o" style="font-size:130%"></i></span>
                       &nbsp; {{cmt.time | date}} -
                       <a href="<%=ar.retPath%>v/{{cmt.userKey}}/userSettings.htm">
                          <span class="red">{{cmt.userName}}</span>
                       </a>
                       <span ng-hide="cmt.emailSent">-email pending-</span>
                         <span ng-show="cmt.replyTo">
                             <span ng-show="cmt.commentType==1">In reply to
                                 <a style="border-color:white;" href="#cmt{{cmt.replyTo}}">
                                 <i class="fa fa-comments-o"></i> {{findComment(item,cmt.replyTo).userName}}</a></span>
                             <span ng-show="cmt.commentType>1">Based on
                                 <a style="border-color:white;" href="#cmt{{cmt.replyTo}}">
                                 <i class="fa fa-star-o"></i> {{findComment(item,cmt.replyTo).userName}}</a></span>
                         </span>

                   </div>
                   <div class="leafContent comment-inner">
                       <div ng-bind-html="cmt.html"></div>
                   </div>

                   <table style="min-width:500px;" ng-show="cmt.commentType==2 || cmt.commentType==3">
                   <tr ng-repeat="resp in cmt.responses">
                       <td style="padding:5px;max-width:100px;">
                           <div ng-show="cmt.commentType==2"><b>{{resp.choice}}</b></div>
                           <div>{{resp.userName}}</div>
                       </td>
                       <td>
                         <span ng-show="resp.user=='<%ar.writeJS(currentUser);%>'" ng-click="openResponseEditor(cmt)" style="cursor:pointer;">
                           <a href="#cmt{{cmt.time}}" title="Edit your response to this proposal"><i class="fa fa-edit"></i></a>
                         </span>
                       </td>
                       <td style="padding:5px;">
                          <div class="leafContent comment-inner" ng-bind-html="resp.html"></div>
                       </td>
                   </tr>
                   <tr ng-show="noResponseYet(cmt) && cmt.state==12">
                       <td style="padding:5px;max-width:100px;">
                           <b>????</b>
                           <br/>
                           <% ar.writeHtml(currentUserName); %>
                       </td>
                       <td>
                         <span ng-click="openResponseEditor(cmt)" style="cursor:pointer;">
                           <a href="#" title="Create a response to this proposal"><i class="fa fa-edit"></i></a>
                         </span>
                       </td>
                       <td style="padding:5px;">
                          <div class="leafContent comment-inner"><i>Click edit button to register a response.</i></div>
                       </td>
                   </tr>
                   </table>
                   <div class="leafContent comment-inner" ng-show="cmt.state==13 && (cmt.commentType==2 || cmt.commentType==3)">
                       <div ng-bind-html="cmt.outcome"></div>
                   </div>
                   <div ng-show="cmt.replies.length>0 && cmt.commentType>1">
                       See proposals:
                       <span ng-repeat="reply in cmt.replies"><a href="#cmt{{reply}}" >
                           <i class="fa fa-star-o"></i> {{findComment(item,reply).userName}}</a> </span>
                   </div>
                   <div ng-show="cmt.replies.length>0 && cmt.commentType==1">
                       See replies:
                       <span ng-repeat="reply in cmt.replies"><a href="#cmt{{reply}}" >
                           <i class="fa fa-comments-o"></i> {{findComment(item,reply).userName}}</a> </span>
                   </div>
                   <div ng-show="cmt.decision">
                       See Linked Decision: <a href="decisionList.htm#DEC{{cmt.decision}}">#{{cmt.decision}}</a>
                   </div>

               </div>
           </td>
      </tr>
<%if (isLoggedIn) { %>
      <tr>
        <td></td>
        <td>
        <div style="margin:20px;">
            <button ng-click="openCommentCreator(item, 1)" class="btn btn-default">
                Create New <i class="fa fa-comments-o"></i> Comment</button>
            <button ng-click="openCommentCreator(item, 2)" class="btn btn-default">
                Create New <i class="fa fa-star-o"></i> Proposal</button>
            <button ng-click="openCommentCreator(item, 3)" class="btn btn-default">
                Create New <i class="fa fa-question-circle"></i> Round</button>
            <button ng-click="openCommentCreator(item, 5)" class="btn btn-default">
                Create New <i class="fa fa-file-code-o"></i> Minutes</button>
        </div>
        </td>
      </tr>
<% } %>
    </table>
    </div>

<%if (isLoggedIn) { %>
    <hr/>
    <div style="margin:20px;">
        <button ng-click="createAgendaItem()" class="btn">Create New Agenda Item</button>
    </div>


    Refreshed {{refreshCount}} times.   {{refreshStatus}}<br/>
    reminder sent {{meeting.reminderSent | date:'M/d/yy H:mm'}}

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



