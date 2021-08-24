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
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;

import com.purplehillsbooks.json.JSONArray;
import com.purplehillsbooks.json.JSONException;
import com.purplehillsbooks.json.JSONObject;

/**
 * Holds New Site Requests
 *
 * This is a RARELY used file.  Very rare to request a site, and
 * also rare to review, grant, or deny it.  We are talking about
 * less than 0.1% of the traffic.  So don't waste a lot of time
 * storing this in memory.
 *
 * Requests are kept 100 days, and thrown away after that.
 * The site persists if granted, but otherwise forgotten about.
 *
 */
public class SiteReqFile {

    File requestFile;
    JSONObject contents;

    public SiteReqFile(Cognoscenti cog) throws Exception {
        File userFolder = cog.getConfig().getUserFolderOrFail();
        requestFile = new File(userFolder, "siteRequests.json");
        if (!requestFile.exists()) {
            //initialize it here
            contents = new JSONObject();
            contents.put("reqs", new JSONArray());
        }
        else {
            contents = JSONObject.readFromFile(requestFile);
            JSONArray reqs = contents.getJSONArray("reqs");

            //now remove anything more than ninety days old
            long ninetyDaysAgo = System.currentTimeMillis() - 90L*24*60*60*1000;  //ninety days
            JSONArray cleanList = new JSONArray();
            for (int i=0; i<reqs.length(); i++) {
                JSONObject oneReq = reqs.getJSONObject(i);
                if (oneReq.optLong("modTime",0)>=ninetyDaysAgo) {
                    cleanList.put(oneReq);
                }
            }
            contents.put("reqs", cleanList);
        }
    }

    public void save() throws Exception {
        contents.writeToFile(requestFile);
    }



    /**
     * Get all requests
     */
    public List<SiteRequest> getAllSiteReqs() throws Exception {
        List<SiteRequest> usersReqs = new ArrayList<SiteRequest>();
        JSONArray reqs = contents.getJSONArray("reqs");
        for (int i=0; i<reqs.length(); i++) {
            SiteRequest oneReq = new SiteRequest(reqs.getJSONObject(i));
            usersReqs.add( oneReq );
        }
        sortSiteRequests(usersReqs);
        return usersReqs;
    }

    /**
     * Get requests for one user
     */
    public List<SiteRequest> getUsersSiteRequests(UserProfile up) throws Exception {
        List<SiteRequest> usersReqs = new ArrayList<SiteRequest>();
        JSONArray reqs = contents.getJSONArray("reqs");
        for (int i=0; i<reqs.length(); i++) {
            SiteRequest oneReq = new SiteRequest(reqs.getJSONObject(i));
            if(up.hasAnyId(oneReq.getRequester())) {
                usersReqs.add( oneReq );
            }
        }
        sortSiteRequests(usersReqs);
        return usersReqs;
    }


    /**
     * Get requests more than 48 hours old
     */
    public List<SiteRequest> scanAllDelayedSiteReqs() throws Exception {
        List<SiteRequest> delayedList = new ArrayList<SiteRequest>();
        long fortyEightHoursAgo = System.currentTimeMillis() - 172800000; // 172800000 = 48 hours
        JSONArray reqs = contents.getJSONArray("reqs");
        for (int i=0; i<reqs.length(); i++) {
            SiteRequest oneReq = new SiteRequest(reqs.getJSONObject(i));
            if ((oneReq.getStatus().equalsIgnoreCase("requested"))) {
                if (oneReq.getModTime() < fortyEightHoursAgo) {
                    delayedList.add(oneReq);
                }
            }
        }
        sortSiteRequests(delayedList);
        return delayedList;
    }


    public SiteRequest getRequestByKey(String key) throws Exception {
        JSONArray reqs = contents.getJSONArray("reqs");
        for (int i=0; i<reqs.length(); i++) {
            SiteRequest oneReq = new SiteRequest(reqs.getJSONObject(i));
            if (key.equals(oneReq.getRequestId())) {
                return oneReq;
            }
        }
        return null;
    }













    /**
     * Create new request for new site with the specified name and description.
     * And save the file.
     */
    public static SiteRequest createNewSiteRequest(JSONObject newSiteReq, AuthRequest ar) throws Exception {

        Cognoscenti cog = ar.getCogInstance();

        String siteId      = newSiteReq.getString("siteId").toLowerCase();
        String siteName    = newSiteReq.getString("siteName");
        
        //need to assure this is lower case so that the folder is created
        //lower case.  On Linux this makes a difference.
        newSiteReq.put("siteId", siteId);


        // first, lets see if there is a site already with that ID
        NGContainer site = cog.getSiteById(siteId);
        if (site != null) {
            throw new JSONException("Sorry, there already exists a site with that ID ({0}).  Please try again with a different ID.",
                    siteId);
        }

        if (siteName.length() < 4) {
            throw new JSONException("New site must have a name with 4 or more letters");
        }
        if (siteId == null) {
            throw new JSONException("SiteId parameter can not be null in createNewSiteRequest");
        }
        if (siteId.length() < 4 || siteId.length() > 8) {
            throw new JSONException("SiteId must be four to eight charcters/numbers long.  Received ({0})", siteId);
        }

        for (int i = 0; i < siteId.length(); i++) {
            char ch = siteId.charAt(i);
            if (ch < '0' || (ch > '9' && ch < 'a') || ch > 'z') {
                throw new JSONException("AccountId must have only letters and numbers - no spaces or punctuation.  Received ({0})",
                        siteId);
            }
        }

        //actually update the file
        SiteReqFile siteReqFile = new SiteReqFile(cog);
        SiteRequest newRequest = siteReqFile.createNewRequest(newSiteReq);

        String preApprove = newSiteReq.optString("preapprove", "").toLowerCase();
        if (preApprove.equals("ccc2019") || preApprove.equals("ccc2018")) {
            HistoricActions ha = new HistoricActions(ar);
            ha.completeSiteRequest(newRequest, true, "Accepted pre-approval code: "+preApprove);
        }

        siteReqFile.save();

        return newRequest;
    }



    private SiteRequest createNewRequest(JSONObject newSiteReq) throws Exception {
        String requestedId = IdGenerator.generateKey();

        SiteRequest newRequest = new SiteRequest(newSiteReq);
        newRequest.setRequestId(requestedId);
        newRequest.setStatus("requested");
        newRequest.setModified("", System.currentTimeMillis());

        JSONArray reqs = contents.getJSONArray("reqs");
        reqs.put(newRequest.getJSON());
        return newRequest;
    }


    /**
     * Sort reverse chronological, so most recent is first
     *
     */
    public static void sortSiteRequests(List<SiteRequest> sortable) throws Exception {
        Collections.sort(sortable, new SortByDateComparator());
    }
    private static class SortByDateComparator implements Comparator<SiteRequest> {

        public SortByDateComparator() {}

        @Override
        public int compare(SiteRequest arg0, SiteRequest arg1) {
            try {
                if (arg0.getModTime() == arg1.getModTime()) {
                    return 0;
                }
                if (arg1.getModTime() < arg0.getModTime()) {
                    return -1;
                }
            }
            catch (Exception e) {
                //this should never happen...
                throw new RuntimeException(e);
            }
            return 1;

        }
    }

}
