<%
    JSONObject loginConfigSetup = new JSONObject();
    loginConfigSetup.put("providerUrl", ar.getSystemProperty("identityProvider"));
    loginConfigSetup.put("serverUrl",   ar.baseURL);
    String myPath = request.getRequestURL().toString()+"?"+request.getQueryString();
    String otherPath = ar.getCompleteURL();
%> 
<script>
SLAP.initLogin(<% loginConfigSetup.write(out, 2, 2); %>, {}, updateBar);

function updateBar() {
    var x = document.getElementById("nb-must-login");
    var y = document.getElementById("nb-is-login");
    if (!SLAP.loginInfo.verified) {
        y.style.display = "none";
        x.style.display = "block";
    } else {
        document.getElementById("nb-user-name").textContent = SLAP.loginInfo.userName;
        y.style.display = "block";
        x.style.display = "none";
    }
    reloadIfLoggedIn();
} 

</script>

<nav class="navbar navbar-default appbar">
  <div class="container-fluid">

    <!-- Logo Brand -->
    <a class="navbar-brand" href="<%=ar.retPath%>" title="Weaver Home Page">
      <img class="hidden-xs" alt="Weaver Icon" src="<%=ar.retPath%>bits/header-icon.png">
      <h1>Weaver</h1>
    </a>

    <div class="navbar-brand pull-right" id="nb-must-login" >
       <a title="Authenticate Yourself"
       href="<%=ar.getSystemProperty("identityProvider")%>?openid.mode=quick&go=<%=URLEncoder.encode(otherPath, "UTF-8")%>">
          <h1>Login</h1>
       </a>
    </div>
    <div class="navbar-brand pull-right" id="nb-is-login" >
       <a title="Authenticate Yourself"
       href="<%=ar.getSystemProperty("identityProvider")%>?openid.mode=quick&go=<%=URLEncoder.encode(otherPath, "UTF-8")%>">
          <h1 id="nb-user-name">Authenticating</h1>
       </a>
    </div>

  </div>
</nav>
   