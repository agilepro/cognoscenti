<!-- BEGIN LearningBar.jsp -->

<style>
.learningBox {
    width: 1000px;
    #background-color: #DBEEF9;
    background-color: white;
    border: 2px solid skyblue;
    margin-bottom: 30px;
    box-shadow: 0 4px 8px 0 rgba(0, 0, 0, 0.2), 0 6px 20px 0 rgba(0, 0, 0, 0.19);
}
.learningTitle {
    font-size: 30px;
    margin: 0px;
    font-weight: 300;
    color: skyblue;
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
.learningButton {
    margin: 20px;
}
</style>


<div class="learningBox" ng-hide="learningMode.done" ng-cloak>
  <div class="learningInfo">
    <div class="learningTitle">
      Learning Path <button class="btn btn-sm btn-default btn-raised" ng-click="toggleLearningDone()">Close</button>
      
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
        <button class="btn btn-warning btn-raised" ng-click="openLearningEditor()">
              Improve this Learning Path</button>
        <span>  <%=wrappedJSP%>  </span>
    </div>
<%
    }
%>
</div>

