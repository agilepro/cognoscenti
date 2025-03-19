<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/include.jsp"
%><%
    String pageId    = ar.reqParam("pageId");
    String siteId    = ar.reqParam("siteId");
    String taskId    = ar.reqParam("taskId");
    NGWorkspace ngw  = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngw);
   

%>

<!-- ************************ wmf/{PickMeetomg/jsp ************************ -->
<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal) {
    
    $scope.workspaceName = "<% ar.writeJS(ngw.getFullName()); %>";

    
    $scope.reportError = function(data) {
        console.log("ERROR: ", data);
    }

});

</script>


<div>

    
    <div class="topper">
    {{workspaceName}}
    </div>
    <div>
    Show the Action Item Here
    </div>
    




