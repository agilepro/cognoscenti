<%@page errorPage="/spring/jsp/error.jsp"
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
    JSONObject workspaceInfo = ngw.getConfigJSON();

    boolean isLoggedIn = ar.isLoggedIn();

    //there might be a better way to measure this that takes into account
    //magic numbers and tokens
    boolean canComment = ar.canUpdateWorkspace();

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
    int topicNumericId = DOMFace.safeConvertInt(topicId);

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
<!-- ******************************** ltd/NoteZoom.jsp ******************************** -->
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
</style>

<script type="text/javascript">
document.title="<% ar.writeJS(note.getSubject());%>";

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal, $interval, AllPeople) {
    window.setMainPageTitle("Discussion Topic");
    $scope.siteInfo = <%ngb.getConfigJSON().write(out,2,4);%>;
    $scope.workspaceInfo = <%workspaceInfo.write(out,2,4);%>;
    $scope.noteInfo = <%noteInfo.write(out,2,4);%>;
    $scope.topicId = "<%=topicId%>";
    $scope.allDocs = [];
    $scope.attachmentList = <%attachmentList.write(out,2,4);%>;
    $scope.allLabels = <%allLabels.write(out,2,4);%>;
    $scope.canComment = <%=canComment%>;
    $scope.history = <%history.write(out,2,4);%>;
    $scope.allGoals = <%allGoals.write(out,2,4);%>;
    $scope.nonMembers = [];
    $scope.addressMode = false;

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


    $scope.myComment = "";
    $scope.myCommentType = 1;   //simple comment
    $scope.myReplyTo = 0;


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
        console.log("can not start edit for topic if not member of workspace");
    }
    $scope.mergeUpdateDoc = function(changeEditing) {
        console.log("can not merge edit for topic if not member of workspace");
    }
    $scope.saveEdits = function(fields) {
        console.log("can not save edit for topic if not member of workspace");
    };
    function refreshTopic() {
        var postURL = "getTopic.json?nid="+$scope.topicId;
        console.log("GET:", postURL);
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
        $scope.wikiEditing = $scope.noteInfo.wiki;
        $scope.htmlEditing = convertMarkdownToHtml($scope.wikiEditing);
        $scope.wikiLastSave = $scope.noteInfo.wiki;
        $scope.changesToSave = false;
        $scope.changesToMerge = false;
    }

    $scope.receiveTopicRecord = function(data) {
        data.comments.forEach( function(cmt) {
            $scope.generateCommentHtml(cmt);
        });
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
        if (data.subscribers) {
            data.subscribers.forEach( function(person) {
                if (person.uid == "<%=ar.getBestUserId()%>") {
                    check = true;
                }
                person.image = AllPeople.imageName(person);
            });
        }
        $scope.fixUpChoices();
        $scope.isSubscriber = check;
        $scope.refreshHistory();
        
        //recalculate non-members
        var members = getRolePlayers("Members");
        var newNonMembers = [];
        $scope.noteInfo.subscribers.forEach( function(subber) {
            if (!members[subber.key]) {
                newNonMembers.push(subber);
            }
        });
        $scope.nonMembers = newNonMembers;
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
        console.log("can not add a member if not member of workspace");
    }
    function refreshLabels() {

        console.log("can not add refresh labels if not member of workspace");    }

    $scope.saveDocs = function() {
        console.log("can not save document if not member of workspace");
    }
    $scope.saveLabels = function() {
        console.log("can not save labels if not member of workspace");
    }

    $scope.savePartial = function(recordToSave) {
        console.log("can not save partial if not member of workspace");
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
                if (item.commentType != 6) {
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
        $scope.addressMode = true;
    }
    $scope.updatePlayers = function() {
        $scope.noteInfo.subscribers = cleanUserList($scope.noteInfo.subscribers);
    }    
    $scope.postIt = function(sendEmail) {
        //automatic sending has been defeated, but just 
        //redirect to the manual sending to prepare the messsage
        $scope.noteInfo.sendEmailNow = false;;
        $scope.setPhase("Freeform");
        $scope.addressMode = false;
        console.log("Yes, posted now, but send email is: ", sendEmail);
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
            console.log("DOCID", doc);
            alert("doc id is missing");
        }
        window.location="DocDetail.htm?aid="+doc.id;
    }
    $scope.sendDocByEmail = function(docId) {
        var doc = $scope.getFullDoc(docId);
        window.location="SendNote.htm?att="+doc.id;
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
        console.log("can not retrieve all documents for topic if not member of workspace");
    }
    $scope.refreshAttachedDocs = function() {
        console.log("can not retrieve all documents for topic if not member of workspace");
    }
    $scope.retrieveAllDocuments();
    
    

    $scope.refreshAllGoals = function() {
        console.log("can not get all goals if not member of workspace");
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
            $scope.extendBackgroundTime();
            //not sure what to do here
        }, function () {
            $scope.extendBackgroundTime();
            //cancel action - nothing really to do
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
        $scope.saveNotice = "Saved at "+new Date().toLocaleTimeString();
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
            alert("This topic has been deleted (in Trash).  Undelete it before sending by email.");
            return;
        }
        window.location = "SendNote.htm?noteId="+$scope.topicId;
    }
    $scope.navigateToUser = function(player) {
        window.location="<%=ar.retPath%>v/"+encodeURIComponent(player.key)+"/PersonShow.htm";
    }
    $scope.startSubscriberEdit = function() {
        console.log("can not edit subscriber if not member of workspace");
    }
    $scope.saveSubscriberEdit = function() {
        console.log("can not save subscriber if not member of workspace");
    }
    
    
    initializeLabelPicker($scope, $http, $modal);    
    
    //now actually get it
    refreshTopic();
});

