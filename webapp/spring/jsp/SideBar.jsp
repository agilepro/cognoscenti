<!-- BEGIN SideBar.jsp -->

<!-- Side Bar -->
<nav class="navbar navbar-default navbar-fixed-side sidebar navbar-responsive-collapse" role="navigation">
  <ul>
    <% if(isSiteHeader) { %>
    <li<%if("Workspaces in Site".equals(jspName)){%> class="active"<%}%>>
      <a href="accountListProjects.htm">Workspaces in Site</a></li>
    <li<%if("Site Admin".equals(jspName)){%> class="active"<%}%>>
      <a href="SiteAdmin.htm">Site Admin</a></li>
    <li><a href="roleManagement.htm">Roles</a></li>

    <% } else if(!isUserHeader) { %>

    <li<%if("Front Page".equals(jspName)){%> class="active"<%}%>><a href="frontPage.htm">Front Page</a></li>
    <li<%if("Meetings".equals(jspName)){%> class="active"<%}%>><a href="meetingList.htm">Meetings</a></li>
    <li<%if("Topics".equals(jspName)){%> class="active"<%}%>><a href="notesList.htm">Topics</a></li>
    <li<%if("Documents".equals(jspName)){%> class="active"<%}%>><a href="listAttachments.htm">Documents</a></li>
    <li<%if("Action Items".equals(jspName)){%> class="active"<%}%>><a href="goalList.htm">Action Items</a></li>
    <li<%if("Decisions".equals(jspName)){%> class="active"<%}%>><a href="decisionList.htm">Decisions</a></li>
    <li<%if("Labels".equals(jspName)){%> class="active"<%}%>><a href="labelList.htm">Labels</a></li>
    <li<%if("Roles".equals(jspName)){%> class="active"<%}%>><a href="roleManagement.htm">Roles</a></li>
    <li<%if("Workspace Admin".equals(jspName)){%> class="active"<%}%>><a href="admin.htm">Workspace Admin</a></li>
    <li<%if("Personal".equals(jspName)){%> class="active"<%}%>><a href="personal.htm">Personal</a></li>

    <% } %>
  </ul>
</nav>
<!-- END SideBar.jsp -->
<% out.flush(); %>
