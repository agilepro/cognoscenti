
app.controller('CommentModalCtrl', function ($scope, $modalInstance, $modal, $interval, cmt, parentScope, AllPeople, attachmentList, docSpaceURL) {

    // initial comment object
    $scope.cmt = cmt;
    if (!cmt.docs) {
        cmt.docs = [];
    }
    // parent scope with all the crud methods
    $scope.parentScope = parentScope;
    // are there unsaved changes?
	$scope.unsaved = 0;
	// controls if comment can be saved
	$scope.saveDisabled = false;
    
    $scope.docSpaceURL = docSpaceURL;
    $scope.attachmentList = attachmentList;
	
	// return a readable status message
	$scope.getStatusMassage = function() {
		switch ($scope.unsaved) {
            case -1:    return "Autosave completed";
            case 0:     return "No changes";
            case 1:     return "Unsaved changes";
        }
	};
	
	$scope.dummyDate1 = new Date();
    if (cmt.dueDate>0) {
        $scope.dummyDate1 = new Date(cmt.dueDate);
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

    function tinymceChangeTrigger(e, editor) {
        if (tinyMCE.activeEditor.getContent() != $scope.initialContent)
            $scope.unsaved = 1;
        else $scope.unsaved = 0;
    }

    $scope.postIt = function () {
        if ($scope.cmt.state == 11 && $scope.autosaveEnabled) {
            $scope.cmt.state = 12;
        }
        $scope.cmt.dueDate = $scope.dummyDate1.getTime();
        if ($scope.cmt.state==12) {
            if ($scope.cmt.commentType==1 || $scope.cmt.commentType==5) {
                $scope.cmt.state=13;
            }
        }
        $scope.saveAndClose();
   };

    $scope.save = function() {
		$scope.saveDisabled = true;
        $scope.cmt.dueDate = $scope.dummyDate1.getTime();
		$scope.$$hashKey = 250;
        $scope.parentScope.updateComment($scope.cmt);
        $scope.unsaved = 0;
        $scope.cmt.isNew = false;
    }

    $scope.saveAndClose = function () {
		
		// warn message if there are unsaved changes
		var r = true;
		$scope.save();
		
		// stop autosave interval
        $interval.cancel($scope.promiseAutosave);
		
        $modalInstance.dismiss('cancel');
    };

    $scope.commentTypeName = function() {
        if ($scope.cmt.commentType==2) {
            return "Proposal";
        }
        if ($scope.cmt.commentType==3) {
            return "Round";
        }
        if ($scope.cmt.commentType==5) {
            return "Minutes";
        }
        return "Comment";
    }

    $scope.getVerbHeader = function() {
        if ($scope.cmt.isNew) {
            return "Create";
        }
        return "Update";
    }
	
    $scope.datePickOptions = {
        formatYear: 'yyyy',
        startingDay: 1
    };
    $scope.datePickOpen1 = false;
    $scope.openDatePicker1 = function($event) {
        $event.preventDefault();
        $event.stopPropagation();
        $scope.datePickOpen1 = true;
    };
    $scope.datePickDisable = function(date, mode) {
        return false;
    };

    /** AUTOSAVE
     * this part of the controller enables an autosave every 30 seconds
     */
    // TODO Make autosave interval configureable
    // TODO Add autosave enable/disable to configuration
	
	// check for updateComment() in parent scope to disable autosave
	$scope.autosaveEnabled = true;
	if ($scope.parentScope.updateComment == undefined) {
		$scope.autosaveEnabled = false;
    }
	
    $scope.autosave = function() {
        if ($scope.unsaved == 1) {
            $scope.save();
            $scope.unsaved = -1;
        }
    }
	if ($scope.autosaveEnabled) {
		$scope.promiseAutosave = $interval($scope.autosave, 15000);
    }
    
    $scope.loadPersonList = function(query) {
        return AllPeople.findMatchingPeople(query);
    }
    $scope.itemHasDoc = function(doc) {
        var res = false;
        var found = $scope.cmt.docs.forEach( function(docid) {
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
    $scope.openAttachDocument = function () {

        var attachModalInstance = $modal.open({
            animation: true,
            templateUrl: '../../../templates/AttachDocument.html?s=a',
            controller: 'AttachDocumentCtrl',
            size: 'lg',
            resolve: {
                docList: function () {
                    return JSON.parse(JSON.stringify($scope.cmt.docs));
                },
                attachmentList: function() {
                    return $scope.attachmentList;
                },
                docSpaceURL: function() {
                    return $scope.docSpaceURL;
                }
            }
        });

        attachModalInstance.result
        .then(function (docList) {
            $scope.cmt.docs = docList;
        }, function () {
            //cancel action - nothing really to do
        });
    };


});