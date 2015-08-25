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
import java.io.FileInputStream;
import java.io.InputStream;
import java.net.URLDecoder;
import org.apache.commons.httpclient.HttpURL;
import org.apache.commons.httpclient.NTCredentials;
import org.apache.webdav.lib.WebdavResource;

public class WebDavAccess extends ConnectionTypeBase  {


    public WebDavAccess(ConnectionSettings _folder){
        super(_folder);
        if (!ConnectionType.PTCL_WEBDAV.equals(folder.getProtocol()))
        {
            //just being paranoid and making sure that this is constructed correctly
            throw new RuntimeException("A WebDavAccess object can ONLY be created on a folder with WEBDAV protocol!");
        }


        //all relative addresses must start with a slash, and so the base address must
        //not have a slash on the end.  Remove one if one is found.
        String baseAddr = _folder.getBaseAddress();
        if (baseAddr.endsWith("/"))
        {
            baseAddr  = baseAddr.substring(0, baseAddr.length()-1);
        }

        //clean up any old addresses that had spaces in them, and convert space to %20
        //put the modified value back into the connection settings for possible save
        int spacePos = baseAddr.indexOf(" ");
        while (spacePos>=0) {
            baseAddr = baseAddr.substring(0,spacePos) + "%20" + baseAddr.substring(spacePos+1);
            spacePos = baseAddr.indexOf(" ");
            _folder.setBaseAddress(baseAddr);
        }
    }


    public boolean createFolder(String path) throws Exception
    {
        int indx = path.lastIndexOf('/');
        if (indx<0)
        {
            throw new NGException("nugen.exception.path.dont.have.slashes", new Object[]{path});
        }
        String parentPath = truncatePath(path);
        String goofyPath = URLDecoder.decode(path, "UTF-8");
        WebdavResource wRes = null;
        try
        {
            wRes = getWebdavResource(parentPath);
            if (!wRes.mkcolMethod(goofyPath))
            {
                throw new NGException("nugen.exception.fail.while.creating.folder", new Object[]{wRes.getStatusCode(), goofyPath});
            }
            return true;
        }
        catch (Exception e)
        {
            throw new NGException("nugen.exception.unable.to.create.folder", new Object[]{path}, e);
        }
        finally
        {
            if (wRes != null)
            {
                wRes.closeSession();
                wRes.close();
            }
        }
    }

    public boolean deleteEntity(String path) throws Exception{
        WebdavResource wRes = null;
        try {
            wRes = getWebdavResource(path);
            if (!wRes.deleteMethod()) {
                throw new NGException("nugen.exception.fail.while.delete", new Object[]{wRes.getStatusCode()});
            }
            return true;
        } catch (Exception e) {
            throw new NGException("nugen.exception.cant.delete.remote.resource", new Object[]{path}, e);
        } finally {
            if (wRes != null) {
                wRes.closeSession();
                wRes.close();
            }
        }
    }

    /**
    * Gets an object that represents a remote resource in this remote folder
    * @parameter expand will build the entire tree under this resource, and link it into a tree
    */
    public void lookUpDetails(ResourceEntity entity, boolean expand) throws Exception
    {
        String fullPath = entity.getFullPath();
        if (fullPath.indexOf(" ")>0) {
            throw new NGException("nugen.exception.cant.contain.space", new Object[]{fullPath});
        }

        WebdavResource wRes = null;

        try {
            wRes = getWebdavResource(entity.getFullPath());
            String displayName = folder.getDisplayName() + entity.getPath();
            copyInfoFromWebDavResource(entity, wRes, displayName, false);
            if(wRes.isCollection()){
                if (!fullPath.endsWith("/")) {
                    fullPath = fullPath + '/';
                }
                WebdavResource[] allChildren = wRes.listWebdavResources();
                entity.setFileCount(getFileCount(allChildren));
                if (expand) {
                    for (WebdavResource cres : allChildren) {
                        String childName = cres.getName();

                        //special, there is a bug with WEbDAV getting funny character
                        //so for now simply exclude them from consideration.
                        //the distortion seems to put ? characters in the name
                        //TODO: fix the encoding
                        if (childName.contains("?")) {
                            continue;
                        }

                        ResourceEntity cEntity = entity.getChild(childName);
                        try {
                            String cDisplayname = displayName + "/" + cres.getName();
                            copyInfoFromWebDavResource(cEntity, cres, cDisplayname, true);
                        }finally {
                            if (cres != null) {
                                cres.closeSession();
                                cres.close();
                            }
                        }
                        entity.addChildEntity(cEntity);
                    }
                }
            }
        } catch (Exception e) {
            throw new NGException("nugen.exception.entity.not.found", new Object[]{fullPath,folder.getId(),expand}, e);

        } finally {
            if (wRes != null) {
                wRes.closeSession();
                wRes.close();
            }
        }
    }

