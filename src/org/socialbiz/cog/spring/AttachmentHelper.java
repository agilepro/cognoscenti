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

package org.socialbiz.cog.spring;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;

import org.socialbiz.cog.AttachmentRecord;
import org.socialbiz.cog.AuthRequest;
import org.socialbiz.cog.HistoryRecord;
import org.socialbiz.cog.NGContainer;
import org.socialbiz.cog.NGPage;
import org.socialbiz.cog.SectionAttachments;
import org.socialbiz.cog.UserPage;
import org.socialbiz.cog.dms.ConnectionType;
import org.socialbiz.cog.dms.RemoteLinkCombo;
import org.socialbiz.cog.dms.ResourceEntity;
import org.socialbiz.cog.exception.NGException;
import org.socialbiz.cog.exception.ProgramLogicError;
import org.springframework.web.multipart.MultipartFile;

/**
* AttachmentHelper is a static class that contains helpful
* methods for handling attachments
*/
public class AttachmentHelper {

    public static void uploadNewDocument(AuthRequest ar,
                                            NGContainer ngc,
                                            MultipartFile file,
                                            String desiredName,
                                            String visibility,
                                            String comment,
                                            String modUser) throws Exception {

        //first, default the desired name if one was not set
        String fileName = file.getOriginalFilename();
        if (desiredName==null || desiredName.length()==0) {
            desiredName = fileName;
        }

        //first look for an attachment with this name, if found use that
        //and stream a new version of that attachment, otherwise, create a new.
        AttachmentRecord attachment =  ngc.findAttachmentByName(desiredName);
        if (attachment==null) {
            attachment =  ngc.createAttachment();
            attachment.setDisplayName(desiredName);
        }
        attachment.setDescription(comment);
        attachment.setModifiedBy(modUser);
        attachment.setModifiedDate(ar.nowTime);
        attachment.setType("FILE");
        attachment.setVersion(1);

        if (visibility != null && visibility.equals("*PUB*")) {
            attachment.setVisibility(1);
        } else {
            attachment.setVisibility(2);
        }

        setDisplayName(ngc, attachment, assureExtension(desiredName, fileName));
        saveUploadedFile(ar, attachment, file);
        HistoryRecord.createHistoryRecord(ngc, attachment.getId(), HistoryRecord.CONTEXT_TYPE_DOCUMENT,
                ar.nowTime, HistoryRecord.EVENT_DOC_ADDED, ar, "");

        ngc.saveFile(ar, comment);
    }

/*
public static void updateAttachment(AuthRequest ar, MultipartFile file, NGPage ngp)
            throws Exception {

        String aid = ar.reqParam("aid");
        AttachmentRecord attachment = ngp.findAttachmentByIDOrFail(aid);

        String action = ar.reqParam("actionType");

        if (action.equals("renameDoc")) {
            String accessName = ar.reqParam("accessName");
            String proposedName = AttachmentHelper.assureExtension(accessName,
                    attachment.getDisplayName());
            attachment.setDisplayName(proposedName);
        }
        else if (action.equals("changePermission")) {
            String visPublic = ar.reqParam("visPublic");
            if (visPublic.equals("PUB")) {
                attachment.setVisibility(1);
            }
            else {
                attachment.setVisibility(2);
            }
            throw new Exception("is 'changePermissions' still used.   If you see this exception, remove it from the code.");
        }
        else if (action.equals("UploadRevisedDoc")) {
            if (file.getSize() <= 0) {
                throw new NGException("nugen.exception.unexpectedly.got.zero.length.file.uploaded",
                        new Object[] { "action", ngp.getFullName() });
            }
            String comment_panel = ar.defParam("comment_panel", "");
            if (comment_panel == null) {
                throw new NGException("nugen.exception.parameter.required", new Object[] {
                        "comment_panel", ngp.getFullName() });
            }
            attachment.setDescription(comment_panel);
            AttachmentHelper.setDisplayName(
                    ngp,
                    attachment,
                    AttachmentHelper.assureExtension(attachment.getDisplayName(),
                            file.getOriginalFilename()));
            AttachmentHelper.saveUploadedFile(ar, attachment, file);

        }
        else if ("Update".equals(action)) {

            String ftype = ar.reqParam("ftype");
            String comment = ar.defParam("comment", "");
            String name = ar.reqParam("name");
            attachment.setType(ftype);
            attachment.setDescription(comment);

            String visPublic = ar.defParam("visPublic", "NONE");
            if (visPublic.equals("PUB")) {
                attachment.setVisibility(1);
            }
            else {
                attachment.setVisibility(2);
            }
            String visUpstream = ar.defParam("visUpstream", "NONE");
            attachment.setUpstream(visUpstream.equals("UPS"));

            if (ftype.equals("FILE") || ftype.equals("GONE")) {
                if (file != null && file.getSize() > 0) {
                    attachment.setModifiedBy(ar.getBestUserId());
                    attachment.setModifiedDate(ar.nowTime);
                    AttachmentHelper.setDisplayName(ngp, attachment,
                            AttachmentHelper.assureExtension(name, file.getOriginalFilename()));
                    AttachmentHelper.saveUploadedFile(ar, attachment, file);
                }
                else {
                    AttachmentHelper.setDisplayName(ngp, attachment, name);
                }
            }
            else if (ftype.equals("URL")) {
                attachment.setModifiedBy(ar.getBestUserId());
                attachment.setModifiedDate(ar.nowTime);
                String taskUrl = ar.reqParam("taskUrl");
                attachment.setStorageFileName(taskUrl);
                setDisplayName(ngp, attachment, name);
            }
            else {
                throw new Exception("update not implemented for this attachment type: " + ftype);
            }

            // handle the access by roles
            String[] roleNames = ar.multiParam("role");
            Vector<NGRole> checkedRoles = new Vector<NGRole>();
            for (String aName : roleNames) {
                NGRole possible = ngp.getRole(aName);
                if (possible != null) {
                    checkedRoles.add(possible);
                }
            }
            attachment.setAccessRoles(checkedRoles);
        }
        else if ("Accept".equals(action)) {
            throw new ProgramLogicError("Need to implement operation" + action);
        }
        else if ("Reject".equals(action)) {
            throw new ProgramLogicError("Need to implement operation" + action);
        }
        else if ("Skipped".equals(action)) {
            throw new ProgramLogicError("Need to implement operation" + action);
        }
        else if ("Remove".equals(action)) {
            ngp.deleteAttachment(aid, ar);
        }
        else if ("Add".equals(action)) {
            attachment.setType("FILE");
            AttachmentVersion aVer = attachment.getLatestVersion(ngp);
            if (aVer != null) {
                File curFile = aVer.getLocalFile();
                attachment.setAttachTime(curFile.lastModified());
                attachment.setModifiedDate(curFile.lastModified());
            }
            attachment.setModifiedBy(ar.getBestUserId());
            attachment.commitWorkingCopy(ngp);
        }
        else if ("Commit".equals(action)) {
            //used when a file is modified in the working directory
            //and will store the working copy as an official version
            attachment.setModifiedDate(ar.nowTime);
            attachment.setModifiedBy(ar.getBestUserId());
            attachment.commitWorkingCopy(ngp);
            AttachmentVersion aVer = attachment.getLatestVersion(ngp);

            //sets the file time so they are consistent
            File curFile = aVer.getLocalFile();
            curFile.setLastModified(ar.nowTime);
        }
        else if ("RefreshWorking".equals(action)) {
            throw new Exception("Refresh from backup is not implemented yet.");
        }
        else {
            throw new ProgramLogicError("Don't understand the operation: " + action);
        }

        HistoryRecord.createHistoryRecord(ngp, attachment.getId(),
                HistoryRecord.CONTEXT_TYPE_DOCUMENT, ar.nowTime, HistoryRecord.EVENT_DOC_UPDATED,
                ar, "");

        ngp.setLastModify(ar);
        ngp.saveFile(ar, "Modified attachments");
    }

    //Will remove this function while cleaning AccountDocumentController
    public static void updateAttachmentFile(String pageId,
            HttpServletRequest request,
            MultipartFile file,
            AuthRequest ar, String action,
            String visibility, NGContainer ngp) throws Exception {

        // get the list of files that has to be removed.
        Vector<String> rmFileIdVect = new Vector<String>();

        @SuppressWarnings("unchecked")
        Enumeration<String> en = request.getParameterNames();

        while (en.hasMoreElements()) {
            String key = en.nextElement();
            if (key.startsWith("rmFileId")) {
                String value = ar.defParam(key,"");
                rmFileIdVect.add(value);
            }
        }

        String[] filesToBeRemoved = new String[rmFileIdVect.size()];

        rmFileIdVect.copyInto(filesToBeRemoved);
        String aid = ar.reqParam("aid");
        AttachmentRecord attachment = ngp.findAttachmentByIDOrFail( aid );

        boolean isRemoveOp = (filesToBeRemoved.length > 0);
        if (isRemoveOp) {
            throw new NGException("nugen.exception.remove.files.unimplemented", null);
        }
        if ("Update".equals(action)) {

            String ftype = ar.reqParam("ftype");
            attachment = ngp.findAttachmentByIDOrFail(aid);
            if (!ftype.equals("FILE")) {
                throw new NGException("nugen.exception.attachment.type.problem",new Object[]{ftype});
            }

            attachment.setType("FILE");

            attachment.setDescription(ar.defParam("comment",""));

            if (visibility.equals("PUB")) {
                attachment.setVisibility(1);
            } else {
                attachment.setVisibility(2);
            }
            String name = ar.defParam("name","");
            if(file != null && file.getSize() > 0){
                attachment.setModifiedBy(ar.getBestUserId());
                attachment.setModifiedDate(ar.nowTime);
                setDisplayName(ngp, attachment,assureExtension(name, file.getOriginalFilename()));
                saveUploadedFile(ar, attachment, file);
            }else
            {
                setDisplayName(ngp, attachment, name);
            }

        } else if ("Accept".equals(action)) {

        } else if ("Reject".equals(action)) {

        } else if ("Skipped".equals(action)) {

        } else if ("Remove".equals(action)) {
            ngp.deleteAttachment( aid,ar);

        }
        else if ("UnDelete".equalsIgnoreCase(action)) {
            ngp.unDeleteAttachment( aid );
        }else {
            throw new ProgramLogicError("Don't understand the operation: " + action);
        }

        HistoryRecord.createHistoryRecord(ngp, attachment.getId(), HistoryRecord.CONTEXT_TYPE_DOCUMENT,
                ar.nowTime, HistoryRecord.EVENT_DOC_UPDATED, ar, "");
        ngp.saveContent( ar, "Modified attachments");

    }
*/

