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
    <div class="grayBox">
        <div class="infoBox"> Workspace Front Page </div>

    </div>
    
    <div>
    <a href="PickMeeting.wmf">List Meetings</a>
    </div>
    <div>
    <a href="PickDocument.wmf">List Documents</a>
    </div>
    <div>
    <a href="PickTopic.wmf">List Topics</a>
    </div>
    <div>
    <a href="PickTask.wmf">List Action Items</a>
    </div>    
    <!-- Begin Template Footer -->
    <jsp:include page="WMFFooter.jsp" />
    <!-- End Template Footer -->

</div>



