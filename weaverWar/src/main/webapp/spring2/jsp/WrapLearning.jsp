<!-- BEGIN LearningBar.jsp -->




<div class="learningBox" ng-hide="learningMode.done" ng-cloak>
  <div class="learningInfo">
    <div class="h5">
      Learning Path 
      
    </div>
    <div ng-bind-html="learningMode.description|wiki"></div>
  </div>
  <div class="learningVideo" ng-show="learningMode.video">
    <div ng-repeat="vidname in learningMode.video.split(',')" style="margin-bottom:15px">
      <a href="https://s06.circleweaver.com/{{vidname.trim()}}.html"  target="Tutorials">
        <img src="https://s06.circleweaver.com/tutorial-files/{{vidname.trim()}}-thumb.png"
             class="tutorialThumbnail"/>
      </a>
      
    </div>
    
    <hr/>
  </div>
  <div style="clear:both"></div>

<%
    if (ar.isSuperAdmin()) {
%>
    <div class="learningButton">
        <button class="btn btn-secondary btn-wide btn-raised" ng-click="openLearningEditor()">
              Improve this Learning Path</button>
        <span class="h6">  <%=wrappedJSP%>  </span>
        <span class="float-end"><button class="learningBtn btn-wide btn-raised me-5" ng-click="toggleLearningDone()">Close</button></span>
    </div>
<%
    }
%>
</div>

