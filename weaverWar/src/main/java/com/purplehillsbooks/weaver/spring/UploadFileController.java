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

package com.purplehillsbooks.weaver.spring;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import com.purplehillsbooks.weaver.AccessControl;
import com.purplehillsbooks.weaver.AttachmentRecord;
import com.purplehillsbooks.weaver.AuthRequest;
import com.purplehillsbooks.weaver.Cognoscenti;
import com.purplehillsbooks.weaver.HistoryRecord;
import com.purplehillsbooks.weaver.NGWorkspace;
import com.purplehillsbooks.weaver.ReminderMgr;
import com.purplehillsbooks.weaver.ReminderRecord;
import com.purplehillsbooks.weaver.UserManager;
import com.purplehillsbooks.weaver.exception.NGException;
import com.purplehillsbooks.weaver.exception.ProgramLogicError;
import com.purplehillsbooks.weaver.exception.WeaverException;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.multipart.MultipartFile;

@Controller
public class UploadFileController extends BaseController {




    @RequestMapping(value = "/{siteId}/{pageId}/upload.form", method = RequestMethod.POST)
    protected void uploadFile(  @PathVariable String siteId, @PathVariable String pageId,
                HttpServletRequest request, HttpServletResponse response,
                @RequestParam("fname") MultipartFile file) throws Exception {
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            Cognoscenti cog = ar.getCogInstance();
            UserManager userManager = cog.getUserManager();
            NGWorkspace ngw = registerWorkspaceRequired(ar, siteId, pageId);
            //Handling special case for Multipart request
            ar.req = request;

            ReminderRecord reminderRecord = null;

            boolean requestFromReminder = false;
            String rid = ar.defParam("rid", null);
            String go = ar.defParam("go", null);

            boolean canAccessToReminder = false;
            if(rid != null){
                // rid is not null its mean request to upload a document has come from 'Reminders To Share Document'
                requestFromReminder = true;
                ReminderMgr mgr = ngw.getReminderMgr();
                reminderRecord = mgr.findReminderByIDOrFail(rid);
                canAccessToReminder = AccessControl.canAccessReminder(ar, ngw, reminderRecord);

                //find the user profile of the user that created the reminder, and set the user
                //of record for this request to be that user.   Allows the rest of the request
                //to act as if the request is logged in under the name of the record creator.
                if (!ar.isLoggedIn()) {
                    ar.setPossibleUser(userManager.findUserByAnyIdOrFail(reminderRecord.getModifiedBy()));
                }
            }
            if(!requestFromReminder ||  !canAccessToReminder){
                ar.assertLoggedIn(ar.getMessageFromPropertyFile("message.can.not.upload.attachment", null));
            }

            ar.assertNotFrozen(ngw);
            request.setCharacterEncoding("UTF-8");

            if (file.getSize() == 0) {
                throw new NGException("nugen.exceptionhandling.no.file.attached",null);
            }

            if(file.getSize() > 500000000){
                throw new NGException("nugen.exceptionhandling.file.size.exceeded", new Object[]{"500000000"});
            }

            String fileName = file.getOriginalFilename();

            if (fileName == null || fileName.length() == 0) {
                throw new NGException("nugen.exceptionhandling.filename.empty", null);
            }

            String visibility = ar.defParam("visibility", "*MEM*");
            String comment = ar.defParam("comment", "");
            String desiredName = ar.defParam("name", null);

            uploadNewDocument(ar, ngw, file, desiredName, visibility, comment, "");

            if(reminderRecord != null){
                reminderRecord.setClosed();
                ngw.save();
            }
            if (go==null) {
                response.sendRedirect("DocsList.htm");
            }
            else {
                response.sendRedirect(go);
            }
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.project.upload.document", new Object[]{pageId,siteId} , ex);
        }
    }

    @RequestMapping(value = "/{siteId}/{pageId}/emailReminder.form", method = RequestMethod.POST)
    protected void submitEmailReminderForAttachment(
            @PathVariable String siteId, @PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        try{
            AuthRequest ar = getLoggedInAuthRequest(request, response, "message.can.not.send.email");
            NGWorkspace ngw = registerWorkspaceRequired(ar, siteId, pageId);
            ar.assertNotFrozen(ngw);

            String comment = ar.reqParam("comment");
            String pname = ar.defParam("pname", "");
            String assignee = ar.reqParam("assignee");
            String instruct = ar.reqParam("instruct");
            String subj = ar.reqParam("subj");
            String visibility = ar.reqParam("visibility");

            ReminderMgr rMgr = ngw.getReminderMgr();
            ReminderRecord rRec = rMgr.createReminder(ngw.getUniqueOnPage());
            rRec.setFileDesc(comment);
            rRec.setInstructions(instruct);
            rRec.setAssignee(assignee);
            rRec.setFileName(pname);
            rRec.setSubject(subj);
            rRec.setModifiedBy(ar.getBestUserId());
            rRec.setModifiedDate(ar.nowTime);
            rRec.setDestFolder(visibility);
            rRec.setSendNotification("yes");
            HistoryRecord.createHistoryRecord(ngw, rRec.getId(), HistoryRecord.CONTEXT_TYPE_DOCUMENT,
                    ar.nowTime, HistoryRecord.EVENT_DOC_ADDED, ar, "Added Reminder for "+assignee);

            ngw.saveFile(ar, "Modified attachments");
            response.sendRedirect("reminders.htm");
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.project.email.reminder", new Object[]{pageId,siteId} , ex);
        }

    }

    @RequestMapping(value = "/{siteId}/{pageId}/sendemailReminder.htm", method = RequestMethod.GET)
    protected void sendEmailReminderForAttachment(
            @PathVariable String siteId, @PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            showJSPMembers(ar, siteId, pageId, "ReminderEmail.jsp");
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.project.send.email.reminder", new Object[]{pageId,siteId} , ex);
        }
    }

    @RequestMapping(value = "/{siteId}/{pageId}/resendemailReminder.htm", method = RequestMethod.POST)
    protected void resendEmailReminderForAttachment(
            @PathVariable String siteId, @PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        try{
            AuthRequest ar = getLoggedInAuthRequest(request, response, "message.can.not.resend.email.reminder");
            NGWorkspace ngw =  registerWorkspaceRequired(ar, siteId, pageId);

            String reminderId = ar.reqParam("rid");
            String emailto = ar.defParam("emailto", null);
            ReminderRecord.reminderEmail(ar, pageId, reminderId, emailto, ngw);

            response.sendRedirect("reminders.htm");
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.project.resend.email.reminder", new Object[]{pageId,siteId} , ex);
        }
    }



    @RequestMapping(value = "/{siteId}/{pageId}/linkURLToProject.htm", method = RequestMethod.GET)
    protected void getLinkURLToProjectForm(@PathVariable String siteId,
            @PathVariable String pageId, HttpServletRequest request,
            HttpServletResponse response) throws Exception {
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            NGWorkspace ngw =  registerWorkspaceRequired(ar, siteId, pageId);

            if (warnFrozenOrNotMember(ar, ngw)) {
                return;
            }

            showJSPMembers(ar, siteId, pageId, "linkURLToProject.jsp");
        }
        catch(Exception ex){
            throw new NGException("nugen.operation.fail.project.linkurl.to.project.page", new Object[]{pageId,siteId} , ex);
        }
    }

    @RequestMapping(value = "/{siteId}/{pageId}/DocLinkGoogle.htm", method = RequestMethod.GET)
    protected void docLinkGoogle(@PathVariable String siteId,
            @PathVariable String pageId, HttpServletRequest request,
            HttpServletResponse response) throws Exception {
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            NGWorkspace ngw =  registerWorkspaceRequired(ar, siteId, pageId);

            if (warnFrozenOrNotMember(ar, ngw)) {
                return;
            }

            showJSPMembers(ar, siteId, pageId, "DocLinkGoogle.jsp");
        }
        catch(Exception ex){
            throw new NGException("nugen.operation.fail.project.linkurl.to.project.page", new Object[]{pageId,siteId} , ex);
        }
    }



    @RequestMapping(value = "/{siteId}/{pageId}/emailReminder.htm", method = RequestMethod.GET)
    protected void getEmailRemainderForm(@PathVariable String siteId,
            @PathVariable String pageId, HttpServletRequest request,
            HttpServletResponse response) throws Exception {
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            NGWorkspace ngw =  registerWorkspaceRequired(ar, siteId, pageId);

            if (warnFrozenOrNotMember(ar, ngw)) {
                return;
            }

            request.setAttribute("isNewUpload", "yes");
            request.setAttribute("title", ngw.getFullName());
            showJSPMembers(ar, siteId, pageId, "emailreminder_form.jsp");

        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.project.email.reminder.page", new Object[]{pageId,siteId} , ex);
        }
    }




     @RequestMapping(value = "/{siteId}/{pageId}/remindAttachment.htm", method = RequestMethod.GET)
     protected void remindAttachment(@PathVariable String siteId,
                @PathVariable String pageId, HttpServletRequest request,
                HttpServletResponse response) throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try{
            NGWorkspace ngw =  registerWorkspaceRequired(ar, siteId, pageId);
            ar.setPageAccessLevels(ngw);

            String rid = ar.reqParam("rid");
            ReminderMgr mgr = ngw.getReminderMgr();
            ReminderRecord reminderRecord = mgr.findReminderByIDOrFail(rid);
            if (AccessControl.canAccessReminder(ar, ngw, reminderRecord)) {
                showJSPMembers(ar, siteId, pageId, "remindAttachment.jsp");
                return;
            }

            if(!ar.isLoggedIn()){
                request.setAttribute("property_msg_key", "You must be logged in to access this page.");
            }else if(!ar.canAccessWorkspace()){
                request.setAttribute("property_msg_key", "User "+ar.getUserProfile().getName()+" must be a Member of this workspace to open an document reminder of the Workspace");
                showJSPMembers(ar, siteId, pageId, "WarningNotMember.jsp");
            }else {
                //basically, the reminder should have been display, and we have no idea now why not
                throw new Exception("Program Logic Error ... something is wrong with the canAccessReminder method");
            }
            showJSPMembers(ar, siteId, pageId, "Warning.jsp");

        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.project.reminder.attachment.page",
                    new Object[]{pageId,siteId} , ex);
        }
     }

    private static void uploadNewDocument(AuthRequest ar,
                                            NGWorkspace ngc,
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

        //if the existing document is marked deleted, you want to clear
        //that now that a new version has appeared.  Otherwise the new
        //uploaded document remains deleted.
        attachment.clearDeleted();

        setAttachmentDisplayName(ngc, attachment, assureExtension(desiredName, fileName));
        saveUploadedFile(ar, attachment, file);
        HistoryRecord.createHistoryRecord(ngc, attachment.getId(), HistoryRecord.CONTEXT_TYPE_DOCUMENT,
                ar.nowTime, HistoryRecord.EVENT_DOC_ADDED, ar, "");

        ngc.saveFile(ar, comment);
    }


    private static String saveUploadedFile(AuthRequest ar, AttachmentRecord att,
            MultipartFile file) throws Exception {

        if(file.getSize() <= 0){
            //not sure why this would ever happen, but I saw other checks in the code for zero length
            //an just copying that here in the right place to check for it.
            throw new NGException("nugen.exception.file.size.zero",null);
        }
        String originalName = file.getOriginalFilename();


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
        att.streamNewVersion(ar, (NGWorkspace)ar.ngp, fis);
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
    
    private static String assureExtension(String dName, String fName) {
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

    private static void setAttachmentDisplayName(NGWorkspace ngw, AttachmentRecord attachment,
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

        AttachmentRecord att = ngw.findAttachmentByName(trialName);
        int iteration = 0;
        while (att != null) {

            if (att.getType().equals("EXTRA")) {
                throw WeaverException.newBasic("Found an attachment of type EXTRA and there should not be any");
            }
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
            att = ngw.findAttachmentByName(trialName);
        }
        // if we get here, then there exists no other attachment with the trial name
        attachment.setDisplayName(trialName);
    }
    
}
