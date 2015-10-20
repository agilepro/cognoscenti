<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.Cognoscenti"
%><%@page import="java.net.URLEncoder"
%><%
 /* Copyright 2013 Keith D Swenson
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * Contributors Include: Shamim Quader, Sandia Yang, CY Chen, Neal Wang,
 * Anamika Chaudhari, Ajay Kakkar
 */

    /***************************************************************
    * PLEASE NOTE: this is a TEST APPLICATION for testing the SSOFI client
    *
    * The SSOFI module consists only of scaffolding that demonstrates
    * the kinds of call you will need to make.
    * Feel free to use the java script in this file, but be sure
    * fully adopt and debug it.
    *****************************************************************/

Cognoscenti cog = Cognoscenti.getInstance(session);
String identityProvider = cog.getConfig().getProperty("identityProvider");
if (identityProvider==null) {
    identityProvider = "https://interstagebpm.com/eid/";
}

String thisPage = request.getRequestURL().toString();
int pos = thisPage.lastIndexOf("/");

String thisServer = thisPage.substring(0, pos+1)+"auth/";

%>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>SSOFI JS Client Test</title>
</head>
<body>
<h1>SSOFI JS Client Test</h1>

<p>This is a test page for the JavaScript client login
   capability of the SSOFI provider authentication system.
   This is not an Angular application, but it could be.
</p>

<div id="userPrompt" style="border-width:2px;border-color:blue;padding:5px;margin:10px;bckground-color:lightyellow;border-style:dashed;">
    Login status unknown
</div>

<pre id="messageArea" style="border-width:2px;border-color:red;padding:5px;margin:10px;bckground-color:lightyellow;border-style:dashed;">
    Page is in initial state. Used buttons below to run tests.
</pre>

<p>
Name: <span id="myName" style="color: teal;"></span>
</p>
<p>
Email: <span id="myId" style="color: teal;"></span>
</p>

<script>

serverLogin = false;
responseCode = 0;
response = {};

var foo = JSON.stringify( response );

function getJSON(url, passedFunction) {
    console.log("calling GET "+url);
    var xhr = new XMLHttpRequest();
    globalForXhr = xhr;
    xhr.open("GET", url, true);
    xhr.withCredentials = true;
    xhr.onreadystatechange = function() {
        if (xhr.readyState == 4 && xhr.status == 200) {
            try {
                responseCode = xhr.status;
                passedFunction(JSON.parse(xhr.responseText));
            }
            catch (e) {
                alert("Got an exception ("+e+") whille trying to handle: "+url);
            }
        }
    }
    xhr.send();
}

function postJSON(url, data, passedFunction) {
    console.log("calling POST "+url);
    var xhr = new XMLHttpRequest();
    globalForXhr = xhr;
    xhr.open("POST", url, true);
    xhr.withCredentials = true;
    if (document.getElementById("useMime").checked) {
        xhr.setRequestHeader("Content-Type","application/json");
        console.log("using MimeType=application/json");
    }
    else {
        xhr.setRequestHeader("Content-Type","text/plain");
        console.log("using MimeType=text/plain");
    }
    xhr.onreadystatechange = function() {
        if (xhr.readyState == 4 && xhr.status == 200) {
            try {
                responseCode = xhr.status;
                passedFunction(JSON.parse(xhr.responseText));
            }
            catch (e) {
                alert("Got an exception ("+e+") whille trying to handle: "+url);
            }
        }
    }
    xhr.send(JSON.stringify(data));
}

function queryServer() {
    var pUrl = document.getElementById("MyServer").value + "query";
    getJSON(pUrl, function(data) {
        response = data;
        displayUser();
    });
}

function whoAmI() {
    var pUrl = document.getElementById("MyProvider").value + "?openid.mode=apiWho";
    response = {};
    getJSON(pUrl, function(data) {
        response = data;
        displayUser();
    });
}

function requestChallenge() {
    var pUrl = document.getElementById("MyServer").value + "getChallenge";
    var data1 = response;
    response = {};
    displayUser();
    postJSON(pUrl, data1, function(data) {
        response = data;
        displayUser();
    });
    response = {};
}

