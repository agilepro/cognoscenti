<%@page errorPage="/spring/jsp/error.jsp"
%><%@page import="org.socialbiz.cog.SharePortRecord"
%><%@page import="org.socialbiz.cog.AccessControl"
%><%@ include file="/spring/jsp/include.jsp"
%><%
/*
Required parameters:

    1. pageId   : This is the id of a workspace and here it is used to retrieve NGWorkspace.

*/

    String pageId = ar.reqParam("pageId");
    String siteId = ar.reqParam("siteId");
    NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngw);
    
    String meetId          = ar.reqParam("id");
    String mnm             = ar.defParam("mnm", null);
    MeetingRecord meeting  = ngw.findMeeting(meetId);
    JSONObject meetingObj = meeting.getFullJSON(ar, ngw);
    
    JSONArray timeSlots = meetingObj.getJSONArray("timeSlots");
    if (timeSlots.length()==0) {
        long startTime = meeting.getStartTime();
        if (startTime>0) {
            meeting.findOrCreateProposedTime("timeSlots", startTime);
            meetingObj = meeting.getFullJSON(ar, ngw);
        }
    }
    

    String emailId    = ar.defParam("emailId", null);
    if (ar.isLoggedIn()) {
        emailId = ar.getBestUserId();
    }


%>
<!DOCTYPE html>
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
    $scope.meeting = {};
    $scope.emailId = "<% ar.writeJS(emailId); %>";

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        console.log("Encountered problem: ",serverErr);
    };
    
    $scope.setMeetingData = function(data) {
        console.log("Received meeting data: ", data);
        if (!data.meetingInfo) {
            data.meetingInfo = "";
        }
        $scope.timerCorrection = data.serverTime - new Date().getTime();
        $scope.meeting = data;

        $scope.editHead=false;
        $scope.editDesc=false;
        if (data.reminderTime%1440 == 0) {
            $scope.timeFactor="Days"
        }
        else {
            $scope.timeFactor="Minutes"
        }
        if ($scope.timeFactor=="Days") {
            $scope.factoredTime = $scope.meeting.reminderTime / 1440;
        }
        else {
            $scope.factoredTime = $scope.meeting.reminderTime;
        }
        data.timeSlots.sort(function(a,b) {
            return a.proposedTime - b.proposedTime;
        });
        data.futureSlots.sort(function(a,b) {
            return a.proposedTime - b.proposedTime;
        });
        $scope.timeSlotResponders = calcResponders(data.timeSlots, $scope.emailId);
        $scope.futureSlotResponders = calcResponders(data.futureSlots, $scope.emailId);
        
        $scope.descriptionHtml = data.meetingInfo;
    }    
    $scope.setMeetingData(<%meetingObj.write(out,2,4);%>);
    
    $scope.setVote = function(fieldName, time, resp, newVal) {
        var isCurrent = ("timeSlots" == fieldName);
        var obj = {action:"SetValue", isCurrent: isCurrent, time: time, user: resp, value:newVal};
        var postURL = "proposedTimes.json?id="+$scope.meeting.id+"&mnm=<% ar.writeURLData(mnm); %>";
        var postdata = angular.toJson(obj);
        $http.post(postURL,postdata)
        .success( function(data) {
            $scope.setMeetingData(data);
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    }    
    $scope.columnStyle = function(user) {
        if (user==$scope.emailId) {
            return {"background-color": 'lightyellow',"text-align":"center"};
        } 
        else {
            return {"background-color": 'white',"text-align":"center"};
        }
    }
});

function calcResponders(slots, curUser) {
    var res = [];
    slots.forEach( function(oneTime) {
        Object.keys(oneTime.people).forEach( function(person) {
            if (res.indexOf(person)<0) {
                res.push(person);
            }
        });
    });
    if (res.indexOf(curUser)<0) {
        res.push(curUser);
    }
    res.sort();
    return res;
}


function reloadIfLoggedIn() {
    if (SLAP.loginInfo.verified) {
        window.location = "<%= ar.getCompleteURL() %>";
    }
}
</script>

</head>

<body>
  <div class="bodyWrapper"  style="margin:50px">


<style>
.spacey tr td {
    padding: 5px 10px;
}
</style>


