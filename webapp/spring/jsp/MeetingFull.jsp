<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="org.socialbiz.cog.MeetingRecord"
%><%@page import="org.socialbiz.cog.MicroProfileMgr"
%><%

    ar.assertLoggedIn("Must be logged in to see anything about a meeting");

    String pageId      = ar.reqParam("pageId");
    NGPage ngp = ar.getCogInstance().getProjectByKeyOrFail(pageId);
    ar.setPageAccessLevels(ngp);
    NGBook ngb = ngp.getSite();
    UserProfile uProf = ar.getUserProfile();
    String currentUser = uProf.getUniversalId();
    String currentUserName = uProf.getName();

    String meetId          = ar.reqParam("id");
    MeetingRecord mRec     = ngp.findMeeting(meetId);
    String targetRole = mRec.getTargetRole();
    if (targetRole==null || targetRole.length()==0) {
        mRec.setTargetRole(ngp.getPrimaryRole().getName());
    }
    JSONObject meetingInfo = mRec.getFullJSON(ar, ngp);
    JSONArray attachmentList = ngp.getJSONAttachments(ar);
    JSONArray goalList     = ngp.getJSONGoals();

    JSONArray allRoles = new JSONArray();
    for (NGRole aRole : ngp.getAllRoles()) {
        allRoles.put(aRole.getName());
    }

    JSONArray allLabels = ngp.getJSONLabels();

    JSONArray allPeople = UserManager.getUniqueUsersJSON();

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

<link href="<%=ar.retPath%>jscript/textAngular.css" rel="stylesheet" />
<script src="<%=ar.retPath%>jscript/textAngular-rangy.min.js"></script>
<script src="<%=ar.retPath%>jscript/textAngular-sanitize.min.js"></script>
<script src="<%=ar.retPath%>jscript/textAngular.min.js"></script>

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

<script type="text/javascript">

