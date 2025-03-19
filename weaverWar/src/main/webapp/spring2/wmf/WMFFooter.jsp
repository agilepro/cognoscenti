  <div class="mt-2"></div>
  
  
  <!-- this is mainly for testing pages when logged out -->
  <div style="justify-content: center; display: flex; padding: 20px;">
   <a href="Home.wmf" class="btn btn-secondary btn-wide btn-raised">User Home</a> 
       <a onClick="SLAP.logoutUser()" class="btn btn-wide btn-primary btn-raised">Log Out</a>
    </div>


<div>
  <h2 class="h6">Site Full View Links:</h2>
    <div class="d-flex" >
      
        
    <div class="btn btn-wide btn-comment btn-raised" ng-show="meetId">
       <a href="MeetingHtml.htm?id={{meetId}}" class="text-decoration-none lh-sm">Meeting</a>
    </div>
    <div class="btn btn-wide btn-comment btn-raised">
       <a href="FrontPage.htm" class="text-decoration-none">Workspace</a>
    </div>
    <div class="btn btn-wide btn-comment btn-raised">
       <a href="https://s06.circleweaver.com/" class="text-decoration-none">Weaver.com</a>
    </div>
  </div>
  </div>