<%@ include file="AnonNavBar.jsp" %>

<div ng-app="myApp" ng-controller="myCtrl">

    <div class="page-name">
        <h1 id="mainPageTitle" ng-click="infoOpen=!infoOpen"
            title="This is the title of the discussion topic that all these topics are attached to">
            Meeting: {{meeting.name}} <i class="fa fa-caret-square-o-down"></i>
        </h1>
    </div>
    <div>
        <div ng_bind-html="descriptionHtml"></div>
    </div>

    <table ng-show="infoOpen" class="table">
    
    </table>

    <div class="comment-outer"  ng-show="emailId"
         title="Shows what time slots people might be able to attend.">
      <div ng-click="showTimeSlots=!showTimeSlots">Indicate whether these times would be good for you</div>
      <div class="comment-inner">
          <table class="table">
          <tr>
              <th>Time</th>
              <th style="width:20px;"></th>
              <th ng-repeat="resp in timeSlotResponders" title="{{resp}}"     
                  ng-style="columnStyle(resp)">
                <span class="dropdown" >
                    {{resp|limitTo:6}}
                </span>
              
              </th>
          </tr>
          <tr ng-repeat="time in meeting.timeSlots">
              <td><div ng-click="setProposedTime(time.proposedTime)">{{time.proposedTime |date:"dd-MMM-yyyy HH:mm"}}</div></td>
              <td style="width:20px;"></td>
              <td ng-repeat="resp in timeSlotResponders"   
                  ng-style="columnStyle(resp)">
                 <span class="dropdown">
                    <button class="dropdown-toggle btn votingButton" type="button"  d="menu" style="margin:0px"
                        data-toggle="dropdown"> &nbsp;
                        <span ng-show="time.people[resp]==1" title="very bad time for me" style="color:red;">
                            <span class="fa fa-minus-circle"></span>
                            <span class="fa fa-minus-circle"></span></span>
                        <span ng-show="time.people[resp]==2" title="bad time for me" style="color:red;">
                            <span class="fa fa-minus-circle"></span></span>
                        <span ng-show="time.people[resp]==3" title="don't know" style="color:#eeeeee;">
                            <span class="fa fa-question-circle"></span></span>
                        <span ng-show="time.people[resp]==4" title="ok time for me" style="color:green;">
                            <span class="fa fa-plus-circle"></span></span>
                        <span ng-show="time.people[resp]==5" title="good time for me" style="color:green;">
                            <span class="fa fa-plus-circle"></span>
                            <span class="fa fa-plus-circle"></span></span>
                        &nbsp;
                    </button>
                    <ul class="dropdown-menu" role="menu" aria-labelledby="menu">
                      <li role="presentation">
                          <a role="menuitem" ng-click="setVote('timeSlots', time.proposedTime, resp, 5)">
                          <i class="fa fa-plus-circle" style="color:green"></i>
                          <i class="fa fa-plus-circle" style="color:green"></i>
                          Good Time</a></li>
                      <li role="presentation">
                          <a role="menuitem" ng-click="setVote('timeSlots', time.proposedTime, resp, 4)">
                          <i class="fa fa-plus-circle" style="color:green"></i>
                          OK Time</a></li>
                      <li role="presentation">
                          <a role="menuitem" ng-click="setVote('timeSlots', time.proposedTime, resp, 3)">
                          <i class="fa fa-question-circle" style="color:gray"></i>
                          Unknown</a></li>
                      <li role="presentation">
                          <a role="menuitem" ng-click="setVote('timeSlots', time.proposedTime, resp, 2)">
                          <i class="fa fa-minus-circle" style="color:red"></i>
                          Bad time</a></li>
                      <li role="presentation">
                          <a role="menuitem" ng-click="setVote('timeSlots', time.proposedTime, resp, 1)">
                          <i class="fa fa-minus-circle" style="color:red"></i>
                          <i class="fa fa-minus-circle" style="color:red"></i>
                          Impossible</a></li>
                    </ul>
                </span>
              </td>
          </tr>
          </table>
       </div>
    </div>
        
<br/>
<br/>
<div><i>Login to gain more options.</i></div>
<br/>
<br/>
<br/>

</div>


  </div>
</body>
</html>





