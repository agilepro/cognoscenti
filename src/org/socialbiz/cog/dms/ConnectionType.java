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
 * limitations under the License.package org.socialbiz.cog.dms;
 *
 * Contributors Include: Shamim Quader, Sameer Pradhan, Kumar Raja, Jim Farris,
 * Sandia Yang, CY Chen, Rajiv Onat, Neal Wang, Dennis Tam, Shikha Srivastava,
 * Anamika Chaudhari, Ajay Kakkar, Rajeev Rastogi
 */

package org.socialbiz.cog.dms;

import java.io.File;
import java.io.InputStream;

/**
* This base class must be extended by each "ConnectionType" because it
* represents a type of connection: HTTP, WebDav, SharePoint, LocalFile, SMB, etc.
* This implements all the methods to actually access a remote resource.
*/
public interface ConnectionType {

    public static final int TYPE_FOLDER = 0;
    public static final int TYPE_FILE = 1;

    public static final String PTCL_SMB = "SMB";
    public static final String PTCL_WEBDAV = "WEBDAV";
    public static final String PTCL_CVS = "CVS";
    public static final String PTCL_LOCAL = "LOCAL";
    public static final String PTCL_PUBLIC = "PUBLICWEB";

    public static final String FORM_FIELD_PRTCL = "ptc";
    public static final String FORM_FIELD_URL = "serverpath";
    public static final String FORM_FIELD_UID = "uid";
    public static final String FORM_FIELD_PWD = "pwd";
    public static final String FORM_FIELD_NAME = "displayname";


    /*
    * Gets a resourceEntity that is filled in with details.
    * Note, filling in the details take time to go out and get info
    */
    public ResourceEntity getResourceEntity(String rpath, boolean expand)throws Exception;


    public InputStream openInputStream(ResourceEntity ent)throws Exception;
    public boolean deleteEntity(String path)throws Exception;
    public boolean createFolder(String path) throws Exception;

    /***
    * Checks if file or folder exists in the given parent folder
    */
    public boolean checkAvailability(String parentPath, String fileName) throws Exception;

    /**
    * Upload the bytes of the specified file to the remote address.
    * Or fail with an exception that explains what when wrong.
    */
    public void uploadFile(String path, File srcFile)throws Exception;
    public void createNewFile(String parentPath, String fileName, File srcFile)throws Exception;

    public void createNewFile(ResourceEntity target, File srcFile)throws Exception;

    public void overwriteExistingDocument(ResourceEntity target, File srcFile)throws Exception;

    // Type-specific methods for composing and decomposing paths
    /**
    * Takes a name that might be used for display purpose, or that a user
    * might enter, and converts it to protocol specific encoded form.
    */
    public String encodeName(String displayName);

    /**
    * Takes a name in protocol specific encoded form and returns
    * a name that might be used for display or entry.
    */
    public String decodeName(String encodedName);

    /**
    * Given a path that is fully valid and encoded, along with a non encoded
    * display name of a file or folder, this routine puts the two together
    * into a single, properly encoded path.
    */
    public String extendPath(String path, String displayName);

    /**
    * truncatePath takes the last (tail) element off of a path, and returns
    * the path that would be the parent folder of the path that was passed.
    */
    public String truncatePath(String path) throws Exception;

    /**
    * getFileName returns the last (tail) element off of a path, decoded
    * and can be used as a display name of the file/folder on the end of path.
    */
    public String getFileName(String path) throws Exception;

    /**
    * getValidationError performs a check to see if the supplied path has
    * the correct form for the protocol.  If so, returns null.
    * If not, returns an exception describing one problem.
    */
    public Exception getValidationError(String path) throws Exception;

    /**
    * cleanPath attempts to clean up a supplied path and to fix any possible
    * validation problems.  E.G. it will convert space characters to %20.
    * No guarantee this will work completely since we can only guess what the
    * user meant with the invalid constructs.
    * For some protocols this does nothing but return the string passed in.
    */
    public String cleanPath(String path) throws Exception;


    /**
    * the key of the user that owns this connection
    */
    public String getOwnerKey() throws Exception;

    /**
    * the id of the connection
    */
    public String getConnectionId() throws Exception;

    /**
    * the id of the connection
    */
    public String getDisplayName() throws Exception;

    /**
    * the root address of the connection
    */
    public String getBaseAddress() throws Exception;

    public String getFullPath(String relPath) throws Exception;

    /**
    * This validates that the path is a valid part of this connection,
    * and it returns the proper "internal path" -- that is the relative
    * path from the base of the connection.
    *
    * Throws exception if full path is NOT part of connection.
    */
    public String getInternalPathOrFail(String fullPath) throws Exception;


    /**
    * The fully qualified external path to a resource is given
    * result is true if this connection contains that resource, false if not
    */
    public boolean contains(String fullPath) throws Exception;

    /**
    * The fully qualified external path to a resource is given
    * An empty ResourceEntity representing that resource is returned.
    * Call lookUpDetails if you want info about the remote file.
    * exception thrown if this connection does not contain that resource
    */
    public ResourceEntity getResource(String fullPath) throws Exception;

    /**
    * The path relative to the connection root to a resource is given
    * An empty ResourceEntity representing that resource is returned.
    * Call lookUpDetails if you want info about the remote file.
    * exception thrown if this connection does not contain that resource
    */
    public ResourceEntity getResourceInternal(String partialPath) throws Exception;

    /**
    * This is how a ResourceEntity asks to have its information filled in
    */
    void lookUpDetails(ResourceEntity needsFilling, boolean expand) throws Exception;

}
