package org.socialbiz.cog.api;

import javax.servlet.http.HttpSession;

public class AuthStatus {

    //these are official verified value from trusted authentication server
    private String authID = null;
    private String authName = null;
    private String challenge = "";
    private String token = null;

    public static AuthStatus getAuthStatus(HttpSession session) {

        AuthStatus aStat = (AuthStatus) session.getAttribute("AuthStatus");
        if (aStat == null) {
            aStat = new AuthStatus();
            session.setAttribute("AuthStatus", aStat);
        }
        return aStat;
    }

    public boolean isAuthenticated() {
        return (authID!=null);
    }

    public void logout() {
        authID = null;
        authName = null;
    }

    public String getId() {
        return authID;
    }
    public void setId(String newID) {
        authID = newID;
    }

    public String getName() {
        return authName;
    }
    public void setName(String newName) {
        authName = newName;
    }

    public String generateChallenge() {
        challenge = generateKey();
        return challenge;
    }
    public void clearChallenge() {
        challenge = "";
    }
    public String getChallenge() {
        return challenge;
    }

    public String getToken() {
        return token;
    }
    public void setToken(String newToken) {
        token = newToken;
    }



    private static long lastKey = System.currentTimeMillis();
    private static char[] thirtySix = new char[] {'0','1','2','3','4','5','6','7','8','9',
        'a','b','c','d','e','f','g','h','i','j', 'k','l','m','n','o','p','q','r','s','t',
        'u','v','w','x','y','z'};
    /**
    * Generates a value based on the current time, and the time of
    * the previous id generation, but checking also
    * that it has not given out this value before.  If a key has
    * already been given out for the current time, it increments
    * by one.  This method works as long as on the average you
    * get less than one ID per millisecond.
    */
    private synchronized static String generateKey() {
        long ctime = System.currentTimeMillis();
        if (ctime <= lastKey) {
            ctime = lastKey+1;
        }
        long lastctime = lastKey;
        lastKey = ctime;

        //now convert timestamp into cryptic alpha string
        //start with the server defined prefix based on mac address
        StringBuilder res = new StringBuilder(8);
        while (ctime>0) {
            res.append(thirtySix[(int)(ctime % 36)]);
            res.append(thirtySix[(int)(lastctime % 10)]);  //always a numeral
            ctime = ctime / 36;
            lastctime = lastctime / 10;
        }
        return res.toString();
    }

}
