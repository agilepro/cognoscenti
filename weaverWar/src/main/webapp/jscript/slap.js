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
    "email": "kswenson@fujitsu.com",
    "emailConfirmed": false,
    "go": "http://bobcat/weaver/t/index.htm",
    "isLDAP": false,
    "isLocal": true,
    "isLoggedIn": true,
    "msg": "Logged In",
    "presumedId": "kswenson@fujitsu.com",
    "source": "UI:kswenson@fujitsu.com",
    "ss": "SZBC-BE-INL-BD-OUH",
    "userId": "kswenson@fujitsu.com",
    "userName": "Keith 🥴 Swenson"
}
statusCallback is a function that takes loginInfo as a parameter.  Every time
the login state is changed, this callback is called.

Use 'logOutProvider' to logout.   When logged out, the statusCallback will be called
again, with no user name or id in it. 
*/

SLAP = {
    loginConfig: {},
    loginInfo: {},
    displayLoginStatus: null
};

SLAP.initLogin = function(config, info, statusCallback) {
    SLAP.loginConfig = config;
    SLAP.retrieveSession();
    SLAP.displayLoginStatus = statusCallback;
    SLAP.queryTheServer();
    return SLAP.loginInfo;
};

SLAP.loginUserRedirect = function() {
    let pUrl = SLAP.loginConfig.providerUrl + '?openid.mode=quick&go='
        + encodeURIComponent(window.location);
    pUrl = SLAP.addSessionParameter(pUrl);
    window.location = pUrl;
};

SLAP.logoutUser = function() {
    SLAP.logOutProvider();
    SLAP.loginInfo = {};
    SLAP.storeSession(SLAP.loginInfo);
};

SLAP.sendInvitationEmail = function(message, success, failure) {
    if (!success) {
        success = function(data) {alert("invitation email has been sent to "+message.userId);};
    }
    if (!failure) {
        failure = function(data) {alert("Failure sending invitation email to "+message.userId+"\n"+data);};
    }
    var pUrl = SLAP.loginConfig.providerUrl + "?openid.mode=apiSendInvite";
    SLAP.postJSON(pUrl, message, success, failure);
}

//interface methods above, implementation methods below

SLAP.storeSession = function(data) {
    //preserve the session info if needed
    if (!data.ss && SLAP.loginInfo.ss) {
        data.ss = SLAP.loginInfo.ss;
    }
    SLAP.loginInfo = data;
    sessionStorage.setItem("SSOFI_Logged_User", JSON.stringify(data));
}
SLAP.retrieveSession = function() {
    var oldData = sessionStorage.getItem("SSOFI_Logged_User");
    if (oldData) {
        console.log("SSOFI: YES found data from previous session: ",oldData);
        try {
            SLAP.loginInfo = JSON.parse(oldData);
        }
        catch (e) {
            SLAP.loginInfo = {};
        }
    }
    else {
        console.log("SSOFI: NO data from previous session: ");
    }        
    /* calling method does this anyway...
    if (!SLAP.loginInfo.ss) {
        //if there is no session id, go and get one, migration from earlier object.
        SLAP.queryTheProvider();
        console.log("FETCHED new SSOFI session id: ", SLAP.loginInfo);
    }
    */
}
    
SLAP.getJSON = function(url, passedFunction, errorFunction) {
    console.log("SSOFI GET to: ", url); 
    var xhr = new XMLHttpRequest();
    xhr.open("GET", url, true);
    xhr.withCredentials = true;
    xhr.onreadystatechange = function() {
        if (xhr.readyState == 4 && xhr.status == 200) {
            try {
                console.log("SSOFI SUCCESS: ", xhr.responseText); 
                passedFunction(JSON.parse(xhr.responseText));
            }
            catch (e) {
                alert("Got an exception ("+e+") while trying to handle: "+url);
            }
        }
        else if (xhr.readyState == 4 && xhr.status != 200) {
            errorFunction(xhr.responseText);
        }
        else if (xhr.status == 0) {
            console.log("STRANGE browser situation the xhr.status is zero!  Might be due to CORS problem or it could be that you have an ad-blocker or privacy-protector active preventing you from being authenticated?");
        }
    }
    xhr.send();
};

