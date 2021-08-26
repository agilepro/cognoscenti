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

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.purplehillsbooks.weaver.AccessControl;
import com.purplehillsbooks.weaver.AttachmentRecord;
import com.purplehillsbooks.weaver.AuthRequest;
import com.purplehillsbooks.weaver.Cognoscenti;
import com.purplehillsbooks.weaver.HistoryRecord;
import com.purplehillsbooks.weaver.NGWorkspace;
import com.purplehillsbooks.weaver.ReminderMgr;
import com.purplehillsbooks.weaver.ReminderRecord;
import com.purplehillsbooks.weaver.UserManager;
import com.purplehillsbooks.weaver.UserPage;
import com.purplehillsbooks.weaver.dms.FolderAccessHelper;
import com.purplehillsbooks.weaver.dms.ResourceEntity;
import com.purplehillsbooks.weaver.exception.NGException;
import com.purplehillsbooks.weaver.exception.ProgramLogicError;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.ApplicationContext;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.ServletRequestDataBinder;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.multipart.support.ByteArrayMultipartFileEditor;

@Controller
public class UploadFileController extends BaseController {


    @Autowired
    public void setContext(ApplicationContext context) {
    }

    /*
    protected void initBinder(HttpServletRequest request,
            ServletRequestDataBinder binder) throws ServletException {

        binder.registerCustomEditor(byte[].class,new ByteArrayMultipartFileEditor());
    }
    */

    @RequestMapping(value = "/{siteId}/{pageId}/upload.form", method = RequestMethod.POST)
    protected void uploadFile(  @PathVariable String siteId, @PathVariable String pageId,
                HttpServletRequest request, HttpServletResponse response,
                @RequestParam("fname") MultipartFile file) throws Exception {
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            Cognoscenti cog = ar.getCogInstance();
            UserManager userManager = cog.getUserManager();
            NGWorkspace ngw = registerRequiredProject(ar, siteId, pageId);
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
                    ar.setUserForOneRequest(userManager.findUserByAnyIdOrFail(reminderRecord.getModifiedBy()));
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

            AttachmentHelper.uploadNewDocument(ar, ngw, file, desiredName, visibility, comment, "");

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
            NGWorkspace ngw = registerRequiredProject(ar, siteId, pageId);
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
            showJSPMembers(ar, siteId, pageId, "ReminderEmail");
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
            NGWorkspace ngw =  registerRequiredProject(ar, siteId, pageId);

            String reminderId = ar.reqParam("rid");
            String emailto = ar.defParam("emailto", null);
            ReminderRecord.reminderEmail(ar, pageId, reminderId, emailto, ngw);

            response.sendRedirect("reminders.htm");
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.project.resend.email.reminder", new Object[]{pageId,siteId} , ex);
        }
    }



    /*
    @RequestMapping(value = "/{siteId}/{pageId}/createLinkURL.form", method = RequestMethod.POST)
    protected void createLinkURL(@PathVariable String siteId,
            @PathVariable String pageId, HttpServletRequest request,
            HttpServletResponse response) throws Exception {
        try{
            AuthRequest ar = getLoggedInAuthRequest(request, response, "message.can.not.create.link.url");
            NGWorkspace ngw =  registerRequiredProject(ar, siteId, pageId);
            ar.assertNotFrozen(ngw);

            String comment = ar.reqParam("comment");
            String taskUrl = ar.reqParam("taskUrl");
            String ftype = ar.reqParam("ftype");

            AttachmentRecord attachment = ngw.createAttachment();
            String proposedName = taskUrl;

            if(taskUrl.contains("/")){
                proposedName = taskUrl.substring(taskUrl.lastIndexOf("/")+1);
            }

            AttachmentHelper.setDisplayName(ngw, attachment, proposedName);

            attachment.setDescription(comment);
            attachment.setModifiedBy(ar.getBestUserId());
            attachment.setModifiedDate(ar.nowTime);
            attachment.setType(ftype);

            HistoryRecord.createHistoryRecord(ngw, attachment.getId(), HistoryRecord.CONTEXT_TYPE_DOCUMENT,
                    ar.nowTime, HistoryRecord.EVENT_DOC_ADDED, ar, "Created Link URL");

            attachment.setURLValue(taskUrl);
            ngw.saveFile(ar, "Created Link URL");

            response.sendRedirect("DocsList.htm");
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.project.create.link.url.to.project", new Object[]{pageId,siteId} , ex);
        }
    }
    */


    @RequestMapping(value = "/{siteId}/{pageId}/linkURLToProject.htm", method = RequestMethod.GET)
    protected void getLinkURLToProjectForm(@PathVariable String siteId,
            @PathVariable String pageId, HttpServletRequest request,
            HttpServletResponse response) throws Exception {
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            NGWorkspace ngp =  registerRequiredProject(ar, siteId, pageId);

            if (warnFrozenOrNotMember(ar, ngp)) {
                return;
            }

            showJSPMembers(ar, siteId, pageId, "linkURLToProject");
        }
        catch(Exception ex){
            throw new NGException("nugen.operation.fail.project.linkurl.to.project.page", new Object[]{pageId,siteId} , ex);
        }
    }

    @RequestMapping(value = "/{siteId}/{pageId}/linkGoogleDoc.htm", method = RequestMethod.GET)
    protected void linkGoogleDoc(@PathVariable String siteId,
            @PathVariable String pageId, HttpServletRequest request,
            HttpServletResponse response) throws Exception {
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            NGWorkspace ngp =  registerRequiredProject(ar, siteId, pageId);

            if (warnFrozenOrNotMember(ar, ngp)) {
                return;
            }

            showJSPMembers(ar, siteId, pageId, "linkGoogleDoc");
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
            NGWorkspace ngp =  registerRequiredProject(ar, siteId, pageId);

            if (warnFrozenOrNotMember(ar, ngp)) {
                return;
            }

            request.setAttribute("isNewUpload", "yes");
            request.setAttribute("title", ngp.getFullName());
            showJSPMembers(ar, siteId, pageId, "emailreminder_form");

        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.project.email.reminder.page", new Object[]{pageId,siteId} , ex);
        }
    }





