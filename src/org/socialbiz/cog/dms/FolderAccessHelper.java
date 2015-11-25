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
import java.io.FileOutputStream;
import java.io.InputStream;
import java.net.URLEncoder;
import java.util.ArrayList;
import java.util.List;
import java.util.Properties;
import java.util.StringTokenizer;

import org.socialbiz.cog.AttachmentRecord;
import org.socialbiz.cog.AttachmentVersion;
import org.socialbiz.cog.AuthRequest;
import org.socialbiz.cog.Cognoscenti;
import org.socialbiz.cog.MimeTypes;
import org.socialbiz.cog.NGPage;
import org.socialbiz.cog.UserManager;
import org.socialbiz.cog.UserPage;
import org.socialbiz.cog.exception.NGException;
import org.socialbiz.cog.exception.ProgramLogicError;
import org.socialbiz.cog.util.UploadFile;
import org.socialbiz.cog.util.UploadFiles;

public class FolderAccessHelper {

    private static List<LocalFolderConfig> loaclConnections = null;
    private static List<CVSConfig> cvsConnections = null;

    AuthRequest ar;

    public FolderAccessHelper(AuthRequest ar)throws Exception
    {
        if(ar == null)
        {
            throw new ProgramLogicError("FolderAccessHelper requires that AuthRequest parameter not be null");
        }
        this.ar = ar;
    }


    public static void initLocalConnections(Cognoscenti cog){
        loaclConnections = new ArrayList<LocalFolderConfig>();
        String lclConn = cog.getConfig().getProperty("localConnections");
        if(lclConn == null){
            return;
        }
        lclConn = lclConn.replace('[', ' ');
        StringTokenizer st = new StringTokenizer(lclConn, "]");
        while (st.hasMoreTokens()) {
            String tok = st.nextToken();
            int indx = tok.indexOf('=');
            if(indx > 0){
                String dname = tok.substring(0,indx).trim();
                String path = tok.substring(indx+1).trim();
                path = path.replace("\\", "/");
                if (!path.endsWith("/")) {
                    path = path + "/";
                }
                LocalFolderConfig lclconfig = new LocalFolderConfig(dname, path);
                loaclConnections.add(lclconfig);
            }
        }

    }
    public static void initCVSConnections(Cognoscenti cog){
        cvsConnections = new ArrayList<CVSConfig>();
        String cvsConn = cog.getConfig().getProperty("cvsConnections");
        if(cvsConn == null){
            return;
        }
        cvsConn = cvsConn.replace('[', ' ');
        StringTokenizer st = new StringTokenizer(cvsConn, "]");

        while (st.hasMoreTokens()) {
            String tok = st.nextToken();
            StringTokenizer cst = new StringTokenizer(tok, ",");
            Properties cvsProp = new Properties();
            while(cst.hasMoreTokens()){
                String ctok = cst.nextToken();
                int indx = ctok.indexOf('=');
                if(indx > 0){
                    String pkey = ctok.substring(0,indx).trim();
                    String pvalue = ctok.substring(indx+1).trim();
                    cvsProp.put(pkey, pvalue);
                }
            }

            CVSConfig cvsConfig = new CVSConfig(
                    cvsProp.getProperty("root"),
                    cvsProp.getProperty("repository"),
                    cvsProp.getProperty("sandbox"));
            cvsConnections.add(cvsConfig);
        }

    }



    /**
    * Either creates or updates a "resource connection" for a given user
    * creates a connection if the id is "CREATE"
    */
    public static ConnectionSettings updateConnection(AuthRequest ar) throws Exception
    {
        UserPage up = ar.getUserPage();
        String connectionId = ar.reqParam("fid");
        ConnectionSettings cSet = null;
        if ("CREATE".equals(connectionId))
        {
            cSet = up.createConnectionSettings();
        }
        else
        {
            cSet = up.getConnectionSettingsOrFail(connectionId);
        }

        updateSettingsFromRequest(ar, up, cSet);
        return cSet;
    }

