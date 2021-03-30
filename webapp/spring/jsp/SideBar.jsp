<!-- BEGIN SideBar.jsp -->
<%!
    public static JSONObject allMenu = new JSONObject();

%>
<%
    File menuFile = ar.getCogInstance().getConfig().getFileFromRoot("MenuTree.json");
    allMenu = JSONObject.readFromFile(menuFile);
    
    JSONArray fullMenu = new JSONArray();
    String thisPageName = "MeetingList.htm";
    
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
    <% for (JSONObject jo : fullMenu.getJSONObjectList()) { 
        String menuAddress = jo.getString("addr"); %>
    <li><a href="<%ar.writeHtml(menuAddress);%>" title="<%ar.writeHtml(jo.getString("help"));%>">
          <%ar.writeHtml(jo.getString("name"));%></a>
          <% if (menuAddress.equals(thisPageName) && jo.has("opts")) {
              %><ul><%
              for (JSONObject jo2 : jo.getJSONArray("opts").getJSONObjectList()) { %>
                  <li><a href="<%ar.writeHtml(jo2.getString("addr"));%>" title="<%ar.writeHtml(jo2.getString("help"));%>">
                      &gt; <%ar.writeHtml(jo2.getString("name"));%></a></li> <%
              }       
              %></ul><%
          }
          %>
          </li>
    <% } %>

  </ul>
</nav>
<!-- END SideBar.jsp -->
<% out.flush(); %>
