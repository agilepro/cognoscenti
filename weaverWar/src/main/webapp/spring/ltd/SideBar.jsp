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
    
    boolean userIsReadOnly = false;
    if (site!=null) {
        userIsReadOnly = ar.isReadOnly(); 
    }
    else if (ngp!=null) {
        //userIsReadOnly = ngp.getSite().userReadOnly(ar.getBestUserId());
    }
%>

<!-- Side Bar -->
<nav class="navbar navbar-default navbar-fixed-side sidebar navbar-responsive-collapse" role="navigation">
  <ul>
      <li><a href="LimitedAccess.htm" title="Explains what you can access here.">Limited Access</a></li>
      
      <li><a href="https://s06.circleweaver.com/TutorialList.html" title="Lots of videos on YouTube to help you learn how to use Weaver." target="_blank">Training <i class="fa fa-external-link"></i></a></li>
      
      <li style="color:black">  <% if (userIsReadOnly) { %>READ ONLY<% } else { %>WRITEABLE<% } %></li>
    
  </ul>

</nav>
<!-- END SideBar.jsp -->
<% out.flush(); %>
