/*
 * Copyright 2013 Keith D Swenson
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
 */

package org.socialbiz.cog.api;

import java.io.InputStream;
import java.io.OutputStream;
import java.io.OutputStreamWriter;
import java.io.Writer;
import java.net.HttpURLConnection;
import java.net.URL;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.socialbiz.cog.Cognoscenti;
import org.socialbiz.cog.UserManager;
import org.socialbiz.cog.UserProfile;
import com.purplehillsbooks.json.JSONArray;
import com.purplehillsbooks.json.JSONObject;
import com.purplehillsbooks.json.JSONTokener;

/**
 * This servlet implements the Lightweight Authentication Protocol
 * which consists of two operations, both POST method, and both
 * receiving and returning JSON structures.  A JavaScript client
 * can use these method to authenticate the user to this server.
 *
 * <server>/<app>/auth/getChallenge
 *
 * This receives a request for a challenge value, generates a challenge
 * value, associates the challenge with the current session, and returns
 * the challenge in a JSON file.
 *
 * <server>/<app>/auth/verifyToken
 *
 * This receives a JSON with the challenge, the token from the auth
 * provider.  This will make a call to the auth provider, and if
 * it gets an acceptable response (verified) then it records the
 * user information in the session, and returns a value saying
 * that the user is logged in.
 *
 *
 */
@SuppressWarnings("serial")
public class LightweightAuthServlet extends javax.servlet.http.HttpServlet {

    private static String trusterProviderUrl = "https://interstagebpm.com/eid/";

    public static void init(String _trusterProviderUrl) {
        if (_trusterProviderUrl!=null) {
            trusterProviderUrl = _trusterProviderUrl;
        }
    }

    private void setHeadersForRediculousBrowserAuthRequirements(HttpServletRequest req, HttpServletResponse resp) {
        //this is an API to be read by others, for these really strange rules
        //set up by the browsers, you have to set the CORS to
        //allow scripts to read this data from a browser.
        //Longer story, the browser will accept setting allow origin to '*'
        //but if you do, it will not send the cookies.  If you tell it to send
        //the cookies with "withCredentials" then it will not allows the '*'
        //setting on allow origin any more.  The only alternative is that you
        //MUST copy the origin from the request into the response.
        //This is truly strange, but required.

        String origin = req.getHeader("Origin");
        if (origin==null || origin.length()==0) {
            //this does not always work, but what else can we do?
            origin="*";
        }
        resp.setHeader("Access-Control-Allow-Origin",      origin);
        resp.setHeader("Access-Control-Allow-Credentials", "true");
        resp.setHeader("Access-Control-Allow-Methods",     "GET, POST, OPTIONS");
        resp.setHeader("Access-Control-Allow-Headers",     "Origin, X-Requested-With, Content-Type, Accept, Authorization");
        resp.setHeader("Access-Control-Max-Age",           "1");
        resp.setHeader("Vary",                             "*");
    }

    @Override
    public void doGet(HttpServletRequest req, HttpServletResponse resp) {

        setHeadersForRediculousBrowserAuthRequirements(req, resp);
        AuthStatus aStat = AuthStatus.getAuthStatus(req.getSession());
        JSONObject jo = new JSONObject();
        resp.setContentType("application/json;charset=UTF-8");
        try {
            JSONArray providers = new JSONArray();
            providers.put( trusterProviderUrl );
            jo.put("providers", providers);
            if (aStat.isAuthenticated()) {
                jo.put("msg",  "User logged in as "+aStat.getName());
                jo.put("userId",  aStat.getId());
                jo.put("userName",  aStat.getName());
                jo.put("verified",  true);
            }
            else {
                jo.put("msg",  "User not logged in");
            }
            Writer w = resp.getWriter();
            jo.write(w);
            w.flush();
        } catch (Exception e) {
            System.out.println("COG-LAuth FAILURE LightweightAuthServlet handling GET request "+e);
            e.printStackTrace(System.out);
        }
    }

