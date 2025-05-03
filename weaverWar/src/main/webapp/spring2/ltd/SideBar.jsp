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


      <li class="nav-item dropdown"><a class="nav-link dropdown p-1"  href="LimitedAccess.htm" title="Explains what you can access here."><img src="<%=ar.retPath%>new_assets/assets/navicon/GuestAccessMenu.png" title="You have limited and unknown access to some parts of this workspace" class="accessIndicator"/></a></li>

      
      <li class="nav-item dropdown"><a class="nav-link dropdown p-1" href="https://s06.circleweaver.com/TutorialList.html" title="Lots of videos on YouTube to help you learn how to use Weaver." target="_blank"><img src="<%=ar.retPath%>new_assets/assets/navicon/Training.png" > </a></li>
<div style="height:100px"></div>
      <li class="my-5 text-weaverbody" data-bs-toggle="modal" data-bs-target="#accessModal">
        <img src="<%=ar.retPath%>new_assets/assets/LimitIndicator.png" title="You have limited access to some parts of this workspace" 
             class="accessIndicator"/>
      </li>
    
  </ul>

    </div>
    <!-- Modal -->
    <div class="modal fade" id="accessModal" tabindex="-1" aria-labelledby="accessModalLabel" aria-hidden="true">
        <div class="modal-dialog">
            <div class="modal-content">
                
                    <div class="modal-header bg-primary-subtle text-primary">
                        <h5 class="modal-title" id="accessModalLabel">Guest Access</h5>
                        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                    </div>
                    <div class="modal-body">
                        <h6><img src="<%=ar.retPath%>new_assets/assets/LimitIndicator.png"
                            title="You have limited access to this workspace" 
                            class="accessIndicator" /> = Limited access to this workspace.<br/>
                                 If you would like to access this workspace, please contact
                                 your administrator.
                        </h6><br/>
                        <img src="<%=ar.retPath%>new_assets/assets/ReadIndicator.png"
                                title="You have read-only access to this workspace" 
                                class="accessIndicator" /> = 
                            Unpaid access to this workspace. <br>
                        <img src="<%=ar.retPath%>new_assets/assets/Site-Writable.png"
                            title="You have full update access to this workspace" 
                            class="accessIndicator" /> = Full update access to this workspace. <br/>
                    </div>
                    <div class="modal-footer override">
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
                    </div>
            </div>
        </div>
    </div>
</nav>
<!-- END SideBar.jsp -->
<% out.flush(); %>
