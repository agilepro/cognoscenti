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
import java.util.ArrayList;
import java.util.List;

import org.socialbiz.cog.exception.NGException;
import org.socialbiz.cog.exception.ProgramLogicError;

/**
* A project folder file versioning system just represents multiple files
* in a file system.  The primary version (the latest version) is kept directly
* in the project folder using the name of the attachment.  All version are
* stored in a subfolder named ".cog". and are named as the internal ID and
* appending the version number to that ID.
* For example the following might exist in the file system:
*
*     great-cars/CarStatistics.xls    (this is equal to version 5)
*     great-cars/.cog/9987-1.xls
*     great-cars/.cog/9987-2.xls
*     great-cars/.cog/9987-3.xls
*     great-cars/.cog/9987-4.xls
*     great-cars/.cog/9987-5.xls
*
* In this case, the project folder (container) is "great-cars"
* The attachment id is "9987" which is unique within the container.
* The hyphen number at the end is the version number of the attachment.
*
* The drawback of the project versioning system is obvious: all versions of all
* files are in the file system at the same time, taking up space.
* Also, the files are all stored local to one system.
* The advantage, however, is that it does not depend upon complex code
* to unpack or otherwise manipulate things to access the versions.
* Simply find the version by name, and stream it out.  Very fast.
*
* Disks are cheap, and if your documents are mostly binary, then there is
* little need to use a differencing algorithm to store more efficiently.
*
* The current version file is duplicated: it is both in the version folder
* and it is also with the access name in the main folder.  First reason
* is to enable accurate detection of changes when a person is editing directly.
* Second, if the file is deleted, the display copy is removed, but the
* versioned copy is still there for accessing deleted documents.  If user
* is editing directly, the former version is preserved this way.
*
* Date and time of the version is taken directly from the file system date.
*
* There is no record of who made the change, and other helpful metadata that
* you would get in a real versioning system.  Might think about adding another
* structure in the .cog folder to track that.
*
* The attachment can be in some funny states.  (FILE, EXTRA, GONE, or URL)
*
* "FILE" is the normal situation, there is a file in the main folder, and there
* is at least one version in the COG folder that exactly equals it.
*
* "URL" is data only, there are no files on the disk.
*
* "EXTRA" is when a file exists in the folder, but NO file in the COG folder
* This means that the file has appeared through user saving it.  User might
* want to commit this to make a version in the COG folder.
*
*     great-cars/CarStatistics.xls
*
* "GONE" means that there is one or more versions in the COG folder,
* but there is nothing in the main folder.  There are two options to
* rectify: delete the file, or restore from latest committed version.
*
*     great-cars/.cog/9987-1.xls
*     great-cars/.cog/9987-2.xls
*     great-cars/.cog/9987-3.xls
*
* "GHOST" - this state does not exist, but it means that there is an attachment
* record, and there is no file at all, neither in the main folder, nor in the COG.
* In this case the attachment record should be ignored?
*
* "DELETED" - this state is when the user deleted the file.  There should still be
* files in the COG folder.
*
* "MODIFIED" is when there are all the normal files, but the file has been modified
* in the main folder so that it is NOT the same as the highest numbered version in
* the COG folder.  In this case the list of versions is extended and one more
* is included to represent the file in the folder.
*/
public class AttachmentVersionProject implements AttachmentVersion {
    private final File      actualFile;
    private final int       number;
    private final boolean   readOnly;
    public  boolean   isInMainFolder;    //DUPLICATED in the cog subfolder

