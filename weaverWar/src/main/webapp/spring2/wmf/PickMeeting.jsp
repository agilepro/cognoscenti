<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/include.jsp"
%><%
    String pageId    = ar.reqParam("pageId");
    String siteId    = ar.reqParam("siteId");
    NGWorkspace ngw  = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngw);
   

%>

<!-- ************************ wmf/{PickMeetomg/jsp ************************ -->
<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal) {

    
    $scope.reportError = function(data) {
        console.log("ERROR: ", data);
    }
    
    $scope.getMeetingList = function() {
        var postURL = "meetingList.json";
        $http.get(postURL)
        .success( function(data) {
            $scope.meetings = data.meetings;
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };
    $scope.getMeetingList();

});

</script>


<div>

    
    <div class="topper">
    <%=ngw.getFullName()%>
    </div>
    
    <div class="instruction ms-3">
    Select a meeting:
    </div>
    
    <div ng-repeat="meet in meetings" class="my-3 border border-1 border-dark rounded btn-raised">
      <div class="listItemStyle">
        <a class="fs-5 bold text-wrap text-decoration-none ms-2" href="RunMeeting.wmf?meetId={{meet.id}}">
            <span class="fa fa-gavel"></span>&nbsp;{{meet.name}}
        </a>
      
      <span class="bold fs-6 float-end lh-lg">
        {{meet.startTime|pdate}}
      </span>
    </div>
    </div>




