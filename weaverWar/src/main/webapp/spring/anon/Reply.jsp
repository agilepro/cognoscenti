<%@page errorPage="/spring/jsp/error.jsp"
%><%@page import="com.purplehillsbooks.weaver.SharePortRecord"
%><%@page import="com.purplehillsbooks.weaver.AccessControl"
%><%@page import="com.purplehillsbooks.weaver.CommentContainer"
%><%@page import="com.purplehillsbooks.weaver.AgendaItem"
%><%@page import="com.purplehillsbooks.weaver.CommentRecord"
%><%@page import="com.purplehillsbooks.weaver.EmailContext"
%><%@page import="com.purplehillsbooks.weaver.mail.MailInst"
%><%@ include file="/include.jsp"
%><%
/*
Required parameters:

    1. pageId   : This is the id of a workspace and here it is used to retrieve NGWorkspace.

*/

    String pageId    = ar.reqParam("pageId");
    String siteId    = ar.reqParam("siteId");
    NGWorkspace ngw  = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngw);
    
    
    long msgId     = ar.reqParamLong("msgId");
    MailInst mail = EmailSender.findEmailById(ngw, msgId);
    String commentContainerKey = mail.getCommentContainer();
    CommentContainer cc = ngw.findContainerByKey(commentContainerKey);
    
    
    String topicId   = "";
    String meetId    = "";
    String agendaId  = "";
    String commentId = ar.defParam("commentId", null);
    String emailId   = ar.defParam("emailId", null);
    String docId     = "";
    
    String linkedEmailId = emailId;
    if (ar.isLoggedIn()) {
        emailId = ar.getBestUserId();
    }

    EmailContext emailContext = null;
    String specialAccess = "";
    String originalTopic = "";
    String agendaItem = "";
    String meetingTitle = "";
    String topicSubject = "";
    JSONArray comments = new JSONArray();
    JSONArray subscribers = new JSONArray();
    JSONArray attachments = new JSONArray();
    String originalSubject = "";

    if (cc instanceof AgendaItem) {
        AgendaItem ai = (AgendaItem) cc;
        MeetingRecord meet = ai.meeting;
        agendaId = ai.getId();
        meetId = meet.getId();
        emailContext = new EmailContext(meet, ai);
        meetingTitle = meet.getName();
        agendaItem = ai.getSubject();
        originalTopic = ai.getDesc();
        originalSubject = "Agenda: " + ai.getSubject();
        JSONObject meetInfo = meet.getFullJSON(ar, ngw, false);
        subscribers = meetInfo.getJSONArray("participants");
    }
    else if (cc instanceof TopicRecord) {
        TopicRecord topic = (TopicRecord) cc;
        topicId = topic.getId();
        topicSubject = topic.getSubject();
        JSONObject topicInfo = topic.getJSONWithComments(ar, ngw);
        originalTopic = topicInfo.getString("wiki");
        subscribers = topicInfo.getJSONArray("subscribers");
        specialAccess = AccessControl.getAccessTopicParams(ngw, topic);
        emailContext = new EmailContext(topic);
        originalSubject = "Topic: " + topic.getSubject();
        
        for (AttachmentRecord att : topic.getAttachedDocsIncludeComments(ngw)) {
             attachments.put(att.getMinJSON(ngw));
        }
    } 
    else if (cc instanceof AttachmentRecord) {
        AttachmentRecord att = (AttachmentRecord)cc;
        docId = att.getId();
        originalTopic = "!!!"+att.getNiceName()+"\n\n"+att.getDescription();
        originalSubject = "Document: " + att.getNiceName();
        emailContext = new EmailContext(att);
        attachments.put(att.getMinJSON(ngw));
    }
    else {
        throw new Exception("can not recognize this email type");
    }
    String goToUrl = ar.baseURL + emailContext.getEmailURL(ar, ngw);
    for (CommentRecord comm : emailContext.getPeerComments()) {
        comments.put(comm.getJSONWithDocs(ngw));
    }


%>

