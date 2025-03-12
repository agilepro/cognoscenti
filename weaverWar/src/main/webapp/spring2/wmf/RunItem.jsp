<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/include.jsp"
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
    $scope.nextItem = null;
    $scope.prevItem = null;
    $scope.meeting = {};
    $scope.agendaItem = {};

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
        $scope.agendaItem = {};
        $scope.prevItem = null;
        $scope.nextItem = null;
        var previousItem =null;
        data.agenda.forEach( function(item) {
            if (previousItem == $scope.itemId) {
                $scope.nextItem = item.id;
            }
            if (item.id == $scope.itemId) {
                $scope.agendaItem = item;
                console.log("RECEIVED", item);
                $scope.prevItem = previousItem;
            }
            previousItem = item.id;
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
        <div class="infoBoxSm">
        {{meeting.startTime|pdate}}
        </div>
        <div class="infoBoxSm" ng-show="agendaItem.isSpacer">
        {{agendaItem.subject}}
        </div>
        
        <div class="d-flex justify-content-between">
            <span class="float:left" style="margin-top: 10px; margin-left:5px;" ng-show="prevItem">
                <a href="RunItem.wmf?meetId={{meeting.id}}&itemId={{prevItem}}">
                    <span class="fa fa-arrow-circle-left fa-2x"></span>
                </a>
            </span>
            <span class="h5 mt-3" ng-hide="agendaItem.isSpacer">
        {{agendaItem.number}} <span class="fa fa-thumb-tack"></span> {{agendaItem.subject}}
        </span>
            <span class="float:right" style="margin-top: 10px; margin-right:5px;" ng-show="nextItem">
                <a href="RunItem.wmf?meetId={{meeting.id}}&itemId={{nextItem}}" aria-label="Next Item">
                    <span class="fa fa-arrow-circle-right fa-2x"></span>
                </a>
            </span>
        </div>
    </div>
    

    <div ng-hide="agendaItem.isSpacer">
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
          <div class="subItemStyle" ng-repeat="topic in agendaItem.topicList">
            <a href="TopicView.wmf?meetId={{meeting.id}}&topicId={{topic.id}}">
              <span class="fa fa-lightbulb-o"></span> {{topic.subject}}</a>
          </div>
          <div class="subItemStyle" ng-repeat="att in agendaItem.attList">
            <a href="DocView.wmf?meetId={{meeting.id}}&docId={{att.id}}">
              <span class="fa fa-file-o"></span> {{att.name}}</a>
          </div>
          <div class="subItemStyle" ng-repeat="comment in agendaItem.comments">
            <a href="CmtView.wmf?meetId={{meeting.id}}&cmtId={{comment.time}}">
              <span class="fa {{getIcon(comment)}}"></span> {{trimit(comment.body)}}</a>
          </div>
        
    </div> 
    
    <!-- Begin Template Footer -->
    <jsp:include page="WMFFooter.jsp" />
    <!-- End Template Footer -->

</div>