    public static void updateSettingsFromRequest(AuthRequest ar, UserPage up, ConnectionSettings cSet) throws Exception
    {
        String displayName = ar.reqParam(ConnectionType.FORM_FIELD_NAME);
        String ptc = ar.reqParam(ConnectionType.FORM_FIELD_PRTCL);
        String serverpath = ar.reqParam(ConnectionType.FORM_FIELD_URL);
        serverpath = constructValidUrl(serverpath, ptc, ar);
        String uid = ar.defParam(ConnectionType.FORM_FIELD_UID,"").trim();
        String pwd = ar.defParam(ConnectionType.FORM_FIELD_PWD,"").trim();

        cSet.setDisplayName(displayName);
        cSet.setProtocol(ptc);
        cSet.setBaseAddress(serverpath);
        cSet.setFolderUserId(uid);
        if (pwd.length()>0)
        {
            //don't change the password if none given
            cSet.setFolderPassword(pwd);
        }

        //Set Extended attribute for CVS protocol
        if(ConnectionType.PTCL_CVS.equalsIgnoreCase(ptc)){
            String rootModule = ar.reqParam("cvsroot").trim();
            String module = ar.reqParam("cvsmodule").trim();
            CVSConfig cvsConfig = getCVSConfig(rootModule);
            cSet.setCVSRoot(cvsConfig.getRoot());
            cSet.setCVSModule(module);
        }else if(ConnectionType.PTCL_LOCAL.equalsIgnoreCase(ptc)){
            String localRoot = ar.reqParam("localRoot");
            cSet.setLocalRoot(localRoot);
        }

        cSet.setLastModified(ar.nowTime);
        up.saveFile(ar, "requested to create folder " +  displayName);
    }


    public static void deleteConnection(AuthRequest ar, String fid)throws Exception
    {
        UserPage up = ar.getUserPage();
        ConnectionSettings cSet = up.getConnectionSettingsOrFail(fid);
        cSet.setDeleted(true);
        up.saveFile(ar, "requested to delete connection ");
    }



    public void createNewFolderFile(String symbol,
                String fileName, UploadFiles ufs)throws Exception {
        UserPage up = ar.getUserPage();
        ResourceEntity remoteFolder = up.getResourceFromSymbol(symbol);
        ConnectionType cType = remoteFolder.getConnection();

        UploadFile ulf = ufs.getFile(0);
        File tempFile = File.createTempFile(fileName + "_temp",  ".tmp");
        tempFile.delete();
        ulf.saveToFile(tempFile);
        cType.createNewFile(remoteFolder.getFullPath(), fileName, tempFile);
        tempFile.delete();
    }

    public void deleteFolder(String symbol)throws Exception
    {
        UserPage up = ar.getUserPage();
        ResourceEntity remote = up.getResourceFromSymbol(symbol);
        remote.deleteEntity();
    }


    /**
    * @deprecated use getRemoteResource instead
    */
     public ResourceEntity getResourceEntity(String symbol, boolean expand) throws Exception {
         try {
             String id = symbol;
             String rpath = "";
             int indx = symbol.indexOf('/');
             if (indx > 0) {
                 id = symbol.substring(0, indx);
                 rpath = symbol.substring(indx);
             }
             return getRemoteResource(id, rpath, expand);
         }
         catch (Exception e) {
             throw new NGException("nugen.exception.unable.to.get.resource", new Object[]{symbol}, e);
         }
     }

    public ResourceEntity getRemoteResource(String id, String rpath, boolean expand) throws Exception
    {
        if (rpath==null) {
            throw new ProgramLogicError("getRemoteResource received a null rpath parameter, must be at least a slash");
        }
        if (rpath.length()<1) {
            throw new ProgramLogicError("getRemoteResource received a zero length rpath parameter, must be at least a slash");
        }
        if (!rpath.startsWith("/")) {
            throw new ProgramLogicError("getRemoteResource received a rpath that does not start with slash: ("+rpath+")");
        }
        UserPage up = ar.getUserPage();
        ConnectionType cType = up.getConnectionOrFail(id);
        return cType.getResourceEntity(rpath, expand);
    }

     private void createRemotefolder(RemoteLinkCombo parent, String subFolderName)
         throws Exception{

        ResourceEntity parentEntity = parent.getResource();
        ResourceEntity child = parentEntity.getChild(subFolderName);
        child.createFolder();
    }

     /*
    private void createFolders(ResourceEntity folderToCreate)
            throws Exception{

        ResourceEntity parent = folderToCreate.getParent();
        parent.fillInDetails(false);

        //recursively fill in the details
        if (!parent.exists()) {
            createFolders(parent);
        }

        folderToCreate.createFolder();
    }
    */

