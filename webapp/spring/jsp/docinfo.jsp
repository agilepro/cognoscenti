<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="java.net.URLDecoder"
%><%@page import="org.socialbiz.cog.AttachmentVersion"
%><%@page import="org.socialbiz.cog.LicenseForUser"
%><%@page import="org.socialbiz.cog.AccessControl"
%><%/*
Required parameters:

    1. pageId : This is the id of a workspace and here it is used to retrieve NGWorkspace (Workspace's Details).
    2. aid : This is document/attachment id which is used to get information of the attachment being downloaded.

*/

    //set 'forceTemplateRefresh' in config file to 'true' to get this
    String templateCacheDefeater = "";
    if ("true".equals(ar.getSystemProperty("forceTemplateRefresh"))) {
        templateCacheDefeater = "?t="+System.currentTimeMillis();
    }

    String pageId = ar.reqParam("pageId");
    String siteId = ar.reqParam("siteId");
    NGWorkspace ngp = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngp);
    NGBook site = ngp.getSite();
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
        permaLink = attachment.getURLValue();
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
    for (TopicRecord note : attachment.getLinkedTopics(ngp)) {
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

    JSONArray attachmentList = ngp.getJSONAttachments(ar);
    String docSpaceURL = "";
    if (uProf!=null) {
        LicenseForUser lfu = new LicenseForUser(ar.getUserProfile());
        docSpaceURL = ar.baseURL +  "api/" + site.getKey() + "/" + ngp.getKey()
                    + "/summary.json?lic="+lfu.getId();
    }

    JSONArray allLabels = ngp.getJSONLabels();
    
%>

<script type="text/javascript">
document.title="<% ar.writeJS(attachment.getDisplayName());%>";

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal) {
    window.setMainPageTitle("Access Document");
    $scope.siteInfo = <%site.getConfigJSON().write(out,2,4);%>;
    $scope.docInfo = <%docInfo.write(out,2,4);%>;
    $scope.linkedMeetings = <%linkedMeetings.write(out,2,4);%>;
    $scope.linkedTopics = <%linkedTopics.write(out,2,4);%>;
    $scope.linkedGoals = <%linkedGoals.write(out,2,4);%>;
    $scope.attachmentList = <%attachmentList.write(out,2,4);%>;
    $scope.allLabels = <%allLabels.write(out,2,4);%>;

    $scope.myComment = "";
    $scope.canUpdate = <%=canAccessDoc%>;

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };
    $scope.docSpaceURL = "<%ar.writeJS(docSpaceURL);%>";

    $scope.refreshData = function(cmt) {
        var saveRecord = {};
        saveRecord.id = $scope.docInfo.id;
        saveRecord.universalid = $scope.docInfo.universalid;
        $scope.savePartial(saveRecord);
    }
    $scope.updateComment = function(cmt) {
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

    $scope.allowCommentEmail = function() {
        return true;
    }

    $scope.openCommentCreator = function(itemNotUsed, type, replyTo, defaultBody) {
        var newComment = {};
        newComment.time = -1;
        newComment.commentType = type;
        newComment.containerType = "A";
        newComment.containerID = $scope.docInfo.id;
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
        $scope.openCommentEditor(itemNotUsed, newComment);
    }

    $scope.openCommentEditor = function (itemNotUsed, cmt) {

        var modalInstance = $modal.open({
            animation: false,
            templateUrl: '<%=ar.retPath%>templates/CommentModal.html<%=templateCacheDefeater%>',
            controller: 'CommentModalCtrl',
            size: 'lg',
            backdrop: "static",
            resolve: {
                cmt: function () {
                    return JSON.parse(JSON.stringify(cmt));
                },
                attachmentList: function() {
                    return $scope.attachmentList;
                },
                docSpaceURL: function() {
                    return $scope.docSpaceURL;
                },
                parentScope: function() { return $scope; },
                siteId: function () {
                  return $scope.siteInfo.key;
                }
            }
        });

        modalInstance.result.then(function (returnedCmt) {
            $scope.refreshData();
        }, function () {
            //cancel action - nothing really to do
            $scope.refreshData();
        });
    };
    
    
    
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
        if (cmt.state==11) {
            return "comment-state-draft";
        }
        if (cmt.state==12) {
            return "comment-state-active";
        }
        return "comment-state-complete";
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
    $scope.needsUserResponse = function(cmt) {
        if (cmt.state!=12) { //not open
            return false;
        }
        var whatNot = $scope.getResponse(cmt);
        return (whatNot.length == 0);
    }
    $scope.getResponse = function(cmt) {
        var selected = cmt.responses.filter( function(item) {
            return item.user=="<%ar.writeJS(currentUser);%>";
        });
        return selected;
    }
    $scope.findComment = function(itemNotUsed, timestamp) {
        var selected = {};
        $scope.docInfo.comments.map( function(cmt) {
            if (timestamp==cmt.time) {
                selected = cmt;
            }
        });
        return selected;
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

    $scope.assignedLabels = function() {
        var res = [];
        $scope.allLabels.forEach( function(item) {
            if ($scope.docInfo.labelMap[item.name]) {
                res.push(item);
            }
        });
        return res;
    }

});
</script>
<script src="../../../jscript/AllPeople.js"></script>

