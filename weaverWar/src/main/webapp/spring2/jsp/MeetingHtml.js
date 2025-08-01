
var app = angular.module('myApp');
app.controller('myCtrl', function ($scope, $http, $modal, $interval, AllPeople, $timeout) {
    setUpLearningMethods($scope, $modal, $http);
    window.setMainPageTitle("Meeting");

    var isLinkToComment = (window.location.href.indexOf("#") > 0);

    $scope.siteInfo = embeddedData.siteInfo;
    $scope.workspaceInfo = embeddedData.workspaceInfo;
    $scope.pageId = embeddedData.pageId;
    $scope.meetId = embeddedData.meetId;
    $scope.meeting = { rollCall: [], agenda: [], participants: [] };
    $scope.previousMeeting = embeddedData.previousMeeting;
    $scope.allGoals = embeddedData.allGoals;
    $scope.attachmentList = [];
    $scope.allRoles = embeddedData.allRoles;
    $scope.allLabels = embeddedData.allLabels;
    $scope.allLayoutNames = embeddedData.allLayoutNames;
    $scope.allTopics = [];
    $scope.timeFactor = "Minutes";
    $scope.factoredTime = 0;

    $scope.htmlAgenda = "";
    $scope.htmlMinutes = "";

    $scope.userZone = embeddedData.userZone;
    $scope.browserZone = Intl.DateTimeFormat().resolvedOptions().timeZone;

    $scope.showTimeSlots = false;
    $scope.timeSlotResponders = [];
    $scope.newProposedTime = 0;
    $scope.editSitch = {};

    $scope.toggleEditSitch = function (pers) {
        console.log("starting SITCH: ", pers);
        if ($scope.editSitch.uid != pers.uid) {
            $scope.editSitch = { expect: pers.expect, situation: pers.situation, uid: pers.uid };
        }
    }
    $scope.stopEditSitch = function (pers) {
        //must do a save here
        console.log("SAVING SITCH: ", pers);
        $scope.saveSituation(pers);
        $scope.editSitch = {};
    };

    var templateCacheDefeater = embeddedData.templateCacheDefeater;

    var n = new Date().getTimezoneOffset();
    var tzNeg = n < 0;
    if (tzNeg) {
        n = -n;
    }
    var tzHours = Math.floor(n / 60);
    var tzMinutes = n - (tzHours * 60);
    var tzFiddle = (100 + tzHours) * 100 + tzMinutes;
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

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function (serverErr) {
        $scope.cancelBackgroundTime();
        //console.log("Encountered problem: ",serverErr);
        errorPanelHandler($scope, serverErr);
    };

    $scope.tinymceOptions = standardTinyMCEOptions();
    $scope.tinymceOptions.height = 300;

    //control what is open and closed
    $scope.showItemMap = {};
    $scope.editMeetingDesc = false;

    $scope.stopEditing = function () {
        $scope.editMeetingDesc = false;
    }


    $scope.showAll = function () {
        $scope.meeting.agenda.forEach(function (item) {
            $scope.showItemMap[item.id] = true;
        });
    }

    $scope.getAgendaItems = function () {
        if (!$scope.meeting.agenda) {
            $scope.meeting.agenda = [];
        }
        $scope.meeting.agenda.forEach(function (item) {
            if (item.isSpacer) {
                //spacers (breaks) can not be proposed
                item.proposed = false;
            }
        });
        return $scope.meeting.agenda;
    }
    $scope.getSims = function () {
        if (!$scope.meeting.agenda) {
            $scope.meeting.agenda = [];
        }
        if (!$scope.sims) {
            $scope.sims = {};
        }
        var simList = [];
        $scope.meeting.agenda.forEach(function (item) {
            if (item.isSpacer) {
                return;
            }
            var sim = $scope.sims[item.id];
            if (!sim) {
                sim = new SimText(item.minutes);
                sim.itemRef = item;
                $scope.sims[item.id] = sim;
            }
            else {
                // this is wrong for actually editing
                // because the sims are not actually being used for edit, 
                // and for display only, so this refreshes them.
                sim.init(item.minutes);
            }
            //TEMP disable editing
            sim.startEdit = function () { alert('editing not yet enabled on this page'); }
            sim.item = item;
            simList.push(sim);
        });
        return simList;
    }


    $scope.sortItemsB = function () {
        $scope.meeting.agenda.sort(function (a, b) {
            if (a.proposed == b.proposed) {
                return a.position - b.position;
            }
            else if (a.proposed) {
                return 1;
            }
            else {
                return -1;
            }
        });
        var runTime = new Date($scope.meeting.startTime);
        var runDur = 0;
        for (var i = 0; i < $scope.meeting.agenda.length; i++) {
            var item = $scope.meeting.agenda[i];
            item.position = i + 1;
            item.schedule = runTime;
            runDur = runDur + item.duration;
            runTime = new Date(runTime.getTime() + (item.duration * 60000));
            item.scheduleEnd = runTime;
        }
        $scope.meeting.endTime = runTime;
        $scope.meeting.totalDuration = runDur;
        return $scope.meeting.agenda;
    };

    $scope.itemHasDoc = function (item, doc) {
        var res = false;
        var found = item.docList.forEach(function (docid) {
            if (docid == doc.universalid) {
                res = true;
            }
        });
        return res;
    }
    $scope.itemDocs = function (item) {
        return $scope.attachmentList.filter(function (oneDoc) {
            return $scope.itemHasDoc(item, oneDoc);
        });
    }
    $scope.itemTopics = function (item) {
        if (!item || !item.topicList) {
            return false;
        }
        let topicIdList = [];
        for (aTopic of item.topicList) {
            topicIdList.push(aTopic.universalid);
        }
        return $scope.allTopics.filter(function (oneTopic) {
            return topicIdList.includes(oneTopic.universalid);
        });
    }

    $scope.itemGoals = function (item) {
        if (!item) {
            return [];
        }
        if (!item.aiList) {
            return [];
        }
        var res = [];
        if (item) {
            for (var j = 0; j < item.aiList.length; j++) {
                var actionItemInfo = item.aiList[j];
                for (var i = 0; i < $scope.allGoals.length; i++) {
                    var oneGoal = $scope.allGoals[i];
                    if (oneGoal.id == actionItemInfo.id) {
                        res.push(oneGoal);
                    }
                }
            }
            res.sort(function (a, b) {
                return a.duedate - b.duedate;
            });
        }
        return res;
    }
    $scope.filterGoals = function (actionItemFilter) {
        var res = [];
        var fil = actionItemFilter.toLowerCase();
        for (var i = 0; i < $scope.allGoals.length; i++) {
            var oneGoal = $scope.allGoals[i];
            if (oneGoal.state < 2 || oneGoal.state > 4) {
                continue;
            }
            //TODO: does synposis, need to do others, including assigneeds, and need to split filter
            if (fil.length == 0 || oneGoal.synopsis.toLowerCase().indexOf(fil) >= 0) {
                res.push(oneGoal);
                continue;
            }
            for (var j = 0; j < oneGoal.assignTo.length; j++) {
                var ass = oneGoal.assignTo[j];
                if (ass.name.toLowerCase().indexOf(fil) >= 0) {
                    res.push(oneGoal);
                    break;
                }
            }
        }
        return res;
    }
    $scope.filterGoalsForItem = function (actionItemFilter, item) {
        var filteredList = $scope.filterGoals(actionItemFilter);
        var res = []
        for (var i = 0; i < filteredList.length; i++) {
            var oneGoal = filteredList[i];
            if (!$scope.itemHasGoal(item, oneGoal)) {
                res.push(oneGoal);
            }
        }
        return res;
    }
    $scope.itemHasGoal = function (item, goal) {
        for (var j = 0; j < item.aiList.length; j++) {
            if (item.aiList[j].id == goal.universalid) {
                return true;
            }
        }
        return false;
    }

    $scope.meetingStateName = function () {
        if ($scope.meeting.state <= 0) {
            return "Draft";
        }
        if ($scope.meeting.state <= 1) {
            return "Planning";
        }
        if ($scope.meeting.state == 2) {
            return "Running";
        }
        return "Completed";
    };
    $scope.itemStateName = function (item) {
        if (item.status <= 1) {
            return "Good";
        }
        if (item.status == 2) {
            return "Warnings";
        }
        return "Trouble";
    };
    $scope.goalStateName = function (goal) {
        if (goal.prospects == "good") {
            return "Good";
        }
        if (goal.prospects == "ok") {
            return "Warnings";
        }
        return "Trouble";
    };

    $scope.calcAutSendTimes = function () {
        $scope.meetingInPast = ($scope.meeting.startTime < new Date().getTime());
        $scope.reminderDate = $scope.meeting.startTime - ($scope.meeting.reminderTime * 60000);
        $scope.reminderNone = ($scope.meeting.reminderTime == 0);
        $scope.reminderImmediate = !$scope.reminderNone && ($scope.reminderDate < new Date().getTime());
        $scope.reminderLater = !$scope.reminderNone && !$scope.reminderImmediate;
        return true;
    }

    $scope.startSend = function () {
        $scope.addressMode = true;
        $scope.calcAutSendTimes();
        if (!$scope.meeting.participants || $scope.meeting.participants.length == 0) {
            $scope.allLabels.forEach(function (item) {
                if (item.name == $scope.meeting.targetRole) {
                    var listCopy = [];
                    item.players.forEach(function (player) {
                        listCopy.push(player)
                    });
                    $scope.meeting.participants = listCopy;
                }
            });
        }
    }
    $scope.postIt = function (sendEmail) {
        $scope.meeting.state = 1;
        $scope.savePartialMeeting(['state', 'sendEmailNow', 'participants']);
        $scope.addressMode = false;
        if (sendEmail) {
            document.location = "EmailCompose.htm?meet=" + $scope.meetId;
        }
    }
    $scope.loadPersonList = function (query) {
        return AllPeople.findMatchingPeople(query, $scope.siteInfo.key);
    }


    $scope.meetingStateStyle = function (val) {
        if (val <= 0) {
            return "background-color:#f0c85a; color: primary; font-weight: 500; font-size: 1.1rem; text-align: center; border-radius: 10px;";
        }
        if (val <= 1) {
            return "background-color:#7dc7ff; color: primary; font-weight: 500; font-size: 1.1rem; text-align: center; border-radius: 10px;";
        }
        if (val == 2) {
            return "background-color:#90b990; color: primary; font-weight: 500; font-size: 1.1rem; text-align: center; border-radius: 10px;";
        }
        if (val > 2) {
            return "background-color:#9f8fae; color: primary; font-weight: 500; font-size: 1.1rem; text-align: center; border-radius: 10px;";
        }
        return "Unknown";
    }
    $scope.itemStateStyle = function (item) {
        if (item.status <= 1) {
            return "background-color:#90b990";
        }
        if (item.status == 2) {
            return "background-color:#f0c85a";
        }
        if (item.status > 2) {
            return "background-color:red";
        }
        return "background-color:primary-subtle";
    }
    $scope.goalStateStyle = function (goal) {
        if (goal.prospects == "good") {
            return "background-color:#90b990";
        }
        if (goal.prospects == "ok") {
            return "background-color:#f0c85a";
        }
        if (goal.prospects == "bad") {
            return "background-color:red";
        }
        return "background-color:lavender";
    }


    $scope.savePendingEdits = function (parts) {
        if (!embeddedData.canUpdate) {
            alert("Unable to update meeting because you are not playing an update role in the workspace");
            return;
        }
        if (!parts) {
            parts = [];
        }
        if ($scope.editMeetingDesc) {
            var newMarkdown = HTML2Markdown($scope.meeting.descriptionHtml, {});
            if (newMarkdown != $scope.meeting.description) {
                $scope.meeting.descriptionMerge = { old: $scope.meeting.description, new: newMarkdown };
                parts.push('descriptionMerge');
            }
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
    $scope.stopAgendaRunning = function () {
        var saveRecord = {};
        saveRecord.stopTimer = "0";
        $scope.putGetMeetingInfo(saveRecord);
    }

    $scope.calcTimes = function () {
        var totalTotal = 0;
        //get the time that it is on the server
        var nowTime = new Date().getTime() + $scope.timerCorrection;
        if ($scope.meeting.state >= 2) {
            $scope.meeting.agenda.forEach(function (agendaItem) {
                if (agendaItem.timerRunning) {
                    agendaItem.timerTotal = (agendaItem.timerElapsed + nowTime - agendaItem.timerStart) / 60000;
                }
                else {
                    agendaItem.timerTotal = (agendaItem.timerElapsed) / 60000;
                }
                agendaItem.timerRemaining = agendaItem.duration - agendaItem.timerTotal;
                totalTotal += agendaItem.timerTotal;
            })
        }
        $scope.meeting.timerTotal = totalTotal;
    }
    $scope.timerStyleComplete = function (item) {
        if (!item) {
            return {};
        }
        if (!item.timerRunning) {
            if (item.proposed) {
                return { "background-color": "#cccccc" };
            }
            if (item.isSpacer) {
                return { "background-color": "#bbbbbb" }
            }
            return {};
        }
        if (item.duration - item.timerTotal < 0) {
            return { "background-color": "#ffb57d", "color": "black" };
        }
        return { "background-color": "#90b990", "color": "black" };
    }

    $scope.itemTabStyleComplete = function (item) {
        if (!item) {
            return {};
        }
        let style = {
            "background-color": "#f5f5f5",
            "color": "$primary",
            "margin-top": "10px",
            "margin-bottom": "10px",
            "padding": "5px 10px",
            "border-radius": "4px",
        };
        if (!item.timerRunning) {
            if (item.proposed) {
                style["background-color"] = "#cccccc";
            }
            else if (item.isSpacer) {
                style["background-color"] = "#bbbbbb";
            }
        }
        else if (item.duration - item.timerTotal < 0) {
            style["background-color"] = "#ffb57d";
        }
        else {
            style["background"] = "#90b990";
        }
        /*
        if ($scope.selectedItem && item.position==$scope.selectedItem.position) {
            style.border = "4px solid black";
            style["border-right"] = "none"
        }
        */
        return style;
    }

    //don't know if we need this one any more....
    $scope.timerStyle = function (item) {
        var style = { "background-color": "yellow", "color": "black", "padding": "5px" };
        if (item.timerRemaining < 0) {
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


    $scope.changeMeetingState = function (newState) {
        if (!embeddedData.canUpdate) {
            alert("Unable to update meeting because you are not playing an update role in the workspace");
            return;
        }
        if ($scope.meeting.state == newState) {
            //nothing changed, so ignore this
            return;
        }
        $scope.meeting.state = newState;
        $scope.savePendingEdits(['state']);
        $scope.stopAgendaRunning();
    };
    $scope.toggleSpacer = function (item) {
        item.isSpacer = !item.isSpacer;
        $scope.saveAgendaItemParts(item, ['isSpacer']);
    };

    $scope.agendaStartButton = function (agendaItem) {
        startAgendaRunning(agendaItem);
    }
    $scope.changeGoalState = function (goal, newState) {
        if (!embeddedData.canUpdate) {
            alert("Unable to update meeting because you are not playing an update role in the workspace");
            return;
        }
        goal.prospects = newState;
        $scope.saveGoal(goal);
    };
    $scope.saveMeeting = function () {
        $scope.sortItemsB();
        $scope.putGetMeetingInfo($scope.meeting);
    };
    $scope.savePartialMeeting = function (fieldList) {
        if (!embeddedData.canUpdate) {
            alert("Unable to update meeting because you are not playing an update role in the workspace");
            return;
        }
        var saveRecord = {};
        for (var j = 0; j < fieldList.length; j++) {
            saveRecord[fieldList[j]] = $scope.meeting[fieldList[j]];
        }
        $scope.putGetMeetingInfo(saveRecord);
        $scope.stopEditing();
    };
    $scope.saveNoteFromSim = function (sim) {
        var item = sim.item;
        var newItem = {};
        newItem.id = sim.item.id;

    }
    $scope.saveAgendaItem = function (agendaItem) {
        if (!embeddedData.canUpdate) {
            alert("Unable to update meeting because you are not playing an update role in the workspace");
            return;
        }
        var saveRecord = {};
        saveRecord.agenda = [agendaItem];
        $scope.putGetMeetingInfo(saveRecord);
        $scope.stopEditing();
    };
    $scope.saveAgendaItemParts = function (agendaItem, fieldList) {
        if (!embeddedData.canUpdate) {
            alert("Unable to update meeting because you are not playing an update role in the workspace");
            return;
        }
        agendaItem.presenters = [];
        agendaItem.presenterList.forEach(function (user) {
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
        if (!agendaItem.subject || agendaItem.subject.length < 1) {
            alert("Please enter agenda item name and subject before saving");
            agendaItem.subject = "Agenda Item " + (new Date()).getTime();
        }
        fieldList.forEach(function (ele) {
            itemCopy[ele] = agendaItem[ele];
        });
        $scope.saveAgendaItem(itemCopy);
    };
    $scope.revertAllEdits = function () {
        $scope.putGetMeetingInfo(null);
        $scope.stopEditing();
    };
    $scope.putGetMeetingInfo = function (readyToSave) {
        var promise;
        if (readyToSave) {
            if (!embeddedData.canUpdate) {
                alert("Unable to update meeting because you are not playing an update role in the workspace");
                return;
            }
            if (readyToSave.participants) {
                readyToSave.participants.forEach(function (item) {
                    if (!item.uid) {
                        item.uid = item.name;
                    }
                });
            }
            var postURL = "meetingUpdate.json?id=" + $scope.meetId;
            if (readyToSave.id == "~new~") {
                postURL = "agendaAdd.json?id=" + $scope.meeting.id;
            }
            var postdata = angular.toJson(readyToSave);
            console.log("POSTING meeting info", readyToSave);
            promise = $http.post(postURL, postdata);
        }
        else {
            console.log("GETTING meeting info");
            promise = $http.get("meetingRead.json?id=" + $scope.meetId);
        }
        promise.success(function (data) {
            if (readyToSave) {
                $scope.extendBackgroundTime();
            }
            setMeetingData(data);
        });
        promise.error(function (data, status, headers, config) {
            console.log("Error", data);
            $scope.reportError(data);
        });
        $scope.showError = false;
        return promise;
    };
    $scope.refreshMeetingPromise = function () {
        return $scope.putGetMeetingInfo(null);
    }
    $scope.singleTryToAdd = true;
    function addYouselfIfAppropriate() {
        // the problem here is that SLAP.loginInfo.userId is not necessarily
        // the preferred email address in the profile, and in that case,
        // you will never fine this address in the list.
        // For now, manual setting of attended ONLY
        if ($scope.singleTryToAdd && !$scope.workspaceInfo.frozen && !$scope.workspaceInfo.deleted) {
            if ($scope.meeting.state == 2) {
                var foundMe = false;
                $scope.meeting.attended.forEach(function (item) {
                    if (item == SLAP.loginInfo.userId) {
                        foundMe = true;
                    }
                });
                if (!foundMe) {
                    var fakeMeeting = {};
                    fakeMeeting.attended_add = SLAP.loginInfo.userId;
                    $scope.putGetMeetingInfo(fakeMeeting);
                }
            }
            $scope.singleTryToAdd = false;
        }
    }
    function setMeetingData(data) {
        if (!data) {
            throw "ASKED to SET MEETING DATA but no meeting data passed";
        }

        //create HTML for description
        data.descriptionHtml = convertMarkdownToHtml(data.description);
        console.log("GOT MEETING: ", data);
        if (!data.participants) {
            data.participants = [];
        }
        if (data.participants.length == 0) {
            let person = AllPeople.findPerson(data.owner, $scope.siteInfo.key);
            if (person) {
                data.participants.push(person);
            }
        }

        Object.keys(data.people).forEach(function (key) {
            let partCopy = data.people[key];
            partCopy.key = key;
            if (!partCopy.name) {
                partCopy.name = partCopy.uid;
            }
            partCopy.image = key + ".jpg";
            if (!partCopy.expect) {
                partCopy.expect = "Unknown";
            }
            if (!partCopy.situation) {
                partCopy.situation = "";
            }
            partCopy.timeSlots = {};
            partCopy.available = 3;
            if (data.timeSlots) {
                data.timeSlots.forEach(function (timeSlot) {
                    partCopy.timeSlots[timeSlot.proposedTime] = timeSlot.people[partCopy.uid] || 3;
                    if (timeSlot.proposedTime == data.startTime) {
                        partCopy.available = timeSlot.people[partCopy.uid] || 3;
                    }
                });
            }
        });


        var totalAgendaTime = 0;
        data.agenda.forEach(function (item) {
            //just for demonstration, I am clearing out actionItems so that
            //I know this field is never being used
            item.actionItems = "DONT USE THIS ANY MORE";

            if (!item.proposed) {
                totalAgendaTime += item.duration;
            }
            item.descriptionHtml = convertMarkdownToHtml(item.description);
            item.comments.forEach(function (cmt) {
                $scope.generateCommentHtml(cmt);
            });
        });

        data.agendaDuration = totalAgendaTime;
        $scope.timerCorrection = data.serverTime - new Date().getTime();
        $scope.meeting = data;
        $scope.sortItemsB();
        $scope.calcTimes();

        $scope.editHead = false;
        $scope.editDesc = false;
        $scope.determineIfAttending();
        if (data.reminderTime % 1440 == 0) {
            $scope.timeFactor = "Days"
        }
        else {
            $scope.timeFactor = "Minutes"
        }
        if ($scope.timeFactor == "Days") {
            $scope.factoredTime = $scope.meeting.reminderTime / 1440;
        }
        else {
            $scope.factoredTime = $scope.meeting.reminderTime;
        }
        addYouselfIfAppropriate();
        data.timeSlots.sort(function (a, b) {
            return a.proposedTime - b.proposedTime;
        });
        if (data.timeSlots && data.timeSlots.length > 0) {
            $scope.newProposedTime = data.timeSlots[data.timeSlots.length - 1].proposedTime;
        }
        else {
            $scope.newProposedTime = new Date().getTime();
        }
        $scope.timeSlotResponders = calcResponders(data.participants, AllPeople, $scope.siteInfo.key);
        determineRoleEqualsParticipants();
        if (isLinkToComment) {
            $scope.showAll();
            isLinkToComment = false;
        }
        $scope.calcAttended();

        $scope.selectedItem = {};
        $scope.setSelectedItemById($scope.uiState.selectedItemId);
        if (!$scope.selectedItem) {
            if (data.agenda && data.agenda.length > 0) {
                $scope.setSelectedItem(data.agenda[0]);
            }
        }

        $scope.loadAgenda();
        $scope.loadMinutes();

        $scope.actionItemSims = $scope.getSims();
        window.setMainPageTitle($scope.meeting.name);
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
            console.log("Meeting has invalid targetRole: " + roleName, $scope.allRoles);
            return;
        }
        if ($scope.meeting.participants.length < theRole.length) {
            //less people, so must be some missing
            return;
        }
        for (var i = 0; i < theRole.players.length; i++) {
            var rolePerson = theRole.players[i];
            var found = false;
            for (var j = 0; j < $scope.meeting.participants.length; j++) {
                var participant = $scope.meeting.participants[j];
                if (participant.uid == rolePerson.uid) {
                    found = true;
                }
            }
            if (!found) {
                //mismatch, return
                //console.log("meeting is missing user from role: ", rolePerson);
                return;
            }
        }
        //everything matched down to here, so matches
        $scope.roleEqualsParticipants = true;
    }

    $scope.createAgendaItem = function () {
        if (!embeddedData.canUpdate) {
            alert("Unable to update meeting because you are not playing an update role in the workspace");
            return;
        }
        var newAgenda = {
            id: "~new~",
            duration: 10,
            position: $scope.meeting.agenda.length + 1,
            number: "?",
            docList: [],
            presenters: [],
            presenterList: [],
            aiList: [],
            proposed: false
        };
        $scope.meeting.agenda.push(newAgenda);
        $scope.openAgenda(newAgenda);
    };


    $scope.getPeople = function (query) {
        var res = AllPeople.findMatchingPeople(query, $scope.siteInfo.key);
        return res;
    }


    $scope.replaceGoal = function (goal) {
        var newList = $scope.allGoals.filter(function (item) {
            return item.id != goal.id;
        });
        newList.push(goal);
        $scope.allGoals = newList;
    }

    $scope.saveGoal = function (goal) {
        if (!embeddedData.canUpdate) {
            alert("Unable to update meeting because you are not playing an update role in the workspace");
            return;
        }
        var postURL = "updateGoal.json?gid=" + goal.id;
        var objForUpdate = {};
        objForUpdate.id = goal.id;
        objForUpdate.universalid = goal.universalid;
        objForUpdate.prospects = goal.prospects;  //first thing that could have been changed
        objForUpdate.duedate = goal.duedate;      //second thing that could have been changed
        objForUpdate.status = goal.status;        //third thing that could have been changed
        objForUpdate.checklist = goal.checklist;        //fourth thing that could have been changed
        var postdata = angular.toJson(objForUpdate);
        $scope.showError = false;
        $scope.editGoalInfo = false;
        $scope.showAccomplishment = false;
        $http.post(postURL, postdata)
            .success(function (data) {
                $scope.replaceGoal(data);
                $scope.constructAllCheckItems();
            })
            .error(function (data, status, headers, config) {
                $scope.reportError(data);
            });
    };

    $scope.refreshCount = 0;
    $scope.extendCount = 0;
    $scope.saveCount = 0;
    $scope.lastAutoSave = new Date().getTime();
    $scope.cancelBackgroundTime = function () {
        console.log("AUTOSAVE (Meeting) cancelled");
        $scope.bgActiveLimit = 0;  //this disables the autosave capability
    }
    $scope.extendBackgroundTime = function () {
        console.log("AUTOSAVE (Meeting) time extended (" + (++$scope.extendCount) + " times) because user click");
        $scope.bgActiveLimit = (new Date().getTime()) + 1200000;  //twenty minutes
    }
    $scope.extendBackgroundTime();
    $scope.refresh = function () {
        if ($scope.bgActiveLimit <= 0) {
            //refresh is disabled, so just leave silently
            $scope.refreshStatus = "Refreshing is disabled by logic";
            return;
        }
        if ($scope.meeting.state < 1 || $scope.meeting.state > 2) {
            console.log("AUTOSAVE (Meeting) avoided because meeting in state = "+$scope.meeting.state);
            $scope.refreshStatus = "No refresh because meeting is not being run"; 
            return;
        }
        var currentTime = (new Date().getTime()); 
        var remainingSeconds = ($scope.bgActiveLimit - currentTime) / 1000;
        var secondsSinceLast = (currentTime - $scope.lastAutoSave) / 1000;
        if (remainingSeconds < 0) {
            $scope.refreshStatus = "No refresh because too long without user interaction";
            console.log("AUTOSAVE (Meeting) avoided because timed out.");
            if ($scope.askingToContinue) {
                return;
            }
            $scope.askingToContinue = true;
            msg = "Background refresh stopped after 20 minutes without interaction.\n"
                + "Click OK to manually refresh.";
            console.log("AUTOSAVE (Meeting) prompting user response.");
            if (confirm(msg)) {
                location.reload(true);
            }
            else {
                $scope.extendBackgroundTime();
                $scope.askingToContinue = false;
            }
            console.log("AUTOSAVE (Meeting) received user response.");
            return;
        }
        console.log("AUTOSAVE:  refreshing after " + secondsSinceLast + " seconds (" + (++$scope.saveCount) + " times), shold stop in " + remainingSeconds + " seconds.");
        $scope.lastAutoSave = currentTime;
        var nowEditing = $scope.editMeetingDesc;
        if (nowEditing) {
            $scope.refreshStatus = "No refresh because currently editing";
            return;
        }
        $scope.refreshStatus = "Refreshing is active";
        $scope.putGetMeetingInfo(null);
        $scope.refreshCount++;
    }
    $scope.promiseAutosave = $interval($scope.refresh, 15000);

    $scope.toggleReady = function (item) {
        item.readyToGo = !item.readyToGo
        $scope.saveAgendaItemParts(item, ['readyToGo']);
    }
    $scope.toggleProposed = function (item) {
        if (item.proposed) {
            item.proposed = false;
        }
        else {
            item.proposed = true;
        }
        $scope.saveAgendaItemParts(item, ['proposed']);
    }
    

    $scope.createMinutes = function () {
        if ($scope.meeting.state != 3) {
            alert("Put the meeting into completed mode before generating minutes.");
            return;
        }
        var postURL = "createMinutes.json?id=" + $scope.meeting.id;
        var postdata = angular.toJson("");
        $scope.showError = false;
        $http.post(postURL, postdata)
            .success(function (data) {
                $scope.meeting = data;
                $scope.sortItemsB();
                $scope.showInput = false;
                $scope.refreshTopicList();
            })
            .error(function (data, status, headers, config) {
                $scope.reportError(data);
            });
    };
    $scope.postMinutes = function () {
        if (!embeddedData.canUpdate) {
            alert("Unable to update meeting because you are not playing an update role in the workspace");
            return;
        }
        if (!$scope.meeting.minutesId) {
            alert("program logic error: don't know about any minutes to change the state of");
            return;
        }
        var topicRecord = $scope.findTopicRecord($scope.meeting.minutesId)
        if (!topicRecord) {
            alert("program logic error: can't find a topic with the id " + $scope.meeting.minutesId);
            return;
        }
        var postURL = "noteHtmlUpdate.json?nid=" + topicRecord.id;
        var rec = {};
        rec.id = topicRecord.id;
        rec.universalid = topicRecord.universalid;
        rec.discussionPhase = "Freeform";
        var postdata = angular.toJson(rec);
        $scope.showError = false;
        $http.post(postURL, postdata)
            .success(function (data) {
                $scope.refreshTopicList();
            })
            .error(function (data, status, headers, config) {
                $scope.reportError(data);
            });
    };

    $scope.refreshAttachmentList = function () {
        var getURL = "docsList.json?meet=" + $scope.meetId;
        console.log("REQUEST DOCS", getURL);
        $scope.showError = false;
        $http.get(getURL)
            .success(function (data) {
                $scope.attachmentList = data.docs;
                sessionStorage.setItem("ws" + $scope.pageId + "attachList", JSON.stringify(data.docs));
            })
            .error(function (data, status, headers, config) {
                $scope.reportError(data);
            });
    }
    var cachedAttachmentList = sessionStorage.getItem("ws" + $scope.pageId + "attachList");
    if (cachedAttachmentList) {
        $scope.attachmentList = JSON.parse(cachedAttachmentList);
        $scope.refreshAttachmentList(); //pick up any changes
    }
    else {
        $scope.refreshAttachmentList();
    }


    $scope.findTopicRecord = function (topicId) {
        var ret = null;
        $scope.allTopics.forEach(function (oneTopic) {
            if (topicId == oneTopic.universalid) {
                ret = oneTopic;
            }
            else if (topicId == oneTopic.id) {
                ret = oneTopic;
            }
        });
        return ret;
    }
    $scope.refreshTopicList = function () {
        var getURL = "topicList.json";
        $scope.showError = false;
        $http.get(getURL)
            .success(function (data) {
                $scope.allTopics = data.topics;
                sessionStorage.setItem("ws" + $scope.pageId + "topicList", JSON.stringify(data.topics));
                $scope.minutesDraft = $scope.getMinutesIsDraft();
            })
            .error(function (data, status, headers, config) {
                $scope.reportError(data);
            });
    }
    var cachedTopicList = sessionStorage.getItem("ws" + $scope.pageId + "topicList");
    if (cachedTopicList) {
        $scope.allTopics = JSON.parse(cachedTopicList);
        $scope.refreshTopicList(); //pick up any changes
    }
    else {
        $scope.refreshTopicList();
    }




    $scope.getMinutesStyle = function () {
        if ($scope.meeting.minutesId) {
            if (!$scope.minutesDraft) {
                return "margin:4px;"
            }
        }
        return "margin:4px;background-color:yellow;"
    }
    $scope.getMinutesIsDraft = function () {
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





    $scope.getMyResponse = function (cmt) {
        cmt.choices = ["Consent", "Objection"]
        var selected = [];
        if (cmt.user == SLAP.loginInfo.userId) {
            return selected;
        }
        cmt.responses.map(function (item) {
            if (item.user == SLAP.loginInfo.userId) {
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


    $scope.navigateToTopic = function (topicId) {
        var topicRecord = $scope.findTopicRecord(topicId);
        if (topicRecord) {
            window.open("NoteZoom" + topicRecord.id + ".htm", "_blank");
        }
        else {
            alert("Sorry, can't seem to find a discussion topic with the id: " + topicId);
        }
    }


    function getMeetingRole() {
        var selRole = { players: [] };
        $scope.allLabels.forEach(function (item) {
            if (item.name === $scope.meeting.targetRole) {
                selRole = item;
            }
        });
        return selRole;
    }
    $scope.getMeetingParticipants = function () {
        if ($scope.meeting.participants.length > 0) {
            return $scope.meeting.participants;
        }
        $scope.allLabels.forEach(function (item) {
            if (item.name === $scope.meeting.targetRole) {
                return item.players;
            }
        });
        return [];
    }


    $scope.editAttendees = function () {
        return ($scope.meeting.state == 2);
    }
    $scope.isCompleted = function () {
        return ($scope.meeting.state >= 3);
    }
    $scope.determineIfAttending = function () {
        $scope.isInAttendees = false;
        if ($scope.meeting.attended) {
            $scope.meeting.attended.forEach(function (person) {
                if (person == SLAP.loginInfo.userId) {
                    $scope.isInAttendees = true;
                }
            });
        }
    }
    $scope.getAttended = function () {
        return $scope.attendedCache;
    }

    $scope.calcAttended = function () {
        var res = [];
        if ($scope.meeting.attended) {
            $scope.meeting.attended.forEach(function (trial) {
                var trialPerson = AllPeople.findPerson(trial, $scope.siteInfo.key);
                if (!trialPerson || !trialPerson.uid) {
                    return;
                }
                var found = false;
                res.forEach(function (itemx) {
                    if (itemx && itemx.uid == trialPerson.uid) {
                        found = true;
                    }
                });
                if (!found) {
                    res.push(trialPerson);
                }
            });
        }
        $scope.attendedCache = res;
    }

    $scope.saveSituation = function (pers) {
        var found = false;
        $scope.meeting.rollCall.forEach(function (item) {
            if (item.uid == pers.uid) {
                found = true;
                item.attend = pers.expect;
                item.situation = pers.situation;
            }
        });
        if (!found) {
            $scope.meeting.rollCall.push({
                uid: pers.uid,
                attend: pers.expect,
                situation: pers.situation
            });
        }
        $scope.savePartialMeeting(['rollCall']);
    }

    $scope.removeParticipant = function (pers) {
        if (!embeddedData.canUpdate) {
            alert("Unable to update meeting because you are not playing an update role in the workspace");
            return;
        }
        if ($scope.meeting.people[pers.key]) {
            delete $scope.meeting.people[pers.key];
            let newParticipants = [];
            Object.keys($scope.meeting.people).forEach(function (key) {
                let peopleItem = $scope.meeting.people[key];
                newParticipants.push({ name: peopleItem.name, uid: peopleItem.uid, key: peopleItem.key });
            });
            $scope.meeting.participants = newParticipants;
            console.log("CHANGE PARTICIPANTS: ", newParticipants);
            $scope.savePartialMeeting(['participants']);
        }
    }
    $scope.addPlayers = function (role) {
        if (!embeddedData.canUpdate) {
            alert("Unable to update meeting because you are not playing an update role in the workspace");
            return;
        }
        role.players.forEach( function(player) {
            addToTo(player);
        });
    }
    function addToTo(player) {
        var found = false;
        $scope.meeting.participants.forEach( function(person) {
            if (person.name == player.name) {
                found = true;
            }
        });
        if (!found) {
            $scope.meeting.participants.push({name: player.name, uid: player.uid});
        }
    }
    
    $scope.startParticipantEdit = function () {
        console.log("PARTICIPANTS", $scope.meeting.participants);
        console.log("ROLES", $scope.allRoles);
        $scope.participantEditCopy = [];
        $scope.editMeetingPart = 'participants';
    }
    $scope.finishEditParticipants = function () {
        if (!embeddedData.canUpdate) {
            alert("Unable to update meeting because you are not playing an update role in the workspace");
            return;
        }
        $scope.savePartialMeeting(['participants']);
        $scope.editMeetingPart = "";
    }

    $scope.deleteItem = function (item) {
        if (!embeddedData.canUpdate) {
            alert("Unable to update meeting because you are not playing an update role in the workspace");
            return;
        }
        if (!confirm("Are you sure you want to delete agenda item: " + item.subject)) {
            return;
        }
        var postObj = { "id": item.id };
        var postURL = "agendaDelete.json?id=" + $scope.meeting.id;
        var postdata = angular.toJson(postObj);
        $scope.showError = false;
        $http.post(postURL, postdata)
            .success(function (data) {
                $scope.refreshMeetingPromise();
            })
            .error(function (data, status, headers, config) {
                $scope.reportError(data);
            });
    };



    $scope.openMeetingComment = function (item, commentKind) {
        if (!item || !item.id) {
            alert("Please select an agenda item, and try again");
            return;
        }
        $scope.openCommentCreator(item, commentKind)
    }

    $scope.openModalActionItem = function (item, goal, start) {
        if (!embeddedData.canUpdate) {
            alert("Unable to update meeting because you are not playing an update role in the workspace");
            return;
        }
        if (!item || !item.id) {
            alert("Please select an agenda item, and try again");
            return;
        }
        $scope.cancelBackgroundTime();
        if (!start) {
            start = 'status';
        }
        var modalInstance = $modal.open({
            animation: true,
            templateUrl: embeddedData.retPath + "new_assets/templates/ActionItem.html" + templateCacheDefeater,
            controller: 'ActionItemCtrl',
            size: 'xl',
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
                },
                siteInfo: function () {
                    return $scope.siteInfo;
                }
            }
        });

        modalInstance.result.then(function (modifiedGoal) {
            $scope.allGoals.forEach(function (item) {
                if (item.id == modifiedGoal.id) {
                    item.duedate = modifiedGoal.duedate;
                    item.status = modifiedGoal.status;
                }
            });
            $scope.saveGoal(modifiedGoal);
            $scope.extendBackgroundTime();

        }, function () {
            $scope.putGetMeetingInfo(null);
            $scope.extendBackgroundTime();
        });
    };

    $scope.constructAllCheckItems = function () {
        $scope.allGoals.forEach(function (actionItem) {
            var list = [];
            if (actionItem.checklist) {
                var lines = actionItem.checklist.split("\n");
                var idx = 0;
                lines.forEach(function (item) {
                    item = item.trim();
                    if (item && item.length > 0) {
                        if (item.indexOf("x ") == 0) {
                            list.push({ name: item.substring(2), checked: true, index: idx });
                            idx++;
                        }
                        else {
                            list.push({ name: item, checked: false, index: idx });
                            idx++;
                        }
                    }
                });
            }
            actionItem.checkitems = list;
        });
    }
    $scope.toggleCheckItem = function ($event, item, changeIndex) {
        if (!embeddedData.canUpdate) {
            alert("Unable to update meeting because you are not playing an update role in the workspace");
            return;
        }
        item.checkitems.forEach(function (item) {
            if (item.index == changeIndex) {
                item.checked = !item.checked;
            }
        });
        var newList = [];
        item.checkitems.forEach(function (item) {
            if (item.checked) {
                newList.push("x " + item.name);
            }
            else {
                newList.push(item.name);
            }
        });
        item.checklist = newList.join("\n");
        $scope.saveGoal(item);
        $event.stopPropagation();
    }

    $scope.constructAllCheckItems();

    $scope.findComment = function (item, timeStamp) {
        var foundComment = null;
        if (item) {
            item.comments.forEach(function (xitem) {
                if (xitem.time == timeStamp) {
                    foundComment = xitem;
                }
            });
        }
        else {
            console.log("Null in findComment");
        }
        return foundComment;
    }
    $scope.currentTime = (new Date()).getTime();
    $scope.calcDueDisplay = function (cmt) {
        if (cmt.commentType == 1 || cmt.commentType == 4) {
            return "";
        }
        if (cmt.state == 13) {
            return "";
        }
        var diff = Math.floor((cmt.dueDate - $scope.currentTime) / 60000);
        if (diff < 0) {
            return "overdue";
        }
        if (diff < 120) {
            return "due in " + diff + " minutes";
        }
        diff = Math.floor(diff / 60);
        if (diff < 48) {
            return "due in " + diff + " hours";
        }
        diff = Math.floor(diff / 24);
        if (diff < 8) {
            return "due in " + diff + " days";
        }
        diff = Math.trunc(diff / 7);
        return "due in " + diff + " weeks";
    }
    $scope.getResponse = function (cmt, userId) {
        var selected = null;
        cmt.responses.forEach(function (item) {
            if (item.user == userId) {
                selected = item;
            }
        });
        return selected;
    }
    $scope.noResponseYet = function (cmt, userId) {
        if (cmt.state != 12) { //not open
            return false;
        }
        var whatNot = $scope.getResponse(cmt, userId);
        return (whatNot != null);
    }
    $scope.moveItem = function (item, amt) {
        if (!embeddedData.canUpdate) {
            alert("Unable to update meeting because you are not playing an update role in the workspace");
            return;
        }
        var thisPos = item.position;
        var otherPos = thisPos + amt;
        if (otherPos <= 0) {
            return;
        }
        if (otherPos > $scope.meeting.agenda.length) {
            return;
        }
        $scope.meeting.agenda.forEach(function (x) {
            if (x.position == otherPos) {
                x.position = thisPos;
            }
        });
        item.position = otherPos;
        $scope.saveMeeting();
    }

    $scope.defaultProposalAssignees = function () {
        return $scope.getMeetingParticipants();
    }
    $scope.removeResponse = function (cmt, resp) {
        if (!confirm("Are you sure you want to remove the response from " + resp.userName)) {
            return;
        }
        cmt.responses.forEach(function (item) {
            if (item.user == resp.user) {
                item.removeMe = true;
            }
        });
        $scope.updateComment(cmt);
    }

    $scope.commentItemBeingEdited = 0;
    $scope.updateComment = function (cmt) {
        var agendaItem = null;
        $scope.meeting.agenda.forEach(function (ai) {
            if (hasComment(ai, cmt)) {
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
    function hasComment(ai, cmt) {
        var foundIt = false;
        ai.comments.forEach(function (item) {
            if (item.time == cmt.time) {
                foundIt = true;
            }
        });
        return foundIt;
    }
    $scope.toggleSelectedPerson = function (tag) {
        $scope.selectedPersonShow = !$scope.selectedPersonShow;
        $scope.selectedPerson = tag;
        if (!$scope.selectedPerson.uid) {
            $scope.selectedPerson.uid = $scope.selectedPerson.name;
        }
    }
    $scope.navigateToUser = function (player) {
        window.open(embeddedData.retPath + "v/" + encodeURIComponent(player.key) + "/PersonShow.htm", "_blank");
    }

    $scope.allowCommentEmail = function () {
        return ($scope.meeting.state > 0);
    }



    $scope.getSelectedDocList = function (docId) {
        var doc = [];
        $scope.attachmentList.forEach(function (item) {
            if (item.universalid == docId) {
                doc.push(item);
            }
        });
        return doc;
    }
    $scope.navigateToDoc = function (docId) {
        window.open("DocDetail.htm?aid=" + docId, "_blank");
    }
    $scope.sendDocByEmail = function (docId) {
        window.open("EmailCompose.htm?att=" + docId, "_blank");
    }
    $scope.downloadDocument = function (doc) {
        if (doc.attType == 'URL') {
            window.open(doc.url, "_blank");
        }
        else {
            window.open("a/" + doc.name, "_blank");
        }
    }
    $scope.unattachDocFromItem = function (item, docId) {
        var newList = [];
        item.docList.forEach(function (iii) {
            if (iii != docId) {
                newList.push(iii);
            }
        });
        item.docList = newList;
        $scope.saveAgendaItemParts(item, ['docList']);
    }
    $scope.openAttachDocument = function (item) {
        if (!embeddedData.canUpdate) {
            alert("Unable to update meeting because you are not playing an update role in the workspace");
            return;
        }
        if (!item || !item.id) {
            alert("Please select an agenda item, and try again");
            return;
        }
        if ($scope.workspaceInfo.frozen) {
            alert("Workspace is frozen so you can't change the attached documents");
            return;
        }
        $scope.cancelBackgroundTime();

        var attachModalInstance = $modal.open({
            animation: true,
            templateUrl: embeddedData.retPath + "new_assets/templates/AttachDocument.html" + templateCacheDefeater,
            controller: 'AttachDocumentCtrl',
            size: 'lg',
            backdrop: "static",
            resolve: {
                containingQueryParams: function () {
                    return "meet=" + $scope.meetId + "&ai=" + item.id;
                },
                docSpaceURL: function () {
                    return embeddedData.docSpaceURL;
                }
            }
        });

        attachModalInstance.result
            .then(function (docList) {
                //something changed, so re-read the meeting
                $scope.refreshMeetingPromise();
                $scope.extendBackgroundTime();
            }, function () {
                $scope.putGetMeetingInfo(null);
                $scope.extendBackgroundTime();
            });
    };


    $scope.openAttachTopics = function (item) {
        if (!embeddedData.canUpdate) {
            alert("Unable to update meeting because you are not playing an update role in the workspace");
            return;
        }
        if (!item || !item.id) {
            alert("Please select an agenda item, and try again");
            return;
        }
        if ($scope.workspaceInfo.frozen) {
            alert("Workspace is frozen so you can't change the attached topics");
            return;
        }
        $scope.cancelBackgroundTime();

        var attachModalInstance = $modal.open({
            animation: true,
            templateUrl: embeddedData.retPath + "new_assets/templates/AttachTopic.html" + templateCacheDefeater,
            controller: 'AttachTopicCtrl',
            size: 'lg',
            backdrop: "static",
            resolve: {
                selectedTopics: function () {
                    return item.topicList;
                },
                attachmentList: function () {
                    return $scope.allTopics;
                }
            }
        });

        attachModalInstance.result
            .then(function (selectedTopics) {
                var replacement = {};
                replacement.id = item.id;
                replacement.topicList = selectedTopics;
                $scope.saveAgendaItem(replacement);
                $scope.extendBackgroundTime();
            }, function () {
                $scope.putGetMeetingInfo(null);
                $scope.extendBackgroundTime();
            });
    };

    $scope.openAttachAction = function (item) {
        if (!embeddedData.canUpdate) {
            alert("Unable to update meeting because you are not playing an update role in the workspace");
            return;
        }
        if (!item || !item.id) {
            alert("Please select an agenda item, and try again");
            return;
        }
        $scope.cancelBackgroundTime();

        var attachModalInstance = $modal.open({
            animation: true,
            templateUrl: embeddedData.retPath + "new_assets/templates/AttachAction.html" + templateCacheDefeater,
            controller: 'AttachActionCtrl',
            size: 'lg',
            backdrop: "static",
            resolve: {
                containingQueryParams: function () {
                    return "meet=" + $scope.meetId + "&ai=" + item.id;
                },
                siteId: function () {
                    return $scope.siteInfo.key;
                }
            }
        });

        attachModalInstance.result
            .then(function (selectedActionItems) {
                // item.actionItems = selectedActionItems;
                //no need to save...
                $scope.refreshAllGoals();
                $scope.extendBackgroundTime();

            }, function () {
                $scope.putGetMeetingInfo(null);
                $scope.extendBackgroundTime();
            });
    };

    $scope.refreshAllGoals = function () {
        var getURL = "allActionsList.json";
        $http.get(getURL)
            .success(function (data) {
                $scope.allGoals = data.list;
                $scope.refreshMeetingPromise();
                $scope.constructAllCheckItems();
            })
            .error(function (data, status, headers, config) {
                $scope.reportError(data);
            });
    }


    $scope.openAgendaControlled = function (agendaItem, display) {
        var allowedit = true;
        if ($scope.meeting.state >= 2) {
            allowedit = confirm("The 'description' is generally not edited during the running of the meeting. "
                + "Notes should be kept in the meeting notes field and not the description. "
                + "Are you sure you want to edit this?");
        }
        if (allowedit) {
            $scope.openAgenda(agendaItem, display);
        }
    }

    $scope.openAgenda = function (agendaItem, display) {
        if (!embeddedData.canUpdate) {
            alert("Unable to update meeting because you are not playing an update role in the workspace");
            return;
        }
        if (!agendaItem || !agendaItem.id) {
            alert("Please select an agenda item, and try again");
            return;
        }
        $scope.cancelBackgroundTime();

        var displayMode = 'Settings';
        if (display) {
            displayMode = 'Description';
        }

        var agendaModalInstance = $modal.open({
            animation: true,
            templateUrl: embeddedData.retPath + "new_assets/templates/Agenda.html" + templateCacheDefeater,
            controller: 'AgendaCtrl',
            size: 'xl',
            backdrop: "static",
            resolve: {
                agendaItem: function () {
                    return JSON.parse(JSON.stringify(agendaItem));
                },
                siteId: function () {
                    return $scope.siteInfo.key;
                },
                displayMode: function () {
                    return displayMode;
                }
            }
        });

        agendaModalInstance.result
            .then(function (changedAgendaItem) {
                $scope.saveAgendaItemParts(changedAgendaItem,
                    ["subject", "descriptionMerge", "minutesMerge", "duration",
                        "timerElapsed", "isSpacer", "presenters", "proposed"]);
                $scope.extendBackgroundTime();
            }, function () {
                $scope.putGetMeetingInfo(null);
                $scope.extendBackgroundTime();
            });
    };

    $scope.getTimeZoneList = function () {
        if ($scope.allDates && $scope.allDates.length > 0) {
            $scope.allDates = [];
            return;
        }
        var input = {};
        input.date = $scope.meeting.startTime;
        input.template = "MMM dd, YYYY  HH:mm";
        input.zones = ["America/New_York", "America/Los_Angeles", "America/Chicago", "America/Denver", "Europe/London", "Europe/Paris", "Asia/Tokyo"];
        input.users = [];
        var roleName = $scope.meeting.targetRole;
        embeddedData.allLabels.forEach(function (label) {
            if (label.name == roleName) {
                label.players.forEach(function (player) {
                    input.users.push(player.uid);
                });
            }
        });
        var postdata = angular.toJson(input);
        $scope.showError = false;
        var promise = $http.post("timeZoneList.json", postdata)
        promise.success(function (data) {
            data.dates.sort();
            let tmplst = [];
            data.dates.forEach(function (item) {
                let pos = item.indexOf("(");
                let pre = item.substring(0, pos).trim();
                let post = item.substring(pos);
                tmplst.push({ "zone": post, "time": pre });
            });
            $scope.allDates = tmplst;
        });
        promise.error(function (data, status, headers, config) {
            $scope.reportError(data);
        });
    }


    $scope.$watch(
        function (scope) { return scope.factoredTime },
        function (newValue, oldValue) {
            if ($scope.timeFactor == "Days") {
                $scope.meeting.reminderTime = $scope.factoredTime * 1440;
            }
            else {
                $scope.meeting.reminderTime = $scope.factoredTime;
            }
        }
    );
    $scope.$watch(
        function (scope) { return scope.timeFactor },
        function (newValue, oldValue) {
            if ($scope.timeFactor == "Days") {
                $scope.meeting.reminderTime = $scope.factoredTime * 1440;
            }
            else {
                $scope.meeting.reminderTime = $scope.factoredTime;
            }
        }
    );


    $scope.refreshMeetingPromise();

    $scope.openEditor = function () {
        if (!embeddedData.canUpdate) {
            alert("Unable to update meeting because you are not playing an update role in the workspace");
            return;
        }
        $scope.extendBackgroundTime();
        if ($scope.meeting.state < 1) {
            alert("Post the meeting before entering any minutes / notes.");
            return;
        }
        if ($scope.meeting.state != 2) {
            if (confirm("Meeting is not running.   Set meeting into Run mode before taking notes?")) {
                $scope.changeMeetingState(2);
            }
        }
        window.open('MeetingMinutes.htm?id=' + $scope.meeting.id);
    }

    $scope.createTime = function (fieldName, newTime) {
        if (!embeddedData.canUpdate) {
            alert("Unable to update meeting because you are not playing an update role in the workspace");
            return;
        }
        //first, ignore new duplicate values
        let found = false;
        $scope.meeting.timeSlots.forEach(function (timeSlot) {
            if (newTime == timeSlot.proposedTime) {
                found = true;
            }
        });
        if (found) {
            return;
        }
        var obj = { action: "AddTime", isCurrent: true, time: newTime };
        var postURL = "proposedTimes.json?id=" + $scope.meeting.id;
        var postdata = angular.toJson(obj);
        $scope.showTimeAdder = false;
        $http.post(postURL, postdata)
            .success(function (data) {
                setMeetingData(data);
            })
            .error(function (data, status, headers, config) {
                $scope.reportError(data);
            });
    }
    $scope.addProposedVoter = function (fieldName, newVoter) {
        var current = $scope.meeting[fieldName];
        if (newVoter) {
            current.forEach(function (slot) {
                if (!slot.people[newVoter]) {
                    $scope.setVote(fieldName, slot.proposedTime, newVoter, 3);
                }
            });
        }
    }
    $scope.removeVoter = function (unusedparameter, oldVoter) {
        var obj = { action: "RemoveUser", isCurrent: isCurrent, user: oldVoter };
        var postURL = "proposedTimes.json?id=" + $scope.meeting.id;
        var postdata = angular.toJson(obj);
        $http.post(postURL, postdata)
            .success(function (data) {
                setMeetingData(data);
            })
            .error(function (data, status, headers, config) {
                $scope.reportError(data);
            });
    }
    $scope.removeTime = function (time) {
        if (!embeddedData.canUpdate) {
            alert("Unable to update meeting because you are not playing an update role in the workspace");
            return;
        }
        var hasSetting = false;
        if ($scope.meeting.timeSlots) {
            $scope.meeting.timeSlots.forEach(function (aTime) {
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

        var obj = { action: "RemoveTime", isCurrent: true, time: time };
        var postURL = "proposedTimes.json?id=" + $scope.meeting.id;
        var postdata = angular.toJson(obj);
        $http.post(postURL, postdata)
            .success(function (data) {
                setMeetingData(data);
            })
            .error(function (data, status, headers, config) {
                $scope.reportError(data);
            });
    }
    $scope.setVote = function (unusedparameter, time, resp, newVal) {
        var obj = { action: "SetValue", isCurrent: true, time: time, user: resp, value: newVal };
        var postURL = "proposedTimes.json?id=" + $scope.meeting.id;
        var postdata = angular.toJson(obj);
        $http.post(postURL, postdata)
            .success(function (data) {
                setMeetingData(data);
            })
            .error(function (data, status, headers, config) {
                $scope.reportError(data);
            });
    }
    $scope.setProposedTime = function (propTime) {
        $scope.newProposedTime = propTime;
    }
    $scope.setMeetingTime = function (propTime) {
        $scope.meeting.startTime = propTime;
        $scope.savePartialMeeting(['startTime']);
    }
    $scope.checkRole = function () {
        $scope.roleWarningMessage = "Checking role " + $scope.meeting.targetRole + " now.";
        var postURL = "isRolePlayer.json?role=" + encodeURIComponent($scope.meeting.targetRole);
        $http.get(postURL)
            .success(function (data) {
                if (data.isPlayer) {
                    $scope.roleWarningMessage = null;
                }
                else {
                    $scope.roleWarningMessage = "You are not a player of " + $scope.meeting.targetRole + ". If you save this, you will no longer have access to this meeting.";
                }
            })
            .error(function (data, status, headers, config) {
                $scope.roleWarningMessage = "Unable to read role information about " + $scope.meeting.targetRole;
            });
    }
    $scope.labelButtonClass = function (state, item) {
        if ("Items" == $scope.displayMode && item) {
            if (item.id == $scope.selectedItem.id) {
                return "btn btn-default btn-raised btn-success";
            }
            else {
                return "btn btn-default btn-raised btn-outline-primary";
            }
        }
        if (state == $scope.displayMode) {
            return "btn btn-default btn-raised btn-success";
        }
        else {
            return "btn btn-default btn-raised btn-outline-primary";
        }
    }
    $scope.setSelectedItem = function (item) {
        $scope.selectedItem = item;

        $scope.uiState.selectedItemId = item.id;
        WCACHE.putObj("MEET" + $scope.meetId, $scope.uiState, new Date().getTime());
    }
    $scope.setSelectedItemById = function (itemId) {
        $scope.getAgendaItems().forEach(function (item) {
            if (itemId == item.id) {
                $scope.setSelectedItem(item);
            }
        });
    }


    $scope.toggleAttend = function (person) {
        var saveRecord = {};
        if (person.attended) {
            saveRecord.attended_remove = person.key;
        }
        else {
            saveRecord.attended_add = person.key;
        }
        $scope.putGetMeetingInfo(saveRecord);
        person.attended = !person.attended;
    }
    $scope.changeMeetingMode = function (newMode) {
        $scope.selectedItem = {};
        $scope.extendBackgroundTime();
        $scope.displayMode = newMode;
        let stateObj = {
            foo: newMode
        }
        $scope.uiState.displayMode = newMode;
        WCACHE.putObj("MEET" + $scope.meetId, $scope.uiState, new Date().getTime());
    }


    $scope.loadAgenda = function () {
        let getURL = "MeetPrint.htm?id=" + $scope.meeting.id + "&tem=" + $scope.meeting.notifyLayout;
        $http.get(getURL)
            .success(function (data) {
                $scope.htmlAgenda = data;
            })
            .error(function (data, status, headers, config) {
                $scope.reportError(data);
            });
    }
    $scope.loadMinutes = function () {
        let getURL = "MeetPrint.htm?id=" + $scope.meeting.id + "&tem=" + $scope.meeting.defaultLayout;
        $http.get(getURL)
            .success(function (data) {
                $scope.htmlMinutes = data;
            })
            .error(function (data, status, headers, config) {
                $scope.reportError(data);
            });
    }

    $scope.copyNotes = function (item) {
        var confirmed = confirm("Do you want to copy last meeting's notes/minutes into the notes for this meeting for this agenda item?");
        if (confirmed) {
            if (item.minutes) {
                item.minutes = item.minutes + "\n\n" + item.lastMeetingMinutes;
            }
            else {
                item.minutes = item.lastMeetingMinutes;
            }
            $scope.saveAgendaItemParts(item, ['minutes']);
        }
    }

    $scope.openNotesDialog = function (agendaItem) {
        console.log("openNotesDialog called");
        if ($scope.workspaceInfo.frozen) {
            alert("Workspace is frozen so notes can not be edited");
            return;
        }

        if (!embeddedData.canUpdate) {
            alert("Unable to update meeting because you are not playing an update role in the workspace");
            return;
        }
        if (!agendaItem || !agendaItem.id) {
            alert("Please select an agenda item, and try again");
            return;
        }

        $scope.cancelBackgroundTime();

        var notesModalInstance = $modal.open({
            animation: true,
            templateUrl: embeddedData.retPath + "new_assets/templates/MeetingNotes.html" + templateCacheDefeater,
            controller: 'MeetingNotesCtrlx',
            size: 'lg',
            backdrop: "static",
            resolve: {
                agendaId: function () {
                    return agendaItem.id;
                },
                meetId: function () {
                    return $scope.meetId;
                }
            }
        });

        notesModalInstance.result
            .then(function () {
                $scope.refreshMeetingPromise();
                $scope.extendBackgroundTime();
            }, function () {
                //cancel action - nothing really to do
                $scope.extendBackgroundTime();
                $scope.getSims();
            });
    };

    $scope.isPresent = function (tuid) {
        var found = false;
        $scope.meeting.visitors.forEach(function (visitor) {
            if (tuid == visitor.uid) {
                found = true;
            }
        });
        return found;
    }
    $scope.refreshCommentList = function () {
        $scope.refreshMeetingPromise(true);
    }

    $scope.tuneNewComment = function (newComment) {
        newComment.containerType = "M";
        newComment.containerID = $scope.meetId + ":" + $scope.selectedItem.id;
    }
    $scope.tuneNewDecision = function (newDecision, cmt) {
        newDecision.sourceId = $scope.meeting.id;
        newDecision.sourceType = 7;
    }
    $scope.refreshCommentContainer = function () {
        $scope.refreshMeetingPromise(true);
        $scope.extendBackgroundTime();
    }
    setUpCommentMethods($scope, $http, $modal);

    //this is the display state of the meeting for user
    $scope.uiState = WCACHE.getObj("MEET" + $scope.meetId);
    if ($scope.uiState.displayMode) {
        $scope.changeMeetingMode($scope.uiState.displayMode);
    }
    else if (embeddedData.mode) {
        $scope.changeMeetingMode(embeddedData.mode);
    }
    $scope.setSelectedItemById($scope.uiState.selectedItemId);


    $scope.timeRowStyle = function (time) {
        if (time.proposedTime == $scope.meeting.startTime) {
            return { "background-color": "#cddacd", "border": "2px solid green", borderRadius: "5px" };
        }
        return {};
    }


    function calcResponders(slots, AllPeople, siteId) {
        var res = [];
        var checker = [];
        slots.forEach(function (person) {
            if (checker.indexOf(person.uid) < 0) {
                let onePerson = AllPeople.findUserFromID(person.uid, siteId);
                if (onePerson && onePerson.uid) {
                    res.push(onePerson);
                }
                checker.push(person.uid);
            }
        });
        if (checker.indexOf(embeddedData.userId) < 0) {
            let onePerson = AllPeople.findUserFromID(embeddedData.userId, siteId);
            if (onePerson && onePerson.uid) {
                res.push(onePerson);
            }
        }
        res.forEach(function (person) {
            person.sitchChoice = "Unknown";
            person.sitchText = "";
            $scope.meeting.rollCall.forEach(function (rc) {
                if (rc.uid === person.uid) {
                    person.sitchChoice = rc.attend;
                    person.sitchText = rc.situation;
                }
            });
        });
        res.sort(function (a, b) {
            return a.name.localeCompare(b.name);
        });
        return res;
    }
    $scope.goToMobileUi = function() {
        let dest = "RunMeeting.wmf?meetId="+$scope.meetId;
        console.log("NAV TO: "+dest);
        window.location.assign(dest);
    }

});


app.filter('minutes', function () {

    return function (input) {
        if (!input) {
            return "";
        }
        var neg = "";
        if (input < 0) {
            neg = "-";
            input = 0 - input;
        }
        var mins = Math.floor(input);
        var secs = Math.floor((input - mins) * 60);
        if (secs < 10) {
            return neg + mins + ":0" + secs;
        }
        return neg + mins + ":" + secs;

    }

});