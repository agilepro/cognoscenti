<%
    String identityProvider = ar.getSystemProperty("identityProvider");
    String otherPath = ar.getCompleteURL();
    String loginLink = identityProvider+"?openid.mode=quick&go="+URLEncoder.encode(otherPath, "UTF-8");
%> 


<nav class="navbar navbar-default appbar">
  <div class="container-fluid">

      <!-- Logo Brand -->
    <a class="navbar-brand" href="<%=ar.retPath%>" title="Access your overall personal Weaver Home Page">
        <img class="hidden-xs" alt="Weaver Icon" src="<%=ar.retPath%>bits/header-icon.png">
        <span class="weaver-logo">Weaver</span>
    </a>

<% if (!ar.isLoggedIn()) { %>
    <div class="navbar-brand pull-right">
        <a title="Authenticate Yourself" href="<%=loginLink%>">
            <span class="weaver-logo">Login</span>
        </a>
    </div>
<% } %>

  </div>
</nav>
   