    /**
    * This is the static method that will search the file system for all of the attachments
    * for a given container and attachment id.  Keeping this code here in the class
    * keeps all the Simple versioning system together in one maintainable place.
    * Other versioning system should have a static member like this as well to find the
    * the versions in their way.
    */
    public static List<AttachmentVersion> getProjectVersions(File projectfolder,  String attachName,
            String attachmentId) throws Exception  {
        if (projectfolder==null)  {
            throw new ProgramLogicError("null project folder sent to getProjectVersions");
        }
        if (attachName==null) {
            throw new ProgramLogicError("null attachment Name sent to getProjectVersions");
        }
        if (attachmentId==null) {
            throw new ProgramLogicError("null attachment Id sent to getProjectVersions");
        }
        if (!projectfolder.exists()) {
            throw new ProgramLogicError("getProjectVersions needs to be passed a valid projectfolder.  This does not exist: "+projectfolder.toString());
        }
        List<AttachmentVersion> list = new ArrayList<AttachmentVersion>();

        AttachmentVersionProject highestInternal = fillListReturnHighestInternalVersion(
                list, projectfolder,  attachName, attachmentId);

        int highestVersionSeen = 0;
        if (highestInternal!=null) {
            highestVersionSeen = highestInternal.getNumber();
        }

        //This is needed only if there have been recent edits to the display copy
        //this is detected by comparing lengths
        for (File testFile : projectfolder.listFiles()) {
            String testName = testFile.getName();
            if (attachName.equalsIgnoreCase(testName)) {
                //only add to the list of versions if it is a different length
                if (highestInternal==null || highestInternal.getFileSize()!=testFile.length()) {
                    list.add(new AttachmentVersionProject(testFile, highestVersionSeen+1, true, true));
                }
                break;
            }
        }

        return list;
    }

    public static AttachmentVersionProject fillListReturnHighestInternalVersion(
            List<AttachmentVersion> list, File projectfolder,  String attachName,
            String attachmentId) {
        File cogfolder = new File(projectfolder, ".cog");
        if (!cogfolder.exists()) {
            return null;
        }

        int highestVersionSeen = 0;
        AttachmentVersionProject highestVersion = null;
        // Here we make up a name to store the file on the server by combining the
        // attachment key, and then an integer that indicates how many
        // time the attachment has been modified.
        String storageNameBase = "att"+attachmentId+"-";
        int len = storageNameBase.length();

        for (File testFile : cogfolder.listFiles()) {
            String testName = testFile.getName();
            if (testName.startsWith(storageNameBase)) {
                String tail = testName.substring(len);
                //the version number is everything up to the dot
                //if no dot, then it is the entire rest of the name
                int dotPos = tail.indexOf(".");
                int ver = highestVersionSeen+1;
                if (dotPos>0) {
                    ver = DOMFace.safeConvertInt(tail.substring(0, dotPos));
                }
                else {
                    ver = DOMFace.safeConvertInt(tail);
                }
                if (ver==0) {
                    //what do we do if this is zero????
                    //ignore the file because it is not validly named, it does not have a
                    //version number, and so should not include in the list of files
                    continue;
                }
                AttachmentVersionProject avp = new AttachmentVersionProject(testFile, ver, true, false);
                list.add(avp);
                if (ver>highestVersionSeen) {
                    highestVersionSeen = ver;
                    highestVersion = avp;
                }
            }
        }
        return highestVersion;
    }



