<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/include.jsp"
%><%
    String pageId    = ar.reqParam("pageId");
    String siteId    = ar.reqParam("siteId");
    NGWorkspace ngw  = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngw);
    


%>

<!-- ************************ anon/Reply.jsp ************************ -->
<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal) {

    $scope.PickMeeting = function() {
        window.location.href = 'PickMeeting.wmf';
    }

});

</script>







<div>

    
    <div class="topper">
    <%=ngw.getFullName()%>
    </div>
    
    <div class="fullWidth">
        <img src="<%=ar.retPath%>bits/agenda-icon.png" class="centered">
        <div class="topper">
        Create Agenda
        </div>
    </div>
    
    
    <div class="fullWidth" ng-click="PickMeeting()">
        <img src="<%=ar.retPath%>bits/meeting-icon-big.png" class="centered">
        <div class="topper" ng-click="PickMeeting()">
        Begin Meeting
        </div>
    </div>
        
    <div class="fullWidth">
        <img src="<%=ar.retPath%>bits/meeting-icon-mid.png" class="centered">
        <div class="topper">
        Past Meetings
        </div>
    </div>
    
    <div class="fullWidth">
        <img src="<%=ar.retPath%>bits/discussion-icon-mid.png" class="centered">
        <div class="topper">
        Discussions
        </div>
    </div>
    
    
</div>



