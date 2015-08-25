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

import org.workcast.json.JSONObject;
import org.socialbiz.cog.License;

/**
* A remote license is a wrapper for the JSONRepresentation
* of a license that you might get from a remote service
*/
public class RemoteLicense implements License
{
    JSONObject root;

    public RemoteLicense(JSONObject licObj) throws Exception {
        root = licObj;
        if (root==null) {
            root = new JSONObject();
        }
    }

    public String getId() throws Exception {
        return root.getString("id");
    }

    public String getNotes() throws Exception{
        return root.optString("notes");
    }

    public void setNotes(String newVal) throws Exception {
        //do nothing
    }

    public String getCreator() throws Exception {
        return root.optString("creator");
    }

    public void setCreator(String newVal) throws Exception {
        //do nothing
    }

    public long getTimeout() throws Exception {
        return root.optLong("timeout");
    }

    public void setTimeout(long timeout) throws Exception {
        //do nothing
    }

    public String getRole() throws Exception {
        return root.optString("role");
    }

    public void setRole(String newRole) throws Exception {
        //do nothing
    }

    public boolean isReadOnly() throws Exception {
        return root.optBoolean("readonly");
    }

    public void setReadOnly(boolean isReadOnly) throws Exception {
        //do nothing
    }

    public JSONObject getJSON() throws Exception {
        return root;
    }

}