<style>
.spacey {
    width:100%;
}
.spacey tr td {
    padding:5px;
}
.firstcol {
    width:180px;
}
</style>


<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

<% if (ar.isLoggedIn()) { %>
    <div class="upRightOptions rightDivContent">
      <span class="dropdown">
        <button class="btn btn-default btn-raised dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
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
              href="SendNote.htm?att={{docInfo.id}}">Send Document by Email</a></li>
        </ul>
      </span>
    </div>
<% } %>    

<hr/>
    <div style="clear:both"></div>


    <table  class="spacey">
        <tr>
            <td class="firstcol">
                <span ng-show="'FILE'==docInfo.attType">Document Name:</span>
                <span ng-show="'URL'==docInfo.attType">Link Name:</span>
            </td>
            <td><b>{{docInfo.name}}</b>
                <span ng-show="docInfo.deleted" style="color:red">
                    <i class="fa fa-trash"></i> (DELETED)
                </span>
            </td>
        </tr>
        <tr>
            <td class="firstcol">Description:</td>
            <td>
            <%ar.writeHtml(attachment.getDescription());%>
            <span ng-repeat="role in assignedLabels()">
                <button class="labelButton" 
                    type="button" id="menu2"
                    style="background-color:{{role.color}};">
                    {{role.name}}</button>
                </ul>
            </span>
            </td>
        </tr>
        <tr>
            <td class="firstcol">
            <%if("FILE".equals(attachment.getType())){ %> Uploaded by: <%}else if("URL".equals(attachment.getType())){ %>
            Attached by <%} %>
            </td>
            <td>
            <% ale.writeLink(ar); %> on <% SectionUtil.nicePrintTime(ar, attachment.getModifiedDate(), ar.nowTime); %>
            </td>
        </tr>
        <tr>
            <td class="firstcol">Accessibility:</td>
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
            <td class="firstcol">Version:</td>
            <td><%=attachment.getVersion()%>
             - Size: <%=fileSize%> bytes</td>
        </tr>
        <tr>
            <td class="firstcol">Maintained by:</td>
            <td><% ar.writeHtml(editUser); %></td>
        </tr>
<%}%>
        <tr>
            <td class="firstcol">Linked Action Items:</td>
            <td><span ng-repeat="act in linkedGoals" class="btn btn-sm btn-default btn-raised"  style="margin:4px;"
                   ng-click="navigateToActionItem(act)">
                   <img ng-src="<%=ar.retPath%>assets/goalstate/small{{act.state}}.gif">  {{act.synopsis}}
                </span>
            </td>
        </tr>
        <tr>
            <td class="firstcol">Linked Topics:</td>
            <td><span ng-repeat="topic in linkedTopics" class="btn btn-sm btn-default btn-raised"  style="margin:4px;"
                   ng-click="navigateToTopic(topic)">
                   <i class="fa fa-lightbulb-o" style="font-size:130%"></i> {{topic.subject}}
                </span>
            </td>
        </tr>
        <tr>
            <td class="firstcol">Linked Meetings:</td>
            <td><span ng-repeat="meet in linkedMeetings" class="btn btn-sm btn-default btn-raised"  style="margin:4px;"
                   ng-click="navigateToMeeting(meet)">
                   <i class="fa fa-gavel" style="font-size:130%"></i> {{meet.name}}
                </span>
            </td>
        </tr>
    </table>
    <table class="spacey">
        <tr>
            <td class="firstcol"></td>
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
            <a href="CleanAtt.htm?path=<% ar.writeURLData(permaLink); %>" target="_blank">
                <button class="btn btn-primary btn-raised">View Text Only</button></a>
            <%} %>

            </td>
        </tr>
<%  }
    else{
%>
        <tr>
            <td class="firstcol"></td>
            <td><a href="#"><img
                src="<%=ar.retPath%>downloadInactive.gif" border="0"></a><br />
            <span class="red">* You need to log in to access this
            document.</span></td>
        </tr>
<%
    }
%>
</table>


<table >
  <tr ng-repeat="cmt in docInfo.comments">
     <%@ include file="/spring/jsp/CommentView.jsp"%>
  </tr>
</table>


  <div ng-show="canUpdate">
    <div ng-hide="isCreatingComment" style="margin:20px;">
      <button ng-click="openCommentCreator(null, 1)" class="btn btn-default btn-raised">
        Create New <i class="fa fa-comments-o"></i> Comment</button>
    </div>
  </div>
  <div ng-hide="canUpdate">
    <i>You have to be logged in and a member of this workspace in order to create a comment</i>
  </div>

  <div>
    <span class="tipText">This web page is a secure and
      convenient way to send documents to others collaborating on projects.
      The email message does not carry the document, but only a link to this
      page, so that email is small. Then, from this page, you can get the
      very latest version of the document. Documents can be protected by
      access controls.
    </span>
  </div>

</div>

<script src="<%=ar.retPath%>templates/CommentModal.js"></script>
<script src="<%=ar.retPath%>templates/ResponseModal.js"></script>
<script src="<%=ar.retPath%>templates/OutcomeModal.js"></script>
<script src="<%=ar.retPath%>templates/DecisionModal.js"></script>
<script src="<%=ar.retPath%>templates/AttachDocumentCtrl.js"></script>

