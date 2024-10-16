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
            
                <li class="nav-item dropdown">
                    <a class="nav-link dropdown p-1" <%
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
                            %><img src="../../new_assets/assets/navicon/<% ar.writeHtml(jo.getString("icon")); %>"><%
                        }

                        
                        %></a><%
                        if (jo.has("opts")) {
                        JSONArray options = getOptions(jo, wrappedJSP);
                        if (options.length()>0) {
                        %>
                        <ul class="dropdown-menu bg-weaverbody ms-0">

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
           </ul><% 
    
    %> 


</div>
<%if (false) {ar.write(wrappedJSP);} %>
    </nav>

<!-- END SideBar.jsp -->
<% out.flush(); %>
