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
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.InputStream;
import java.net.URL;

/**
* PublicWebAccess is a special type of connection, it is a dummy connection
* it does not have any user name or password, and it has no root path.
* instead, this connection type is used when you have a Web URL, and
* the resource is publicly accessible, and you just want to be able to
* get it without any authentication.
*
* Folder ID for PublicWebAccess is always PUBLIC.
* Every user has this automatically, and there is no reason to store the settings
* You can not browse this connection type because it would be the whole web.
* This connection should not appear in any list of connections.
* Instead, it is created on the fly when needed where folder id = PUBLIC.
*
* note, if the full path is: http://machine/document.doc
* then internal path is: /http://machine/document.doc
* We ADD a slash on the front to make the internal "relative" path
*/
public class PublicWebAccess implements ConnectionType  {

    private String ownerKey;

    public PublicWebAccess(String newOwnerKey){
        ownerKey = newOwnerKey;
    }


    public ResourceEntity getResource(String fullPath) throws Exception
    {
        return new ResourceEntity(this, fullPath);
    }
    public ResourceEntity getResourceInternal(String partialPath) throws Exception
    {
        //just remove the slash off the beginning to get the full path
        return new ResourceEntity(this, partialPath.substring(1));
    }
    public boolean contains(String fullPath) throws Exception
    {
        String lcversion = fullPath.toLowerCase();
        //either it contains everything, as long as it starts with http
        return lcversion.startsWith("http");
    }
    public String getFullPath(String relPath) throws Exception
    {
        //internal path is just the global path with a slash in front of it
        if (!relPath.startsWith("/")) {
            throw new Exception("Somethign wrong, the internal path for a public web access caes should start with a slash: "+relPath);
        }
        //they had better pass the full address into public access.
        return relPath.substring(1);
    }
    public String getInternalPathOrFail(String fullPath) throws Exception
    {
        //normalize for trailing slash.  If the full path ends with a slash, then
        //this the SAME as having no slash on the end, so remove it.  In general,
        //paths should NEVER end with a slash, but no problem, just remove it.
        while (fullPath.endsWith("/") && fullPath.length()>0) {
            fullPath = fullPath.substring(0,fullPath.length()-1);
        }

        //for Public Web Access, we just return the complete path for the relative path.
        return "/"+fullPath;
    }


    public String getBaseAddress() throws Exception
    {
        //the thing about this approach is that there is no base address...
        return "";
    }
    public String getDisplayName() throws Exception
    {
        return "Public Web Access";
    }
    public void setOwnerKey(String newKey) throws Exception
    {
        ownerKey = newKey;
    }
    public String getOwnerKey() throws Exception
    {
        return ownerKey;
    }
    public void overwriteExistingDocument(ResourceEntity target, File srcFile)throws Exception
    {
        throw new Exception("Public access can not write documents to the web.");
    }
    public void createNewFile(ResourceEntity target, File srcFile)throws Exception
    {
        throw new Exception("Public access can not create new files out on the web");
    }
    public ResourceEntity getResourceEntity(String rpath, boolean expand)throws Exception
    {
        if (rpath==null) {
            throw new ProgramLogicError("getResourceEntity received a null rpath parameter, must be at least a slash");
        }
        if (rpath.length()>0 && !rpath.startsWith("/")) {
            throw new ProgramLogicError("getResourceEntity received a rpath that does not start with slash: ("+rpath+")");
        }
        ResourceEntity val = getResourceInternal(rpath);
        return val;
    }


    public boolean createFolder(String path) throws Exception {
        throw new Exception("Public access does not have a create folder option");
    }

    public boolean deleteEntity(String path) throws Exception{
        throw new Exception("Public access does not have a delete entity option");
    }

    /**
    * Gets an object that represents a remote resource in this remote folder
    * @parameter expand will build the entire tree under this resource, and link it into a tree
    */
    public void lookUpDetails(ResourceEntity entity, boolean expand) throws Exception
    {
        entity.setType(ConnectionType.TYPE_FILE);

        //no idea what the size is, but use ZERO
        entity.setSize(0);

        //no idea what last modified is, use zero
        entity.setLastModifed(0);

        //just use the full path URL
        entity.setDisplayName(entity.getFullPath());

        //ignore expand,because we can not browse
    }

    public InputStream openInputStream(ResourceEntity ent) throws Exception{
        URL link = new URL(ent.getFullPath());
        return link.openStream();
    }

    public void uploadFile(String path, File srcFile) throws Exception{
        throw new Exception("PublicWebAccess class can not create remote files ... it is read only");
    }

    public void createNewFile(String parentPath,
            String fileName, File srcFile) throws Exception {
        throw new Exception("PublicWebAccess class can not create remote files ... it is read only");
    }


    public boolean checkAvailability(String parentPath, String fileName) throws Exception {
        //PublicWebAccess always assumes that the resource exists.
        //This is used mainly to tell if space id available to upload to.
        //but  PublicWebAccess class can not create remote files ... it is read only
        return true;
    }

    public void overwriteExistingDocument(String parentPath,
            String fileName, File srcFile) throws Exception {
        throw new Exception("PublicWebAccess class can not create remote files ... it is read only");
    }


