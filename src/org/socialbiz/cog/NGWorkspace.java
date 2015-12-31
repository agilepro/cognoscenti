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
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.OutputStreamWriter;
import java.io.Writer;
import java.util.ArrayList;
import java.util.List;

import org.socialbiz.cog.exception.NGException;
import org.w3c.dom.Document;
import org.workcast.streams.HTMLWriter;

/**
* NGWorkspace is a Container that represents a Workspace.
* This kind of project/page/workspace exists anywhere in a site hierarchy.
* The old project (NGPage) existed only in a single date folder, and all the attachments
* existed in the attachment folder.  The old NGPage is not used anymore,
* but exists in name only in the class hierarchy.
*
* This workspace is represented by a folder in a site hierarchy,
* and the attachments are just files within that folder.
* The project file itself has a reserved name ".cog/ProjInfo.xml"
* and the old versions of attachments are in the ".cog" folder as well.
*/
public class NGWorkspace extends NGPage {
    /**
    * This workspace inhabits a folder on disk, and this is the path to the folder.
    */
    public File containingFolder;


    public NGWorkspace(File theFile, Document newDoc, NGBook site) throws Exception {
        super(theFile, newDoc, site);

        String name = theFile.getName();
        File cogFolder = theFile.getParentFile();
        if (name.endsWith(".sp")) {
            //this is a non-migrated case ... remove this code
            containingFolder = theFile.getParentFile();
        }
        else if (name.equalsIgnoreCase("ProjInfo.xml")) {
            if (!cogFolder.getName().equalsIgnoreCase(".cog")) {
                throw new Exception("Something is wrong with the data folder structure.  "
                        +"Tried to open a NGWorkspace file named "+name
                        +" except it should be in a folder named .cog, however "
                        +"it was in a folder named "+cogFolder.getName());
            }
            containingFolder = cogFolder.getParentFile();
        }
        else {
            throw new Exception("Something is wrong with the data folder structure.  "
                    +"Tried to open a NGWorkspace file named "+name
                    +" and don't know what to do with that.");
        }

    }

    @Override
    protected void migrateKeyValue(File theFile) throws Exception {
        if (theFile.getName().equalsIgnoreCase("ProjInfo.xml")) {
            File cogFolder = theFile.getParentFile();
            for (File child : cogFolder.listFiles()) {
                String childName = child.getName();
                if (childName.startsWith("key_")) {
                    String fileKey = SectionUtil.sanitize(childName.substring(4));
                    setKey(fileKey);
                }
            }
        }
        else if (theFile.getName().endsWith(".sp")) {
            super.migrateKeyValue(theFile);
        }
        else {
            throw new Exception("don't know how to make key for "+theFile);
        }
    }

    public void schemaUpgrade() throws Exception {
        getAllAttachments();
        this.getAllEmail();
        this.getAllGoals();
        this.getAllHistory();
        this.getAllLabels();
        for (NoteRecord note : this.getAllNotes()) {
            for (CommentRecord comm : note.getComments()) {
                //schema migration from before 101
                comm.schemaMigration();
            }
        }
        this.getAllRoles();
        for (MeetingRecord meet : getMeetings()) {
            for (AgendaItem ai : meet.getAgendaItems()) {
                for (CommentRecord comm : ai.getComments()) {
                    //schema migration from before 101
                    comm.schemaMigration();
                }
            }
        }
    }
    public int currentSchemaVersion() {
        return 101;
    }

    public static NGWorkspace readWorkspaceAbsolutePath(File theFile) throws Exception {
        if (!theFile.exists()) {
            throw new NGException("nugen.exception.file.not.exist", new Object[]{theFile});
        }
        try {
            String fullFilePath = theFile.toString();

            //look in the cache
            NGWorkspace newPage = pageCache.recall(fullFilePath);
            if (newPage==null) {
                Document newDoc;
                InputStream is = new FileInputStream(theFile);
                newDoc = DOMUtils.convertInputStreamToDocument(is, false, false);
                is.close();
                if (NGBook.fileIsInDataPath(theFile)) {
                    //since moving to the site scheme, all the workspaces should be site folder
                    //this is old code left from when all project/pages were in a single folder.
                    //remove this after Jan 2016
                    throw new Exception("I found a file in the data path which should never happen: "+theFile);
                }
                else {
                    newPage = new NGWorkspace(theFile, newDoc, null);
                }
            }

            //store into the cache.  Note, there is possibility
            //that another thread picks this up before we are done with it...
            //need to implement page lock mechanism to prevent this, and that
            //means having reliable clean-up code to store at the end of use.
            //Probably should lock the file reliably....
            pageCache.store(fullFilePath, newPage);
            return newPage;
        }
        catch (Exception e) {
            throw new NGException("nugen.exception.unable.to.read.file",new Object[]{theFile}, e);
        }
    }


