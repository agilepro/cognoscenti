<%@page errorPage="/spring2/jsp/error.jsp"
%><%@ include file="/include.jsp"
%><%@page import="com.purplehillsbooks.weaver.LeafletResponseRecord"
%><%@page import="com.purplehillsbooks.weaver.LicenseForUser"
%><%
    //set 'forceTemplateRefresh' in config file to 'true' to get this
    String templateCacheDefeater = "";
    if ("true".equals(ar.getSystemProperty("forceTemplateRefresh"))) {
        templateCacheDefeater = "?t="+System.currentTimeMillis();
    }


    String pageId = ar.reqParam("pageId");
    String siteId = ar.reqParam("siteId");
    NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngw);
    ar.assertLoggedIn("Page designed only for logged in user, should never see this message");
    JSONObject workspaceInfo = ngw.getConfigJSON();

    boolean isLoggedIn = ar.isLoggedIn();

    //there might be a better way to measure this that takes into account
    //magic numbers and tokens
    boolean canComment = ar.canUpdateWorkspace();

    NGBook ngb = ngw.getSite();
    UserProfile uProf = ar.getUserProfile();
    String currentUser = uProf.getUniversalId();
    String currentUserName = uProf.getName();
    String currentUserKey = uProf.getKey();
    boolean canUpdate = ar.canUpdateWorkspace();

    String topicId = ar.reqParam("topicId");
    TopicRecord topic = ngw.getNoteOrFail(topicId);
    
    String topicPrivateUrl = ar.baseURL + ar.getResourceURL(ngw, "NoteZoom"+topicId+".htm");
    String magicNumber = AccessControl.getAccessTopicParams(ngw, topic);
    String topicPublicUrl = ar.baseURL + ar.getResourceURL(ngw, "NoteZoom"+topicId+".htm?"+magicNumber);

    if (!AccessControl.canAccessTopic(ar, ngw, topic)) {
        throw new Exception("Program Logic Error: this view should only display when user can actually access the note.");
    }

    JSONObject noteInfo = topic.getJSONWithComments(ar, ngw);
    JSONArray comments = noteInfo.getJSONArray("comments");
    JSONArray attachmentList = ngw.getJSONAttachments(ar);
    JSONArray allLabels = ngw.getJSONLabels();

    JSONArray history = new JSONArray();
    for (HistoryRecord hist : topic.getNoteHistory(ngw)) {
        history.put(hist.getJSON(ngw, ar));
    }

    JSONArray allGoals     = ngw.getJSONGoals();
    JSONArray allRoles = new JSONArray();
    for (NGRole role : ngw.getAllRoles()) {
        allRoles.put( role.getJSON() );
    }

    String docSpaceURL = "";
    if (uProf!=null) {
        LicenseForUser lfu = new LicenseForUser(ar.getUserProfile());
        docSpaceURL = ar.baseURL +  "api/" + ngb.getKey() + "/" + ngw.getKey()
                    + "/summary.json?lic="+lfu.getId();
    }

    //to access the email-ready page, you need to get the license parameter
    //for this note.  This string saves this for use below on reply to comments
    String specialAccess =  AccessControl.getAccessTopicParams(ngw, topic)
                + "&emailId=" + URLEncoder.encode(ar.getBestUserId(), "UTF-8");


    long reportStart = topic.getReportStart();
    long reportEnd = topic.getReportEnd();
    
    JSONObject report = new JSONObject();
    JSONArray meetingList = report.requireJSONArray("meetingList");
    JSONArray goalList = report.requireJSONArray("goalList");
    JSONArray decisionList = report.requireJSONArray("decisionList");
    
    if (reportStart>0 && reportEnd > 0) {
        for (MeetingRecord meet: ngw.getMeetings()) {
            if (meet.getStartTime()>=reportStart && meet.getStartTime()<=reportEnd) {
                meetingList.put(meet.getListableJSON(ar));
            }
        }
        for (GoalRecord goal: ngw.getAllGoals()) {
            if (goal.getState() != BaseRecord.STATE_COMPLETE) {
                // continue;
            }
            if (goal.getEndDate()>=reportStart && goal.getEndDate()<=reportEnd) {
                goalList.put(goal.getJSON4Goal(ngw));
            }
        }
        for (DecisionRecord dec: ngw.getDecisions()) {
            if (dec.getTimestamp()>=reportStart && dec.getTimestamp()<=reportEnd) {
                decisionList.put(dec.getJSON4Decision(ngw, ar));
            }
        }
    }
    
%>



<script type="text/javascript">
document.title="<% ar.writeJS(topic.getSubject());%>";

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal, $interval, AllPeople) {
    setUpLearningMethods($scope, $modal, $http);
    window.setMainPageTitle("Discussion Topic");
    $scope.siteInfo = <%ngb.getConfigJSON().write(out,2,4);%>;
    $scope.workspaceInfo = <%workspaceInfo.write(out,2,4);%>;
    $scope.noteInfo = <%noteInfo.write(out,2,4);%>;
    $scope.topicId = "<%=topicId%>";
    $scope.allRoles = <%allRoles.write(out,2,4);%>;
    $scope.allDocs = [];
    $scope.attachmentList = <%attachmentList.write(out,2,4);%>;
    $scope.allLabels = <%allLabels.write(out,2,4);%>;
    $scope.canComment = <%=canComment%>;
    $scope.history = <%history.write(out,2,4);%>;
    $scope.allGoals = <%allGoals.write(out,2,4);%>;
    $scope.nonMembers = [];
    $scope.addressMode = false;
    $scope.canUpdate = <%=canUpdate%>;
    $scope.topicPrivateUrl = "<%ar.writeJS(topicPrivateUrl);%>";
    $scope.topicPublicUrl = "<%ar.writeJS(topicPublicUrl);%>";
    $scope.report = <%report.write(out,2,4);%>;

    $scope.currentTime = (new Date()).getTime();
    $scope.docSpaceURL = "<%ar.writeJS(docSpaceURL);%>";

    $scope.isEditing = false;
    $scope.item = {};

    $scope.autoRefresh = true;
    $scope.bgActiveLimit = 0;
    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        $scope.cancelBackgroundTime();
        errorPanelHandler($scope, serverErr);
    };
    $scope.secondsTillSave = 0;
    $scope.changesToSave = false;

    $scope.fixUpChoices = function() {
        if ($scope.noteInfo.comments) {
            $scope.noteInfo.comments.forEach( function(cmt) {
                if (!cmt.choices || cmt.choices.length==0) {
                    cmt.choices = ["Consent", "Objection"];
                }
                if (cmt.choices[1]=="Object") {
                    cmt.choices[1]="Objection";
                }
            });
        }
    }
    $scope.getContrastColor = function (color) {

        const tempEl = document.createElement("div");
        tempEl.style.color = color;
        document.body.appendChild(tempEl);
        const computedColor = window.getComputedStyle(tempEl).color;
        document.body.removeChild(tempEl);

        const match = computedColor.match(/\d+/g);

        if (!match) {
            console.error("Failed to parse color: ", computedColor);
            return "#39134C";
        }
        const [r, g, b] = match.map(Number);

        var yiq = ((r * 299) + (g * 587) + (b * 114)) / 1000;

        return (yiq >= 128) ? '#39134C' : '#ebe7ed';
    };

    $scope.myComment = "";
    $scope.myCommentType = 1;   //simple comment
    $scope.myReplyTo = 0;
    $scope.getContrastColor = function (color) {

        const tempEl = document.createElement("div");
        tempEl.style.color = color;
        document.body.appendChild(tempEl);
        const computedColor = window.getComputedStyle(tempEl).color;
        document.body.removeChild(tempEl);

        const match = computedColor.match(/\d+/g);

        if (!match) {
            console.error("Failed to parse color: ", computedColor);
            return "#39134C";
        }
        const [r, g, b] = match.map(Number);

        var yiq = ((r * 299) + (g * 587) + (b * 114)) / 1000;

        return (yiq >= 128) ? '#39134C' : '#ebe7ed';
    };

