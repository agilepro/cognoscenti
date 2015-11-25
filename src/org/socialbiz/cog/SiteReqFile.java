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

import java.io.File;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;

import org.socialbiz.cog.exception.NGException;
import org.socialbiz.cog.exception.ProgramLogicError;
import org.w3c.dom.Document;

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
public class SiteReqFile extends DOMFile {

    private static ArrayList<SiteRequest> allRequests = null;
    private static SiteReqFile siteReqFile = null;

    public synchronized static void clearAllStaticVars() {
        siteReqFile = null;
        allRequests = null;
    }

    public static synchronized void initSiteList(Cognoscenti cog) throws Exception {
        siteReqFile = readSiteReqFile(cog);

        long hundredDaysAgo = System.currentTimeMillis() - 8640000000L;
        List<SiteRequest> requests = siteReqFile.getChildren("request", SiteRequest.class);
        ArrayList<SiteRequest> outOfDate = new ArrayList<SiteRequest>();
        allRequests = new ArrayList<SiteRequest>();
        for (SiteRequest accountDetails : requests) {
            long time = accountDetails.getModTime();
            if (time < hundredDaysAgo) {
                // collect all the old requests
                outOfDate.add(accountDetails);
            }
            else {
                allRequests.add(accountDetails);
            }
        }

        // now actually get rid of the out of date children in case this is
        // saved back to file
        for (SiteRequest accountDetails : outOfDate) {
            siteReqFile.removeChild(accountDetails);
        }
        
        Collections.sort(allRequests, new SortByDateComparator());
    }


    public SiteReqFile(File path, Document newDoc) throws Exception {
        super(path, newDoc);
    }

    /**
     * Save the one file holding all the site requests
     */
    public static void saveAll() throws Exception {
        if (siteReqFile == null) {
            throw new ProgramLogicError(
                    "Program logic Error: attempting to save site request records "
                            + "when they have not been read yet.");
        }
        siteReqFile.save();
    }

    /**
     * Get ALL requests in the file
     */
    public static List<SiteRequest> getAllSiteReqs() throws Exception {
        if (allRequests == null) {
            throw new Exception("SiteReqFile is not initialized");
        }
        return allRequests;
    }

    /**
     * Get requests more than 48 hours old
     */
    public static List<SiteRequest> scanAllDelayedSiteReqs() throws Exception {
        if (allRequests == null) {
            throw new Exception("SiteReqFile is not initialized");
        }
        List<SiteRequest> delayedList = new ArrayList<SiteRequest>();

        long timeSpan = 0;
        long accountModTime = 0;
        for (SiteRequest oneReq : allRequests) {
            if ((oneReq.getStatus().equalsIgnoreCase("requested"))) {
                accountModTime = oneReq.getModTime();
                timeSpan = System.currentTimeMillis() - accountModTime;
                if (timeSpan >= 172800000) // 172800000 = 48 hours
                {
                    delayedList.add(oneReq);
                }
            }
        }
        return delayedList;
    }

    /**
     * Create new request for new site with the specified name and description.
     * And save the file.
     */
    public static SiteRequest createNewSiteRequest(String siteId, String displayName,
            String description, AuthRequest ar) throws Exception {
        if (allRequests == null) {
            initSiteList(ar.getCogInstance());
        }

        if (displayName.length() < 4) {
            throw new NGException("nugen.exception.site.name.length", null);
        }
        if (siteId == null) {
            throw new Exception("SiteId parameter can not be null");
        }
        if (siteId.length() < 4 || siteId.length() > 8) {
            throw new Exception(
                    "AccountId must be four to eight charcters/numbers long.  Received (" + siteId
                            + ")");
        }
        for (int i = 0; i < siteId.length(); i++) {
            char ch = siteId.charAt(i);
            if (ch < '0' || (ch > '9' && ch < 'A') || (ch > 'Z' && ch < 'a') || ch > 'z') {
                throw new Exception(
                        "AccountId must have only letters and numbers - no spaces or punctuation.  Received ("
                                + siteId + ")");
            }
        }

        // to avoid file system problems all ids need to be lower case.
        siteId = siteId.toLowerCase();

        // now, lets see if there is a site already with that ID
        NGContainer site = ar.getCogInstance().getSiteById(siteId);
        if (site != null) {
            throw new Exception("Sorry, there already exists an site with that ID (" + siteId
                    + ").  Please try again with a different ID.");
        }

        String status = "requested";
        String universalId = ar.getUserProfile().getUniversalId();
        String modUser = ar.getUserProfile().getKey();

        SiteRequest accountReq = siteReqFile.createNewRequest(siteId, displayName, description,
                status, universalId, ar.nowTime, modUser);

        saveAll();
        return accountReq;
    }

