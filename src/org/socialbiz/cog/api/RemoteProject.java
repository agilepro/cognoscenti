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

package org.socialbiz.cog.api;

import java.net.URL;

import org.socialbiz.cog.License;
import org.socialbiz.cog.RemoteJSON;

import com.purplehillsbooks.json.JSONArray;
import com.purplehillsbooks.json.JSONException;
import com.purplehillsbooks.json.JSONObject;

/**
* A remote project is access purely through URLs and REST oriented web services
*/
public class RemoteProject
{
    String     urlStr;
    JSONObject root;

    public RemoteProject(String s) throws Exception {
        urlStr = s;
    }

    public JSONObject getJSONObj() throws Exception {
        try {
            if (root == null) {
                root = RemoteJSON.getFromRemote(new URL(urlStr));
            }
            return root;
        }
        catch (Exception e) {
            throw new JSONException("Unable to get site detail from url={0}", e, urlStr);
        }
    }

    public JSONArray getNotes() throws Exception {
        return getJSONObj().getJSONArray("notes");
    }
    public JSONArray getDocs() throws Exception {
        return getJSONObj().getJSONArray("docs");
    }
    public JSONArray getGoals() throws Exception {
        return getJSONObj().getJSONArray("goals");
    }
    public License getLicense() throws Exception {
        return new RemoteLicense(getJSONObj().optJSONObject("license"));
    }
    public String getName() throws Exception {
        return getJSONObj().optString("projectname");
    }
    public String getUIAddress() throws Exception {
        String projectui = getJSONObj().optString("projectui");

        //old api had a field for 'ui' attempt to reconstruct
        if (projectui == null || projectui.length()==0) {
            projectui = getJSONObj().optString("ui") + "frontPage.htm";
        }
        return projectui;
    }
    public String getSiteURL() throws Exception {
        return getJSONObj().optString("siteinfo");
    }
    public String getSiteName() throws Exception {
        return getJSONObj().optString("sitename");
    }
    public String getSiteUIAddress() throws Exception {
        String siteui = getJSONObj().optString("siteui");

        //old api had a field for 'ui' attempt to reconstruct
        if (siteui == null || siteui.length()==0) {
            siteui = getJSONObj().optString("ui");
            int len = siteui.length();
            siteui = siteui.substring(0, len-1);
            int slashpos = siteui.lastIndexOf('/');
            siteui = siteui.substring(0, slashpos) + "/$/accountListProjects.htm";
        }
        return siteui;
    }

    /**
     * Send a JSONObject to this server as a POST and
     * get a JSONObject back with the response.
     */
    public JSONObject call(JSONObject msg) throws Exception {
        return RemoteJSON.postToRemote(new URL(urlStr), msg);
    }
}
