<!-- BEGIN LearningBar.jsp -->


<div class="learningBox override" ng-cloak>
  <div class="learningInfo">

    <div class="modal-body d-flex">
    <div ng-bind-html="learningMode.description|wiki"></div>
  
  <div class="learningVideo" ng-show="learningMode.video">
    <div ng-repeat="vidname in learningMode.video.split(',')" style="margin-bottom:15px">
      <a href="https://s06.circleweaver.com/{{vidname.trim()}}.html"  target="Tutorials">
        <img src="https://s06.circleweaver.com/tutorial-files/{{vidname.trim()}}-thumb.png"
             class="tutorialThumbnail"/>
      </a>

    </div>
 

  </div>        

  <div style="clear:both"></div>
</div>             
<!--<button class="btn btn-comment btn-raised mx-3" ng-click="toggleLearningDone()">Remove Learning Path</button>-->
<%
    if (ar.isSuperAdmin()) {
%>
    <div class="superAdminOnly learningButton" >
        <button class="btn btn-danger btn-wide btn-raised superAdminOnly" ng-click="openLearningEditor()">
              Improve this Learning Path FF</button>
        <span class="h6 superAdminOnly">  <%=wrappedJSP%>  </span>

    </div>
<%
    }
%>
</div>
</div>