<!-- ************************ anon/Reply.jsp ************************ -->
<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal) {
    setUpLearningMethods($scope, $modal, $http);
    window.setMainPageTitle("<%ar.writeJS(originalSubject);%>");
    $scope.topicId = "<%ar.writeJS(topicId);%>";
    $scope.meetId = "<%ar.writeJS(meetId);%>";
    $scope.agendaId = "<%ar.writeJS(agendaId);%>";
    
    $scope.focusId = <%=commentId%>;
    $scope.focusComment = {};
    $scope.otherComments = [];
    $scope.comments = <%comments.write(out,2,4);%>;
    $scope.newComment = {html:"",state:11};
    $scope.newComment.time = new Date().getTime();
    $scope.commentTypeName = "Comment";
    $scope.responseTypeName = "Answer";
    
    $scope.linkedEmailId = "<%ar.writeJS(linkedEmailId);%>";
    
    $scope.tinymceOptions = standardTinyMCEOptions();
    $scope.tinymceOptions.height = 250;
    $scope.isLoggedIn = <%=ar.isLoggedIn()%>;
    
    function reportError(data) {
        console.log("FAILURE: ", data);
        alert("Unable to update server");
    }
    
    
    <% if (ar.isLoggedIn()) {%>
    $scope.loggedUserIds = <%ar.getUserProfile().getFullJSON().getJSONArray("ids").write(out,2,4);%>;
    $scope.emailId = "<%ar.writeJS(emailId);%>";
    $scope.userName = "<%ar.writeJS(ar.getUserProfile().getName());%>";
    localStorage.setItem('userEmail', $scope.emailId);
    localStorage.setItem('userName', $scope.userName);
    <% } else {%>
    $scope.loggedUserIds = [];
    $scope.emailId = localStorage.getItem('userEmail');
    $scope.userName = localStorage.getItem('userName');
    <% } %>
    $scope.sentAlready = false;
    $scope.userCounts = {};
    $scope.isSubscriber = true;
    $scope.specialAccess = "<%ar.writeJS(specialAccess);%>";
    $scope.subscribers = <%subscribers.write(out,2,4);%>;
    $scope.originalWiki = "<%ar.writeJS(originalTopic);%>";
    $scope.originalSubject = "<%ar.writeJS(originalSubject);%>";
    $scope.meetingTitle = "<%ar.writeJS(meetingTitle);%>";
    $scope.topicSubject = "<%ar.writeJS(topicSubject);%>";
    $scope.agendaItem = "<%ar.writeJS(agendaItem);%>";
    $scope.attachments = <%attachments.write(out,2,4);%>;
    
 
    $scope.distributeComments = function() {
        if (!$scope.emailId) {
            $scope.emailId = "";
        }
        if (!$scope.userName) {
            $scope.userName = "";
        }
        var newCounts = {};
        var allOthers = [];
        console.log("COMMENTS", $scope.comments);
        $scope.comments.forEach( function(cmt) {
            if (cmt.newPhase) {
                //ignore phase change comments of any kind
                return;
            }
            if (cmt.time == $scope.focusId) {
                $scope.focusComment = cmt;
            }
            else if (cmt.user == $scope.emailId && cmt.state==11) {
                $scope.newComment = cmt;
            }
            else if (cmt.state==12 || cmt.state==13) {
                allOthers.push(cmt);
            }
            if (newCounts[cmt.userName]) {
                newCounts[cmt.userName]++;
            }
            else {
                newCounts[cmt.userName] = 1;
            }
        });
        $scope.otherComments = allOthers;
        $scope.userCounts = newCounts;
        $scope.newComment.html2 = convertMarkdownToHtml($scope.newComment.body);
        
        $scope.hasResponse = false;
        $scope.showReplyBox = true;
        if ($scope.focusComment.commentType) {
            $scope.showReplyBox = ($scope.focusComment.commentType==1);
            if ($scope.focusComment.commentType==2) {
                $scope.commentTypeName = "Proposal";
                $scope.responseTypeName = "Response";
            }
            else if ($scope.focusComment.commentType==3) {
                $scope.commentTypeName = "Question";
                $scope.responseTypeName = "Answer";
            }
            else {
                $scope.commentTypeName = "Comment";
                $scope.responseTypeName = "N/A";
            }
            if ($scope.focusComment.responses) {
                $scope.focusComment.responses.forEach( function(resp) {
                    if (resp.user == $scope.emailId) {
                        $scope.hasResponse = true;
                        $scope.myResponse = convertMarkdownToHtml(resp.body);
                    }
                });
            }
        }
        
        //determine if the user is subscribed to the topic
        $scope.isSubscriber = false;
        $scope.subscribers.forEach( function(sub) {
            var subIdLC = sub.uid.toLowerCase();
            $scope.loggedUserIds.forEach( function(anId) {
                if (subIdLC == anId.toLowerCase()) {
                    $scope.isSubscriber = true;
                }
            });
        });
    }
    $scope.distributeComments();

    $scope.otherComments.sort(function(a,b) {
        return (a.time-b.time);
    });

    $scope.sendIt = function() {
        if (!$scope.emailId) {
            alert("Please specify your email address");
            return;
        }
        if (!$scope.userName) {
            alert("Please specify your full name");
            return;
        }
        localStorage.setItem('userEmail', $scope.emailId);
        localStorage.setItem('userName', $scope.userName);
        console.log("SENDING:",$scope.newComment); 
        $scope.sentAlready = true;
        $scope.newComment.state=13;
        $scope.saveIt();
    }
    $scope.saveIt = function() {
        $scope.newComment.body = HTML2Markdown($scope.newComment.html2, {});
        $scope.newComment.user = $scope.emailId;
        $scope.newComment.replyTo = $scope.focusId;
        var thisTime = $scope.newComment.time;
        
        var postObj = {comments:[]};
        postObj.commentId = $scope.focusId;
        postObj.topicId = $scope.topicId;
        postObj.meetId = $scope.meetId;
        postObj.agendaId = $scope.agendaId;
        postObj.emailId = $scope.emailId;
        postObj.userName = $scope.userName;
        postObj.comments.push($scope.newComment)
        var postData = angular.toJson(postObj);
        var postURL = "SaveReply.json?" + $scope.specialAccess;
        if ($scope.topicId) {
            postURL = postURL + "&topicId="+$scope.topicId;
        }
        if ($scope.meetId) {
            postURL = postURL + "&meetId="+$scope.meetId;
        }
        if ($scope.agendaId) {
            postURL = postURL + "&agendaId="+$scope.agendaId;
        }
        if ($scope.emailId) {
            postURL = postURL + "&emailId="+$scope.emailId;
        }
        console.log("REQUEST URL", postURL, postObj)
        $http.post(postURL, postData)
        .success( function(data) {
            console.log("result", data);
            $scope.comments = data.comments;
            
            //now find the comment from the server and place back in new comment variable
            data.comments.forEach(  function( oneComm ) {
                if (oneComm.time == thisTime) {
                    $scope.newComment = oneComm;
                }
            });
            $scope.distributeComments();
        })
        .error( function(data, status, headers, config) {
            console.log("ERROR", data, status);
            alert("Failure to save data");
        });
    }
    $scope.goToDiscussion = function() {
    <% if (ar.isLoggedIn()) {%>
    window.location = "<%ar.writeJS(goToUrl);%>";
    <% } else {%>
       SLAP.loginUserRedirect();
    <% } %>
    }

    $scope.changeSubscription = function(onOff) {
        if (!$scope.isLoggedIn) {
            alert("Please log in in order to verify that you are the owner of this email address before you change subscription status.");
            return;
        }
        var url = "topicSubscribe.json?nid="+$scope.topicId + "&" + $scope.specialAccess
        if (!onOff) {
            url = "topicUnsubscribe.json?nid="+$scope.topicId + "&" + $scope.specialAccess
        }
        console.log("SENDING:", url);
        $http.get(url)
        .success( function(data) {
            console.log("GOT BACK:", data); 
            $scope.subscribers = data.subscribers;
            $scope.distributeComments();
        } )
        .error( function(data, status, headers, config) {
            console.log("ERROR",data);
            alert("Failure to save data");
        });
    }
    $scope.downloadDocument = function(doc) {
        if (doc.attType=='URL') {
             window.open(doc.url,"_blank");
        }
        else {
            window.open("a/"+doc.name,"_blank");
        }
    }
    $scope.navigateToDoc = function(doc) {
        if (!doc.id) {
            console.log("DOCID", doc);
            alert("doc id is missing");
        }
        window.location="DocDetail.htm?aid="+doc.id;
    }
    $scope.navigateToLink = function(doc) {
        window.open(doc.url, "_blank");
    }
    
    $scope.startResponse = function() {
        $scope.makingResponse = true;
        $scope.mustGetId = (!$scope.emailId || !$scope.userName);
        
        //get response/answer if any
        $scope.hasResponse = false;
        $scope.myResponse = "";        
        if ($scope.focusComment) {
           if ($scope.focusComment.responses) {
                $scope.focusComment.responses.forEach( function(resp) {
                    if (resp.user == $scope.emailId) {
                        $scope.hasResponse = true;
                        $scope.myResponse = convertMarkdownToHtml(resp.body);
                    }
                });
            }
        }
    }
    $scope.saveResponse = function(choice) {
        if (choice=='Objection' && $scope.myResponse.length < 12) {
            alert("If you object, you must give a clear reason for your objection");
            return;
        }
        $scope.makingResponse = false;
        var newResponse = {};
        newResponse.user = $scope.emailId;
        newResponse.choice = choice;
        newResponse.body = HTML2Markdown($scope.myResponse, {});
        var cmtUpdate = {};
        cmtUpdate.time = $scope.focusComment.time;
        cmtUpdate.responses = [newResponse];
        
        var postData = angular.toJson(cmtUpdate);
        $http.post("updateCommentAnon.json?cid="+cmtUpdate.time+"&msg=<%=msgId%>", postData)
        .success( function(data) {
            console.log("GOT BACK:", data); 
            $scope.focusComment = data;
        } )
        .error( function(data, status, headers, config) {
            console.log("ERROR",data);
            alert("Failure to save data");
        });
    }
    $scope.cancelResponse = function() {
        $scope.makingResponse = false;
    }
    if (!$scope.emailId || !$scope.userName) {
        $scope.mustGetId = true;
    }
    $scope.saveComment = function() {
        $scope.makingResponse = false;
    }
    $scope.cancelComment = function() {
        $scope.makingResponse = false;
    }
    $scope.forgetMe = function() {
        <% if (!ar.isLoggedIn()) {%>
        localStorage.removeItem('userEmail');
        localStorage.removeItem('userName');
        $scope.emailId = "";
        $scope.userName = "";
        <% } %>
    }
    $scope.saveAddresses = function() {
        if (!$scope.emailId) {
            alert("Please enter an email address");
            return;
        }
        
        if (!$scope.emailId) {
            alert("Please enter an email address");
            return;
        }
        localStorage.setItem('userEmail', $scope.emailId);
        localStorage.setItem('userName', $scope.userName);
        $scope.mustGetId = false;
        
        $scope.startResponse();
    }

});