    public static String saveUploadedFile(AuthRequest ar, AttachmentRecord att,
            MultipartFile file) throws Exception {

        if(file.getSize() <= 0){
            //not sure why this would ever happen, but I saw other checks in the code for zero length
            //an just copying that here in the right place to check for it.
            throw new NGException("nugen.exception.file.size.zero",null);
        }
        String originalName = file.getOriginalFilename();
        // first make sure that the server is configured properly
        String attachFolder = ar.getSystemProperty("attachFolder");
        if (attachFolder == null) {
            throw new NGException(
                    "nugen.exception.system.configured.incorrectly",new Object[]{"attachFolder"});
        }
        File localRoot = new File(attachFolder);
        if (!localRoot.exists()) {
            throw new NGException("nugen.exception.incorrect.setting.for.attachfolder",
                    new Object[]{attachFolder});
        }
        if (!localRoot.isDirectory()) {
            throw new NGException("nugen.exception.incorrectfile.setting.for.attachfolder",
                    new Object[]{attachFolder});
        }

        // Figure out the file extension (including dot)
        if (originalName.indexOf("\\") >= 0) {
            throw new ProgramLogicError(
                    "Strange, got a path with a backslash.  This code assumes that will never happen. "
                            + originalName);
        }
        if (originalName.indexOf("/") >= 0) {
            throw new ProgramLogicError(
                    "Just checking: the source file name should not have any slashes "
                            + originalName);
        }
        int dotPos = originalName.lastIndexOf(".");
        if (dotPos < 0) {
            throw new NGException("nugen.exception.file.ext.missing",null);
        }
        String fileExtension = originalName.substring(dotPos);

        File tempFile = File.createTempFile("~editaction",  fileExtension);
        tempFile.delete();
        saveToFileAH(file, tempFile);
        FileInputStream fis = new FileInputStream(tempFile);
        att.streamNewVersion(ar, ar.ngp, fis);
        tempFile.delete();

        return fileExtension;
    }

