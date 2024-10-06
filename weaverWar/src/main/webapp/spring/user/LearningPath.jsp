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



<div class="guideVocal">
    These are your learning path steps.  As you close a learning path box on a 
    page of the workspace, that is remembered.  But to see them again, please
    uncheck the boxes below.

    <button ng-click="clearAllLearning()" class="btn btn-primary btn-raised">
        Reset all Learning Path Flags</button>
</div>

<style>
.padded { padding:10px }
.bottomline { border-bottom: 1px solid lightgray; background-color: yellow }
</style>


    <div class="col-xs-12 col-sm-6 col-md-3 padded">
        <b>JSP</b>
    </div>
    <div class="col-xs-12 col-sm-6 col-md-3 padded">
        <b>Mode</b>
    </div>
    <div class="col-xs-12 col-md-6 padded">
        <b>Active</b>
    </div>
    <div class="col-xs-12 col-sm-12 col-md-12 bottomline"></div>

  <div ng-repeat="(jsp, path) in learningPath">
    <div ng-repeat="step in path">
        <div class="col-xs-12 col-sm-6 col-md-3 padded">
            <b>{{jsp}}</b>
        </div>
        <div class="col-xs-12 col-sm-6 col-md-3 padded">
            <b>{{step.mode}}</b> <br/>
            
        </div>
        <div class="col-xs-12 col-md-6 padded">
            <img src="<%=ar.retPath%>bits/sliderOn.png" ng-hide="step.done">
            <img src="<%=ar.retPath%>bits/sliderOff.png" ng-show="step.done">
        </div>
        <div class="col-xs-12 col-sm-12 col-md-12 bottomline">
        </div>
     </div>
  </div>
