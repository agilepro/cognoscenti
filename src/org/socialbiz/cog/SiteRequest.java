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

import org.w3c.dom.Document;
import org.w3c.dom.Element;
import com.purplehillsbooks.json.JSONObject;

/**
 *
 */
public class SiteRequest extends DOMFace {

    public SiteRequest(Document doc, Element ele, DOMFace p) {
         super(doc, ele, p);
    }

    public String getName() {
        return getScalar("displayName");
    }

    public void setName(String displayName) {

        setScalar("displayName", displayName.trim());
    }

    public String getDescription() {
        return getScalar("description");
    }

    public void setDescription(String descr) {
        setScalar("description", descr.trim());
    }

    public String getAdminComment() {
        return getScalar("comment");
    }

    public void setAdminComment(String descr) {
        setScalar("comment", descr.trim());
    }

    public String getSiteId() {
        return getScalar("accountId");
    }

    public void setSiteId(String siteId) {

        setScalar("accountId", siteId.trim());
    }

    public void setUniversalId(String universalId) {
        setScalar("universalId", universalId.trim());
    }

    /*
     * This returns email id of the user who has requested site.
     */
    public String getUniversalId() {
        return getScalar("universalId");
    }

    public void setRequestId(String Id) {
        setAttribute("Id", Id.trim());
    }

    public void setStatus(String status) {
        setAttribute("status", status.trim());
    }

    public void setModified(String userId, long time) {
        setAttribute("modUser", userId);
        setAttribute("modTime", Long.toString(time));
    }

    public String getStatus() {
        return getAttribute("status");
    }

    public String getRequestId() {
        return getAttribute("Id");
    }

    public long getModTime() {
        return safeConvertLong(getAttribute("modTime"));
    }
    public String getModUser() {
        return getAttribute("modUser");
    }

    public JSONObject getJSON() throws Exception {
        UserProfile userProfile =  UserManager.findUserByAnyId(getModUser());
        JSONObject jo = new JSONObject();
        jo.put("requestId", getRequestId());
        jo.put("name", getName());
        jo.put("status", getStatus());
        jo.put("desc", getDescription());
        jo.put("modTime", getModTime());
        jo.put("adminComment", getAdminComment());
        jo.put("requester", userProfile.getJSON());
        return jo;
    }


}
