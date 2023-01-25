<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%
    String pageId    = ar.reqParam("pageId");
    String siteId    = ar.reqParam("siteId");
    String meetId    = ar.defParam("meetId", "");
    String cmtId    = ar.reqParam("cmtId");
    NGWorkspace ngw  = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngw);
    
    String currentUserId = "";
    if (ar.isLoggedIn()) {
        UserProfile uProf = ar.getUserProfile();
        currentUserId = uProf.getUniversalId();
    }
   

%>

<!-- ************************ wmf/{PickMeetomg/jsp ************************ -->
<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal) {
    
    $scope.workspaceName = "<% ar.writeJS(ngw.getFullName()); %>";
    $scope.meetId = "<% ar.writeJS(meetId); %>";
    $scope.currentUserId = "<% ar.writeJS(currentUserId); %>";
    if ($scope.meetId) {
        localStorage.setItem("meetId", $scope.meetId);
        console.log("STORED meeting to local storage: ("+$scope.meetId+")");
    }
    else {
        $scope.meetId = localStorage.getItem("meetId");
        console.log("RETRIEVED meeting from local storage: ("+$scope.meetId+")");
    }
    $scope.cmtId = "<% ar.writeJS(cmtId); %>";
    $scope.meeting = {};
    $scope.comment = {};

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
    $scope.getCommentInfo = function() {
        var postURL = "getComment.json?cid="+$scope.cmtId;
        $http.get(postURL)
        .success( function(data) {
            setCommentData(data);
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };
    $scope.updateCommentInfo = function(cmtObj) {
        console.log("SAVE COMMENT: ", cmtObj);
        var postURL = "updateComment.json?cid="+$scope.cmtId;
        var postBody = angular.toJson(cmtObj);
        $http.post(postURL, postBody)
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
        console.log("ONWER: ",$scope.comment.user, $scope.currentUserId,
                    $scope.comment.user == $scope.currentUser());
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
        if (!val) {
            return val;
        }
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
    
    $scope.startEditComment = function() {
        $scope.textComment = $scope.comment.body;
        $scope.editMode = "comment";
    }    
    $scope.startEditAnswer = function() {
        var thisUser = $scope.currentUser();
        if (!thisUser) {
            alert("You must be logged in to edit an answer");
            return;
        }
        console.log("User is ", thisUser);
        $scope.textAnswer = "";
        $scope.comment.responses.forEach( function(item) {
            if (item.user == thisUser) {
                $scope.textAnswer = item.body;
            }
        });
        $scope.editMode = "answer";
    }    
    $scope.saveComment = function() {
        var cmtObj = {body: $scope.textComment};
        $scope.editMode = "";
        $scope.updateCommentInfo(cmtObj);
    }    
    $scope.saveAnswer = function(choice) {
        var responseObj = {
            user: $scope.currentUserId,  
            body: $scope.textAnswer,
            choice: choice
        };
        var cmtObj = {responses: [responseObj]};
        $scope.updateCommentInfo(cmtObj);
        $scope.editMode = "";
    }
    $scope.currentUser = function() {
        return $scope.currentUserId;
    }

});

</script>


<div>

    
    <div class="topper">
    {{workspaceName}}
    </div>
    <div class="grayBox">
        <div class="infoBox" ng-show="meetId">
        <a href="RunMeeting.wmf?meetId={{meeting.id}}">
          <span class="fa fa-gavel"></span> {{meeting.name}}</a>
        </div>
        <div class="infoBoxSm" ng-show="meetId">
        {{meeting.startTime|pdate}}
        </div>
        <div class="infoBoxSm">
        <span class="fa {{getIcon(comment)}}"></span> {{trimit(comment.body)}}
        </div>
    </div>
    

    <div ng-show="editMode=='comment'">
        <div><textarea ng-model="textComment" class="textEditor"></textarea></div>
        <div class="smallButton"  ng-click="saveComment()">
           Save Comment
        </div>
    </div>
 
    <div ng-show="editMode=='answer'">
        <div><textarea ng-model="textAnswer" class="textEditor"></textarea></div>
        <div class="smallButton"  ng-click="saveAnswer('Save Response')" ng-show="comment.commentType!=2">
           Save Answer
        </div>
        <div class="smallButton"  ng-click="saveAnswer('Consent')" ng-show="comment.commentType==2">
           Consent
        </div>
        <div class="smallButton"  ng-click="saveAnswer('Objection')" ng-show="comment.commentType==2">
           Objection
        </div>
    </div>   
    
    <div ng-hide="editMode">
        <div class="smallButton"  ng-click="startEditComment()" 
             ng-show="comment.user == currentUser()">
           Edit Comment
        </div>
        <div class="smallButton"  ng-click="startEditAnswer()" 
             ng-show="comment.commentType>1">
           Your Answer
        </div>  
    </div>
    
    <div class="instruction">
    {{getTypeString(comment)}}:
    </div>
    <div ng-bind-html="comment.body | wiki" class="richTextBox"></div> 
    
    <div ng-repeat="response in comment.responses">
        <div ng-show="(response.choice || response.body) && response.choice!='None'">
            <div class="instruction" ng-show="response.choice=='Save Response'">
                <span class="fa fa-check"></span> {{trimit(response.alt.name, 25)}}
            </div>
            <div class="instruction" ng-show="response.choice=='Consent'">
                <span class="fa fa-plus"></span> {{trimit(response.alt.name, 25)}}:  {{response.choice}}
            </div>
            <div class="instruction" ng-show="response.choice=='Objection'">
                <span class="fa fa-minus"></span> {{trimit(response.alt.name, 25)}}:  {{response.choice}}
            </div>
            <div ng-bind-html="response.body | wiki" class="richTextBox" style="margin-left:25px"></div> 
        </div>
    </div> 
    
    
    <div ng-show="comment.outcome">
        <div class="instruction">
        Outcome:
        </div>
        <div ng-bind-html="comment.outcome | wiki" class="richTextBox"></div> 
    </div>
    
    <div class="instruction">
        Started: {{comment.time | cdate}}<br/>
        Posted: {{comment.postTime | cdate}}<br/>
        Due: {{comment.dueDate | cdate}}
    </div>
    
    <!-- Begin Template Footer -->
    <jsp:include page="WMFFooter.jsp" />
    <!-- End Template Footer -->
</div>



