
app.controller('CommentModalCtrl', function ($scope, $modalInstance, $modal, $interval, cmt, parentScope,
    AllPeople, attachmentList, docSpaceURL, $http, siteId) {


    $scope.siteId = siteId;
    // initial comment object
    $scope.cmt = {};
    setComment(cmt);

    // parent scope with all the crud methods
    $scope.parentScope = parentScope;
    $scope.allowCommentEmail = parentScope.allowCommentEmail();

    // are there unsaved changes?
    $scope.unsaved = 0;
    // controls if comment can be saved
    $scope.saveDisabled = false;
    $scope.promiseAutosave = null;

    $scope.docSpaceURL = docSpaceURL;
    $scope.attachmentList = attachmentList;
    $scope.showEmail = false;
    $scope.hasOutcome = (cmt.commentType == 2 || cmt.commentType == 3);
    $scope.selectedTab = (cmt.state > 11 && $scope.hasOutcome) ? "Outcome" : "Update";
    getComment();

    $scope.scratchHtml = "";
    $scope.scratchWiki = "";
    $scope.oldScratchWiki = "";

    function getComment() {
        if ($scope.cmt.time > 0) {
            var getURL = "info/comment?cid=" + $scope.cmt.time;
            console.log("calling: ", getURL);
            $http.get(getURL)
                .success(setComment)
                .error(handleHTTPError);
        }
    }
    function setComment(newComment) {
        if (!newComment.responses) {
            newComment.responses = [];
        }
        $scope.unsaved = 0;
        newComment.suppressEmail = (newComment.suppressEmail == true);
        newComment.choices = ["Consent", "Objection"];
        if (!newComment.docList) {
            newComment.docList = [];
        }
        if (!newComment.notify) {
            newComment.notify = [];
        }


        //only set if the wiki value is different
        if ($scope.cmt.body != newComment.body) {
            $scope.bodyHtml = convertMarkdownToHtml(newComment.body);
        }
        if ($scope.cmt.outcome != newComment.outcome) {
            $scope.outcomeHtml = convertMarkdownToHtml(newComment.outcome);
        }

        $scope.hasOutcome = (newComment.commentType == 2 || newComment.commentType == 3);
        $scope.unsaved = 0;
        $scope.cmt = newComment;
        $scope.flattenedCmt = JSON.stringify(newComment);
        $scope.oldCmt = JSON.parse($scope.flattenedCmt);
        $scope.responders = [];
        if (newComment.commentType == 2 || newComment.commentType == 3) {
            $scope.cmt.responses.forEach(function (item) {
                $scope.responders.push({
                    "uid": item.user,
                    "name": item.userName,
                    "key": item.key
                });
            });
        }
        $scope.dataReceived = new Date().getTime();
    }
    function handleHTTPError(data, status, headers, config) {
        console.log("ERROR in ResponseModel Dialog: ", data);
    }


    $scope.tinymceOptions = standardTinyMCEOptions();
    $scope.tinymceOptions.height = 300;
    $scope.tinymceOptions.init_instance_callback = function (editor) {
        $scope.initialContent = editor.getContent();
        editor.on('Change', tinymceChangeTrigger);
        editor.on('KeyUp', tinymceChangeTrigger);
        editor.on('Paste', tinymceChangeTrigger);
        editor.on('Remove', tinymceChangeTrigger);
        editor.on('Format', tinymceChangeTrigger);
    }

    $scope.cancel = function () {
        //bogus redirect because of caching problems
        $scope.closeAndShutDown();
    }
    $scope.closeAndShutDown = function () {
        if ($scope.promiseAutosave) {
            $interval.cancel($scope.promiseAutosave);
        }
        console.log("Comment popup closed.");
        $scope.promiseAutosave = null;
        $modalInstance.dismiss('cancel');
    }
    $scope.save = function () {
        $scope.saveScratch();
        saveComment("N", false);
    }
    $scope.saveAndClose = function () {
        $scope.saveScratch();
        saveComment("Y", false);
    };
    $scope.saveReopen = function () {
        $scope.cmt.state = 12
        saveComment("Y", false);
    };
    $scope.resendEmail = function () {
        $scope.cmt.suppressEmail = false;
        saveComment("Y", true);
    };
    $scope.closeSendEmail = function () {
        $scope.cmt.state = 13;
        $scope.cmt.suppressEmail = false;
        saveComment("Y", true);
    };
    $scope.closeNoEmail = function () {
        $scope.cmt.state = 13;
        $scope.cmt.suppressEmail = true;
        saveComment("Y", false);
    };


    $scope.postIt = function (resendEmail) {
        if ($scope.cmt.state == 11 && $scope.autosaveEnabled) {
            $scope.cmt.state = 12;
        }
        if ($scope.cmt.state == 12) {
            if ($scope.cmt.commentType == 1 || $scope.cmt.commentType == 5) {
                $scope.cmt.state = 13;
            }
        }
        $scope.cmt.suppressEmail = !resendEmail;
        saveComment("Y", resendEmail);
    };
    function saveComment(closeIt, resend) {
        $scope.cmt.notify.forEach(function (item) {
            if (!item.uid) {
                item.uid = item.name;
            }
        });
        var updateRec = {};
        updateRec.resendEmail = resend;
        updateRec.time = $scope.cmt.time;
        updateRec.containerType = $scope.cmt.containerType;
        updateRec.containerID = $scope.cmt.containerID;
        updateRec.notify = $scope.cmt.notify;
        updateRec.docList = $scope.cmt.docList;
        updateRec.excludeSelf = $scope.cmt.excludeSelf;
        updateRec.includeInMinutes = $scope.cmt.includeInMinutes;
        updateRec.suppressEmail = $scope.cmt.suppressEmail;
        updateRec.state = $scope.cmt.state;
        updateRec.commentType = $scope.cmt.commentType;
        updateRec.dueDate = $scope.cmt.dueDate;
        updateRec.body = HTML2Markdown($scope.bodyHtml, {});
        updateRec.outcome = HTML2Markdown($scope.outcomeHtml, {});
        updateRec.responses = $scope.cmt.responses;
        updateRec.replyTo = $scope.cmt.replyTo;
        updateRec.containerID = $scope.cmt.containerID;
        updateRec.containerType = $scope.cmt.containerType;
        $scope.responders.forEach(function (userRec) {
            var found = false;
            $scope.oldCmt.responses.forEach(function (oldItem) {
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
        var postURL = "info/comment?cid=" + $scope.cmt.time;
        console.log(postURL, updateRec);
        $http.post(postURL, postdata)
            .success(function (data) {
                if ("Y" == closeIt) {
                    $scope.closeAndShutDown();
                }
                else {
                    setComment(data);
                }
            })
            .error(handleHTTPError);
    }



    $scope.commentTypeName = function () {
        if ($scope.cmt.commentType == 2) {
            return "Proposal";
        }
        if ($scope.cmt.commentType == 3) {
            return "Round";
        }
        if ($scope.cmt.commentType == 5) {
            return "Minutes";
        }
        return "Comment";
    }

    $scope.getVerbHeader = function () {
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
    $scope.openDatePicker1 = function ($event) {
        $event.preventDefault();
        $event.stopPropagation();
        $scope.datePickOpen1 = true;
    };
    $scope.datePickDisable = function (date, mode) {
        return false;
    };




    //this fires every keystroke to maintain change flag
    function tinymceChangeTrigger(e, editor) {
        $scope.lastKeyTimestamp = new Date().getTime();
        $scope.cmt.body = HTML2Markdown($scope.bodyHtml, {});
        $scope.cmt.outcome = HTML2Markdown($scope.outcomeHtml, {});
        $scope.scratchWiki = HTML2Markdown($scope.scratchHtml);
        var newFlat = JSON.stringify($scope.cmt);
        if (newFlat != $scope.flattenedCmt) {
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
    if ($scope.parentScope.updateComment == undefined) {
        //$scope.autosaveEnabled = false;
    }

    $scope.autosave = function () {
        var newFlat = JSON.stringify($scope.cmt);
        if (newFlat != $scope.flattenedCmt) {
            $scope.unsaved = 1;
        }
        else {
            $scope.unsaved = 0;
        }
        var secondsSinceKeypress = Math.floor((new Date().getTime() - $scope.lastKeyTimestamp) / 1000);
        $scope.secondsTillSave = 5 - secondsSinceKeypress;
        $scope.minutesTillClose = Math.floor((1200 - secondsSinceKeypress) / 60);
        if (secondsSinceKeypress > 1200) {
            //it has been 1200 seconds (20 minutes) since any save or keystroke
            //time to close this pop up dialog
            console.log("Auto close time achieved, closing the dialog box", $scope);
            $scope.saveAndClose();
        }
        if (secondsSinceKeypress < 5) {
            //user has typed in last 20 seconds to wait until 20 seconds of silence
            return;
        }
        $scope.saveScratch();
        if ($scope.unsaved) {
            $scope.unsaved = -1;
            saveComment("N", false);
            return;
        }
        var secondsSinceLastRefresh = Math.floor((new Date().getTime() - $scope.dataReceived) / 1000);
        if (secondsSinceLastRefresh > 60) {
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

    $scope.loadPersonList = function (query) {
        return AllPeople.findMatchingPeople(query, $scope.siteId);
    }
    $scope.itemHasDoc = function (doc) {
        var res = false;
        var found = $scope.cmt.docList.forEach(function (docid) {
            if (docid == doc.universalid) {
                res = true;
            }
        });
        return res;
    }
    $scope.getDocs = function () {
        return $scope.attachmentList.filter(function (oneDoc) {
            return $scope.itemHasDoc(oneDoc);
        });
    }
    $scope.getFullDoc = function (docId) {
        var doc = {};
        $scope.attachmentList.filter(function (item) {
            if (item.universalid == docId) {
                doc = item;
            }
        });
        return doc;
    }
    $scope.navigateToDoc = function (docId) {
        var doc = $scope.getFullDoc(docId);
        window.location = "DocDetail.htm?aid=" + doc.id;
    }
    $scope.openAttachDocument = function () {

        if (!$scope.cmt.time || $scope.cmt.time <= 100000) {
            alert("Save draft comment before you attempt to attach documents.");
            return;
        }

        var attachModalInstance = $modal.open({
            animation: true,
            templateUrl: '../../new_assets/templates/AttachDocument.html?s=a',
            controller: 'AttachDocumentCtrl',
            size: 'lg',
            resolve: {
                containingQueryParams: function () {
                    return "cmt=" + $scope.cmt.time;
                },
                docSpaceURL: function () {
                    return $scope.docSpaceURL;
                }
            }
        });

        attachModalInstance.result
            .then(function (docList) {
                getComment();
            }, function () {
                getComment();
                //cancel action - nothing really to do
            });
    };

    $scope.updateNotify = function () {
        console.log("updateNotify");
        $scope.cmt.notify = cleanUserList($scope.cmt.notify);
    }
    $scope.updateResponders = function () {
        console.log("updateNotify");
        $scope.responders = cleanUserList($scope.responders);
    }

    $scope.getScratch = function () {
        var postURL = "GetScratchpad.json";
        $http.get(postURL)
            .success(function (data) {
                if ($scope.scratchWiki != data.scratchpad) {
                    //avoid setting it, if it is the same, to avoid editor problems
                    $scope.scratchWiki = data.scratchpad;
                    $scope.scratchHtml = convertMarkdownToHtml(data.scratchpad);
                }
                $scope.oldScratchWiki = $scope.scratchWiki;
            })
            .error(handleHTTPError);
    }
    $scope.saveScratch = function () {
        $scope.scratchWiki = HTML2Markdown($scope.scratchHtml);
        if ($scope.scratchWiki == $scope.oldScratchWiki) {
            //don't bother trying to save if no change
            console.log("SAVESCRATCH- no change");
            return;
        }

        var postURL = "UpdateScratchpad.json";
        var data = {
            oldScratchpad: $scope.oldScratchWiki,
            newScratchpad: $scope.scratchWiki
        }
        var lastSave = $scope.scratchWiki;
        $http.post(postURL, angular.toJson(data))
            .success(function (data) {
                if (lastSave != data.scratchpad) {
                    //avoid setting it, if it is the same, to avoid editor problems
                    $scope.scratchWiki = Textmerger.get().merge(lastSave, $scope.scratchWiki, data.scratchpad);
                    $scope.scratchHtm = convertMarkdownToHtml(data.scratchpad);
                }
                $scope.oldScratchWiki = $scope.scratchWiki;
            })
            .error(handleHTTPError);
    }

    $scope.getScratch();
});