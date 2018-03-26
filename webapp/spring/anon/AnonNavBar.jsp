<%
    JSONObject loginConfigSetup = new JSONObject();
    loginConfigSetup.put("providerUrl", ar.getSystemProperty("identityProvider"));
    loginConfigSetup.put("serverUrl",   ar.baseURL);
%> 
<script>
SLAP.initLogin(<% loginConfigSetup.write(out, 2, 2); %>, {}, reloadIfLoggedIn);


</script>

<nav class="navbar navbar-default appbar">
  <div class="container-fluid">

    <!-- Logo Brand -->
    <a class="navbar-brand" href="<%=ar.retPath%>" title="Weaver Home Page">
      <img class="hidden-xs" alt="Weaver Icon" src="<%=ar.retPath%>bits/header-icon.png">
      <h1>Weaver</h1>
    </a>

    <a class="navbar-brand pull-right"  title="Authenticate Yourself"
       href="<%=ar.getSystemProperty("identityProvider")%>?openid.mode=quick&go=<%=URLEncoder.encode(ar.realRequestURL, "UTF-8")%>">
      <h1>Login</h1>
    </a>

  </div>
</nav>
   