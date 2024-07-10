console.log("loaded the MeetingNotesCtrl");

/*
Agenda item data looks like this:
{
  "duration": 30,
  "id": "6569",
  "new": "This is the current value that I am typing.",
  "pos": 1,
  "timerElapsed": 0,
  "timerRunning": false,
  "timerStart": 0,
  "title": "Review the Minutes from last meeting"
}

The "new" entry is being edited always.
locally, in memory, we have another member which holds the value 
from the server.


  "old": "this is what I think is on the server",


The old is there to compare with what we received so we know what we have changed
and also:


  "lastSave": "this is what I had when I last saved",
  
  
TIME OF SAVE

OLD: holds the last official version from server
NEW: holds user changes
Send the old and the new to the server.   
The difference between these is what I have typed: MY_FIRST_CHANGES
Store a copy of new into lastSave so that we know what has changed since the save: MY_LATER_CHANGES

RESPONSE FROM SERVER

Server returns a "new" value to client.
The difference between received.new and lastSave is SERVER_CHANGES.
The difference between client.new and lastSave is MY_LATER_CHANGES

Merge the SERVER_CHANGES into new and update what you are working on
Merge SERVER_CHANGES into old causes old == received.new

So that the user is not interrupted, we DEFER the update from the server to the new.
The update from the server is in the old and the difference is between old and lastSave.
So at the time the user clicks "merge" it merges the difference between old and lastSave.
Note that while deferred, you must not do another save.

  

*/




app.controller('MeetingNotesCtrlx', function ($scope, $modalInstance, $http, $interval, meetId, agendaId, AllPeople) {

    console.log("loaded the MeetingNotesCtrl");

    $scope.meetId = meetId;
    $scope.agendaId = agendaId;
    $scope.agendaData = null;
    $scope.readyToLeave = false;
    $scope.isEditing = true;
    $scope.autoMerge = false;
    $scope.editMode = "edit";
    $scope.agendaWiki = "";
    $scope.agendaHtml = "";
    
    $scope.tinymceOptions = standardTinyMCEOptions();
    $scope.tinymceOptions.height = 300;
    
    $scope.ok = function () {
        $interval.cancel($scope.promiseAutosave);
        $scope.saveMinutes();
        $scope.readyToLeave = true;
    };

    $scope.cancel = function () {
        $interval.cancel($scope.promiseAutosave);
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
        if (!$scope.agendaData || !$scope.isEditing) {
            $scope.agendaData = newItem;
            oldItem = newItem;
            oldItem.old = newItem.new;
            $scope.isEditing = true;
            if (newItem.new != $scope.agendaWiki) {
                $scope.agendaWiki = newItem.new;
                $scope.agendaHtml = convertMarkdownToHtml(newItem.new);
            }
        }
        else if (newItem.new == oldItem.lastSave) {
            //if you get back what you sent to the server
            //then nothing has changed on the server, so you
            //can ignore the update and don't update at all
            //whether user typing or not
            oldItem.old = oldItem.lastSave;
            oldItem.needsMerge = false;
            if (newItem.new != $scope.agendaWiki) {
                $scope.agendaWiki = newItem.new;
                $scope.agendaHtml = convertMarkdownToHtml(newItem.new);
            }
        } 
        else if (newItem.new != oldItem.new) {
            //unfortunately, there are edits from someone else to 
            //merge in causing some loss from of current typing.
            if ($scope.autoMerge) {
                console.log("merging new version from server.",newItem,oldItem);
                oldItem.new = Textmerger.get().merge(oldItem.lastSave, oldItem.new, newItem.new);
                oldItem.old = newItem.new;
                if (newItem.new != $scope.agendaWiki) {
                    $scope.agendaWiki = newItem.new;
                    $scope.agendaHtml = convertMarkdownToHtml(newItem.new);
                }
            }
            else {
                oldItem.needsMerge = true;
                oldItem.old = oldItem.lastSave;
            }
        }
        else {
            oldItem.old = newItem.new;
            oldItem.needsMerge = false;
            if (newItem.new != $scope.agendaWiki) {
                $scope.agendaWiki = newItem.new;
                $scope.agendaHtml = convertMarkdownToHtml(newItem.new);
            }
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
        console.log("GETTING notes");
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
        console.log("AUTOSAVE");
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
        $scope.agendaWiki = HTML2Markdown($scope.agendaHtml, {});
        $scope.agendaData.new = $scope.agendaWiki;
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

    $scope.mergeNewData = function() {
        $scope.isEditing = false;
        $scope.autosave();
    }
    $scope.bodyStyle = function() {
        if ($scope.agendaData && $scope.agendaData.needsMerge) {
            return {"background-color":"orange","min-height":"400px"};
        }
        else {
            return {"background-color":"white","min-height":"400px"};
        }
    }

});