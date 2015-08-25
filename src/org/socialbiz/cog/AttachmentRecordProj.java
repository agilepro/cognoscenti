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
import java.io.InputStream;
import java.util.List;

import org.socialbiz.cog.exception.NGException;
import org.w3c.dom.Document;
import org.w3c.dom.Element;

/**
* Project Attachments (attachments on NGProj) work differently than attachments on
* NGPage objects.  They are stored with real file names (not just IDs) in the same
* folder that the project is stored in.
*
* Former versions are stored in a subfolder named ".cog"
*
* This allows projects to exist in folders that already contain documents, and those
* documents automatically become part of the project.  This record implements the
* special attachment behavior that projects need.
*/
public class AttachmentRecordProj extends AttachmentRecord
{

    public AttachmentRecordProj(Document doc, Element definingElement, DOMFace attachmentContainer) {
        super (doc, definingElement, attachmentContainer);
    }

    public void setContainer(NGContainer newCon) throws Exception
    {
        if (!(newCon instanceof NGProj)) {
            throw new Exception("Problem: ProjectAttachment should only belong to NGProject, but somehow got a different kind of container.");
        }
        container = newCon;
    }

    public void updateActualFile(String oldName, String newName) throws Exception
    {
        if (container==null) {
            throw new Exception("ProjectAttachment record has not be innitialized correctly, there is no container setting.");
        }
        File folder = ((NGProj)container).containingFolder;
        File docFile = new File(folder, oldName);
        File newFile = new File(folder, newName);
        if (docFile.exists()) {
            //this will fail if the file already exists.
            docFile.renameTo(newFile);
        }
        else {
            //it is possible that user is 'fixing' the project by changing the name of an attachment
            //record to the name of an existing file.  IF this is the case, there may have been a
            //record of an "extra" file.  This will eliminate that.
            ((NGProj)container).removeExtrasByName(newName);
        }
    }

    /**
    * Get a list of all the versions of this attachment that exist.
    * The container is needed so that each attachment can caluculate
    * its own name properly.
    */
    public List<AttachmentVersion> getVersions(NGContainer ngc)
        throws Exception {
        if (!(ngc instanceof NGProj)) {
            throw new Exception("Problem: ProjectAttachment should only belong to NGProject, "
                    +"but somehow got a different kind of container.");
        }

        File projectFolder = ((NGProj)ngc).containingFolder;
        if (projectFolder==null) {
            throw new Exception("NGProject container has no containing folder????");
        }

        List<AttachmentVersion> list =
            AttachmentVersionProject.getProjectVersions(projectFolder, getNiceName(), getId());

        sortVersions(list);

        return list;
    }

    /**
    * Provide an input stream to the contents of the new version, and this method will
    * copy the contents into here, and then create a new version for that file, and
    * return the AttachmentVersion object that represents that new version.
    */
    public AttachmentVersion streamNewVersion(NGContainer ngc, InputStream contents,
            String userId, long timeStamp) throws Exception {

        if (!(ngc instanceof NGProj)) {
            throw new Exception("Problem: ProjectAttachment should only belong to NGProject, but somehow got a different kind of container.");
        }
        File projectFolder = ((NGProj)ngc).containingFolder;
        if (projectFolder==null) {
            throw new Exception("NGProject container has no containing folder????");
        }

        String displayName = getNiceName();
        AttachmentVersion av = AttachmentVersionProject.getNewProjectVersion(projectFolder,
                 displayName, getId(), contents);

        //update the record
        setVersion(av.getNumber());
        setStorageFileName(av.getLocalFile().getName());
        setModifiedDate(timeStamp);
        setModifiedBy(userId);

        return av;
    }

    /**
     * In some versioning schemes, there is a 'checked-out' copy of the file that
     * is the working version -- the user can modify that directly.  This gets
     * a version object pointing to it.
     *
     * Returns null if versioning system does not have working copy.
     */
    public AttachmentVersion getWorkingCopy(NGContainer ngc) throws Exception {
        AttachmentVersion highest = getHighestCommittedVersion(ngc);
        int ver = 0;
        if (highest!=null) {
            ver = highest.getNumber();
        }
        File projectFolder = ((NGProj)ngc).containingFolder;
        String attachName = getDisplayName();
        for (File testFile : projectFolder.listFiles())
        {
            String testName = testFile.getName();
            if (attachName.equalsIgnoreCase(testName)) {
                return new AttachmentVersionProject(testFile, ver+1, true, true);
            }
        }
        return null;
    }

    /**
     * Takes the working copy, and make a new internal, backed up copy.
     */
    public void commitWorkingCopy(NGContainer ngc) throws Exception {
        File projectFolder = ((NGProj)ngc).containingFolder;
        if (!projectFolder.exists()) {
            throw new Exception("Strange, this project's folder does not exist.  "
                    + "Something must be wrong: "+projectFolder);
        }
        File cogFolder = new File(projectFolder,".cog");
        if (!cogFolder.exists()) {
            //this might be the first thing in the COG folder
            cogFolder.mkdirs();
        }
        if (!cogFolder.exists()) {
            throw new Exception("Unable to create the COG folder: "+cogFolder);
        }
        AttachmentVersion workCopy = getWorkingCopy(ngc);
        String attachmentId = getId();
        String fileExtension = getFileExtension();
        File tempCogFile = File.createTempFile("~newP_"+attachmentId, fileExtension, cogFolder);
        File workFile = workCopy.getLocalFile();
        AttachmentVersionProject.copyFileContents(workFile, tempCogFile);

        //rename the special copy to have the right version number
        String specialVerFileName = "att"+attachmentId+"-"+Integer.toString(workCopy.getNumber())
                +fileExtension;
        File specialVerFile = new File(cogFolder, specialVerFileName);
        if (!tempCogFile.renameTo(specialVerFile)) {
            throw new NGException("nugen.exception.unable.to.rename.temp.file",
                new Object[]{tempCogFile,specialVerFile});
        }
    }

}