    public static void saveToFileAH(MultipartFile file, File destinationFile)
            throws Exception {
        if (destinationFile == null) {
            throw new IllegalArgumentException(
                    "Can not save file.  Destination file must not be null.");
        }

        if (destinationFile.exists()) {
            throw new NGException("nugen.exception.file.already.exist",new Object[]{destinationFile});
        }
        File folder = destinationFile.getParentFile();
        if (!folder.exists()) {
            throw new NGException("nugen.exception.folder.not.exist" ,new Object[]{destinationFile});
        }

        try {
            FileOutputStream fileOut = new FileOutputStream(destinationFile);
            fileOut.write(file.getBytes());
            fileOut.close();
        } catch (Exception e) {
            throw new NGException("nugen.exception.failed.to.save.file", new Object[]{destinationFile}, e);
        }
    }

    public static String assureExtension(String dName, String fName) {
        if (dName == null || dName.length() == 0) {
            return fName;
        }
        int dotPos = fName.lastIndexOf(".");
        if (dotPos<0)
        {
            return dName;
        }
        String fileExtension = fName.substring(dotPos);
        if (!dName.endsWith(fileExtension))
        {
            dName = dName + fileExtension;
        }
        return dName;
    }

    public static void setDisplayName(NGContainer ngp, AttachmentRecord attachment,
            String proposedName) throws Exception {
        String currentName = attachment.getDisplayName();
        if (currentName.equals(proposedName)) {
            return; // nothing to do
        }
        if (attachment.equivalentName(proposedName)) {
            attachment.setDisplayName(proposedName);
            return;
        }
        String trialName = proposedName;

        String proposedRoot = proposedName;
        String proposedExt = "";
        int dotPos = proposedRoot.lastIndexOf(".");
        if (dotPos>0) {
            proposedExt = proposedRoot.substring(dotPos);
            proposedRoot = proposedRoot.substring(0, dotPos);
        }
        //now strip off any concluding hyphen number if present
        //but only if it is a hyphen followed by a single digit
        //if we get into double digit redundant names ... I don't care
        //about letting more hyphens appear
        if (proposedRoot.charAt(proposedRoot.length()-2) == '-') {
            char lastChar = proposedRoot.charAt(proposedRoot.length()-1);
            if (lastChar>='0' && lastChar <= '9') {
                proposedRoot = proposedRoot.substring(0, proposedRoot.length()-2);
            }
        }

        //NOTE: currently deleted documents are still present in the
        //project folder.  They probably should not be there.
        //TODO: remove deleted documents from project folder
        //so they do not cause a name clash that can not be seen.

        AttachmentRecord att = ngp.findAttachmentByName(trialName);
        int iteration = 0;
        while (att != null) {

            if (att.getType().equals("EXTRA")) {
                //This may be an attempt by the user to "reclaim" an attachment that had
                //been renamed, and discovered as a EXTRA file.   If this is the
                //case, then remove the EXTRA record.
                ngp.eraseAttachmentRecord(att.getId());
                att = null;
            }
            else {
                trialName = proposedRoot + "-"
                        + Integer.toString(++iteration)
                        + proposedExt;

                if (currentName.equals(trialName)) {
                    return; // nothing to do
                }
                if (attachment.equivalentName(trialName)) {
                    attachment.setDisplayName(trialName);
                    return;
                }
                att = ngp.findAttachmentByName(trialName);
            }
        }
        // if we get here, then there exists no other attachment with the trial
        // name
        attachment.setDisplayName(trialName);
    }

