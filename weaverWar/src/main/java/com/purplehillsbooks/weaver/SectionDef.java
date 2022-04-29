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

import java.util.ArrayList;
import java.util.List;

/**
* a monomorphic class which holds details about a section definition
* read from the configuration file.  Users can create new definitions
* if they need to.
*/
public class SectionDef
{

    public static final int PUBLIC_ACCESS = 1;
    public static final int MEMBER_ACCESS = 2;
    public static final int ADMIN_ACCESS  = 3;
    public static final int PRIVATE_ACCESS = 4;


    //holds the section ele element
    public SectionFormat format = null;
    public String name          = null;
    public String displayName   = null;
    public int    viewAccess    = ADMIN_ACCESS;
    public int    editAccess    = ADMIN_ACCESS;

    //mark deprecated sections so they can not be ADDED to pages
    //and so that existing copies can indicate that the information
    //should be moved to a different section.
    public boolean deprecated = false;

    //mark required sections to prevent deleting
    public boolean required   = false;

    //
    private static List<SectionDef> allDefs = null;
    private static SectionFormat defaultUnknownSectionFormat = null;
    public SectionDef(SectionFormat newFormat, String newName, int view, int edit, boolean depr, String dName, boolean req)
    {
        if (allDefs == null) {
            initialize();
        }
        format      = newFormat;
        name        = newName;
        viewAccess  = view;
        editAccess  = edit;
        deprecated  = depr;
        displayName = dName;
        required    = req;
    }

    /**
    * Set all static values back to their initial states, so that
    * garbage collection can be done, and subsequently, the
    * class will be reinitialized.
    */
    public synchronized static void clearAllStaticVars()
    {
        allDefs = null;
        defaultUnknownSectionFormat = null;
    }


    private static void initialize() {
        allDefs = new ArrayList<SectionDef>();

        defaultUnknownSectionFormat = new SectionUnknown();
        SectionFormat cannonNotes =      new SectionForNotes();
        SectionFormat canonAttachments = new SectionAttachments();
        SectionFormat cannonTasks =      new SectionTask();
        SectionFormat canonFolders     = new SectionFolders();

        allDefs.add(new SectionDef(cannonNotes, "Comments", MEMBER_ACCESS, MEMBER_ACCESS,
                                   false, "Notes", true));
        allDefs.add(new SectionDef(canonAttachments, "Attachments", MEMBER_ACCESS, MEMBER_ACCESS,
                                   false, "Attachments", true));
        allDefs.add(new SectionDef(cannonTasks, "Tasks", MEMBER_ACCESS, MEMBER_ACCESS,
                                   false, "Tasks", true));
        allDefs.add(new SectionDef(canonFolders, "Folders", MEMBER_ACCESS, MEMBER_ACCESS,
                false, "Folders", true));
    }

    public String getTypeName() throws Exception {
        return name;
    }


    public SectionFormat getFormat()
    {
        return format;
    }


    public static SectionDef getDefByName(String defName) throws Exception {
        if (allDefs == null) {
            initialize();
        }
        if (defName==null||defName.length()==0) {
            throw new RuntimeException("Must pass a non-null name to getDefByName");
        }
        for (SectionDef sd : allDefs) {
            if (sd.getTypeName().equals(defName)) {
                return sd;
            }
        }
        
        throw new RuntimeException("Unable to find a section with the name: "+defName);
    }
}
