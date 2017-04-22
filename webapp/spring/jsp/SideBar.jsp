<!-- BEGIN SideBar.jsp -->

<!-- Side Bar -->
<nav class="navbar navbar-default navbar-fixed-side sidebar navbar-responsive-collapse" role="navigation">
  <ul>
    <% if(isSiteHeader) { %>
    <li>
      <a href="accountListProjects.htm" title="Lists all the workspaces that are in this site.">
          Workspaces in Site</a></li>
    <li>
      <a href="SiteAdmin.htm" title="View and adjust the main settings for the site.">
          Site Admin</a></li>
    <li>
      <a href="roleManagement.htm" title="Role define who can do what within this site.">
          Roles</a></li>

    <% } else if(!isUserHeader) { %>

    <li><a href="frontPage.htm" title="Get the main overview of the workspace and recent changes">
        Front Page</a></li>
    <li><a href="meetingList.htm" title="List and manage all the meetings in this workspace">
        Meetings</a></li>
    <li><a href="notesList.htm" title="List and manage the discussions in the workspace.">
        Topics</a></li>
    <li><a href="listAttachments.htm" title="List and access all the attached documents in the workspace.">
        Documents</a></li>
    <li><a href="goalList.htm" title="List and update all the action items in the workspace, current and historical">
        Action Items</a></li>
    <li><a href="decisionList.htm" title="Each workspace has a list of decisions that have been made over time.">
        Decisions</a></li>
    <li><a href="labelList.htm" title="Labels can be defined to help categorize documents, discussions, and action items.">
        Labels</a></li>
    <li><a href="roleManagement.htm" title="Roles define who is able to what in this workspace">
        Roles</a></li>
    <li><a href="admin.htm" title="See and adjust all the settings for this workspace if you are in the administrator role">
        Admin</a></li>
    <li><a href="personal.htm" title="See your own settings that are unique to this workspace">
        Personal</a></li>

    <% } %>
  </ul>
</nav>
<!-- END SideBar.jsp -->
<% out.flush(); %>
