<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="org.socialbiz.cog.AccessControl"
%><%@page import="org.socialbiz.cog.LeafletResponseRecord"
%><%@page import="org.socialbiz.cog.LicenseForUser"
%><%@page import="org.socialbiz.cog.MicroProfileMgr"
%><%/*
Required parameter:

    1. pageId : This is the id of a Workspace and used to retrieve NGWorkspace.
    2. topicId: This is id of note (TopicRecord).

*/
    //set 'forceTemplateRefresh' in config file to 'true' to get this
    String templateCacheDefeater = "";
    if ("true".equals(ar.getSystemProperty("forceTemplateRefresh"))) {
        templateCacheDefeater = "?t="+System.currentTimeMillis();
    }


    String pageId = ar.reqParam("pageId");
    String siteId = ar.reqParam("siteId");
    NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngw);
    JSONObject workspaceInfo = ngw.getConfigJSON();

    boolean isLoggedIn = ar.isLoggedIn();

    //there might be a better way to measure this that takes into account
    //magic numbers and tokens
    boolean canUpdate = ar.isMember();

    NGBook ngb = ngw.getSite();
    UserProfile uProf = ar.getUserProfile();
    String currentUser = "NOBODY";
    String currentUserName = "NOBODY";
    String currentUserKey = "NOBODY";
    if (isLoggedIn) {
        //this page can be viewed when not logged in, possibly with special permissions.
        //so you can't assume that uProf is non-null
        currentUser = uProf.getUniversalId();
        currentUserName = uProf.getName();
        currentUserKey = uProf.getKey();
    }

    String topicId = ar.reqParam("topicId");
    TopicRecord note = ngw.getNoteOrFail(topicId);

    if (!AccessControl.canAccessTopic(ar, ngw, note)) {
        throw new Exception("Program Logic Error: this view should only display when user can actually access the note.");
    }

    JSONObject noteInfo = note.getJSONWithComments(ar, ngw);
    JSONArray comments = noteInfo.getJSONArray("comments");
    JSONArray attachmentList = ngw.getJSONAttachments(ar);
    JSONArray allLabels = ngw.getJSONLabels();

    JSONArray history = new JSONArray();
    for (HistoryRecord hist : note.getNoteHistory(ngw)) {
        history.put(hist.getJSON(ngw, ar));
    }

    JSONArray allGoals     = ngw.getJSONGoals();

    String docSpaceURL = "";
    if (uProf!=null) {
        LicenseForUser lfu = new LicenseForUser(ar.getUserProfile());
        docSpaceURL = ar.baseURL +  "api/" + ngb.getKey() + "/" + ngw.getKey()
                    + "/summary.json?lic="+lfu.getId();
    }

    //to access the email-ready page, you need to get the license parameter
    //for this note.  This string saves this for use below on reply to comments
    String specialAccess =  AccessControl.getAccessTopicParams(ngw, note)
                + "&emailId=" + URLEncoder.encode(ar.getBestUserId(), "UTF-8");

%>

<style>
.ta-editor {
    min-height: 150px;
    max-height: 600px;
    width:600px;
    height: auto;
    overflow: auto;
    font-family: inherit;
    font-size: 100%;
    margin:20px 0;
}
.labelColumn:hover {
    background-color:#ECB6F9;
}
.doubleClickHint {
    background-color:#eee;
    color:#aaa;
    padding:4px;
    max-width:400px
}
</style>