function reloadIfLoggedIn() {
    if (SLAP.loginInfo.verified) {
        //don't do anything
    }
}
</script>


<div class="bodyWrapper"  style="margin:50px">


<style>
.spacey tr td {
    padding: 5px 5px;
}
.mainAboutObject {
    background-color: #F0D7F7;
}

</style>


<div style="max-width:800px;scroll-margin-top:50px">
    
    <div>
<% if (!ar.isLoggedIn()) {%>
            For more options <button class="btn btn-primary btn-raised" ng-click="goToDiscussion()"
                title="Link to the full discussion with all the options">Login</button>
<% } else {%>
            For more options <button class="btn btn-primary btn-raised" ng-click="goToDiscussion()"
                title="Link to the full discussion with all the options">Go To Full Discussion</button>
<% } %>
    </div>
    <div class="comment-outer mainAboutObject">
        <div class="comment-inner">
            <div ng-bind-html="originalWiki|wiki"></div>
        </div>
        <div ng-show="attachments">
          <div><b>Attachments</b></div>
          <div ng-repeat="doc in attachments"  style="vertical-align: top">
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
              &nbsp; {{doc.name}}
          </div>
        </div>
    </div>
    
    <div class="page-name">
        <h1 id="mainPageTitle"
            title="This is the title of the discussion topic and comment thread">
            Comments
        </h1>
    </div>

    <div ng-repeat="cmt in otherComments">
      <div class="comment-outer">
        <div>{{cmt.time|date:'MMM dd, yyyy - HH:mm'}} - <a href="../../FindPerson.htm?uid={{cmt.userKey}}">{{cmt.userName}}</a></div>
        <div class="comment-inner">
          <div ng-bind-html="cmt.body|wiki"></div>
        </div>
        <table ng-show="cmt.responses" class="spacey">
          <tr ng-repeat="resp in cmt.responses" ng-show="resp.body">
            <td><b>{{resp.choice}}</b></td>
            <td><i>{{resp.userName}}</i></td>
            <td><div ng-bind-html="resp.body|wiki" class="comment-inner"></div></td> 
          </tr>
        </table>
        <div class="comment-inner" ng-show="cmt.outcome">
          <div ng-bind-html="cmt.outcome|wiki"></div>
        </div>
        <div ng-repeat="doc in cmt.docDetails">
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
          &nbsp; {{doc.name}}
        </div>
      </div>
    </div>
    
    
    <div id="Comment" style="scroll-margin-top:80px;scroll-padding-top:80px"></div>
    <div ng_show="focusComment.body">
        <h1>{{commentTypeName}} from email:</h1>

        <div class="comment-outer comment-state-active">
          <div>{{focusComment.time|date:'MMM dd, yyyy - HH:mm'}} - <a href="../../FindPerson.htm?uid={{focusComment.userKey}}">{{focusComment.userName}}</a></div>
          <div ng-show="focusComment.commentType>=2"><h3>The {{commentTypeName}}:</h3></div>
          <div class="comment-inner">
            <div ng-bind-html="focusComment.body|wiki"></div>
          </div>
          <table ng-show="focusComment.responses" class="spacey" style="width:100%">
            <tr ng-show="focusComment.commentType>=2 && !makingResponse">
                <td colSpan="3"><h3>{{responseTypeName}}s so far:</h3></td></tr>
            <tr ng-repeat="resp in focusComment.responses" ng-show="!makingResponse">
              <td><b>{{resp.choice}}</b></td>
              <td><i>{{resp.userName}}</i></td>
              <td><div ng-bind-html="resp.body|wiki" class="comment-inner"></div></td> 
            </tr>
            <tr ng-show="focusComment.commentType>=2 && !makingResponse"><td></td><td></td><td>
              <button ng-click="startResponse()" class="btn btn-primary btn-raised">Create / update your {{responseTypeName}}</button></td></tr>
            <tr ng-show="makingResponse && mustGetId"><td colSpan="3">
                <div class="comment-outer" style="padding:25px;width:600px">
                
                    <div>Please enter/verify your email address</div>
                    <div><input class="form-control" ng-model="emailId" placeholder="Enter email"/></div>
                    <div>And your name</div>
                    <div><input class="form-control" ng-model="userName" placeholder="Enter name"/></div>
                    <div><button class="btn btn-primary btn-raised" ng-click="saveAddresses()"
                        title="Save these verified values">Save & Continue</button></div>
                </div>
            </td></tr>
            <tr ng-show="makingResponse && !mustGetId"><td colSpan="3">
              <div><h3>Your {{responseTypeName}}:</h3></div>       
              <div ui-tinymce="tinymceOptions" ng-model="myResponse"
                 class="leafContent" style="height:250px;" id="theOnlyEditor"></div>
              <div ng-show="focusComment.commentType==2">
                  <button ng-click="saveResponse('Consent')" class="btn btn-primary btn-raised">Consent</button>
                  <button ng-click="saveResponse('Objection')" class="btn btn-primary btn-raised">Objection</button>
                  <button ng-click="cancelResponse()" class="btn btn-warning btn-raised">Cancel</button>
              </div>
              <div ng-show="focusComment.commentType==3">
                  <button ng-click="saveResponse()" class="btn btn-primary btn-raised">Save</button>
                  <button ng-click="cancelResponse()" class="btn btn-warning btn-raised">Cancel</button>
              </div>
            </td></tr>
          </table>

          <div ng-show="focusComment.outcome"><h3>The Outcome:</h3></div>
          <div class="comment-inner" ng-show="focusComment.outcome">
            <div ng-bind-html="focusComment.outcome|wiki"></div>
          </div>
        <div ng-repeat="doc in focusComment.docDetails">
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
          &nbsp; {{doc.name}}
        </div>
      </div>
        </div>
    </div>
 
  <div ng-show="showReplyBox">
    <div ng-show="showReplyBox && mustGetId">
        <div class="comment-outer comment-state-active" style="padding:25px;min-height:460px">
        
            <div>Please enter/verify your email address</div>
            <div><input class="form-control" ng-model="emailId" placeholder="Enter email"/></div>
            <div>And your name</div>
            <div><input class="form-control" ng-model="userName" placeholder="Enter name"/></div>
            <div><button class="btn btn-primary btn-raised" ng-click="saveAddresses()"
                title="Save these verified values">Save & Continue</button></div>
        </div>
    </div>
    <div ng-show="showReplyBox && !mustGetId">
        <div ng-hide="sentAlready" class="comment-outer comment-state-active" style="min-height:460px">
            <h2 id="QuickReply" style="scroll-margin-top:80px;scroll-padding-top:80px">Quick&nbsp;Reply:</h2>
            <div ui-tinymce="tinymceOptions" ng-model="newComment.html2"
                 class="leafContent" style="height:250px;" id="theOnlyEditor"></div>
            <div>
                <button class="btn btn-default btn-raised" ng-click="saveIt()"
                        title="Send the comment into the discussion topic">Save Draft</button>
                <button class="btn btn-primary btn-raised" ng-click="sendIt()"
                        title="Send the comment into the discussion topic">Send</button>
            </div>
        </div>
    </div>
  </div>
    
    <div style="margin:50px"  style="broder:2px solid red"></div>
    
    
    
    <div ng-hide="makingResponse">
    <% if (!ar.isLoggedIn()) {%>
            For more options <button class="btn btn-primary btn-raised" ng-click="goToDiscussion()"
                title="Link to the full discussion with all the options">Login</button>
    <% } else {%>
            For more options <button class="btn btn-primary btn-raised" ng-click="goToDiscussion()"
                title="Link to the full discussion with all the options">Go To Full Discussion</button>
    <% } %>
    </div>   
    
    <table class="table" style="width:100%;max-width:800px">
        <tr ng-show="topicSubject">
            <td>Discussion Topic</td>
            <td>{{topicSubject}}</td>
        </tr>
        <tr ng-show="meetingTitle">
            <td>Meeting</td>
            <td>{{meetingTitle}}</td>
        </tr>
        <tr ng-show="agendaItem">
            <td>Agenda Item</td>
            <td>{{agendaItem}}</td>
        </tr>
        <tr >
            <td>Subscribers</td>
            <td>
                The following people will receive email if you reply:
                <ul>
                <li ng-repeat="sub in subscribers">{{sub.name}}</li>
                </ul>
            </td>
        </tr>
        <tr ng-show="topicSubject && isLoggedIn">
            <td>Your Subscription</td>
            <td>
              <div ng-show="isSubscriber">
                <div>You are currently subscribed to this discussion topic
                <b>{{topicSubject}}</b>.</div>
                <button ng-click="changeSubscription(false)" 
                        class="btn btn-default btn-raised"
                        title="Click to remove yourself from the list and stop getting notifications from this discussion topic">
                        Unsubscribe</button>
                <div>
                    If you unsubscribe, then you will stop receiving any email
                    when a new comment is added to the discussion.  Unsubscribe if
                    you no longer want to see comments on this topic.
                </div>
              </div>
              <div ng-hide="isSubscriber">
                <div>You are NOT subscribed to this discussion topic
                <b>{{topicSubject}}</b>.</div>
                <button ng-click="changeSubscription(true)" 
                        class="btn btn-default btn-raised"
                        title="Click to remove add youself to the list and start getting notifications from this discussion topic">
                        Subscribe</button>
                <div>
                    If you subscribe, you will receive email
                    every time a new comment is added to the discussion.  
                    Subscribe if you want to see comments on this topic.
                </div>
              </div>
            </td>
        </tr>
        <tr ng-show="agendaItem">
            <td>Your Participation</td>
            <td>
              <div ng-show="isSubscriber">
                <div>You are currently a participant of the meeting
                <b>{{meetingTitle}}</b>.</div>
                
                <div>
                    As a participant, you will receive email for comments
                    made on meeting agenda items.  
                    <i>At the current time there is no option here to 
                    withdraw from participating in the meeting, but 
                    if you choose to go to the full discussion and 
                    change your participation there.</i>
                </div>
              </div>
            </td>
        </tr>
        <tr>
            <td>Count</td>
            <td>{{comments.length}} comments</td>
        </tr>
        <tr>
            <td id="Unsub">Contributors</td>
            <td id="Unsub"><span ng-repeat="(user,cnt) in userCounts">{{user}} {{cnt}},  &nbsp;</span></td>
        </tr>
        <tr>
            <td>Reply as</td>
            <td>{{emailId}}
              <span ng-hide="emailId==linkedEmailId">(You used a hyperlink from {{linkedEmailId}})</span>
<% if (!ar.isLoggedIn()) {%>
              <br/>
              <button ng-click="forgetMe()" class="btn btn-default btn-raised">Wait!  That is not me!</button>
<% } %>
            </td>
        </tr>
    </table>

    </div>
  </div>
  
