
var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal, AllPeople, $timeout) {
    window.setMainPageTitle("Meeting");
    
    var isLinkToComment = ( window.location.href.indexOf("#")>0 );
    
    $scope.siteInfo = embeddedData.siteInfo;
    $scope.pageId = embeddedData.pageId;
    $scope.meetId = embeddedData.meetId;
    $scope.meeting = {rollCall:[],agenda:[]};
    $scope.previousMeeting = embeddedData.previousMeeting;
    $scope.allGoals = embeddedData.allGoals;
    $scope.attachmentList = [];
    $scope.allRoles = embeddedData.allRoles;
    $scope.allLabels = embeddedData.allLabels;
    $scope.allLayoutNames = embeddedData.allLayoutNames;
    $scope.allTopics = [];
    $scope.backlogId = embeddedData.backlogId;
    $scope.timeFactor = "Minutes";
    $scope.factoredTime = 0;
    
    $scope.userZone = embeddedData.userZone;
    $scope.browserZone = Intl.DateTimeFormat().resolvedOptions().timeZone;
    
    $scope.showTimeSlots = false;
    $scope.showFutureSlots = false;
    $scope.timeSlotResponders = [];
    $scope.futureSlotResponders = [];
    $scope.newProposedTime = 0;
    
    var templateCacheDefeater = embeddedData.templateCacheDefeater;

    var n = new Date().getTimezoneOffset();
    var tzNeg = n<0;
    if (tzNeg) {
        n = -n;
    }
    var tzHours = Math.floor(n/60);
    var tzMinutes = n - (tzHours*60);
    var tzFiddle = (100 + tzHours)*100 + tzMinutes;
    var txFmt = tzFiddle.toString().substring(1);
    if (tzNeg) {
        txFmt = "+".concat(txFmt);
    }
    else {
        txFmt = "-".concat(txFmt);
    }
    $scope.tzIndicator = txFmt;

    $scope.onTimeSet = function (newDate) {
        $scope.meeting.startTime = newDate.getTime();
    }    
    
    

    $scope.newAssignee = "";
    $scope.newAttendee = "";
    $scope.newGoal = {};
    $scope.newPerson = "";
    $scope.myUserId = SLAP.loginInfo.userId;
    $scope.actionItemFilter = "";
    $scope.realDocumentFilter = "";

    $scope.isRegistered = function() {
        var registered = false;
        $scope.meeting.rollCall.forEach( function(item) {
            if (item.uid == SLAP.loginInfo.userId) {
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
    $scope.editMeetingDesc = false;

    $scope.stopEditing =  function() {
        $scope.editMeetingDesc = false;
    }


    $scope.showAll = function() {
        $scope.meeting.agenda.forEach( function(item) {
            $scope.showItemMap[item.id] = true;
        });
    }

    $scope.getAgendaItems = function() {
        if (!$scope.meeting.agenda) {
            $scope.meeting.agenda = [];
        }
        $scope.meeting.agenda.forEach( function(item) {
            if (item.isSpacer) {
                //spacers (breaks) can not be proposed
                item.proposed = false;
            }
            if (!item.desc) {
                item.desc = "<p></p>";
            }
        });
        return $scope.meeting.agenda;
    }


    $scope.sortItemsB = function() {
        $scope.meeting.agenda.sort( function(a, b){
            if (a.proposed==b.proposed) {
                return a.position - b.position;
            }
            else if (a.proposed) {
                return 1;
            }
            else {
                return -1;
            }
        } );
        var runTime = new Date($scope.meeting.startTime);
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
        if ($scope.meeting.state<=0) {
            return "Draft";
        }
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
    
    $scope.calcAutSendTimes = function() {
        $scope.meetingInPast = ($scope.meeting.startTime < new Date().getTime());
        $scope.reminderDate =  $scope.meeting.startTime - ($scope.meeting.reminderTime*60000);
        $scope.reminderNone = ($scope.meeting.reminderTime==0);
        $scope.reminderImmediate = !$scope.reminderNone && ($scope.reminderDate < new Date().getTime());
        $scope.reminderLater = !$scope.reminderNone && !$scope.reminderImmediate;
        return true;
    }
    
    $scope.startSend = function() {
        $scope.addressMode = true;
        $scope.calcAutSendTimes();
        if (!$scope.meeting.participants || $scope.meeting.participants.length==0) {
            $scope.allLabels.forEach( function(item) {
                if (item.name==$scope.meeting.targetRole) {
                    var listCopy = [];
                    item.players.forEach( function(player) {
                        listCopy.push(player)
                    });
                    $scope.meeting.participants = listCopy;
                }
            });
        }
    }
    $scope.updatePlayers = function() {
        $scope.meeting.participants = cleanUserList($scope.meeting.participants);
    }    
    $scope.postIt = function(sendEmail) {
        $scope.meeting.state=1;
        $scope.savePartialMeeting(['state','sendEmailNow','participants']);
        $scope.addressMode = false;
        if (sendEmail) {
            document.location = "SendNote.htm?meet="+$scope.meetId;
        }
    }
    $scope.loadPersonList = function(query) {
        return AllPeople.findMatchingPeople(query);
    }
    

    $scope.meetingStateStyle = function(val) {
        if (val<=0) {
            return "background-color:yellow";
        }
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


    $scope.savePendingEdits = function() {
        var parts = [];
        if ($scope.editMeetingDesc) {
            parts.push('meetingInfo');
        }
        if ($scope.editMeetingPart) {
            parts.push($scope.editMeetingPart);
        }
        $scope.savePartialMeeting(parts);
        $scope.editMeetingDesc = false;
        $scope.editMeetingPart = null;
    }
    
    function startAgendaRunning(agendaItem) {
        var saveRecord = {};
        saveRecord.startTimer = agendaItem.id;
        $scope.putGetMeetingInfo(saveRecord);
    }
    $scope.stopAgendaRunning = function() {
        var saveRecord = {};
        saveRecord.stopTimer = "0";
        $scope.putGetMeetingInfo(saveRecord);
    }
    
    $scope.calcTimes = function() {
        var totalTotal = 0;
        //get the time that it is on the server
        var nowTime = new Date().getTime() + $scope.timerCorrection;
        if ($scope.meeting.state>=2) {
            $scope.meeting.agenda.forEach( function(agendaItem) {
                if (agendaItem.timerRunning) {
                    agendaItem.timerTotal = (agendaItem.timerElapsed + nowTime - agendaItem.timerStart)/60000;
                }
                else {
                    agendaItem.timerTotal = (agendaItem.timerElapsed)/60000;
                }
                agendaItem.timerRemaining = agendaItem.duration - agendaItem.timerTotal;
                totalTotal += agendaItem.timerTotal;
            })
        }
        $scope.meeting.timerTotal = totalTotal;
    }
    $scope.timerStyle = function(item) {
        var style = {"background-color":"yellow", "color":"black", "padding":"5px"};
        if (item.timerRemaining<0) {
            style["background-color"] = "red";
        }
        return style;
    }
    function tick() {
        $scope.calcTimes();
        $timeout(tick, 1000); // reset the timer
    }
    // Start the timer
    $timeout(tick, 1000);

    
    $scope.changeMeetingState = function(newState) {
        if ($scope.meeting.state == newState) {
            //nothing changed, so ignore this
            return;
        }
        $scope.savePendingEdits();
        $scope.meeting.state = newState;
        $scope.stopAgendaRunning();
        $scope.savePartialMeeting(['state']);
    };
    $scope.agendaStartButton = function(agendaItem) {
        startAgendaRunning(agendaItem);
    }
    $scope.changeGoalState = function(goal, newState) {
        goal.prospects = newState;
        $scope.saveGoal(goal);
    };
    $scope.saveMeeting = function() {
        $scope.sortItemsB();
        $scope.putGetMeetingInfo($scope.meeting);
    };
    $scope.savePartialMeeting = function(fieldList) {
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
            if (user.uid) {
                agendaItem.presenters.push(user.uid);
            }
            else {
                //if you enter an email address it puts that in the name spot
                agendaItem.presenters.push(user.name);
            }
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
        $scope.putGetMeetingInfo(null);
        $scope.stopEditing();
    };
    $scope.putGetMeetingInfo = function(readyToSave) {
        var promise;
        if (readyToSave) {
            if (readyToSave.participants) {
                readyToSave.participants.forEach( function(item) {
                    if (!item.uid) {
                        item.uid = item.name;
                    }
                });
            }
            var postURL = "meetingUpdate.json?id="+$scope.meetId;
            if (readyToSave.id=="~new~") {
                postURL = "agendaAdd.json?id="+$scope.meeting.id;
            }
            var postdata = angular.toJson(readyToSave);
            promise = $http.post(postURL, postdata);
        }
        else {
            promise = $http.get("meetingRead.json?id="+$scope.meetId);
        }
        promise.success( function(data) {
            setMeetingData(data);
        });
        promise.error( function(data, status, headers, config) {
            console.log("ERROROROROR", data);
            $scope.reportError(data);
        });
        $scope.showError=false;
        return promise;
    };
    $scope.refreshMeetingPromise = function() {
        return $scope.putGetMeetingInfo(null);
    }
    function setMeetingData(data) {
        if (!data) {
            throw "ASKED to SET MEETING DATA but no meeting data passed";
        }
        if (!data.meetingInfo) {
            data.meetingInfo = "";
        }
        data.participants.forEach( function(item) {
            item.image = AllPeople.imageName(item);
        });
        var totalAgendaTime = 0;
        data.agenda.forEach( function(item) {
            totalAgendaTime += item.duration;
        });
        data.agendaDuration = totalAgendaTime;
        $scope.timerCorrection = data.serverTime - new Date().getTime();
        $scope.meeting = data;
        $scope.sortItemsB();
        $scope.calcTimes();

        $scope.editHead=false;
        $scope.editDesc=false;
        $scope.extractPeopleSituation();
        $scope.determineIfAttending();
        if (data.reminderTime%1440 == 0) {
            $scope.timeFactor="Days"
        }
        else {
            $scope.timeFactor="Minutes"
        }
        if ($scope.timeFactor=="Days") {
            $scope.factoredTime = $scope.meeting.reminderTime / 1440;
        }
        else {
            $scope.factoredTime = $scope.meeting.reminderTime;
        }
        $scope.addYouselfIfAppropriate();
        data.timeSlots.sort(function(a,b) {
            return a.proposedTime - b.proposedTime;
        });
        data.futureSlots.sort(function(a,b) {
            return a.proposedTime - b.proposedTime;
        });
        $scope.timeSlotResponders = calcResponders(data.timeSlots, AllPeople);
        $scope.futureSlotResponders = calcResponders(data.futureSlots, AllPeople);
        determineRoleEqualsParticipants();
        if (isLinkToComment) {
            $scope.showAll();
            isLinkToComment = false;
        }
    }
    function determineRoleEqualsParticipants() {
        $scope.roleEqualsParticipants = false;
        var roleName = $scope.meeting.targetRole;
        if (!roleName) {
            //nothing else to do
            return;
        }
        var theRole = getMeetingRole();
        if (!theRole) {
            //name appears to be invalid
            console.log("Meeting has invalid targetRole: "+roleName, $scope.allRoles);
            return;
        }
        if ($scope.meeting.participants.length < theRole.length) {
            //less people, so must be some missing
            return;
        }
        for (var i=0; i<theRole.players.length; i++) {
            var rolePerson = theRole.players[i];
            var found = false;
            for (var j=0; j<$scope.meeting.participants.length; j++) {
                var participant = $scope.meeting.participants[j];
                if (participant.uid == rolePerson.uid) {
                    found = true;
                }
            }
            if (!found) {
                //mismatch, return
                console.log("meeting is missing user: ", rolePerson);
                return;
            }
        }
        //everything matched down to here, so matches
        $scope.roleEqualsParticipants = true;
    }
    $scope.appendRolePlayers = function() {
        var theRole = getMeetingRole();
        if (!theRole) {
            //name appears to be invalid
            console.log("Meeting has invalid targetRole");
            return;
        }
        for (var i=0; i<theRole.players.length; i++) {
            var rolePerson = theRole.players[i];
            var found = false;
            for (var j=0; j<$scope.meeting.participants.length; j++) {
                var participant = $scope.meeting.participants[j];
                if (participant.uid == rolePerson.uid) {
                    found = true;
                }
            }
            if (!found) {
                $scope.meeting.participants.push(rolePerson);
            }
        }
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
            actionItems:[],
            proposed:true
        };
        $scope.meeting.agenda.push(newAgenda);
        $scope.openAgenda(newAgenda);
    };


    $scope.getPeople = function(query) {
        var res = AllPeople.findMatchingPeople(query);
        return res;
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
        window.setTimeout( function() {$scope.refresh()}, 15000);
        if ($scope.meeting.state!=2) {
            $scope.refreshStatus = "No refresh because meeting is not being run";
            return;  //don't set of refresh unless in run mode
        }
        var nowEditing = $scope.editMeetingDesc;
        if (nowEditing) {
            $scope.refreshStatus = "No refresh because currently editing";
            return;
        }
        //if (true) {
        //    $scope.refreshStatus = "No refresh because it doesn't work with TinyMCE editor";
        //    return;
        //}
        $scope.refreshStatus = "Refreshing";
        $scope.putGetMeetingInfo( null );
        $scope.refreshCount++;
    }
    $scope.refreshCount = 0;
    window.setTimeout( function() {$scope.refresh()}, 30000);

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
    $scope.toggleProposed = function(item) {
        if (item.proposed) {
            item.proposed = false;
        }
        else {
            item.proposed = true;
        }
        $scope.saveAgendaItemParts(item, ['proposed']);
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
            $scope.sortItemsB();
            $scope.showInput=false;
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
        if (cmt.commentType==6) {
            return "comment-phase-change";
        }
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
        if (cmt.user==SLAP.loginInfo.userId) {
            return selected;
        }
        cmt.responses.map( function(item) {
            if (item.user==SLAP.loginInfo.userId) {
                selected.push(item);
            }
        });
        if (selected.length == 0) {
            var newResponse = {};
            newResponse.user = SLAP.loginInfo.userId;
            cmt.responses.push(newResponse);
            selected.push(newResponse);
        }
        return selected;
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
    
    function getMeetingRole() {
        var selRole = {players:[]};
        $scope.allLabels.forEach( function(item) {
            if (item.name === $scope.meeting.targetRole) {
                selRole = item;
            }
        });
        return selRole;
    }
    $scope.getMeetingParticipants = function() {
        var parts = [];
        if ($scope.meeting.participants.length > 0) {
            return $scope.meeting.participants;
        }
        $scope.allLabels.forEach( function(item) {
            if (item.name === $scope.meeting.targetRole) {
                return item.players;
            }
        });
        return [];
    }
    
    
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
        var selRole = getMeetingRole();
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
            if (item.uid === SLAP.loginInfo.userId) {
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
        return ($scope.meeting.state == 1 && !$scope.showRollCall);
    }
    $scope.showRollBox = function() {
        return $scope.showRollCall && $scope.meeting.state >= 1 && $scope.meeting.state <= 2
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
        var fakeMeeting = {};
        fakeMeeting.attended_add = SLAP.loginInfo.userId;
        $scope.putGetMeetingInfo(fakeMeeting);
    }
    $scope.addYouselfIfAppropriate = function() {
        if ($scope.meeting.state==2) {
            var foundMe = false;
            $scope.meeting.attended.forEach( function(item) {
                if (item==SLAP.loginInfo.userId) {
                    foundMe=true;
                }
            });
            if (!foundMe) {
                $scope.addYouself();
            }
        }
    }
    $scope.determineIfAttending = function() {
        $scope.isInAttendees = false;
        if ($scope.meeting.attended) {
            $scope.meeting.attended.forEach( function(person) {
                if (person == SLAP.loginInfo.userId) {
                    $scope.isInAttendees = true;
                }
            });
        }
    }    
    $scope.addAttendee = function() {
        if (!$scope.newAttendee) {
            return;
        }
        var fakeMeeting = {};
        fakeMeeting.attended_add = $scope.newAttendee;
        $scope.putGetMeetingInfo(fakeMeeting);
        $scope.newAttendee = "";
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
        var check = {};
        var res = [];
        if ($scope.meeting.attended) {
            $scope.meeting.attended.forEach( function(trial) {
                var trialPerson = AllPeople.findPerson(trial);
                if (!trialPerson || !trialPerson.uid) {
                    return;
                }
                var found = false;
                res.forEach( function(itemx) {
                    if (itemx && itemx.uid == trialPerson.uid) {
                        found = true;
                    }
                });
                if (!found) {
                    res.push(trialPerson);                
                }
            });
        }
        return res;
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


    $scope.openModalActionItem = function (item, goal, start) {
        
        if (!start) {
            start = 'status';
        }

        var modalInstance = $modal.open({
          animation: false,
          templateUrl: embeddedData.retPath+"templates/ActionItem.html"+templateCacheDefeater,
          controller: 'ActionItemCtrl',
          size: 'lg',
          backdrop: "static",
          resolve: {
            goal: function () {
              return goal;
            },
            taskAreaList: function () {
              return [];
            },
            allLabels: function () {
              return $scope.allLabels;
            },
            startMode: function () {
              return start;
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
    $scope.getResponse = function(cmt, userId) {
        var selected = null;
        cmt.responses.forEach( function(item) {
            if(item.user==userId) {
                selected = item;
            }
        });
        return selected;
    }
    $scope.noResponseYet = function(cmt, userId) {
        if (cmt.state!=12) { //not open
            return false;
        }
        var whatNot = $scope.getResponse(cmt, userId);
        return (whatNot!=null);
    }
    $scope.updateResponse = function(cmt, response) {
        var selected = cmt.responses.filter( function(item) {
            return item.user!=SLAP.loginInfo.userId;
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

    $scope.openResponseEditor = function (cmt, userId) {

        if (cmt.choices.length==0) {
            cmt.choices = ["Consent", "Objection"];
            if (cmt.choices[1]=="Object") {
                cmt.choices[1]="Objection";
            }
        }

        var modalInstance = $modal.open({
            animation: false,
            templateUrl: embeddedData.retPath+"templates/ResponseModal.html"+templateCacheDefeater,
            controller: 'ModalResponseCtrl',
            size: 'lg',
            backdrop: "static",
            resolve: {
                responseUser: function () {
                    return userId;
                },
                cmtId: function () {
                    return cmt.time;
                }
            }
        });

        modalInstance.result.then(function () {
            $scope.refreshMeetingPromise();
        }, function () {
            //cancel action - nothing really to do
            $scope.refreshMeetingPromise();
        });
    };
    $scope.removeResponse =  function(cmt,resp) {
        if (!confirm("Are you sure you want to remove the response from "+resp.userName)) {
            return;
        }
        cmt.responses.forEach( function(item) {
            if (item.user == resp.user) {
                item.removeMe = true;
            }
        });
        $scope.updateComment(cmt);
    }

    $scope.commentItemBeingEdited = 0;
    $scope.updateComment = function(cmt) {
        var agendaItem = null;
        $scope.meeting.agenda.forEach( function(ai) {
            if (hasComment(ai,cmt)) {
                agendaItem = ai;
            }
        });
        if (agendaItem) {
            $scope.saveComment(agendaItem, cmt);
        }
        else if ($scope.commentItemBeingEdited) {
            //this is needed for the comment CREATE case
            $scope.saveComment($scope.commentItemBeingEdited, cmt);
        }
        else {
            console.log("DID NOT find an agenda item for comment", cmt);
        }
    }
    function hasComment(ai,cmt) {
        var foundIt = false;
        ai.comments.forEach( function(item) {
            if (item.time == cmt.time) {
                foundIt = true;
            }
        });
        return foundIt;
    }
    $scope.toggleSelectedPerson = function(tag) {
        $scope.selectedPersonShow = !$scope.selectedPersonShow;
        $scope.selectedPerson = tag;
        if (!$scope.selectedPerson.uid) {
            $scope.selectedPerson.uid = $scope.selectedPerson.name;
        }
    }
    $scope.navigateToUser = function(player) {
        window.location=embeddedData.retPath+"v/FindPerson.htm?uid="+encodeURIComponent(player.uid);
    }

    $scope.allowCommentEmail = function() {
        return ($scope.meeting.state>0);
    }

    $scope.openCommentCreator = function(item, type, replyTo, defaultBody) {
        if (item.topicLink) {
            var timeDiff = (new Date()).getTime() - $scope.meeting.startTime;
            var sevenDays = 7*24*60*60*1000;
            if (timeDiff > sevenDays) {
                alert("This meeting happened to long ago to comment on it today.  In a meeting we only show 7 days of comments after the meeting, and it has been more than 7 days, so any comment you make now will not show here.  If you wish to comment on the topic, navigate to the discussion topic itself, and comment there.");
                return;
            }
            if (timeDiff < 0-sevenDays) {
                alert("This meeting is too far in the future to comment on it today.  In a meeting we only show 7 days of comments before the meeting, and it is scheduled more than 7 days from now, so any comment you make now will not show here.  If you wish to comment on the topic, navigate to the discussion topic itself, and comment there.");
                return;
            }
        }
        
        var newComment = {};
        newComment.time = -1;
        newComment.commentType = type;
        newComment.containerType = "M";
        newComment.containerID = $scope.meetId + ":" + item.id;
        newComment.state = 11;
        newComment.dueDate = (new Date()).getTime() + (7*24*60*60*1000);
        newComment.isNew = true;
        newComment.user = SLAP.loginInfo.userId;
        newComment.userName = SLAP.loginInfo.userName;
        newComment.userKey = AllPeople.findUserKey(SLAP.loginInfo.userId);
        if (replyTo) {
            newComment.replyTo = replyTo;
        }
        if (defaultBody) {
            newComment.html = defaultBody;
        }
        newComment.responses = [];
        if (type==2 || type==3) {
            var selRole = $scope.getMeetingParticipants();
            selRole.forEach( function(item) {
                newComment.responses.push({
                    "choice": "None",
                    "html": "",
                    "user": item.uid,
                    "key": item.key,
                    "userName": item.name,
                });
            });
        }
        $scope.openCommentEditor(item, newComment);
    }

    $scope.openCommentEditor = function (item, cmt) {
        $scope.commentItemBeingEdited = item;

        var modalInstance = $modal.open({
            animation: true,
            templateUrl: embeddedData.retPath+"templates/CommentModal.html"+templateCacheDefeater,
            controller: 'CommentModalCtrl',
            size: 'lg',
            backdrop: "static",
            resolve: {
                cmt: function () {
                    return JSON.parse(JSON.stringify(cmt));
                },
                attachmentList: function() {
                    return $scope.attachmentList;
                },
                docSpaceURL: function() {
                    return $scope.docSpaceURL;
                },
                parentScope: function() { return $scope; }
            }
        });

        modalInstance.result.then(function () {
            $scope.refreshMeetingPromise();
        }, function () {
            //cancel action - nothing really to do
            $scope.refreshMeetingPromise();
        });
    };

    $scope.openOutcomeEditor = function (item, cmt) {

        var modalInstance = $modal.open({
            animation: false,
            templateUrl: embeddedData.retPath+"templates/OutcomeModal.html"+templateCacheDefeater,
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
            templateUrl: embeddedData.retPath+"templates/DecisionModal.html"+templateCacheDefeater,
            controller: 'DecisionModalCtrl',
            size: 'lg',
            backdrop: "static",
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


    $scope.getFullDoc = function(docId) {
        var doc = {};
        $scope.attachmentList.filter( function(item) {
            if (item.universalid == docId) {
                doc = item;
            }
        });
        return doc;
    }
    $scope.navigateToDoc = function(docId) {
        var doc = $scope.getFullDoc(docId);
        window.location="docinfo"+doc.id+".htm";
    }
    $scope.navigateToDocDetails = function(docId) {
        var doc = $scope.getFullDoc(docId);
        window.location="editDetails"+doc.id+".htm";
    }
    $scope.sendDocByEmail = function(docId) {
        var doc = $scope.getFullDoc(docId);
        window.location="SendNote.htm?att="+doc.id;
    }
    $scope.downloadDocument = function(docId) {
        var doc = $scope.getFullDoc(docId);
        window.location="a/"+doc.name;
    }
    $scope.unattachDocFromItem = function(item, docId) {
        var newList = [];
        item.docList.forEach( function(iii) {
            if (iii != docId) {
                newList.push(iii);
            }
        });
        item.docList = newList;
        $scope.saveAgendaItemParts(item, ['docList']);
    }
    $scope.openAttachDocument = function (item) {

        var attachModalInstance = $modal.open({
            animation: true,
            templateUrl: embeddedData.retPath+"templates/AttachDocument.html"+templateCacheDefeater,
            controller: 'AttachDocumentCtrl',
            size: 'lg',
            backdrop: "static",
            resolve: {
                containingQueryParams: function() {
                    return "meet="+$scope.meetId+"&ai="+item.id;
                },
                docSpaceURL: function() {
                    return embeddedData.docSpaceURL;
                }
            }
        });

        attachModalInstance.result
        .then(function (docList) {
            //something changed, so re-read the meeting
            $scope.refreshMeetingPromise(); 
        }, function () {
            //cancel action - nothing really to do
        });
    };


    $scope.openAttachTopics = function (item) {

        var attachModalInstance = $modal.open({
            animation: true,
            templateUrl: embeddedData.retPath+"templates/AttachTopic.html"+templateCacheDefeater,
            controller: 'AttachTopicCtrl',
            size: 'lg',
            backdrop: "static",
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
            templateUrl: embeddedData.retPath+"templates/AttachAction.html"+templateCacheDefeater,
            controller: 'AttachActionCtrl',
            size: 'lg',
            backdrop: "static",
            resolve: {
                containingQueryParams: function() {
                    return "meet="+$scope.meetId+"&ai="+item.id;
                }
            }
        });

        attachModalInstance.result
        .then(function (selectedActionItems) {
            item.actionItems = selectedActionItems;
            //no need to save...
            $scope.refreshMeetingPromise();
        }, function () {
            //cancel action - nothing really to do
        });
    };

    $scope.openAgenda = function (agendaItem) {

        var agendaModalInstance = $modal.open({
            animation: true,
            templateUrl: embeddedData.retPath+"templates/Agenda.html"+templateCacheDefeater,
            controller: 'AgendaCtrl',
            size: 'lg',
            backdrop: "static",
            resolve: {
                agendaItem: function () {
                    return JSON.parse(JSON.stringify(agendaItem));
                }
            }
        });

        agendaModalInstance.result
        .then(function (changedAgendaItem) {
            $scope.saveAgendaItemParts(changedAgendaItem, 
                ["subject", "desc","duration","isSpacer","presenters","proposed"]);
        }, function () {
            //cancel action - nothing really to do
        });
    };
    
    $scope.getTimeZoneList = function() {
        if ($scope.allDates && $scope.allDates.length>0) {
            $scope.allDates = [];
            return;
        }
        var input = {};
        input.date = $scope.meeting.startTime;
        input.template = "MMM dd, YYYY  HH:mm";
        input.zones = ["America/New_York", "America/Los_Angeles", "America/Chicago", "America/Denver", "Europe/London", "Europe/Paris", "Asia/Tokyo"];
        input.users = [];
        var roleName = $scope.meeting.targetRole;
        embeddedData.allLabels.forEach( function(label) {
            if (label.name==roleName) {
                label.players.forEach( function(player) {
                    input.users.push(player.uid);
                });
            } 
        });
        var postdata = angular.toJson(input);
        $scope.showError=false;
        var promise = $http.post("timeZoneList.json", postdata)
        promise.success( function(data) {
            $scope.allDates = data.dates;
            $scope.allDates.sort();
        });
        promise.error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    }

    $scope.$watch(
        function(scope) { return scope.factoredTime },
        function(newValue, oldValue) {
            if ($scope.timeFactor=="Days") {
                $scope.meeting.reminderTime = $scope.factoredTime * 1440;
            }
            else {
                $scope.meeting.reminderTime = $scope.factoredTime;
            }
        }
    );
    $scope.$watch(
        function(scope) { return scope.timeFactor },
        function(newValue, oldValue) {
            if ($scope.timeFactor=="Days") {
                $scope.meeting.reminderTime = $scope.factoredTime * 1440;
            }
            else {
                $scope.meeting.reminderTime = $scope.factoredTime;
            }
        }
    );
    
    $scope.refreshMeetingPromise(); 

    $scope.openEditor = function() {
        window.open('meetingMinutes.htm?id='+$scope.meeting.id);
    }
    
    $scope.createTime = function(fieldName,newTime) {
        var isCurrent = ("timeSlots" == fieldName);
        var obj = {action:"AddTime", isCurrent: isCurrent, time: newTime};
        var postURL = "proposedTimes.json?id="+$scope.meeting.id;
        var postdata = angular.toJson(obj);
        $http.post(postURL,postdata)
        .success( function(data) {
            setMeetingData(data);
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    }
    $scope.addProposedVoter = function(fieldName, newVoter) {
        var current = $scope.meeting[fieldName];
        if (newVoter) {
            current.forEach( function(slot) {
                if (!slot.people[newVoter]) {
                    $scope.setVote(fieldName, slot.proposedTime, newVoter, 3);
                }
            });
        }
    }
    $scope.removeVoter = function(fieldName, oldVoter) {
        var isCurrent = ("timeSlots" == fieldName);
        var obj = {action:"RemoveUser", isCurrent: isCurrent, user: oldVoter};
        var postURL = "proposedTimes.json?id="+$scope.meeting.id;
        var postdata = angular.toJson(obj);
        $http.post(postURL,postdata)
        .success( function(data) {
            setMeetingData(data);
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    }
    $scope.removeTime = function(fieldName,time) {
        var hasSetting = false;
        if ($scope.meeting[fieldName]) {
            $scope.meeting[fieldName].forEach( function(aTime) {
                if (aTime.proposedTime == time) {
                    if (Object.keys(aTime.people).length > 0) {
                        hasSetting = true;
                    }
                }
            });
        }
        if (hasSetting) {
            if (!confirm("Are you sure to remove this row?  User values will be lost.")) {
                return;
            }
        }
        
        var isCurrent = ("timeSlots" == fieldName);
        var obj = {action:"RemoveTime", isCurrent: isCurrent, time: time};
        var postURL = "proposedTimes.json?id="+$scope.meeting.id;
        var postdata = angular.toJson(obj);
        $http.post(postURL,postdata)
        .success( function(data) {
            setMeetingData(data);
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    }
    $scope.setVote = function(fieldName, time, resp, newVal) {
        var isCurrent = ("timeSlots" == fieldName);
        var obj = {action:"SetValue", isCurrent: isCurrent, time: time, user: resp, value:newVal};
        var postURL = "proposedTimes.json?id="+$scope.meeting.id;
        var postdata = angular.toJson(obj);
        $http.post(postURL,postdata)
        .success( function(data) {
            setMeetingData(data);
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    }
    $scope.setProposedTime = function(propTime) {
        $scope.newProposedTime = propTime;
    }
    $scope.setMeetingTime = function(propTime) {
        $scope.meeting.startTime = propTime;
        $scope.savePartialMeeting(['startTime']);
    }
    $scope.checkRole = function() {
        $scope.roleWarningMessage = "Checking role "+$scope.meeting.targetRole+" now.";
        var postURL = "isRolePlayer.json?role="+encodeURIComponent($scope.meeting.targetRole);
        $http.get(postURL)
        .success( function(data) {
            if (data.isPlayer) {
                $scope.roleWarningMessage = null;
            }
            else {
                $scope.roleWarningMessage = "You are not a player of "+$scope.meeting.targetRole+". If you save this, you will no longer have access to this meeting.";
            }
        })
        .error( function(data, status, headers, config) {
            $scope.roleWarningMessage = "Unable to read role information about "+$scope.meeting.targetRole;
        });
    }
    
});

function calcResponders(slots, AllPeople) {
    var res = [];
    var checker = [];
    slots.forEach( function(oneTime) {
        Object.keys(oneTime.people).forEach( function(email) {
            if (checker.indexOf(email)<0) {
                res.push(AllPeople.findUserFromID(email));
                checker.push(email);
            }
        });
    });
    if (checker.indexOf(embeddedData.userId)<0) {
        res.push(AllPeople.findUserFromID(embeddedData.userId));
    }
    res.sort( function(a,b) {
        return a.name.localeCompare(b.name);
    });
    return res;
}

app.filter('minutes', function() {

  return function(input) {
      var neg = "";
    if (input<0) {
        neg = "-";
        input = 0-input;
    }
    var mins = Math.floor(input);
    var secs = Math.floor((input-mins) * 60);
    if (secs<10) {
        return neg+mins+":0"+secs;
    }
    return neg+mins+":"+secs;

  }

});