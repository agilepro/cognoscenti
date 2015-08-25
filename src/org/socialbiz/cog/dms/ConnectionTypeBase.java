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

import org.socialbiz.cog.exception.NGException;
import org.socialbiz.cog.exception.ProgramLogicError;
import java.io.File;
import java.io.InputStream;

/**
* This base class must be extended by each "ConnectionType" because it
* represents a type of connection: HTTP, WebDav, SharePoint, LocalFile, SMB, etc.
* This implements all the methods to actually access a remote resource.
*/
public abstract class ConnectionTypeBase implements ConnectionType {

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


    protected ConnectionSettings folder = null;

    //protected contructor only for base class init
    protected ConnectionTypeBase(ConnectionSettings cData)
    {
        folder = cData;
        if (folder==null)
        {
            //just being paranoid and making sure that this is constructed correctly
            throw new RuntimeException("Can not create a connection object with a null folder");
        }
    }

    /*
    * Gets a resourceEntity that is filled in with details.
    * Note, filling in the details take time to go out and get info
    */
    public ResourceEntity getResourceEntity(String rpath, boolean expand)throws Exception
    {
        if (rpath==null) {
            throw new ProgramLogicError("getResourceEntity received a null rpath parameter, must be at least a slash");
        }
        if (rpath.length()>0 && !rpath.startsWith("/")) {
            throw new ProgramLogicError("getResourceEntity received a rpath that does not start with slash: ("+rpath+")");
        }
        ResourceEntity val = getResourceInternal(rpath);
        val.fillInDetails(expand);
        return val;
    }


    public abstract InputStream openInputStream(ResourceEntity ent)throws Exception;
    public abstract boolean deleteEntity(String path)throws Exception;
    public abstract boolean createFolder(String path) throws Exception;

    /***
    * Checks if file or folder exists in the given parent folder
    */
    public abstract boolean checkAvailability(String parentPath, String fileName) throws Exception;

    /**
    * Upload the bytes of the specified file to the remote address.
    * Or fail with an exception that explains what when wrong.
    */
    public abstract void uploadFile(String path, File srcFile)throws Exception;
    public abstract void createNewFile(String parentPath, String fileName, File srcFile)throws Exception;

    public void createNewFile(ResourceEntity target, File srcFile)throws Exception
    {
        //this is backward, the other method should call this one
        String parentPath = truncatePath( target.getFullPath() );
        String name  = target.getDecodedName();
        createNewFile(parentPath, name, srcFile);
    }


    public abstract void overwriteExistingDocument(String parentPath, String fileName, File srcFile) throws Exception;

    public void overwriteExistingDocument(ResourceEntity target, File srcFile)throws Exception
    {
        //this is backward, the other method should call this one
        String parentPath = truncatePath( target.getFullPath() );
        String name  = target.getDecodedName();
        overwriteExistingDocument(parentPath, name, srcFile);
    }

    // Type-specific methods for composing and decomposing paths
    /**
    * Takes a name that might be used for display purpose, or that a user
    * might enter, and converts it to protocol specific encoded form.
    */
    public String encodeName(String displayName) {
        //default behavior is no change, no encoding
        return displayName;
    }

    /**
    * Takes a name in protocol specific encoded form and returns
    * a name that might be used for display or entry.
    */
    public String decodeName(String encodedName){
        //default behavior is no change, no encoding
        return encodedName;
    }

    /**
    * Given a path that is fully valid and encoded, along with a non encoded
    * display name of a file or folder, this routine puts the two together
    * into a single, properly encoded path.
    */
    public String extendPath(String path, String displayName) {
        if (path.endsWith("/")) {
            return path + encodeName(displayName);
        } else {
            return path + "/" + encodeName(displayName);
        }
    }
    /**
    * truncatePath takes the last (tail) element off of a path, and returns
    * the path that would be the parent folder of the path that was passed.
    */
    public String truncatePath(String path) throws Exception {
        //this needs to handle both the case where the string ends with
        //slash, and where it does not end with slash.  Start looking
        //at length-2 in order to skip the last character in case it was a slash
        int slashPos = path.lastIndexOf("/", path.length()-2);
        if (slashPos<=0) {
            throw new NGException("nugen.exception.cant.trauncate.path", new Object[]{path});
        }
        return path.substring(0, slashPos);
    }

