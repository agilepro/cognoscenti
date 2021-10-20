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
import java.io.FileInputStream;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.List;

import com.purplehillsbooks.weaver.exception.NGException;
import com.purplehillsbooks.weaver.exception.ProgramLogicError;

import com.purplehillsbooks.json.JSONObject;
import com.purplehillsbooks.streams.StreamHelper;

/**
* A project folder file versioning system just represents multiple files
* in a file system.  All version are
* stored in a subfolder named ".cog". and are named as the internal ID and
* appending the version number to that ID.
* For example the following might exist in the file system:
*
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
* The current version file is no longer duplicated in the project folder.
* Used to be these for direct editing, but we only support servers now.
*
* Date and time of the version is taken directly from the file system date.
*
* There is no record of who made the change, and other helpful metadata that
* you would get in a real versioning system.  Might think about adding another
* structure in the .cog folder to track that.
*
* The attachment can be in these states:  (FILE, or URL)
*
* "FILE" is the normal situation, there is a file in the main folder, and there
* is at least one version in the COG folder that exactly equals it.
*
* "URL" is data only, there are no files on the disk.
*
* "EXTRA" - deprecated, not used
*
* "GONE" - deprecated, not used
*
* "GHOST" - deprecated, not used
*
* "DELETED" - this state is when the user deleted the file.  There should still be
* files in the COG folder.
*
* "MODIFIED" - deprecated, not used
*/
public class AttachmentVersion {
    private final AttachmentRecord attachment;
    private final File      actualFile;
    private final int       number;

    /**
    * This is the static method that will search the file system for all of the attachments
    * for a given container and attachment id.  Keeping this code here in the class
    * keeps all the Simple versioning system together in one maintainable place.
    * Other versioning system should have a static member like this as well to find the
    * the versions in their way.
    */
    public static List<AttachmentVersion> getProjectVersions(File projectfolder, AttachmentRecord att) throws Exception  {
        if (projectfolder==null)  {
            throw new ProgramLogicError("null workspace folder sent to getProjectVersions");
        }
        if (att==null)  {
            throw new ProgramLogicError("null attachment object sent to getProjectVersions");
        }
        String attachName = att.getNiceName();
        String attachmentId = att.getId();
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

        fillListReturnHighestInternalVersion(list, projectfolder,  att);

        /*
        int highestVersionSeen = 0;
        if (highestInternal!=null) {
            highestVersionSeen = highestInternal.getNumber();
        }

        //This is needed only if there have been recent edits to the display copy
        //this is detected by comparing lengths
        //--UPDATE: eliminating this because we do not allow editing of the file 
        //  on the server.  Original design included possibly running server locally
        //  and that caused an extra copy of the file to be in the project dir.
        //  That extra copy no longer needed, so no need to look for attachments in the main folder
        
        for (File testFile : projectfolder.listFiles()) {
            String testName = testFile.getName();
            if (attachName.equalsIgnoreCase(testName)) {
                //only add to the list of versions if it is a different length
                if (highestInternal==null || highestInternal.getFileSize()!=testFile.length()) {
                    list.add(new AttachmentVersion(att,testFile, highestVersionSeen+1, true, true));
                }
                break;
            }
        }
        */
        
        return list;
    }

    private static AttachmentVersion fillListReturnHighestInternalVersion(
            List<AttachmentVersion> list, File projectfolder, AttachmentRecord att ) throws Exception {
        String attachmentId = att.getId();
        File cogfolder = new File(projectfolder, ".cog");
        if (!cogfolder.exists()) {
            return null;
        }

        int highestVersionSeen = 0;
        AttachmentVersion highestVersion = null;
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
                AttachmentVersion avp = new AttachmentVersion(att, testFile, ver);
                list.add(avp);
                if (ver>highestVersionSeen) {
                    highestVersionSeen = ver;
                    highestVersion = avp;
                }
            }
        }
        return highestVersion;
    }


    static int counter = 1;
    private static String unique() {
        return Integer.toString(counter++);
    }
    
    
    /**
    * This static method does the right thing for project versioning system to get a new
    * version file. Calculates the name of the new file, and it streams the entire contents
    * to the file in the attachment folder.  This method is synchronized so that only one
    * thread will be creating a new version at a time, and there is no confusion about
    * what version a file is.
    */
    public synchronized static AttachmentVersion getNewProjectVersion(File projectFolder,
            AttachmentRecord att, InputStream contents) throws Exception {
        String attachName = att.getNiceName();
        String attachmentId = att.getId();
        File cogFolder = new File(projectFolder,".cog");
        //File currentFile = new File(projectFolder, attachName);
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
        File tempCogFile = new File(cogFolder, "~tmpV-"+attachmentId+"-"+unique()+fileExtension);
        StreamHelper.copyStreamToFile(contents, tempCogFile);

        //Second, make a copy of this in the main directory.
        //---Eliminate the copy in the main folder.  ONLY use the COG version
        //---No need for the unnecessary duplication
        //File tempFile = File.createTempFile("~newM_"+attachmentId, fileExtension, projectFolder);
        //copyFileContents(tempCogFile, tempFile);

        //Third, check to see if the local copy in the project file has been modified,
        //if so, make a copy of that in the cog directory -- just INCASE it is needed
        //---Since no file in the main folder, there is no need to check
        //File specialCogFile = null;
        //if (currentFile.exists()) {
        //    specialCogFile = File.createTempFile("~newS_"+attachmentId, fileExtension, cogFolder);
        //    copyFileContents(currentFile, specialCogFile);
        //}


        //Next, search through the directory, find the version number that is next available
        //in the cog folder, and rename the file to that version number, and then rename the
        //temp current file to the current name.  Must be done in a synchronized block
        //to avoid the problem with two threads claiming the same version number.
        synchronized(AttachmentVersion.class)
        {
            //first, see what versions exist, and get the latest
            List<AttachmentVersion> list = getProjectVersions(projectFolder, att);

            int newSubVersion = 1;
            for (AttachmentVersion av : list) {
                int thisVer = av.getNumber();
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

            //no more files in the project folder
            /*
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
            */
            return new AttachmentVersion(att, newCogFile, newSubVersion);
        }
    }


    /**
    * Use the public static methods above to construct the file.
    */
    public AttachmentVersion(AttachmentRecord att, File versionFile, int newNumber) throws Exception {
        attachment = att;
        actualFile = versionFile;
        number = newNumber;
    }


    public int getNumber() {
        return number;
    }


    public long getCreatedDate() {
        return actualFile.lastModified();
    }


    public long getFileSize() {
        return actualFile.length();
    }

    public InputStream getInputStream() throws Exception {
        return new FileInputStream(actualFile);
    }


    public File getLocalFile() {
        return actualFile;
    }


    public void purgeLocalFile() throws Exception {
        if (actualFile.exists()) {
            actualFile.delete();
        }
        if (actualFile.exists()) {
            throw new Exception("Attempted, and unable to delete file "+actualFile);
        }
    }

    public String getLink() {
        if ("URL".equals(attachment.getType())) {
            return attachment.getURLValue();
        }
        else {
            return "a/" + SectionUtil.encodeURLData(attachment.getNiceName())+"?version="+this.getNumber();
        }
    }

    public JSONObject getJSON() throws Exception {
        JSONObject jo = new JSONObject();
        jo.put("date", this.getCreatedDate());
        jo.put("link", this.getLink());
        jo.put("num",  this.getNumber());
        jo.put("size", this.getFileSize());
        return jo;
    }

}