    public static SiteRequest getRequestByKey(String key) throws Exception {
        if (allRequests == null) {
            throw new Exception("SiteReqFile is not initialized");
        }
        for (SiteRequest accountDetails : allRequests) {
            if (key.equals(accountDetails.getRequestId())) {
                return accountDetails;
            }
        }
        return null;
    }

    public static void removeRequest(String reqId) throws Exception {
        if (allRequests == null) {
            throw new Exception("SiteReqFile is not initialized");
        }
        for (SiteRequest accountDetails : allRequests) {
            if (reqId.equals(accountDetails.getRequestId())) {
                siteReqFile.removeChild(accountDetails);
                allRequests.remove(accountDetails);
            }
        }
    }

    private SiteRequest createNewRequest(String siteId, String displayName, String description,
            String status, String universalId, long modTime, String modUser) throws Exception {
        if (siteId == null) {
            throw new RuntimeException("createNewRequest was passed a null siteId parameter");
        }
        if (displayName == null || displayName.equals("")) {
            throw new RuntimeException("createNewRequest was passed a null displayName parameter");
        }
        String requestedId = IdGenerator.generateKey();

        SiteRequest newRequest = createChild("request", SiteRequest.class);

        newRequest.setRequestId(requestedId);
        newRequest.setStatus(status);
        newRequest.setModified(modUser, modTime);

        newRequest.setName(displayName);
        newRequest.setDescription(description);
        newRequest.setSiteId(siteId);
        newRequest.setUniversalId(universalId);
        allRequests.add(newRequest);
        return newRequest;
    }

    /**
     * Read the site request file, and automatically remove old requests from
     * the in-memory version.
     */

    private static SiteReqFile readSiteReqFile(Cognoscenti cog) throws Exception {
        File requestFile = null;
        try {
            File userFolder = cog.getConfig().getUserFolderOrFail();
            requestFile = new File(userFolder, "siteRequests.xml");
            if (!requestFile.exists()) {
                //migration, this used to be in the data folder, so check there briefly
                //and if the old file is found, copy it to the new location, then delete
                //migration started March 2014
                File otherFile = new File(cog.getConfig().getDataFolderOrFail(), "requeted.account");
                if (otherFile.exists()) {
                    UtilityMethods.copyFileContents(otherFile, requestFile);
                    otherFile.delete();
                }
            }
            Document newDoc = readOrCreateFile(requestFile, "accounts-request");
            SiteReqFile site = new SiteReqFile(requestFile, newDoc);
            return site;
        }
        catch (Exception e) {
            throw new NGException("nugen.exception.unable.load.account.request.file",
                    new Object[] { requestFile }, e);
        }
    }

    public synchronized List<SiteRequest> scanPendingSiteRequests() throws Exception {
        List<SiteRequest> pendingReqs = new ArrayList<SiteRequest>();
        for (SiteRequest oneReq : allRequests) {
            if ((oneReq.getStatus().equalsIgnoreCase("requested"))
                    || (oneReq.getStatus().equalsIgnoreCase("Denied"))) {
                pendingReqs.add(oneReq);
            }
        }
        return pendingReqs;
    }

    public static List<SiteRequest> scanDeniedSiteReqs() throws Exception {
        if (allRequests == null) {
            throw new Exception("SiteReqFile is not initialized");
        }
        List<SiteRequest> deniedReqs = new ArrayList<SiteRequest>();
        for (SiteRequest oneReq : allRequests) {
            if ((oneReq.getStatus().equalsIgnoreCase("Denied"))) {
                deniedReqs.add(oneReq);
            }
        }
        return deniedReqs;
    }
    
    /**
     * Sort reverse chronological, so most recent is first
     *
     */
    private static class SortByDateComparator implements Comparator<SiteRequest> {

        public SortByDateComparator() {}
        
        @Override
        public int compare(SiteRequest arg0, SiteRequest arg1) {
            if (arg0.getModTime() == arg1.getModTime()) {
                return 0;
            }
            if (arg1.getModTime() < arg0.getModTime()) {
                return -1;
            }
            return 1;

        }
    }

}
