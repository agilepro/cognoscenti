<%
    JSONObject loginConfigSetup = new JSONObject();
    String identityProvider = ar.getSystemProperty("identityProvider");
    loginConfigSetup.put("providerUrl", identityProvider);
    loginConfigSetup.put("serverUrl",   ar.baseURL);
    String myPath = request.getRequestURL().toString()+"?"+request.getQueryString();
    String otherPath = ar.getCompleteURL();
    
    String loginLink = identityProvider+"?openid.mode=quick&go="+URLEncoder.encode(otherPath, "UTF-8");
%> 
<script>
SLAP.initLogin(<% loginConfigSetup.write(out, 2, 2); %>, {}, updateBar);

function updateBar() {
    var x = document.getElementById("nb-must-login");
    reloadIfLoggedIn();
} 

</script>

<nav class="navbar navbar-default appbar">
  <div class="container-fluid">

    <!-- Logo Brand -->
    <a href="<%=ar.retPath%>" title="Weaver Home Page">
      <img class="hidden-xs" alt="Weaver Icon" src="<%=ar.retPath%>bits/header-icon.png">
      <span class="weaver-logo">Weaver</span>
    </a>

    <div class="pull-right">
       <a title="Authenticate Yourself" href="<%=loginLink%>">
          <span class="weaver-logo">Login</span>
       </a>
    </div>

  </div>
</nav>
   