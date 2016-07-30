<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="java.net.URLDecoder"
%><%@page import="org.socialbiz.cog.AttachmentVersion"
%><%@page import="org.socialbiz.cog.AccessControl"
%><%/*
Required parameters:

    1. pageId : This is the id of a workspace and here it is used to retrieve NGPage (Workspace's Details).
    2. aid : This is document/attachment id which is used to get information of the attachment being downloaded.

*/

    String pageId      = ar.reqParam("pageId");
    NGWorkspace ngp = ar.getCogInstance().getProjectByKeyOrFail(pageId);
    ar.setPageAccessLevels(ngp);
    NGBook ngb = ngp.getSite();
    UserProfile uProf = ar.getUserProfile();
    String currentUser = "";
    String currentUserName = "";
    String currentUserKey = "";
    if (uProf!=null) {
        currentUser = uProf.getUniversalId();
        currentUserName = uProf.getName();
        currentUserKey = uProf.getKey();
    }


    String aid      = ar.reqParam("aid");
    AttachmentRecord attachment = ngp.findAttachmentByIDOrFail(aid);
    String version  = ar.defParam("version", null);

    JSONObject docInfo = attachment.getJSON4Doc(ar, ngp);

    long fileSizeInt = attachment.getFileSize(ngp);
    String fileSize = String.format("%,d", fileSizeInt);

    boolean canAccessDoc = AccessControl.canAccessDoc(ar, ngp, attachment);


    String access = "Member Only";
    if (attachment.isPublic()) {
        access = "Public";
    }

    String accessName = attachment.getNiceName();
    String relativeLink = "a/"+accessName+"?version="+attachment.getVersion();
    String permaLink = ar.getResourceURL(ngp, relativeLink);
    if("URL".equals(attachment.getType())){
        permaLink = attachment.getStorageFileName();
    }

//TODO: this terminology is 'getEditModeUser' is really about 'maintainers' of a document.
//should be reworked
    String editUser = attachment.getEditModeUser();

    AddressListEntry ale = new AddressListEntry(attachment.getModifiedBy());

    JSONArray linkedMeetings = new JSONArray();
    for (MeetingRecord meet : attachment.getLinkedMeetings(ngp)) {
        linkedMeetings.put(meet.getListableJSON(ar));
    }
    JSONArray linkedTopics = new JSONArray();
    for (NoteRecord note : attachment.getLinkedTopics(ngp)) {
        linkedTopics.put(note.getJSON(ngp));
    }

    JSONArray linkedGoals = new JSONArray();
    for (GoalRecord goal : ngp.getAllGoals()) {
        boolean found = false;
        for (String otherId : goal.getDocLinks()) {
            if (otherId.equals(attachment.getUniversalId())) {
                found = true;
            }
        }
        if (found) {
            linkedGoals.put(goal.getJSON4Goal(ngp));
        }
    }

%>

<link href="<%=ar.retPath%>assets/font-awesome/css/font-awesome.min.css" rel="stylesheet" />

<script type="text/javascript">
document.title="<% ar.writeJS(attachment.getDisplayName());%>";