    private void copyInfoFromWebDavResource(ResourceEntity entity, WebdavResource wRes,
            String displayName, boolean isSubFolder)throws Exception{
        try {
            if (wRes.isCollection()) {
                entity.setType(ConnectionType.TYPE_FOLDER);
            }
            else {
                entity.setType(ConnectionType.TYPE_FILE);
                entity.setSize(wRes.getGetContentLength());
            }
            entity.setLastModifed(wRes.getGetLastModified());
            entity.setDisplayName(displayName);
        }
        catch (Exception e) {
            throw new NGException("nugen.exception.cant.create.webdav.access", new Object[]{folder.getId(),displayName},e);
        }
    }


    public InputStream openInputStream(ResourceEntity ent) throws Exception{
        String path = ent.getFullPath();
        WebdavResource wRes = null;
        try {
            wRes = getWebdavResource(path);
            File tmpFile = File.createTempFile(wRes.getName() + "_fromrep",  ".tmp");
            boolean success = wRes.getMethod(tmpFile);
            if (!success) {
                throw new NGException("nugen.exception.cant.get.remote.resource", new Object[]{wRes.getStatusCode()});
            }
            return new FileInputStream(tmpFile);
        } catch (Exception e) {
            throw new NGException("nugen.exception.unable.to.open.input.stream", new Object[]{path}, e);

        } finally {
            if (wRes != null) {
                wRes.closeSession();
                wRes.close();
            }
        }
    }

    public void uploadFile(String path, File srcFile) throws Exception{
        WebdavResource wRes = null;
        try {

            wRes = getWebdavResource(path);
            boolean vers = wRes.versionControlMethod(path);

            if (vers) {
                if (!wRes.checkoutMethod()) {
                    throw new NGException("nugen.exception.fail.return.checkout.method", new Object[]{wRes.getStatusCode()});
                }
            }
            InputStream is = new FileInputStream(srcFile);
            boolean result = wRes.putMethod(is);
            if (!result) {
                throw new NGException("nugen.exception.fail.while.upload", new Object[]{wRes.getStatusCode()});
            }

            if (vers) {
                if (!wRes.checkinMethod()) {
                    throw new NGException("nugen.exception.fail.return.checkin.method", new Object[]{wRes.getStatusCode()});
                }
            }
        } catch (Exception e){
            throw new NGException ("nugen.exception.file.upload.issue.from.local.path", new Object[]{path, srcFile}, e);
        } finally {
            if (wRes != null) {
                wRes.closeSession();
                wRes.close();
            }
        }
    }


    /**
    * Get a resource for this connection using connection credentials
    */
    private WebdavResource getWebdavResource(String path) throws Exception
    {
        return getWebdavResource(path, folder.getFolderUserId(), folder.getFolderPassword());
    }


