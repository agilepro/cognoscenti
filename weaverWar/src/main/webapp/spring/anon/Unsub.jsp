<%@page errorPage="/spring/jsp/error.jsp"
%><%@page import="com.purplehillsbooks.weaver.SharePortRecord"
%><%@page import="com.purplehillsbooks.weaver.AccessControl"
%><%@ include file="/include.jsp"
%><%
/*
Required parameters:

    1. pageId   : This is the id of a workspace and here it is used to retrieve NGWorkspace.

*/

    String topicId   = ar.reqParam("topicId");
    String commentId = ar.reqParam("commentId");
    String pageId    = ar.reqParam("pageId");
    String siteId    = ar.reqParam("siteId");
    String emailId    = ar.reqParam("emailId");
    String linkedEmailId = emailId;
    NGWorkspace ngw  = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngw);
    
    if (ar.isLoggedIn()) {
        emailId = ar.getBestUserId();
    }

    TopicRecord topic = ngw.getDiscussionTopic(topicId);
    
    JSONObject topicInfo = topic.getJSONWithComments(ar, ngw);
    
    String specialAccess = AccessControl.getAccessTopicParams(ngw, topic)
                + "&emailId=" + URLEncoder.encode(emailId, "UTF-8");
    
    
%>


<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal) {
    $scope.topicInfo = <%topicInfo.write(out,2,4);%>;
    $scope.focusId = <%=commentId%>;
    $scope.focusComment = {};
    $scope.otherComments = [];
    $scope.nowTime = new Date().getTime();
    $scope.tinymceOptions = standardTinyMCEOptions();
    $scope.tinymceOptions.height = 400;
    $scope.isLoggedIn = <%=ar.isLoggedIn()%>;
    $scope.sentAlready = false;
    $scope.userCounts = {};
    $scope.emailId = "<%ar.writeJS(emailId);%>";
    $scope.linkedEmailId = "<%ar.writeJS(linkedEmailId);%>";
    $scope.isSubscriber = true;
    $scope.newComment = {html:"",state:11,user:"<%ar.writeJS(emailId);%>"};
    $scope.newComment.time = $scope.nowTime;
    $scope.specialAccess = "<%ar.writeJS(specialAccess);%>";
    $scope.infoOpen = true;
    
    $scope.distributeComments = function() {
        var newCounts = {};
        var allOthers = [];
        $scope.topicInfo.comments.forEach( function(cmt) {
            cmt.html2 = convertMarkdownToHtml(cmt.body);
            if (cmt.time == $scope.focusId) {
                $scope.focusComment = cmt;
            }
            else if (cmt.user == $scope.emailId && cmt.state==11) {
                $scope.newComment = cmt;
            }
            else if (cmt.state!=11) {
                allOthers.push(cmt);
            }
            if (newCounts[cmt.userName]) {
                newCounts[cmt.userName]++;
            }
            else {
                newCounts[cmt.userName] = 1;
            }
            var isSub = false;
            $scope.topicInfo.subscribers.forEach( function(sub) {
                if ($scope.emailId.toLowerCase() == sub.uid.toLowerCase()) {
                    isSub = true;
                }
            });
            $scope.isSubscriber = isSub;
        });
        $scope.otherComments = allOthers;        
        $scope.userCounts = newCounts;
        $scope.otherComments.sort(function(a,b) {
            return (b.time-a.time);
        });
    }
    $scope.distributeComments();
    
    
    $scope.saveIt = function() {
        var postURL = $scope.focusId + ".json?" + $scope.specialAccess;
        var postObj = {comments:[]};
        postObj.comments.push($scope.newComment)
        var postData = angular.toJson(postObj);
        console.log("REQUEST URL", postURL, postData)
        $http.post(postURL, postData)
        .success( function(data) {
            $scope.topicInfo = data;
            $scope.distributeComments();
        })
        .error( function(data, status, headers, config) {
            console.log("ERROR", data, status)
        });
    }
    $scope.sendIt = function() {
        $scope.sentAlready = true;
        $scope.newComment.state=13;
        $scope.saveIt();
    }
    $scope.goToDiscussion = function() {
        var url = "../../noteZoom"+$scope.topicInfo.id+".htm";
        window.location = url;
    }

    $scope.changeSubscription = function(onOff) {
        var url = "../../topicSubscribe.json?nid="+$scope.topicInfo.id + "&" + $scope.specialAccess
        if (!onOff) {
            url = "../../topicUnsubscribe.json?nid="+$scope.topicInfo.id + "&" + $scope.specialAccess
        }
        console.log("SENDING:", url);
        $http.get(url)
        .success( function(data) {
            console.log("GOT BACK:", data);
            $scope.topicInfo = data;
            $scope.distributeComments();
        } )
        .error( function(data, status, headers, config) {
            console.log("ERROR",data);
        });
    }
    
});
</script>

  
    <div ng-app="myApp" ng-controller="myCtrl">

        <div class="page-name">
            <h1 id="mainPageTitle" ng-click="infoOpen=!infoOpen"
                title="This is the title of the discussion topic that all these topics are attached to">
                {{topicInfo.subject}} <i class="fa fa-caret-square-o-down"></i>
            </h1>
        </div>
        
        <table ng-show="infoOpen" class="table">
        <tr>
            <td>Discussion Topic</td>
            <td>{{topicInfo.subject}}</td>
        </tr>
        <tr>
            <td>Subscribers</td>
            <td><span ng-repeat="sub in topicInfo.subscribers">{{sub.name}}, </span></td>
        </tr>
        <tr>
            <td>You are</td>
            <td>{{emailId}}   
              <span ng-hide="emailId==linkedEmailId" style="color:red">(You used a link for {{linkedEmailId}})</span>
            </td>
        </tr>
        <tr>
            <td>Your Participation</td>
            <td>
                
                <span style="color:lightgray" ng-show="isSubscriber" >
                    <button ng-click="changeSubscription(false)" 
                        class="btn btn-primary btn-raised" 
                        title="Click to remove yourself from the list and stop getting notifications from this discussion topic">
                        Unsubscribe</button>
                    &nbsp; Unsubscribe if you no longer want to receive email notification about new comments on this discussion topic.</span>
                <span style="color:lightgray" ng-hide="isSubscriber" >
                    <button ng-click="changeSubscription(true)" 
                        class="btn btn-primary btn-raised" 
                        title="Click to remove add youself to the list and start getting notifications from this discussion topic">
                        Subscribe</button>
                    &nbsp; Subscribe to be notified of new comments on this topic.</span>
            </td>
        </tr>
        <tr>
            <td>Count</td>
            <td>{{topicInfo.comments.length}} comments</td>
        </tr>
        <tr>
            <td>Contributors</td>
            <td><span ng-repeat="(user,cnt) in userCounts">{{user}} {{cnt}},  &nbsp;</span></td>
        </tr>
        </table>


        <h2>Comments:</h2>
        <div ng_show="focusId>0">
            
            <div class="comment-outer">
              <div>{{focusComment.userName}} - {{focusComment.time|date:'MMM dd, yyyy - HH:mm'}}</div>
              <div class="comment-inner">
                <div ng-bind-html="focusComment.html2"></div>
              </div>
            </div>
        </div>
        
        <div ng-repeat="cmt in otherComments" class="comment-outer">
          <div>{{cmt.userName}} - {{cmt.time|date:'MMM dd, yyyy - HH:mm'}}</div>
          <div class="comment-inner">
            <div ng-bind-html="cmt.html2"></div>
          </div>
        </div>
        
        <h2>Original Topic:</h2>
        
        <div class="comment-outer">
          <div class="comment-inner">
            <div ng-bind-html="topicInfo.html2"></div>
          </div>
        </div>
        
        
    </div>