    /**
    * getFileName returns the last (tail) element off of a path, decoded
    * and can be used as a display name of the file/folder on the end of path.
    */
    public String getFileName(String path) throws Exception {
        //this needs to handle both the case where the string ends with
        //slash, and where it does not end with slash.  Start looking
        //at length-2 in order to skip the last character in case it was a slash
        int slashPos = path.lastIndexOf("/", path.length()-2);
        if (slashPos<=0) {
            throw new NGException("nugen.exception.cant.find.file.no.slash", new Object[]{path});
        }
        String encodedName = path.substring(slashPos+1);
        //now trim the slash off the end if necessary
        if (encodedName.endsWith("/"))
        {
            encodedName = encodedName.substring(0, encodedName.length()-1);
        }
        return decodeName(encodedName);
    }

    /**
    * getValidationError performs a check to see if the supplied path has
    * the correct form for the protocol.  If so, returns null.
    * If not, returns an exception describing one problem.
    */
    public abstract Exception getValidationError(String path) throws Exception;

    /**
    * cleanPath attempts to clean up a supplied path and to fix any possible
    * validation problems.  E.G. it will convert space characters to %20.
    * No guarantee this will work completely since we can only guess what the
    * user meant with the invalid constructs.
    * For some protocols this does nothing but return the string passed in.
    */
    public abstract String cleanPath(String path) throws Exception;


    /**
    * the key of the user that owns this connection
    */
    public String getOwnerKey() throws Exception
    {
        return folder.getOwnerKey();
    }
    /**
    * should not be needed but temporary fix to set and store until I can figure
    * out how to get this from the UserPage object directly from the ConnectionSettings
    */
    public void setOwnerKey(String newKey) throws Exception
    {
        folder.setOwnerKey(newKey);
    }


    /**
    * the id of the connection
    */
    public String getConnectionId() throws Exception
    {
        return folder.getId();
    }
    /**
    * the id of the connection
    */
    public String getDisplayName() throws Exception
    {
        return folder.getDisplayName();
    }
    /**
    * the connection settings object
    */
    public ConnectionSettings getConnectionSettings()
    {
        return folder;
    }
    /**
    * the root address of the connection
    */
    public String getBaseAddress() throws Exception
    {
        return folder.getBaseAddress();
    }
    public String getFullPath(String relPath) throws Exception
    {
        //this is just a sanity check that the path has the right form.
        //might remove this some day for performance reasons.
        if (!relPath.startsWith("/")) {
            throw new ProgramLogicError("attempt to calculate resource full path when the relative path does not start with a slash ("+relPath+")");
        }
        return folder.getBaseAddress()+relPath;
    }

    public String getInternalPathOrFail(String fullPath) throws Exception
    {
        if (!contains(fullPath)) {
            throw new NGException("nugen.exception.wrong.attempt.to.set.path", new Object[]{fullPath, folder.getBaseAddress()});
        }

        int basePathLen = folder.getBaseAddress().length();

        //normalize for trailing slash.  If the full path ends with a slash, then
        //this the SAME as having no slash on the end, so remove it.  In general,
        //paths should NEVER end with a slash, but no problem, just remove it.
        while (fullPath.endsWith("/") && fullPath.length()>basePathLen) {
            fullPath = fullPath.substring(0,fullPath.length()-1);
        }

        String path = fullPath.substring(basePathLen);
        if (path.length()>0 && !path.startsWith("/")) {
            throw new ProgramLogicError("Path supplied ("+fullPath
                +") should have a slash after the connection base, but instead we get a relative path of ("+path+").");
        }
        return path;
    }


    /**
    * The fully qualified external path to a resource is given
    * result is true if this connection contains that resource, false if not
    */
    public boolean contains(String fullPath) throws Exception
    {
        return (fullPath.startsWith(folder.getBaseAddress()));
    }

    /**
    * The fully qualified external path to a resource is given
    * An empty ResourceEntity representing that resource is returned.
    * Call lookUpDetails if you want info about the remote file.
    * exception thrown if this connection does not contain that resource
    */
    public ResourceEntity getResource(String fullPath) throws Exception
    {
        return new ResourceEntity(this, fullPath);
    }

    /**
    * The path relative to the connection root to a resource is given
    * An empty ResourceEntity representing that resource is returned.
    * Call lookUpDetails if you want info about the remote file.
    * exception thrown if this connection does not contain that resource
    */
    public ResourceEntity getResourceInternal(String partialPath) throws Exception
    {
        return new ResourceEntity(this, getBaseAddress()+partialPath);
    }

    /**
    * This is how a ResourceEntity asks to have its information filled in
    */
    public abstract void lookUpDetails(ResourceEntity needsFilling, boolean expand) throws Exception;

}
