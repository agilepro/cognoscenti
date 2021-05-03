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
    <% 
    for (JSONObject jo : fullMenu.getJSONObjectList()) { 
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
        %>><% ar.writeHtml(jo.getString("name")); %></a><%
        if (jo.has("opts")) {
            boolean found = false;
            if (jo.has("useOpts")) {
                found = hasString(jo, "useOpts", templateName);
            }
            if (found) {
            %>
              <div class="sublist" style="color:black"><ul><%
                for (JSONObject jo2 : jo.getJSONArray("opts").getJSONObjectList()) { 
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
                    %>><% ar.writeHtml(jo2.getString("name")); %></a></li> <%
                 }       
            %></ul></div><%
            }
        }
        %></li><% 
    }
    %>
  </ul>
  <%= templateName%>
</nav>
<!-- END SideBar.jsp -->
<% out.flush(); %>
