<%@ include file="/include.jsp"
%><%
    String pageId    = ar.reqParam("pageId");
    String siteId    = ar.reqParam("siteId");
    NGWorkspace ngw  = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngw);
    JSONObject workspaceConf = ngw.getConfigJSON();

%>

<!-- ************************ wmf/{PickMeetomg/jsp ************************ -->
<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal) {
    
    $scope.workspaceName = "<% ar.writeJS(ngw.getFullName()); %>";
    $scope.workspaceConf = <% workspaceConf.write(out, 2, 0); %>;
    $scope.meeting = {}; 


});

</script>


<div>

    
    <div class="topper">
    {{workspaceName}}
    </div>
    <div class="grayBox mb-3">
        <div class="infoBox my-4"> Workspace Front Page </div>

    </div>
    
    <div class="fullWidth my-4">
        <a href="PickMeeting.wmf"><img src="<%=ar.retPath%>new_assets/assets/navicon/Meeting.png" class="centered text-decoration-none">
        <div class="h4 text-center" >
            List Meetings
        </div></a>
    </div>
    <div class="fullWidth my-4">
        <a href="PickTopic.wmf"><img src="<%=ar.retPath%>new_assets/assets/navicon/Topics.png" class="centered text-decoration-none">
        <div class="h4 text-center" >
            List Topics</div></a>
    </div>
    <div class="fullWidth my-4">
        <a href="PickDocument.wmf"><img src="<%=ar.retPath%>new_assets/assets/navicon/Documents.png" class="centered text-decoration-none" >
        <div class="h4 text-center" >
    List Documents</div></a>
    </div>
<div class="fullWidth my-4">
    <a href="PickTask.wmf"><img src="<%=ar.retPath%>new_assets/assets/navicon/ActionItems.png" class="centered text-decoration-none" >
    <div class="h4 text-center" >
    List Action Items
    </div>    </a>
</div>
    <!-- Begin Template Footer -->
    <jsp:include page="WMFFooter.jsp" />
    <!-- End Template Footer -->

</div>



