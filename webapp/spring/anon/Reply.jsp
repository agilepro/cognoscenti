<%@page errorPage="/spring/jsp/error.jsp"
%><%@page import="org.socialbiz.cog.SharePortRecord"
%><%@page import="org.socialbiz.cog.AccessControl"
%><%@ include file="/spring/jsp/include.jsp"
%><%
/*
Required parameters:

    1. pageId   : This is the id of a workspace and here it is used to retrieve NGPage.

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

    TopicRecord topic = ngw.getNote(topicId);
    
    JSONObject topicInfo = topic.getJSONWithComments(ar, ngw);
    
    String specialAccess = AccessControl.getAccessTopicParams(ngw, topic)
                + "&emailId=" + URLEncoder.encode(emailId, "UTF-8");
    
    
%>

<html>
<head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
    <meta http-equiv="Content-Language" content="en-us" />
    <meta http-equiv="Content-Style-Type" content="text/css" />
    <meta http-equiv="imagetoolbar" content="no" />
    <meta name="viewport" content="user-scalable=no, initial-scale=1.0, minimum-scale=1.0, maximum-scale=1.0" />

    <!-- INCLUDE the ANGULAR JS library -->
    <script src="<%=ar.baseURL%>jscript/angular.min.js"></script>
    <script src="<%=ar.baseURL%>jscript/ui-bootstrap-tpls.min.js"></script>
    <script src="<%=ar.baseURL%>jscript/jquery.min.js"></script>
    <script src="<%=ar.baseURL%>jscript/bootstrap.min.js"></script>
    <script src="<%=ar.baseURL%>jscript/slap.js"></script>
    <link href="<%=ar.baseURL%>jscript/bootstrap.min.css" rel="stylesheet">
    <script src='<%=ar.baseURL%>jscript/tinymce/tinymce.min.js'></script>
    <script src='<%=ar.baseURL%>jscript/tinymce/tinymce-ng.js'></script>
    <script src="<%=ar.baseURL%>jscript/textAngular-sanitize.min.js"></script>
    <link href="<%=ar.baseURL%>jscript/ng-tags-input.css" rel="stylesheet">
    <script src="<%=ar.baseURL%>jscript/bootstrap-material-design/ripples.min.js"></script>
    <script src="<%=ar.baseURL%>jscript/bootstrap-material-design/material.min.js"></script>
    <link rel="stylesheet" href="<%=ar.baseURL%>css/bootstrap-material-design/bootstrap-material-design.min.css" media="screen">
    <link rel="stylesheet" href="<%=ar.baseURL%>css/bootstrap-material-design/ripples.min.css" media="screen">
    <script src="<%=ar.baseURL%>jscript/common.js"></script>

	<!-- INCLUDE web fonts -->
    <link href="<%=ar.retPath%>assets/font-awesome/css/font-awesome.min.css" rel="stylesheet"
          data-semver="4.3.0" data-require="font-awesome@*" />
	  <link href="<%=ar.retPath%>assets/google/css/PT_Sans-Web.css" rel="stylesheet"/>

    <link href="<%=ar.retPath%>bits/fixed-sidebar.min.css" rel="styleSheet" type="text/css" media="screen" />
    <!-- Weaver specific tweaks -->
    <link href="<%=ar.retPath%>bits/main.min.css" rel="styleSheet" type="text/css" media="screen" />

<script type="text/javascript">

var app = angular.module('myApp', ['ui.bootstrap', 'ui.tinymce', 'ngSanitize']);
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
    
    $scope.distributeComments = function() {
        var newCounts = {};
        var allOthers = [];
        $scope.topicInfo.comments.forEach( function(cmt) {
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
    }
    $scope.distributeComments();
    
    $scope.otherComments.sort(function(a,b) {
        return (b.time-a.time);
    });
    
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

</head>

<body>
  <div class="bodyWrapper"  style="margin:50px">

  
  
    <nav class="navbar navbar-default appbar">
      <div class="container-fluid">

      
<style>
.spacey tr td {
    padding: 5px 10px;
}
</style>


        <!-- Logo Brand -->
        <a class="navbar-brand" href="<%=ar.retPath%>" title="Weaver Home Page">
          <img class="hidden-xs" alt="Weaver Icon" src="<%=ar.retPath%>bits/header-icon.png">
          <h1>Weaver</h1>
        </a>


      </div>
    </nav>
  
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
            <td>{{topicInfo.comments.length}} comments</td>
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

        <div ng-hide="sentAlready">
            <table class="spacey"><tr>
            <td><h2>Quick Reply:</h2></td>
            <td><button class="btn btn-default btn-raised" ng-click="saveIt()"
                title="Send the comment into the discussion topic">Save Draft</button></td>
            <td><button class="btn btn-primary btn-raised" ng-click="sendIt()"
                title="Send the comment into the discussion topic">Send</button></td>
            <td><button class="btn btn-primary btn-raised" ng-click="goToDiscussion()"
                title="Link to the full discussion with all the options">Go To Full Discussion</button></td>
            <td><span ng-hide="isLoggedIn" style="color:lightgray">You will need to log in to access the discussion</span></td>
            </tr></table>
            <div ui-tinymce="tinymceOptions" ng-model="newComment.html" 
                 class="leafContent" style="min-height:160px;" id="theOnlyEditor"></div>
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

        <div ng_show="focusId>0">
            <h2>You are replying to:</h2>
            
            <div class="comment-outer">
              <div>{{focusComment.userName}} - {{focusComment.time|date:'MMM dd, yyyy - HH:mm'}}</div>
              <div class="comment-inner">
                <div ng-bind-html="focusComment.html"></div>
              </div>
            </div>
        </div>

        <h2>Other Comments:</h2>
        
        <div ng-repeat="cmt in otherComments" class="comment-outer">
          <div>{{cmt.userName}} - {{cmt.time|date:'MMM dd, yyyy - HH:mm'}}</div>
          <div class="comment-inner">
            <div ng-bind-html="cmt.html"></div>
          </div>
        </div>
        
        <h2>Original Topic:</h2>
        
        <div class="comment-outer">
          <div class="comment-inner">
            <div ng-bind-html="topicInfo.html"></div>
          </div>
        </div>
        
        
    </div>
  </div>
</body>
</html>





