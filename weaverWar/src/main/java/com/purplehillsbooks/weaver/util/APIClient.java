package com.purplehillsbooks.weaver.util;

import java.io.InputStream;
import java.io.OutputStream;
import java.io.OutputStreamWriter;
import java.io.Writer;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.HashMap;

import com.purplehillsbooks.json.JSONArray;
import com.purplehillsbooks.json.JSONException;
import com.purplehillsbooks.json.JSONObject;
import com.purplehillsbooks.json.JSONTokener;
import com.purplehillsbooks.weaver.exception.WeaverException;

public class APIClient {
    
    private HashMap<String,String> headers = new HashMap<String,String>();
    
    //are we getting a JSONObject back, or a JSONArray?  Normally we expect
    //to get JSONObjects, however some API return an array, and we need to 
    //know that to parse it.
    public boolean expectArray = false;
    
    public APIClient() {
        //default header values
        setHeader("Content-Type", "text/plain");
        setHeader("Origin", "http://bogus.example.com/");
    }
    
    
    public void setHeader(String key, String value) {
        headers.put(key, value);
    }

    public JSONObject getFromRemote(URL url) throws Exception {
        try {
            System.out.println("APIClient: GET to api: "+url);
            HttpURLConnection httpCon = (HttpURLConnection) url.openConnection();
            httpCon.setDoOutput(true);
            httpCon.setDoInput(true);
            httpCon.setUseCaches(false);
            for (String key : headers.keySet()) {
                System.out.println("    HEADER: "+key+" = ("+headers.get(key)+")");
                httpCon.setRequestProperty( key, headers.get(key) );
            }

            httpCon.setRequestMethod("GET");
            httpCon.connect();

            InputStream is = httpCon.getInputStream();
            JSONTokener jt = new JSONTokener(is);
            if (expectArray) {
                JSONArray list = new JSONArray(jt);
                JSONObject res = new JSONObject();
                res.put("list", list);
                return res;
            }
            else {
                JSONObject resp = new JSONObject(jt);
                return resp;
            }
        }
        catch (Exception e) {
            throw new Exception("Unable to call the server site located at "+url, e);
        }
    }

    
    
    /**
     * Send a JSONObject to this server as a POST and
     * get a JSONObject back with the response.
     */
    public JSONObject postToRemote(URL url, JSONObject msg) throws Exception {
        try {
            System.out.println("APIClient: POST object to api: "+url);
            HttpURLConnection httpCon = (HttpURLConnection) url.openConnection();
            httpCon.setDoOutput(true);
            httpCon.setDoInput(true);
            httpCon.setUseCaches(false);
            for (String key : headers.keySet()) {
                System.out.println("    HEADER: "+key+" = ("+headers.get(key)+")");
                httpCon.setRequestProperty( key, headers.get(key) );
            }

            httpCon.setRequestMethod("POST");
            httpCon.connect();
            OutputStream os = httpCon.getOutputStream();
            OutputStreamWriter osw = new OutputStreamWriter(os, "UTF-8");
            msg.write(osw, 2, 0);
            osw.flush();
            osw.close();
            os.close();
            
            int returnCode = httpCon.getResponseCode();
            if (200 == returnCode) {

                InputStream is = httpCon.getInputStream();
                JSONTokener jt = new JSONTokener(is);
                JSONObject resp = new JSONObject(jt);
                return resp;
                
            }
            
            if (400 <= returnCode && 500 > returnCode) {
                
                InputStream is = httpCon.getErrorStream();
                JSONTokener jt = new JSONTokener(is);
                JSONObject resp = new JSONObject(jt);
                
                //let try to recognize this, if it has an error member
                //then there is some likelihood that this is a standard error message
                if (resp.has("error")) {
                    
                    Exception remoteError = JSONException.convertJSONToException(resp);
                    throw remoteError;
                    
                }
                
                System.out.println("RECEIVED UNRECOGNIZABLE JSON "+returnCode+" ERROR from "+url);
                Writer w = new OutputStreamWriter(System.out, "UTF-8");
                resp.write(w, 2, 2);
                w.flush();
                
            }
            
            //we got an error code that we really can not handle, so just report 
            //it here and give up
            throw WeaverException.newBasic("Received response code %s unable to handle response.", Integer.toString(returnCode)); 
           
        }
        catch (Exception e) {
            throw WeaverException.newWrap("Unable to call the server site located at %s", e, url) ;
        }
    }
    
    
}