SLAP.postJSON = function(url, data, passedFunction, errorFunction) {
    console.log("SSOFI POST to: ", url, data); 
    var xhr = new XMLHttpRequest();
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
        else if (xhr.readyState == 4 && xhr.status == 200) {
            errorFunction(xhr.responseText);
        }
        else if (xhr.status == 0) {
            console.log("STRANGE browser situation the xhr.status is zero!  Might be due to CORS problem or it could be that you have an ad-blocker or privacy-protector active preventing you from being authenticated?");
        }
    }
    xhr.send(JSON.stringify(data));
};

SLAP.addSessionParameter = function(url) {
    if (SLAP.loginInfo.ss) {
        return url+"&ss="+SLAP.loginInfo.ss;
    }
    console.log("NO SSOFI session found in stored record!", SLAP.loginInfo); 
    return url;
}

SLAP.queryTheServer = function() {
    var pUrl = SLAP.loginConfig.serverUrl + "auth/query";
    SLAP.getJSON(pUrl, function(data) {
        SLAP.storeSession(data);
        SLAP.displayLoginStatus(data);
        //if the server says which providers it will allow, then just use
        //that provider automatically
        if (data.providers) {
            SLAP.loginConfig.providerUrl = data.providers[0];
        }
        if (!data.userId) {
            SLAP.queryTheProvider();
        }
    }, function(data) {
        console.log("Failure querying server.  Is server really at:\n "+pUrl);
    });
};

SLAP.queryTheProvider = function() {
    console.log("###queryTheProvider");
    console.trace()
    var pUrl = SLAP.loginConfig.providerUrl + "?openid.mode=apiWho";
    pUrl = SLAP.addSessionParameter(pUrl);
    SLAP.getJSON(pUrl, function(data) {
        SLAP.storeSession(data);
        SLAP.displayLoginStatus(data);
        if (data.userId) {
            SLAP.requestChallenge();
        }
    }, function(data) {
        console.log("Failure querying Identity provider.  Is provider really at:\n "+pUrl);
    });
};

SLAP.requestChallenge = function() {
    var pUrl = SLAP.loginConfig.serverUrl + "auth/getChallenge";
    SLAP.postJSON(pUrl, SLAP.loginInfo, function(data) {
        SLAP.storeSession(data);
        SLAP.displayLoginStatus(SLAP.loginInfo);
        SLAP.getToken();
    }, function(data) {
        console.log("Failure getting challenge from server.  Is server really at:\n "+pUrl);
    });
};

SLAP.getToken = function() {
    var pUrl  = SLAP.loginConfig.providerUrl + "?openid.mode=apiGenerate";
    pUrl = SLAP.addSessionParameter(pUrl);
    SLAP.postJSON(pUrl, SLAP.loginInfo, function(data) {
        SLAP.storeSession(data);
        SLAP.displayLoginStatus(data);
        SLAP.verifyToken();
    }, function(data) {
        console.log("Failure getting token from provider.  Is provider really at:\n "+pUrl);
    });
};

SLAP.verifyToken = function() {
    var pUrl = SLAP.loginConfig.serverUrl + "auth/verifyToken";
    SLAP.postJSON(pUrl, SLAP.loginInfo, function(data) {
        SLAP.storeSession(data);
        SLAP.displayLoginStatus(data);
    }, function(data) {
        console.log("Failure verifying token.  Is server using the same provider as: "+pUrl);
    });
};

SLAP.logOutProvider = function() {
    var pUrl = SLAP.loginConfig.providerUrl + "?openid.mode=apiLogout";
    pUrl = SLAP.addSessionParameter(pUrl);
    SLAP.storeSession({});
    SLAP.postJSON(pUrl, SLAP.loginInfo, function(data) {
        SLAP.logOutServer();
    }, function(data) {
        console.log("Failure logging out.  Is provider still at:\n "+pUrl);
    });
};

SLAP.logOutServer = function() {
    var pUrl = SLAP.loginConfig.serverUrl + "auth/logout";
    SLAP.postJSON(pUrl, SLAP.loginInfo, function(data) {
        SLAP.displayLoginStatus(SLAP.loginInfo);
    }, function(data) {
        console.log("Failure logging out.  Is server really at:\n "+pUrl);
    });
}




