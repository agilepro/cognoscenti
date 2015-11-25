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
import java.util.Hashtable;
import java.util.List;

import org.socialbiz.cog.exception.NGException;
import org.socialbiz.cog.exception.ProgramLogicError;
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

        //check to see if it exists
        if (!theFile.exists()) {
            //this used to be in {dataFolder}/microprofiles.profile,  if it is there, then
            //move it to the new location as an 'upgrade'
            File dataFolder = config.getDataFolderOrFail();
            if (dataFolder.exists()) {
                File theOldFile = new File(dataFolder,"microprofiles.profile");
                if (theOldFile.exists()) {
                    UtilityMethods.copyFileContents(theOldFile,theFile);
                    theOldFile.delete();
                }
            }
        }

        Document newDoc = DOMFile.readOrCreateFile(theFile, "micro-profiles");
        profileFile = new DOMFile(theFile, newDoc);
        refreshMicroProfilesHashTable();
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

        for (MicroProfileRecord profileRecord : getAllMicroProfileRecords()){
            String lowerCase = profileRecord.getId().toLowerCase();
            microProfiles.put(lowerCase, profileRecord);
            allProfileIds.add(new AddressListEntry(profileRecord.getId()));
        }
    }

    public static List<MicroProfileRecord> getAllMicroProfileRecords() throws Exception
    {
        if (profileFile==null)
        {
            throw new ProgramLogicError("profileFile is null when it shoudl not be.  May not have been initialized correctly.");
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
            String dName = mpr.getDisplayName();
            if (dName!=null && dName.length()>0) {
                res.add(new AddressListEntry(mpr.getId(), dName));
            }
            else {
                //seems like we should remember email addresses even if we don't have a name
                res.add(new AddressListEntry(mpr.getId()));
            }
        }
        return res;
    }

    public synchronized static void save() throws Exception{
        if(profileFile == null){
            throw new NGException("nugen.exception.microprofile.name.not.set",null);
        }
        profileFile.save();
    }

    /**
    * find a MicroProfileRecord, or create one
    */
    public static MicroProfileRecord findOrCreateMicroProfile(String emailId, String displayName) throws Exception
    {
        if (emailId == null) {
            throw new ProgramLogicError("createMicroProfileRecord was passed a null emailId parameter");
        }
        if (profileFile==null) {
            throw new ProgramLogicError("profileFile is null when it should not be.  May not have been initialized correctly.");
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
            throw new ProgramLogicError("removeMicroProfileRecord was passed a null emailId parameter");
        }
        if (profileFile==null) {
            throw new ProgramLogicError("profileFile is null when it shoudl not be.  May not have been initialized correctly.");
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
