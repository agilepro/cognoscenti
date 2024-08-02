<!-- BEGIN SideBar.jsp -->
<%!
    public static JSONObject allMenu = new JSONObject();
    
    public static boolean hasString(JSONObject cont, String fieldName, String value) throws Exception {
        for (String test : cont.getJSONArray(fieldName).getStringList()) {
            if (value.equals(test)) {
                return true;
            }
        }
        return false;
    }
    public static JSONArray getOptions(JSONObject cont, String value) throws Exception {
        JSONArray res = new JSONArray();
        if (cont.has("opts")) {
            for (JSONObject entry : cont.getJSONArray("opts").getJSONObjectList()) {
                if (hasString(entry, "use", value)) {
                    res.put(entry);
                }
            }
        }
        return res;
    }

%>
<%
    String thisPageName = "MeetingList.htm";
    
    
    
    
    File menuFile = ar.getCogInstance().getConfig().getFileFromRoot("MenuTree.json");
    allMenu = JSONObject.readFromFile(menuFile);
    
    JSONArray fullMenu = new JSONArray();
    
    if(isSiteHeader) {
        fullMenu.addAll(allMenu.getJSONArray("siteMode"));
    }
    else if(!isUserHeader) {
        fullMenu.addAll(allMenu.getJSONArray("workMode"));
    }
    fullMenu.addAll(allMenu.getJSONArray("allModes"));
    
%>

<!-- Side Bar -->
<nav class="sidebar">
    <div class="container-fluid min-vh-100 sidebar">
        <ul class="sidebar-nav list-unstyled py-2">


      <li class="nav-item dropdown"><a class="nav-link dropdown p-1"  href="LimitedAccess.htm" title="Explains what you can access here.">Guest Access</a></li>
      
      <li class="nav-item dropdown"><a class="nav-link dropdown p-1" href="https://s06.circleweaver.com/TutorialList.html" title="Lots of videos on YouTube to help you learn how to use Weaver." target="_blank">Training <i class="fa fa-external-link"></i></a></li>
      
      <li class="nav-item dropdown">
        <img src="<%=ar.retPath%>assets/LimitIndicator.png" title="You have limited access to some parts of this workspace" 
             class="accessIndicator"/>
      </li>
    
  </ul>

    </div>

</nav>
<!-- END SideBar.jsp -->
<% out.flush(); %>