var app = angular.module('myApp', ['ui.bootstrap', 'textAngular']);
app.controller('myCtrl', function($scope, $http, $modal) {
    $scope.meeting = <%meetingInfo.write(out,2,4);%>;
    $scope.goalList = <%goalList.write(out,2,4);%>;
    $scope.attachmentList = <%attachmentList.write(out,2,4);%>;
    $scope.allPeople = <%allPeople.write(out,2,4);%>;
    $scope.allRoles = <%allRoles.write(out,2,4);%>;
    $scope.allLabels = <%allLabels.write(out,2,4);%>;

    $scope.newAssignee = "";
    $scope.newGoal = {};
    $scope.newPerson = "";
    $scope.myUserId = "<% ar.writeJS(ar.getBestUserId()); %>";
    $scope.actionItemFilter = "";
    $scope.realDocumentFilter = "";

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };


    $scope.showItemMap = {};
    $scope.nowEditing = "nothing";
    $scope.editComment = false;
    $scope.sortItems = function() {
        $scope.meeting.agenda.sort( function(a, b){
            return a.position - b.position;
        });
        return $scope.meeting.agenda;
    };

    $scope.showAll = function() {
        $scope.meeting.agenda.map( function(item) {
            $scope.showItemMap[item.id] = true;
        });
    }
    $scope.showAll();

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
    $scope.extractDateParts = function() {
        $scope.meetingTime = new Date($scope.meeting.startTime);
        $scope.meetingHour = $scope.meetingTime.getHours();
        $scope.meetingMinutes = $scope.meetingTime.getMinutes();
        $scope.sortItems();
    };
    $scope.extractDateParts();

    $scope.sortItems = function() {
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
        }
        $scope.meeting.endTime = runTime;
        $scope.meeting.totalDuration = runDur;
        return $scope.meeting.agenda;
    };

    $scope.itemDocs = function(item) {
        var res = [];
        for (var j=0; j<item.docList.length; j++) {
            var docId = item.docList[j];
            for(var i=0; i<$scope.attachmentList.length; i++) {
                var oneDoc = $scope.attachmentList[i];
                if (oneDoc.universalid == docId) {
                    res.push(oneDoc);
                }
            }
        }
        return res;
    }
    $scope.filterDocs = function(filter) {
        var res = [];
        var filterlc = filter.toLowerCase();
        for(var i=0; i<$scope.attachmentList.length; i++) {
            var oneDoc = $scope.attachmentList[i];
            if (filterlc.length==0 || oneDoc.name.toLowerCase().indexOf(filterlc)>=0) {
                res.push(oneDoc);
            }
            else if (oneDoc.description.toLowerCase().indexOf(filterlc)>=0) {
                res.push(oneDoc);
            }
        }
        return res;
    }
    $scope.itemGoals = function(item) {
        var res = [];
        for (var j=0; j<item.actionItems.length; j++) {
            var aiId = item.actionItems[j];
            for(var i=0; i<$scope.goalList.length; i++) {
                var oneGoal = $scope.goalList[i];
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
        for(var i=0; i<$scope.goalList.length; i++) {
            var oneGoal = $scope.goalList[i];
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
    $scope.itemHasDoc = function(item, doc) {
        for (var j=0; j<item.docList.length; j++) {
            if (item.docList[j] == doc.universalid) {
                return true;
            }
        }
        return false;
    }
    $scope.addDocToItem = function(item, doc, filter) {
        $scope.realDocumentFilter = filter;
        if (!$scope.itemHasDoc(item, doc)) {
            item.docList.push(doc.universalid);
        }
        $scope.saveAgendaItem(item);
    }
    $scope.foo = function(val) {
        alert("foo is ("+val+")");
    }
    $scope.removeDocFromItem = function(item, doc, filter) {
        //this is the strangest thing.  If the filter is not
        //passed and reset, it will mysterously be cleared.
        //Something clears it before this line.
        $scope.realDocumentFilter = filter;
        var res = [];
        for (var j=0; j<item.docList.length; j++) {
            var aiId = item.docList[j];
            if (aiId != doc.universalid) {
                res.push(aiId);
            }
        }
        item.docList = res;
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
        //$scope.savePartialMeeting(['state']);
        $scope.saveMeeting();
    };
    //$scope.changeItemState = function(item, newState) {
    //    item.status = newState;
    //    $scope.saveMeeting();
    //};
    $scope.changeGoalState = function(goal, newState) {
        goal.prospects = newState;
        $scope.saveGoal(goal);
    };
    $scope.saveMeeting = function() {
        $scope.meetingTime.setHours($scope.meetingHour);
        $scope.meetingTime.setMinutes($scope.meetingMinutes);
        $scope.meetingTime.setSeconds(0);
        $scope.meeting.startTime = $scope.meetingTime.getTime();

        $scope.sortItems();
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
        var postdata = angular.toJson(readyToSave);
        $scope.showError=false;
        $http.post(postURL ,postdata)
        .success( function(data) {
            $scope.meeting = data;
            $scope.extractDateParts();
            $scope.editHead=false;
            $scope.editDesc=false;
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };
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
        for( var i=0; i<$scope.allPeople.length; i++) {
            var onePeople = $scope.allPeople[i];
            if (onePeople.uid.indexOf(viewValue)>=0) {
                newVal.push(onePeople);
            }
            else if (onePeople.name.indexOf(viewValue)>=0) {
                newVal.push(onePeople);
            }
        }
        return newVal;
    }

    $scope.createActionItem = function(item) {
        var postURL = "createActionItem.json?id="+$scope.meeting.id+"&aid="+item.id;
        var newSynop = $scope.newGoal.synopsis;
        if (newSynop == null || newSynop.length==0) {
            alert("must enter a description of the action item");
            return;
        }
        for(var i=0; i<$scope.goalList.length; i++) {
            var oneItem = $scope.goalList[i];
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
            $scope.goalList.push(data);
            item.actionItems.push(data.universalid);
            $scope.newGoal = {};
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
        $scope.stopEditing();
    };
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
            goal.prospects = data.prospects;  //update back with official value
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

    $scope.findPersonName = function(email) {
        var person = {name: email};
        $scope.allPeople.map( function(item) {
            if (item.uid == email) {
                person = item;
            }
        });
        return person.name;
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
    $scope.startNewComment = function(item, isPoll, cmt) {
        item.newComment = {};
        item.newComment.choices = ["Consent", "Object"];
        item.newComment.html="";
        item.newComment.poll=isPoll;
        if (cmt) {
            item.newComment.replyTo = cmt.time;
        }
        $scope.toggleEditor(8,item.id)
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

    $scope.startResponse = function(cmt, pickedChoice) {
        $scope.toggleEditor(9,cmt.time);
        var myList = $scope.getMyResponse(cmt);
        if (myList.length>0) {
            myList[0].choice = pickedChoice;
        }
    }

    $scope.createModifiedProposal = function(item, cmt) {
        item.newComment = {}
        item.newComment.html = cmt.html;
        item.newComment.time = cmt.time + 1;
        item.newComment.poll = true;
        item.newComment.replyTo = cmt.time;
        item.newPoll = true;
        $scope.toggleEditor(8,item.id);
    }

    $scope.navigateToDoc = function(doc) {
        window.location="docinfo"+doc.id+".htm";
    }

    $scope.openModalActionItem = function (item, goal) {

        var modalInstance = $modal.open({
          animation: false,
          templateUrl: '<%=ar.retPath%>templates/ModalActionItem.html',
          controller: 'ModalActionItemCtrl',
          size: 'lg',
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
            $scope.goalList.map( function(item) {
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
        item.newComment = {}
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
    $scope.updateResponse = function(cmt, response) {
        var selected = cmt.responses.filter( function(item) {
            return item.user!="<%ar.writeJS(currentUser);%>";
        });
        selected.push(response);
        cmt.responses = selected;
        //should pass the agent item so we can just save it....
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
            templateUrl: '<%=ar.retPath%>templates/ResponseModal.html',
            controller: 'ModalResponseCtrl',
            size: 'lg',
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

});



</script>

<script src="<%=ar.retPath%>templates/ModalActionItemCtrl.js"></script>
<script src="<%=ar.retPath%>templates/ResponseModal.js"></script>
<script src="<%=ar.retPath%>templates/DecisionModal.js"></script>

<div ng-app="myApp" ng-controller="myCtrl" ng-cloak>

<%@include file="ErrorPanel.jsp"%>

    <div class="generalHeading" style="height:40px">
        <div  style="float:left;margin-top:8px;">
            <span ng-show="meeting.meetingType==1">Circle</span>
            <span ng-show="meeting.meetingType==2">Operational</span>
            Meeting: <a href="meetingFull.htm?id={{meeting.id}}">{{meeting.name}}</a>
            @ {{meeting.startTime|date: "h:mma 'on' dd-MMM-yyyy"}}
        </div>
        <div class="rightDivContent" style="margin-right:100px;">
          <span class="dropdown">
            <button class="btn btn-default dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
            Options: <span class="caret"></span></button>
            <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
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
    </div>


    <div>
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


    <table>
      <tr>
        <td style="width:100%">
          <div class="leafContent">
            <span style="font-size:150%;font-weight: bold;">
                Meeting: {{meeting.name}} @ {{meeting.startTime|date: "h:mma 'on' dd-MMM-yyyy"}}
            </span>
            <span ng-show="meeting.state<3">
                (
                <i class="fa fa-cogs meeting-icon" ng-click="toggleEditor(5,'0')"></i>
                <i class="fa fa-pencil-square-o meeting-icon" ng-click="toggleEditor(6,'0')"></i>
                )
            </span>
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
             <div ng-model="meeting.meetingInfo" ta-toolbar="[['h1','h2','h3','p','ul','indent','outdent'],['bold','italics','clear','insertLink'],['undo','redo']]" text-angular="" class="leafContent"></div>

             <button ng-click="savePartialMeeting(['meetingInfo'])" class="btn btn-danger">Save</button>
             <button ng-click="revertAllEdits()" class="btn btn-danger">Cancel</button>
           </div>
        </td>
      </tr>
    </table>

<div ng-repeat="item in meeting.agenda">
    <div style="border: 1px solid lightgrey;border-radius:10px;margin-top:20px;">
    <table >

                          <!--  AGENDA HEADER -->
      <tr>
        <td style="width:100%">
          <div style="padding:5px;">
            <span style="font-size:130%;font-weight: bold;" ng-click="showItemMap[item.id]=!showItemMap[item.id]">{{item.position}}. {{item.subject}} &nbsp; </span>
            <span ng-show="showItemMap[item.id] && meeting.state<3">
                ( <i class="fa fa-cogs meeting-icon" ng-click="toggleEditor(2,item.id)"
                    title="Agenda Item Settings"></i>
                <i class="fa fa-pencil-square-o meeting-icon" ng-click="startEdit(item)"
                    title="Edit Description"></i>
                <i class="fa fa-book meeting-icon" ng-click="toggleEditor(3,item.id)"
                    title="Agenda Item Attached Documents"></i>
                <i class="fa fa-flag meeting-icon" ng-click="toggleEditor(4,item.id)"
                    title="Create New Action Item"></i>
                <i class="fa fa-tasks meeting-icon" ng-click="toggleEditor(9,item.id)"
                    title="Manage Action Items"></i> )
            </span>
            <div>
                <i>{{item.schedule | date: 'hh:mm'}} ({{item.duration}} minutes)</i><span ng-repeat="pres in getPresenters(item)">, {{pres.name}}</span>
            </div>
          </div>

          <div ng-show="isEditing(2,item.id)" class="well">
            <div class="form-inline form-group">
              Name: <input ng-model="item.subject"  class="form-control" style="width:200px;"/>
              Duration: <input ng-model="item.duration"  class="form-control" style="width:50px;"/>
              <button ng-click="saveAgendaItemParts(item, ['subject','duration'])" class="btn btn-danger">Save</button>
              <button ng-click="revertAllEdits()" class="btn btn-danger">Cancel</button>
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
          </div>
        </td>
      </tr>

                          <!--  AGENDA BODY -->
      <tr ng-show="showItemMap[item.id]">
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
             <div ng-model="item.desc" ta-toolbar="[['h1','h2','h3','p','ul','indent','outdent'],['bold','italics','clear','insertLink'],['undo','redo']]" text-angular="" class="leafContent"></div>

             <button ng-click="saveAgendaItemParts(item, ['desc'])" class="btn btn-danger">Save</button>
             <button ng-click="cancelEdit(item)" class="btn btn-danger">Cancel</button>
           </div>
        </td>
      </tr>

                          <!--  AGENDA ATTACHMENTS -->
      <tr ng-show="showItemMap[item.id]">
        <td>
           <table style="margin:10px;"><tr>
              <td style="vertical-align:top;"><b>Attachments: </b></td>
              <td><span ng-repeat="doc in itemDocs(item)" class="btn btn-sm btn-default"  style="margin:4px;"
                   ng-click="navigateToDoc(doc)">
                      <img src="<%=ar.retPath%>assets/images/iconFile.png"> {{doc.name}}
                  </span>
              </td>
           </table>
        </td>
      </tr>

                          <!--  AGENDA ADD DOCUMENTS -->
      <tr ng-show="showItemMap[item.id]">
        <td ng-show="isEditing(3,item.id)" style="width:100%">
           <div class="well" style="margin:10px;">
              <div style="float:right;"><i class="fa fa-close meeting-icon" ng-click="toggleEditor(3,item.id)"></i></div>
              <div><b>Add Document to this Agenda Item</b></div>
              <table class="table">
                <tr>
                   <td colspan="4">
                      Filter <input type="text" ng-model="realDocumentFilter"> {{realDocumentFilter}}
                   </td>
                </tr>
                <tr ng-repeat="doc in filterDocs(realDocumentFilter+'')">
                    <td><img src="<%=ar.retPath%>assets/images/iconFile.png"/> {{doc.name}} </td>
                    <td></td>
                    <td>
                        <button ng-click="addDocToItem(item, doc, realDocumentFilter)" ng-hide="itemHasDoc(item,doc)">Add</button>
                        <button ng-click="removeDocFromItem(item, doc, realDocumentFilter)" ng-show="itemHasDoc(item,doc)">Remove</button>
                    </td>
                    </td>
                </tr>
                <tr>
                   <td><button>Add All Above</button></td>
                </tr>
             </table>
           </div>
        </td>
      </tr>

                          <!--  AGENDA Action ITEMS -->
      <tr><td style="height:15px"></td></tr>
      <tr ng-show="showItemMap[item.id]">
        <td ng-hide="isEditing(4,item.id)" style="width:100%">
           <table class="table">
           <tr ng-show="itemGoals(item).length>0">
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
                    <button class="btn btn-default dropdown-toggle" type="button" id="menu2" data-toggle="dropdown" >
                          <span class="caret"></span></button>
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
                          <!--  AGENDA ADD ACTION ITEMS -->
      <tr ng-show="showItemMap[item.id]">
        <td ng-show="isEditing(9,item.id)" style="width:100%">
           <div class="well" style="margin:10px;">
              <div style="float:right;"><i class="fa fa-close meeting-icon" ng-click="toggleEditor(9,item.id)"></i></div>
              <div><b>Add Action Item to this Agenda Item</b></div>
              <table class="table">
                <tr>
                   <td colspan="4">
                      Filter <input type="text" ng-model="actionItemFilter">
                   </td>
                </tr>
                <tr ng-repeat="goal in filterGoalsForItem(actionItemFilter, item)">
                    <td><img src="<%=ar.retPath%>assets/goalstate/small{{goal.state}}.gif"/> {{goal.synopsis}} </td>
                    <td><span ng-repeat="person in goal.assignTo"> {{person.name}} <br/></span></td>
                    <td>
                        <button ng-click="addGoalToItem(item, goal)" ng-hide="itemHasGoal(item,goal)">Add</button>
                        <button ng-click="removeGoalFromItem(item, goal)" ng-show="itemHasGoal(item,goal)">Remove</button>
                    </td>
                    </td>
                </tr>
                <tr>
                   <td><button>Add All Above</button></td>
                </tr>
             </table>
           </div>
        </td>
      </tr>


      </table>
      </div>

                          <!--  AGENDA comments -->
      <table ng-show="showItemMap[item.id]">
      <tr ng-repeat="cmt in item.comments">
           <td style="width:50px;vertical-align:top;padding:15px;">
               <img id="cmt{{cmt.time}}" class="img-circle" style="height:35px;width:35px;" src="<%=ar.retPath%>/users/{{cmt.userKey}}.jpg">
           </td>
           <td>
               <div class="comment-outer">
                   <div>
                       <div class="dropdown" style="float:left">
                           <button class="btn btn-default dropdown-toggle" type="button" id="menu" data-toggle="dropdown" style="margin-right:10px;">
                               <span class="caret"></span>
                           </button>
                           <ul class="dropdown-menu" role="menu" aria-labelledby="menu">
                              <li role="presentation" ng-show="cmt.user=='<%=uProf.getUniversalId()%>'">
                                  <a role="menuitem" ng-click="toggleEditor(7,cmt.time)">Edit Your Comment</a></li>
                              <li role="presentation" ng-show="cmt.poll">
                                  <a role="menuitem" ng-click="openResponseEditor(cmt)">Create/Edit Response:</a></li>
                              <li role="presentation" ng-show="cmt.poll">
                                  <a role="menuitem" ng-click="createModifiedProposal(item,cmt)">Make Modified Proposal</a></li>
                              <li role="presentation" ng-hide="cmt.poll">
                                  <a role="menuitem" ng-click="startNewComment(item, false, cmt)">Reply</a></li>
                              <li role="presentation" ng-show="cmt.poll">
                                  <a role="menuitem" ng-click="openDecisionEditor(item, cmt)">Create New Decision</a></li>
                           </ul>
                       </div>

                       <span ng-hide="cmt.poll"><i class="fa fa-comments-o"></i></span>
                       <span ng-show="cmt.poll"><i class="fa fa-star-o"></i></span>
                       &nbsp; {{cmt.time | date}} -
                       <a href="<%=ar.retPath%>v/{{cmt.userKey}}/userSettings.htm">
                          <span class="red">{{cmt.userName}}</span>
                       </a>
                       <span ng-hide="cmt.emailSent">-email pending-</span>
                         <span ng-show="cmt.replyTo">
                             <span ng-hide="cmt.poll">In reply to
                                 <a style="border-color:white;" href="#cmt{{cmt.replyTo}}">
                                 <i class="fa fa-comments-o"></i> {{findComment(item,cmt.replyTo).userName}}</a></span>
                             <span ng-show="cmt.poll">Based on
                                 <a style="border-color:white;" href="#cmt{{cmt.replyTo}}">
                                 <i class="fa fa-star-o"></i> {{findComment(item,cmt.replyTo).userName}}</a></span>
                         </span>

                   </div>
                   <div class="leafContent comment-inner" ng-hide="isEditing(7,cmt.time)">
                       <div ng-bind-html="cmt.html"></div>
                   </div>

                    <div class="well leafContent" style="width:100%" ng-show="isEditing(7,cmt.time)">
                      <div ng-model="cmt.html"
                          ta-toolbar="[['h1','h2','h3','p','ul','indent','outdent'],['bold','italics','clear','insertLink'],['undo','redo']]"
                          text-angular="" class="" style="width:100%;"></div>

                      <button ng-click="saveComment(item,cmt);stopEditing()" class="btn btn-danger">Save Changes</button>
                      <button ng-click="revertAllEdits();stopEditing()" class="btn btn-danger">Cancel</button>
                      &nbsp;
                      <input type="checkbox" ng-model="cmt.poll"> Proposal</button>
                    </div>

                   <table style="min-width:500px;" ng-show="cmt.poll && !isEditing(9,cmt.time)">
                   <tr ng-repeat="resp in cmt.responses">
                       <td style="padding:5px;max-width:100px;">
                           <b>{{resp.choice}}</b>
                           <span ng-show="resp.user=='<%ar.writeJS(currentUser);%>'" ng-click="openResponseEditor(cmt)" style="cursor:pointer;">&nbsp; <a href="#"><i class="fa fa-edit"></i></a></span>
                           <br/>
                           {{resp.userName}}
                       </td>
                       <td style="padding:5px;">
                          <div class="leafContent comment-inner" ng-bind-html="resp.html"></div>
                       </td>
                   </tr>
                   </table>
                   <div ng-show="cmt.replies.length>0 && cmt.poll">
                       See proposals:
                       <span ng-repeat="reply in cmt.replies"><a href="#cmt{{reply}}" >
                           <i class="fa fa-star-o"></i> {{findComment(item,reply).userName}}</a> </span>
                   </div>
                   <div ng-show="cmt.replies.length>0 && !cmt.poll">
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
      <tr>
        <td></td>
        <td>
        <div ng-hide="isEditing(8,item.id)" style="margin:20px;">
            <button ng-click="startNewComment(item, false)" class="btn btn-default">
                Create New <i class="fa fa-comments-o"></i> Comment</button>
            <button ng-click="startNewComment(item, true)" class="btn btn-default">
                Create New <i class="fa fa-star-o"></i> Proposal</button>
        </div>
        <div ng-show="isEditing(8,item.id)">
            <div class="well leafContent" style="width:100%">
              <div ng-model="item.newComment.html"
                  ta-toolbar="[['h1','h2','h3','p','ul','indent','outdent'],['bold','italics','clear','insertLink'],['undo','redo']]"
                  text-angular="" class="" style="width:100%;"></div>

              <button ng-click="saveNewComment(item);stopEditing()" class="btn btn-danger" ng-hide="item.newComment.poll">
                  Create <i class="fa fa-comments-o"></i> Comment</button>
              <button ng-click="saveNewComment(item);stopEditing()" class="btn btn-danger" ng-show="item.newComment.poll">
                  Create <i class="fa fa-star-o"></i> Proposal</button>
              <button ng-click="stopEditing()" class="btn btn-danger">Cancel</button>
              &nbsp;
              <input type="checkbox" ng-model="item.newComment.poll"> Proposal</button>
            </div>
        </div>
        </td>
      </tr>
    </table>
    </div>

    <hr/>
    <div style="margin:20px;">
        <button ng-click="createAgendaItem()" class="btn">Create New Agenda Item</button>
    </div>


    Refreshed {{refreshCount}} times.   {{refreshStatus}}<br/>
    reminder sent {{meeting.reminderSent | date:'M/d/yy H:mm'}}



</div>


