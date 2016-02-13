<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="org.socialbiz.cog.AccessControl"
%><%@page import="org.socialbiz.cog.LeafletResponseRecord"
%><%@page import="org.socialbiz.cog.LicenseForUser"
%><%@page import="org.socialbiz.cog.MicroProfileMgr"
%><%/*
Required parameter:

    1. pageId : This is the id of a Workspace and used to retrieve NGPage.
    2. lid    : This is id of note (NoteRecord).

*/

    String pageId      = ar.reqParam("pageId");
    NGWorkspace ngp = ar.getCogInstance().getProjectByKeyOrFail(pageId);
    ar.setPageAccessLevels(ngp);

    boolean isLoggedIn = ar.isLoggedIn();

    //there might be a better way to measure this that takes into account
    //magic numbers and tokens
    boolean canUpdate = ar.isMember();

    NGBook ngb = ngp.getSite();
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

    String lid = ar.reqParam("lid");
    NoteRecord note = ngp.getNoteOrFail(lid);

    boolean canAccessNote  = AccessControl.canAccessNote(ar, ngp, note);
    if (!canAccessNote) {
        throw new Exception("Program Logic Error: this view should only display when user can actually access the note.");
    }

    JSONObject noteInfo = note.getJSONWithComments(ar);
	JSONArray comments = noteInfo.getJSONArray("comments");
    JSONArray attachmentList = ngp.getJSONAttachments(ar);
    JSONArray allLabels = ngp.getJSONLabels();

    JSONArray history = new JSONArray();
    for (HistoryRecord hist : note.getNoteHistory(ngp)) {
        history.put(hist.getJSON(ngp, ar));
    }

    JSONArray allGoals     = ngp.getJSONGoals();
    JSONArray allPeople = UserManager.getUniqueUsersJSON();

    String docSpaceURL = "";
    if (uProf!=null) {
        LicenseForUser lfu = new LicenseForUser(ar.getUserProfile());
        docSpaceURL = ar.baseURL +  "api/" + ngb.getKey() + "/" + ngp.getKey()
                    + "/summary.json?lic="+lfu.getId();
    }

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
</style>

<script type="text/javascript">
document.title="<% ar.writeJS(note.getSubject());%>";