    @Override
    public void doPost(HttpServletRequest req, HttpServletResponse resp) {

        setHeadersForRediculousBrowserAuthRequirements(req, resp);
        Writer w = null;
        String pathInfo = req.getPathInfo();

        resp.setContentType("application/json;charset=UTF-8");
        try {
            w = resp.getWriter();
            AuthStatus aStat = AuthStatus.getAuthStatus(req.getSession());

            //receive the JSONObject
            InputStream is = req.getInputStream();
            JSONTokener jt = new JSONTokener(is);
            JSONObject objIn = new JSONObject(jt);
            is.close();
            JSONArray providers = new JSONArray();
            providers.put( trusterProviderUrl );
            objIn.put("providers",  providers);

            if (pathInfo.startsWith("/logout")) {
                aStat.logout();
                objIn = new JSONObject();
                objIn.put("msg",  "User not logged in");
                objIn.put("providers",  providers);
                objIn.write(w, 2, 0);
                w.flush();
            }
            else if (pathInfo.startsWith("/getChallenge")) {

                String challenge = aStat.generateChallenge();
                objIn.put("challenge",  challenge);
                objIn.write(w, 2, 0);
                w.flush();
            }
            else if (pathInfo.startsWith("/verifyToken")) {

                String chg1 = aStat.getChallenge();
                String chg2 = objIn.getString("challenge");

                if (objIn.getString("token").length()==0) {
                    throw new Exception("Need to have a 'token' member of the passed JSON in order to verify it.");
                }

                if (!chg1.equals(chg2)) {
                    aStat.clearChallenge();
                    throw new Exception("Got a request to verify a token and challenge that is not that which was given out.  Authentication transaction aborted.");
                }

                objIn.put("challenge", chg2);

                if (trusterProviderUrl==null || trusterProviderUrl.length()==0) {
                    throw new Exception("the LightweightAuthServlet has not been initialized with the address of the provider");
                }

                //Now, actually call the provider and see if this is true
                String destUrl = trusterProviderUrl + "?openid.mode=apiVerify";
                JSONObject response = postToRemote(new URL(destUrl), objIn);
                boolean valid = response.getBoolean("verified");

                if (valid) {
                    String userId = response.getString("userId");
                    aStat.setId(userId);
                    aStat.setName(response.getString("userName"));

                    //remember for the user that they logged in at this time
                    UserProfile up = UserManager.findUserByAnyId(userId);

                    //This could be the first time a user accesses, so create profile
                    if (up==null) {
                        Cognoscenti cog = Cognoscenti.getInstance(req);
                        UserManager userManager = cog.getUserManager();
                        up = userManager.createUserWithId(userId);
                        up.setName(response.getString("userName"));
                        userManager.saveUserProfiles();
                    }

                    up.setLastLogin(System.currentTimeMillis(), userId);
                }
                else {
                    //after a failed login, don't leave any previous login around....
                    aStat.logout();
                }

                response.write(w, 2, 0);
                w.flush();
            }
            else {
                throw new Exception("Lightweight Auth Servlet can not handle address: "+pathInfo);
            }
        }
        catch (Exception e) {
            System.out.println("COG-LAuth FAILURE handling "+pathInfo);
            e.printStackTrace(System.out);
            try {
                JSONObject err = new JSONObject();
                JSONArray msgs = new JSONArray();
                Throwable t = e;
                while (t!=null) {
                    msgs.put(t.toString());
                    t = t.getCause();
                }
                err.put("exception", msgs);
                if (w!=null) {
                    err.write(w,2,0);
                    w.flush();
                }
            }
            catch (Exception eeee) {
                //can't seem to do anything to let the client know.
                System.out.println("COG-LAuth FAILURE sending exception to client: "+ eeee);
            }
        }
    }

    /**
     * Send a JSONObject to this server as a POST and
     * get a JSONObject back with the response.
     */
    private static JSONObject postToRemote(URL url, JSONObject msg) throws Exception {
        try {
            HttpURLConnection httpCon = (HttpURLConnection) url.openConnection();
            httpCon.setDoOutput(true);
            httpCon.setDoInput(true);
            httpCon.setUseCaches(false);
            httpCon.setRequestProperty( "Content-Type", "text/plain" );
            httpCon.setRequestProperty("Origin", "http://bogus.example.com/");

            httpCon.setRequestMethod("POST");
            httpCon.connect();
            OutputStream os = httpCon.getOutputStream();
            OutputStreamWriter osw = new OutputStreamWriter(os, "UTF-8");
            msg.write(osw, 2, 0);
            osw.flush();
            osw.close();
            os.close();

            InputStream is = httpCon.getInputStream();
            JSONTokener jt = new JSONTokener(is);
            JSONObject resp = new JSONObject(jt);

            return resp;
        }
        catch (Exception e) {
            throw new Exception("Unable to call the server site located at "+url, e);
        }
    }


}
