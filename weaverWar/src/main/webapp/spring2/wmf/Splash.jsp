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

    $scope.logMeIn = function() {
        console.log("go to home");
        window.location.href = 'Front.wmf';
    }

});

</script>







<div class="container">

    
    <div class="justify-content-center">
    <img src="<%=ar.retPath%>bits/big-weaver.png">
    </div>
    
    <h1 class="big-weaver text-center bold">
    Weaver
    </h1>
    <div class="text-center">
    <h2>Meeting Facilitation Tool</h2>
    </div>
    <div class="well dropdown">
        <label for="workspace" class="h5">Select Workspace:</label>
    <select ng-model="workspace" class="form-control" style="border-radius: 5px;"><option><%=ngw.getFullName()%></option></select>

    </div>
    <h3>Select:</h3>
    <div class="my-3 h5 ms-4">
    <input type="checkbox" > Participant
    </div>
    
    <div class="my-3 h5 ms-4">
    <input type="checkbox"> Administrative
    </div>
    
    <div class="my-3" style="justify-content: center; display: flex;">
    <button class="btn btn-primary btn-default btn-raised centered" ng-click="logMeIn()">Login</button>
    </div>
    
    
</div>



