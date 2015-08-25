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

/**
* An attachment can have many different versions, and this object
* represents a specific version.  The AttachmentRecord object will
* return a List of these when UI needs to display all the versions
* of a particular attachment.
*
* This object is not persisted, but instead is information collected
* by the versioning system when requested.
*
* There will be an implementation of this class for each kind of
* versioning system supported.  The AttachmentRecord object will have
* to determine the right implementation class for the server configuration.
*/
public interface AttachmentVersion
{

    /**
    * Returns the integer version number.  There is no minor and major version
    * but just a simple number that represent the sequence of versions.
    */
    public int getNumber();

    /**
    * Returns the date of the version, usually the date that the version was
    * checked into the system.
    */
    public long getCreatedDate();

    /**
    * Returns the size in bytes of this version.
    */
    public long getFileSize();

    /**
    * Generally an old, historical versions are read only.
    * But when you ask for a new version, you get a writeable
    * version object.
    */
    public boolean isReadOnly();

    /**
    * Indicates that the document has been modified, and those modifications
    * have not been saved yet.  Use commitLocalFile in order to save them permanently
    * in the version stream.
    */
    public boolean isModified();


    /**
    * Retrieves an input stream that the contents of the attachment can be acccessed
    * as a stream of bytes.
    */
    public InputStream getInputStream() throws Exception;
    
    
    /**
    * Retrieves the version (if necessary) and returns a File object that points to
    * the (temporary) file that contains the contents.
    *
    * Retrieved versions are usually read only.
    */
    public File getLocalFile();

    /**
    * If you had a writable version, after writing the contents to the file, you
    * must call commit in order to actually save the contents to the versioning system.
    * This will also release and clean up any unnecessary temporary files or resources.
    */
    //public void commitLocalFile();

    /**
    * If you called "getLocalFile" then it is possible that a temporary file has been created
    * or other resources help.  Calling release will either delete that file, or otherwise
    * free up the resources help to access the old version.
    */
    //public void releaseLocalFile();

    /**
     * Some versioning systems have a 'working copy' of the file hanging around in
     * the project folder, and not checked into the archive folder.  This working
     * copy is represented as a version of the document with a version number
     * one greater than the highest in the repository.
     *
     * Returns true if this AttachmentVersion record is referring to a working copy
     * Returns false if this is a version that is checked in.
     */
    public boolean isWorkingCopy();

    /**
     * Actually delete any file or record associated with this version
     */
    public void purgeLocalFile() throws Exception;
    
}
