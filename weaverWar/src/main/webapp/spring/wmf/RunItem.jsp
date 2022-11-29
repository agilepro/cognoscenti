<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%
    String pageId    = ar.reqParam("pageId");
    String siteId    = ar.reqParam("siteId");
    String meetId    = ar.reqParam("meetId");
    String itemId    = ar.reqParam("itemId");
    NGWorkspace ngw  = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngw);
   

%>

<!-- ************************ wmf/{PickMeetomg/jsp ************************ -->
<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal) {
    
    $scope.workspaceName = "<% ar.writeJS(ngw.getFullName()); %>";
    $scope.meetId = "<% ar.writeJS(meetId); %>";
    $scope.itemId = "<% ar.writeJS(itemId); %>";
    $scope.meeting = {};
    $scope.agendaItem = {};

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
        $scope.agendaItem = {};
        data.agenda.forEach( function(item) {
            if (item.id == $scope.itemId) {
                $scope.agendaItem = item;
                console.log("RECEIVED", item);
            }
        });
        
    }
    

    $scope.setMeetingState = function(stateVal) {
        var meetData = {};
        meetData.state = stateVal;
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
    $scope.trimit  = function(val) {
        if (val.length<40) {
            return val;
        }
        return val.substring(0,40);
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
        <div class="infoBox">
        <span class="fa fa-bullseye"></span> {{agendaItem.subject}}
        </div>
    </div>
    

    
    <div class="instruction">
    Description:
    </div>
    <div ng-bind-html="agendaItem.description | wiki" class="richTextBox"></div> 
    

    <div class="instruction">
    Minutes:
    </div>
    <div ng-bind-html="agendaItem.minutes | wiki" class="richTextBox"></div> 
    
    
    <div class="instruction">
    Links:
    </div>   
      <div class="subItemStyle" ng-repeat="topic in agendaItem.topics">
        <a href="TopicView.wmf?meetId={{meeting.id}}&topicId={{getNid(topic)}}">
          <span class="fa fa-lightbulb-o"></span> {{getNid(topic)}}</a>
      </div>
      <div class="subItemStyle" ng-repeat="att in agendaItem.attList">
        <a href="DocView.wmf?meetId={{meeting.id}}&docId={{att.id}}">
          <span class="fa fa-file-o"></span> {{att.name}}</a>
      </div>
      <div class="subItemStyle" ng-repeat="comment in agendaItem.comments">
        <a href="CmtView.wmf?meetId={{meeting.id}}&cmtId={{comment.time}}">
          <span class="fa {{getIcon(comment)}}"></span> {{trimit(comment.body)}}</a>
      </div>
    
    
    <div class="notFinished">
    This page is not completed yet!
    </div>
</div>