    /**
    * This static method does the right thing for project versioning system to get a new
    * version file. Calculates the name of the new file, and it streams the entire contents
    * to the file in the attachment folder.  This method is synchronized so that only one
    * thread will be creating a new version at a time, and there is no confusion about
    * what version a file is.
    */
    public synchronized static AttachmentVersionProject getNewProjectVersion(File projectFolder,
            String attachName, String attachmentId, InputStream contents) throws Exception {
        File cogFolder = new File(projectFolder,".cog");
        File currentFile = new File(projectFolder, attachName);
        if (!cogFolder.exists()) {
            cogFolder.mkdir();
        }

        int dotPos = attachName.lastIndexOf(".");
        String fileExtension = "";
        if (dotPos>0) {
            fileExtension = attachName.substring(dotPos);
        }

        //First, lets copy the new contents here, so that there is no blocking while in the synchronized
        //block.  Create a local file in the attachments folds, and copy the file there, so that
        //later the rename will be very fast.
        File tempFile = File.createTempFile("~newM_"+attachmentId, fileExtension, projectFolder);
        streamContentsToFile(contents, tempFile);

        //Second, make a copy of this in the cog directory.

        File tempCogFile = File.createTempFile("~newV_"+attachmentId, fileExtension, cogFolder);
        copyFileContents(tempFile, tempCogFile);

        //Third, check to see if the local copy in the project file has been modified,
        //if so, make a copy of that in the cog directory -- just INCASE it is needed
        File specialCogFile = null;
        if (currentFile.exists()) {
            specialCogFile = File.createTempFile("~newS_"+attachmentId, fileExtension, cogFolder);
            copyFileContents(currentFile, specialCogFile);
        }


        //Next, search through the directory, find the version number that is next available
        //in the cog folder, and rename the file to that version number, and then rename the
        //temp current file to the current name.  Must be done in a synchronized block
        //to avoid the problem with two threads claiming the same version number.
        synchronized(AttachmentVersionProject.class)
        {
            //first, see what versions exist, and get the latest
            List<AttachmentVersion> list = getProjectVersions(projectFolder, attachName, attachmentId);

            int newSubVersion = 1;
            for (AttachmentVersion av : list) {
                int thisVer = av.getNumber();
                if (((AttachmentVersionProject)av).isInMainFolder) {
                    //should never happen, but test to be sure
                    if (specialCogFile==null)  {
                        throw new Exception("Consistency problem: found a modified version in "
                                +"the project folder, but the file did not exist and was not copied: "
                                +currentFile);
                    }
                    //rename the special copy to have the right version number
                    String specialVerFileName = "att"+attachmentId+"-"+thisVer+fileExtension;
                    File specialVerFile = new File(cogFolder, specialVerFileName);
                    if (!specialCogFile.renameTo(specialVerFile)) {
                        throw new NGException("nugen.exception.unable.to.rename.temp.file",
                            new Object[]{specialCogFile,specialVerFile});
                    }
                    specialCogFile = null;
                }
                if (thisVer>=newSubVersion) {
                    newSubVersion = thisVer+1;
                }
            }

            //rename the file in the cog folder to have the right version id
            String newSubFileName = "att"+attachmentId+"-"+newSubVersion+fileExtension;
            File newCogFile = new File(cogFolder, newSubFileName);
            if (!tempCogFile.renameTo(newCogFile)) {
                throw new NGException("nugen.exception.unable.to.rename.temp.file",
                        new Object[]{tempCogFile,newCogFile});
            }

            if (currentFile.exists()) {
                currentFile.delete();
            }
            //clean up that special copy made 'just in case'
            if (specialCogFile!=null && specialCogFile.exists()){
                specialCogFile.delete();
            }
            if (!tempFile.renameTo(currentFile)) {
                throw new NGException("nugen.exception.unable.to.rename.temp.file",
                        new Object[]{tempFile,currentFile});
            }
            return new AttachmentVersionProject(currentFile, newSubVersion, false, true);
        }
    }


    protected static void copyFileContents(File source, File dest)  throws Exception {
        if (!source.exists())
        {
            throw new Exception("copyFileContents - The source file for copying does not exist: ("+source.toString()+")");
        }
        FileInputStream fis = new FileInputStream(source);
        streamContentsToFile(fis, dest);
        fis.close();
    }

    protected static void streamContentsToFile(InputStream source, File dest)  throws Exception {
        FileOutputStream fos = new FileOutputStream(dest);
        byte[] buf = new byte[2048];
        int amtRead = source.read(buf);
        while (amtRead>0)
        {
            fos.write(buf, 0, amtRead);
            amtRead = source.read(buf);
        }
        fos.close();
    }

    /**
    * Use the public static methods above to construct the file.
    */
    public AttachmentVersionProject(File versionFile, int newNumber, boolean isReadOnly, boolean theLatest) {
        actualFile = versionFile;
        number = newNumber;
        readOnly = isReadOnly;
        isInMainFolder = theLatest;
    }

    @Override
    public int getNumber() {
        return number;
    }

    @Override
    public long getCreatedDate() {
        return actualFile.lastModified();
    }

    @Override
    public long getFileSize() {
        return actualFile.length();
    }

    /**
    * Generally an old, historical version is read only.
    * But when you ask for a new version, you get a writeable
    * version object.
    */
    @Override
    public boolean isReadOnly() {
        return readOnly;
    }

    @Override
    public boolean isModified() {
        return isInMainFolder;
    }

    @Override
    public InputStream getInputStream() throws Exception {
        return new FileInputStream(actualFile);
    }
    
    @Override
    public File getLocalFile() {
        return actualFile;
    }

    @Override
    public boolean isWorkingCopy() {
        return isInMainFolder;
    }

    @Override
    public void purgeLocalFile() throws Exception {
        if (actualFile.exists()) {
            actualFile.delete();
        }
        if (actualFile.exists()) {
            throw new Exception("Attempted, and unable to delete file "+actualFile);
        }
    }

}
