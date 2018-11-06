
app.controller('CommentModalCtrl', function ($scope, $modalInstance, $modal, $interval, cmt, parentScope, AllPeople, attachmentList, docSpaceURL, $http) {

    // initial comment object
    setComment(cmt);
    console.log("Received comment is ", cmt);
    
	// parent scope with all the crud methods
    $scope.parentScope = parentScope;
    // are there unsaved changes?
	$scope.unsaved = 0;
	// controls if comment can be saved
	$scope.saveDisabled = false;
    
    $scope.docSpaceURL = docSpaceURL;
    $scope.attachmentList = attachmentList;
    $scope.showEmail = false;
    getComment();


    function getComment() {
        if ($scope.cmt.time>0) {
            var getURL = "info/comment?cid="+$scope.cmt.time;
            console.log("calling: ",getURL);
            $http.get(getURL)
            .success( setComment )
            .error( handleHTTPError );
        }
    }
    function saveComment(closeIt) {
		$scope.cmt.notify.forEach( function(item) {
			if (!item.uid) {
				item.uid = item.name;
			}
		});
        var updateRec = {};
        updateRec.time = $scope.cmt.time;
        updateRec.containerType = $scope.cmt.containerType;
        updateRec.containerID = $scope.cmt.containerID;
        updateRec.notify = $scope.cmt.notify;
        updateRec.docList = $scope.cmt.docList;
        updateRec.excludeSelf = $scope.cmt.excludeSelf;
        updateRec.suppressEmail = $scope.cmt.suppressEmail;
        updateRec.state = $scope.cmt.state;
        updateRec.commentType = $scope.cmt.commentType;
        updateRec.dueDate = $scope.cmt.dueDate;
        updateRec.html = $scope.cmt.html;
        updateRec.responses = $scope.cmt.responses;
        $scope.responders.forEach( function(userRec) {
            var found = false;
            $scope.oldCmt.responses.forEach( function(oldItem) {
                if (oldItem.user == userRec.uid) {
                    found = true;
                }
            });
            if (!found) {
                updateRec.responses.push({
                    "choice": "None",
                    "html": "",
                    "user": userRec.uid
                });
            }
        });
        var postdata = angular.toJson(updateRec);
        var postURL = "info/comment?cid="+$scope.cmt.time;
        console.log(postURL,updateRec);
        $http.post(postURL ,postdata)
        .success( function(data) {
            if ("Y"==closeIt) {
                $modalInstance.dismiss('cancel')
            }
            else {
                setComment(data);
            }
        })
        .error( handleHTTPError );
    }
    function setComment(newComment) {
        console.log("GOT comment: ", newComment);
        if (!newComment.responses) {
            newComment.responses = [];
        }
        newComment.suppressEmail = (newComment.suppressEmail==true);
        newComment.choices = ["Consent", "Objection"];
        if (!newComment.docList) {
            newComment.docList = [];
        }
        if (!newComment.notify) {
            newComment.notify = [];
        }
        $scope.unsaved = 0;
        $scope.cmt = newComment;
        $scope.flattenedCmt = JSON.stringify(newComment);
        $scope.oldCmt = JSON.parse($scope.flattenedCmt);
        $scope.responders = [];
        if (newComment.commentType==2 || newComment.commentType==3) {
            $scope.cmt.responses.forEach( function(item)  {
                $scope.responders.push({
                    "uid": item.user,
                    "name": item.userName,
                    "key": item.key
                });
            });
        }
    }
    function handleHTTPError(data, status, headers, config) {
        console.log("ERROR in ResponseModel Dialog: ", data);
    }
	
	// return a readable status message
	$scope.getStatusMassage = function() {
		switch ($scope.unsaved) {
            case -1:    return "Autosave completed";
            case 0:     return "No changes";
            case 1:     return "Unsaved changes";
        }
	};
	
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
        if (tinyMCE.activeEditor.getContent() != $scope.initialContent) {
            $scope.unsaved = 1;
        }
    }


    $scope.save = function() {
		saveComment("N");
    }
    $scope.saveAndClose = function () {
		saveComment("Y");
        $interval.cancel($scope.promiseAutosave);
    };
    $scope.postIt = function () {
        if ($scope.cmt.state == 11 && $scope.autosaveEnabled) {
            $scope.cmt.state = 12;
        }
        if ($scope.cmt.state==12) {
            if ($scope.cmt.commentType==1 || $scope.cmt.commentType==5) {
                $scope.cmt.state=13;
            }
        }
        $scope.saveAndClose();
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
        var newFlat = JSON.stringify($scope.cmt);
        if (newFlat != $scope.flattenedCmt ) {
            saveComment("N");
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
        var found = $scope.cmt.docList.forEach( function(docid) {
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
    $scope.openAttachDocument = function () {

        var attachModalInstance = $modal.open({
            animation: true,
            templateUrl: '../../../templates/AttachDocument.html?s=a',
            controller: 'AttachDocumentCtrl',
            size: 'lg',
            resolve: {
                docList: function () {
                    return JSON.parse(JSON.stringify($scope.cmt.docList));
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
            $scope.cmt.docList = docList;
        }, function () {
            //cancel action - nothing really to do
        });
    };
    $scope.selectedTab = "Update";

});