<!-- BEGIN LearningBar.jsp -->
<%
    File learningPathFile    =  ar.getCogInstance().getConfig().getFileFromRoot("learningPath.json");
    UserProfile user = ar.getUserProfile();
    UserPage userPage = user.getUserPage();
    
    JSONArray learningPath = userPage.getLearningPathForUser(wrappedJSP);
    JSONObject learningMode = null;
    for (JSONObject oneLearn : learningPath.getJSONObjectList()) {
        if (oneLearn.getBoolean("done")) {
            continue;
        }
        learningMode = oneLearn;
        break;
    }
    if (learningMode != null) {
%>

<style>
.learningBox {
    width: 1000px;
    background-color: #EEFFEE;
    border: 2px solid springGreen;
    margin-bottom: 30px;
}
.learningTitle {
    font-size: 30px;
    margin: 0px;
    font-weight: 300;
    color: green;
}
.learningInfo {
    width:600px;
    margin: 20px;
    float: left;
}
.learningVideo {
    margin: 20px;
    float: right;
}
</style>
<script>
function setUpLearningMethods($scope) {
    $scope.learningModes = <% learningModes.write(out, 2, 2); %>;
    
    $scope.findLearningMode = function() {
        $scope.learningMode = null;
        $scope.learningModes.forEach(function(item) {
            if (!item.suppress && !$scope.learningMode) {
                $scope.learningMode = item;
            }
        });
    }
    
    $scope.findLearningMode();
    
    $scope.markLearningDone = function() {
        $scope.learningMode.suppress = true;
        $scope.findLearningMode();
    }
}
</script>
<div class="learningBox" ng-show="learningMode">
  <div class="learningInfo">
    <div class="learningTitle">
      Learning Path <button class="btn btn-sm btn-default btn-raised" ng-click="markLearningDone()">Close</button>
      
    </div>
    <div ng-bind-html="learningMode.description|wiki"></div>
    <p>({{learningMode.mode}} )</p>
  </div>
  <div class="learningVideo" ng-show="learningMode.video">
    <a href="https://s06.circleweaver.com/{{learningMode.video}}.html"  target="Tutorials">
           <img src="https://s06.circleweaver.com/tutorial-files/{{learningMode.video}}-thumb.png"
                class="tutorialThumbnail"/>
    </a>
  </div>
  <div style="clear:both"></div>
</div>

<%
    }
    if (ar.isAdmin() || true) {
%>
<div class="learningBox" ng-show="learningMode">
    <button class="btn btn-primary btn-raised">Improve this Learning Path</button>
</div>
<%
    }
%>