    private WebdavResource getWebdavResource(String path, String uid, String pwd)
        throws Exception
    {
        try
        {
            //This is the goofy step, the HttpURL class requires something that looks like
            //a file path, NOT a URL, and so must be "decoded".  But normal URLDecoding does
            //not work because it converts plus symbols to spaces, so need to "encode" the
            //plus signs first, so that the decode preserves them correctly.
            //we need to move OFF this library sometime soon
            int plusPos = path.indexOf("+");
            while (plusPos>=0) {
                path = path.substring(0,plusPos) + "%2B" + path.substring(plusPos+1);
                plusPos = path.indexOf("+");
            }
            String goofyPath = URLDecoder.decode(path, "UTF-8");


            HttpURL url = new HttpURL(goofyPath);
            //A backslash in the user id indicates the use of NT domain auth
            int slashPos = uid.indexOf('\\');
            if (slashPos>0)
            {
                //This is the NT domain case
                String hostName = url.getHost();
                String ntdomain = uid.substring(0,slashPos);
                String ntuid = uid.substring(slashPos+1);
                NTCredentials cred = new NTCredentials(ntuid, pwd, hostName, ntdomain);
                return new WebdavResource(goofyPath, cred);
            }
            else
            {
                if (uid!=null && uid.length()>0 && pwd!=null) {
                    //This is the non-NT case, use basic auth if uid is provided
                    url.setUserinfo(uid, pwd);
                }
                return new WebdavResource(url);
            }
        }
        catch (Exception e)
        {
            throw new NGException("nugen.exception.unable.to.access.webdav.resource", new Object[]{path,uid}, e);
        }
    }

    private boolean isFileExists(WebdavResource wRes, String fileName, String pathThatWResIsFrom) throws Exception{
        try {
            WebdavResource list[] = wRes.listWebdavResources();
            if (list == null) {
                return false;
            }
            for (int i = 0; i < list.length; i++) {
                WebdavResource twrs = list[i];
                if (fileName.equalsIgnoreCase(twrs.getName())) {
                    return true;
                }
            }
            return false;
        }
        catch (Exception e) {
            throw new NGException("nugen.exception.fail.check.path.existence", new Object[]{pathThatWResIsFrom, fileName});
        }
    }

     private int getFileCount(WebdavResource[] wrs) throws Exception {
        int count = 0;
        if (wrs == null) {
            return 0;
        }
        for (int i = 0; i < wrs.length; i++) {
            WebdavResource twrs = wrs[i];
            if (!twrs.isCollection()) {
                count++;
            }
        }
        return count;
    }

    public void createNewFile(String parentPath,
            String fileName, File srcFile) throws Exception {
        createNewFileInt(parentPath, fileName, srcFile, false);
    }


    private void createNewFileInt(String parentPath,
            String fileName, File srcFile, boolean overwrite) throws Exception {
        WebdavResource wRes = null;
        try{
            wRes = getWebdavResource(parentPath);
            if (!overwrite) {
                boolean alreadyExists = this.isFileExists(wRes, fileName, parentPath);
                if (alreadyExists) {
                    throw new NGException("nugen.exception.file.already.exists", new Object[]{fileName});
                }
            }

            String realPath = extendPath(parentPath, fileName);
            FileInputStream tfis = new FileInputStream(srcFile);

            String goofyPath = URLDecoder.decode(realPath, "UTF-8");
            boolean result = wRes.putMethod(goofyPath, tfis);
            if (result == false) {
                throw new NGException("nugen.exception.fail.to.upload.file", new Object[]{wRes.getStatusCode(), realPath});
            }
            wRes.versionControlMethod(goofyPath);
        }finally {
            if (wRes != null) {
                wRes.closeSession();
                wRes.close();
            }
        }

    }

    public boolean checkAvailability(String parentPath, String fileName) throws Exception {
        WebdavResource wRes = null;

        wRes = getWebdavResource(parentPath);
        boolean alreadyExists = this.isFileExists(wRes, fileName, parentPath);
        if (alreadyExists) {
            return true;
        }else {
            return false;
        }
    }

    public void overwriteExistingDocument(String parentPath,
            String fileName, File srcFile) throws Exception {
        createNewFileInt(parentPath, fileName, srcFile, true);
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
            throw new RuntimeException("UTF-8 will never cause unsupported encoding exception", e);
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
}