    public void attachDocument(ResourceEntity remoteFile,
            NGPage ngp,        String description,   String dName,
            String visibility, String readonly) throws Exception{

        if (!remoteFile.isFilled()) {
            //make sure we have the modified date
            remoteFile.fillInDetails(false);
        }

        AttachmentRecord attachment = ngp.createAttachment();
        attachment.setDisplayName(dName);
        attachment.setDescription(description);
        attachment.setModifiedBy(ar.getBestUserId());
        attachment.setModifiedDate(ar.nowTime);
        attachment.setAttachTime(ar.nowTime);
        attachment.setType("FILE");
        if (visibility.equals("*PUB*")) {
           attachment.setVisibility(1);
        }
        else {
           attachment.setVisibility(2);
        }

        RemoteLinkCombo rlc = new RemoteLinkCombo(ar.getUserProfile().getKey(), remoteFile);
        attachment.setRemoteCombo(rlc);
        attachment.setRemoteFullPath(remoteFile.getFullPath());
        attachment.setReadOnlyType(readonly);

        attachment.setFormerRemoteTime(remoteFile.getLastModifed());

        //the following should be inside the ResourceEntity ... soon
        ConnectionType cType = remoteFile.getConnection();
        InputStream is = cType.openInputStream(remoteFile);
        attachment.streamNewVersion(ar, ar.ngp, is);
        is.close();
    }

    public void uploadAttachment(NGPage ngp, String laid)throws Exception{
        AttachmentRecord att = ngp.findAttachmentByID(laid);
        if (att==null)
        {
            //why sleep?  Here, this is VERY IMPORTANT
            //Someone might be trying all the possible file names just to
            //see what is here.  A three second sleep makes that more difficult.
            Thread.sleep(3000);
            throw new NGException("nugen.exception.attachment.not.attached.with.page", new Object[]{laid,ngp.getFullName()});
        }
        RemoteLinkCombo rld = att.getRemoteCombo();

        UserPage up = rld.getUserPage();
        ConnectionType cType = up.getConnectionOrFail(rld.folderId);

        AttachmentVersion aver = att.getLatestVersion(ngp);
        File attachmentFile = aver.getLocalFile();

        String path = cType.getFullPath(rld.rpath);
        cType.uploadFile(path, attachmentFile);

        att.setAttachTime(att.getModifiedDate());

        ResourceEntity re = cType.getResourceEntity(rld.rpath, false);
        att.setFormerRemoteTime(re.getLastModifed());

    }

    public void refreshAttachmentFromRemote(NGPage ngp, String laid)throws Exception
    {
        AttachmentRecord att = ngp.findAttachmentByID(laid);
        if (att==null)
        {
            //why sleep?  Here, this is VERY IMPORTANT
            //Someone might be trying all the possible file names just to
            //see what is here.  A three second sleep makes that more difficult.
            Thread.sleep(3000);
            throw new NGException("nugen.exception.attachment.not.attached.with.page", new Object[]{laid,ngp.getFullName()});
        }

        RemoteLinkCombo rlc = att.getRemoteCombo();
        ResourceEntity remoteFile = rlc.getResource();

        InputStream is = remoteFile.getInputStream();
        att.streamNewVersion(ar, ar.ngp, is);
        is.close();

        remoteFile.fillInDetails(false);
        att.setFormerRemoteTime(remoteFile.getLastModifed());
        att.setAttachTime(att.getModifiedDate());
     }


     public void serveUpRemoteFile(String symbol)throws Exception{

        UserPage up = ar.getUserPage();
        ResourceEntity remoteFile = up.getResourceFromSymbol(symbol);

        //get the mime type from the file extension
        String mimeType = MimeTypes.getMimeType(remoteFile.getName());
        ar.resp.setContentType(mimeType);

        //set expiration to about 1 year from now
        ar.resp.setDateHeader("Expires", System.currentTimeMillis()+3000000);
        ar.resp.setHeader( "Content-Disposition", "attachment; filename=\"" + remoteFile.getName() + "\"" );

        InputStream is = remoteFile.getInputStream();
        ar.streamBytesOut(is);
        is.close();
     }

    public long getLastModified(String rLink)throws Exception
    {
        try
        {
            RemoteLinkCombo rld = RemoteLinkCombo.parseLink(rLink);

            UserPage up = rld.getUserPage();
            ConnectionType cType = up.getConnectionOrFail(rld.folderId);
            ResourceEntity re = cType.getResourceEntity(rld.rpath, false);

            return re.getLastModifed();
        }
        catch (Exception e)
        {
            throw new NGException("nugen.exception.unable.to.get.lbd", new Object[]{rLink}, e);
        }
    }

/*
    public ConnectionType getConnectionType(ConnectionSettings folder) throws Exception
    {
        String ptcl = folder.getProtocol();
        if(ConnectionType.PTCL_WEBDAV.equals(ptcl)){
            return new WebDavAccess(folder);
        }else if(ConnectionType.PTCL_SMB.equals(ptcl)){
            return new SMBAccess(folder);
        }else if(ConnectionType.PTCL_CVS.equals(ptcl)){
             return new CVSAccess(folder, ar.getBestUserId());
        }else if(ConnectionType.PTCL_LOCAL.equals(ptcl)){
            return new LocalAccess(folder);
        }else{
            throw new ProgramLogicError("Invalid Connection type " + ptcl);
        }
    }
*/

