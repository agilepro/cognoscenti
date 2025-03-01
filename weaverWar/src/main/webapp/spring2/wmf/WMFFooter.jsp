  <div class="mt-5"></div>
    <div class="grayBox d-inline-flex p-3">
        
    <div class="btn btn-default btn-comment btn-raised" ng-show="meetId">
       <a href="MeetingHtml.htm?id={{meetId}}" class="text-decoration-none">Full Meeting View</a>
    </div>
    <div class="btn btn-default btn-comment btn-raised">
       <a href="FrontPage.htm" class="text-decoration-none">Front Page View</a>
    </div>
    <div class="btn btn-default btn-comment btn-raised">
       <a href="https://s06.circleweaver.com/" class="text-decoration-none">Learn About Weaver</a>
    </div>
  </div>
  
  <!-- this is mainly for testing pages when logged out -->
  <div  style="margin:50px">
    <div class="btn btn-default btn-comment btn-raised">
       <a onClick="SLAP.logoutUser()" class="text-decoration-none">Log Out</a>
    </div>
  </div>