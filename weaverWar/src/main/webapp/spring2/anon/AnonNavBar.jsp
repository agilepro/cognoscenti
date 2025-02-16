<%
    String identityProvider = ar.getSystemProperty("identityProvider");
    String otherPath = ar.getCompleteURL();
    String loginLink = identityProvider+"?openid.mode=quick&go="+URLEncoder.encode(otherPath, "UTF-8");
%> 


<nav class="navbar navbar-expand-lg navbar-dark bg-primary py-0">
  <div class="container-fluid override">

      <!-- Logo Brand -->
    <a class="navbar-brand pb-2" href="<%=ar.retPath%>" title="Access your overall personal Weaver Home Page">
        <span class="fw-semibold fs-1 text-weaverbody">
        <img class="hidden-xs" alt="Weaver Logo" src="<%=ar.retPath%>new_assets/bits/header-icon.png">
        Weaver</span>
    </a>

<% if (!ar.isLoggedIn()) { %>
    <div class="navbar-brand pull-right">
        <a title="Authenticate Yourself" href="<%=loginLink%>">
            <span class="text-weaverbody h5">Login</span>
        </a>
    </div>
<% } %>

  </div>
</nav>
   