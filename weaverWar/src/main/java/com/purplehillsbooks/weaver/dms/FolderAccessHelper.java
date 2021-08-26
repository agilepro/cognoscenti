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
 * limitations under the License.package com.purplehillsbooks.weaver.dms;
 *
 * Contributors Include: Shamim Quader, Sameer Pradhan, Kumar Raja, Jim Farris,
 * Sandia Yang, CY Chen, Rajiv Onat, Neal Wang, Dennis Tam, Shikha Srivastava,
 * Anamika Chaudhari, Ajay Kakkar, Rajeev Rastogi
 */

package com.purplehillsbooks.weaver.dms;

import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.List;
import java.util.Properties;
import java.util.StringTokenizer;

import com.purplehillsbooks.weaver.AttachmentRecord;
import com.purplehillsbooks.weaver.AttachmentVersion;
import com.purplehillsbooks.weaver.AuthRequest;
import com.purplehillsbooks.weaver.Cognoscenti;
import com.purplehillsbooks.weaver.MimeTypes;
import com.purplehillsbooks.weaver.NGWorkspace;
import com.purplehillsbooks.weaver.UserPage;
import com.purplehillsbooks.weaver.exception.NGException;
import com.purplehillsbooks.weaver.exception.ProgramLogicError;
import com.purplehillsbooks.weaver.util.UploadFile;
import com.purplehillsbooks.weaver.util.UploadFiles;

public class FolderAccessHelper {

    AuthRequest ar;

    @Deprecated
    public FolderAccessHelper(AuthRequest ar)throws Exception
    {
        if(ar == null)
        {
            throw new ProgramLogicError("FolderAccessHelper requires that AuthRequest parameter not be null");
        }
        this.ar = ar;
    }









    @Deprecated
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


    public void attachDocument(ResourceEntity remoteFile,
            NGWorkspace ngp,        String description,   String dName,
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

    public void uploadAttachment(NGWorkspace ngp, String laid)throws Exception{
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

    public void refreshAttachmentFromRemote(NGWorkspace ngp, String laid)throws Exception
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

    private  static String  constructValidUrl(String url, String ptcl, AuthRequest ar) throws Exception{
        String validUrl = url;
        if(ConnectionType.PTCL_WEBDAV.equals(ptcl))
        {
            if(url.endsWith("/"))
            {
                validUrl = url.substring(0, url.length()-1 );
            }
        }

        return validUrl;
    }




    public boolean copyAttachmentToRemote(NGWorkspace ngp, String aid, ResourceEntity targetFile, boolean isOverwrite) throws Exception {

        throw new Exception("copyAttachmentToRemote needs to be updated to handle attachements in the workspace in sites.");

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
