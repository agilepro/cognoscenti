<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%
    String pageId    = ar.reqParam("pageId");
    String siteId    = ar.reqParam("siteId");
    String meetId    = ar.defParam("meetId", "");
    String topicId    = ar.reqParam("topicId");
    NGWorkspace ngw  = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngw);
   

%>

<!-- ************************ wmf/{PickMeetomg/jsp ************************ -->
<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal) {
    
    $scope.workspaceName = "<% ar.writeJS(ngw.getFullName()); %>";
    $scope.meetId = "<% ar.writeJS(meetId); %>";
    if ($scope.meetId) {
        localStorage.setItem("meetId", $scope.meetId);
        console.log("STORED meeting to local storage: ("+$scope.meetId+")");
    }
    else {
        $scope.meetId = localStorage.getItem("meetId");
        console.log("RETRIEVED meeting from local storage: ("+$scope.meetId+")");
    }
    $scope.topicId = "<% ar.writeJS(topicId); %>";
    $scope.meeting = {};
    $scope.topic = {};

    $scope.getMeetingInfo = function() {
        if (!$scope.meetId) {
            return;
        }
        var postURL = "meetingRead.json?id="+$scope.meetId;
        $http.get(postURL)
        .success( function(data) {
            setMeetingData(data);
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };
    $scope.getTopicInfo = function() {
        var postURL = "getTopic.json?nid="+$scope.topicId;
        $http.get(postURL)
        .success( function(data) {
            console.log("getTopicInfo", data.comments);
            setTopicData(data);
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };
    $scope.getMeetingInfo();
    $scope.getTopicInfo();
    
    
    
    function setMeetingData(data) {
        Object.keys(data.people).forEach( function(key) {
            data.people[key].notAttended = !data.people[key].attended;
        });
        $scope.meeting = data;
        
    }    
    function setTopicData(data) {
        $scope.topic = data;
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
    }
    $scope.getNid = function(uid) {
        var pos = uid.lastIndexOf("@");
        return uid.substring(pos+1);
    }
    $scope.trimit  = function(val) {
        if (!val) {
            return "- noname -";
        }
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
        if (comment.commentType>3) {
            return "fa-arrow-right";
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
        <div class="infoBox" ng-show="{{meetId}}">
            <a href="RunMeeting.wmf?meetId={{meeting.id}}">
              <span class="fa fa-gavel"></span> {{meeting.name}}</a>
        </div>
        <div class="infoBoxSm" ng-show="{{meetId}}">
        {{meeting.startTime|pdate}}
        </div>
        <div class="infoBoxSm">
        <span class="fa fa-lightbulb-o"></span> {{topic.subject}}
        </div>
    </div>
    

    
    <div class="instruction">
    Description:
    </div>
    <div ng-bind-html="topic.wiki | wiki" class="richTextBox"></div> 
    
    <div class="instruction">
    Links:
    </div>  
      <div class="subItemStyle" ng-repeat="att in topic.docList">
        <a href="DocView.wmf?meetId={{meeting.id}}&docId={{getNid(att)}}">
          <span class="fa fa-file-o"></span> {{getNid(att)}}</a>
        <a href="DocView.wmf?meetId={{meeting.id}}&docId={{getNid(att)}}">
          <span class="fa fa-file-o"></span> {{getNid(att)}}</a>
      </div>
      <div class="subItemStyle" ng-repeat="comment in topic.comments">
        <div ng-show="comment.body">
          <a href="CmtView.wmf?meetId={{meeting.id}}&cmtId={{comment.time}}">
            <span class="fa {{getIcon(comment)}}"></span> {{trimit(comment.body)}}</a>
        </div>
      </div>
    
    
    
    <!-- Begin Template Footer -->
    <jsp:include page="WMFFooter.jsp" />
    <!-- End Template Footer -->
</div>



