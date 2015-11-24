<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="org.socialbiz.cog.AccessControl"
%><%@page import="org.socialbiz.cog.LeafletResponseRecord"
%><%@page import="org.socialbiz.cog.MicroProfileMgr"
%><%/*
Required parameter:

    1. pageId : This is the id of a Workspace and used to retrieve NGPage.
    2. lid    : This is id of note (NoteRecord).

*/

    String pageId      = ar.reqParam("pageId");
    NGPage ngp = ar.getCogInstance().getProjectByKeyOrFail(pageId);
    ar.setPageAccessLevels(ngp);

    boolean isLoggedIn = ar.isLoggedIn();

    //there might be a better way to measure this that takes into account
    //magic numbers and tokens
    boolean canUpdate = ar.isMember();

    NGBook ngb = ngp.getSite();
    UserProfile uProf = ar.getUserProfile();
    String currentUser = "NOBODY";
    String currentUserName = "NOBODY";
    if (uProf!=null) {
        //this page can be viewed when not logged in, possibly with special permissions.
        //so you can't assume that uProf is non-null
        currentUser = uProf.getUniversalId();
        currentUserName = uProf.getName();
    }

    String lid = ar.reqParam("lid");
    NoteRecord note = ngp.getNoteOrFail(lid);

    boolean canAccessNote  = AccessControl.canAccessNote(ar, ngp, note);
    if (!canAccessNote) {
        throw new Exception("Program Logic Error: this view should only display when user can actually access the note.");
    }

    JSONObject noteInfo = note.getJSONWithComments(ar);
    JSONArray attachmentList = ngp.getJSONAttachments(ar);
    JSONArray allLabels = ngp.getJSONLabels();

    JSONArray history = new JSONArray();
    for (HistoryRecord hist : note.getNoteHistory(ngp)) {
        history.put(hist.getJSON(ngp, ar));
    }

%>

<!-- something in here is needed for the html bind -->
<link href="<%=ar.retPath%>jscript/textAngular.css" rel="stylesheet" />
<script src="<%=ar.retPath%>jscript/textAngular-rangy.min.js"></script>
<script src="<%=ar.retPath%>jscript/textAngular-sanitize.min.js"></script>
<script src="<%=ar.retPath%>jscript/textAngular.min.js"></script>

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

