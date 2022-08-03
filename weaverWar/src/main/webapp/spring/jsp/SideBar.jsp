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
    
    fullMenu.addAll(allMenu.getJSONArray("workMode"));
    fullMenu.addAll(allMenu.getJSONArray("allModes"));
    
    boolean userIsReadOnly = !ar.canUpdateWorkspace();

%>

<!-- Side Bar -->
<nav class="navbar navbar-default navbar-fixed-side sidebar navbar-responsive-collapse" role="navigation">
  <ul>
    <% 
    for (JSONObject jo : fullMenu.getJSONObjectList()) {
        if (userIsReadOnly && !jo.has("readOnly")) {
            //skip anything not marked for read only when user is readonly.
            continue;
        }
    %>
      <li><a<%
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
        %>><% ar.writeHtml(jo.getString("name")); if (jo.has("external")) {ar.write(" <i class=\"fa fa-external-link\"></i>");}%></a><%
        if (jo.has("opts")) {
            JSONArray options = getOptions(jo, wrappedJSP);
            if (options.length()>0) {
            %>
              <div class="sublist" style="color:black"><ul><%
                for (JSONObject jo2 : options.getJSONObjectList()) { 
                    if (userIsReadOnly && !jo2.has("readOnly")) {
                        //skip anything not marked for read only when user is readonly.
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
                    %>><% ar.writeHtml(jo2.getString("name")); %></a></li> <%
                 }       
            %></ul></div><%
            }
        }
        %></li><% 
    }
    %>
    <li style="color:blue">  <% if (userIsReadOnly) { %>READ ONLY<% } else { %>CAN UPDATE<% } %></li>
    
  </ul>
  <%if (false) {ar.write(wrappedJSP);} %>
</nav>
<!-- END SideBar.jsp -->
<% out.flush(); %>