var app = angular.module('myApp', ['ui.bootstrap', 'ui.tinymce', 'ngSanitize']);
app.controller('myCtrl', function($scope, $http, $modal) {
    $scope.noteInfo = <%noteInfo.write(out,2,4);%>;
    $scope.attachmentList = <%attachmentList.write(out,2,4);%>;
    $scope.allLabels = <%allLabels.write(out,2,4);%>;
    $scope.canUpdate = <%=canUpdate%>;
    $scope.history = <%history.write(out,2,4);%>
    $scope.allGoals = <%allGoals.write(out,2,4);%>
    $scope.allPeople = <%allPeople.write(out,2,4);%>;
    
    $scope.tinymceOptions = standardTinyMCEOptions();
    $scope.tinymceOptions.height = 400;
 
    $scope.currentTime = (new Date()).getTime();
    $scope.docSpaceURL = "<%ar.writeJS(docSpaceURL);%>";

    $scope.isEditing = false;

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
                cmt.choices = ["Consent", "Object"];
            }
        });
    }
    $scope.fixUpChoices();


    $scope.myComment = "";
    $scope.myCommentType = 1;   //simple comment
    $scope.myReplyTo = 0;

    $scope.saveEdit = function() {
        $scope.saveEdits(['html','subject']);
        $scope.isEditing = false;
    }
    $scope.cancelEdit = function() {
        $scope.isEditing = false;
    }
    $scope.saveEdits = function(fields) {
        var postURL = "noteHtmlUpdate.json?nid="+$scope.noteInfo.id;
        var rec = {};
        rec.id = $scope.noteInfo.id
        rec.universalid = $scope.noteInfo.universalid;
        fields.forEach( function(fieldName) {
            rec[fieldName] = $scope.noteInfo[fieldName];
            console.log("SAVING: "+fieldName);
        });
        var postdata = angular.toJson(rec);
        $scope.showError=false;
        $http.post(postURL ,postdata)
        .success( function(data) {
            $scope.noteInfo = data;
            console.log("GOT NOTE SAVED", data);
            $scope.refreshHistory();
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };

    $scope.postComment = function(cmt) {
        cmt.state = 12;
        if (cmt.commentType == 1) {
            //simple comments go all the way to closed
            cmt.state = 13;
        }
        $scope.updateComment(cmt);
    }
    $scope.deleteComment = function(cmt) {
        cmt.deleteMe = true;
        $scope.updateComment(cmt);
    }
    $scope.closeComment = function(cmt) {
        cmt.state = 13;
        if (cmt.commentType>1) {
            $scope.openOutcomeEditor(cmt);
        }
        else {
            $scope.updateComment(cmt);
        }
    }
    $scope.reopenComment = function(cmt) {
        cmt.state = 12;
        $scope.updateComment(cmt);
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
        var postURL = "updateNote.json?nid="+$scope.noteInfo.id;
        var postdata = angular.toJson(recordToSave);
        console.log(postdata);
        $scope.showError=false;
        $http.post(postURL ,postdata)
        .success( function(data) {
            $scope.noteInfo = data;
            $scope.fixUpChoices();
            $scope.myComment = "";
            $scope.refreshHistory();
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };

    $scope.itemHasDoc = function(doc) {
        var res = false;
        var found = $scope.noteInfo.docList.forEach( function(docid) {
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
    $scope.navigateToDoc = function(doc) {
        window.location="docinfo"+doc.id+".htm";
    }
    $scope.navigateToMeeting = function(meet) {
        window.location="meetingFull.htm?id="+meet.id;
    }
    $scope.navigateToAction = function(oneAct) {
        window.location="task"+oneAct.id+".htm";
    }

    $scope.getResponse = function(cmt) {
        var selected = [];
        cmt.responses.map( function(item) {
            if (item.user=="<%ar.writeJS(currentUser);%>") {
                selected.push(item);
            }
        });
        return selected;
    }
    $scope.needsUserResponse = function(cmt) {
        if (cmt.state!=12) { //not open
            return false;
        }
        var whatNot = $scope.getResponse(cmt);
        return (whatNot.length == 0);
    }
    $scope.updateResponse = function(cmt, response) {
        var selected = [];
        cmt.responses.map( function(item) {
            if (item.user!="<%ar.writeJS(currentUser);%>") {
                selected.push(item);
            }
        });
        selected.push(response);
        cmt.responses = selected;
        $scope.updateComment(cmt);
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
    $scope.findComment = function(timestamp) {
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
    $scope.calcDueDisplay = function(cmt) {
        if (cmt.commentType==1 || cmt.commentType==4) {
            return "";
        }
        if (cmt.state==13) {
            return "";
        }
        var diff = Math.trunc((cmt.dueDate-$scope.currentTime) / 60000);
        if (diff<0) {
            return "overdue";
        }
        if (diff<120) {
            return "due in "+diff+" minutes";
        }
        diff = Math.trunc(diff / 60);
        if (diff<48) {
            return "due in "+diff+" hours";
        }
        diff = Math.trunc(diff / 24);
        if (diff<8) {
            return "due in "+diff+" days";
        }
        diff = Math.trunc(diff / 7);
        return "due in "+diff+" weeks";
    }

    $scope.createModifiedProposal = function(cmt) {
        $scope.openCommentCreator(2,cmt.time,cmt.html);  //proposal
    }
    $scope.replyToComment = function(cmt) {
        $scope.openCommentCreator(1,cmt.time);  //simple comment
    }
    $scope.openCommentCreator = function(type, replyTo, defaultBody) {
        var newComment = {};
        newComment.time = -1;
        newComment.commentType = type;
        newComment.state = 11;
        newComment.isNew = true;
        newComment.user = "<%ar.writeJS(currentUser);%>";
        newComment.userName = "<%ar.writeJS(currentUserName);%>";
        newComment.userKey = "<%ar.writeJS(currentUserKey);%>";
        if (replyTo) {
            newComment.replyTo = replyTo;
        }
        if (defaultBody) {
            newComment.html = defaultBody;
        }
        $scope.openCommentEditor(newComment);
    }


    $scope.openCommentEditor = function (cmt) {

        var modalInstance = $modal.open({
            animation: false,
            templateUrl: '<%=ar.retPath%>templates/CommentModal.html?t=<%=System.currentTimeMillis()%>',
            controller: 'CommentModalCtrl',
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
            cleanCmt.html = returnedCmt.html;
            cleanCmt.state = returnedCmt.state;
            cleanCmt.replyTo = returnedCmt.replyTo;
            cleanCmt.commentType = returnedCmt.commentType;
            $scope.updateComment(cleanCmt);
        }, function () {
            //cancel action - nothing really to do
        });
    };

    $scope.openResponseEditor = function (cmt) {

        var selected = $scope.getResponse(cmt);
        var selResponse = {};
        if (selected.length == 0) {
            selResponse.user = "<%ar.writeJS(currentUser);%>";
            selResponse.userName = "<%ar.writeJS(currentUserName);%>";
            selResponse.choice = cmt.choices[0];
            selResponse.isNew = true;
        }
        else {
            selResponse = JSON.parse(JSON.stringify(selected[0]));
        }

        var modalInstance = $modal.open({
            animation: false,
            templateUrl: '<%=ar.retPath%>templates/ResponseModal.html',
            controller: 'ModalResponseCtrl',
            size: 'lg',
            backdrop: "static",
            resolve: {
                response: function () {
                    return selResponse;
                },
                cmt: function () {
                    return cmt;
                }
            }
        });

        modalInstance.result.then(function (response) {
            var cleanResponse = {};
            cleanResponse.html = response.html;
            cleanResponse.user = response.user;
            cleanResponse.userName = response.userName;
            cleanResponse.choice = response.choice;
            $scope.updateResponse(cmt, cleanResponse);
        }, function () {
            //cancel action - nothing really to do
        });
    };


    $scope.openOutcomeEditor = function (cmt) {

        var modalInstance = $modal.open({
            animation: false,
            templateUrl: '<%=ar.retPath%>templates/OutcomeModal.html',
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
            cleanCmt.state = returnedCmt.state;
            cleanCmt.commentType = returnedCmt.commentType;
            $scope.updateComment(cleanCmt);
        }, function () {
            //cancel action - nothing really to do
        });
    };


    $scope.createDecision = function(newDecision) {
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

    $scope.openDecisionEditor = function (cmt) {

        var newDecision = {
            html: cmt.html,
            labelMap: $scope.noteInfo.labelMap,
            sourceId: $scope.noteInfo.id,
            sourceType: 4,
            sourceCmt: cmt.time
        };

        var decisionModalInstance = $modal.open({
            animation: false,
            templateUrl: '<%=ar.retPath%>templates/DecisionModal.html',
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

    $scope.openAttachDocument = function () {

        var attachModalInstance = $modal.open({
            animation: true,
            templateUrl: '<%=ar.retPath%>templates/AttachDocument.html?t=<%=System.currentTimeMillis()%>',
            controller: 'AttachDocumentCtrl',
            size: 'lg',
            resolve: {
                docList: function () {
                    return JSON.parse(JSON.stringify($scope.noteInfo.docList));
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
            $scope.noteInfo.docList = docList;
            $scope.saveEdits(['docList']);
        }, function () {
            //cancel action - nothing really to do
        });
    };

    $scope.openAttachAction = function (item) {

        var attachModalInstance = $modal.open({
            animation: true,
            templateUrl: '<%=ar.retPath%>templates/AttachAction.html?t=<%=System.currentTimeMillis()%>',
            controller: 'AttachActionCtrl',
            size: 'lg',
            resolve: {
                selectedActions: function () {
                    return $scope.noteInfo.actionList;
                },
                allActions: function() {
                    return $scope.allGoals;
                },
                allPeople: function() {
                    return $scope.allPeople;
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

});

</script>

<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

    <div class="generalHeading" style="height:40px">
        <div  style="float:left;margin-top:8px;">
            <i class="fa fa-lightbulb-o" style="font-size:130%"></i>
            {{noteInfo.subject}}
        </div>
        <div class="rightDivContent" style="margin-right:100px;">
<%if (isLoggedIn) { %>
          <span class="dropdown">
            <button class="btn btn-default dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
            Options: <span class="caret"></span></button>
            <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
              <li role="presentation"><a role="menuitem" tabindex="-1"
                  href="notesList.htm">List Topics</a></li>
              <li role="presentation"><a role="menuitem" tabindex="-1"
                  ng-click="isEditing = !isEditing" target="_blank">Edit This Topic</a></li>
              <li role="presentation"><a role="menuitem" tabindex="-1"
                  href="pdf/note{{noteInfo.id}}.pdf?publicNotes={{noteInfo.id}}">Generate PDF</a></li>
              <li role="presentation"><a role="menuitem" tabindex="-1"
                  href="sendNote.htm?noteId={{noteInfo.id}}">Send Topic By Email</a></li>
            </ul>
          </span>
<% } %>
        </div>
    </div>

    <div class="leafContent" ng-hide="isEditing">
    	<div  ng-bind-html="noteInfo.html"></div>
    </div>
<%if (isLoggedIn) { %>
    <div class="leafContent" ng-show="isEditing">
        <input type="text" class="form-control" ng-model="noteInfo.subject">
        <div style="height:15px"></div>
    	<div ui-tinymce="tinymceOptions" ng-model="noteInfo.html"></div>
        <div style="height:15px"></div>
        <button class="btn btn-primary" ng-click="saveEdit()">Save</button>
        <button class="btn btn-primary" ng-click="cancelEdit()">Cancel</button>
    </div>
<% } %>

    
    <div class="generalHeading" style="margin-top:50px;"></div>

    <div>
          <span style="width:150px">Labels:</span>
          <span class="dropdown" ng-repeat="role in allLabels">
            <button class="btn btn-sm dropdown-toggle labelButton" type="button" id="menu2"
               data-toggle="dropdown" style="background-color:{{role.color}};"
               ng-show="hasLabel(role.name)">{{role.name}}</button>
            <ul class="dropdown-menu" role="menu" aria-labelledby="menu2">
               <li role="presentation"><a role="menuitem" title="{{add}}"
                  ng-click="toggleLabel(role)">Remove Label:<br/>{{role.name}}</a></li>
            </ul>
          </span>
<%if (isLoggedIn) { %>
          <span>
             <span class="dropdown">
               <button class="btn btn-sm btn-primary dropdown-toggle" type="button" id="menu1" data-toggle="dropdown"
               style="padding: 2px 5px;font-size: 11px;"> + </button>
               <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
                 <li role="presentation" ng-repeat="rolex in allLabels">
                     <button role="menuitem" tabindex="-1" href="#"  ng-click="toggleLabel(rolex)" class="btn btn-sm labelButton"
                     ng-hide="hasLabel(rolex.name)" style="background-color:{{rolex.color}};">
                         {{rolex.name}}</button></li>
               </ul>
             </span>
          </span>
<% } %>
    </div>


    <div style="width:100%">
    <div>
      <span style="width:150px">Attachments:</span>
      <span ng-repeat="doc in getDocs()" class="btn btn-sm btn-default"  style="margin:4px;"
           ng-click="navigateToDoc(doc)">
              <img src="<%=ar.retPath%>assets/images/iconFile.png"> {{doc.name}}
      </span>
<%if (isLoggedIn) { %>
      <button class="btn btn-sm btn-primary" ng-click="openAttachDocument()"
          title="Attach a document">
          ADD </button>
<% } %>
    </div>

    <div>
      <span style="width:150px">Action Items:</span>
      <span ng-repeat="act in getActions()" class="btn btn-sm btn-default"  style="margin:4px;"
           ng-click="navigateToAction(act)">
             <img src="<%=ar.retPath%>assets/goalstate/small{{act.state}}.gif"> {{act.synopsis}}
      </span>
<%if (isLoggedIn) { %>
      <button class="btn btn-sm btn-primary" ng-click="openAttachAction()"
          title="Attach an Action Item">
          ADD </button>
<% } %>
    </div>


    <div style="height:30px;"></div>

    <style>
    .comment-outer {
        border: 1px solid lightgrey;
        border-radius:8px;
        padding:5px;
        margin-top:15px;
        background-color:#EEE
    }
    .comment-inner {
        border: 1px solid lightgrey;
        border-radius:6px;
        padding:5px;
        background-color:white;
        margin:2px
    }

    </style>

      <table>

      <tr ng-repeat="cmt in getComments()">
           <td style="width:50px;max-width:50px;vertical-align:top;padding:5px;padding-top:15px">
               <img id="cmt{{cmt.time}}" class="img-circle" style="height:35px;width:35px;" src="<%=ar.retPath%>/users/{{cmt.userKey}}.jpg">
           </td>
           <td>
               <div class="comment-outer" style="{{stateStyle(cmt)}}">
                   <div>
                     <div>

                         <div class="dropdown" style="float:left">
<% if (isLoggedIn) { %>
                            <button class="dropdown-toggle specCaretBtn" type="button"  id="menu1" 
                                data-toggle="dropdown"> <span class="caret"></span> </button>
                           <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
                              <li role="presentation" ng-show="cmt.user=='<%ar.writeJS(currentUser);%>' && (cmt.state<13 || cmt.commentType==1)">
                                  <a role="menuitem" ng-click="openCommentEditor(cmt)">Edit Your {{commentTypeName(cmt)}}</a></li>
                              <li role="presentation" ng-show="cmt.user=='<%ar.writeJS(currentUser);%>' && cmt.state==13 && cmt.commentType>1">
                                  <a role="menuitem" ng-click="reopenComment(cmt)">Reopen Your {{commentTypeName(cmt)}}</a></li>
                              <li role="presentation" ng-show="cmt.state==11 && cmt.user=='<%ar.writeJS(currentUser);%>'">
                                  <a role="menuitem" ng-click="postComment(cmt)">Post Your {{commentTypeName(cmt)}}</a></li>
                              <li role="presentation" ng-show="cmt.state==11 && cmt.user=='<%ar.writeJS(currentUser);%>'">
                                  <a role="menuitem" ng-click="deleteComment(cmt)">Delete Your {{commentTypeName(cmt)}}</a></li>
                              <li role="presentation" ng-show="cmt.state==12 && cmt.user=='<%ar.writeJS(currentUser);%>'">
                                  <a role="menuitem" ng-click="closeComment(cmt)">Close Your {{commentTypeName(cmt)}}</a></li>
                              <li role="presentation" ng-show="cmt.user=='<%ar.writeJS(currentUser);%>' && cmt.state==13 && cmt.commentType>1">
                                  <a role="menuitem" ng-click="openOutcomeEditor(cmt)">Edit the Final Outcome</a></li>
                              <li role="presentation" ng-show="cmt.commentType>1 && cmt.state==12">
                                  <a role="menuitem" ng-click="startResponse(cmt)">Create/Edit Response:</a></li>
                              <li role="presentation" ng-show="cmt.commentType==2">
                                  <a role="menuitem" ng-click="createModifiedProposal(cmt)">Make Modified Proposal</a></li>
                              <li role="presentation" ng-show="cmt.commentType==1">
                                  <a role="menuitem" ng-click="replyToComment(cmt)">Reply</a></li>
                              <li role="presentation" ng-show="cmt.commentType==2 && !cmt.decision">
                                  <a role="menuitem" ng-click="openDecisionEditor(cmt)">Create New Decision</a></li>
                           </ul>
<% } %>
                         </div>
                         <span ng-show="cmt.commentType==1"><i class="fa fa-comments-o" style="font-size:130%"></i></span>
                         <span ng-show="cmt.commentType==2"><i class="fa fa-star-o" style="font-size:130%"></i></span>
                         <span ng-show="cmt.commentType==3"><i class="fa fa-question-circle" style="font-size:130%"></i></span>
                         <span ng-show="cmt.commentType==4"><i class="fa fa-gavel" style="font-size:130%"></i></span>
                         &nbsp; {{cmt.time | date}} - 
                         <a href="<%=ar.retPath%>v/{{cmt.userKey}}/userSettings.htm">
                             <span class="red">{{cmt.userName}}</span>
                         </a>
                         <span ng-hide="cmt.emailSent">-email pending-</span>
                         <span ng-show="cmt.replyTo">
                             <span ng-hide="cmt.commentType>1">In reply to
                                 <a style="border-color:white;" href="#cmt{{cmt.replyTo}}">
                                 <i class="fa fa-comments-o"></i> {{findComment(cmt.replyTo).userName}}</a></span>
                             <span ng-show="cmt.commentType>1">Based on
                                 <a style="border-color:white;" href="#cmt{{cmt.replyTo}}">
                                 <i class="fa fa-star-o"></i> {{findComment(cmt.replyTo).userName}}</a></span>
                         </span>
                         <span style="float:right;color:green;">{{calcDueDisplay(cmt)}}</span>
                         <div style="clear:both"></div>
                      </div>
                   </div>
                   <div ng-show="cmt.state==11">
                       Draft {{commentTypeName(cmt)}} needs posting to be seen by others
                   </div>
                   <div class="leafContent comment-inner" ng-hide="cmt.meet">
                       <div ng-bind-html="cmt.html"></div>
                   </div>
                   <div ng-show="cmt.meet" class="btn btn-sm btn-default"  style="margin:4px;"
                       ng-click="navigateToMeeting(cmt.meet)">
                        <i class="fa fa-gavel" style="font-size:130%"></i> {{cmt.meet.name}} @ {{cmt.meet.startTime | date}}
                   </div>

                   <table style="min-width:500px;" ng-show="cmt.commentType>1">
                       <col style="width:100px">
                       <col width="width:1*">
                       <tr ng-repeat="resp in cmt.responses">
                           <td style="padding:5px;max-width:100px;">
                               <div ng-show="cmt.commentType==12"><b>{{resp.choice}}</b></div>
                               <div>{{resp.userName}}</div>
                           </td>
                           <td>
                             <span ng-show="resp.user=='<%ar.writeJS(currentUser);%>' && cmt.state==12"
                                   ng-click="startResponse(cmt)"
                                   style="cursor:pointer;">
                               <a href="#cmt{{cmt.time}}" title="Edit your response to this proposal">
                                   <i class="fa fa-edit" style="font-size:140%"></i>
                               </a>
                             </span>
                           </td>
                           <td >
                               <div class="comment-inner leafContent">
                                  <div ng-bind-html="resp.html"></div>
                               </div>
                           </td>
                       </tr>
                       <tr ng-show="needsUserResponse(cmt)">
                           <td style="padding:5px;max-width:100px;">
                               <div ng-show="cmt.commentType==12"><b>????</b></div>
                               <div><% ar.writeHtml(currentUserName); %></div>
                           </td>
                           <td>
                             <span ng-click="startResponse(cmt)" style="cursor:pointer;">
                               <a href="#cmt{{cmt.time}}" title="Create a response to this proposal">
                                 <i class="fa fa-edit" style="font-size:140%"></i>
                               </a>
                             </span>
                           </td>
                           <td >
                              <div class="comment-inner leafContent">
                                  <i>Click edit button to register a response.</i>
                              </div>
                           </td>
                       </tr>
                   </table>
                   <div class="leafContent comment-inner" ng-show="cmt.state==13 && cmt.commentType>1">
                       <div ng-bind-html="cmt.outcome"></div>
                   </div>
                   <div ng-show="cmt.decision">
                       See Linked Decision: <a href="decisionList.htm#DEC{{cmt.decision}}">#{{cmt.decision}}</a>
                   </div>
                   <div ng-show="cmt.replies.length>0 && cmt.commentType>1">
                       See proposals:
                       <span ng-repeat="reply in cmt.replies"><a href="#cmt{{reply}}" >
                           <i class="fa fa-star-o"></i> {{findComment(reply).userName}}</a> </span>
                   </div>
                   <div ng-show="cmt.replies.length>0 && cmt.commentType==1">
                       See replies:
                       <span ng-repeat="reply in cmt.replies"><a href="#cmt{{reply}}" >
                           <i class="fa fa-comments-o"></i> {{findComment(reply).userName}}</a> </span>
                   </div>


               </div>
           </td>
       </tr>


    <tr><td style="height:20px;"></td></tr>

    <tr>
    <td></td>
    <td>
    <div ng-show="canUpdate">
        <div style="margin:20px;">
            <button ng-click="openCommentCreator(1)" class="btn btn-default">
                Create New <i class="fa fa-comments-o"></i> Comment</button>
            <button ng-click="openCommentCreator(2)" class="btn btn-default">
                Create New <i class="fa fa-star-o"></i> Proposal</button>
            <button ng-click="openCommentCreator(3)" class="btn btn-default">
                Create New <i class="fa  fa-question-circle"></i> Round</button>
        </div>
    </div>
    <div ng-hide="canUpdate">
        <i>You have to be logged in and a member of this workspace in order to create a comment</i>
    </div>
    </td>
    </tr>

</table>


    <div class="generalHeading">History</div>
        <table >
            <tr><td style="height:10px"></td></tr>
            <tr ng-repeat="rec in history">
                    <td class="projectStreamIcons"  style="padding:10px;">
                        <img class="img-circle" src="<%=ar.retPath%>users/{{rec.responsible.image}}" alt="" width="50" height="50" /></td>
                    <td colspan="2"  class="projectStreamText"  style="padding:10px;max-width:600px;">
                        {{rec.time|date}} -
                        <a href="<%=ar.retPath%>v/{{rec.responsible.key}}/userSettings.htm" title="access the profile of this user, if one exists">
                            <span class="red">{{rec.responsible.name}}</span>
                        </a>
                        <br/>
                        {{rec.ctxType}} -
                        <a href="">{{rec.ctxName}}</a> was {{rec.event}} - {{rec.comment}}
                        <br/>

                    </td>
            </tr>
        </table>
    </div>

</div>

<script src="<%=ar.retPath%>templates/DecisionModal.js"></script>
<script src="<%=ar.retPath%>templates/ResponseModal.js"></script>
<script src="<%=ar.retPath%>templates/AttachDocumentCtrl.js"></script>
<script src="<%=ar.retPath%>templates/CommentModal.js"></script>
<script src="<%=ar.retPath%>templates/OutcomeModal.js"></script>
<script src="<%=ar.retPath%>templates/AttachActionCtrl.js"></script>

<%out.flush();%>
