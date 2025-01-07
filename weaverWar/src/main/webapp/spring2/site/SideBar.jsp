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
    
    
    
    
    File menuFile = ar.getCogInstance().getConfig().getFileFromRoot("MenuTree2.json");
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
<nav class="sidebar bg-primary">
  <div class="container-fluid min-vh-100 sidebar bg-primary">
    <ul class="sidebar-nav list-unstyled py-2">
    <% 
    for (JSONObject jo : fullMenu.getJSONObjectList()) {
        if (userIsReadOnly && !jo.has("readOnly")) {
            //skip anything not marked for read only when user is readonly.
            continue;
        }
    %>
      <li class="nav-item">
        <a class="nav-link p-1" <%
        if (jo.has("href")) {
            %> href="<% ar.writeHtml(jo.getString("href")); %>"<%
        }
        if (jo.has("title")) {
            %> title="<% ar.writeHtml(jo.getString("title")); %>"<%
        }
        if (jo.has("ng-click")) {
            %> ng-click="<% ar.writeHtml(jo.getString("ng-click")); %>"<%
        }
        if (jo.has("external")) {
            %> target="_blank"<%
        }
        %>> <% 
        if (jo.has("icon")) {
            %><img src="../../../new_assets/assets/navicon/<% ar.writeHtml(jo.getString("icon")); %>"><%
        }

        %></a><%
        if (jo.has("opts")) {
            JSONArray options = getOptions(jo, wrappedJSP);
            if (options.length()>0) {
            %>
            <ul class="dropdown-menu bg-weaverbody ms-0"><%
                for (JSONObject jo2 : options.getJSONObjectList()) { 
                    if (userIsReadOnly && !jo2.has("readOnly")) {
                        //skip anything not marked for observer when user is readonly.
                        continue;
                    }
                    %>
                      <li><a<%
                    if (jo2.has("href")) {
                        %> href="<% ar.writeHtml(jo2.getString("href")); %>"<%
                    }
                    if (jo2.has("title")) {
                        %> title="<% ar.writeHtml(jo2.getString("title")); %>"<%
                    }
                    if (jo2.has("ng-click")) {
                        %> ng-click="<% ar.writeHtml(jo2.getString("ng-click")); %>"<%
                    }
                    if (jo2.has("external")) {
                        %> target="_blank"<%
                    }
                    %>><% ar.writeHtml(jo2.getString("name")); %>
                </a>
            </li> 
            <% } %>
            </ul>
        <% }} %>
    </li>
    <% } %>
</ul>
<div style="height:100px"></div>
<span class="my-5 text-weaverbody" data-bs-toggle="modal" data-bs-target="#accessModal">  <% if (userIsReadOnly) { %>
    <img src="<%=ar.retPath%>new_assets/assets/ReadIndicator.png" title="You have observer access to this workspace" 
    class="accessIndicator"/>
<% } else { %>
    <img src="<%=ar.retPath%>new_assets/assets/Site-Writable.png" title="You have full edit access to this workspace" 
class="accessIndicator"/>
<% } %></span>
<!-- Modal -->
<div class="modal fade" id="accessModal" tabindex="-1" aria-labelledby="accessModalLabel" aria-hidden="true">
<div class="modal-dialog">
  <div class="modal-content"><% if (userIsReadOnly) { %>
    <div class="modal-header">
      <h5 class="modal-title" id="accessModalLabel">Observer Only</h5>
      <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
    </div>
    <div class="modal-body">
        <h5><img src="<%=ar.retPath%>new_assets/assets/ReadIndicator.png" title="You have observer access to this workspace" 
            class="accessIndicator"/>  =  You have observer access to this workspace. <br>If you would like to edit this workspace, please contact your administrator.</h5><br>
                    <img src="<%=ar.retPath%>new_assets/assets/Site-Writable.png" title="You have full edit access to this workspace" 
            class="accessIndicator"/>  =  Full editing access to this workspace.<br><br>
            <img src="<%=ar.retPath%>new_assets/assets/LimitIndicator.png" title="You have guest access to this workspace" 
            class="accessIndicator"/>  =  Guest access to this site. 
    </div>
    <% } else { %>
        <div class="modal-header bg-primary-subtle text-primary">
            <h5 class="modal-title" id="accessModalLabel">Full Edit Access</h5>
            <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
          </div>
          <div class="modal-body">
            <h6><b><img src="<%=ar.retPath%>new_assets/assets/Site-Writable.png" title="You have full edit access to this site" 
                class="accessIndicator"/>  =  You have full editing access to this site.</b></h6><br>
                            <img src="<%=ar.retPath%>new_assets/assets/ReadIndicator.png" title="You have observer access to this workspace" 
                class="accessIndicator"/>  =  Observer access to this site. <br><br>
                <img src="<%=ar.retPath%>new_assets/assets/LimitIndicator.png" title="You have guest access to this workspace" 
                class="accessIndicator"/>  =  Guest access to this site. 
          </div>
          <% } %>
    <div class="modal-footer">
      <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
    </div>
  </div>
</div>
</div>
    
  </div>

  
  <%if (false) {ar.write(wrappedJSP);} %>
</nav>
<!-- END SideBar.jsp -->
<% out.flush(); %>
