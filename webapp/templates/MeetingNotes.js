console.log("loaded the MeetingNotesCtrl");

app.controller('MeetingNotesCtrl', function ($scope, $modalInstance, $http, $interval, meetId, agendaId, AllPeople) {

    console.log("loaded the MeetingNotesCtrl");

    $scope.meetId = meetId;
    $scope.agendaId = agendaId;
    $scope.agendaData = null;
    $scope.readyToLeave = false;
    
    
    $scope.ok = function () {
        $scope.saveMinutes();
        $scope.readyToLeave = true;
    };

    $scope.cancel = function () {
        $modalInstance.dismiss('cancel');
    };

    $scope.loadPersonList = function(query) {
        return AllPeople.findMatchingPeople(query, $scope.siteId);
    }

    $scope.setMinutesData = function(data) {
        $scope.timerCorrection = data.serverTime - new Date().getTime();
        $scope.visitors = data.visitors;
        data.minutes.forEach( function(newItem) {
            if (newItem.id == $scope.agendaId) {
                updateItemData($scope.agendaData, newItem);
            }
        });
    }
    
    function updateItemData(oldItem, newItem) {
        if (!newItem) {
            //strange, no information about the agenda item being edited
            return;
        }
        if (!$scope.agendaData) {
            $scope.agendaData = newItem;
            oldItem = newItem;
            oldItem.old = newItem.new;
        }
        else if (newItem.new == oldItem.lastSave) {
            //if you get back what you sent to the server
            //then ignore it and don't update at all
            //whether user typing or not
            oldItem.old = oldItem.lastSave;
            oldItem.needsMerge = false;
        } 
        else if (newItem.new != oldItem.new) {
            //unfortunately, there are edits from someone else to 
            //merge in causing some loss from of current typing.
            console.log("merging new version from server.",newItem,oldItem);
            oldItem.needsMerge = true;
            oldItem.old = oldItem.lastSave;
        }
        else {
            oldItem.old = newItem.new;
            oldItem.needsMerge = false;
        }
        oldItem.lastSave = null;
        oldItem.timerRunning = newItem.timerRunning;
        oldItem.timerStart = newItem.timerStart;
        oldItem.timerElapsed = newItem.timerElapsed;
        oldItem.duration = newItem.duration;
        oldItem.title = newItem.title;   
    }
    $scope.handleDeferred = function() {
        $scope.isUpdating = false;
        if ($scope.deferredUpdate) {
            $scope.deferredUpdate = false;
            $scope.autosave();
        }
    }
    $scope.getMeetingNotes = function() {
        $scope.isUpdating = true;
        var postURL = "getMeetingNotes.json?id="+$scope.meetId;
        $http.get(postURL)
        .success( function(data) {
            $scope.setMinutesData(data);
            $scope.handleDeferred();
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
            $scope.handleDeferred();
        });
        
    }
    $scope.getMeetingNotes();
    $scope.saveMinutes = function(min) {
        if ($scope.isUpdating) {
            console.log("update was deferred because we are already updating");
            $scope.deferredUpdate = true;
            return;
        }
        $scope.autosave();
    }
    $scope.autosave = function() {
        if ($scope.showError) {
            console.log("Autosave is turned off when there is an error.")
            return;
        }
        if ($scope.isUpdating) {
            console.log("update was skipped because we are already updating");
            return;
        }
        $scope.isUpdating = true;
        var postURL = "updateMeetingNotes.json?id="+$scope.meetId;
        var postRecord = {minutes:[]};
        if ($scope.agendaData.new != $scope.agendaData.old) {
            postRecord.minutes.push( JSON.parse( JSON.stringify( $scope.agendaData )));
        }
        $scope.agendaData.lastSave = $scope.agendaData.new;
        
        var postData = JSON.stringify(postRecord);
        $http.post(postURL, postData)
        .success( function(data) {
            $scope.setMinutesData(data);
            $scope.handleDeferred();
            if ($scope.readyToLeave) {
                $modalInstance.close();
            }
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
            $scope.handleDeferred();
        });
    }
	$scope.promiseAutosave = $interval($scope.autosave, 3000);



});