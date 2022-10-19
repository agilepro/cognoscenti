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
    if (meetId!=null) {
        MeetingRecord meet = ngw.findMeeting(meetId);
        AgendaItem ai = meet.findAgendaItem(agendaId);
        emailContext = new EmailContext(meet, ai);
        meetingTitle = meet.getName();
        agendaItem = ai.getSubject();
    }
    else {
        TopicRecord topic = ngw.getDiscussionTopic(topicId);
        JSONObject topicInfo = topic.getJSONWithComments(ar, ngw);
        originalTopic = topicInfo.getString("wiki");
        subscribers = topicInfo.getJSONArray("subscribers");
        specialAccess = AccessControl.getAccessTopicParams(ngw, topic)
                    + "&emailId=" + URLEncoder.encode(emailId, "UTF-8");
        emailContext = new EmailContext(topic);
        topicSubject = topic.getSubject();
    }
    String goToUrl = ar.baseURL + emailContext.getEmailURL(ar, ngw);
    String originalSubject = emailContext.emailSubject();
    for (CommentRecord comm : emailContext.getPeerComments()) {
        comments.put(comm.getJSONWithDocs(ngw));
    }
%>

<!-- ************************ jsp/ReplyOld.jsp ************************ -->
<script type="text/javascript">
var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal) {
    window.setMainPageTitle("OLD Reply Format: Better things are coming . . .");
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
    
    $scope.originalTopic = convertMarkdownToHtml($scope.originalWiki);
    
    $scope.distributeComments = function() {
        var newCounts = {};
        var allOthers = [];
        $scope.comments.forEach( function(cmt) {
            if (cmt.newPhase) {
                //ignore phase change comments of any kind
                return;
            }
            //assure that the HTML exists
            if (cmt.body) {
                cmt.html = convertMarkdownToHtml(cmt.body);
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
        $scope.newComment.body = HTML2Markdown($scope.newComment.html, {});
        $scope.newComment.user = $scope.emailId;
        
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
            $scope.topicInfo = data;
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
        var url = "../../topicSubscribe.json?nid="+$scope.topicId + "&" + $scope.specialAccess
        if (!onOff) {
            url = "../../topicUnsubscribe.json?nid="+$scope.topicId + "&" + $scope.specialAccess
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
    <div class="page-name">
        <h1 id="mainPageTitle"
            title="This is the title of the discussion topic and comment thread">
            Topic: {{originalSubject}} 
        </h1>
    </div>
    
    <div class="comment-outer comment-state-active">
      <div class="comment-inner">
        <div ng-bind-html="originalTopic"></div>
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
      <div>{{focusComment.time|date:'MMM dd, yyyy - HH:mm'}} - {{focusComment.userName}}</div>
      <div class="comment-inner">
        <div ng-bind-html="cmt.html"></div>
      </div>
    </div>
   </div>

        <div ng_show="focusComment.html">
            <h1>You are replying to:</h1>

            <div class="comment-outer">
              <div>{{focusComment.time|date:'MMM dd, yyyy - HH:mm'}} - {{focusComment.userName}}</div>
              <div class="comment-inner">
                <div ng-bind-html="focusComment.html"></div>
              </div>
            </div>
        </div>


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
            <div ui-tinymce="tinymceOptions" ng-model="newComment.html"
                 class="leafContent" style="max-height:250px;" id="theOnlyEditor"></div>
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
                <div ng-bind-html="newComment.html"></div>
              </div>
            </div>
            
        </div>

    <table class="table">
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
        <tr ng-show="topicSubject">
            <td>Subscribers</td>
            <td><span ng-repeat="sub in subscribers">{{sub.name}}, </span></td>
        </tr>
        <tr ng-show="topicSubject"  id="Unsub">
            <td>Your Participation</td>
            <td>
                <button ng-click="changeSubscription(false)" ng-show="isSubscriber"
                        class="btn btn-default btn-raised"
                        title="Click to remove yourself from the list and stop getting notifications from this discussion topic">
                        Unsubscribe</button>
                <button ng-click="changeSubscription(true)" ng-hide="isSubscriber"
                        class="btn btn-default btn-raised"
                        title="Click to remove add youself to the list and start getting notifications from this discussion topic">
                        Subscribe</button>
                <span style="color:lightgray">&nbsp; Controls future email messages</span>
            </td>
        </tr>
        <tr>
            <td>Count</td>
            <td>{{comments.length}} comments</td>
        </tr>
        <tr>
            <td>Contributors</td>
            <td><span ng-repeat="(user,cnt) in userCounts">{{user}} {{cnt}},  &nbsp;</span></td>
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
  