<script type="text/javascript">
document.title="<% ar.writeJS(note.getSubject());%>";

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal, $interval, AllPeople) {
    window.setMainPageTitle("Discussion Topic");
    $scope.workspaceInfo = <%workspaceInfo.write(out,2,4);%>;
    $scope.noteInfo = <%noteInfo.write(out,2,4);%>;
    $scope.attachmentList = <%attachmentList.write(out,2,4);%>;
    $scope.allLabels = <%allLabels.write(out,2,4);%>;
    $scope.canUpdate = <%=canUpdate%>;
    $scope.history = <%history.write(out,2,4);%>;
    $scope.allGoals = <%allGoals.write(out,2,4);%>;
    $scope.siteInfo = <%ngb.getConfigJSON().write(out,2,4);%>;
    $scope.addressMode = false;

    $scope.tinymceOptions = standardTinyMCEOptions();
    $scope.tinymceOptions.height = 400;

    $scope.currentTime = (new Date()).getTime();
    $scope.docSpaceURL = "<%ar.writeJS(docSpaceURL);%>";

    $scope.isEditing = false;
    $scope.item = {};

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };

    $scope.fixUpChoices = function() {
        $scope.noteInfo.comments.forEach( function(cmt) {
            if (!cmt.choices || cmt.choices.length==0) {
                cmt.choices = ["Consent", "Objection"];
            }
            if (cmt.choices[1]=="Object") {
                cmt.choices[1]="Objection";
            }
        });
    }
    $scope.fixUpChoices();


    $scope.myComment = "";
    $scope.myCommentType = 1;   //simple comment
    $scope.myReplyTo = 0;

    $scope.startEdit = function() {
        if ($scope.workspaceInfo.frozen) {
            alert("Sorry, this workspace is frozen by the administrator\nTopics can not be edited in a frozen workspace.");
            return;
        }
        $scope.isEditing = true;
    }
    $scope.saveEdit = function() {
        $scope.saveEdits(['html','subject']);
        $scope.isEditing = false;
    }
    $scope.saveEdits = function(fields) {
        var postURL = "noteHtmlUpdate.json?nid="+$scope.noteInfo.id;
        var rec = {};
        rec.id = $scope.noteInfo.id;
        rec.universalid = $scope.noteInfo.universalid;
        fields.forEach( function(fieldName) {
            rec[fieldName] = $scope.noteInfo[fieldName];
        });
        if ($scope.isEditing) {
            rec.html = $scope.noteInfo.html;
            rec.subject = $scope.noteInfo.subject;
        }
        var postdata = angular.toJson(rec);
        $scope.showError=false;
        $http.post(postURL ,postdata)
        .success( $scope.receiveTopicRecord )
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };
    function refreshTopic() {
        var postURL = "noteHtmlUpdate.json?nid="+$scope.noteInfo.id;
        var rec = {};
        rec.id = $scope.noteInfo.id
        rec.universalid = $scope.noteInfo.universalid;
        var postdata = angular.toJson(rec);
        $scope.showError=false;
        $http.post(postURL, postdata)
        .success( $scope.receiveTopicRecord )
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    }

    $scope.receiveTopicRecord = function(data) {
        $scope.noteInfo = data;
        var check = false;
        data.subscribers.forEach( function(person) {
            if (person.uid == "<%=ar.getBestUserId()%>") {
                check = true;
            }
            person.image = AllPeople.imageName(person);
        });
        $scope.fixUpChoices();
        $scope.isSubscriber = check;
        $scope.refreshHistory();
    }

    $scope.postComment = function(itemNotUsed, cmt) {
        cmt.state = 12;
        if (cmt.commentType == 1 || cmt.commentType == 5) {
            //simple comments go all the way to closed
            cmt.state = 13;
        }
        $scope.updateComment(cmt);
    }
    $scope.deleteComment = function(itemNotUsed, cmt) {
        cmt.deleteMe = true;
        $scope.updateComment(cmt);
    }
    $scope.closeComment = function(itemNotUsed, cmt) {
        if (cmt.commentType>1) {
            if (cmt.state!=13) {
                $scope.openOutcomeEditor(cmt);
            }
        }
        else {
            $scope.updateComment(cmt);
        }
    }
    $scope.updateComment = function(cmt) {
        var saveRecord = {};
        saveRecord.id = $scope.noteInfo.id;
        saveRecord.universalid = $scope.noteInfo.universalid;
        saveRecord.comments = [];
        saveRecord.comments.push(cmt);
        $scope.savePartial(saveRecord);
    }
    $scope.saveDocs = function() {
        var saveRecord = {};
        saveRecord.id = $scope.noteInfo.id;
        saveRecord.universalid = $scope.noteInfo.universalid;
        saveRecord.docList = $scope.noteInfo.docList;
        $scope.savePartial(saveRecord);
    }
    $scope.saveLabels = function() {
        var saveRecord = {};
        saveRecord.id = $scope.noteInfo.id;
        saveRecord.universalid = $scope.noteInfo.universalid;
        saveRecord.labelMap = $scope.noteInfo.labelMap;
        $scope.savePartial(saveRecord);
    }

    $scope.savePartial = function(recordToSave) {
        if ($scope.isEditing) {
            recordToSave.html = $scope.noteInfo.html;
            recordToSave.subject = $scope.noteInfo.subject;
        }
        var postURL = "noteHtmlUpdate.json?nid="+$scope.noteInfo.id;
        var postdata = angular.toJson(recordToSave);
        $scope.showError=false;
        $http.post(postURL ,postdata)
        .success( function(data) {
            $scope.myComment = "";
            $scope.receiveTopicRecord(data);
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };
    
    $scope.allowCommentEmail = function() {
        return (!$scope.noteInfo.draft);
    }

    $scope.itemHasAction = function(oneAct) {
        var res = false;
        var found = $scope.noteInfo.actionList.forEach( function(actionId) {
            if (actionId == oneAct.universalid) {
                res = true;
            }
        });
        return res;
    }
    $scope.getActions = function() {
        return $scope.allGoals.filter( function(oneAct) {
            return $scope.itemHasAction(oneAct);
        });
    }
    $scope.navigateToMeeting = function(meet) {
        window.location="meetingFull.htm?id="+meet.id;
    }
    $scope.navigateToAction = function(oneAct) {
        window.location="task"+oneAct.id+".htm";
    }

    $scope.getResponse = function(cmt, user) {
        if (!user) {
            user = "<%ar.writeJS(currentUser);%>";
        }
        var selected = [];
        cmt.responses.forEach( function(item) {
            if (item.user==user) {
                selected.push(item);
            }
        });
        return selected;
    }
    $scope.noResponseYet = function(cmt) {
        if (cmt.state!=12) { //not open
            return false;
        }
        var whatNot = $scope.getResponse(cmt);
        return (whatNot.length == 0);
    }
    $scope.getOrCreateResponse = function(cmt) {
        var selected = $scope.getResponse(cmt);
        if (selected.length == 0) {
            var newResponse = {};
            newResponse.user = "<%ar.writeJS(currentUser);%>";
            newResponse.userName = "<%ar.writeJS(currentUserName);%>";
            cmt.responses.push(newResponse);
            selected.push(newResponse);
        }
        return selected;
    }

    $scope.startResponse = function(cmt) {
        if (!$scope.canUpdate) {
            alert("You must be logged in to ceate a response");
            return;
        }
        $scope.openResponseEditor(cmt)
    }

    $scope.getComments = function() {
        var res = [];
        $scope.noteInfo.comments.map( function(item) {
            res.push(item);
        });
        res.sort( function(a,b) {
            return a.time - b.time;
        });
        return res;
    }
    $scope.findComment = function(itemNotUsed, timestamp) {
        var selected = {};
        $scope.noteInfo.comments.map( function(cmt) {
            if (timestamp==cmt.time) {
                selected = cmt;
            }
        });
        return selected;
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
    $scope.refreshHistory = function() {
        var postURL = "getNoteHistory.json?nid="+$scope.noteInfo.id;
        $scope.showError=false;
        $http.get(postURL)
        .success( function(data) {
            $scope.history = data;
        })
        .error( function(data, status, headers, config) {
            console.log("FAILED TO refreshHistory: "+postURL, data, status, headers, config);
            $scope.reportError(data);
        });
    }
    $scope.hasLabel = function(searchName) {
        return $scope.noteInfo.labelMap[searchName];
    }
    $scope.toggleLabel = function(label) {
        $scope.noteInfo.labelMap[label.name] = !$scope.noteInfo.labelMap[label.name];
        $scope.saveLabels();
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
    $scope.stateName = function(cmt) {
        if (cmt.state==11) {
            return "Draft";
        }
        if (cmt.state==12) {
            return "Active";
        }
        return "Completed";
    }
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
        diff = Math.floor(diff / 7);
        return "due in "+diff+" weeks";
    }

    $scope.createModifiedProposal = function(cmt) {
        $scope.openCommentCreator({},2,cmt.time,cmt.html);  //proposal
    }
    $scope.replyToComment = function(cmt) {
        $scope.openCommentCreator({},1,cmt.time);  //simple comment
    }

    $scope.phaseNames = {
        "Draft": "Draft",
        "Freeform": "Freeform",
        "Resolved": "Resolved",
        "Forming": "Picture Forming",
        "Shaping": "Proposal Shaping",
        "Finalizing": "Proposal Finalizing",
        "Trash": "In Trash"
    }
    $scope.showDiscussionPhase = function(phase) {
        if (!phase) {
            return "Unknown";
        }
        var name = $scope.phaseNames[phase];
        if (name) {
            return name;
        }
        return "?"+phase+"?";
    }
    $scope.getPhases = function() {
        return ["Draft", "Freeform", "Resolved", "Forming", "Shaping", "Finalizing", "Trash"];
    }
    $scope.setPhase = function(newPhase) {
        if ($scope.noteInfo.discussionPhase == newPhase) {
            return;
        }
        $scope.noteInfo.discussionPhase = newPhase;
        $scope.saveEdits(['discussionPhase','suppressEmail','subscribers','sendEmailNow']);
    }
    $scope.getPhaseStyle = function() {
        if ($scope.noteInfo.draft) {
            return "background-color:yellow;cursor:pointer";
        }
        return "cursor:pointer";
    }
    $scope.startSend = function() {
        $scope.addressMode = true;
    }
    $scope.updatePlayers = function() {
        $scope.noteInfo.subscribers = cleanUserList($scope.noteInfo.subscribers);
    }    
    $scope.postIt = function(sendEmail) {
        $scope.noteInfo.sendEmailNow = sendEmail;
        $scope.setPhase("Freeform");
        $scope.addressMode = false;
    }

    $scope.changeSubscription = function(onOff) {
        var url = "topicSubscribe.json?nid="+$scope.noteInfo.id;
        if (!onOff) {
            url = "topicUnsubscribe.json?nid="+$scope.noteInfo.id;
        }
        $http.get(url)
        .success( $scope.receiveTopicRecord )
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    }


    $scope.openCommentCreator = function(itemNotUsed, type, replyTo, defaultBody) {
        if ($scope.workspaceInfo.frozen) {
            alert("Sorry, this workspace is frozen by the administrator\Comments can not be modified in a frozen workspace.");
            return;
        }
        if (!$scope.canUpdate) {
            alert("You must be logged in to ceate a response");
            return;
        }
        var newComment = {};
        newComment.time = -1;
        newComment.containerType = "T";
        newComment.containerID = $scope.noteInfo.id;
        newComment.dueDate = (new Date()).getTime() + (7*24*60*60*1000);
        newComment.commentType = type;
        newComment.state = 11;
        newComment.isNew = true;
        newComment.user = "<%ar.writeJS(currentUser);%>";
        newComment.userName = "<%ar.writeJS(currentUserName);%>";
        newComment.userKey = "<%ar.writeJS(currentUserKey);%>";
        newComment.responses = [];
        if (type==2 || type==3) {
            $scope.noteInfo.subscribers.forEach( function(item) {
                newComment.responses.push({
                    "choice": "None",
                    "html": "",
                    "user": item.uid,
                    "key": item.key,
                    "userName": item.name,
                });
            });
        }
        
        if (replyTo) {
            newComment.replyTo = replyTo;
        }
        if (defaultBody) {
            newComment.html = defaultBody;
        }
        $scope.openCommentEditor({}, newComment);
    }


    $scope.openCommentEditor = function (itemNotUsed, cmt) {
        if ($scope.workspaceInfo.frozen) {
            alert("Sorry, this workspace is frozen by the administrator\Comments can not be modified in a frozen workspace.");
            return;
        }
        var modalInstance = $modal.open({
            animation: true,
            templateUrl: '<%=ar.retPath%>templates/CommentModal.html<%=templateCacheDefeater%>',
            controller: 'CommentModalCtrl',
            size: 'lg',
            backdrop: "static",
            resolve: {
                cmt: function () {
                    return cmt;
                },
                attachmentList: function() {
                    return $scope.attachmentList;
                },
                docSpaceURL: function() {
                    return $scope.docSpaceURL;
                },
                parentScope: function() { return $scope; },
                siteId: function() {return $scope.siteInfo.key}
            }
        });

        modalInstance.result.then(function (returnedCmt) {
            refreshTopic();
        }, function () {
            //cancel action - nothing really to do
            refreshTopic();
        });
    };

    $scope.openResponseEditor = function (cmt, user) {
        if ($scope.workspaceInfo.frozen) {
            alert("Sorry, this workspace is frozen by the administrator\nComments can not be modified in a frozen workspace.");
            return;
        }

        var modalInstance = $modal.open({
            animation: false,
            templateUrl: '<%=ar.retPath%>templates/ResponseModal.html<%=templateCacheDefeater%>',
            controller: 'ModalResponseCtrl',
            size: 'lg',
            backdrop: "static",
            resolve: {
                responseUser: function () {
                    return user;
                },
                cmtId: function () {
                    return cmt.time;
                }
            }
        });

        modalInstance.result.then(function (response) {
            refreshTopic();
        }, function () {
            //cancel action - nothing really to do
            refreshTopic();
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

    $scope.openOutcomeEditor = function (cmt) {
        if ($scope.workspaceInfo.frozen) {
            alert("Sorry, this workspace is frozen by the administrator\Comments can not be modified in a frozen workspace.");
            return;
        }

        var modalInstance = $modal.open({
            animation: false,
            templateUrl: '<%=ar.retPath%>templates/OutcomeModal.html<%=templateCacheDefeater%>',
            controller: 'OutcomeModalCtrl',
            size: 'lg',
            backdrop: "static",
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
            cleanCmt.state = 13;    //close
            cleanCmt.commentType = returnedCmt.commentType;
            $scope.updateComment(cleanCmt);
        }, function () {
            //cancel action - nothing really to do
        });
    };


    $scope.createDecision = function(newDecision) {
        if ($scope.workspaceInfo.frozen) {
            alert("Sorry, this workspace is frozen by the administrator\Comments can not be modified in a frozen workspace.");
            return;
        }
        newDecision.num="~new~";
        newDecision.universalid="~new~";
        var postURL = "updateDecision.json?did=~new~";
        var postData = angular.toJson(newDecision);
        $http.post(postURL, postData)
        .success( function(data) {
            var relatedComment = data.sourceCmt;
            $scope.noteInfo.comments.map( function(cmt) {
                if (cmt.time == relatedComment) {
                    cmt.decision = "" + data.num;
                    $scope.updateComment(cmt);
                }
            });
            $scope.refreshHistory();
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };

    $scope.openDecisionEditor = function (itemNotUsed, cmt) {
        if ($scope.workspaceInfo.frozen) {
            alert("Sorry, this workspace is frozen by the administrator\Comments can not be modified in a frozen workspace.");
            return;
        }
        if (!$scope.canUpdate) {
            alert("You must be logged in to ceate a response");
            return;
        }

        var newDecision = {
            html: cmt.html,
            labelMap: $scope.noteInfo.labelMap,
            sourceId: $scope.noteInfo.id,
            sourceType: 4,
            sourceCmt: cmt.time
        };

        var decisionModalInstance = $modal.open({
            animation: false,
            templateUrl: '<%=ar.retPath%>templates/DecisionModal.html<%=templateCacheDefeater%>',
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

        decisionModalInstance.result.then(function (modifiedDecision) {
            $scope.createDecision(modifiedDecision);
        }, function () {
            //cancel action - nothing really to do
        });
    };

    $scope.getObjDocs = function(noteInfo) {
        var res = [];
        $scope.attachmentList.forEach( function(docObj) {
            $scope.noteInfo.docList.forEach( function(docId) {
                if (docId == docObj.universalid) {
                    res.push(docObj);
                }
            })
        })
        return res;
    }

    $scope.getFullDoc = function(docId) {
        var doc = {};
        $scope.attachmentList.forEach( function(item) {
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
    $scope.unattachDocFromItem = function(docId) {
        var newList = [];
        $scope.noteInfo.docList.forEach( function(iii) {
            if (iii != docId) {
                newList.push(iii);
            }
        });
        $scope.noteInfo.docList = newList;
        $scope.saveEdits(['docList']);
    }
    $scope.openAttachDocument = function () {

        if ($scope.workspaceInfo.frozen) {
            alert("Sorry, this workspace is frozen by the administrator\Documents can not be attached in a frozen workspace.");
            return;
        }

        var attachModalInstance = $modal.open({
            animation: true,
            templateUrl: '<%=ar.retPath%>templates/AttachDocument.html<%=templateCacheDefeater%>',
            controller: 'AttachDocumentCtrl',
            size: 'lg',
            resolve: {
                containingQueryParams: function() {
                    return "note="+$scope.noteInfo.id;
                },
                docSpaceURL: function() {
                    return $scope.docSpaceURL;
                }
            }
        });

        attachModalInstance.result
        .then(function (docList) {
            //don't save, just force re-read
            $scope.saveEdits([]);
        }, function () {
            //cancel action - nothing really to do
        });
    };

    $scope.openAttachAction = function (item) {

        if ($scope.workspaceInfo.frozen) {
            alert("Sorry, this workspace is frozen by the administrator\Action items can not be attached in a frozen workspace.");
            return;
        }
        var attachModalInstance = $modal.open({
            animation: true,
            templateUrl: '<%=ar.retPath%>templates/AttachAction.html<%=templateCacheDefeater%>',
            controller: 'AttachActionCtrl',
            size: 'lg',
            resolve: {
                containingQueryParams: function() {
                    return "note="+$scope.noteInfo.id;
                },
                siteId: function () {
                  return $scope.siteInfo.key;
                }
            }
        });

        attachModalInstance.result
        .then(function (selectedActionItems) {
            $scope.noteInfo.actionList = selectedActionItems;
            $scope.saveEdits(['actionList']);
        }, function () {
            //cancel action - nothing really to do
        });
    };
    $scope.openFeedbackModal = function (item) {

        var attachModalInstance = $modal.open({
            animation: true,
            templateUrl: '<%=ar.retPath%>templates/Feedback.html<%=templateCacheDefeater%>',
            controller: 'FeedbackCtrl',
            size: 'lg',
            resolve: {
                currentUser: function () {
                    return "<%ar.writeJS(currentUser);%>";
                }
            }
        });

        attachModalInstance.result
        .then(function (selectedActionItems) {
            //not sure what to do here
        }, function () {
            //cancel action - nothing really to do
        });
    };

    $scope.refreshFromServer = function() {
        saveRecord = {};
        saveRecord.saveMode = "autosave";
        saveRecord.id = $scope.noteInfo.id;
        saveRecord.universalid = $scope.noteInfo.universalid;
        var postURL = "noteHtmlUpdate.json?nid="+$scope.noteInfo.id;
        var postdata = angular.toJson(saveRecord);
        //does not really save antthing ... just get response
        $http.post(postURL ,postdata)
        .success( function(data) {
            $scope.receiveTopicRecord(data);
        })
        .error( function(data) {
            console.log("AUTOSAVE FAILED", data);
        });
    }


    $scope.receiveTopicRecord($scope.noteInfo);
    $scope.autoIdleCount = 0;

    $scope.autosave = function() {
        if ($scope.isEditing) {
            if (!$scope.lastAuto) {
                $scope.lastAuto = {};
            }
            if ($scope.noteInfo.html==$scope.lastAuto.html &&
                            $scope.noteInfo.subject==$scope.lastAuto.subject) {
                console.log("AUTOSAVE - skipped, nothing new to save");
                //it IS idle so increase the idle counter, but after ten tried no change, go and fetch the latest
                //this indicates that the user is not actively typing and might be OK to refresh the edit panel
                if ($scope.autoIdleCount++ > 10) {
                    $scope.autoIdleCount = 0;
                    $scope.refreshFromServer();
                }
                return;
            }
            //it is NOT idle so mark it thus
            $scope.autoIdleCount = 0;
            $scope.lastAuto.html = $scope.noteInfo.html;
            $scope.lastAuto.subject = $scope.noteInfo.subject;
            saveRecord = {};
            saveRecord.saveMode = "autosave";
            saveRecord.html = $scope.noteInfo.html;
            saveRecord.subject = $scope.noteInfo.subject;
            saveRecord.id = $scope.noteInfo.id;
            saveRecord.universalid = $scope.noteInfo.universalid;
            var postURL = "noteHtmlUpdate.json?nid="+$scope.noteInfo.id;
            var postdata = angular.toJson(saveRecord);
            //for autosave ... don't complain about errors
            $http.post(postURL ,postdata)
            .success( function(data) {
                console.log("AUTOSAVE succeeded at "+new Date());
            })
            .error( function(data) {
                console.log("AUTOSAVE FAILED", data);
            });
        }
    }
    $scope.promiseAutosave = $interval($scope.autosave, 15000);

    $scope.loadPersonList = function(query) {
        return AllPeople.findMatchingPeople(query, $scope.siteInfo.key);
    }
    
    $scope.sendNoteByMail = function() {
        if ("Draft" == $scope.noteInfo.discussionPhase) {
            alert("Before sending by email you need to POST the note (possibly sending email at that time)");
            return;
        }
        if ("Trash" == $scope.noteInfo.discussionPhase) {
            alert("This topic has been deleted (in Trash).  Undelete it before sending by email.");
            return;
        }
        window.location = "SendNote.htm?noteId="+$scope.noteInfo.id;
    }

});

</script>
<script src="../../../jscript/AllPeople.js"></script>

<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

    <div class="upRightOptions rightDivContent">
      <span class="dropdown" ng-show="noteInfo.draft">
          <button class="btn btn-default btn-primary btn-raised" ng-click="startSend()"
                  title="Post this topic to take it out of Draft mode and allow others to see it">
          Post Topic </button>
      </span>
      <span class="dropdown" ng-hide="noteInfo.draft">
          <button class="btn btn-default btn-raised dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
          {{showDiscussionPhase(noteInfo.discussionPhase)}} <span class="caret"></span></button>
          <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
            <li role="presentation" ng-repeat="phase in getPhases()"><a role="menuitem"
                ng-click="setPhase(phase)">{{showDiscussionPhase(phase)}}</a></li>
          </ul>
      </span>
      <span class="dropdown">
        <button class="btn btn-default btn-raised dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
        Options: <span class="caret"></span></button>
        <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
          <li role="presentation"><a role="menuitem" tabindex="-1"
              href="NotesList.htm">List Topics</a></li>
          <li role="presentation"><a role="menuitem" tabindex="-1"
              ng-click="startEdit()" target="_blank">Edit This Topic</a></li>
          <li role="presentation"><a role="menuitem" tabindex="-1"
              href="pdf/note{{noteInfo.id}}.pdf?publicNotes={{noteInfo.id}}&comments=true">PDF with Comments</a></li>
          <li role="presentation"><a role="menuitem" tabindex="-1"
              href="pdf/note{{noteInfo.id}}.pdf?publicNotes={{noteInfo.id}}">PDF without Comments</a></li>
          <li role="presentation"><a role="menuitem" tabindex="-1"
              ng-click="sendNoteByMail()">Send Topic By Email</a></li>
          <li role="presentation" ng-hide="isSubscriber"><a role="menuitem" tabindex="-1"
              ng-click="changeSubscription(true)">Subscribe to this Topic</a></li>
          <li role="presentation" ng-show="isSubscriber"><a role="menuitem" tabindex="-1"
              ng-click="changeSubscription(false)">Unsubscribe from this Topic</a></li>
          <li role="presentation" ng-show="isSubscriber"><a role="menuitem" tabindex="-1"
              ng-click="openFeedbackModal()">Feedback</a></li>

        </ul>
      </span>
    </div>

    <div class="well" ng-show="addressMode" ng-cloak>
      <h2>Email Notification To (Subscribers):</h2>
      <div>
          <tags-input ng-model="noteInfo.subscribers" placeholder="Enter users to send notification email to"
                      display-property="name" key-property="uid"
                      replace-spaces-with-dashes="false" add-on-space="true" add-on-comma="true"
                      on-tag-added="updatePlayers()" 
                      on-tag-removed="updatePlayers()">
              <auto-complete source="loadPersonList($query)" min-length="1"></auto-complete>
          </tags-input>
      </div>
      <span class="dropdown">
          <button class="btn btn-default btn-primary btn-raised" type="button" ng-click="postIt(false)"
                  title="Post this topic but don't send any email">
          Post Without Email </button>
      </span>
      <span class="dropdown">
          <button class="btn btn-default btn-primary btn-raised" type="button" ng-click="postIt(true)"
                  title="Post this topic and send the email to selected users">
          Post &amp; Send Email </button>
      </span>
      <span class="dropdown">
          <button class="btn btn-default btn-warning btn-raised" type="button" ng-click="addressMode = false"
                  title="Cancel and leave this in draft mode.">
          Cancel </button>
      </span>

    </div>

    <div  class="h1" style="{{getPhaseStyle()}}"  ng-hide="isEditing" ng-click="startEdit()" >
        <i class="fa fa-lightbulb-o" style="font-size:130%"></i>
        {{noteInfo.subject}}
    </div>

    <div class="leafContent" ng-hide="isEditing" ng-dblclick="startEdit()">
        <div  ng-bind-html="noteInfo.html"></div>
    </div>
<%if (isLoggedIn) { %>
    <div class="leafContent" ng-show="isEditing">
        <input type="text" class="form-control" ng-model="noteInfo.subject">
        <div style="height:15px"></div>
        <div ui-tinymce="tinymceOptions" ng-model="noteInfo.html"></div>
        <div style="height:15px"></div>
        <button class="btn btn-primary btn-raised" ng-click="saveEdit()">Close Editor</button>
    </div>
<% } %>


<table class="table">
<col style="width:150px">
<tr>
    <td>Last modified:</td><td>{{noteInfo.modTime|date}}</td>
</tr>
<tr>
    <td>Labels:</td>
    <td>
          <span class="dropdown" ng-repeat="role in allLabels">
            <button class="labelButton" type="button" id="menu2"
               data-toggle="dropdown" style="background-color:{{role.color}};"
               ng-show="hasLabel(role.name)">{{role.name}}</button>
            <ul class="dropdown-menu" role="menu" aria-labelledby="menu2">
               <li role="presentation">
                  <a role="menuitem" title="{{add}}"
                     ng-click="toggleLabel(role)" style="border:2px {{role.color}} solid;">
                     Remove Label:<br/>{{role.name}}</a></li>
            </ul>
          </span>

        <%if (isLoggedIn) { %>
        <span class="dropdown">
           <button class="btn btn-sm btn-primary btn-raised labelButton"
               type="button"
               id="menu1"
               data-toggle="dropdown"
               title="Add Label"
               style="padding:5px 10px">
               <i class="fa fa-plus"></i></button>
           <ul class="dropdown-menu" role="menu" aria-labelledby="menu1"
                   style="width:320px;left:-130px">
               <li role="presentation" ng-repeat="rolex in allLabels" style="float:left">
                   <button role="menuitem" tabindex="-1" ng-click="toggleLabel(rolex)" class="labelButton"
                           ng-hide="hasLabel(rolex.name)" style="background-color:{{rolex.color}}">
                       {{rolex.name}}</button>
               </li>
           </ul>
        </span>
        <% } %>
    </td>
</tr>
<tr>
    <td class="labelColumn" ng-click="openAttachDocument()">Attachments:</td>
    <td ng-dblclick="openAttachDocument()">
        <div ng-repeat="docid in noteInfo.docList" style="vertical-align: top">
          <span ng-click="navigateToDoc(docid)"><img src="<%=ar.retPath%>assets/images/iconFile.png"></span>&nbsp;
          <span ng-click="downloadDocument(docid)"><span class="fa fa-download"></span></span>&nbsp;
          <span ng-click="sendDocByEmail(docid)"><span class="fa fa-envelope-o"></span></span>&nbsp;
          
          {{getFullDoc(docid).name}}
        </div>
        <div ng-hide="noteInfo.docList && noteInfo.docList.length>0" class="doubleClickHint">
            Double-click to add / remove attachments
        </div>
    </td>
</tr>

<tr>
    <td class="labelColumn" ng-click="openAttachAction()">Action Items:</td>
    <td ng-dblclick="openAttachAction()">
        <div ng-repeat="goal in getActions()">
          <div>
            <img ng-src="<%=ar.retPath%>assets/goalstate/small{{goal.state}}.gif">
            {{goal.synopsis}}
          </div>
          </div>
        </div>
        <div ng-hide="getActions().length>0" class="doubleClickHint">
            Double-click to add / remove action items
        </div>
    </td>
</tr>
<tr ng-hide="editMeetingPart=='subscribers'">
    <td class="labelColumn" ng-click="editMeetingPart='subscribers'">Subscribers:</td>
    <td ng-dblclick="editMeetingPart='subscribers'">
        <span ng-repeat="player in noteInfo.subscribers" title="{{player.name}}"    
          style="text-align:center">
          <span class="dropdown" >
            <span id="menu1" data-toggle="dropdown">
              <img src="<%=ar.retPath%>icon/{{player.image}}" 
                 style="width:32px;height:32px" 
                 title="{{player.name}} - {{player.uid}}"
                 class="img-circle" />
            </span>
            <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
              <li role="presentation" style="background-color:lightgrey"><a role="menuitem" 
                  tabindex="-1" style="text-decoration: none;text-align:center">
                  {{player.name}}<br/>{{player.uid}}</a></li>
              <li role="presentation" style="cursor:pointer"><a role="menuitem" tabindex="-1"
                  ng-click="navigateToUser(player)">
                  <span class="fa fa-user"></span> Visit Profile</a></li>
            </ul>
          </span>
        </span>
    </td>
</tr>
<tr><td>&nbsp;</td><td>&nbsp;</td></tr>
</table>
      <div class="well" ng-show="editMeetingPart=='subscribers'">
          <h2>Adjust Subscribers:</h2>
          <div>
              <tags-input ng-model="noteInfo.subscribers" 
                          placeholder="Enter users to send notification email to"
                          display-property="name" key-property="uid"
                          replace-spaces-with-dashes="false" add-on-space="true" add-on-comma="true"
                          on-tag-added="updatePlayers()" 
                          on-tag-removed="updatePlayers()">
                  <auto-complete source="loadPersonList($query)" min-length="1"></auto-complete>
              </tags-input>
          </div>
          <div>
          <span class="dropdown">
              <button class="btn btn-default btn-primary btn-raised" type="button" 
                      ng-click="saveEdits(['subscribers']);editMeetingPart=null"
                      title="Post this topic but don't send any email">
              Save </button>
          </span>
          </div>
      </div>


<table>
  <tr ng-repeat="cmt in getComments()">

     <%@ include file="/spring/jsp/CommentView.jsp"%>

  </tr>


    <tr><td style="height:20px;"></td></tr>

    <tr>
    <td></td>
    <td>
    <div ng-show="canUpdate && !isEditing">
        <div style="margin:20px;">
            <button ng-click="openCommentCreator({},1)" class="btn btn-default btn-raised">
                Create New <i class="fa fa-comments-o"></i> Comment</button>
            <button ng-click="openCommentCreator({},2)" class="btn btn-default btn-raised">
                Create New <i class="fa fa-star-o"></i> Proposal</button>
            <button ng-click="openCommentCreator({},3)" class="btn btn-default btn-raised">
                Create New <i class="fa  fa-question-circle"></i> Round</button>
        </div>
    </div>
    <div ng-hide="canUpdate">
        <i>You have to be logged in and a member of this workspace in order to create a comment</i>
    </div>
    </td>
    </tr>

</table>


</div>

<script src="<%=ar.retPath%>templates/CommentModal.js"></script>
<script src="<%=ar.retPath%>templates/ResponseModal.js"></script>
<script src="<%=ar.retPath%>templates/OutcomeModal.js"></script>
<script src="<%=ar.retPath%>templates/DecisionModal.js"></script>
<script src="<%=ar.retPath%>templates/AttachDocumentCtrl.js"></script>
<script src="<%=ar.retPath%>templates/AttachActionCtrl.js"></script>
<script src="<%=ar.retPath%>templates/Feedback.js"></script>

<%out.flush();%>