    private  static String  constructValidUrl(String url, String ptcl, AuthRequest ar) throws Exception{
        String validUrl = url;
        if(ConnectionType.PTCL_SMB.equals(ptcl))
        {
            validUrl = url.replace('\\', '/');
            if (validUrl.startsWith("//"))
            {
                validUrl = "smb:" + validUrl;
            }
        }
        else if(ConnectionType.PTCL_WEBDAV.equals(ptcl))
        {
            if(url.endsWith("/"))
            {
                validUrl = url.substring(0, url.length()-1 );
            }
        }else if(ConnectionType.PTCL_LOCAL.equals(ptcl)){
            validUrl = ar.reqParam("lclfldr").trim();
            if(validUrl.endsWith("/")){
                validUrl = validUrl.substring(0, validUrl.length()-1);
            }
        }else if(ConnectionType.PTCL_CVS.equals(ptcl)){
            String rootModule = ar.reqParam("cvsroot").trim();
            String module = ar.reqParam("cvsmodule").trim();
            CVSConfig cvsConfig = getCVSConfig(rootModule);
            String sandBox = cvsConfig.getSandbox();

            if(!module.startsWith(rootModule)){
                validUrl = sandBox;
            }else if(module.indexOf("..")>0){
                validUrl = sandBox;
            }else if(module.length() > rootModule.length()){
                validUrl = sandBox + module.substring(rootModule.length());
            }else{
                validUrl = sandBox;
            }

            if(validUrl.endsWith("/")){
                validUrl = validUrl.substring(0, validUrl.length()-1);
            }

        }

        return validUrl;
    }


    public static List<LocalFolderConfig> getLoclConnections(){
        //Test
        if(loaclConnections == null) {
            throw new RuntimeException("FolderAccessHelper is not initialized");
        }
        return loaclConnections;
    }

    public static List<CVSConfig> getCVSConnections(){
        if(cvsConnections == null) {
            throw new RuntimeException("FolderAccessHelper is not initialized");
        }
        return cvsConnections;
    }

    private static CVSConfig getCVSConfig(String module)throws Exception{
        List<CVSConfig> v = getCVSConnections();
        for(int i=0; i<v.size(); i++){
            String rmodule = v.get(i).getRepository();
            if(rmodule.equals(module)){
                return v.get(i);
            }
        }

        throw new NGException("nugen.exception.cvs.config.error", new Object[]{module}) ;
    }


    public String getConnectionHealth(String folderId) throws Exception {
        try
        {
            String id = folderId;
            String rpath = "";
            int indx = folderId.indexOf('/');
            if (indx > 0) {
                id = folderId.substring(0, indx);
                rpath = folderId.substring(indx);
            }
            UserPage up = ar.getUserPage();
            ConnectionType cType = up.getConnectionOrFail(id);
            cType.getResourceEntity(rpath, true);
            ConnectionSettings cSet = up.getConnectionSettingsOrNull(folderId);
            if((cSet != null)&&(!cSet.isDeleted())){
                return "Healthy";
            }else{
                String unheathyStr = "Unhealthy-Either Connection is deleted or there is some problem with the Connection settings.";
                return unheathyStr;
            }

        }catch(Exception e){
            return "Unhealthy-"+e.getMessage();
        }
    }


    public Exception getRemoteAccessException(RemoteLinkCombo rlc) throws Exception
    {
        try
        {
            UserPage up = rlc.getUserPage();
            ConnectionType cType = up.getConnectionOrFail(rlc.folderId);
            cType.getResourceEntity(rlc.rpath, false);
            return null;
        }
        catch (Exception e)
        {
            return e;
        }
    }

    public void changePassword(String folderId) throws Exception {
        String pwd = ar.defParam(ConnectionType.FORM_FIELD_PWD,"").trim();
        UserPage up = ar.getUserPage();
        ConnectionSettings cSet = up.getConnectionSettingsOrFail(folderId);
        if (pwd.length()>0)
        {
            cSet.setFolderPassword(pwd);
        }
        up.saveFile(ar, "requested to update the the password of connection " +ar);
    }


