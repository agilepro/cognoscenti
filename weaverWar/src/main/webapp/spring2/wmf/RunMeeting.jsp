<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/include.jsp"
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
    
    $scope.reportError = function(data) {
        console.log("ERROR: ", data);
    }

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
    
    $scope.browserUI = function() {
        
    }
    

});

</script>


<div>

    
    <div class="topper">
    {{workspaceName}}
    </div>
    <div class="grayBox">
        <div class="infoBox">
        <a href="RunMeeting.wmf?meetId={{meetId}}">
          <span class="fa fa-gavel"></span> {{meeting.name}}</a>
        </div>
        <div class="infoBoxSm">
        {{meeting.startTime|pdate}}
        </div>
    
    </div>
    
    <div class="instruction">
    Agenda:
    </div>
    
    <div ng-repeat="item in meeting.agenda">
      <div class="listItemStyle">
        <a href="RunItem.wmf?meetId={{meetId}}&itemId={{item.id}}">
          <span class="fa fa-thumb-tack"></span> {{item.subject}}</a>
      </div>

      <div class="subItemStyle" ng-repeat="topic in item.topicList">
        <a href="TopicView.wmf?meetId={{meetId}}&topicId={{topic.id}}">
          <span class="fa fa-lightbulb-o"></span> {{topic.subject}}</a>
      </div>
      <div class="subItemStyle" ng-repeat="att in item.attList">
        <a href="DocView.wmf?meetId={{meetId}}&docId={{att.id}}">
          <span class="fa fa-file-o"></span> 
          {{att.name}}</a>
      </div>
      <div class="subItemStyle" ng-repeat="comment in item.comments">
        <a href="CmtView.wmf?meetId={{meetId}}&cmtId={{comment.time}}">
          <span class="fa {{getIcon(comment)}}"></span> {{trimit(comment.body)}}</a>
      </div>
    </div>

    <hr style="margin:20px;color:lightgray"/>
    
    <div class="instruction">
    Reports:
    </div>
      <div class="listItemStyle" >
        <a href="MeetPrint.htm?id={{meetId}}&tem=AgendaDetail.chtml">
          <span class="fa fa-file-o"></span> Agenda Page</a>
      </div>
      <div class="listItemStyle" >
        <a href="MeetPrint.htm?id={{meetId}}&tem=MinutesDetails.chtml">
          <span class="fa fa-file-o"></span> Minutes Page</a>
      </div>      
    

    <hr style="margin:20px;color:lightgray"/>
    
    <div class="grayBox p-2">    
    <table class="table">
    <tr class="h6">
        <td style="max-width:200px">Participant</td>
        <td>P</td>
        <td>A</td>
    </tr>
    <tr ng-repeat="(key, person) in meeting.people" class="fs-6">
    <a href="RunMeeting.wmf?meetid={{person.id}}">
        <td>{{trimit(person.name, 25)}}</td>
        <td><input type="checkbox" ng-model="person.attended" ng-click="setAttended(person)"></td>
        <td><input type="checkbox" ng-model="person.notAttended" ng-click="setNotAttended(person)"></td>
    </a>
    </tr>
    </table>
    </div>