    public List<AttachmentRecord> getAllAttachments() throws Exception {
        @SuppressWarnings("unchecked")
        List<AttachmentRecord> list = (List<AttachmentRecord>)(List<?>)
                attachParent.getChildren("attachment", AttachmentRecordProj.class);
        for (AttachmentRecord att : list) {
            att.setContainer(this);
            String atype = att.getType();
            boolean isDel = att.isDeleted();
            if (atype.equals("FILE") && !isDel)
            {
                File attPath = new File(containingFolder, att.getDisplayName());
                if (!attPath.exists()) {
                    //the file is missing, set to GONE, but should this be persistent?
                    att.setType("GONE");
                }
            }
            else if (atype.equals("GONE"))
            {
                File attPath = new File(containingFolder, att.getDisplayName());
                if (isDel || attPath.exists()) {
                    //either attachment deleted, or we found it again, so set it back to file
                    att.setType("FILE");
                }
            }
        }
        return list;
    }

    public AttachmentRecord createAttachment() throws Exception {
        AttachmentRecord attach = attachParent.createChild("attachment", AttachmentRecordProj.class);
        String newId = getUniqueOnPage();
        attach.setId(newId);
        attach.setContainer(this);
        attach.setUniversalId( getContainerUniversalId() + "@" + newId );
        return attach;
    }

    public void scanForNewFiles() throws Exception {
        File[] children = containingFolder.listFiles();
        List<AttachmentRecord> list = getAllAttachments();
        for (File child : children) {
            if (child.isDirectory()) {
                continue;
            }
            String fname = child.getName();
            if (fname.endsWith(".sp")) {
                //ignoring other possible project files
                continue;
            }
            if (fname.startsWith(".cog")) {
                //need to ignore .cogProjectView.htm and other files with .cog*
                continue;
            }

            //all others are possible documents at this point
            AttachmentRecord att = null;
            for (AttachmentRecord knownAtt : list) {
                if (fname.equals(knownAtt.getDisplayName())) {
                    att = knownAtt;
                }
            }
            if (att!=null) {
                continue;
            }
            att = createAttachment();
            att.setDisplayName(fname);
            att.setType("EXTRA");
            list.add(att);
        }
        List<AttachmentRecord> ghosts = new ArrayList<AttachmentRecord>();
        for (AttachmentRecord knownAtt : list) {
            if ("URL".equals(knownAtt.getType())) {
                continue;   //ignore URL attachments
            }
            AttachmentVersion aVer = knownAtt.getLatestVersion(this);
            if (aVer==null) {
                // this is a ghost if there are no versions at all.  Remove it
                ghosts.add(knownAtt);
                continue;
            }
            File attFile = aVer.getLocalFile();
            if (!attFile.exists()) {
                knownAtt.setType("GONE");
            }
        }

        //delete the ghosts, if any exist
        for (AttachmentRecord ghost : ghosts) {
            //it disappears without a trace.  But what else can we do?
            attachParent.removeChild(ghost);
        }
    }


    public void removeExtrasByName(String name) throws Exception {
        List<AttachmentRecordProj> list = attachParent.getChildren("attachment", AttachmentRecordProj.class);
        for (AttachmentRecordProj att : list) {
            if (att.getType().equals("EXTRA") && att.getDisplayName().equals(name)) {
                attachParent.removeChild(att);
                break;
            }
        }
    }


    public void saveFile(AuthRequest ar, String comment) throws Exception {
        super.saveFile(ar, comment);
        assureLaunchingPad(ar);
    }

    public void assureLaunchingPad(AuthRequest ar) throws Exception {
        File launchFile = new File(containingFolder, ".cogProjectView.htm");
        if (!launchFile.exists()) {
            boolean previousUI = ar.isNewUI();
            ar.setNewUI(true);
            OutputStream os = new FileOutputStream(launchFile);
            Writer w = new OutputStreamWriter(os, "UTF-8");
            w.write("<html><body><script>document.location = \"");
            HTMLWriter.writeHtml(w, ar.baseURL);
            HTMLWriter.writeHtml(w, ar.getDefaultURL(this));
            w.write("\";</script></body></html>");
            w.flush();
            w.close();
            ar.setNewUI(previousUI);
        }
    }


    public File getContainingFolder() {
        return containingFolder;
    }
}