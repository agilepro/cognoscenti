<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%
    String pageId    = ar.reqParam("pageId");
    String siteId    = ar.reqParam("siteId");
    String meetId    = ar.reqParam("meetId");
    String cmtId    = ar.reqParam("cmtId");
    NGWorkspace ngw  = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngw);
   

%>

<!-- ************************ wmf/{PickMeetomg/jsp ************************ -->
<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal) {
    
    $scope.workspaceName = "<% ar.writeJS(ngw.getFullName()); %>";
    $scope.meetId = "<% ar.writeJS(meetId); %>";
    $scope.cmtId = "<% ar.writeJS(cmtId); %>";
    $scope.meeting = {};
    $scope.comment = {};

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
    $scope.getCommentInfo = function() {
        var postURL = "info/comment?cid="+$scope.cmtId;
        $http.get(postURL)
        .success( function(data) {
            setCommentData(data);
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };
    $scope.getMeetingInfo();
    $scope.getCommentInfo();
    
    
    
    function setMeetingData(data) {
        Object.keys(data.people).forEach( function(key) {
            data.people[key].notAttended = !data.people[key].attended;
        });
        $scope.meeting = data;
        $scope.agendaItem = {};
        data.agenda.forEach( function(item) {
            if (item.id == $scope.itemId) {
                $scope.agendaItem = item;
                item.descriptionHtml = convertMarkdownToHtml(item.description);
                item.minutesHtml = convertMarkdownToHtml(item.minutes);
                console.log("RECEIVED", item);
            }
        });
        
    }    
    function setCommentData(data) {
        $scope.comment = data;
        $scope.comment.bodyHtml = convertMarkdownToHtml(data.body);
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
    $scope.getTypeString  = function(comment) {
        if (comment.commentType==2) {
            return "Proposal";
        }
        if (comment.commentType==3) {
            return "Question";
        }
        return "Comment";
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
        <span class="fa {{getIcon(comment)}}"></span> {{trimit(comment.body)}}
        </div>
    </div>
    

    
    <div class="instruction">
    {{getTypeString(comment)}}:
    </div>
    <div ng-bind-html="comment.body | wiki" class="richTextBox"></div> 
    
    <div ng-repeat="response in comment.responses">
        <div ng-show="(response.choice || response.body) && response.choice!='None'">
            <div class="subItemStyle">
            <span class="fa fa-check"></span> {{trimit(response.alt.name, 25)}}:  {{response.choice}}
            </div>
            <div ng-bind-html="response.body | wiki" class="richTextBox" style="margin-left:25px;color:red"></div> 
        </div>
    </div> 
    
    
    <div ng-show="comment.outcome">
        <div class="instruction">
        Outcome:
        </div>
        <div ng-bind-html="comment.outcome | wiki" class="richTextBox"></div> 
    </div>
    
    <div class="notFinished">
    This page is not completed yet!
    </div>


    
</div>



