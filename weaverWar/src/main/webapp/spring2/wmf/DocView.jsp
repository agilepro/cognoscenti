<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/include.jsp"
%><%
    String pageId    = ar.reqParam("pageId");
    String siteId    = ar.reqParam("siteId");
    String meetId    = ar.defParam("meetId", "");
    String docId    = ar.reqParam("docId");
    NGWorkspace ngw  = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngw);
   

%>

<!-- ************************ wmf/{PickMeetomg/jsp ************************ -->
<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal) {
    
    $scope.workspaceName = "<% ar.writeJS(ngw.getFullName()); %>";
    $scope.meetId = "<% ar.writeJS(meetId); %>";
    $scope.docId = "<% ar.writeJS(docId); %>";
    $scope.document = {};
    if ($scope.meetId) {
        localStorage.setItem("meetId", $scope.meetId);
        console.log("STORED meeting to local storage: ("+$scope.meetId+")");
    }
    else {
        $scope.meetId = localStorage.getItem("meetId");
        console.log("RETRIEVED meeting from local storage: ("+$scope.meetId+")");
    }
    $scope.meeting = {};
    $scope.document = {};

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
    $scope.getDocInfo = function() {
        var postURL = "docInfo.json?did="+$scope.docId;
        $http.get(postURL)
        .success( function(data) {
            setDocumentData(data);
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };
    $scope.getMeetingInfo();
    $scope.getDocInfo();
    
    
    
    function setMeetingData(data) {
        Object.keys(data.people).forEach( function(key) {
            data.people[key].notAttended = !data.people[key].attended;
        });
        $scope.meeting = data;
    }    
    function setDocumentData(data) {
        $scope.document = data;
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
    
    $scope.downloadDocument = function(doc) {
        if (doc.attType=='URL') {
             window.open(doc.url,"_blank");
        }
        else {
            window.open("a/"+doc.name,"_blank");
        }
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
        <div class="infoBox" ng-show="meetId">
        {{meeting.startTime|pdate}}
        </div>
        <div class="infoBox">
        <span class="fa fa-file-o"></span> {{document.name}}
        </div>
    </div>
    
    <div class="mt-3">
        <div class="btn btn-primary btn-group-raised"  ng-click="downloadDocument(document)"
             ng-show="document.attType == 'FILE'">
           Download Document
        </div>
        <div class="btn btn-secondary btn-raised"  ng-click="downloadDocument(document)"
             ng-show="document.attType != 'FILE'">
           Visit Link
        </div>  
    </div>

    
    <div class="instruction">
    Description:
    </div>
    <div ng-bind-html="document.description | wiki" class="richTextBox"></div> 
    
    <div class="instruction">
    Links:
    </div>
      <div class="subItemStyle" ng-repeat="comment in document.comments">
        <a href="CmtView.wmf?meetId={{meeting.id}}&cmtId={{comment.time}}">
          <span class="fa {{getIcon(comment)}}"></span> {{trimit(comment.body)}}</a>
      </div>
    
    <!-- Begin Template Footer -->
    <jsp:include page="WMFFooter.jsp" />
    <!-- End Template Footer -->
    
</div>



