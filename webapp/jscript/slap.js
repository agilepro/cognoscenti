/*
slap.js

This is a client side implementation of the SSOFI Lightweight Access Protocol, a REST/JSON protocol
to authenticate to a server and a third party identity provider.

Start everything with a call to 'initLogin' which will discover the users identity and log into
the server if necessary.  The three parameters are:

loginConfig = {
    "providerUrl": (url to identity provider api),
    "serverUrl": (url to server auth api)
}
loginInfo = {
    "msg": (last msg from server),
    "userId": (current user email address),
    "userName": (current user name),
    "verified": (true if full logged into server),
    "haveNotCheckedYet": (set this to true initially to indicate initial state)
}
displayCallback is a function that takes loginInfo as a parameter.  Every time
the login state is changed, this callback is called.

Use 'logOutProvider' to logout.   When logged out, the displayCallback will be called
again, with no user name or id in it. 
*/

var loginConfig = null;
var loginInfo = null;
var displayLoginStatus = null;

function initLogin(config, info, statusCallback) {
    loginInfo = info;
    loginConfig = config;
    displayLoginStatus = statusCallback;
    if (!loginInfo.verified) {
        queryTheProvider();
    }
}

function getJSON(url, passedFunction) {
    console.log("calling GET");
    var xhr = new XMLHttpRequest();
    globalForXhr = xhr;
    xhr.open("GET", url, true);
    xhr.withCredentials = true;
    xhr.onreadystatechange = function() {
        if (xhr.readyState == 4 && xhr.status == 200) {
            try {
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
    console.log("calling POST");
    var xhr = new XMLHttpRequest();
    globalForXhr = xhr;
    xhr.open("POST", url, true);
    xhr.withCredentials = true;
    xhr.setRequestHeader("Content-Type","text/plain");
    xhr.onreadystatechange = function() {
        if (xhr.readyState == 4 && xhr.status == 200) {
            try {
                passedFunction(JSON.parse(xhr.responseText));
            }
            catch (e) {
                alert("Got an exception ("+e+") whille trying to handle: "+url);
            }
        }
    }
    xhr.send(JSON.stringify(data));
}

function queryTheProvider() {
    var pUrl = loginConfig.providerUrl + "?openid.mode=apiWho";
    getJSON(pUrl, function(data) {
        loginInfo = data;
        displayLoginStatus(loginInfo);
        if (data.userId) {
            requestChallenge();
        }
    });
}

function requestChallenge() {
    var pUrl = loginConfig.serverUrl + "auth/getChallenge";
    postJSON(pUrl, loginInfo, function(data) {
        loginInfo = data;
        displayLoginStatus(loginInfo);
        getToken();
    });
}

function getToken() {
    var pUrl  = loginConfig.providerUrl + "?openid.mode=apiGenerate";
    postJSON(pUrl, loginInfo, function(data) {
        loginInfo = data;
        displayLoginStatus(loginInfo);
        verifyToken();
    });
}

function verifyToken() {
    var pUrl = loginConfig.serverUrl + "auth/verifyToken";
    postJSON(pUrl, loginInfo, function(data) {
        loginInfo = data;
        if (loginInfo.verified) {
            window.location.reload();
        }
        else {
            alert("Internal Error: was not able to verify token: "+JSON.stringify(data));
        }
        displayLoginStatus(loginInfo);
    });
}

function logOutProvider() {
    var pUrl = loginConfig.providerUrl + "?openid.mode=apiLogout";
    postJSON(pUrl, loginInfo, function(data) {
        loginInfo = data;
        logOutServer();
    });
}
function logOutServer() {
    var pUrl = loginConfig.serverUrl + "auth/logout";
    postJSON(pUrl, loginInfo, function(data) {
        loginInfo = data;
        displayLoginStatus(loginInfo);
        window.location.reload();
    });
}

