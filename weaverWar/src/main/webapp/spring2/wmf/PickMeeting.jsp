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
    
    <div class="instruction">
    Choose a meeting from list below:
    </div>
    
    <div ng-repeat="meet in meetings" style="margin:10px;" >
      <div class="listItemStyle">
        <a href="RunMeeting.wmf?meetId={{meet.id}}">
            <span class="fa fa-gavel"></span> {{meet.name}}
        </a>
      </div>
      <div class="subItemStyle">
        {{meet.startTime|pdate}}
      </div>
    </div>
    
    
    <!-- Begin Template Footer -->
    <jsp:include page="WMFFooter.jsp" />
    <!-- End Template Footer -->
</div>