</script>
<script src="../../../jscript/AllPeople.js"></script>

<div>

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
          <tags-input ng-model="noteInfo.subscribers" placeholder="Enter users to send notify about changes"
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
    <div>Refreshing {{autoRefresh}} in {{secondsTillSave}} seconds, {{autoSaveCount}} refreshes</div>

    <div class="leafContent" ng-hide="isEditing" ng-dblclick="startEdit()">
        <div  ng-bind-html="htmlEditing"></div>
    </div>
<%if (isLoggedIn) { %>
    <div class="leafContent" ng-show="isEditing">
        <input type="text" class="form-control" ng-model="noteInfo.subject">
        <div style="height:15px"></div>
        <div ui-tinymce="tinymceOptions" ng-model="htmlEditing"></div>
        <div style="height:15px"></div>
        <button class="btn btn-primary btn-raised" ng-click="mergeUpdateDoc(false)">Close Editor</button>
        <button ng-show="changesToMerge" class="btn btn-warning btn-raised" 
            ng-click="mergeFromOthers()">Merge Edits from other Users</button>
        <span ng-show="changesToSave">{{saveNotice}}</span>
        <span ng-hide="changesToSave">Changes will be saved in {{secondsTillSave}} seconds.</span>
    </div>
<% } %>

<table class="table">
<col style="width:150px">
<tr>
    <td>Last modified:</td><td>{{noteInfo.modTime|cdate}}</td>
</tr>
<tr>
    <td>Labels:</td>
    <td>
        
        <%@ include file="/spring/ltd/LabelPicker.jsp"%>

    </td>
</tr>
<tr>
    <td>Attachments:</td>
    <td >
        <div ng-repeat="doc in attachedDocs" style="vertical-align: top">
          <span ng-show="doc.attType=='FILE'">
              <span ng-click="navigateToDoc(doc)"><img src="<%=ar.retPath%>assets/images/iconFile.png"></span>
              &nbsp;
              <span ng-click="downloadDocument(doc)"><span class="fa fa-download"></span></span>
          </span>
          <span  ng-show="doc.attType=='URL'">
              <span ng-click="navigateToDoc(doc)"><img src="<%=ar.retPath%>assets/images/iconUrl.png"></span>
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
    </td>
</tr>

<tr>
    <td>Action Items:</td>
    <td>
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
                <div ng-repeat="person in goal.assignTo">
                  <span class="dropdown" >
                    <span id="menu1" data-toggle="dropdown">
                    <img class="img-circle" 
                         ng-src="<%=ar.retPath%>icon/{{person.key}}.jpg" 
                         style="width:32px;height:32px" 
                         title="{{person.name}} - {{person.uid}}">
                    </span>
                    <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
                      <li role="presentation" style="background-color:lightgrey"><a role="menuitem" 
                          tabindex="-1" style="text-decoration: none;text-align:center">
                          {{person.name}}<br/>{{person.uid}}</a></li>
                      <li role="presentation" style="cursor:pointer"><a role="menuitem" tabindex="-1"
                          ng-click="navigateToUser(person)">
                          <span class="fa fa-user"></span> Visit Profile</a></li>
                    </ul>
                  </span>
                </div>
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
    </td>
</tr>
<tr >
    <td >Subscribers:</td>
    <td>
        <span ng-repeat="player in noteInfo.subscribers" title="{{player.name}}"    
          style="text-align:center">
          <span class="dropdown" >
            <span id="menu1" data-toggle="dropdown">
              <img src="<%=ar.retPath%>icon/{{player.key}}.jpg" 
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


<table style="max-width:800px">
  <tr ng-repeat="cmt in getComments()">

     <%@ include file="/spring/jsp/CommentView.jsp"%>

  </tr>


    <tr><td style="height:20px;"></td></tr>

    <tr>
    <td></td>
    <td>
    <div ng-show="canComment && !isEditing">
        <div style="margin:20px;">
            <button ng-click="openCommentCreator(null,1)" class="btn btn-default btn-raised">
                Create New <i class="fa fa-comments-o"></i> Comment</button>
            <button ng-click="openCommentCreator(null,2)" class="btn btn-default btn-raised">
                Create New <i class="fa fa-star-o"></i> Proposal</button>
            <button ng-click="openCommentCreator(null,3)" class="btn btn-default btn-raised">
                Create New <i class="fa  fa-question-circle"></i> Round</button>
        </div>
    </div>
    <div ng-hide="canComment">
        <i>You have to be logged in and a member of this workspace in order to create a comment</i>
    </div>
    </td>
    </tr>

</table>


</div>


<script src="<%=ar.retPath%>templates/ActionItemCtrl.js"></script>
<script src="<%=ar.retPath%>templates/AttachDocumentCtrl.js"></script>
<script src="<%=ar.retPath%>templates/AttachActionCtrl.js"></script>
<script src="<%=ar.retPath%>templates/Feedback.js"></script>
<script src="<%=ar.retPath%>jscript/HtmlToMarkdown.js"></script>
<script src="<%=ar.retPath%>jscript/HtmlParser.js"></script>
<script src="<%=ar.baseURL%>jscript/TextMerger.js"></script>

<%out.flush();%>
