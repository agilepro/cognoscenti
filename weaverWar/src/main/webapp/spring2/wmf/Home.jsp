<%@page errorPage="/spring2/jsp/error.jsp"
%><%@ include file="/include.jsp"
%><%
    String pageId    = ar.reqParam("pageId");
    String siteId    = ar.reqParam("siteId");
    NGWorkspace ngw  = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngw);
    


    String currentUserId = "";
    if (ar.isLoggedIn()) {
        UserProfile uProf = ar.getUserProfile();
        currentUserId = uProf.getUniversalId();
        String currentUserName = uProf.getName();
    }

%>

<!-- ************************ anon/Reply.jsp ************************ -->
<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal) {

    $scope.PickMeeting = function() {
        window.location.href = 'PickMeeting.wmf';
    }
    $scope.PickTask = function() {
        window.location.href = 'PickTask.wmf';
    }
    $scope.PickTopic = function() {
        window.location.href = 'PickTopic.wmf';
    }

});

</script>







<div>

    
    <div class="topper">

  User Home
    </div>
    
    <div class="fullWidth well py-2" ng-click="PickTask()">
        <img src="<%=ar.retPath%>new_assets/assets/navicon/ActionItems.png" class="left my-3">
        <span class="h4"> &nbsp;Action Items</span>

    </div>
    
    
    <div class="fullWidth well py-2" ng-click="PickMeeting()">
        <img src="<%=ar.retPath%>new_assets/assets/navicon/Meeting.png" class="left my-3">
        <span class="h4">
        &nbsp;Select Meeting
        </span>
    </div>
        

    
    <div class="fullWidth well py-2" ng-click="PickTopic()">
        <img src="<%=ar.retPath%>new_assets/assets/navicon/Topics.png" class="left my-3">
        <span class="h4">&nbsp;Select Discussion</span>
    </div>

    

        <div class="fullWidth well py-2">
            <a href="Front.wmf"><img src="<%=ar.retPath%>new_assets/assets/navicon/Workspaces-UserHome.png" class="left my-3"></a>
            <span class="h4">&nbsp;Workspace Home</span>
        </div>
    </div>