    /**
    * @deprecated, use copyAttachmentToRemote instead
    */
    public boolean createCopyInRepository(String userkey, NGPage ngp, String aid,
            String path, String folderId, boolean isOverwrite) throws Exception {

        UserPage up = UserManager.findOrCreateUserPage(userkey);
        ResourceEntity re = up.getResource(folderId, path);

        return copyAttachmentToRemote(ngp, aid, re, isOverwrite);
    }


    public boolean copyAttachmentToRemote(NGPage ngp, String aid, ResourceEntity targetFile, boolean isOverwrite) throws Exception {

        throw new Exception("copyAttachmentToRemote needs to be updated to handle attachements in the workspace in sites.");

    }

    public List<ConnectionSettings> getAvailableConnections(String resourceAddress)throws Exception {
        UserPage up = ar.getUserPage();
        List<ConnectionSettings> filteredConnectionSettingList = new ArrayList<ConnectionSettings>();
        for(ConnectionSettings cSet : up.getAllConnectionSettings()){
            if(!cSet.isDeleted()){

                ConnectionType cType = up.getConnectionOrFail(cSet.getId());
                if(cType.contains(resourceAddress)){
                    filteredConnectionSettingList.add(cSet);
                }
            }
        }
        return filteredConnectionSettingList;
    }

    public void addFileInRepository(String folderId,
            String fileName, byte[] fileContents) throws Exception {
        String id = folderId;
        String rpath = "/";
        int indx = folderId.indexOf('/');
        if (indx > 0) {
            id = folderId.substring(0, indx);
            rpath = folderId.substring(indx);
        }
        UserPage up = ar.getUserPage();
        ConnectionType cType = up.getConnectionOrFail(id);
        String path = cType.getFullPath(rpath);

        String suffix = fileName + "_temp";
        File tempFile = File.createTempFile(suffix,  ".tmp");
        tempFile.delete();
        saveToFileFAH(fileContents,tempFile);
        cType.createNewFile(path, fileName, tempFile);
        tempFile.delete();

    }

    private static void saveToFileFAH(byte[] fileContents, File destinationFile)
    throws Exception {
        if (destinationFile == null) {
            throw new IllegalArgumentException(
                "Can not save file.  Destination file must not be null.");
        }

        if (destinationFile.exists()) {
            throw new NGException("nugen.exception.file.already.exist", new Object[]{destinationFile});
        }
        File folder = destinationFile.getParentFile();
        if (!folder.exists()) {
            throw new NGException("nugen.exception.file.already.exist",new Object[]{destinationFile});
        }

        try {
            FileOutputStream fileOut = new FileOutputStream(destinationFile);
            fileOut.write(fileContents);
            fileOut.close();
        } catch (Exception e) {
            throw new NGException("nugen.exception.failed.to.save.file", new Object[]{destinationFile}, e);
        }
    }

     /**
      * @deprecated use createRemotefolder instead
      */
     public void createSubFolder(String userKey, String parenFolderId, String subFolderName)throws Exception{
         String id = parenFolderId;
         String rpath = "";
         int indx = parenFolderId.indexOf('/');
         if (indx > 0) {
             id = parenFolderId.substring(0, indx);
             rpath = parenFolderId.substring(indx);
         }
         createRemotefolder(new RemoteLinkCombo(userKey, id, rpath), subFolderName);
     }

    /**
    * @deprecated, use the protocol specific methods for this.
    */
    public static String extendUrlPath(String baseURL, String elementToAdd) throws Exception
    {
        if (baseURL.endsWith("/")) {
            return baseURL + URLEncoder.encode(elementToAdd, "UTF-8");
        } else {
            return baseURL + "/" + URLEncoder.encode(elementToAdd, "UTF-8");
        }
    }
    /**
    * @deprecated, not needed any more, use RemoteLinkCombo instead
    */
    public String getFolderId(String rLink) throws Exception{
        RemoteLinkCombo rlc = RemoteLinkCombo.parseLink(rLink);
        return rlc.folderId;
    }
    /**
    * @deprecated, not needed any more, use RemoteLinkCombo instead
    */
    public String getOwner(String rLink) throws Exception{
        RemoteLinkCombo rlc = RemoteLinkCombo.parseLink(rLink);
        return rlc.userKey;
    }
    /**
    * @deprecated, not needed any more, use RemoteLinkCombo instead
    */
    public String getRPath(String rLink) throws Exception{
        RemoteLinkCombo rlc = RemoteLinkCombo.parseLink(rLink);
        return rlc.rpath;
    }

}
