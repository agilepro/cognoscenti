<%  
    String meetId = request.getParameter("meetId"); 
    String topicId = request.getParameter("topicId"); 
%>
  
  <div class="mt-2"></div>
  
  
  <!-- this is mainly for testing pages when logged out -->
  <div style="justify-content: center; display: flex; padding: 20px;">
   <a href="Home.wmf" class="btn btn-secondary btn-wide btn-raised">User Home</a> 
       <a onClick="SLAP.logoutUser()" class="btn btn-wide btn-primary btn-raised">Log Out</a>
    </div>


<div>
    <h2 class="h6">Site Full View Links:</h2>
    <div class="d-flex" >
        
        <% if (topicId!=null) { %>
        <div class="btn btn-wide btn-comment btn-raised"
                onclick="location.href='noteZoom<%=topicId%>.htm'">
           Topic
        </div>
        <% } else if (meetId!=null) { %>
        <div class="btn btn-wide btn-comment btn-raised"
                onclick="location.href='MeetingHtml.htm?id=<%=meetId%>'">
           Meeting
        </div>
        <% } %>
        <div class="btn btn-wide btn-comment btn-raised" onclick="location.href='FrontPage.htm'">
           Workspace
        </div>
        <div class="btn btn-wide btn-comment btn-raised" onclick="location.href='https://s06.circleweaver.com/'">
           Weaver.com
        </div>
    </div>
</div>