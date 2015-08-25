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

import org.socialbiz.cog.exception.ProgramLogicError;
import java.io.File;
import java.io.InputStream;
import java.util.Vector;

public class ResourceEntity {

    private String fullPath;
    private String decodedName;
    private String strangeUndefinedDisplayName = "";

    //if false, this is an empty pointer, if true it has info.
    private boolean hasDetails = false;

    private int type = ConnectionType.TYPE_FILE;
    private long lmodified = -1;
    private String path;
    private long size = -1;
    private int fcount = 0;

    private ConnectionType connection;
    private Vector<ResourceEntity> childList = new Vector<ResourceEntity>();

    /**
    * constructor is only available for classes in this package
    * this *should* be connection and full path.  TODO this.
    */
    ResourceEntity(ConnectionType _connection) {
        this.connection = _connection;
    }

    ResourceEntity(ConnectionType _connection, String fullPath) throws Exception {
        this.connection = _connection;
        setFullPath(fullPath);
    }

    ResourceEntity(ConnectionType _connection, String parentPath, String _decodedName) throws Exception {
        this.connection = _connection;
        this.decodedName = _decodedName;
        setFullPath(connection.extendPath(parentPath, decodedName));
    }

    /**
    * specify whether this is a file or a folder
    * either ConnectionType.TYPE_FOLDER or ConnectionType.TYPE_FILE
    */
    public void setType(int _type) {
        if (_type == ConnectionType.TYPE_FOLDER) {
            type = ConnectionType.TYPE_FOLDER;
        }
        else {
            type = ConnectionType.TYPE_FILE;
        }
    }

    /**
    * An entity can either be a file or a folder (collection).
    * This method returns true if this represents a file,
    * false if it represents a folder.
    */
    public boolean isFile() {
        if (type == ConnectionType.TYPE_FILE) {
            return true;
        }
        else {
            return false;
        }
    }

    /**
    * This is how a folder is given the children entities that represent the
    * files or folders that this folder contains.  Used only by the ConnectionType objects.
    */
    void addChildEntity(ResourceEntity cEntity) {
        childList.add(cEntity);
    }

    public Vector<ResourceEntity> getChidEntityList() {
        return childList;
    }

    /**
    * Pass in the decodedName of a child resource (or a potential child resource)
    * and the result is a ResourceEntity object that represents the child.
    */
    public ResourceEntity getChild(String decodedName) throws Exception {
        return new ResourceEntity(connection, fullPath, decodedName);
    }


    /**
    * Return the Resource Entity for the folder that contains this IF THERE IS ONE.
    * The root folder of the connection is a valid ResourceEntity,
    * but asking for the parent of the root folder will return null.
    */
    public ResourceEntity getParent() throws Exception {
        String baseAddress = connection.getBaseAddress();
        if (fullPath.length() <= baseAddress.length()) {
            return null;
        }
        String fullParentPath = connection.truncatePath(fullPath);
        if (fullParentPath.length() < baseAddress.length()) {
            return null;
        }
        return new ResourceEntity(connection, fullParentPath);
    }


    /**
    * The name of an entity is the 'address' of the entity, that is the
    * unique name that can be used to FIND the entity.  In the case of a
    * HTTP type entity, this should be the URL encoded version of the name.
    * This name is used in the protocol to retrieve the resource.
    * This name may not be suitable for displaying to users.
    */
    public String getName() {
        return connection.encodeName(decodedName);
    }
    public void setName(String name) {
        this.decodedName = connection.decodeName(name);
    }

    /**
    * The display name is the user visible name of this remote resource.
    * This is the version that is appropriate to be displayed.
    * For HTTP type entities, this will NOT be URL encoded.
    */
    public String getDecodedName() {
        return decodedName;
    }

    /**
    * This is a strange value for historic purpose.
    * Calling code was able to set a display name on the resource
    * no idea what that was supposed to represent, but preserving
    * functionality for now.
    */
    public String getDisplayName() {
        return strangeUndefinedDisplayName;
    }
    public void setDisplayName(String strangeUndefinedDisplayName) {
        this.strangeUndefinedDisplayName = strangeUndefinedDisplayName;
    }


    public long getLastModifed() {
        return lmodified;
    }
    public void setLastModifed(long lmodified) {
        this.lmodified = lmodified;
    }

    public void setFullPath(String newPath) throws Exception {
        fullPath = newPath;
        path = connection.getInternalPathOrFail(newPath);
        decodedName = connection.getFileName(newPath);
    }

    /**
    * This is the complete, fully qualified, external path to the remote resource
    */
    public String getFullPath() {
        return fullPath;
    }

    public String getFolderId() throws Exception{
        return connection.getConnectionId();
    }

    public ConnectionType getConnection() {
        return connection;
    }

    /**
    * The symbol represents both the connection (as a number)
    * followed by the relative path within the connection
    */
    public String getSymbol() throws Exception {
        if (path==null) {
            throw new ProgramLogicError("somehow the path variable never got set in the ResourceEntitiy");
        }
        return getFolderId() + path;
    }
    public RemoteLinkCombo getCombo() throws Exception {
        String ownerKey = connection.getOwnerKey();
        if (ownerKey==null) {
            throw new ProgramLogicError("owner has not be initialized on the connection object");
        }
        RemoteLinkCombo combo = RemoteLinkCombo.parseLink(ownerKey + "@" + getSymbol());
        return combo;
    }


    /**
    * This is the (local) path from the root of the connection object to this entity.
    * This path MUST start with a slash.
    * Use a slash by itself to indicate the root folder of the connection.
    */
    public String getPath() throws Exception {
        return connection.getInternalPathOrFail(fullPath);
    }


    public long getSize() {
        return size;
    }

    public void setSize(long size) {
        this.size = size;
    }

    public int getFileCount() {
        return fcount;
    }

    public void setFileCount(int fcount) {
        this.fcount = fcount;
    }



    /**
    * ResourceEntities are created empty, as pointers to a place in the webisphere
    * but later one might want to go look up the details with this command that causes
    * the system to go out and get the info.
    */
    public void fillInDetails(boolean expand) throws Exception {
        connection.lookUpDetails(this, expand);
        hasDetails = true;
    }

    /**
    * lets others know that this object carries valid info
    */
    public boolean isFilled() {
        return hasDetails;
    }

    public boolean exists() throws Exception {
        String parentPath = connection.truncatePath( getFullPath() );
        String name  = getDecodedName();
        return connection.checkAvailability(parentPath, name);
    }


    public boolean createFolder() throws Exception {
        return connection.createFolder(getFullPath());
    }

    public boolean deleteEntity() throws Exception {
        return connection.deleteEntity(getFullPath());
    }

    public InputStream getInputStream() throws Exception {
        return connection.openInputStream(this);
    }

    public boolean sendFileToRemote(File sourceFile, boolean overwrite) throws Exception {
        if (!overwrite) {
            if (exists()) {
                return false;
            }
        }
        connection.uploadFile(getFullPath(), sourceFile);
        return true;
    }

}
