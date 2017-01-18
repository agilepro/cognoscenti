<!-- BEGIN SideBar.jsp -->

<!-- Side Bar -->
<nav class="navbar navbar-default navbar-fixed-side sidebar navbar-responsive-collapse" role="navigation">
  <ul>
    <% if(isSiteHeader) { %>
    <li>
      <a href="accountListProjects.htm">Workspaces in Site</a></li>
    <li>
      <a href="SiteAdmin.htm">Site Admin</a></li>
    <li><a href="roleManagement.htm">Roles</a></li>

    <% } else if(!isUserHeader) { %>

    <li><a href="frontPage.htm">Front Page</a></li>
    <li><a href="meetingList.htm">Meetings</a></li>
    <li><a href="notesList.htm">Topics</a></li>
    <li><a href="listAttachments.htm">Documents</a></li>
    <li><a href="goalList.htm">Action Items</a></li>
    <li><a href="decisionList.htm">Decisions</a></li>
    <li><a href="labelList.htm">Labels</a></li>
    <li><a href="roleManagement.htm">Roles</a></li>
    <li><a href="admin.htm">Workspace Admin</a></li>
    <li><a href="personal.htm">Personal</a></li>

    <% } %>
  </ul>
</nav>
<!-- END SideBar.jsp -->
<% out.flush(); %>
