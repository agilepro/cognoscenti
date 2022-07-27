app.controller('ModalResponseCtrl', function ($scope, $modalInstance, cmtId, responseUser, $http, $interval) {

    $scope.responseUser = responseUser;
    $scope.cmtId = cmtId;
    $scope.cmt = {};
    $scope.response = {};
    $scope.lastSave = new Date().getTime();
    getComment();
    
    function reportError(data) {
        console.log("ERROR in ResponseModel Dialog: ", data);
    }
    function getComment() {
        var getURL = "info/comment?cid="+$scope.cmtId;
        console.log("calling: ",getURL);
        $http.get(getURL)
        .success( function(data) {
            setComment(data);
        })
        .error( function(data, status, headers, config) {
            reportError(data);
        });
    }
    function saveComment(close) {
        var postURL = "info/comment?cid="+$scope.cmtId;
        var updateRec = {time:$scope.cmtId, responses:[]};
        var responseObj = {user: $scope.responseUser, body: $scope.responseBody, choice: $scope.response.choice};
        updateRec.responses.push(responseObj);
        var postdata = angular.toJson(updateRec);
        console.log("saving new comment: ",updateRec);
        $scope.lastSave = new Date().getTime();
        $http.post(postURL ,postdata)
        .success( function(data) {
            setComment(data);
            if ("Y"==close) {
                $modalInstance.close();
            }
        })
        .error( function(data, status, headers, config) {
            reportError(data);
        });
    }
    function setComment(newComment) {
        newComment.choices = ["Consent", "Objection"];
        $scope.displayText = convertMarkdownToHtml(newComment.body + "\n\n" + newComment.outcome);
        $scope.cmt = newComment;
        if (newComment.commentType == 2) {
            $scope.choices = newComment.choices;
        }
        else {
            $scope.choices = ["Save Response"];
        }
        var thisResponse = "";
        newComment.responses.forEach( function(item) {
            if ($scope.responseUser == item.user) {
                thisResponse = item.body;
            }
        });
        if (!$scope.response.choice) {
            $scope.response.choice = newComment.choices[0];
        }
        
        if (thisResponse != $scope.responseBody) {
            //only set it if different so that cursor does not move
            $scope.responseBody = thisResponse;
            $scope.responseHtml = convertMarkdownToHtml(thisResponse);
        }
        
        $scope.oldResponseBody = $scope.responseBody;
        $scope.unsaved = 0;
    }
        
    $scope.tinymceOptions = standardTinyMCEOptions();
    $scope.tinymceOptions.height = 300;
	$scope.tinymceOptions.init_instance_callback = function(editor) {
        $scope.initialContent = editor.getContent();
	    editor.on('Change', tinymceChangeTrigger);
        editor.on('KeyUp', tinymceChangeTrigger);
        editor.on('Paste', tinymceChangeTrigger);
        editor.on('Remove', tinymceChangeTrigger);
        editor.on('Format', tinymceChangeTrigger);
    }


    $scope.saveAndExit = function (choice) {
        if (choice) {
            $scope.response.choice = choice;
        }
        saveComment("Y");
    };

    $scope.commentTypeName = function() {
        if ($scope.cmt.commentType==2) {
            return "Proposal";
        }
        if ($scope.cmt.commentType==3) {
            return "Round";
        }
        return "Comment";
    }
    
    //this fires every keystroke to maintain change flag
    function tinymceChangeTrigger(e, editor) {
        $scope.lastKeyTimestamp = new Date().getTime();
        $scope.responseBody = HTML2Markdown($scope.responseHtml);
        if ($scope.responseBody != $scope.oldResponseBody ) {
            $scope.unsaved = 1;
        }
        else {
            $scope.unsaved = 0;
        }
    }
    
    
    /** AUTOSAVE
     * this part of the controller enables an autosave every 30 seconds
     */
    // TODO Make autosave interval configureable
    // TODO Add autosave enable/disable to configuration
	
	// check for updateComment() in parent scope to disable autosave
	$scope.autosaveEnabled = true;
    $scope.lastKeyTimestamp = new Date().getTime();
	
    $scope.autosave = function() {
        if ($scope.responseBody != $scope.oldResponseBody) {
            $scope.unsaved = 1;
        }
        else {
            $scope.unsaved = 0;
        }
        var secondsSinceKeypress = Math.floor((new Date().getTime() - $scope.lastKeyTimestamp)/1000);
        var secondsSinceLastSave = Math.floor((new Date().getTime() - $scope.lastSave)/1000);
        $scope.secondsTillSave = 20 - secondsSinceKeypress;
        $scope.secondsTillClose = 1200 - secondsSinceKeypress;
        if (secondsSinceKeypress > 1200) {
            //it has been 1200 seconds (20 minutes) since any save or keystroke
            //time to close this pop up dialog
            console.log("Auto close time achieved, closing the dialog box", $scope);
            $scope.saveAndClose();
        }
        if (secondsSinceKeypress < 20 || secondsSinceLastSave < 20) {
            //user has typed in last 20 seconds to wait until 20 seconds of silence
            return;
        }
        if ($scope.unsaved) {
            $scope.unsaved = -1;
            saveComment("N");
            return;
        }
        if (secondsSinceLastSave > 60) {
            getComment();
        }
    }
	if ($scope.autosaveEnabled) {
        if ($scope.promiseAutosave) {
            console.log("ATTEMPT TO DOUBLE START THE TIMER");
        }
        else {
            //check for autosave every second, but only save when user pauses
            $scope.promiseAutosave = $interval($scope.autosave, 1000);
        }
    }
        

});