/*
    @RequestMapping(value = "/unDeleteAttachment.ajax", method = RequestMethod.POST)
    protected void unDeleteAttachment( HttpServletRequest request,
            HttpServletResponse response) throws Exception {

        AuthRequest ar = null;
        try {
            ar = getLoggedInAuthRequest(request, response, "message.must.be.login");
            String containerId=  ar.reqParam("containerId") ;
            NGWorkspace ngw = ar.getCogInstance().getWSByCombinedKeyOrFail(containerId).getWorkspace();
            ar.setPageAccessLevels(ngw);
            String aid = ar.reqParam("aid");
            AttachmentRecord attachment = ngw.findAttachmentByID(aid);
            if(attachment == null){
                throw new NGException("nugen.exception.no.attachment.found", new Object[]{aid, ngw.getFullName()});
            }
            attachment.clearDeleted();
            ngw.saveContent( ar, "Modified attachments");
            sendJson(ar, NGWebUtils.getJSONMessage("success" , "" , ""));
        }
        catch(Exception ex){
            streamException(ex,ar);
        }
    }
*/

     @RequestMapping(value = "/{siteId}/{pageId}/remindAttachment.htm", method = RequestMethod.GET)
     protected void remindAttachment(@PathVariable String siteId,
                @PathVariable String pageId, HttpServletRequest request,
                HttpServletResponse response) throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try{
            NGWorkspace ngw =  registerRequiredProject(ar, siteId, pageId);
            ar.setPageAccessLevels(ngw);

            String rid = ar.reqParam("rid");
            ReminderMgr mgr = ngw.getReminderMgr();
            ReminderRecord reminderRecord = mgr.findReminderByIDOrFail(rid);
            if (AccessControl.canAccessReminder(ar, ngw, reminderRecord)) {
                showJSPMembers(ar, siteId, pageId, "remindAttachment");
                return;
            }

            if(!ar.isLoggedIn()){
                request.setAttribute("property_msg_key", "You must be logged in to access this page.");
            }else if(!ar.isMember()){
                request.setAttribute("property_msg_key", "User "+ar.getUserProfile().getName()+" must be a Member of this workspace to open an document reminder of the Workspace");
                showJSPMembers(ar, siteId, pageId, "WarningNotMember");
            }else {
                //basically, the reminder should have been display, and we have no idea now why not
                throw new Exception("Program Logic Error ... something is wrong with the canAccessReminder method");
            }
            showJSPMembers(ar, siteId, pageId, "Warning");

        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.project.reminder.attachment.page",
                    new Object[]{pageId,siteId} , ex);
        }
     }

}
