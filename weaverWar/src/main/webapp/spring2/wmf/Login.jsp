<%@ include file="/include.jsp"
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
    
    $scope.workspaceName = "<% ar.writeJS(ngw.getFullName()); %>";
    $scope.meeting = {}; 


    $scope.reportError = function(data) {
        console.log("ERROR: ", data);
    }
});

</script>


<div>

    
    <div class="topper">
    {{workspaceName}}
    </div>
    <div class="grayBox">
        <div class="infoBox"> Login </div>

    </div>
    
    <div>
    You will need to log in to see the information.
    </div>
    <div  style="margin:50px">
      <div class="btn btn-default btn-comment btn-raised">
         <a onClick="SLAP.loginUserRedirect()" class="text-decoration-none">Go To Login</a>
      </div>
    </div>  

    <!-- Begin Template Footer -->
    <jsp:include page="WMFFooter.jsp" />
    <!-- End Template Footer -->

</div>



