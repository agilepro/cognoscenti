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
 *
 * Contributors Include: Shamim Quader, Sameer Pradhan, Kumar Raja, Jim Farris,
 * Sandia Yang, CY Chen, Rajiv Onat, Neal Wang, Dennis Tam, Shikha Srivastava,
 * Anamika Chaudhari, Ajay Kakkar, Rajeev Rastogi
 */

package org.socialbiz.cog;

import java.io.InputStream;
import java.io.OutputStream;
import java.io.OutputStreamWriter;
import java.net.HttpURLConnection;
import java.net.URL;

import org.workcast.json.JSONArray;
import org.workcast.json.JSONObject;
import org.workcast.json.JSONTokener;

/**
* A remote retrieval of JSON (GET) and call (POST)
*/
public class RemoteJSON {


    /**
     * Retrieves a remote JSONObject.
     * If an error is returned, it expects the error messages to be in an array
     * called "msgs" and is expecting an error code in a member called "responseCode"
     * The presence of a response code other than 200 causes an exception
     * to be thrown instead of returning the object.
     */
    public static JSONObject getFromRemote(URL url) throws Exception {
        InputStream is = url.openStream();
        JSONTokener jt = new JSONTokener(is);
        JSONObject retrievedObj = new JSONObject(jt);
        String responseCode = retrievedObj.optString("responseCode");
        if (responseCode!=null && responseCode.length()>0 && !"200".equals(responseCode)) {
            StringBuilder reason = new StringBuilder();
            JSONArray msgs = retrievedObj.optJSONArray("msgs");
            if (msgs!=null) {
                for (int i=0; i<msgs.length(); i++) {
                    String msg = msgs.getString(i);
                    reason.append(msg);
                    reason.append("; ");
                }
            }
            throw new Exception("Unable to get remote information ("+responseCode
                    +": "+url+") because: "+reason.toString());
        }
        return retrievedObj;
    }


    /**
     * Send a JSONObject to this server as a POST and
     * get a JSONObject back with the response.
     */
    public static JSONObject postToRemote(URL url, JSONObject msg) throws Exception {
        try {
            HttpURLConnection httpCon = (HttpURLConnection) url.openConnection();
            httpCon.setDoOutput(true);
            httpCon.setDoInput(true);
            httpCon.setUseCaches(false);
            httpCon.setRequestProperty( "Content-Type", "application/json" );
            httpCon.setRequestProperty("Accept", "application/json");

            //put this in because currently the authentication provider expects something in the origin
            //might not be necessary
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

            int responseCode = resp.getInt("responseCode");
            if (responseCode!=200) {
                JSONObject exception = resp.getJSONObject("exception");
                JSONArray errorMsgs = exception.getJSONArray("msgs");
                Exception lastExp = null;
                int len = errorMsgs.length();
                for (int i=0; i<len; i++) {
                    String oneMsg = errorMsgs.getString(i);
                    if (lastExp==null) {
                        lastExp = new Exception(oneMsg);
                    }
                    else {
                        lastExp = new Exception(oneMsg, lastExp);
                    }
                }
                throw new Exception("RemoteProjectException: ("+responseCode+"): ", lastExp);
            }

            return resp;
        }
        catch (Exception e) {
            throw new Exception("Unable to call the server site located at "+url, e);
        }
    }


}
