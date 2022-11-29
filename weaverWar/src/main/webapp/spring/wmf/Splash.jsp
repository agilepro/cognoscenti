<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
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
        window.location.href = 'Home.wmf';
    }

});

</script>







<div>

    
    <div style="margin:auto">
    <img src="<%=ar.retPath%>bits/big-weaver.png">
    </div>
    
    <div class="big-weaver">
    Weaver
    </div>
    
    <select ng-model="workspace"><option><%=ngw.getFullName()%></option><select>
    
    <div>
    <input type="checkbox"> Participant
    </div>
    
    <div>
    <input type="checkbox"> Administrative
    </div>
    
    <div>
    <button class="btn btn-primary" ng-click="logMeIn()">Login</button>
    </div>
    
    
</div>



