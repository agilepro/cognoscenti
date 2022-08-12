<%@page errorPage="/spring/jsp/error.jsp"
%><%@page import="com.purplehillsbooks.weaver.SharePortRecord"
%><%@page import="com.purplehillsbooks.weaver.AccessControl"
%><%@page import="com.purplehillsbooks.weaver.CommentContainer"
%><%@page import="com.purplehillsbooks.weaver.AgendaItem"
%><%@page import="com.purplehillsbooks.weaver.CommentRecord"
%><%@page import="com.purplehillsbooks.weaver.EmailContext"
%><%@ include file="/spring/jsp/include.jsp"
%><%
/*
Required parameters:

    1. pageId   : This is the id of a workspace and here it is used to retrieve NGWorkspace.

*/

    String topicId   = ar.defParam("topicId", null);
    String meetId   = ar.defParam("meetId", null);
    String agendaId   = ar.defParam("agendaId", null);
    String commentId = ar.defParam("commentId", null);
    String pageId    = ar.reqParam("pageId");
    String siteId    = ar.reqParam("siteId");
    String emailId    = ar.defParam("emailId", null);
    
    String linkedEmailId = emailId;
    NGWorkspace ngw  = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngw);

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

    if (meetId!=null) {
        MeetingRecord meet = ngw.findMeeting(meetId);
        AgendaItem ai = meet.findAgendaItem(agendaId);
        emailContext = new EmailContext(meet, ai);
        meetingTitle = meet.getName();
        agendaItem = ai.getSubject();
        originalTopic = ai.getDesc();
        originalSubject = "Agenda: " + ai.getSubject();
        JSONObject meetInfo = meet.getFullJSON(ar, ngw, false);
        subscribers = meetInfo.getJSONArray("participants");
        
    }
    else {
        TopicRecord topic = ngw.getDiscussionTopic(topicId);
        JSONObject topicInfo = topic.getJSONWithComments(ar, ngw);
        originalTopic = topicInfo.getString("wiki");
        subscribers = topicInfo.getJSONArray("subscribers");
        specialAccess = AccessControl.getAccessTopicParams(ngw, topic)
                    + "&emailId=" + URLEncoder.encode(emailId, "UTF-8");
        emailContext = new EmailContext(topic);
        originalSubject = "Topic: " + topic.getSubject();
        
        for (AttachmentRecord att : topic.getAttachedDocsIncludeComments(ngw)) {
             attachments.put(att.getMinJSON(ngw));
        }
    }
    String goToUrl = ar.baseURL + emailContext.getEmailURL(ar, ngw);
    for (CommentRecord comm : emailContext.getPeerComments()) {
        comments.put(comm.getHtmlJSON());
    }


%>

<!-- ************************ anon/Reply.jsp ************************ -->
<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal) {
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
    
    $scope.emailId = "<%ar.writeJS(emailId);%>";
    

    $scope.tinymceOptions = standardTinyMCEOptions();
    $scope.tinymceOptions.height = 250;
    $scope.isLoggedIn = <%=ar.isLoggedIn()%>;
    $scope.sentAlready = false;
    $scope.userCounts = {};
    $scope.linkedEmailId = "<%ar.writeJS(linkedEmailId);%>";
    $scope.isSubscriber = true;
    $scope.specialAccess = "<%ar.writeJS(specialAccess);%>";
    $scope.subscribers = <%subscribers.write(out,2,4);%>;
    $scope.originalWiki = "<%ar.writeJS(originalTopic);%>";
    $scope.originalSubject = "<%ar.writeJS(originalSubject);%>";
    $scope.meetingTitle = "<%ar.writeJS(meetingTitle);%>";
    $scope.topicSubject = "<%ar.writeJS(topicSubject);%>";
    $scope.agendaItem = "<%ar.writeJS(agendaItem);%>";
    $scope.attachments = <%attachments.write(out,2,4);%>;
    
    $scope.originalTopic = convertMarkdownToHtml($scope.originalWiki);
    
 
    $scope.generateCommentHtml = function(cmt) { 
        cmt.html2 = convertMarkdownToHtml(cmt.body);
        cmt.outcomeHtml = convertMarkdownToHtml(cmt.outcome);
        cmt.responses.forEach( function(item) {
            item.html = convertMarkdownToHtml(item.body);
        });
    }
    $scope.distributeComments = function() {
        var newCounts = {};
        var allOthers = [];
        console.log("COMMENTS", $scope.comments);
        $scope.comments.forEach( function(cmt) {
            if (cmt.newPhase) {
                //ignore phase change comments of any kind
                return;
            }
            $scope.generateCommentHtml(cmt);
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
        var isSub = false;
        $scope.subscribers.forEach( function(sub) {
            if ($scope.emailId.toLowerCase() == sub.uid.toLowerCase()) {
                isSub = true;
            }
        });
        $scope.isSubscriber = isSub;
    }
    $scope.distributeComments();

    $scope.otherComments.sort(function(a,b) {
        return (a.time-b.time);
    });

    $scope.saveIt = function() {
        $scope.newComment.body = HTML2Markdown($scope.newComment.html2, {});
        $scope.newComment.user = $scope.emailId;
        var thisTime = $scope.newComment.time;
        
        var postObj = {comments:[]};
        postObj.commentId = $scope.focusId;
        postObj.topicId = $scope.topicId;
        postObj.meetId = $scope.meetId;
        postObj.agendaId = $scope.agendaId;
        postObj.emailId = $scope.emailId;
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
        console.log("REQUEST URL", postURL, postData)
        $http.post(postURL, postData)
        .success( function(data) {
            console.log("result", data);
            $scope.comments = data.comments;
            
            //now find the comment from the server and place back in new comment variable
            data.comments.forEach(  function( oneComm ) {
                if (oneComme.time == thisTime) {
                    $scope.newComment = oneComm;
                }
            });
            $scope.distributeComments();
        })
        .error( function(data, status, headers, config) {
            console.log("ERROR", data, status)
        });
    }
    $scope.sendIt = function() {
        console.log("SENDING:",$scope.newComment); 
        $scope.sentAlready = true;
        $scope.newComment.state=13;
        $scope.saveIt();
    }
    $scope.goToDiscussion = function() {
        window.location = "<%ar.writeJS(goToUrl);%>";
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
        });
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

});

