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

import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.socialbiz.cog.exception.NGException;
import org.socialbiz.cog.exception.ProgramLogicError;
import org.socialbiz.cog.DOMFace;
import org.socialbiz.cog.util.TextEncrypter;

/**
* This class represents a Repository Connection.
* A repository connection is owned by a single user, and contains the path
* to a remote resource, a username and password to use at that repository.
*/
public class ConnectionSettings extends DOMFace {

    public static String ATT_ID = "id";
    private static String ATT_DISPLAY_NAME = "displayName";
    private static String ATT_FOLDER_URL   = "folderUrl";
    private static String ATT_FOLDER_UID   = "folderUID";
    private static String ATT_FOLDER_PWD   = "folderPWD";
    private static String ATT_PROTOCOL     = "protocol";
    private static String ATT_IS_DELETED   = "isDeleted";

    private String id;
    private String dname;
    private String baseAddr;
    private String fuid;
    private String fpwd;
    private String protocol;

    public ConnectionSettings(Document definingDoc, Element definingElement, DOMFace p)
            throws Exception {
        super(definingDoc, definingElement, p);
    }

    public String getId() {
        if (id == null) {
            id = getAttribute(ATT_ID);
        }
        return id;
    }

    public String getDisplayName() {
        if (dname == null) {
            dname = getAttribute(ATT_DISPLAY_NAME);
        }
        if (dname == null) {
            //if no name exists, make up one based on ID
            dname = "Connection "+getId();
        }
        return dname;
    }

    public void setDisplayName(String name) {
        if (name == null) {
            //if no name provided, make up one based on ID
            name = "Connection "+getId();
        }
        setAttribute(ATT_DISPLAY_NAME, name);
        dname = name;
    }

    public String getProtocol() {
        if (protocol == null) {
            protocol = getAttribute(ATT_PROTOCOL);
        }
        return protocol;

    }

    public void setProtocol(String prtcl) {
        setAttribute("protocol", prtcl);
        protocol = prtcl;
    }


    /**
    * The base address, is the address of the root of the repository connection.
    * Exact format of the address depends upon the protocol.
    * For some protocols this will be a URL, sometimes a UNC, sometimes a path.
    * This connection will only search from this address and folders inside
    * this address, never allowing navigation to parent folders or contents.
    *
    * This path NEVER ends with a slash.
    */
    public String getBaseAddress() {
        if (baseAddr == null) {
            baseAddr = getAttribute(ATT_FOLDER_URL);
        }

        //temp, clean up existing data
        //remove this after Nov 2011
        while (baseAddr.endsWith("/")) {
            baseAddr = baseAddr.substring(0, baseAddr.length()-1);
            setAttribute(ATT_FOLDER_URL, baseAddr);
        }

        //test that it does not have a slash on the end
        if (baseAddr.endsWith("/")) {
            throw new RuntimeException("PLE: baseaddress has slash on end: ("+baseAddr+")");
        }
        return baseAddr;
    }

    public void setBaseAddress(String address) {
        //remove slashes off the end if there are any
        while (address.endsWith("/")) {
            address = baseAddr.substring(0, address.length()-1);
        }
        baseAddr = address;
        setAttribute(ATT_FOLDER_URL, baseAddr);
    }

    /**
    * Does two things.  I verifies that the path passed in is a path to somthing that is
    * inside this connection.  That is, the path starts with the connection base address.
    * Second, it calculates and returns the relative path within the connection.
    * Returned relative path always start with a slash.
    */
    public String getRelativePath(String fullPath) throws Exception
    {
        String base = getBaseAddress();
        if(!fullPath.startsWith(base)){
            throw new NGException("nugen.exception.con.do.not.contain.resource", new Object[]{getDisplayName(), fullPath});
        }

        String relPath = fullPath.substring(base.length());
        if (!relPath.startsWith("/")) {
            throw new NGException("nugen.exception.cant.form.relative.path", new Object[]{getDisplayName(), fullPath});
        }
        return relPath;
    }

    public String getFolderUserId() {
        if (fuid == null) {
            fuid = getAttribute(ATT_FOLDER_UID);
        }
        return fuid;
    }

    public void setFolderUserId(String uid) {
        setAttribute(ATT_FOLDER_UID, uid);
        fuid = uid;
    }

    public void setLocalRoot(String localRoot){
        setAttribute("localRoot", localRoot);
    }
    public String getLocalRoot() {
        return getAttribute("localRoot");
    }
    public String getFolderPassword() throws Exception {
        if (fpwd == null) {
            String tmpPwd = getAttribute(ATT_FOLDER_PWD);
            if (tmpPwd != null && tmpPwd.length() > 0) {
                TextEncrypter te = new TextEncrypter(
                        TextEncrypter.DESEDE_ENCRYPTION_SCHEME);
                fpwd = te.decrypt(tmpPwd);
            } else {
                fpwd = tmpPwd;
            }
        }

        return fpwd;
    }

    public void setFolderPassword(String pwd) throws Exception {
        if (pwd != null && pwd.length() > 0) {
            TextEncrypter te = new TextEncrypter(
                    TextEncrypter.DESEDE_ENCRYPTION_SCHEME);
            pwd = te.encrypt(pwd);
        } else {
            pwd = "";
        }
        setAttribute(ATT_FOLDER_PWD, pwd);
        fpwd = pwd;
    }

    public long getLastModified() {
        return safeConvertLong(getAttribute("lmodified"));
    }

    public void setLastModified(long lmodified) {
        setAttribute("lmodified", Long.toString(lmodified));
    }

    public String getExtendedAttribute(String name){
        return getAttribute(name);
    }

    public void setCVSModule(String value){
        setAttribute("cvsModule", value);
    }

    public void setCVSRoot(String value){
        setAttribute("cvsRoot", value);
    }

    public String getCVSModule(){
        return getAttribute("cvsModule");
    }

    public String getCVSRoot(){
        return getAttribute("cvsRoot");
    }

    public boolean isDeleted(){
        String isDeleted = getAttribute(ATT_IS_DELETED);
        if (isDeleted == null)
        {
            return false;
        }
        else
        {
            return "true".equals(isDeleted);
        }
    }

    public void setDeleted(boolean isDeleted) {
        if (isDeleted)
        {
            setAttribute("isDeleted", "true");
        }
        else
        {
            setAttribute("isDeleted", null);
        }
    }

    public ConnectionType getConnectionOrNull() throws Exception
    {
        String ptcl = getProtocol();
        if(ConnectionType.PTCL_WEBDAV.equals(ptcl)){
            return new WebDavAccess(this);
        }else if(ConnectionType.PTCL_SMB.equals(ptcl)){
            return new SMBAccess(this);
        }else if(ConnectionType.PTCL_CVS.equals(ptcl)){
             return new CVSAccess(this, null);
        }else if(ConnectionType.PTCL_LOCAL.equals(ptcl)){
            return new LocalAccess(this);
        }else{
            return null;
        }
    }

    public ConnectionType getConnectionOrFail() throws Exception
    {
        ConnectionType found = getConnectionOrNull();
        if (found == null) {
            throw new ProgramLogicError("Invalid folder type " + getProtocol());
        }
        return found;
    }

    String tempOwnerKey;   //stored as member variable for now.
    /**
    * the key of the user that owns this connection
    */
    public String getOwnerKey() throws Exception
    {
        return tempOwnerKey;
    }
    /**
    * should not be needed but temporary fix to set and store until I can figure
    * out how to get this from the UserPage object directly from the ConnectionSettings
    */
    public void setOwnerKey(String newKey) throws Exception
    {
        tempOwnerKey = newKey;
    }

}