var app = angular.module('myApp', ['ui.bootstrap', 'textAngular']);
app.controller('myCtrl', function($scope, $http, $modal) {
    $scope.noteInfo = <%noteInfo.write(out,2,4);%>;
    $scope.attachmentList = <%attachmentList.write(out,2,4);%>;
    $scope.allLabels = <%allLabels.write(out,2,4);%>;
    $scope.canUpdate = <%=canUpdate%>;
    $scope.history = <%history.write(out,2,4);%>

    $scope.isEditing = false;

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };

    $scope.fixUpChoices = function() {
        $scope.noteInfo.comments.map( function(cmt) {
            if (!cmt.choices || cmt.choices.length==0) {
                cmt.choices = ["Consent", "Object"];
            }
        });
    }
    $scope.fixUpChoices();

//which editor is open
    $scope.editCmt = "NOTHING";



    $scope.myComment = "";
    $scope.myPoll = false;
    $scope.myReplyTo = 0;

    $scope.saveEdits = function(fields) {
        var postURL = "noteHtmlUpdate.json?nid="+$scope.noteInfo.id;
        var rec = {};
        rec.id = $scope.noteInfo.id
        rec.universalid = $scope.noteInfo.universalid;
        fields.map( function(fieldName) {
            rec[fieldName] = $scope.noteInfo[fieldName];
        });
        var postdata = angular.toJson(rec);
        $scope.showError=false;
        $http.post(postURL ,postdata)
        .success( function(data) {
            $scope.noteInfo = data;
            $scope.refreshHistory();
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };

    $scope.createComment = function() {
        var saveRecord = {};
        saveRecord.id = $scope.noteInfo.id;
        saveRecord.universalid = $scope.noteInfo.universalid;
        saveRecord.newComment = {};
        saveRecord.newComment.html = $scope.myComment;
        saveRecord.newComment.poll = $scope.myPoll;
        if ($scope.myReplyTo>0) {
            saveRecord.newComment.replyTo = $scope.myReplyTo;
        }
        $scope.savePartial(saveRecord);
        $scope.editCmt='NOTHING';
    }
    $scope.updateComment = function(cmt) {
        var saveRecord = {};
        saveRecord.id = $scope.noteInfo.id;
        saveRecord.universalid = $scope.noteInfo.universalid;
        saveRecord.comments = [];
        saveRecord.comments.push(cmt);
        $scope.savePartial(saveRecord);
        $scope.editCmt='NOTHING';
    }
    $scope.saveDocs = function() {
        var saveRecord = {};
        saveRecord.id = $scope.noteInfo.id;
        saveRecord.universalid = $scope.noteInfo.universalid;
        saveRecord.docList = $scope.noteInfo.docList;
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

    $scope.getDocs = function() {
        var res = [];
        $scope.noteInfo.docList.map( function(docId) {
            $scope.attachmentList.map( function(oneDoc) {
                if (oneDoc.universalid == docId) {
                    res.push(oneDoc);
                }
            });
        });
        return res;
    }
    $scope.filterDocs = function(filter) {
        var res = [];
        for(var i=0; i<$scope.attachmentList.length; i++) {
            var oneDoc = $scope.attachmentList[i];
            if (oneDoc.name.indexOf(filter)>=0) {
                res.push(oneDoc);
            }
            else if (oneDoc.description.indexOf(filter)>=0) {
                res.push(oneDoc);
            }
        }
        return res;
    }
    $scope.addAttachment = function(doc) {
        for (var i=0; i<$scope.noteInfo.docList.length; i++) {
            if (doc.universalid == $scope.noteInfo.docList[i]) {
                alert("Document already attached: "+doc.name);
                return;
            }
        }
        $scope.noteInfo.docList.push(doc.universalid);
        $scope.saveDocs();
        $scope.newAttachment = "";
    }
    $scope.removeAttachment = function(doc) {
        var newVal = [];
        $scope.noteInfo.docList.map( function(docId) {
            if (docId!=doc.universalid) {
                newVal.push(docId);
            }
        });
        $scope.noteInfo.docList = newVal;
        $scope.saveDocs();
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

    $scope.startEdit = function(cmt) {
        $scope.editCmt  = cmt.time;
    }

    $scope.stopEdit = function() {
        $scope.editCmt  = 'NOTHING';
    }

    $scope.createModifiedProposal = function(cmt) {
        $scope.editCmt  = 'NEW';
        $scope.myComment = cmt.html;
        $scope.myReplyTo = cmt.time;
        $scope.myPoll = true;
    }
    $scope.replyToComment = function(cmt) {
        $scope.editCmt  = 'NEW';
        $scope.myReplyTo = cmt.time;
        $scope.myPoll = false;
        //$anchorScroll("#CommentEditor");
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
        if (cmt.poll) {
            return "Proposal";
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
    }


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

        var modalInstance = $modal.open({
            animation: false,
            templateUrl: '<%=ar.retPath%>templates/DecisionModal.html',
            controller: 'ModalInstanceCtrl',
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

        modalInstance.result.then(function (modifiedDecision) {
            $scope.createDecision(modifiedDecision);
        }, function () {
            //cancel action - nothing really to do
        });
    };
});

</script>
<script src="<%=ar.retPath%>templates/DecisionModal.js"></script>
<script src="<%=ar.retPath%>templates/ResponseModal.js"></script>

<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

    <div class="generalHeading" style="height:40px">
        <div  style="float:left;margin-top:8px;">
            {{noteInfo.subject}}
        </div>
        <div class="rightDivContent" style="margin-right:100px;">
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

        </div>
    </div>

    <div class="leafContent" ng-hide="isEditing">
      <div ng-bind-html="noteInfo.html"></div>
      <div><br/><i>Last modified by <a href="findUser.htm?uid={{noteInfo.modUser.uid}}"><span class="red">{{noteInfo.modUser.name}}</span></a> on {{noteInfo.modTime|date}}</i></div>
    </div>
    <div class="well leafContent" ng-show="isEditing">
      <div ng-model="noteInfo.html"
          ta-toolbar="[['h1','h2','h3','p','ul','indent','outdent'],['bold','italics','clear','insertLink'],['undo','redo']]"
          text-angular="" class="leafContent"></div>

      <button ng-click="saveEdits(['html']);isEditing=false" class="btn btn-danger">Save</button>
      <button ng-click="saveEdits([]);isEditing=false" class="btn btn-danger">Cancel</button>
    </div>


    <div class="generalHeading" style="margin-top:50px;"></div>

    <div>
          Labels:
          <span class="dropdown" ng-repeat="role in allLabels">
            <button class="btn btn-sm dropdown-toggle labelButton" type="button" id="menu2"
               data-toggle="dropdown" style="background-color:{{role.color}};"
               ng-show="hasLabel(role.name)">{{role.name}}</button>
            <ul class="dropdown-menu" role="menu" aria-labelledby="menu2">
               <li role="presentation"><a role="menuitem" title="{{add}}"
                  ng-click="toggleLabel(role)">Remove Role:<br/>{{role.name}}</a></li>
            </ul>
          </span>
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
    </div>


    <div style="width:100%">
      <div>
          <div class="dropdown" ng-repeat="doc in getDocs()">
            <a href="docinfo{{doc.id}}.htm">
                <img src="<%=ar.retPath%>assets/images/iconFile.png" ng-show="'FILE'==doc.attType">
                <img src="<%=ar.retPath%>assets/images/iconUrl.png" ng-show="'URL'==doc.attType">
                {{doc.name}}</a>
          </div>
      </div>
    </div>
    <div>
      Attachments:
      <span class="dropdown" ng-repeat="doc in getDocs()">
        <button class="btn dropdown-toggle" type="button" id="menu1"
          data-toggle="dropdown" style="margin:2px;padding: 2px 5px;font-size: 11px;">
        {{doc.name}}</button>
        <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
          <li role="presentation"><a role="menuitem" tabindex="-1"
              ng-click="removeAttachment(doc)">Remove Document:<br/>{{doc.name}}</a></li>
        </ul>
      </span>
      <span ng-show="getDocs().length==0 && canUpdate"><i>no documents attached</i></span>
      <button class="btn dropdown-toggle btn-primary" ng-click="showAdd=!showAdd"
          style="margin:2px;padding: 2px 5px;font-size: 11px;" title="Attach a document">
          + </button>
    </div>
    <div ng-show="showAdd">

        <div class="form-inline form-group" style="padding-top:10px;">

            <button ng-click="addAttachment(newAttachment);showAdd=false" class="btn btn-primary">Add Document</button>
            <input type="text" ng-model="newAttachment"  class="form-control" placeholder="Enter Document Name"
             style="width:350px;" typeahead="att as att.name for att in filterDocs($viewValue) | limitTo:12">
        </div>

    </div>


    <div style="height:30px;"></div>

    <style>
    .comment-outer-box {
        border: 1px solid lightgrey;
        border-radius:8px;
        padding:5px;
        margin-top:15px;
        background-color:#EEE
    }
    .comment-inner-box {
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
               <div class="comment-outer-box">
                   <div>
                     <div>

                         <div class="dropdown" style="float:left">
<% if (isLoggedIn) { %>
                           <button class="btn btn-default dropdown-toggle" type="button" id="menu1" data-toggle="dropdown" style="margin-right:10px;">
                           <span class="caret"></span></button>
                           <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
                              <li role="presentation" ng-show="editCmt=='NOTHING' && cmt.user=='<%ar.writeJS(currentUser);%>'">
                                  <a role="menuitem" ng-click="startEdit(cmt)">Edit Your {{commentTypeName(cmt)}}</a></li>
                              <li role="presentation" ng-show="cmt.poll && editCmt=='NOTHING'">
                                  <a role="menuitem" ng-click="startResponse(cmt)">Create/Edit Response:</a></li>
                              <li role="presentation" ng-show="cmt.poll && editCmt=='NOTHING'">
                                  <a role="menuitem" ng-click="createModifiedProposal(cmt)">Make Modified Proposal</a></li>
                              <li role="presentation" ng-show="cmt.poll && editCmt=='NOTHING' && cmt.user=='<%ar.writeJS(currentUser);%>'">
                                  <a role="menuitem" ng-click="cmt.poll=false;updateComment(cmt)">Close Response Period</a></li>
                              <li role="presentation" ng-show="!cmt.poll && editCmt=='NOTHING'">
                                  <a role="menuitem" ng-click="replyToComment(cmt)">Reply</a></li>
                              <li role="presentation" ng-show="cmt.poll && !cmt.decision && editCmt=='NOTHING'">
                                  <a role="menuitem" ng-click="openDecisionEditor(cmt)">Create New Decision</a></li>
                           </ul>
<% } %>
                         </div>
                         <span ng-hide="cmt.poll"><i class="fa fa-comments-o"></i></span>
                         <span ng-show="cmt.poll"><i class="fa fa-star-o"></i></span>
                         &nbsp; {{cmt.time | date}} - <a href="<%=ar.retPath%>v/{{cmt.userKey}}/userSettings.htm"><span class="red">{{cmt.userName}}</span></a>
                         <span ng-hide="cmt.emailSent">-email pending-</span>
                         <span ng-show="cmt.replyTo">
                             <span ng-hide="cmt.poll">In reply to
                                 <a style="border-color:white;" href="#cmt{{cmt.replyTo}}">
                                 <i class="fa fa-comments-o"></i> {{findComment(cmt.replyTo).userName}}</a></span>
                             <span ng-show="cmt.poll">Based on
                                 <a style="border-color:white;" href="#cmt{{cmt.replyTo}}">
                                 <i class="fa fa-star-o"></i> {{findComment(cmt.replyTo).userName}}</a></span>
                         </span>
                         <div style="clear:both"></div>
                      </div>
                   </div>
                   <div class="leafContent comment-inner-box" ng-hide="editCmt==cmt.time">
                       <div ng-bind-html="cmt.html"></div>
                   </div>

<% if (isLoggedIn) { %>
                    <div class="well leafContent" style="width:100%" ng-show="editCmt==cmt.time">
                      <div ng-model="cmt.html"
                          ta-toolbar="[['h1','h2','h3','p','ul','indent','outdent'],['bold','italics','clear','insertLink'],['undo','redo']]"
                          text-angular="" class="" style="width:100%;"></div>

                      <button ng-click="updateComment(cmt);stopEdit()" class="btn btn-danger">Save Changes</button>
                      <button ng-click="stopEdit()" class="btn btn-danger">Cancel</button>
                      &nbsp;
                      <input type="checkbox" ng-model="cmt.poll"> Proposal</button>
                    </div>
<% } %>

                   <table style="min-width:500px;" ng-show="cmt.poll">
                       <col style="width:100px">
                       <col width="width:1*">
                       <tr ng-repeat="resp in cmt.responses">
                           <td style="padding:5px">
                               <b>{{resp.choice}}</b><br/>
                               {{resp.userName}}
                           </td>
                           <td >
                               <div class="comment-inner-box leafContent">
                                  <div ng-bind-html="resp.html"></div>
                               </div>
                           </td>
                       </tr>
                   </table>
                   <div ng-show="cmt.decision">
                       See Linked Decision: <a href="decisionList.htm#DEC{{cmt.decision}}">#{{cmt.decision}}</a>
                   </div>
                   <div ng-show="cmt.replies.length>0 && cmt.poll">
                       See proposals:
                       <span ng-repeat="reply in cmt.replies"><a href="#cmt{{reply}}" >
                           <i class="fa fa-star-o"></i> {{findComment(reply).userName}}</a> </span>
                   </div>
                   <div ng-show="cmt.replies.length>0 && !cmt.poll">
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
        <div ng-show="editCmt=='NOTHING'" style="margin:20px;">
            <button ng-click="myPoll=false;editCmt='NEW'" class="btn btn-default">
                Create New <i class="fa fa-comments-o"></i> Comment</button>
            <button ng-click="myPoll=true;editCmt='NEW'" class="btn btn-default">
                Create New <i class="fa fa-star-o"></i> Proposal</button>
        </div>
        <div class="well leafContent" style="width:100%" ng-show="editCmt=='NEW'" id="CommentEditor">
          <div ng-model="myComment"
              ta-toolbar="[['h1','h2','h3','p','ul','indent','outdent'],['bold','italics','clear','insertLink'],['undo','redo']]"
              text-angular="" class="" style="width:100%;"></div>

          <button ng-click="createComment()" class="btn btn-danger" ng-hide="myPoll">
              Create <i class="fa fa-comments-o"></i> Comment</button>
          <button ng-click="createComment()" class="btn btn-danger" ng-show="myPoll">
              Create <i class="fa fa-star-o"></i> Proposal</button>
          <button ng-click="myComment='';myPoll=false;editCmt='NOTHING'" class="btn btn-danger">Cancel</button>
          &nbsp;
          <input type="checkbox" ng-model="myPoll"> Proposal</button>
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
<%out.flush();%>