function reloadIfLoggedIn() {
    if (SLAP.loginInfo.verified) {
        //don't do anything
    }
}
</script>

</head>

<body>
  <div class="bodyWrapper"  style="margin:50px">


<style>
.spacey tr td {
    padding: 5px 5px;
}

</style>


<div ng-app="myApp" ng-controller="myCtrl" style="max-width:800px">
    
    <div class="comment-outer comment-state-active">
      <div class="comment-inner">
        <div ng-bind-html="originalTopic"></div>
      </div>
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
    
    <div class="page-name">
        <h1 id="mainPageTitle"
            title="This is the title of the discussion topic and comment thread">
            Comments
        </h1>
    </div>

    <div ng-repeat="cmt in otherComments">
     <div class="comment-outer">
      <div>{{cmt.time|date:'MMM dd, yyyy - HH:mm'}} - {{cmt.userName}}</div>
      <div class="comment-inner">
        <div ng-bind-html="cmt.html2"></div>
      </div>
    </div>
   </div>

        <div ng_show="focusComment.html2">
            <h1>You are replying to:</h1>

            <div class="comment-outer">
              <div>{{focusComment.time|date:'MMM dd, yyyy - HH:mm'}} - {{focusComment.userName}}</div>
              <div class="comment-inner">
                <div ng-bind-html="focusComment.html2"></div>
              </div>
            </div>
        </div>
    SENT ALREADY: {{sentAlready}}
    <div style="min-height:460px">
        <div ng-hide="sentAlready" class="comment-outer">
            <table class="spacey"><tr>
            <td><h2 id="QuickReply">Quick&nbsp;Reply:</h2></td>
            <td><button class="btn btn-default btn-raised" ng-click="saveIt()"
                title="Send the comment into the discussion topic">Save Draft</button></td>
            <td><button class="btn btn-primary btn-raised" ng-click="sendIt()"
                title="Send the comment into the discussion topic">Send</button></td>
            <td><button class="btn btn-primary btn-raised" ng-click="goToDiscussion()"
                title="Link to the full discussion with all the options">Go To Full Discussion</button></td>
            <td><span ng-hide="isLoggedIn" style="color:lightgray">You will need to log in to access discussion</span></td>
            </tr>
<% if (!ar.isLoggedIn()) { %>
            <tr><td colspan="3">
                <h3>Verify/correct your email address:</h3>
            </td><td colspan="2">
                <h3><input type="form-control" ng-model="emailId"/></h3>
            </td></tr>
<% } %>
            </table>
            <div ui-tinymce="tinymceOptions" ng-model="newComment.html2"
                 class="leafContent" style="height:250px;" id="theOnlyEditor"></div>
       </div>
        <div ng-show="sentAlready">
            <table class="spacey"><tr>
            <td><h2>Your reply is sent:</h2></td>
            <td><button class="btn btn-primary btn-raised" ng-click="goToDiscussion()"
                title="Link to the full discussion with all the options">Go To Full Discussion</button></td>
            <td><span ng-hide="isLoggedIn" style="color:lightgray">You will need to log in to access the discussion</span></td>
            </tr></table>
            <div class="comment-outer">
              <div>{{newComment.userName}} - {{newComment.time|date:'MMM dd, yyyy - HH:mm'}}</div>
              <div class="comment-inner">
                <div ng-bind-html="newComment.html2"></div>
              </div>
            </div>
            
        </div>
    </div>
    <table class="table" style="max-width:800px">
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
        <tr ng-show="topicSubject">
            <td>Your Participation</td>
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
              <span ng-hide="emailId==linkedEmailId" style="color:red">(You used a link for {{linkedEmailId}})</span>
            </td>
        </tr>
    </table>

    </div>
  </div>
  