var app = angular.module('myApp', ['ui.bootstrap','ui.tinymce', 'ngSanitize']);
app.controller('myCtrl', function($scope, $http, $modal) {
    $scope.docInfo = <%docInfo.write(out,2,4);%>;
    $scope.linkedMeetings = <%linkedMeetings.write(out,2,4);%>;
    $scope.linkedTopics = <%linkedTopics.write(out,2,4);%>;
    $scope.linkedGoals = <%linkedGoals.write(out,2,4);%>;

    $scope.myComment = "";
    $scope.canUpdate = <%=canAccessDoc%>;

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };

    $scope.saveComment = function(cmt) {
        var saveRecord = {};
        saveRecord.id = $scope.docInfo.id;
        saveRecord.universalid = $scope.docInfo.universalid;
        saveRecord.comments = [];
        saveRecord.comments.push(cmt);
        $scope.isCreatingComment = false;
        $scope.savePartial(saveRecord);
    }
    $scope.savePartial = function(recordToSave) {
        var postURL = "docsUpdate.json?did="+recordToSave.id;
        var postdata = angular.toJson(recordToSave);
        $scope.showError=false;
        $http.post(postURL ,postdata)
        .success( function(data) {
            $scope.docInfo = data;
            $scope.myComment = "";
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };
    $scope.navigateToActionItem = function(act) {
        window.location="task"+act.id+".htm";
    }
    $scope.navigateToTopic = function(topic) {
        window.location="noteZoom"+topic.id+".htm";
    }
    $scope.navigateToMeeting = function(meet) {
        window.location="meetingFull.htm?id="+meet.id;
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

    $scope.openCommentCreator = function(type, replyTo, defaultBody) {
        var newComment = {};
        newComment.time = -1;
        newComment.commentType = type;
        newComment.state = 11;
        newComment.isNew = true;
        newComment.dueDate = (new Date()).getTime() + (7*24*60*60*1000);
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
                },
                parentScope: function () {
                    return $scope;
                }
            }
        });

        modalInstance.result.then(function (returnedCmt) {
            var cleanCmt = {};
            cleanCmt.time = cmt.time;
            cleanCmt.html = returnedCmt.html;
            cleanCmt.state = returnedCmt.state;
            cleanCmt.commentType = returnedCmt.commentType;
            if (cleanCmt.state==12) {
                if (cleanCmt.commentType==1 || cleanCmt.commentType==5) {
                    cleanCmt.state=13;
                }
            }
            cleanCmt.replyTo = returnedCmt.replyTo;
            $scope.saveComment(cleanCmt);
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
            Access Document
        </div>
        <div class="rightDivContent" style="margin-right:100px;">
          <span class="dropdown">
            <button class="btn btn-default dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
            Options: <span class="caret"></span></button>
            <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
              <li role="presentation"><a role="menuitem"
                  href="docinfo{{docInfo.id}}.htm">Access Document</a></li>
              <li role="presentation"><a role="menuitem" tabindex="-1"
                  href="docsRevise.htm?aid={{docInfo.id}}" >Upload New Version</a></li>
              <li role="presentation"><a role="menuitem"
                  href="editDetails{{docInfo.id}}.htm">Edit Details</a></li>
              <li role="presentation"><a role="menuitem" tabindex="-1"
                  href="fileVersions.htm?aid={{docInfo.id}}">List Versions</a></li>
              <li role="presentation"><a role="menuitem"
                  href="sendNote.htm?att={{docInfo.id}}">Send Document by Email</a></li>
            </ul>
          </span>

        </div>
    </div>



    <table border="0px solid red" width="800">
        <tr>
            <td colspan="3">
                <table>
                    <tr>
                        <td class="gridTableColummHeader">
                            <span ng-show="'FILE'==docInfo.attType">Document Name:</span>
                            <span ng-show="'URL'==docInfo.attType">Link Name:</span>
                        </td>
                        <td style="width: 20px;"></td>
                        <td><b>{{docInfo.name}}</b>
                            <span ng-show="docInfo.deleted">
                                <img src="<%=ar.retPath%>deletedLink.gif"> <font color="red">(DELETED)</font>
                            </span>
                        </td>
                    </tr>
                    <tr>
                        <td style="height: 5px"></td>
                    </tr>
                    <tr>
                        <td class="gridTableColummHeader">Description:</td>
                        <td style="width: 20px;"></td>
                        <td>
                        <%ar.writeHtml(attachment.getDescription());%>
                        </td>
                    </tr>
                    <tr>
                        <td style="height: 5px"></td>
                    </tr>
                    <tr>
                        <td class="gridTableColummHeader">
                        <%if("FILE".equals(attachment.getType())){ %> Uploaded by: <%}else if("URL".equals(attachment.getType())){ %>
                        Attached by <%} %>
                        </td>
                        <td style="width: 20px;"></td>
                        <td>
                        <% ale.writeLink(ar); %> on <% SectionUtil.nicePrintTime(ar, attachment.getModifiedDate(), ar.nowTime); %>
                        </td>
                    </tr>
                    <tr>
                        <td style="height: 5px"></td>
                    </tr>
                    <tr>
                        <td class="gridTableColummHeader">Accessibility:</td>
                        <td style="width: 20px;"></td>
                        <%if(!attachment.getReadOnlyType().equals("on")){ %>
                        <td>
                        <% ar.writeHtml(access);%>
                        </td>
                        <%}else{ %>
                        <td>
                        <% ar.writeHtml(access);%> and Read only Type</td>
                        <%} %>
                    </tr>
<%if("FILE".equals(attachment.getType())){ %>
                    <tr>
                        <td style="height: 5px"></td>
                    </tr>
                    <tr>
                        <td class="gridTableColummHeader">Version:</td>
                        <td style="width: 20px;"></td>
                        <td><%=attachment.getVersion()%>
                         - Size: <%=fileSize%> bytes</td>
                    </tr>
                    <tr>
                        <td style="height: 5px"></td>
                    </tr>
                    <tr>
                        <td class="gridTableColummHeader">Maintained by:</td>
                        <td style="width: 20px;"></td>
                        <td><% ar.writeHtml(editUser); %></td>
                    </tr>
<%}%>
                    <tr>
                        <td class="gridTableColummHeader">Linked Action Items:</td>
                        <td style="width: 20px;"></td>
                        <td><span ng-repeat="act in linkedGoals" class="btn btn-sm btn-default"  style="margin:4px;"
                               ng-click="navigateToActionItem(act)">
                               <img src="<%=ar.retPath%>assets/goalstate/small{{act.state}}.gif">  {{act.synopsis}}
                            </span>
                        </td>
                    </tr>
                    <tr>
                        <td class="gridTableColummHeader">Linked Topics:</td>
                        <td style="width: 20px;"></td>
                        <td><span ng-repeat="topic in linkedTopics" class="btn btn-sm btn-default"  style="margin:4px;"
                               ng-click="navigateToTopic(topic)">
                               <i class="fa fa-lightbulb-o" style="font-size:130%"></i> {{topic.subject}}
                            </span>
                        </td>
                    </tr>
                    <tr>
                        <td class="gridTableColummHeader">Linked Meetings:</td>
                        <td style="width: 20px;"></td>
                        <td><span ng-repeat="meet in linkedMeetings" class="btn btn-sm btn-default"  style="margin:4px;"
                               ng-click="navigateToMeeting(meet)">
                               <i class="fa fa-gavel" style="font-size:130%"></i> {{meet.name}}
                            </span>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
        <tr>
            <td style="height: 10px"></td>
        </tr>
        <tr>
            <td class="gridTableColummHeader"></td>
            <td style="width: 20px;"></td>
<%
if (attachment.isPublic() || (ar.isLoggedIn() || canAccessDoc)) {
%>
            <td>
            <%if("FILE".equals(attachment.getType())){ %> 
                <a href="<%=ar.retPath%><%ar.writeHtml(permaLink); %>"><img
                src="<%=ar.retPath%>download.gif"></a> 
            <%}else if("URL".equals(attachment.getType())){ %>
            <a href="<%ar.write(permaLink); %>" target="_blank"><img
                src="<%=ar.retPath%>assets/btnAccessLinkURL.gif"></a> 
            <%} %>

            </td>
        </tr>
<%  }
    else{
%>
        <tr>
            <td class="gridTableColummHeader"></td>
            <td style="width: 20px;"></td>
            <td><a href="#"><img
                src="<%=ar.retPath%>downloadInactive.gif" border="0"></a><br />
            <span class="red">* You need to log in to access this
            document.</span></td>
        </tr>
<%
    }
%>

        <tr>
            <td></td>
            <td style="width: 20px;"></td>
            <td>

                <div ng-repeat="cmt in docInfo.comments">
                   <div style="border: 1px solid lightgrey;border-radius:8px;padding:5px;margin-top:15px;background-color:#EEE">
                       <div class="dropdown" style="float:left">
                           <button class="dropdown-toggle specCaretBtn" type="button"  d="menu" 
                               data-toggle="dropdown"> <span class="caret"></span> </button>
                           <ul class="dropdown-menu" role="menu" aria-labelledby="menu">
                              <li role="presentation" ng-show="cmt.user=='<%ar.writeJS(currentUser);%>'">
                                  <a role="menuitem" ng-click="openCommentEditor(cmt)">Edit Your {{commentTypeName(cmt)}}</a></li>
                              <li role="presentation" ng-show="cmt.commentType==1">
                                  <a role="menuitem" ng-click="openCommentCreator(item,1,cmt.time)">Reply</a></li>
                              <li role="presentation" ng-show="cmt.commentType==2 || cmt.commentType==3">
                                  <a role="menuitem" ng-click="openCommentCreator(item,2,cmt.time,cmt.html)">Make Modified Proposal</a></li>
                              <li role="presentation" ng-show="cmt.commentType==2">
                                  <a role="menuitem" ng-click="openDecisionEditor(item, cmt)">Create New Decision</a></li>
                           </ul>
                       </div>
                       <div style="">
                           <i class="fa fa-comments-o"></i> Comment {{cmt.time | date}} - <a href="#"><span class="red">{{cmt.userName}}</span></a>
                       </div>
                       <div class="leafContent" ng-click="openCommentEditor(cmt)" style="border: 1px solid lightgrey;border-radius:6px;padding:5px;background-color:white">
                         <div ng-bind-html="cmt.html"></div>
                       </div>
                   </div>
                </div>

                <div style="height:20px;"></div>


                <div ng-show="canUpdate">
                    <div ng-hide="isCreatingComment" style="margin:20px;">
                        <button ng-click="openCommentCreator(1)" class="btn btn-default">
                            Create New <i class="fa fa-comments-o"></i> Comment</button>
                    </div>
                </div>
                <div ng-hide="canUpdate">
                    <i>You have to be logged in and a member of this workspace in order to create a comment</i>
                </div>

            </td>
        </tr>

        <tr>
            <td style="height: 10px"></td>
        </tr>
        <tr>
            <td class="gridTableColummHeader"></td>
            <td style="width: 20px;"></td>
            <td><span class="tipText">This web page is a secure and
            convenient way to send documents to others collaborating on projects.
            The email message does not carry the document, but only a link to this
            page, so that email is small. Then, from this page, you can get the
            very latest version of the document. Documents can be protected by
            access controls.</span></td>
        </tr>

    </table>

</div>

<script src="<%=ar.retPath%>templates/CommentModal.js"></script>
