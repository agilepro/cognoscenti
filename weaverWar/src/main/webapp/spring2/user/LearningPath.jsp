<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/include.jsp"
%><%

    UserProfile uProf = (UserProfile)request.getAttribute("userProfile");
    if (uProf == null) {
        throw WeaverException.newBasic("Can not find that user profile to display.");
    }
    
    UserPage uPage = uProf.getUserPage();
    JSONObject lPath = uPage.getUserAllLearning();
    

%>

<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http) {
    window.setMainPageTitle("Notification Settings");
    $scope.learningPath = <%lPath.write(out,2,4);%>;

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };

    $scope.hideNote = false;

    $scope.clearAllLearning = function() {
        var toPost = {}      
        var postdata = angular.toJson(toPost);
        var postURL = "ClearLearningDone.json";
        console.log(postURL,toPost);
        $http.post(postURL, postdata)
        .success( function(data) {
            window.location.reload();
        })
        .error( function(data) {
            errorPanelHandler($scope, data);
        });
    }
});
</script>



<!-- MAIN CONTENT SECTION START -->
<div class="userPageContents">

<%@include file="../jsp/ErrorPanel.jsp"%>


<div class="container override pull-left col-8 ms-4">
    <div class="row well mb-3">
        <span class="h6 col-8 ms-3 guideVocal">
            These are your learning path steps.  As you close a learning path box on a 
            page of the workspace, that is remembered.  But to see them again, please
            uncheck the boxes below.</span>

    <button ng-click="clearAllLearning()" class="col-3 btn btn-primary btn-raised">
        Reset all Learning Path Flags</button>
    </div>

    <div class="row ms-5 mt-3">
        <span class="col-xs-12 col-sm-6 col-md-3 h5">
        <b>JSP</b>
        </span>
        <span class="col-xs-12 col-sm-6 col-md-3 h5">
        <b>Mode</b>
        </span>
        <span class="col-xs-12 col-md-6 h5">
        <b>Active</b>
        </span>
        <span class="col-xs-12 col-sm-12 col-md-12 border-bottom border-2"></span>
    </div>
    <div class="row ms-5">

        <div ng-repeat="(jsp, path) in learningPath">
            <div class="row border-bottom border-1 py-3" ng-repeat="step in path">
                <span class="col-3 ">
            <b>{{jsp}}</b>
                </span>
                <span class="col-3 ">
            <b>{{step.mode}}</b> <br/>
            
                </span>
                <span class="col-6 ">
            <img src="<%=ar.retPath%>bits/sliderOn.png" ng-hide="step.done">
            <img src="<%=ar.retPath%>bits/sliderOff.png" ng-show="step.done">
                </span>
            </div>    
            
        </div>
     </div>
  </div>
