<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%
    String pageId    = ar.reqParam("pageId");
    String siteId    = ar.reqParam("siteId");
    String meetId    = ar.reqParam("meetId");
    NGWorkspace ngw  = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngw);
   

%>

<!-- ************************ wmf/{PickMeetomg/jsp ************************ -->
<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal) {
    
    $scope.workspaceName = "<% ar.writeJS(ngw.getFullName()); %>";
    $scope.meetId = "<% ar.writeJS(meetId); %>";
    $scope.meeting = {};

    $scope.getMeetingInfo = function() {
        var postURL = "meetingRead.json?id="+$scope.meetId;
        $http.get(postURL)
        .success( function(data) {
            setMeetingData(data);
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };
    $scope.getMeetingInfo();
    function setMeetingData(data) {
        Object.keys(data.people).forEach( function(key) {
            data.people[key].notAttended = !data.people[key].attended;
        });
        $scope.meeting = data;
    }
    

    $scope.setMeetingState = function(stateVal) {
        var meetData = {};
        meetData.state = stateVal;
        $scope.saveMeeting(meetData);
    };
    $scope.setAttended = function(person) {
        console.log("PERSON", person);
        var meetData = {};
        meetData.attended_add = person.key;
        $scope.saveMeeting(meetData);
    };
    $scope.setNotAttended = function(person) {
        console.log("PERSON", person);
        var meetData = {};
        meetData.attended_remove = person.key;
        $scope.saveMeeting(meetData);
    };
    $scope.saveMeeting = function(meetData) {
        var postData = angular.toJson(meetData);
        var postURL = "meetingUpdate.json?id="+$scope.meetId;
        $http.post(postURL, postData)
        .success( function(data) {
            setMeetingData(data);
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };
    $scope.getNid = function(uid) {
        var pos = uid.lastIndexOf("@");
        return uid.substring(pos+1);
    }
    $scope.trimit  = function(val, limit) {
        if (!limit) {
            limit = 40;
        }
        if (val.length<limit) {
            return val;
        }
        return val.substring(0,limit);
    }
    $scope.getIcon  = function(comment) {
        if (comment.commentType==2) {
            return "fa-star-o";
        }
        if (comment.commentType==3) {
            return "fa-question-circle";
        }
        return "fa-comments-o";
    }
    

});

</script>


<div>

    
    <div class="topper">
    {{workspaceName}}
    </div>
    <div class="grayBox">
        <div class="infoBox">
        <a href="RunMeeting.wmf?meetId={{meeting.id}}">
          <span class="fa fa-gavel"></span> {{meeting.name}}</a>
        </div>
        <div class="infoBox">
        {{meeting.startTime|pdate}}
        </div>
    
    <table class="table">
    <tr class="listItemStyle">
        <td style="max-width:200px">Participant</td>
        <td>P</td>
        <td>A</td>
    </tr>
    <tr ng-repeat="(key, person) in meeting.people" class="listItemStyle">
    <a href="RunMeeting.wmf?meetid={{person.id}}">
        <td>{{trimit(person.name, 25)}}</td>
        <td><input type="checkbox" ng-model="person.attended" ng-click="setAttended(person)"></td>
        <td><input type="checkbox" ng-model="person.notAttended" ng-click="setNotAttended(person)"></td>
    </a>
    </tr>
    </table>
    
    </div>
    
    <div class="instruction">
    Agenda:
    </div>
    
    <div ng-repeat="item in meeting.agenda">
      <div class="listItemStyle">
        <a href="RunItem.wmf?meetId={{meeting.id}}&itemId={{item.id}}">
          <span class="fa fa-bullseye"></span> {{item.subject}}</a>
      </div>

      <div class="subItemStyle" ng-repeat="topic in item.topicList">
        <a href="TopicView.wmf?meetId={{meeting.id}}&topicId={{topic.id}}">
          <span class="fa fa-lightbulb-o"></span> {{topic.subject}}</a>
      </div>
      <div class="subItemStyle" ng-repeat="att in item.attList">
        <a href="DocView.wmf?meetId={{meeting.id}}&docId={{att.id}}">
          <span class="fa fa-file-o"></span> {{att.name}}</a>
      </div>
      <div class="subItemStyle" ng-repeat="comment in item.comments">
        <a href="CmtView.wmf?meetId={{meeting.id}}&cmtId={{comment.time}}">
          <span class="fa {{getIcon(comment)}}"></span> {{trimit(comment.body)}}</a>
      </div>
    </div>
    
    <div ng-show="meeting.state!=2" class="fullWidth">
      <button class="bigButton" ng-click="setMeetingState(2)">Start Meeting</button>
    </div>
    <div ng-show="meeting.state==2" class="fullWidth">
      <button class="bigButton" ng-click="setMeetingState(3)">Conclude Meeting</button>
    </div>
    
    
    
    <div class="notFinished">
    This page is not completed yet!
    </div>
</div>