//When NOT editing, then the HTML is generated from the WIKI and displayed exactly
//as it is, no complication.
//
//When editing, then
//   wikiLastSave - contains the version of markdown that the editor started with
//   wikiEditing  - contains the version of markdown that the user has just typed
//   htmlEditing  - is the HTML version actually being edited in rich text editor
//
//When saving (or autosave) the above two versions are sent
//When the response comes from the server 
//
//   $scope.noteInfo.wiki contains the last version received from the server
//   data.wiki is the new version from the server and stored 
//
//$scope.changesToMerge indicates that $scope.noteInfo.wiki != wikiLastSave
//because some new change has come from server and needs to be merged
//
//When requested by user, the Merge(noteInfo.wiki, lastSave, wikiEditing)--> wikiEditing
//and then noteInfo.wiki --> lastSave.


    $scope.startEdit = function() {
        if (!$scope.canUpdate) {
            alert("Unable to update discussion because you are not playing an update role in the workspace");
            return;
        }
        if ($scope.workspaceInfo.frozen) {
            alert("Sorry, this workspace is frozen by the administrator\nDiscussions can not be edited in a frozen workspace.");
            return;
        }
        if ($scope.isEditing) {
            //already editing so nothing to do
            return;
        }
        
        //clear from any prior edit sessions
        $scope.saveNotice = "All Saved";
        
        //fetch the newest, most up to date copy to start editing
        var postURL = "getTopic.json?nid="+$scope.topicId;
        $scope.showError=false;
        $http.get(postURL)
        .success( function(data) {
            $scope.extendBackgroundTime();
            $scope.receiveTopicRecord(data);
            $scope.wikiLastSave = $scope.noteInfo.wiki;
            $scope.wikiEditing = $scope.noteInfo.wiki;
            $scope.htmlEditing = convertMarkdownToHtml($scope.noteInfo.wiki);
            $scope.isEditing = true;
            $scope.changesToSave = false;
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    }
    $scope.mergeUpdateDoc = function(changeEditing) {
        if (!$scope.canUpdate) {
            alert("Unable to update discussion because you are not playing an update role in the workspace");
            return;
        }
        if (!changeEditing) {
            $scope.extendBackgroundTime();
        }
        $scope.wikiEditing = HTML2Markdown($scope.htmlEditing, {});
        
        var rec = {};
        rec.old = $scope.wikiLastSave;
        rec.new = $scope.wikiEditing;
        rec.subject = $scope.noteInfo.subject;
        
        var postURL = "mergeTopicDoc.json?nid="+$scope.topicId;
        $scope.showError=false;
        $http.post(postURL, angular.toJson(rec))
        .success( function(data) {
            $scope.wikiLastSave = rec.new;
            $scope.receiveTopicRecord(data);
            $scope.isEditing = changeEditing;
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    }
    $scope.saveEdits = function(fields) {
        if (!$scope.canUpdate) {
            alert("Unable to update discussion because you are not playing an update role in the workspace");
            return;
        }
        var postURL = "noteHtmlUpdate.json?nid="+$scope.topicId;
        var rec = {};
        rec.id = $scope.topicId;
        rec.universalid = $scope.noteInfo.universalid;
        fields.forEach( function(fieldName) {
            rec[fieldName] = $scope.noteInfo[fieldName];
        });
        if ($scope.isEditing) {
            rec.subject = $scope.noteInfo.subject;
        }
        var postdata = angular.toJson(rec);
        $scope.showError=false;
        $http.post(postURL ,postdata)
        .success( function(data) {
            $scope.extendBackgroundTime();
            $scope.receiveTopicRecord(data);
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };
    function refreshTopic() {
        var postURL = "getTopic.json?nid="+$scope.topicId;
        $scope.showError=false;
        $http.get(postURL)
        .success( function(data, status, headers, config) {
            $scope.receiveTopicRecord(data);
        })
        .error( function(data, status, headers, config) {
            console.log("   FAILED"+ status, data);
            $scope.reportError(data);
        });
    }

    
    $scope.mergeFromOthers = function() {
        if ($scope.isEditing) {
            $scope.wikiEditing = HTML2Markdown($scope.htmlEditing, {});
            $scope.wikiEditing = Textmerger.get().merge($scope.wikiLastSave, $scope.wikiEditing, $scope.noteInfo.wiki);
        }
        else {
            $scope.wikiEditing = $scope.noteInfo.wiki;
        }
        $scope.htmlEditing = convertMarkdownToHtml($scope.wikiEditing);
        $scope.wikiLastSave = $scope.noteInfo.wiki;
        $scope.changesToMerge = false;
        $scope.changesToSave = ($scope.wikiEditing != $scope.wikiLastSave);
    }

    $scope.receiveTopicRecord = function(data) {
        data.comments.forEach( function(cmt) {
            $scope.generateCommentHtml(cmt);
        });
        if (data.subscribers) {
            data.subscribers.forEach( function(person) {
                if (person.uid == "<%=ar.getBestUserId()%>") {
                    check = true;
                }
                person.image = AllPeople.imageName(person);
            });
        }
        $scope.lastRefreshTimestamp = new Date().getTime();
        $scope.noteInfo = data;
        if (data.wiki) {
            if ($scope.isEditing) {
                if (data.wiki.trim() != $scope.wikiEditing.trim()) {
                    $scope.changesToMerge = true;
                }
            }
            else {
                //merge immediately if not editing
                $scope.mergeFromOthers();
            }
        }
        var check = false;
        $scope.fixUpChoices();
        $scope.isSubscriber = check;
        $scope.refreshHistory();
        
        //recalculate non-members
        var members = getRolePlayers("Members");
        var stewards = getRolePlayers("Stewards");
        var newNonMembers = [];
        $scope.noteInfo.subscribers.forEach( function(subber) {
            if (!members[subber.key] && !stewards[subber.key]) {
                newNonMembers.push(subber);
            }
        });
        $scope.nonMembers = newNonMembers;
        $scope.changesToSave = ($scope.wikiEditing != $scope.wikiLastSave);
    }
    
    function getRolePlayers(roleName) {
        var res = {};
        $scope.allLabels.forEach( function(role) {
            if (role.name == roleName) {
                role.players.forEach( function(player) {
                    res[player.key] = player;
                });
            }
        });
        return res;
    }
    
    $scope.addMember = function(newMember) {
        if ($scope.isFrozen) {
            alert("You are not able to update this role because this workspace is frozen");
            return;
        }
        var postURL = "roleUpdate.json?op=Update";
        var roleData = {name: "MembersRole", addPlayers: []};
        roleData.addPlayers.push(newMember);
        var postdata = angular.toJson(roleData);
        $scope.showError=false;
        $http.post(postURL ,postdata)
        .success( function(data) {
            location.reload(true);
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    }
    function refreshLabels() {
        if ($scope.isFrozen) {
            alert("You are not able to update this role because this workspace is frozen");
            return;
        }
        $scope.showError=false;
        $http.get("getAllLabels.json")
        .success( function(data) {
            $scope.allLabels = data.list;
            refreshTopic();
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    }

    $scope.saveDocs = function() {
        var saveRecord = {};
        saveRecord.id = $scope.topicId;
        saveRecord.universalid = $scope.noteInfo.universalid;
        saveRecord.docList = $scope.noteInfo.docList;
        $scope.savePartial(saveRecord);
    }
    $scope.saveLabels = function() {
        var saveRecord = {};
        saveRecord.id = $scope.topicId;
        saveRecord.universalid = $scope.noteInfo.universalid;
        saveRecord.labelMap = $scope.noteInfo.labelMap;
        $scope.savePartial(saveRecord);
    }

    $scope.savePartial = function(recordToSave) {
        var postURL = "noteHtmlUpdate.json?nid="+$scope.topicId;
        var postdata = angular.toJson(recordToSave);
        $scope.showError=false;
        $http.post(postURL, postdata)
        .success( function(data) {
            $scope.extendBackgroundTime();
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
        if ($scope.noteInfo.actionList) {
            $scope.noteInfo.actionList.forEach( function(actionId) {
                if (actionId == oneAct.universalid) {
                    res = true;
                }
            });
        }
        return res;
    }
    $scope.getActions = function() {
        if ($scope.allGoals) {
            return $scope.allGoals.filter( function(oneAct) {
                return $scope.itemHasAction(oneAct);
            });
        }
        else {
            return [];
        }
    }
    $scope.navigateToMeeting = function(meet) {
        window.location="MeetingHtml.htm?id="+meet.id;
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

    $scope.getComments = function() {
        var res = [];
        if ($scope.noteInfo.comments) {
            $scope.noteInfo.comments.forEach( function(item) {
                if (item.commentType < 4) {
                    // 4 is a meeting attachment from topic to meeting
                    // 5 is minutes idea which is no longer used
                    res.push(item);
                }
            });
        }
        res.sort( function(a,b) {
            return a.time - b.time;
        });
        return res;
    }

    $scope.refreshHistory = function() {
        var postURL = "getNoteHistory.json?nid="+$scope.topicId;
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
        $scope.subscriberBuffer = $scope.noteInfo.subscribers;
        $scope.addressMode = true;
    }
    $scope.updatePlayers = function() {
        $scope.noteInfo.subscribers = cleanUserList($scope.noteInfo.subscribers);
    }    
    $scope.postIt = function(sendEmail) {
        //automatic sending has been defeated, but just 
        //redirect to the manual sending to prepare the messsage
        $scope.noteInfo.subscribers = $scope.subscriberBuffer;
        $scope.noteInfo.sendEmailNow = false;;
        $scope.setPhase("Freeform");
        $scope.addressMode = false;
        if (sendEmail) {
            $scope.sendNoteByMail();
        }
    }

    $scope.changeSubscription = function(onOff) {
        var url = "topicSubscribe.json?nid="+$scope.topicId;
        if (!onOff) {
            url = "topicUnsubscribe.json?nid="+$scope.topicId;
        }
        $http.get(url)
        .success( $scope.receiveTopicRecord )
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    }

    $scope.defaultProposalAssignees = function() {
        return $scope.noteInfo.subscribers;
    }
    $scope.refreshCommentList = function() {
        refreshTopic();
    }
    
    
    $scope.tuneNewComment = function(newComment) {
        newComment.containerType = "T";
        newComment.containerID = $scope.topicId;
    }
    $scope.tuneNewDecision = function(newDecision, cmt) {
        newDecision.sourceId = $scope.topicId;
        newDecision.sourceType = 4;
        newDecision.labelMap = $scope.noteInfo.labelMap;
    }
    $scope.refreshCommentContainer = function() {
        refreshTopic();
        $scope.refreshHistory();
        $scope.extendBackgroundTime();
    }
    setUpCommentMethods($scope, $http, $modal);






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

    $scope.navigateToDoc = function(doc) {
        if (!doc.id) {
            alert("doc id is missing");
            return;
        }
        window.location="DocDetail.htm?aid="+doc.id;
    }
    $scope.sendDocByEmail = function(docId) {
        var doc = $scope.getFullDoc(docId);
        window.location="EmailCompose.htm?att="+doc.id;
    }
    $scope.downloadDocument = function(doc) {
        window.location="a/"+doc.name;
    }
    $scope.navigateToLink = function(doc) {
        window.open(doc.url, "_blank");
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
    
    $scope.retrieveAllDocuments = function() {
        var getURL = "docsList.json";
        $scope.showError=false;
        $http.get(getURL)
        .success( function(data) {
            var undeleted = [];
            data.docs.forEach( function(item) {
                if (!item.deleted) {
                    undeleted.push(item);
                }
            });
            $scope.allDocs = undeleted;
            $scope.refreshAttachedDocs();
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    }
    $scope.refreshAttachedDocs = function() {
        var getURL = "attachedDocs.json?note="+$scope.topicId;
        $http.get(getURL)
        .success( function(data) {
            $scope.noteInfo.docList = data.list;
            
            var attachedDocTemp = [];
            data.list.forEach( function(item) {
                $scope.allDocs.forEach( function(aDoc) {
                    if (aDoc.universalid == item) {
                        attachedDocTemp.push(aDoc);
                    }
                });
            });
            $scope.attachedDocs = attachedDocTemp;
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });

    }
    $scope.retrieveAllDocuments();
    
    
    $scope.openAttachDocument = function () {
        if (!$scope.canUpdate) {
            alert("Unable to update discussion because you are not playing an update role in the workspace");
            return;
        }
        $scope.cancelBackgroundTime();

        if ($scope.workspaceInfo.frozen) {
            alert("Sorry, this workspace is frozen by the administrator\Documents can not be attached in a frozen workspace.");
            return;
        }

        var attachModalInstance = $modal.open({
            animation: true,
            templateUrl: '<%=ar.retPath%>new_assets/templates/AttachDocument.html<%=templateCacheDefeater%>',
            controller: 'AttachDocumentCtrl',
            size: 'lg',
            resolve: {
                containingQueryParams: function() {
                    return "note="+$scope.topicId;
                },
                docSpaceURL: function() {
                    return $scope.docSpaceURL;
                }
            }
        });

        attachModalInstance.result
        .then(function (docList) {
            //force re-read
            $scope.retrieveAllDocuments();
            $scope.extendBackgroundTime();
        }, function () {
            refreshTopic();
            $scope.retrieveAllDocuments();
            $scope.extendBackgroundTime();
        });
    };

    $scope.openAttachAction = function (item) {
        if (!$scope.canUpdate) {
            alert("Unable to update discussion because you are not playing an update role in the workspace");
            return;
        }
        $scope.cancelBackgroundTime();

        if ($scope.workspaceInfo.frozen) {
            alert("Sorry, this workspace is frozen by the administrator\Action items can not be attached in a frozen workspace.");
            return;
        }
        var attachModalInstance = $modal.open({
            animation: true,
            templateUrl: '<%=ar.retPath%>new_assets/templates/AttachAction.html<%=templateCacheDefeater%>',
            controller: 'AttachActionCtrl',
            size: 'lg',
            resolve: {
                containingQueryParams: function() {
                    return "note="+$scope.topicId;
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
            $scope.extendBackgroundTime();
        }, function () {
            $scope.refreshAllGoals();
            refreshTopic();
            $scope.extendBackgroundTime();
        });
    };
    
    
    $scope.openModalActionItem = function (goal, start) {
        if (!$scope.canUpdate) {
            alert("Unable to update discussion because you are not playing an update role in the workspace");
            return;
        }
        $scope.cancelBackgroundTime();
        if (!start) {
            start = 'status';
        }
        var modalInstance = $modal.open({
            animation: true,
          templateUrl: "<%=ar.retPath%>new_assets/templates/ActionItem.html<%=templateCacheDefeater%>",
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
            $scope.extendBackgroundTime();
            $scope.allGoals.forEach( function(item) {
                if (item.id == modifiedGoal.id) {
                    item.duedate = modifiedGoal.duedate;
                    item.status = modifiedGoal.status;
                }
            });
            $scope.refreshAllGoals();
            refreshTopic();
        }, function () {
            $scope.refreshAllGoals();
            refreshTopic();
            $scope.extendBackgroundTime();
        });
    };    
    $scope.refreshAllGoals = function() {
        var getURL = "allActionsList.json";
        $http.get(getURL)
        .success( function(data) {
            $scope.allGoals = data.list;
            $scope.constructAllCheckItems();
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    }
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
    $scope.constructAllCheckItems();
    
    $scope.openFeedbackModal = function (item) {
        $scope.cancelBackgroundTime();
        
        var attachModalInstance = $modal.open({
            animation: true,
            templateUrl: '<%=ar.retPath%>new_assets/templates/Feedback.html<%=templateCacheDefeater%>',
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
            refreshTopic();
            $scope.extendBackgroundTime();
        }, function () {
            refreshTopic();
            $scope.extendBackgroundTime();
        });
    };

    $scope.tinymceOptions = standardTinyMCEOptions();
    $scope.tinymceOptions.height = 400;
	$scope.tinymceOptions.init_instance_callback = function(editor) {
        $scope.initialContent = editor.getContent();
	    editor.on('Change', tinymceChangeTrigger);
        editor.on('KeyUp', tinymceChangeTrigger);
        editor.on('Paste', tinymceChangeTrigger);
        editor.on('Remove', tinymceChangeTrigger);
        editor.on('Format', tinymceChangeTrigger);
    }
    function tinymceChangeTrigger(e, editor) {
        //this runs every keystroke in the editor
        $scope.lastKeyTimestamp = new Date().getTime();
        $scope.wikiEditing = HTML2Markdown($scope.htmlEditing, {});
        $scope.changesToSave = ($scope.wikiEditing != $scope.wikiLastSave);
    }


    $scope.autoIdleCount = 0;
    $scope.autoSaveCount = 0;

    $scope.askingToContinue = false;
    $scope.autosave = function() {
        if (!$scope.autoRefresh) {
            //the autorefresh can be turned off and then ignored until 
            //turned back on again.
            return;
        }
        if ($scope.isEditing && $scope.wikiEditing != $scope.wikiLastSave) {
            //while editing & local change, then check every 5 seconds of idle time
            $scope.secondsTillSave = 5 - Math.floor((new Date().getTime() - $scope.lastKeyTimestamp)/1000);
        }
        else {
            //when not editing, refresh every 20 seconds
            $scope.secondsTillSave = 20 - Math.floor((new Date().getTime() - $scope.lastRefreshTimestamp)/1000);
        }
        if ($scope.secondsTillSave > 0) {
            //still time to wait so skip this time
            return;
        }
        var remainingSeconds = ($scope.bgActiveLimit - (new Date().getTime()))/1000;
        if (remainingSeconds<0) {
            //turn all refresh and background activities off
            $scope.autoRefresh = false;
            console.log("AUTOSAVE deactivated");
            if ($scope.askingToContinue) {
                return;
            }
            //this is double prevention of duplicate alert box launches
            $scope.askingToContinue = true;
            msg = "Background refresh stopped after 20 minutes without interaction.\n"
                       +"Click OK to manually refresh.";
            if (alert(msg)) {
                location.reload(true);
            }
            $scope.askingToContinue = false;
            return;
        }
        console.log("AUTOSAVE:  refreshing for "+remainingSeconds+" more seconds");
        $scope.saveNotice = "All Saved at "+new Date().toLocaleTimeString();
        if ($scope.isEditing) {
            if (!$scope.lastAuto) {
                $scope.lastAuto = {};
            }
            if (false && $scope.noteInfo.html==$scope.lastAuto.html &&
                            $scope.noteInfo.subject==$scope.lastAuto.subject) {
                console.log("AUTOSAVE - skipped, nothing new to save");
                //it IS idle so increase the idle counter, but after ten tried no change, go and fetch the latest
                //this indicates that the user is not actively typing and might be OK to refresh the edit panel
                if ($scope.autoIdleCount++ > 10) {
                    $scope.autoIdleCount = 0;
                    refreshTopic();
                }
                return;
            }
            $scope.autoSaveCount++;
            $scope.mergeUpdateDoc(true);
        }
        else {
            refreshTopic();
            $scope.refreshAttachedDocs();
        }
    }
    $scope.cancelBackgroundTime = function() {
        console.log("BACKGROUND cancelled");
        $scope.autoRefresh = false;
        $scope.bgActiveLimit = 0;  //already past
    }
    $scope.extendBackgroundTime = function() {
        console.log("BACKGROUND time extended");
        $scope.autoRefresh = true;
        $scope.bgActiveLimit = (new Date().getTime())+1200000;  //twenty minutes
    }
    $scope.extendBackgroundTime();
    $scope.promiseAutosave = $interval($scope.autosave, 1000);

    $scope.loadPersonList = function(query) {
        return AllPeople.findMatchingPeople(query, $scope.siteInfo.key);
    }
    
    $scope.sendNoteByMail = function() {
        if ("Draft" == $scope.noteInfo.discussionPhase) {
            alert("Before sending by email you need to POST the note (possibly sending email at that time)");
            return;
        }
        if ("Trash" == $scope.noteInfo.discussionPhase) {
            alert("This discussion has been deleted (in Trash).  Undelete it before sending by email.");
            return;
        }
        window.location = "EmailCompose.htm?noteId="+$scope.topicId;
    }
    $scope.navigateToUser = function(player) {
        window.location="<%=ar.retPath%>v/"+encodeURIComponent(player.key)+"/PersonShow.htm";
    }
    $scope.startSubscriberEdit = function() {
        if (!$scope.canUpdate) {
            alert("Unable to update discussion because you are not playing an update role in the workspace");
            return;
        }
        $scope.editMeetingPart='subscribers';
        $scope.subscriberBuffer = $scope.noteInfo.subscribers;
    }
    $scope.saveSubscriberEdit = function() {
        $scope.editMeetingPart=null;
        var saveRec = {subscribers: $scope.subscriberBuffer, universalid: $scope.noteInfo.universalid};
        $scope.savePartial(saveRec);
    }
    $scope.toggleReadOnlyPart = function(section) {
        if ($scope.editMeetingPart===section) {
            $scope.editMeetingPart = "bogus";
        }
        else {
            $scope.editMeetingPart = section;
        }
    }
    $scope.toggleEditPart = function(section) {
        if (!$scope.canUpdate) {
            alert("Unable to update discussion because you are not playing an update role in the workspace");
            return;
        }
        $scope.toggleReadOnlyPart(section);
    }
    
    
    initializeLabelPicker($scope, $http, $modal);    
    
    //now actually get it
    refreshTopic();
    $scope.openEditLabelsModal = function (item) {
        
        var attachModalInstance = $modal.open({
            animation: true,
            templateUrl: '../../../new_assets/templates/EditLabels.html',
            controller: 'EditLabelsCtrl',
            size: 'lg',
            resolve: {
                siteInfo: function () {
                  return $scope.siteInfo;
                },
            }
        });

        attachModalInstance.result
        .then(function (selectedActionItems) {
            $scope.getAllLabels();
        }, function () {
            $scope.getAllLabels();
        });
    };
    
    $scope.generateLink = function(typeOfLink) {
        if (typeOfLink === "Public") {
            $scope.generatedLink = $scope.topicPublicUrl;
        }
        else {
            $scope.generatedLink = $scope.topicPrivateUrl;
        }
    }
    $scope.linkScope = "Private";
    $scope.generateLink("Private");

    $scope.goToMobileUi = function() {
        let dest = "TopicView.wmf?topicId="+$scope.topicId;
        window.location.assign(dest);
    }
    $scope.addPlayers = function(role) {
        if (!role) {
            return;
        }
        let subList = [];
        role.players.forEach( function(player) {
            let found = false;
            $scope.subscriberBuffer.forEach( function(alreadyThere) {
                if (alreadyThere.key === player.key) {
                    found = true;
                } else if (alreadyThere.uid === player.uid) {
                    found = true;
                }
            });
            if (!found) {
                $scope.subscriberBuffer.push(player);
            }
        });
    }
    $scope.clearSubscribers = function() {
        $scope.subscriberBuffer.length = 0;
    }
    $scope.editReport = function() {
        $scope.editMeetingPart = 'report';
    }
    $scope.saveReport = function() {
        $scope.editMeetingPart = '';
        console.log("NOTE REPORT:", $scope.noteInfo);
        var saveRecord = {};
        saveRecord.id = $scope.topicId;
        saveRecord.universalid = $scope.noteInfo.universalid;
        saveRecord.reportStart = $scope.noteInfo.reportStart;
        saveRecord.reportEnd = $scope.noteInfo.reportEnd;
        $scope.savePartial(saveRecord);
    }
    $scope.clearReport = function() {
        $scope.noteInfo.reportStart = 0;
        $scope.noteInfo.reportEnd = 0;
        $scope.saveReport();
    }
    
});

function copyTheLink() {
  /* Get the text field */
  var copyText = document.getElementById("generatedLink");

  /* Select the text field */
  copyText.select();

  /* Copy the text inside the text field */
  document.execCommand("copy");
}
</script>
<script src="../../new_assets/jscript/AllPeople.js"></script>

<style>
.box {
    border: solid 1px lightskyblue;
    border-radius: 15px;
    padding: 10px;
}
.shade {
    background-color: #EEE;
    padding: 10px;
    border-radius: 15px;
}
</style>

<div class="container-fluid override mb-4 mx-3 d-inline-flex">
    <span class="dropdown mt-1">
        <button class="btn btn-outline-secondary btn-tiny dropdown-toggle" type="button" id="dropdownInfoMenu"
            data-bs-toggle="dropdown" aria-expanded="false">
        </button>
        <ul class="dropdown-menu" aria-labelledby="dropdownInfoMenu">
            <li>
                <button class="dropdown-item" onclick="window.location.reload(true)">Refresh</button>
                <span class="dropdown-item" type="button">
                    <a class="nav-link" role="menuitem" tabindex="-1" ng-click="startEdit()">
                        Edit This Topic</a></span>
                <span class="dropdown-item" type="button">
                    <a class="nav-link" role="menuitem" tabindex="-1"
                        href="pdf/note{{noteInfo.id}}.pdf?publicNotes={{noteInfo.id}}&comments=true">
                        PDF with Comments</a></span>
                <span class="dropdown-item" type="button">
                    <a class="nav-link" role="menuitem" tabindex="-1"
                        href="pdf/note{{noteInfo.id}}.pdf?publicNotes={{noteInfo.id}}">
                        PDF without Comments</a></span>
                <span class="dropdown-item" type="button">
                    <a class="nav-link" role="menuitem" tabindex="-1"
                        ng-click="sendNoteByMail()">
                        Send Topic By Email</a></span>
                <span class="dropdown-item" type="button" ng-hide="isSubscriber">
                    <a class="nav-link" role="menuitem" tabindex="-1" 
                        ng-click="changeSubscription(true)">
                        Subscribe to this Topic</a></span>
                <span class="dropdown-item" type="button" ng-show="isSubscriber">
                    <a class="nav-link" role="menuitem" tabindex="-1" 
                        ng-click="changeSubscription(false)">
                        Unsubscribe from this Topic</a></span>
                <span class="dropdown-item" type="button">
                    <a class="nav-link" role="menuitem" tabindex="-1" href="NotesList.htm">
                        List Topics</a></span>
                <span class="dropdown-item" type="button">
                    <a class="nav-link" role="menuitem" tabindex="-1" ng-click="goToMobileUi()">
                        Mobile UI</a></span>
            </li>
        </ul>
    </span>
    <span>
        <h1 class="d-inline page-name" id="mainPageTitle">Discussion Topic</h1>
    </span>
</div>



<%@include file="ErrorPanel.jsp"%>


<div class="d-flex col-12">
  <div class="contentColumn">
    <div class="container-fluid">
      <div class="generalContent">


    <h2 class="h3" ng-hide="isEditing" ng-click="startEdit()" >
        <i class="fa fa-lightbulb-o" style="font-size:130%"></i>
        {{noteInfo.subject}}
    </h2>

    
    <div class="col-12" ng-hide="isEditing" >
        <div class="leafContent" ng-dblclick="startEdit()">
            <div ng-bind-html="htmlEditing"></div>
        </div>
    </div>
<%if (isLoggedIn) { %>
    <div class="col-12 leafContent" ng-show="isEditing">
        <input type="text" class="form-control" ng-model="noteInfo.subject">
        <div style="height:15px"></div>
        <div ui-tinymce="tinymceOptions" ng-model="htmlEditing"></div>
        <div style="height:15px"></div>
        <button class="btn btn-primary btn-raised my-3" ng-click="mergeUpdateDoc(false)" 
                ng-show="changesToSave">Save & Close</button>
        <button class="btn btn-primary btn-raised my-3" ng-click="mergeUpdateDoc(false)"
                ng-hide="changesToSave">Close Editor</button>
        <button ng-show="changesToMerge" class="btn btn-warning btn-raised" 
            ng-click="mergeFromOthers()">Merge Edits from other Users</button>
        <span ng-hide="changesToSave" class="h6">{{saveNotice}}</span>
        <span ng-show="changesToSave" class="h6">Changes will be saved in {{secondsTillSave}} seconds.</span>
    </div>
<% } %>

<div class="box" ng-show="noteInfo.reportStart>0 && noteInfo.reportEnd>0">
  <h3>Status</h3>
  
  <p> The following accomplishments were recorded between {{noteInfo.reportStart|date}} and {{noteInfo.reportEnd|date}}.</p>
  
  <h3>Meetings</h3>
  
  <ul>
    <li ng-repeat="meet in report.meetingList">{{meet.startTime|cdate}} - 
            <a href="{{meet.minutesUrl}}">{{meet.name}}</a></li>
  </ul>
  
   
  <h3>Completed Action Items</h3>
  
  <ul>
    <li ng-repeat="goal in report.goalList">
        {{goal.enddate|date}} - {{goal.synopsis}}<br/>
        {{goal.description}} <br/>
        <span ng-repeat="john in goal.assignTo"> {{john.name}}, </span>
    </li>
  </ul>
    
  <h3>Decisions Recorded / Reviewed</h3>
  
  <div>
    <div ng-repeat="dec in report.decisionList" ng-show="dec.num">
        Decision {{dec.num}} - {{dec.timestamp|cdate}}
        <div ng-bind-html="dec.decision|wiki" class="shade"></div>
    </div>
  </div>
   
</div>

<div class="col-12 m-2">
<hr/>

    <div class="row ms-3">
        <span class="col-2 fixed-width-md bold labelColumn btn btn-outline-secondary mt-2" style="text-align:left" >
            Last modified:</span>
        <span class="col-9">
            {{noteInfo.modTime|cdate}}
            <button class="btn btn-primary btn-default btn-raised" ng-click="postIt(true)" 
                    title="Send this topic description by email with a link back to this page">
                Send This Topic <br/> By Email</button>
            <button class="btn btn-primary btn-default btn-raised" ng-click="postIt(false)" 
                    title="Send this topic description by email with a link back to this page"
                    ng-show="noteInfo.draft">
                Change Draft to Published</button>
        </span>
    </div>
    <div class="row ms-3">
        <span class="col-2 fixed-width-md bold labelColumn btn btn-outline-secondary mt-2" style="text-align:left"
            ng-click="toggleEditPart('Labels')">
            Labels:</span>
        <span class="col-9" ng-hide="editMeetingPart=='Labels'">
            <span class="dropdown mt-0" ng-repeat="role in allLabels">
              <button class="btn btn-wide labelButton"
                style="background-color:{{role.color}}; color: {{getContrastColor(role.color)}};"
                ng-show="hasLabel(role.name)" >{{role.name}}</i></button>
            </span>
        </span>
        <span class="col-9" ng-show="editMeetingPart=='Labels'">
            <%@ include file="/spring2/jsp/LabelPicker.jsp" %>
        </span>
    </div><hr/>

    <div class="row ms-3">
    <span class="col-2 fixed-width-md bold labelColumn btn btn-outline-secondary mt-2" style="text-align:left" ng-click="editReport()">Report Settings:</span>
    <span class="col-9" ng-dblclick="editReport()" ng-hide="editMeetingPart=='report'">
        Start Date: {{noteInfo.reportStart | date}}<br/>
        End Date: {{noteInfo.reportEnd | date}}
    </span>
    <span class="col-9" ng-dblclick="editReport()" ng-show="editMeetingPart=='report'">
        Start Date: <span datetime-picker ng-model="noteInfo.reportStart"
                  class="form-control">
              {{noteInfo.reportStart|date:"dd-MMM-yyyy   '&nbsp; at &nbsp;'  HH:mm"}}
            </span><br/>
        End Date: <span datetime-picker ng-model="noteInfo.reportEnd"
                  class="form-control">
              {{noteInfo.reportEnd|date:"dd-MMM-yyyy   '&nbsp; at &nbsp;'  HH:mm"}}
            </span>
        <button ng-click="saveReport()">Save</button>  <button ng-click="clearReport()">Clear Dates</button>
    </span>
    </div><hr/>
    
    <div class="row ms-3">
    <span class="col-2 fixed-width-md bold labelColumn btn btn-outline-secondary mt-2" style="text-align:left" ng-click="openAttachDocument()">Attachments:</span>
    <span class="col-9" ng-dblclick="openAttachDocument()">
        <div ng-repeat="doc in attachedDocs" style="vertical-align: top">
            <span ng-show="doc.attType=='FILE'">
                <span ng-click="navigateToDoc(doc)"><img src="<%=ar.retPath%>new_assets/assets/images/iconFile.png"></span>
              &nbsp;
                <span ng-click="downloadDocument(doc)"><span class="fa fa-download"></span></span>
            </span>
            <span  ng-show="doc.attType=='URL'">
                <span ng-click="navigateToDoc(doc)"><img src="<%=ar.retPath%>new_assets/assets/images/iconUrl.png"></span>
              &nbsp;
                <span ng-click="navigateToLink(doc)"><span class="fa fa-external-link"></span></span>
            </span>
          &nbsp;
            <span ng-click="sendDocByEmail(doc.id)"><span class="fa fa-envelope-o"></span></span>&nbsp;
          &nbsp; {{doc.name}}
        </div>
        <div ng-hide="attachedDocs && attachedDocs.length>0" class="doubleClickHint">
            Double-click to add / remove attachments
        </div>
        
    </span>
    </div><hr/>
    <div class="row ms-3">
    <span class="col-2 fixed-width-md bold labelColumn btn btn-outline-secondary" style="text-align:left" ng-click="openAttachAction()">Action Items:</span>
    <span class="col-9">
          <table class="table">
          <tr ng-repeat="goal in getActions()">
              <td>
                <a href="task{{goal.id}}.htm" title="access action item details">
                   <img ng-src="<%=ar.retPath%>assets/goalstate/small{{goal.state}}.gif"></a>
              </td>
              <td ng-dblclick="openModalActionItem(goal)">
                {{goal.synopsis}}
              </td>
              <td>
                <span ng-repeat="person in goal.assignTo">
                  <span class="dropdown" >
                    <ul class="nav-item p-0 list-inline">
                        <li class="nav-item dropdown" id="user" data-toggle="dropdown">
                            <img class="rounded-5" 
                         ng-src="<%=ar.retPath%>icon/{{person.key}}.jpg" 
                         style="width:32px;height:32px" 
                         title="{{person.name}} - {{person.uid}}">
                            <ul class="dropdown-menu" role="menu" aria-labelledby="user">
                                <li role="presentation" style="background-color:lightgrey">
                                    <a class="dropdown-item" role="menuitem" 
                          tabindex="0" style="text-decoration: none;text-align:left">
                          {{person.name}}<br/>{{person.uid}}</a></li>
                      <li role="presentation" style="cursor:pointer"><a class="dropdown-item" role="menuitem" tabindex="0"
                          ng-click="navigateToUser(person)">
                          <span class="fa fa-user"></span> Visit Profile</a></li>
                    </ul>
                </li>
                    </ul>
        </span>
    </span>
              </td>
              <td ng-dblclick="openModalActionItem(goal)">
                <div>{{goal.status}}</div>
                <div ng-repeat="ci in goal.checkitems" >
                  <span ng-click="toggleCheckItem($event, goal, ci.index)" style="cursor:pointer">
                    <span ng-show="ci.checked"><i class="fa  fa-check-square-o"></i></span>
                    <span ng-hide="ci.checked"><i class="fa  fa-square-o"></i></span>
                  &nbsp; 
                  </span>
                  {{ci.name}}
                </div>
              </td>
          </tr>
          </table>
    </span><hr>
    </div>
    
    <div class="row ms-3" ng-hide="editMeetingPart=='subscribers'">
    <div class="col-2 fixed-width-md bold labelColumn btn btn-outline-secondary" style="text-align:left" ng-click="startSubscriberEdit()">Subscribers:</div>
    <div class="col-9">
        <div class="d-flex">
          <span ng-repeat="player in noteInfo.subscribers" title="{{player.name}}">
            <span class="dropdown" >
                <ul class="nav-item list-inline m-2">
                  <li class="nav-item dropdown" id="users" data-toggle="dropdown">
                    <img src="<%=ar.retPath%>icon/{{player.key}}.jpg" 
                 style="width:32px;height:32px" 
                 title="{{player.name}} - {{player.uid}}" class="rounded-5" />
                    <ul class="dropdown-menu" role="menu" aria-labelledby="users">
                        <li role="presentation" 
                        style="background-color:lightgrey">
                        <a class="dropdown-item" role="menuitem"  tabindex="0" style="text-decoration: none;text-align:left"> {{player.name}}<br/>{{player.uid}}</a></li>
                        <li role="presentation" style="cursor:pointer"><a class="dropdown-item" role="menuitem" tabindex="0" ng-click="navigateToUser(player)">
                            <span class="fa fa-user"></span> Visit Profile</a></li>
                    </ul>
                  </li>
                </ul>
            </span>
          </span>
        </div>
        <div ng-show="nonMembers.length>0">
          <div>Warning: The following subscribers have no access to the rest of workspace:</div>
          
          <div class="d-flex" >
            <span ng-repeat="outcast in nonMembers">
                <span class="dropdown" >
                  <ul class="nav-item list-inline m-2">
                    <li class="nav-item dropdown" id="outcast" data-toggle="dropdown">
                        <img src="<%=ar.retPath%>icon/{{outcast.key}}.jpg" title="{{outcast.name}} - {{outcast.uid}}" class="rounded-5" style="width:32px;height:32px" />
                        <ul class="dropdown-menu" role="menu" aria-labelledby="outcast">
                            <li role="presentation" style="background-color:lightgrey"><a class="dropdown-item" role="menuitem"  tabindex="-1" style="text-decoration: none;text-align:left"> {{outcast.name}}<br/>{{outcast.uid}}</a></li>
                            <li role="presentation" style="cursor:pointer"><a class="dropdown-item" role="menuitem" tabindex="-1" ng-click="navigateToUser(outcast)">
                            <span class="fa fa-user"></span> Visit Profile</a></li>
                            <li role="presentation" style="float: left;cursor:pointer"><a class="dropdown-item" role="menuitem" tabindex="-1" ng-click="addMember(outcast)">
                            <span class="fa fa-user"></span> Add to Members</a></li>
                        </ul>
                    </li>
                  </ul>
                </span>
            </span>
          </div>
        </div>
    </div>
    <hr></div>

    <div class="well" ng-show="editMeetingPart=='subscribers'">
        <h3 class="h5">Adjust Subscribers:</h3>
        <div>
            <tags-input ng-model="subscriberBuffer" placeholder="Enter users to update about changes" 
                display-property="name" key-property="uid" replace-spaces-with-dashes="false" 
                add-on-space="true" add-on-comma="true" on-tag-added="updatePlayers()"  
                on-tag-removed="updatePlayers()"> 
                <auto-complete source="loadPersonList($query)" min-length="1"></auto-complete>
            </tags-input>
        </div>
        <div>
            <span class="d-grid justify-content-end">
                <button class="btn btn-primary btn-default btn-raised fs-6"  type="button"  ng-click="saveSubscriberEdit()" 
                        title="Save this list of subscribers"> Save </button>
            </span>
        </div>
        <div>
          Add Role Players: 
          <button class="btn btn-primary btn-default btn-raised fs-6"  type="button"  
                ng-repeat="role in allRoles"  ng-click="addPlayers(role)" 
                title="Add role players to subscribers"> {{role.name}} </button>
        </div>
        <div>
          Remove All Subscribers: 
          <button class="btn btn-primary btn-default btn-raised fs-6"  type="button"  
                ng-click="clearSubscribers()" 
                title="Remove all the current subscribers"> Clear All </button>
        </div>
        
        
        
    </div>

    <div class="row ms-3">
        <span class="col-2 fixed-width-md bold labelColumn btn btn-outline-secondary mt-2" style="text-align:left"
            ng-click="toggleReadOnlyPart('makeLink')">
            Get Link:</span>
        <span class="col-9">
            <p ng-hide="editMeetingPart=='makeLink'">Generate a link that works the way you want.  You can make a <b>private</b> link that will allow only the current members of this workspace to see the topic.  Or you can make a <b>public</b> link that makes the topic available to anyone in the world with the link.  Your choice.</p>
            <span  ng-show="editMeetingPart=='makeLink'">
                <div class="col-8 my-2">
                    <input type="radio" ng-model="linkScope" value="Private" ng-click="generateLink('Private')"> <b>Private</b> - topic can be accessed only by workspace members.
                </div>
                <div class="col-8 my-2">
                    <input type="radio" ng-model="linkScope" value="Public" ng-click="generateLink('Public')">
                    <b>Public</b> - topic can be accessed by anyone on the Internet.
                </div>
                <div class="col-8 my-2">
                    <input type="text" ng-model="generatedLink" id="generatedLink"/>
                    <button onClick="copyTheLink()" class="btn btn-primary btn-raised">Copy to Clipboard</button>
                </div>
            </span>

        </span>
    </div><hr/>
    
    <!--Create Comment/Proposal/Round Row-->
    <div class="d-flex col-7 mx-3">
        <button class="btn btn-comment btn-wide btn-raised px-3 mx-2 my-3" ng-click="openCommentCreator(item, 1)" >
            Create New <i class="fa fa-comments-o"></i> Comment</button>
        <button ng-click="openCommentCreator(item, 2)" class="btn btn-comment btn-wide btn-raised px-3 mx-2 my-3">
            Create New <i class="fa fa-star-o"></i> Proposal</button>
        <button ng-click="openCommentCreator(item, 3)" class="btn btn-comment btn-wide btn-raised px-3 mx-2 my-3">
            Create New <i class="fa fa-question-circle"></i> Round</button>

    </div>
</div>
            
      </div> 
      <div class="well mx-3" ng-repeat="cmt in getComments()">

            <%@ include file="/spring2/jsp/CommentView.jsp" %>
       
      </div>
    </div>
    <div ng-hide="canComment">
        <i>You have to be logged in and a member of this workspace in order to create a comment</i>
    </div>

    <div>Refreshing {{autoRefresh}} in {{secondsTillSave}} seconds, {{autoSaveCount}} refreshes</div>

  </div>
</div>


<script src="<%=ar.retPath%>new_assets/templates/ActionItemCtrl.js"></script>
<script src="<%=ar.retPath%>new_assets/templates/AttachDocumentCtrl.js"></script>
<script src="<%=ar.retPath%>new_assets/templates/AttachActionCtrl.js"></script>
<script src="<%=ar.retPath%>new_assets/templates/Feedback.js"></script>
<script src="<%=ar.retPath%>new_assets/jscript/HtmlToMarkdown.js"></script>
<script src="<%=ar.retPath%>new_assets/jscript/HtmlParser.js"></script>
<script src="<%=ar.baseURL%>new_assets/jscript/TextMerger.js"></script>

<%out.flush();%>
