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
import java.util.List;
import java.util.Locale;

import org.socialbiz.cog.exception.NGException;
import org.socialbiz.cog.exception.ProgramLogicError;
import org.w3c.dom.Document;

/**
 * SuperAdminHelper manages a file called 'SuperAdminInfo.xml' in the user folder
 * That file holds information relevant to the running of the whole server
 *
 * 1. automated scheduling of email messages
 * 2. list of new users who joined recently
 * 3. list of sites accepted/denied
 */
public class SuperAdminLogFile extends DOMFile {

    public SuperAdminLogFile(File path, Document doc) throws Exception {
        super(path, doc);
        requireChild("events", DOMFace.class);
    }

    public static SuperAdminLogFile getInstance(Cognoscenti cog) throws Exception {
        File superAdminFile = new File( cog.getConfig().getUserFolderOrFail(), "SuperAdminInfo.xml");
        Document newDoc = readOrCreateFile(superAdminFile, "super-admin");
        return new SuperAdminLogFile(superAdminFile, newDoc);
    }

    /**
     * This method returns a list of ALL sites created
     * within the last 100 days.
     */
    public List<NGBook> getAllNewSites(Cognoscenti cog) throws Exception {
        List<AdminEvent> allEvents = getEventsParent().getChildren("event",
                AdminEvent.class);
        List<NGBook> newSites = new ArrayList<NGBook>();
        long oneHundredDaysAgo = System.currentTimeMillis()-(86000*1000*100);
        for (AdminEvent event : allEvents) {
            if (event.getModTime()>oneHundredDaysAgo) {
                if (event.getContext().equals(AdminEvent.SITE_CREATED)) {
                    NGPageIndex ngpi = cog.getSiteByKey(event.getObjectId());
                    if (ngpi!=null) {
                        NGBook site = ngpi.getSite();
                        if (site!=null) {
                            newSites.add(site);
                        }
                    }
                }
            }
        }
        return newSites;
    }


    /**
     * This method returns a list of ALL users registered
     * TODO: either fix this
     * to return registrations created in a particular timespan OR: implement a
     * mechanism that removes the old registrations from the file, so that only
     * the new ones are left.
     */
    public List<UserProfile> getAllNewRegisteredUsers() throws Exception {
        List<AdminEvent> allEvents = getEventsParent().getChildren("event",
                AdminEvent.class);
        List<UserProfile> newUsers = new ArrayList<UserProfile>();
        for (AdminEvent event : allEvents) {
            if (event.getContext().equals(AdminEvent.NEW_USER_REGISTRATION)) {
                UserProfile profile = UserManager.getUserProfileByKey(event
                        .getObjectId());
                if (profile != null) {
                    //TODO: is this a bad error situation if null??
                    newUsers.add(profile);
                }
            }
        }
        return newUsers;
    }

    public void createAdminEvent(String objectId, long modTime,
            String modUser, String context) throws Exception {

        if (objectId == null || modUser == null || context == null
                || context.equals("")) {
            throw new RuntimeException(
                    "parameter is required to log an event for Super Admin");
        }

        AdminEvent newEvent = getEventsParent().createChild(
                "event", AdminEvent.class);
        newEvent.setObjectId(objectId);
        newEvent.setModified(modUser, modTime);
        newEvent.setContext(context);
        save();
    }

    public void setLastNotificationSentTime(long time, String logTrace)
            throws Exception {
        setScalar("lastnotificationsenttime", Long.toString(time));
        setScalar("previousSendLog", getScalar("lastSendLog"));
        setScalar("lastSendLog", logTrace);
        save();
    }

    public long getLastNotificationSentTime() throws Exception {
        String timeString = getScalar("lastnotificationsenttime");
        return safeConvertLong(timeString);
    }

    public String getSendLog() throws Exception {
        return getScalar("lastSendLog");
    }

    /**
     * Get a four digit numeric id which is unique on the page.
     */
    public String getUniqueOnPage() throws Exception {
        // getUniqueOnPage is not implemented. Do we need this???
        throw new ProgramLogicError("getUniqueOnPage is not implemented.");
    }

    protected DOMFace getEventsParent() throws Exception {
        return requireChild("events", DOMFace.class);
    }

    public void setLastExceptionNo(long exceptionNO) throws Exception {
        setScalar("exceptionNumber",
                String.valueOf(exceptionNO));
        save();
    }

    public long getNextExceptionNo() throws Exception {
        String exceptionNo = getScalar("exceptionNumber");
        long exceptionNO = safeConvertLong(exceptionNo) + 1;
        return exceptionNO;
    }

    public void setEmailListenerPropertiesFlag(boolean flag)
            throws Exception {
        setScalar("emailListenerPropertiesFlag",
                String.valueOf(flag));
        save();
    }

    public void setEmailListenerProblem(Throwable ex) throws Exception {
        setScalar("emailListenerProblem",
                NGException.getFullMessage(ex, Locale.getDefault()));
        save();
    }

    public boolean getEmailListenerPropertiesFlag() throws Exception {
        boolean emailListenerPropertiesFlag = false;
        String flag = getScalar("emailListenerPropertiesFlag");
        if (flag != null && flag.length() > 0 && "true".equals(flag)) {
            emailListenerPropertiesFlag = true;
        }
        return emailListenerPropertiesFlag;
    }

    public String getEmailListenerProblem() throws Exception {
        return getScalar("emailListenerProblem");
    }
}