function getToken() {
    var pUrl  =document.getElementById("MyProvider").value + "?openid.mode=apiGenerate";
    var data1 = response;
    response = {};
    postJSON(pUrl, data1, function(data) {
        response = data;
        displayUser();
    });
}

function verifyToken() {
    var pUrl = document.getElementById("MyServer").value + "verifyToken";
    var data1 = response;
    response = {};
    postJSON(pUrl, data1, function(data) {
        response = data;
        if (response.verified) {
            serverLogin=true;
        }
        displayUser();
    });
}

function logOutServer() {
    var pUrl = document.getElementById("MyServer").value + "logout";
    var data1 = response;
    response = {};
    displayUser();
    postJSON(pUrl, data1, function(data) {
        response = data;
        if (response.verified) {
            serverLogin=true;
        }
        displayUser();
    });
}

function shortCircuitToken() {
    //in general it would be the server that would call this verify
    //function, but included here to see if the SSOFI provider
    //works correctly.
    var pUrl  =document.getElementById("MyProvider").value + "?openid.mode=apiVerify";
    var data1 = response;
    response = {};
    displayUser();
    postJSON(pUrl, data1, function(data) {
        response = data;
        displayUser();
    });
}

function displayUser() {
    setMessageArea("Response Code: "+responseCode+"\n"+JSON.stringify(response, null, 2) );
    document.getElementById("myName").textContent = response.userName;
    document.getElementById("myId").textContent = response.userId;
    var y  = document.getElementById("userPrompt");
    if (responseCode==0) {
        y.innerHTML = 'Checking identity, please <a target="_blank" href="'+document.getElementById("MyProvider").value+'?openid.mode=quick&go=<%=URLEncoder.encode(thisPage, "UTF-8")%>">Login</a>.';
    }
    else if (!response.userName) {
        y.innerHTML = 'Not logged in, please <a target="_blank" href="'+document.getElementById("MyProvider").value+'?openid.mode=quick&go=<%=URLEncoder.encode(thisPage, "UTF-8")%>">Login</a>.';
    }
    else if (serverLogin == false) {
        y.innerHTML = 'Hello '+response.userName+', contacting server.  <a target="_blank" href="'+document.getElementById("MyProvider").value+'?openid.mode=logout&go=<%=URLEncoder.encode(thisPage, "UTF-8")%>">Logout</a>.';
    }
    else {
        y.innerHTML = 'Welcome back <b>'+response.userName+'</b>.  <a target="_blank" href="'+document.getElementById("MyProvider").value+'?openid.mode=logout&go=<%=URLEncoder.encode(thisPage, "UTF-8")%>">Logout</a>.';
    }
}

function setMessageArea(msg) {
    var x  = document.getElementById("messageArea");
    x.textContent = msg;
}

var clickCount = 0;
function clearData() {
    clickCount++;
    responseCode = 0;
    serverLogin = false;
    response = {};
    displayUser();
    setMessageArea("Cleared, clicked "+clickCount+" times.");
}

</script>

Provider: <input id="MyProvider"  style="width:400px;" type="text" value="<%=identityProvider%>"/>
<!--https://interstagebpm.com/eid/""-->
<br/>
<br/>
Server: <input id="MyServer"  style="width:400px;" type="text" value="<%=thisServer%>"/>
<br/>
<br/>
Mime Type: <input id="useMime"  type="checkbox" value="true"/> application/json (instead of text/plain) for all requests
<br/>
<br/>
<button onclick="clearData()">Clear</button>
<button onclick="queryServer()">Query the Server</button>
<button onclick="whoAmI()">Query the Provider</button>
<button onclick="requestChallenge()">Get Challenge</button>
<button onclick="getToken()">Request Token</button>
<button onclick="shortCircuitToken()">Short Circuit</button>
<button onclick="verifyToken()">Verify Token</button>
<button onclick="logOutServer()">Logout</button>

<script>
displayUser();
</script>

</body>
</html>
