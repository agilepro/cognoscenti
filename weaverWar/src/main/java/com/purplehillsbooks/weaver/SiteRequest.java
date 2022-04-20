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

package com.purplehillsbooks.weaver;

import java.io.File;
import java.io.Writer;
import java.util.ArrayList;
import java.util.List;

import com.purplehillsbooks.weaver.mail.ChunkTemplate;
import com.purplehillsbooks.weaver.mail.EmailSender;
import com.purplehillsbooks.weaver.mail.MailInst;
import com.purplehillsbooks.json.JSONException;
import com.purplehillsbooks.json.JSONObject;
import com.purplehillsbooks.streams.MemFile;

/**
 *
 */
public class SiteRequest {
    JSONObject sr;

    public SiteRequest(JSONObject jo) {
        sr = jo;
    }

    public String getSiteName() throws Exception {
        return sr.getString("siteName");
    }
    public void setSiteName(String displayName) throws Exception {
        sr.put("siteName", displayName.trim());
    }

    public String getDescription() throws Exception {
        return sr.getString("purpose");
    }
    public void setDescription(String descr) throws Exception {
        sr.put("purpose", descr.trim());
    }

    /*
    public String getAdminComment() throws Exception {
        return sr.getString("adminComment");
    }
    public void setAdminComment(String descr) throws Exception {
        sr.put("adminComment", descr.trim());
    }
    */

    public String getSiteId() throws Exception {
        return sr.getString("siteId");
    }
    public void setSiteId(String siteId) throws Exception {
        sr.put("siteId", siteId.trim());
    }

    public String getRequestId() throws Exception {
        return sr.getString("requestId");
    }
    public void setRequestId(String requestId) throws Exception {
        sr.put("requestId", requestId);
    }

    /*
     * This returns email id of the user who has requested site.
     */
    public String getRequester() throws Exception {
        return sr.getString("requester");
    }
    public void setRequester(String requester) throws Exception {
        sr.put("requester", requester.trim());
    }


    public void setStatus(String status) throws Exception {
        sr.put("status", status.trim());
    }
    public String getStatus() throws Exception {
        return sr.getString("status");
    }



    public long getModTime() throws Exception {
        return sr.getLong("modTime");
    }
    public String getModUser() throws Exception {
        return sr.getString("modUser");
    }
    public void setModified(String userId, long time) throws Exception {
        sr.put("modUser", userId);
        sr.put("modTime", time);
    }


    public void sendSiteRequestEmail(AuthRequest ar) throws Exception {
        Cognoscenti cog = ar.getCogInstance();
        AddressListEntry from = new AddressListEntry(ar.getBestUserId());
        MailInst msg = MailInst.genericEmail("$", "$", "Site Approval for " + ar.getBestUserId(), "");
        File templateFile = cog.getConfig().getFileFromRoot("email/SiteRequest.chtml");
        for (UserProfile up : cog.getUserManager().getAllSuperAdmins(ar)) {
            JSONObject jo = new JSONObject();
            jo.put("req", this.getJSON());
            jo.put("baseURL", ar.baseURL);
            jo.put("admin", up.getJSON());

            OptOutAddr ooa = new OptOutSuperAdmin(up.getAddressListEntry());
            msg.setBodyFromTemplate(templateFile, jo, ooa);

            EmailSender.generalMailToOne(msg, from, ooa);
        }
    }


    public JSONObject getJSON() throws Exception {
        return sr;
    }

    public static String cleanUpSiteId(String siteId) {
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < siteId.length(); i++) {
            char ch = siteId.charAt(i);
            if (ch >= '0' && ch <= '9') {
                sb.append(ch);
            }
            else if (ch >= 'a' && ch <= 'z') {
                sb.append(ch);
            }
            else if (ch >= 'A' && ch <= 'Z') {
                sb.append(Character.toLowerCase(ch));
            }
        }
        if (sb.length()>12) {
            sb.setLength(12);
        }
        return sb.toString();
    }
    
    public void validateValues() throws Exception {
        if (getSiteName().length() < 4) {
            throw new JSONException("New site must have a name with 4 or more letters");
        }
        String siteId = getSiteId();
        if (siteId == null) {
            throw new JSONException("SiteId parameter can not be null in createNewSiteRequest");
        }
        if (siteId.length() < 4 || siteId.length() > 12) {
            throw new JSONException("SiteId must be four to twelve charcters/numbers long.  Received ({0})", siteId);
        }

        for (int i = 0; i < siteId.length(); i++) {
            char ch = siteId.charAt(i);
            if (ch < '0' || (ch > '9' && ch < 'a') || ch > 'z') {
                throw new JSONException("AccountId must have only letters and numbers - no spaces or punctuation.  Received ({0})",
                        siteId);
            }
        }
    }
    
    public void assertSiteNotExist(Cognoscenti cog) throws Exception {
        NGContainer site = cog.getSiteById(getSiteId());
        if (site != null) {
            throw new JSONException("Sorry, there already exists a site with that ID ({0}).  Please try again with a different ID.",
                    getSiteId());
        }        
    }

}