    /**
     * This is a method to find a file, and output the file as a
     * stream of bytes to the request output stream.
     */
    public static void serveUpFileNewUI(AuthRequest ar, NGContainer ngp, String fileName, int version)
        throws Exception
    {
        SectionAttachments.serveUpFileNewUI(ar,ngp,fileName,version);
    }

    public static void updateRemoteAttachment(
            AuthRequest ar,
            NGPage ngp, String comment, String rpath, String id,
            String name, String visibility) throws Exception {

        String aid = ar.reqParam("aid");

        AttachmentRecord attachment = ngp.findAttachmentByIDOrFail(aid);
        UserPage up = ar.getUserPage();
        ConnectionType cType = up.getConnectionOrFail(id);

        attachment.setType("FILE");
        String readonly  = ar.defParam("readOnly","off");
        attachment.setReadOnlyType(readonly);
        if(comment!=null) {
            attachment.setDescription(comment);
        }

        if(visibility!=null){
            if (visibility.equals("PUB")) {
                attachment.setVisibility(1);
            } else {
                attachment.setVisibility(2);
            }
        }
        AttachmentHelper.setDisplayName(ngp, attachment, name);

        if((id!=null)&&(rpath != null)){
            String userKey = ar.getUserProfile().getKey();
            RemoteLinkCombo comboSymbol = new RemoteLinkCombo(userKey, id, rpath);
            attachment.setRemoteCombo(comboSymbol);
        }

        attachment.setModifiedDate(ar.nowTime);
        attachment.setAttachTime(ar.nowTime);

        ResourceEntity re = cType.getResourceEntity(rpath, false);
        attachment.setFormerRemoteTime(re.getLastModifed());


        HistoryRecord.createHistoryRecord(ngp, attachment.getId(), HistoryRecord.CONTEXT_TYPE_DOCUMENT,
        ar.nowTime, HistoryRecord.EVENT_DOC_UPDATED, ar, "");

        ngp.setLastModify(ar);
        ngp.saveFile(ar, "Updatd remote attachments");
    }

    public static void unlinkDocFromRepository(AuthRequest ar, String aid, NGPage ngp) throws Exception{
        AttachmentRecord attachment = ngp.findAttachmentByIDOrFail(aid);
        attachment.setRemoteCombo(null);
        ngp.saveFile(ar, "Unlinked attachment from repository");
    }

    public static void linkToRemoteFile( AuthRequest ar, NGPage ngp, String aid,
                ResourceEntity remoteFile) throws Exception {
        AttachmentRecord attachment = ngp.findAttachmentByIDOrFail(aid);
        if (remoteFile!=null) {
            attachment.setRemoteCombo(remoteFile.getCombo());
            remoteFile.fillInDetails(false);
            attachment.setFormerRemoteTime(remoteFile.getLastModifed());
        }
        else {
            attachment.setRemoteCombo(null);
            attachment.setFormerRemoteTime(0);
        }

        HistoryRecord.createHistoryRecord(ngp, attachment.getId(), HistoryRecord.CONTEXT_TYPE_DOCUMENT,
            ar.nowTime, HistoryRecord.EVENT_DOC_UPDATED, ar, "");

        ngp.setLastModify(ar);
        ngp.saveFile(ar, "Modified attachments");
    }
}
