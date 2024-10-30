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
import java.util.Hashtable;
import java.util.List;

import com.purplehillsbooks.weaver.exception.ProgramLogicError;
import com.purplehillsbooks.weaver.exception.WeaverException;

import org.w3c.dom.Document;

public class MicroProfileMgr {

    private static Hashtable<String, MicroProfileRecord> microProfiles = new Hashtable<String, MicroProfileRecord>();
    private static DOMFile  profileFile;
    private static List<AddressListEntry> allProfileIds = new ArrayList<AddressListEntry>();

    public synchronized static void loadMicroProfilesInMemory(Cognoscenti cog) throws Exception {
        ConfigFile config = cog.getConfig();
        File userFolder = config.getUserFolderOrFail();

        //this is in {userFolder}/microprofiles.profile
        File theFile = new File(userFolder, "microprofiles.profile");

        Document newDoc = DOMFile.readOrCreateFile(theFile, "micro-profiles");
        profileFile = new DOMFile(theFile, newDoc);
        refreshMicroProfilesHashTable();
        
        //now clean it up because in the past we allowed a lot of bad ids in the list
        List<String> badIdList = new ArrayList<String>();
        for (MicroProfileRecord profileRecord : getAllMicroProfileRecords()){
            String id = profileRecord.getId();
            if (!MicroProfileRecord.validEmailAddress(id)) {
                badIdList.add(id);
            }
        }
        
        if (badIdList.size()>0) {
            for (String badId : badIdList) {
                System.out.println("MicroProfileManager: Found and REMOVED a bad id from the file: "+badId);
                removeMicroProfileRecord(badId);
            }
            save();
        }
        
    }

    public synchronized static void clearAllStaticVars() {
        microProfiles = new Hashtable<String, MicroProfileRecord>();
        allProfileIds = new ArrayList<AddressListEntry>();
        profileFile = null;
    }


    public static void refreshMicroProfilesHashTable() throws Exception
    {
        microProfiles = new Hashtable<String, MicroProfileRecord>();
        allProfileIds = new ArrayList<AddressListEntry>();

        //right now there are a bunch of junk entries in the microprofiles table
        //so we are cleaning them out by considering only entries that look like
        //actual email addresses.   The rest are forgotten.
        for (MicroProfileRecord profileRecord : getAllMicroProfileRecords()){
            String lowerCase = profileRecord.getId().toLowerCase();
            if (MicroProfileRecord.validEmailAddress(lowerCase)) {
                microProfiles.put(lowerCase, profileRecord);
                allProfileIds.add(AddressListEntry.findOrCreate(profileRecord.getId()));
            }
        }
    }

    private static List<MicroProfileRecord> getAllMicroProfileRecords() throws Exception
    {
        if (profileFile==null)
        {
            throw WeaverException.newBasic("profileFile is null when it shoudl not be.  May not have been initialized correctly.");
        }
        List<MicroProfileRecord> vc = profileFile.getChildren("microprofile", MicroProfileRecord.class);
        return vc;
    }

    /**
     * Theoretically gets a list of all the email addresses that the system knows about,
     * some with names, and others without.
     */
    public static List<AddressListEntry> getAllUsers() throws Exception {
        List<AddressListEntry> res = new ArrayList<AddressListEntry>();
        for (MicroProfileRecord mpr : getAllMicroProfileRecords()) {
            String id = mpr.getId();
            if (MicroProfileRecord.validEmailAddress(id)) {
                String dName = mpr.getDisplayName();
                if (dName!=null && dName.length()>0) {
                    res.add(new AddressListEntry(id, dName));
                }
                else {
                    //seems like we should remember email addresses even if we don't have a name
                    res.add(AddressListEntry.findOrCreate(id));
                }
            }
        }
        return res;
    }

    public synchronized static void save() throws Exception{
        if(profileFile == null){
            throw WeaverException.newBasic("Unable to write micro profile information to disk.  The micro profile file name is not set.");
        }
        profileFile.save();
    }

    /**
    * find a MicroProfileRecord, or create one
    */
    public static MicroProfileRecord findOrCreateMicroProfile(String emailId, String displayName) throws Exception
    {
        if (emailId == null) {
            throw WeaverException.newBasic("createMicroProfileRecord was passed a null emailId parameter");
        }
        if (profileFile==null) {
            throw WeaverException.newBasic("profileFile is null when it should not be.  May not have been initialized correctly.");
        }
        if (!MicroProfileRecord.validEmailAddress(emailId)) {
            throw WeaverException.newBasic("This does not look like an email address: %s", emailId);
        }

        MicroProfileRecord profileRecord = findMicroProfileById(emailId);

        if (profileRecord!=null) {
            return profileRecord;
        }

        profileRecord = profileFile.createChild("microprofile", MicroProfileRecord.class);
        profileRecord.setId(emailId);
        profileRecord.setDisplayName(displayName);

        String lowerCase = emailId.toLowerCase();
        microProfiles.put(lowerCase, profileRecord);
        allProfileIds.add(AddressListEntry.parseCombinedAddress(emailId));
        return profileRecord;
    }

    public synchronized static boolean removeMicroProfileRecord(String id) throws Exception {
        if (id == null) {
            throw WeaverException.newBasic("removeMicroProfileRecord was passed a null emailId parameter");
        }
        if (profileFile==null) {
            throw WeaverException.newBasic("profileFile is null when it shoudl not be.  May not have been initialized correctly.");
        }
        List<MicroProfileRecord> vc = profileFile.getChildren("microprofile", MicroProfileRecord.class);
        for (MicroProfileRecord child : vc) {
            if (id.equals(child.getAttribute("id"))) {
                profileFile.removeChild(child);
                refreshMicroProfilesHashTable();
                return true;
            }
        }
        return false;
    }

    public synchronized static void setDisplayName(String id, String displayName) throws Exception
    {
        MicroProfileRecord child = findOrCreateMicroProfile(id, displayName);
        child.setDisplayName(displayName);
    }

    public static List<AddressListEntry> getAllProfileIds() throws Exception
    {
        return allProfileIds;
    }

    public static MicroProfileRecord findMicroProfileById(String id)
    {
        if (id == null) {
            throw new ProgramLogicError("findMicroProfileById was passed a null id parameter");
        }
        if (microProfiles != null){
            String lowerCase = id.toLowerCase();
            return microProfiles.get(lowerCase);
        }
        return null;
    }
}
