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
            //    if (hasString(entry, "use", value)) {
                    res.put(entry);
             //   }
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
    
    fullMenu.addAll(allMenu.getJSONArray("userMode"));
    fullMenu.addAll(allMenu.getJSONArray("allModes"));
    
    boolean userIsReadOnly = !ar.canUpdateWorkspace();

%>

<!-- Side Bar -->

    <nav class="sidebar bg-secondary">
        <div class="container-fluid min-vh-100 sidebar bg-secondary">
            <ul class="sidebar-nav list-unstyled py-2">
    <% 
    for (JSONObject jo : fullMenu.getJSONObjectList()) {
        if (userIsReadOnly && !jo.has("readOnly")) {
            //skip anything not marked for read only when user is readonly.
            continue;
        }
    %>  
            
                <li class="nav-item dropdown pb-2">
                    <a class="nav-link dropdown" role="button" data-bs-toggle="dropdown"<%
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
                            %><img src="../../../assets/navicon/<% ar.writeHtml(jo.getString("icon")); %>"><%
                        }

                        
                        %></a><%
                        if (jo.has("opts")) {
                        JSONArray options = getOptions(jo, wrappedJSP);
                        if (options.length()>0) {
                        %>
                        <ul class="dropdown-menu bg-weaverbody">

                        <% for (JSONObject jo2 : options.getJSONObjectList()) { %>
                            <li>
                                <a<% if (jo2.has("href")) { %> href="<% ar.writeHtml(jo2.getString("href")); %>" <% } %> 
                                    <% if (jo2.has("ng-click")){ %> ng-click="<% ar.writeHtml(jo2.getString("ng-click")); %>" <% } %> 
                                    class="dropdown-item">
                                    <%ar.writeHtml(jo2.getString("name")); %>
                                </a>
                            </li>
                        <% } %>
                        </ul>
                        <% }} %>
                </li>
            <% } %>
           <% 
    
    %> 
    <li class="my-5 text-weaverbody">  <% if (userIsReadOnly) { %>
        <img src="<%=ar.retPath%>assets/ReadIndicator.png" title="You have observer access to this workspace" 
        class="accessIndicator"/>
    <% } else { %>
        <img src="<%=ar.retPath%>assets/Site-Writable.png" title="You have full edit access to this workspace" 
    class="accessIndicator"/>
    <% } %></li>
    
</ul>
</div>
<%if (false) {ar.write(wrappedJSP);} %>
    </nav>

<!-- END SideBar.jsp -->
<% out.flush(); %>
