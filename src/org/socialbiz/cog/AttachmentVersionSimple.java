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
* A simple file versioning system just represents multiple files
* in a file system, appending the version number to the name.
* For example the following might exist in the file system:
*
*     great-cars-9987.doc
*     great-cars-9987-2.doc
*     great-cars-9987-3.doc
*     great-cars-9987-4.doc
*     great-cars-9987-5.doc
*
* In this case, the container is "great-cars"
* The attachment id is "9987" which is unique within the container.
* The hyphen number at the end is the version number of the attachment.
*
* The drawback of the simple versioning system is obvious: all versions of all
* files are in the directory at the same time, taking up a lot of space.
* Also, the files are all stored local to one system.
* The advantage, however, is that it does not depend upon fancy code
* to unpack or otherwise manipulate things to access the versions.
* Simply find the version by name, and stream it out.  Very fast.
*
* Disks are cheap, and if your documents are mostly binary, then there is
* little need to use a differencing algorithm to store more efficiently.
*
* The original file does not have a version number modifyer.  IF not there,
* the assumption is that it is version 1.
*
* The version number can not exceed 999 or it might be confused with the
* attachment id.
*
* Date and time of the version is taken directly from the file system date.
*
* There is no record of who made the change, and other helpful metadata that
* you would get in a real versioning system.
*/
public class AttachmentVersionSimple implements AttachmentVersion
{
    private final File      actualFile;
    private final int       number;
    private final boolean   readOnly;

    // this must be initialized externally before use!
    public static File attachmentFolder;


    /**
    * This is the static method that will search the file system for all of the attachments
    * for a given container and attachment id.  Keeping this code here in the class
    * keeps all the Simple versioning system together in one maintainable place.
    * Other versioning system should have a static member like this as well to find the
    * the versions in their way.
    */
    public static List<AttachmentVersion> getSimpleVersions(String containerId,
        String attachmentId) throws Exception
    {
        if (attachmentFolder==null)
        {
            throw new ProgramLogicError("AttachmentVersionSimple was not initialized, there is no attachmentFolder setting set.");
        }
        if (!attachmentFolder.exists())
        {
            throw new ProgramLogicError("AttachmentVersionSimple was not initialized correctly, the attachmentFolder does not exist.");
        }
        List<AttachmentVersion> list = new ArrayList<AttachmentVersion>();

        //This seems like a slow way to do it, but it should be about as fast as using the
        //FileNameFilter option.  Just walk through all the files and test if the name starts
        //with the right things, and then parse the version number out of that.
        File[] allAttachments = attachmentFolder.listFiles();

        // Here we make up a name to store the file on the server by combining the
        // page key, the attachment key, and then an integer that indicates how many
        // time the attachment has been modified.
        String storageNameBase = containerId+"-"+attachmentId;
        int len = storageNameBase.length();

        for (File testFile : allAttachments)
        {
            String testName = testFile.getName();
            if (testName.startsWith(storageNameBase))
            {
                String tail = testName.substring(len);
                //this can either have a version number, or have a dot for extension
                //nothing else is allowed
                char ch = tail.charAt(0);
                if (ch=='-')
                {
                    int dotPos = tail.indexOf(".");
                    int ver = 1;
                    if (dotPos>0)
                    {
                        ver = DOMFace.safeConvertInt(tail.substring(1, dotPos));
                    }
                    list.add(new AttachmentVersionSimple(testFile, ver, true));
                }
                else if (ch =='.')
                {
                    list.add(new AttachmentVersionSimple(testFile, 1, true));
                }
                else
                {
                    //ignore this file, must be for some other attachment that coincidentally
                    //has a container id that matches this one with attachment id.
                }
            }
        }

        return list;
    }


    /**
    * This static method does the right thing for simple versioning system to get a new
    * version file. Calculates the name of the new file, and it streams the entire contents
    * to the file in the attachment folder.  This method is synchronized so that only one
    * thread will be creating a new version at a time, and there is no confusion about
    * what version a file is.
    */
    public synchronized static AttachmentVersionSimple getNewSimpleVersion(String containerId,
        String attachmentId, String fileExtension, InputStream contents) throws Exception
    {
        if (attachmentFolder==null)
        {
            throw new ProgramLogicError("AttachmentVersionSimple was not initialized, there is no attachmentFolder setting set.");
        }
        if (!attachmentFolder.exists())
        {
            throw new ProgramLogicError("AttachmentVersionSimple was not initialized correctly, the attachmentFolder does not exist.");
        }
        //First, lets copy the file here, so that there is no blocking while in the synchronized
        //block.  Create a local file in the attachments folds, and copy the file there, so that
        //later the rename will be very fast.
        File tempFile = File.createTempFile("~new_"+containerId, fileExtension, attachmentFolder);
        FileOutputStream fos = new FileOutputStream(tempFile);

        byte[] buf = new byte[2048];
        int amtRead = contents.read(buf);
        while (amtRead>0)
        {
            fos.write(buf, 0, amtRead);
            amtRead = contents.read(buf);
        }
        fos.close();

        //Next, search through the directory, find the version number that is next available
        //and rename the file to that version number.  Must be done in a synchronized block
        //to avoid the problem with two threads claiming the same version number.
        synchronized(attachmentFolder)
        {
            //first, see what versions exist
            List<AttachmentVersion> list = getSimpleVersions(containerId, attachmentId);

            int newVer = 1;
            for (AttachmentVersion av : list)
            {
                int thisVer = av.getNumber();
                if (thisVer>=newVer)
                {
                    newVer = thisVer+1;
                }
            }

            String newFileName = containerId+"-"+attachmentId+"-"+newVer+"."+fileExtension;
            File newFile = new File(attachmentFolder, newFileName);
            if (!tempFile.renameTo(newFile))
            {
                throw new NGException("nugen.exception.unable.to.rename.temp.file",new Object[]{tempFile,newFile});
            }
            return new AttachmentVersionSimple(newFile, newVer, false);
        }

    }

    /**
    * Use the public static methods above to construct the file.
    */
    public AttachmentVersionSimple(File versionFile, int newNumber, boolean isReadOnly)
    {
        actualFile = versionFile;
        number = newNumber;
        readOnly = isReadOnly;
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
        //this type of storage does not allow for locally modified files
        return false;
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
        //simple does not have any working copy, never true
        return false;
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
