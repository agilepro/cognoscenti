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
import com.purplehillsbooks.weaver.exception.WeaverException;

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
        try {
            Document newDoc = readOrCreateFile(superAdminFile, "super-admin");
            return new SuperAdminLogFile(superAdminFile, newDoc);
        }
        catch (Exception e) {
            throw WeaverException.newWrap("Unable to load the SuperAdminLogFile from %s", e, superAdminFile.getAbsolutePath());
        }
    }


    public void createAdminEvent(String objectId, long modTime,
            String modUser, String context) throws Exception {

        if (objectId == null || modUser == null || context == null
                || context.equals("")) {
            throw WeaverException.newBasic(
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
        setScalarLong("lastnotificationsenttime", time);
        setScalar("previousSendLog", getScalar("lastSendLog"));
        setScalar("lastSendLog", logTrace);
        save();
    }

    public long getLastNotificationSentTime() throws Exception {
        return getScalarLong("lastnotificationsenttime");
    }

    public String getSendLog() throws Exception {
        return getScalar("lastSendLog");
    }


    protected DOMFace getEventsParent() throws Exception {
        return requireChild("events", DOMFace.class);
    }

    public int incrementExceptionNo() throws Exception {
        int exceptionNo = (int) getScalarLong("exceptionNumber") + 1;
        setScalarLong("exceptionNumber", exceptionNo);
        save();
        return exceptionNo;
    }

    public void setEmailListenerWorking(boolean flag)
            throws Exception {
        setScalar("emailListenerPropertiesFlag",Boolean.toString(flag));
        save();
    }

    public void setEmailListenerProblem(Throwable ex) throws Exception {
        setScalar("emailListenerProblem",
                WeaverException.getFullMessage(ex));
        save();
    }

    public boolean getEmailListenerWorking() throws Exception {
        boolean emailListenerPropertiesFlag = false;
        String flag = getScalar("emailListenerPropertiesFlag");
        if (flag != null && flag.length() > 0 && "true".equals(flag)) {
            emailListenerPropertiesFlag = true;
        }
        return emailListenerPropertiesFlag;
    }
}
