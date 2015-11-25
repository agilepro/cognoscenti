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

import java.util.ArrayList;
import java.util.List;

/**
* a monomorphic class which holds details about a section definition
* read from the configuration file.  Users can create new definitions
* if they need to.
*/
public class SectionDef
{

    private static final int ANON_ACCESS   = 0;
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
    private static List<SectionFormat> allFormats = null;
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
        allFormats = null;
        defaultUnknownSectionFormat = null;
    }

    @SuppressWarnings("deprecation")
    private static void initialize()
    {
        allFormats = new ArrayList<SectionFormat>();
        allDefs = new ArrayList<SectionDef>();
        defaultUnknownSectionFormat = new SectionUnknown();

        SectionFormat cannonNotes =      new SectionForNotes();
        SectionFormat canonAttachments = new SectionAttachments();
        SectionFormat canonFolders =     new SectionFolders();
        SectionFormat cannonTasks =      new SectionTask();

        allDefs.add(new SectionDef(cannonNotes, "Comments", MEMBER_ACCESS, MEMBER_ACCESS,
                                   false, "Notes", true));
        allDefs.add(new SectionDef(canonAttachments, "Attachments", MEMBER_ACCESS, MEMBER_ACCESS,
                                   false, "Attachments", true));
        allDefs.add(new SectionDef(canonFolders, "Folders", MEMBER_ACCESS, MEMBER_ACCESS,
                                   false, "Folders", true));
        allDefs.add(new SectionDef(cannonTasks, "Tasks", MEMBER_ACCESS, MEMBER_ACCESS,
                                   false, "Tasks", true));

        //the rest of these are deprecated
        SectionFormat canonWiki = new SectionWiki();
        SectionFormat canonLink =        new SectionLink();
        SectionFormat canonPoll =        new SectionPoll();
        SectionFormat canonPrivate =     new SectionPrivate();



        //deprecated sections
        allDefs.add(new SectionDef(canonLink, "See Also", ANON_ACCESS, MEMBER_ACCESS,
                                   true, "XXX Public Links", false));
        allDefs.add(new SectionDef(canonPoll, "Poll", MEMBER_ACCESS, MEMBER_ACCESS,
                                   true, "XXX Poll", false));
        allDefs.add(new SectionDef(canonWiki, "Member Content", MEMBER_ACCESS, MEMBER_ACCESS,
                                   true, "XXX Content", false));
        allDefs.add(new SectionDef(canonWiki, "Description", ANON_ACCESS,   MEMBER_ACCESS,
                                   true, "Public Description", false));
        allDefs.add(new SectionDef(canonLink, "Links", MEMBER_ACCESS, MEMBER_ACCESS,
                                   true, "Links", false));
        //comments can be made private to the admin, so no need for this.
        allDefs.add(new SectionDef(canonWiki, "Author Notes",ADMIN_ACCESS, ADMIN_ACCESS,
                                   true, "XXX Admin Notes", false));
        //comments can be made private, so no need for this
        allDefs.add(new SectionDef(canonPrivate, "Private", PRIVATE_ACCESS, PRIVATE_ACCESS,
                                   true, "XXX Private", false));
        //comments can be made public, so no need for this
        allDefs.add(new SectionDef(cannonNotes, "Public Comments", ANON_ACCESS, PUBLIC_ACCESS,
                                   true, "XXX comment format", false));
        //public content is like public description
        allDefs.add(new SectionDef(canonWiki, "Public Content", ANON_ACCESS, MEMBER_ACCESS,
                                   true, "XXX Public Content", false));
        allDefs.add(new SectionDef(canonWiki, "Notes",       MEMBER_ACCESS, MEMBER_ACCESS,
                                   true,  "XXX Notes", false));
        //all attachments are in the regular attachments section
        allDefs.add(new SectionDef(canonAttachments, "Public Attachments", ANON_ACCESS, MEMBER_ACCESS,
                                   true, "XXX Public Attachments", false));

        allFormats.add(canonWiki);
        allFormats.add(canonLink);

        // Please see NGPage.createPage() to add the default sections to the newly created page.
    }

    public String getTypeName()
        throws Exception
    {
        return name;
    }


    public SectionFormat getFormat()
    {
        return format;
    }


    public static SectionDef getDefByName(String defName)
        throws Exception
    {
        if (allDefs == null) {
            initialize();
        }
        if (defName==null||defName.length()==0)
        {
            throw new RuntimeException("Must pass a non-null name to getDefByName");
        }
        for (SectionDef sd : allDefs)
        {
            if (sd.getTypeName().equals(defName)) {
                return sd;
            }
        }

        //create a new definition 'on the fly', deprecated
        SectionDef newsd = new SectionDef(defaultUnknownSectionFormat, defName, MEMBER_ACCESS, MEMBER_ACCESS,
                                   true, "Unknown Section "+defName, false);
        allDefs.add(newsd);
        return newsd;
    }
}
