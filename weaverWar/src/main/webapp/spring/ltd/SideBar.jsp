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
<nav class="navbar navbar-default navbar-fixed-side sidebar navbar-responsive-collapse" role="navigation">
  <ul>
      <li><a href="LimitedAccess.htm" title="Explains what you can access here.">Limited Access</a></li>
      
      <li><a href="https://s06.circleweaver.com/TutorialList.html" title="Lots of videos on YouTube to help you learn how to use Weaver." target="_blank">Training <i class="fa fa-external-link"></i></a></li>
      
      <li style="color:black">
        <img src="<%=ar.retPath%>assets/LimitIndicator.png" title="You have limited access to some parts of this workspace" 
             style="width:30px;width:30px;margin-left:20px"/>
      </li>
    
  </ul>

</nav>
<!-- END SideBar.jsp -->
<% out.flush(); %>
