
var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal, $interval, AllPeople, $timeout) {
    window.setMainPageTitle("Meeting");
    
    var isLinkToComment = ( window.location.href.indexOf("#")>0 );
    
    $scope.siteInfo = embeddedData.siteInfo;
    $scope.workspaceInfo = embeddedData.workspaceInfo;
    $scope.pageId = embeddedData.pageId;
    $scope.meetId = embeddedData.meetId;
    $scope.meeting = {rollCall:[],agenda:[],participants:[]};
    $scope.previousMeeting = embeddedData.previousMeeting;
    $scope.allGoals = embeddedData.allGoals;
    $scope.attachmentList = [];
    $scope.allRoles = embeddedData.allRoles;
    $scope.allLabels = embeddedData.allLabels;
    $scope.allLayoutNames = embeddedData.allLayoutNames;
    $scope.allTopics = [];
    $scope.timeFactor = "Minutes";
    $scope.factoredTime = 0;
    $scope.displayMode='Items';
    if (embeddedData.mode) {
        $scope.displayMode=embeddedData.mode;
    }
    $scope.htmlAgenda = "";
    $scope.htmlMinutes = "";
    
    $scope.userZone = embeddedData.userZone;
    $scope.browserZone = Intl.DateTimeFormat().resolvedOptions().timeZone;
    
    $scope.showTimeSlots = false;
    $scope.timeSlotResponders = [];
    $scope.newProposedTime = 0;
    $scope.mySitch = {uid:embeddedData.userId,attend:"Unknown",situation: ""}
    
    
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
        cancelBackgroundTime();
        //console.log("Encountered problem: ",serverErr);
        errorPanelHandler($scope, serverErr);
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
        if (!item) {
            return false;
        }
        return $scope.allTopics.filter( function(oneTopic) {
            return item.topics.includes(oneTopic.universalid);
        });
    }

    $scope.itemGoals = function(item) {
        var res = [];
        if (item) {
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
        }
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

    $scope.meetingStateName = function() {
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
        return AllPeople.findMatchingPeople(query, $scope.siteInfo.key);
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


    $scope.savePendingEdits = function(parts) {
        if (!parts) {
            parts = [];
        }
        if ($scope.editMeetingDesc) {
            var newMarkdown = HTML2Markdown($scope.meeting.descriptionHtml, {});
            if (newMarkdown != $scope.meeting.description) {
                $scope.meeting.descriptionMerge = {old: $scope.meeting.description, new: newMarkdown};
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
    $scope.stopAgendaRunning = function() {
        var saveRecord = {};
        saveRecord.stopTimer = "0";
        $scope.putGetMeetingInfo(saveRecord);
    }
    
    $scope.setItemTime = function(item, op) {
        var nowTime = new Date().getTime() + $scope.timerCorrection;
        if (item.timerRunning) {
            item.timerElapsed = nowTime - item.timerStart;
            item.timerStart = nowTime;
        }
        if ("incr"==op) {
            item.timerElapsed = item.timerElapsed+60000;
        }
        else if ("decr"==op) {
            item.timerElapsed = item.timerElapsed-60000;
        }
        else if ("floor"==op) {
            item.timerElapsed = Math.floor(item.timerElapsed/60000)*60000;
        }
        else if ("ceil"==op) {
            item.timerElapsed = Math.ceil(item.timerElapsed/60000)*60000;
        }
        else {
            return; //skip the save
        }
        $scope.saveAgendaItem(item);
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
    $scope.timerStyleComplete = function(item) {
        if (!item) {
            return {};
        }
        if (!item.timerRunning) {
            if (item.proposed) {
                return {"background-color":"yellow"};
            }            
            if (item.isSpacer) {
                return {"background-color":"#bbbbbb"}
            }
            return {};
        }
        if (item.duration - item.timerTotal<0) {
            return {"background-color":"orangered", "color":"black"};
        }
        return {"background-color":"lightgreen", "color":"black"};
    }
    
    $scope.itemTabStyleComplete = function(item) {
        if (!item) {
            return {};
        }
        let style = {"background-color":"white", 
                     "color":"black", 
                     "border": "4px solid white",
                     "border-right": "none"};
        if (!item.timerRunning) {
            if (item.proposed) {
                style["background-color"] = "yellow";
            }            
            else if (item.isSpacer) {
                style["background-color"] = "#bbbbbb";
            }
        }
        else if (item.duration - item.timerTotal<0) {
            style["background-color"] = "orangered";
        }
        else {
            style["background-color"] = "lightgreen";
        }
        if ($scope.selectedItem && item.position==$scope.selectedItem.position) {
            style.border = "4px solid black";
            style["border-right"] = "none"
        }
        return style;
    }
    
    //don't know if we need this one any more....
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
        $scope.meeting.state = newState;
        $scope.savePendingEdits(['state']);
        $scope.stopAgendaRunning();
    };
    $scope.toggleSpacer = function(item) {
        item.isSpacer = !item.isSpacer;
        $scope.saveAgendaItemParts(item, ['isSpacer']);
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
        fieldList.forEach( function(ele) {
            //if (agendaItem[ele]) {
                itemCopy[ele] = agendaItem[ele];
            //}
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
            console.log("GETTING meeting info");
            promise = $http.get("meetingRead.json?id="+$scope.meetId);
        }
        promise.success( function(data) {
            if (readyToSave) {
                $scope.extendBackgroundTime();
            }
            setMeetingData(data);
        });
        promise.error( function(data, status, headers, config) {
            console.log("Error", data);
            $scope.reportError(data);
        });
        $scope.showError=false;
        return promise;
    };
    $scope.refreshMeetingPromise = function() {
        return $scope.putGetMeetingInfo(null);
    }
    $scope.getImageName = function(item) {
        if (item) {
            return AllPeople.imageName(item);
        }
        else {
            return "fake-~.jpg";
        }
    }
    $scope.singleTryToAdd = true;
    function addYouselfIfAppropriate() {
        // the problem here is that SLAP.loginInfo.userId is not necessarily
        // the preferred email address in the profile, and in that case,
        // you will never fine this address in the list.
        // For now, manual setting of attended ONLY
        if ($scope.singleTryToAdd) {
            if ($scope.meeting.state==2) {
                var foundMe = false;
                $scope.meeting.attended.forEach( function(item) {
                    if (item==SLAP.loginInfo.userId) {
                        foundMe=true;
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
        
        if (!data.participants) {
            data.participants = [];
        }
        if (data.participants.length==0) {
            let person = AllPeople.findPerson(data.owner, $scope.siteInfo.key);
            if (person) {
                data.participants.push(person);
            }
        }
        
        data.participants.forEach( function(item) {
            if (item) {
                item.image = AllPeople.imageName(item);
            }
        });
        var totalAgendaTime = 0;
        data.agenda.forEach( function(item) {
            if (!item.proposed) {
                totalAgendaTime += item.duration;
            }
            item.minutesHtml = convertMarkdownToHtml(item.minutes);
            item.descriptionHtml = convertMarkdownToHtml(item.description);
            //make sure this is not appearing anywhere
            item.desc = "N/A";
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
        addYouselfIfAppropriate();
        data.timeSlots.sort(function(a,b) {
            return a.proposedTime - b.proposedTime;
        });
        if (data.timeSlots && data.timeSlots.length>0) {  
            $scope.newProposedTime = data.timeSlots[data.timeSlots.length-1].proposedTime;
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
        if (!$scope.selectedItem) {
            if (data.agenda && data.agenda.length>0) {
                $scope.selectedItem = data.agenda[0];
            }
        }
        else {
            data.agenda.forEach( function(item) {
                if (item.position == $scope.selectedItem.position) {
                    $scope.selectedItem = item;
                }
            });
        }
        
        $scope.loadAgenda();
        $scope.loadMinutes();
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
                //console.log("meeting is missing user from role: ", rolePerson);
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
            for (var j=0; j<$scope.participantEditCopy.length; j++) {
                var participant = $scope.participantEditCopy[j];
                if (participant.uid == rolePerson.uid) {
                    found = true;
                }
            }
            if (!found) {
                $scope.participantEditCopy.push(rolePerson);
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
        var res = AllPeople.findMatchingPeople(query, $scope.siteInfo.key);
        return res;
    }


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
        objForUpdate.checklist = goal.checklist;        //fourth thing that could have been changed
        var postdata = angular.toJson(objForUpdate);
        $scope.showError=false;
        $scope.editGoalInfo=false;
        $scope.showAccomplishment=false;
        $http.post(postURL, postdata)
        .success( function(data) {
            $scope.replaceGoal(data);
            $scope.constructAllCheckItems();
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };

    $scope.refreshCount = 0;
    $scope.extendCount = 0;
    $scope.saveCount = 0;
    $scope.lastAutoSave = new Date().getTime();
    function cancelBackgroundTime() {
        console.log("BACKGROUND cancelled");
        $scope.bgActiveLimit = 0;  //already past
    }
    $scope.extendBackgroundTime = function() {
        console.log("BACKGROUND time extended ("+(++$scope.extendCount)+" times) because user click");
        $scope.bgActiveLimit = (new Date().getTime())+1200000;  //twenty minutes
    }
    $scope.extendBackgroundTime();
    $scope.refresh = function() {
        var currentTime = (new Date().getTime());
        var remainingSeconds = ($scope.bgActiveLimit - currentTime)/1000;
        var secondsSinceLast = (currentTime - $scope.lastAutoSave)/1000;
        if (remainingSeconds<0) {
            console.log("AUTOSAVE deactivated");
            if (!$scope.askingToContinue) {
                $scope.askingToContinue = true;
                msg = "Background refresh stopped after 20 minutes without interaction.\n"
                           +"Click OK to manually refresh.";
                if ($scope.bgActiveLimit<=0) {
                    msg = "Background refresh stopped because of an error.\n"
                           +"Click OK to manually refresh.";
                }
                if (confirm(msg)) {
                    location.reload(true);
                }
                else {
                    $scope.askingToContinue = false;
                }
            }
            return;
        }
        console.log("AUTOSAVE:  refreshing after "+secondsSinceLast+" seconds ("+(++$scope.saveCount)+" times), shold stop in "+remainingSeconds+" seconds.");
        $scope.lastAutoSave = currentTime;
        if ($scope.meeting.state!=2) {
            console.log("AUTOSAVE: cancelled because meeting not in running state");
            $interval.cancel($scope.promiseAutosave);
            $scope.refreshStatus = "No refresh because meeting is not being run";
            return;  //don't set of refresh unless in run mode
        }
        var nowEditing = $scope.editMeetingDesc;
        if (nowEditing) {
            $scope.refreshStatus = "No refresh because currently editing";
            return;
        }
        $scope.refreshStatus = "Refreshing";
        $scope.putGetMeetingInfo( null );
        $scope.refreshCount++;
    }
    $scope.promiseAutosave = $interval($scope.refresh, 15000);

    $scope.toggleReady = function(item) {
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
            window.open("noteZoom"+topicRecord.id+".htm","_blank");
        }
        else {
            alert("Sorry, can't seem to find a discussion topic with the id: "+topicId);
        }
    }

    
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
                return;
            }
        }
        else {
            console.log("NO isArray function");
        }
        var selRole = getMeetingRole();
        var expectAttend = {};
        var expectSituation = {};
        $scope.mySitch = {};
        $scope.meeting.participants.forEach( function(item) {
            var current = {uid:item.uid,name:item.name,key:item.key,attend: "Unknown",situation: ""};
            let found = false;
            expectAttend[item.uid] = "Unknown";
            expectSituation[item.uid] = "";
            $scope.meeting.rollCall.forEach( function(rc) {
                if (rc.uid === item.uid) {
                    current.attend = rc.attend;
                    expectAttend[item.uid] = rc.attend;
                    current.situation = rc.situation;
                    expectSituation[item.uid] = rc.situation;
                }
            });
            if (item.uid === embeddedData.userId) {
                $scope.mySitch = current;
            }
        });
        $scope.expectAttend = expectAttend;
        $scope.expectSituation = expectSituation;
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
    $scope.isCompleted = function() {
        return ($scope.meeting.state >= 3);
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
        return $scope.attendedCache;
    }
    
    $scope.calcAttended = function() {
        var res = [];
        if ($scope.meeting.attended) {
            $scope.meeting.attended.forEach( function(trial) {
                var trialPerson = AllPeople.findPerson(trial, $scope.siteInfo.key);
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
        $scope.attendedCache = res;
    }

    $scope.saveSituation = function() {
        var found = false;
        $scope.meeting.rollCall.forEach( function(item) {
            if (item.uid == embeddedData.userId) {
                found = true;
                item.attend = $scope.mySitch.attend;
                item.situation = $scope.mySitch.situation;
            }
        });
        if (!found) {
            $scope.meeting.rollCall.push( {
                uid: embeddedData.userId,
                attend: $scope.mySitch.attend,
                situation: $scope.mySitch.situation
            });
        }
        $scope.savePartialMeeting(['rollCall']);
        $scope.showRollCall = $scope.isRegistered();
    }

    $scope.deleteItem = function(item) {
        if (!confirm("Are you sure you want to delete agenda item: "+item.subject)) {
            return;
        }
        var postObj = {"id": item.id};
        var postURL = "agendaDelete.json?id="+$scope.meeting.id;
        var postdata = angular.toJson(postObj);
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
        $scope.extendBackgroundTime();
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
            },
            siteId: function () {
              return $scope.siteInfo.key;
            }
          }
        });

        modalInstance.result.then(function (modifiedGoal) {
            $scope.allGoals.forEach( function(item) {
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

    $scope.constructAllCheckItems = function() {
        $scope.allGoals.forEach( function(actionItem) {
            var list = [];
            if (actionItem.checklist) {
                var lines = actionItem.checklist.split("\n");
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
            actionItem.checkitems = list;
        });
    }
    $scope.toggleCheckItem = function($event, item, changeIndex) {
        item.checkitems.forEach( function(item) {
            if (item.index==changeIndex) {
                item.checked = !item.checked;
            }
        });
        var newList = [];
        item.checkitems.forEach( function(item) {
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

    $scope.findComment = function(item, timeStamp) {
        var foundComment = null;
        if (item) {
            item.comments.forEach( function(xitem) {
                if ( xitem.time == timeStamp ) {
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
        window.open(embeddedData.retPath+"v/FindPerson.htm?uid="+encodeURIComponent(player.key),"_blank");
    }

    $scope.allowCommentEmail = function() {
        return ($scope.meeting.state>0);
    }



    $scope.openDecisionEditor = function (item, cmt) {
        $scope.extendBackgroundTime();

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


    $scope.getSelectedDocList = function(docId) {
        var doc = [];
        $scope.attachmentList.forEach( function(item) {
            if (item.universalid == docId) {
                doc.push(item);
            }
        });
        return doc;
    }
   $scope.navigateToDoc = function(docId) {
        window.open("DocDetail.htm?aid="+docId,"_blank");
    }
    $scope.sendDocByEmail = function(docId) {
        window.open("SendNote.htm?att="+docId,"_blank");
    }
    $scope.downloadDocument = function(doc) {
        if (doc.attType=='URL') {
             window.open(doc.url,"_blank");
        }
        else {
            window.open("a/"+doc.name,"_blank");
        }
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
        $scope.extendBackgroundTime();

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
        $scope.extendBackgroundTime();

        var attachModalInstance = $modal.open({
            animation: true,
            templateUrl: embeddedData.retPath+"templates/AttachTopic.html"+templateCacheDefeater,
            controller: 'AttachTopicCtrl',
            size: 'lg',
            backdrop: "static",
            resolve: {
                selectedTopics: function () {
                    return item.topics;
                },
                attachmentList: function() {
                    return $scope.allTopics;
                }
            }
        });

        attachModalInstance.result
        .then(function (selectedTopics, topicName) {
            item.topics = selectedTopics;
            $scope.saveAgendaItem(item);
        }, function () {
            //cancel action - nothing really to do
        });
    };

    $scope.openAttachAction = function (item) {
        $scope.extendBackgroundTime();

        var attachModalInstance = $modal.open({
            animation: true,
            templateUrl: embeddedData.retPath+"templates/AttachAction.html"+templateCacheDefeater,
            controller: 'AttachActionCtrl',
            size: 'lg',
            backdrop: "static",
            resolve: {
                containingQueryParams: function() {
                    return "meet="+$scope.meetId+"&ai="+item.id;
                },
                siteId: function () {
                  return $scope.siteInfo.key;
                }
            }
        });

        attachModalInstance.result
        .then(function (selectedActionItems) {
            item.actionItems = selectedActionItems;
            //no need to save...
            $scope.refreshAllGoals();
            
        }, function () {
            //cancel action - nothing really to do
        });
    };

    $scope.refreshAllGoals = function() {
        var getURL = "allActionsList.json";
        $http.get(getURL)
        .success( function(data) {
            $scope.allGoals = data.list;
            $scope.refreshMeetingPromise();
            $scope.constructAllCheckItems();
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    }



    $scope.openAgenda = function (agendaItem, display) {
        $scope.extendBackgroundTime();
        
        var displayMode = 'Settings';
        if (display) {
            displayMode = 'Description';
        }

        var agendaModalInstance = $modal.open({
            animation: true,
            templateUrl: embeddedData.retPath+"templates/Agenda.html"+templateCacheDefeater,
            controller: 'AgendaCtrl',
            size: 'lg',
            backdrop: "static",
            resolve: {
                agendaItem: function () {
                    return JSON.parse(JSON.stringify(agendaItem));
                },
                siteId: function () {
                  return $scope.siteInfo.key;
                },
                displayMode: function() {
                    return displayMode;
                }
            }
        });

        agendaModalInstance.result
        .then(function (changedAgendaItem) {
            $scope.saveAgendaItemParts(changedAgendaItem, 
                ["subject", "descriptionMerge","duration","timerElapsed","isSpacer","presenters","proposed"]);
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
            data.dates.sort();
            let tmplst = [];
            data.dates.forEach( function(item) {
                let pos = item.indexOf("(");
                let pre = item.substring(0,pos).trim();
                let post = item.substring(pos);
                tmplst.push( {"zone":post,"time":pre} );
            });
            $scope.allDates = tmplst;
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
        window.open('meetingMinutes.htm?id='+$scope.meeting.id);
    }
    
    $scope.createTime = function(fieldName,newTime) {
        //first, ignore new duplicate values
        let found = false;
        $scope.meeting.timeSlots.forEach( function(timeSlot) {
            if (newTime == timeSlot.proposedTime) {
                found=true;
            }
        });
        if (found) {
            return;
        }
        var obj = {action:"AddTime", isCurrent: true, time: newTime};
        var postURL = "proposedTimes.json?id="+$scope.meeting.id;
        var postdata = angular.toJson(obj);
        $scope.showTimeAdder=false;
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
    $scope.removeVoter = function(unusedparameter, oldVoter) {
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
    $scope.removeTime = function(time) {
        var hasSetting = false;
        if ($scope.meeting.timeSlots) {
            $scope.meeting.timeSlots.forEach( function(aTime) {
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
        
        var obj = {action:"RemoveTime", isCurrent: true, time: time};
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
    $scope.setVote = function(unusedparameter, time, resp, newVal) {
        var obj = {action:"SetValue", isCurrent: true, time: time, user: resp, value:newVal};
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
    $scope.statusButtonClass = function(state) {
        if (state==$scope.displayMode) {
            return "btn btn-primary btn-raised";
        }
        else {
            return "btn btn-default btn-raised";
        }
    }
    $scope.setSelectedItem = function(item) {
        $scope.selectedItem = item;
    }
    
    $scope.didAttend = function(specId) {
        var found = false;
        $scope.meeting.attended.forEach( function(item) {
            if (specId == item) {
                found = true;
            }
        });
        return found;
    }
    
    $scope.toggleAttend = function(specId) {
        var did = $scope.didAttend(specId);
        if (did) {
            var newArray = [];
            $scope.meeting.attended.forEach( function(item) {
                if (specId != item) {
                    newArray.push(item);
                }
            });
            $scope.meeting.attended = newArray;
        }
        else {
            $scope.meeting.attended.push(specId);
        }
        $scope.savePartialMeeting(["attended"]);
    }
    $scope.changeMeetingMode = function(newMode) {
        $scope.extendBackgroundTime();
        $scope.displayMode=newMode;
        let stateObj = {
            foo: newMode
        }
        window.history.pushState(stateObj, newMode, 'meetingHtml.htm?id='+embeddedData.meetId+'&mode='+newMode);
    }
    
    
    $scope.loadAgenda = function() {
        let getURL = "MeetPrint.htm?id="+$scope.meeting.id+"&tem="+$scope.meeting.notifyLayout;
        $http.get(getURL)
        .success( function(data) {
            $scope.htmlAgenda = data;
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    }
    $scope.loadMinutes = function() {
        let getURL = "MeetPrint.htm?id="+$scope.meeting.id+"&tem="+$scope.meeting.defaultLayout;
        $http.get(getURL)
        .success( function(data) {
            $scope.htmlMinutes = data;
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    }
    
    $scope.openNotesDialog = function (agendaItem) {
        $scope.extendBackgroundTime();
        
        var notesModalInstance = $modal.open({
            animation: true,
            templateUrl: embeddedData.retPath+"templates/MeetingNotes.html"+templateCacheDefeater,
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
        }, function () {
            //cancel action - nothing really to do
        });
    };
    $scope.startParticipantEdit = function() {
        $scope.participantEditCopy = $scope.meeting.participants
        $scope.editMeetingPart='participants';
    }
    $scope.saveParticipantEdit = function() {
        $scope.meeting.participants = $scope.participantEditCopy;
        $scope.savePendingEdits();
    }
    
    $scope.isPresent = function(tuid) {
        var found = false;
        $scope.meeting.visitors.forEach( function(visitor) {
            if (tuid == visitor.uid) {
                found = true;
            }           
        });
        return found;
    }
     $scope.setContainerFields = function(newComment) {
        newComment.containerType = "M";
        newComment.containerID = $scope.meetId+":"+$scope.selectedItem.id;
    }
    $scope.refreshCommentList = function() {
        console.log("REFRESH comment list");
        $scope.refreshMeetingPromise(true);
    }

    setUpCommentMethods($scope, $http, $modal);
   
});

function calcResponders(slots, AllPeople, siteId) {
    var res = [];
    var checker = [];
    slots.forEach( function(person) {
        if (checker.indexOf(person.uid)<0) {
            let onePerson = AllPeople.findUserFromID(person.uid, siteId);
            if (onePerson && onePerson.uid) {
               res.push(onePerson);
            }
            checker.push(person.uid);
        }
    });
    if (checker.indexOf(embeddedData.userId)<0) {
        let onePerson = AllPeople.findUserFromID(embeddedData.userId, siteId);
        if (onePerson && onePerson.uid) {
           res.push(onePerson);
        }
    }
    res.sort( function(a,b) {
        return a.name.localeCompare(b.name);
    });
    return res;
}

app.filter('minutes', function() {

  return function(input) {
    if (!input) {
        return "";
    }
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