    static char[] hexchars = { '0', '1', '2', '3', '4', '5', '6', '7', '8',
            '9', 'A', 'B', 'C', 'D', 'E', 'F' };
    static int[] hexvalue = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 0,
            0, 0, 0, 0, 0, 10, 11, 12, 13, 14, 15, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 10, 11, 12, 13,
            14, 15, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0 };

    public String encodeName(String displayName)
    {
        try {
            byte[] buf = displayName.getBytes("UTF-8");
            StringBuffer res = new StringBuffer();
            for (byte thisByte : buf) {
                if (thisByte>=128) {
                    res.append('%');
                    res.append(hexchars[(thisByte / 16) % 16]);
                    res.append(hexchars[thisByte % 16]);
                }
                else if ( (thisByte>='0'&&thisByte<='9') ||
                          (thisByte>='A'&&thisByte<='Z') ||
                          (thisByte>='a'&&thisByte<='z') ||
                          (thisByte=='-') || (thisByte=='_') ||
                          (thisByte=='.') || (thisByte=='!') ||
                          (thisByte=='~') || (thisByte=='*') ||
                          (thisByte==')') || (thisByte=='(') ||
                          (thisByte=='\'')) {
                    res.append((char)thisByte);
                }
                else {
                    res.append('%');
                    res.append(hexchars[(thisByte / 16) % 16]);
                    res.append(hexchars[thisByte % 16]);
                }
            }
            return res.toString();
        }
        catch (java.io.UnsupportedEncodingException e) {
            throw new RuntimeException("UTF-8 will never cause unsupported encoding exception", e);
        }
    }

    public String decodeName(String encodedName)
    {
        try {
            int i=0;
            int last = encodedName.length();
            ByteArrayOutputStream os = new ByteArrayOutputStream();
            while (i<last) {
                char ch = encodedName.charAt(i++);
                if (ch>=128) {
                    //this should NEVER happen!  What do we do?
                    throw new RuntimeException("The URL supplied for this WebDAV exchange was not propely formatted.  It has a character value greater than 127 in it ("+Integer.toString(ch)+")");
                }
                else if (ch!='%') {
                    os.write(ch);
                    continue;
                }

                //if we get here, we have the first character of a two byte sequence
                //make sure there are two bytes left to read
                if (i+2>=last) {
                    throw new RuntimeException("The URL supplied for this WebDAV exchange was not propely formatted.  It has a % character without two digits after it.");
                }
                int chHigh = encodedName.charAt(i++)%128;
                int chLow  = encodedName.charAt(i++)%128;
                os.write(hexvalue[chHigh]*16 + hexvalue[chLow]);
            }
            return os.toString("UTF-8");
        }
        catch (Exception e) {
            throw new RuntimeException("Reading and writing to a buffer should produce an IO Exception", e);
        }
    }

    public String extendPath(String path, String displayName)
    {
        if (path.endsWith("/")) {
            return path + encodeName(displayName);
        } else {
            return path + "/" + encodeName(displayName);
        }
    }

    public String truncatePath(String path) throws Exception
    {
        if (path.length()<10)
        {
            throw new NGException("nugen.exception.cant.truncate.path.too.short", new Object[]{path});
        }
        //this needs to handle both the case where the string ends with
        //slash, and where it does not end with slash.  Start looking
        //at length-2 in order to skip the last character in case it was a slash
        int slashPos = path.lastIndexOf("/", path.length()-2);
        if (slashPos<=8) {
            //must be a slash in the http:// part, and that is too short
            //there is no file name on the end.
            throw new NGException("nugen.exception.cant.truncate.no.file", new Object[]{path});
        }
        return path.substring(0, slashPos);
    }
    public String getFileName(String path) throws Exception
    {
        if (path.length()<10)
        {
            throw new NGException("nugen.exception.file.not.found.in.path", new Object[]{path});
        }
        //this needs to handle both the case where the string ends with
        //slash, and where it does not end with slash.  Start looking
        //at length-2 in order to skip the last character in case it was a slash
        int slashPos = path.lastIndexOf("/", path.length()-2);
        if (slashPos<=8) {
            //must be a slash in the http:// part, and that is too short
            //there is no file name on the end.
            throw new NGException("nugen.exception.cant.truncate.no.file", new Object[]{path});
        }
        String encodedName = path.substring(slashPos+1);
        //now trim the slash off the end if necessary
        if (encodedName.endsWith("/"))
        {
            encodedName = encodedName.substring(0, encodedName.length()-1);
        }
        return decodeName(encodedName);
    }
    public Exception getValidationError(String urlValue) throws Exception
    {
        if (urlValue.length()<6)
        {
            return new ProgramLogicError("an improperly formatted URL was supplied "
                    +"in a place that a URL should be.  The supplied value is too short. "
                    +"  ("+urlValue+")");
        }
        int spacePos = urlValue.indexOf(' ');
        if (spacePos>=0)
        {
            return new ProgramLogicError("an improperly formatted URL was supplied "
                    +"in a place that a URL should be.  There is a space character at position "
                    +spacePos+".  This is an indication that the URL was not properly encoded. ("
                    +urlValue+")");
        }
        String firstFour = urlValue.substring(0,4).toLowerCase();
        if (!firstFour.equals("http"))
        {
            return new ProgramLogicError("an improperly formatted URL was supplied "
                    +"in a place that a URL should be.  Should start with 'http' but instead started with '"
                    +firstFour+"'.  This is an indication that the URL was not properly encoded. ("
                    +urlValue+")");
        }
        spacePos = urlValue.indexOf("//", 9);
        if (spacePos>=0)
        {
            return new ProgramLogicError("an improperly formatted URL was supplied "
                    +"in a place that a URL should be.  There is a double slash at position "
                    +spacePos+".  This is probably because two values were put together incorrectly. ("
                    +urlValue+")");
        }
        return null;
    }
    public String cleanPath(String path) throws Exception
    {
        throw new ProgramLogicError("cleanPath is not implemented yet");
    }

    public String getConnectionId() throws Exception
    {
        return "PUBLIC";
    }
}
