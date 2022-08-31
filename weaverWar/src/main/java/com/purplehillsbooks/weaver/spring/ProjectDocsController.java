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

import java.io.InputStream;
import java.net.URLEncoder;
import java.util.ArrayList;
import java.util.List;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.purplehillsbooks.weaver.AccessControl;
import com.purplehillsbooks.weaver.AgendaItem;
import com.purplehillsbooks.weaver.AttachmentRecord;
import com.purplehillsbooks.weaver.AttachmentVersion;
import com.purplehillsbooks.weaver.AuthRequest;
import com.purplehillsbooks.weaver.Cognoscenti;
import com.purplehillsbooks.weaver.CommentContainer;
import com.purplehillsbooks.weaver.CommentRecord;
import com.purplehillsbooks.weaver.DOMFace;
import com.purplehillsbooks.weaver.EmailGenerator;
import com.purplehillsbooks.weaver.GoalRecord;
import com.purplehillsbooks.weaver.HistoryRecord;
import com.purplehillsbooks.weaver.MeetingRecord;
import com.purplehillsbooks.weaver.NGPageIndex;
import com.purplehillsbooks.weaver.NGRole;
import com.purplehillsbooks.weaver.NGWorkspace;
import com.purplehillsbooks.weaver.SectionAttachments;
import com.purplehillsbooks.weaver.SharePortRecord;
import com.purplehillsbooks.weaver.TopicRecord;
import com.purplehillsbooks.weaver.UserCache;
import com.purplehillsbooks.weaver.UserManager;
import com.purplehillsbooks.weaver.UserProfile;
import com.purplehillsbooks.weaver.WikiToPDF;
import com.purplehillsbooks.weaver.exception.NGException;
import com.purplehillsbooks.weaver.mail.EmailSender;
import com.purplehillsbooks.weaver.mail.MailInst;
import com.purplehillsbooks.weaver.util.MimeTypes;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;

import com.purplehillsbooks.json.JSONArray;
import com.purplehillsbooks.json.JSONException;
import com.purplehillsbooks.json.JSONObject;

@Controller
public class ProjectDocsController extends BaseController {


    @RequestMapping(value = "/{siteId}/{pageId}/DocsList.htm", method = RequestMethod.GET)
    public void docsList(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        BaseController.showJSPMembers(ar, siteId, pageId, "DocsList.jsp");
    }


    @RequestMapping(value = "/{siteId}/{pageId}/DocsFolder.htm", method = RequestMethod.GET)
    public void docsFolder(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        BaseController.showJSPMembers(ar, siteId, pageId, "DocsFolder.jsp");
    }


    @RequestMapping(value = "/{siteId}/{pageId}/DocsUpload.htm", method = RequestMethod.GET)
    protected void docsUpload(@PathVariable String siteId,
            @PathVariable String pageId, HttpServletRequest request,
            HttpServletResponse response) throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        BaseController.showJSPMembers(ar, siteId, pageId, "DocsUpload.jsp");
    }

    /**
     * Let the user decide how to add a document to the project
     */
    @RequestMapping(value = "/{siteId}/{pageId}/DocsAdd.htm", method = RequestMethod.GET)
    protected void docsAdd(@PathVariable String siteId,
            @PathVariable String pageId, HttpServletRequest request,
            HttpServletResponse response) throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        BaseController.showJSPNotFrozen(ar, siteId, pageId, "DocsAdd.jsp");
    }

    /**
     * Let the user decide how to add a document to the project
     */
    @RequestMapping(value = "/{siteId}/{pageId}/WorkspaceCopyMove1.htm", method = RequestMethod.GET)
    protected void WorkspaceCopyMove1(@PathVariable String siteId,
            @PathVariable String pageId, HttpServletRequest request,
            HttpServletResponse response) throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        BaseController.showJSPMembers(ar, siteId, pageId, "WorkspaceCopyMove1.jsp");
    }

    /**
     * Let the user decide how to add a document to the project
     */
    @RequestMapping(value = "/{siteId}/{pageId}/WorkspaceCopyMove2.htm", method = RequestMethod.GET)
    protected void WorkspaceCopyMove2(@PathVariable String siteId,
            @PathVariable String pageId, HttpServletRequest request,
            HttpServletResponse response) throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        BaseController.showJSPMembers(ar, siteId, pageId, "WorkspaceCopyMove2.jsp");
    }

    // this will be DocDetail.htm??aid={aid}&lic={license}
    @RequestMapping(value = "/{siteId}/{pageId}/DocDetail.htm", method = RequestMethod.GET)
    protected void docDetail(@PathVariable String siteId,
             @PathVariable String pageId,
             HttpServletRequest request,  HttpServletResponse response) throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        String aid = ar.reqParam("aid");

        request.setAttribute("aid", aid);
        NGWorkspace ngw = registerRequiredProject(ar, siteId, pageId);
        AttachmentRecord att = ngw.findAttachmentByID(aid);
        boolean specialAccess = AccessControl.canAccessDoc(ar, ngw, att);
        BaseController.showJSPDepending(ar, ngw, "DocDetail.jsp", specialAccess);
    }

    @RequestMapping(value = "/{siteId}/{pageId}/DocsVersions.htm", method = RequestMethod.GET)
    protected void docsVersions(@PathVariable String siteId,
             @PathVariable String pageId,
             HttpServletRequest request,  HttpServletResponse response) throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);

        //special behavior.  On the list versions page, if someone hits this when NOT LOGGED IN
        //then redirect to the document information page, which is allowed when not logged in,
        //and from there they can decide whether to log in or not, and then to list the versions.
        //Seems better than just saying you are not logged in.
        if (!ar.isLoggedIn()) {
            ar.resp.sendRedirect("DocDetail.htm?aid="+URLEncoder.encode(ar.reqParam("aid"), "UTF-8"));
            return;
        }

        request.setAttribute("aid", ar.reqParam("aid"));
        BaseController.showJSPAnonymous(ar, siteId, pageId, "DocsVersions.jsp");
    }

    @RequestMapping(value = "/{siteId}/{pageId}/DocsRevise.htm", method = RequestMethod.GET)
    protected void docsRevise(@PathVariable String siteId,
             @PathVariable String pageId,
             HttpServletRequest request,  HttpServletResponse response) throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);

        //special behavior.  On the Upload New Version page, if someone hits this when NOT LOGGED IN
        //then redirect to the document information page, which is allowed when not logged in,
        //and from there they can decide whether to log in or not, and then to add a new version.
        //Seems better than just saying you are not logged in.
        if (!ar.isLoggedIn()) {
            ar.resp.sendRedirect("DocDetail.htm?aid="+URLEncoder.encode(ar.reqParam("aid"), "UTF-8"));
            return;
        }

        //ngp.findAttachmentByIDOrFail(aid);
        request.setAttribute("aid", ar.reqParam("aid"));
        BaseController.showJSPAnonymous(ar, siteId, pageId, "DocsRevise.jsp");
    }



    @RequestMapping(value="/{siteId}/{pageId}/a/{docName}.{ext}", method = RequestMethod.GET)
     public void loadDocument(
           @PathVariable String siteId,
           @PathVariable String pageId,
           @PathVariable String docName,
           @PathVariable String ext,
           HttpServletRequest request,
           HttpServletResponse response) throws Exception {
        try{
            NGPageIndex.assertNoLocksOnThread();
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            NGWorkspace ngw = registerRequiredProject(ar, siteId, pageId);

            String attachmentName = docName+"."+ext;
            AttachmentRecord att = ngw.findAttachmentByNameOrFail(attachmentName);

            boolean canAccessDoc = AccessControl.canAccessDoc(ar, ngw, att);

            if(!canAccessDoc){
                sendRedirectToLogin(ar);
                return;
            }

            int version = DOMFace.safeConvertInt(ar.defParam("version", null));

            //get the mime type from the file extension
            String mimeType=MimeTypes.getMimeType(attachmentName);
            ar.resp.setContentType(mimeType);
            //set expiration to about 1 year from now
            ar.resp.setDateHeader("Expires", ar.nowTime + 31000000000L);

            // Temporary fix: To force the browser to show 'SaveAs' dialogbox with right format.
            // Note this originally had some code that assumed that old versions of a file
            // might have a different extension.  I don't see how this can happen.
            // The attachment has a name, and that name holds for all versions.  If you
            // change the name, it changes all the versions.  I don't see how old
            // versions might have a different extension....  Removed complicated logic.
            ar.resp.setHeader( "Content-Disposition", "attachment; filename=\"" + attachmentName + "\"" );

            AttachmentVersion attachmentVersion = SectionAttachments.getVersionOrLatest(ngw,attachmentName,version);
            ar.resp.setHeader( "Content-Length", Long.toString(attachmentVersion.getFileSize()) );

            att.createHistory(ar, ngw, HistoryRecord.EVENT_DOC_DOWNLOADED, "Downloaded document "+attachmentName);

            InputStream fis = attachmentVersion.getInputStream();

            //NOTE: now that we have the input stream, we can let go of the project.  This is important
            //to prevent holding the lock for the entire time that it takes for the client to download
            //the file.  Remember, slow clients might take minutes to download a large file.
            ngw.save();
            NGPageIndex.releaseLock(ngw);
            ngw=null;

            ar.streamBytesOut(fis);
            fis.close();
        }
        catch(Exception ex){
            //why sleep?  Here, this is VERY IMPORTANT
            //Someone might be trying all the possible file names just to
            //see what is here.  A three second sleep makes that more difficult.
            Thread.sleep(3000);
            throw new NGException("nugen.operation.fail.project.download.document", new Object[]{pageId,siteId} , ex);
        }
    }

    
    /**
     * This is a view that prompts the user to specify how they want the PDF to be produced.
     */
    @RequestMapping(value = "/{siteId}/{pageId}/exportPDF.htm", method = RequestMethod.GET)
    public void exportPDF(HttpServletRequest request, HttpServletResponse response,
            @PathVariable String pageId, @PathVariable String siteId) throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        showJSPMembers(ar, siteId, pageId, "exportPDF.jsp");
    }



    

    /**
    * note that the docid in the path is not needed, but it will be different for
    * every file for convenience of auto-generating a file name to save to.
    *
    * following the name is a bunch of query paramters listing the topics to include in the output.
    */
    @RequestMapping(value="/{siteId}/{pageId}/pdf/{docId}.pdf", method = RequestMethod.GET)
    public void generatePDFDocument(
            @PathVariable String siteId,
            @PathVariable String pageId,
            @PathVariable String docId,
            HttpServletRequest request,
            HttpServletResponse response) throws Exception {

        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            ar.getCogInstance().getSiteByIdOrFail(siteId);
            NGWorkspace ngw = registerRequiredProject(ar, siteId, pageId);

            //this constructs and outputs the PDF file to the output stream
            WikiToPDF.handlePDFRequest(ar, ngw);

        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.project.download.document", new Object[]{pageId,siteId} , ex);
        }
    }


    @RequestMapping(value = "/{siteId}/{pageId}/reminders.htm", method = RequestMethod.GET)
    public void remindersTab(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            registerRequiredProject(ar, siteId, pageId);
            showJSPMembers(ar, siteId, pageId, "reminders.jsp");
        }catch(Exception ex){
            throw new JSONException("Failed to open reminder page of workspace {0} in site {1}", ex, pageId, siteId);
        }
    }



    @RequestMapping(value = "/{siteId}/{pageId}/docInfo.json", method = RequestMethod.GET)
    public void docInfo(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        String did = "";
        try{
            did = ar.reqParam("did");
            NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail( siteId, pageId ).getWorkspace();
            ar.setPageAccessLevels(ngw);
            AttachmentRecord attachment = ngw.findAttachmentByIDOrFail(did);
            boolean canAccessDoc = AccessControl.canAccessDoc(ar, ngw, attachment);
            if (!canAccessDoc) {
                throw new JSONException("Unable for user {1} to access document {0}", did, ar.getBestUserId());
            }

            JSONObject repo = attachment.getJSON4Doc(ar, ngw);
            sendJson(ar, repo);
        }
        catch(Exception ex){
            Exception ee = new Exception("Failure accessing document "+did, ex);
            streamException(ee, ar);
        }
    }


    @RequestMapping(value = "/{siteId}/{pageId}/docsUpdate.json", method = RequestMethod.POST)
    public void docsUpdate(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        String did = "";
        try{
            did = ar.reqParam("did");
            NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail( siteId, pageId ).getWorkspace();
            ar.setPageAccessLevels(ngw);
            ar.assertNotFrozen(ngw);
            ar.assertNotReadOnly("Cannot update a document.");
            
            JSONObject docInfo = getPostedObject(ar);
            int historyEventType = 0;

            AttachmentRecord aDoc = null;
            if ("~new~".equals(did)) {
                aDoc = ngw.createAttachment();
                docInfo.put("universalid", aDoc.getUniversalId());
                aDoc.setModifiedDate(ar.nowTime);
                aDoc.setModifiedBy(ar.getBestUserId());
                aDoc.setType(docInfo.getString("attType"));
                historyEventType = HistoryRecord.EVENT_DOC_ADDED;
            }
            else {
                aDoc = ngw.findAttachmentByIDOrFail(did);
                historyEventType = HistoryRecord.EVENT_DOC_UPDATED;
            }

            //everything else updated here
            aDoc.updateDocFromJSON(docInfo, ar);

            HistoryRecord.createHistoryRecord(ngw, aDoc.getId(), HistoryRecord.CONTEXT_TYPE_DOCUMENT,
                    ar.nowTime, historyEventType, ar, "");

            ngw.saveFile(ar, "Updated Agenda Item");
            JSONObject repo = aDoc.getJSON4Doc(ar, ngw);
            sendJson(ar, repo);
        }catch(Exception ex){
            Exception ee = new Exception("Unable to update document "+did, ex);
            streamException(ee, ar);
        }
    }


    @RequestMapping(value = "/{siteId}/{pageId}/docsList.json", method = RequestMethod.GET)
    public void docsListJSON(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try{
            NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail( siteId, pageId ).getWorkspace();
            ar.setPageAccessLevels(ngw);
            ar.assertAccessWorkspace("Must have access to a workspace to get the document list.");

            JSONArray attachmentList = new JSONArray();
            for (AttachmentRecord doc : ngw.getAllAttachments()) {
                attachmentList.put(doc.getJSON4Doc(ar, ngw));
            }

            JSONObject repo = new JSONObject();
            repo.put("docs", attachmentList);
            sendJson(ar, repo);
        }catch(Exception ex){
            Exception ee = new Exception("Unable to get the list of attachments ", ex);
            streamException(ee, ar);
        }
    }


    @RequestMapping(value = "/{siteId}/{pageId}/copyDocument.json", method = RequestMethod.POST)
    public void copyAttachment(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) {
        copyMoveDocument(siteId, pageId, false, request, response);
    }

    @RequestMapping(value = "/{siteId}/{pageId}/moveDocument.json", method = RequestMethod.POST)
    public void moveDocument(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) {
        copyMoveDocument(siteId, pageId, true, request, response);
    }

    public void copyMoveDocument(String siteId, String pageId, boolean deleteOld,
                HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try{
            JSONObject postBody = this.getPostedObject(ar);
            String fromCombo = postBody.getString("from");
            String docId = postBody.getString("id");

            Cognoscenti cog = ar.getCogInstance();
            NGWorkspace thisWS = cog.getWSBySiteAndKeyOrFail( siteId, pageId ).getWorkspace();
            NGWorkspace fromWS = cog.getWSByCombinedKeyOrFail( fromCombo ).getWorkspace();

            ar.setPageAccessLevels(thisWS);
            ar.assertNotFrozen(thisWS);
            ar.assertUpdateWorkspace("You must be able to update the workspace you are copying to");
            ar.assertNotReadOnly("Cannot copy a document");
            ar.setPageAccessLevels(fromWS);
            ar.assertAccessWorkspace("You must be able to access the workspace you are copying from");

            AttachmentRecord oldDoc = fromWS.findAttachmentByID(docId);
            if (oldDoc==null) {
                throw new Exception("Unable to find a document with id="+docId);
            }

            String docName = oldDoc.getDisplayName();
            AttachmentRecord newCopy = thisWS.findAttachmentByName(docName);
            if (newCopy == null) {
                newCopy = thisWS.createAttachment();
                newCopy.setDisplayName(docName);
            }
            else {
                if (newCopy.isDeleted()) {
                    newCopy.clearDeleted();
                }
            }
            newCopy.setDescription(oldDoc.getDescription());
            newCopy.setUniversalId(oldDoc.getUniversalId());
            String docType = oldDoc.getType();
            newCopy.setType(docType);

            if ("FILE".equals(docType)) {
                AttachmentVersion av = oldDoc.getLatestVersion(fromWS);
                InputStream is = av.getInputStream();
                newCopy.streamNewVersion(ar, thisWS, is);
                is.close();
            }
            else if ("URL".equals(docType)) {
                newCopy.setURLValue(oldDoc.getURLValue());
            }
            else {
                throw new Exception("Don't understand how to move document '"+docName+"' type "+docType);
            }

            if (deleteOld) {
                oldDoc.setDeleted(ar);
                fromWS.saveFile(ar, "Document '"+docName+"' transferred to workspace: "+thisWS.getFullName());
            }

            JSONObject repo = new JSONObject();
            repo.put("created", newCopy.getJSON4Doc(ar, thisWS));

            thisWS.saveFile(ar, "Document '"+docName+"' copied from workspace: "+fromWS.getFullName());

            sendJson(ar, repo);
        }catch(Exception ex){
            Exception ee = new Exception("Unable to copy/move the document", ex);
            streamException(ee, ar);
        }
    }


    @RequestMapping(value = "/{siteId}/{pageId}/SharePorts.htm", method = RequestMethod.GET)
    public void sharePorts(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        BaseController.showJSPMembers(ar, siteId, pageId, "SharePorts.jsp");
    }

    @RequestMapping(value = "/{siteId}/{pageId}/sharePorts.json", method = RequestMethod.GET)
    public void sharePortsJSON(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try{
            NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail( siteId, pageId ).getWorkspace();
            JSONObject repo = new JSONObject();
            JSONArray shareList = new JSONArray();
            for (SharePortRecord spr : ngw.getSharePorts()) {
                shareList.put(spr.getMinJSON());
            }
            repo.put("shares", shareList);
            sendJson(ar, repo);
        }catch(Exception ex){
            Exception ee = new Exception("Unable to get the list of share ports ", ex);
            streamException(ee, ar);
        }
    }

    @RequestMapping(value = "/{siteId}/{pageId}/share/{id}.json")
    public void onePortJSON(@PathVariable String siteId,
            @PathVariable String pageId,
            @PathVariable String id,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try{
            NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail( siteId, pageId ).getWorkspace();
            SharePortRecord spr = null;
            boolean needSave = false;
            if ("~new~".equals(id)) {
                ar.assertNotFrozen(ngw);
                spr = ngw.createSharePort();
                id = spr.getPermId();
                needSave = true;
            }
            else {
                spr = ngw.findSharePortOrFail(id);
            }
            if ("POST".equalsIgnoreCase(request.getMethod())) {
                JSONObject postBody = this.getPostedObject(ar);
                ar.assertNotFrozen(ngw);
                spr.updateFromJSON(postBody);
                needSave = true;
            }
            if (needSave) {
                ngw.saveModifiedWorkspace(ar, "updating the share ports");
            }
            JSONObject repo = spr.getFullJSON(ngw);
            sendJson(ar, repo);
        }catch(Exception ex){
            Exception ee = new Exception("Unable to get the list of share ports ", ex);
            streamException(ee, ar);
        }
    }

    @RequestMapping(value = "/{siteId}/{pageId}/share/{id}.htm", method = RequestMethod.GET)
    public void specialShare(@PathVariable String siteId,
            @PathVariable String pageId,
            @PathVariable String id,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        ar.setParam("id", id);
        ar.setParam("pageId", pageId);
        ar.setParam("siteId", siteId);
        streamJSPAnonUnwrapped(ar, "Share.jsp");
    }

    
    //this is the old pattern, harder to accommodate in the ring scheme, so change to a
    //new one which is more the regular pattern.   This needed in case there are 
    //old emails around with the old pattern.
    @RequestMapping(value = "/{siteId}/{pageId}/reply/{topicId}/{commentId}.htm", method = RequestMethod.GET)
    public void forwardReply(@PathVariable String siteId,
            @PathVariable String pageId,
            @PathVariable String topicId,
            @PathVariable String commentId,
    HttpServletRequest request, HttpServletResponse response) throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);

        int hyphenPos = topicId.indexOf("-");
        String meetId = null;
        String agendaId = null;
        if (hyphenPos>0) {
            meetId = topicId.substring(0,hyphenPos);
            agendaId = topicId.substring(hyphenPos+1);
            topicId = null;
        }
        String responseUrl = "../../Reply.htm?commentId=" +URLEncoder.encode(commentId, "UTF-8");
        if (topicId!=null) {
            responseUrl += "&topicId="+URLEncoder.encode(topicId, "UTF-8");
        }
        if (meetId!=null) {
            responseUrl += "&meetId="+URLEncoder.encode(meetId, "UTF-8");
        }
        if (agendaId!=null) {
            responseUrl += "&agendaId="+URLEncoder.encode(agendaId, "UTF-8");
        }
        String emailId = ar.defParam("emailId", null);
        if (emailId!=null) {
            responseUrl += "&emailId="+URLEncoder.encode(emailId, "UTF-8");
        }
        String mnnote = ar.defParam("mnnote", null);
        if (mnnote!=null) {
            responseUrl += "&mnnote="+URLEncoder.encode(mnnote, "UTF-8");
        }
        String mnm = ar.defParam("mnm", null);
        if (mnm!=null) {
            responseUrl += "&mnm="+URLEncoder.encode(mnm, "UTF-8");
        }

        ar.resp.sendRedirect(responseUrl);
    }
    
    
    @RequestMapping(value = "/{siteId}/{pageId}/Reply.htm", method = RequestMethod.GET)
    public void specialReply(@PathVariable String siteId,
            @PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        NGWorkspace ngw = registerRequiredProject(ar, siteId, pageId);

        String msgLocator = ar.defParam("msg", null);
        System.out.println("Reply.htm - got message locator="+msgLocator);
        if (msgLocator==null) {
            //preserve old behavior just in case
            specialReplyOld(siteId, pageId, request, response);
            return;
        }
        
        long msgId = MailInst.getCreateDateFromLocator(msgLocator);
        if (msgId==0) {
            showJSPDepending(ar, ngw, "ReplyNoEmail.jsp", false);
            return;
        }
        if (msgId<=0) {
            throw new Exception("Can not understand the msg locator: "+msgLocator);
        }
        long commentId = MailInst.getCommentIdFromLocator(msgLocator);
        
        MailInst foundMsg = EmailSender.findEmailById(msgId);
        if (foundMsg==null) {
            throw new Exception("Can not find the message from locator: "+msgLocator);
        }

        String containerKey = foundMsg.getCommentContainer();
        if (containerKey==null) {
            throw new Exception("stored email message is missing container key,   msgLocator="+msgLocator);
        }
        
        //check for consistency as a way to avoid hacking
        if (commentId>0 && commentId != foundMsg.getCommentId()) {
            throw new Exception("Can msg locator has wrong comment id in it: "+msgLocator);
        }
        
        //if you get here, then you have a link and the email msg id and the comment id match
        //which means you are not a hacker, so we can allow access to the content.
        
        CommentContainer container = CommentContainer.findContainerByKey(ngw, containerKey);
        if (container==null) {
            throw new Exception("Unable to find a container comment with key="+containerKey);
        }
        if (!containerKey.contentEquals(container.getGlobalContainerKey(ngw))) {
            throw new Exception("Something is wrong, container keys don't match: "+containerKey+" AND "+container.getGlobalContainerKey(ngw));
        }

        boolean specialAccess = false;
        if (container instanceof AgendaItem) {
            AgendaItem ai = (AgendaItem)container;
            MeetingRecord meet = ai.meeting;
            specialAccess  = AccessControl.canAccessMeeting(ar, ngw, meet);
            ar.setParam("meetId", meet.getId());
            ar.setParam("agendaId", ai.getId());
        }
        else if (container instanceof TopicRecord) {
            TopicRecord topic = (TopicRecord)container;
            //normally the permission comes from a license in the URL for anonymous access
            specialAccess  = AccessControl.canAccessTopic(ar, ngw, topic);
            ar.setParam("topicId", topic.getId());
        }
        else if (container instanceof AttachmentRecord) {
            AttachmentRecord doc =(AttachmentRecord)container;
            //normally the permission comes from a license in the URL for anonymous access
            specialAccess  = AccessControl.canAccessDoc(ar, ngw, doc);
        }
        else {
            throw new Exception("Can not understand why comment container is a "+container.getClass().getCanonicalName());
        }
        ar.setParam("emailId", foundMsg.getFromAddress());
        ar.setParam("commentId", commentId);
        ar.setParam("msgId", msgId);
        ar.setParam("pageId", pageId);
        ar.setParam("siteId", siteId);
        showJSPDepending(ar, ngw, "Reply.jsp", specialAccess);
    }
    public void specialReplyOld(@PathVariable String siteId,
            @PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);

        String topicId = ar.defParam("topicId", null);
        String commentId = ar.defParam("commentId", null);
        String meetId = ar.defParam("meetId", null);
        String agendaId = ar.defParam("agendaId", null);
        String emailId = ar.defParam("emailId", null);
        NGWorkspace ngw = registerRequiredProject(ar, siteId, pageId);

        boolean specialAccess = false;
        if (meetId!=null) {
            MeetingRecord meet = ngw.findMeeting(meetId);
            meet.findAgendaItem(agendaId);
            specialAccess  = AccessControl.canAccessMeeting(ar, ngw, meet);
        }
        else {
            TopicRecord note = ngw.getNoteOrFail(topicId);
            //normally the permission comes from a license in the URL for anonymous access
            specialAccess  = AccessControl.canAccessTopic(ar, ngw, note);
        }
        ar.setParam("topicId", topicId);
        ar.setParam("meetId", meetId);
        ar.setParam("agendaId", agendaId);
        ar.setParam("emailId", emailId);
        ar.setParam("commentId", commentId);
        ar.setParam("pageId", pageId);
        ar.setParam("siteId", siteId);
        showJSPDepending(ar, ngw, "Reply.jsp", specialAccess);
    }

    @RequestMapping(value = "/{siteId}/{pageId}/unsub/{topicId}/{commentId}.htm", method = RequestMethod.GET)
    public void specialUnsub(@PathVariable String siteId,
            @PathVariable String pageId,
            @PathVariable String topicId,
            @PathVariable String commentId,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        NGWorkspace ngw = registerRequiredProject(ar, siteId, pageId);
        ngw.getNoteOrFail(topicId);
        ar.setParam("topicId", topicId);
        ar.setParam("commentId", commentId);
        ar.setParam("pageId", pageId);
        ar.setParam("siteId", siteId);
        streamJSPAnonUnwrapped(ar, "Unsub.jsp");
    }

    @RequestMapping(value = "/su/Feedback.htm", method = RequestMethod.GET)
    public void Feedback(HttpServletRequest request, HttpServletResponse response) throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        streamJSPAnonUnwrapped(ar, "Feedback.jsp");
    }

    @RequestMapping(value = "/{siteId}/{pageId}/SaveReply.json", method = RequestMethod.POST)
    public void specialReplySave(@PathVariable String siteId,
            @PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try {
            NGWorkspace ngw = registerRequiredProject(ar, siteId, pageId);
            ar.setPageAccessLevels(ngw);
            ar.assertNotFrozen(ngw);
            JSONObject input = getPostedObject(ar);
            if (!input.has("comments")) {
                throw new Exception("posted object to specialReplySave needs to have a comments list");
            }
            String topicId = input.optString("topicId");
            //String commentId = input.optString("commentId", null);
            String meetId = input.optString("meetId", null);
            String agendaId = input.optString("agendaId", null);
            
            if (!ar.isLoggedIn()) {
                String emailId = input.optString("emailId", null);
                UserManager userMgr = UserManager.getStaticUserManager();
                UserProfile possUser = userMgr.lookupUserByAnyId(emailId);
                if (possUser == null) {
                    //what to do here?  User has created or updated a comment on an email address
                    //that does not have a user profile.   Create one.

                    possUser = userMgr.createUserWithId(emailId);
                    possUser.setName(input.optString("userName", ""));
                    possUser.setDescription("Profile created by entering an anonymous reply to a comment in workspace: "+ngw.getFullName());
                    userMgr.saveUserProfiles();
                }
                else {
                    //not logged in, but if user object does not have a name try to set it
                    String currentName = possUser.getName();
                    if (currentName==null || currentName.length()==0) {
                        possUser.setName(input.optString("userName", ""));
                        userMgr.saveUserProfiles();
                    }
                }
                ar.setPossibleUser(possUser);
            }
            JSONObject repo =null;
            if (meetId!=null && meetId.length()>0) {
                MeetingRecord meet = ngw.findMeeting(meetId);
                AgendaItem ai = meet.findAgendaItem(agendaId);
                boolean canAccessMeet  = AccessControl.canAccessMeeting(ar, ngw, meet);
                if (!canAccessMeet) {
                    ar.assertAccessWorkspace("must have permission to make a reply");
                }
                ai.updateCommentsFromJSON(input, ar);
                repo = ai.getJSON(ar, ngw, meet, true);
                //make sure the meeting cache is refreshed with latest
                MeetingControler.meetingCache.updateCacheFull(ngw, ar, meetId);
            }
            else {
                TopicRecord note = ngw.getNoteOrFail(topicId);
                //normally the permission comes from a license in the URL for anonymous access
                boolean canAccessNote  = AccessControl.canAccessTopic(ar, ngw, note);
                if (!canAccessNote) {
                    ar.assertAccessWorkspace("must have permission to make a reply");
                }
                note.updateCommentsFromJSON(input, ar);
                repo = note.getJSONWithComments(ar, ngw);
                
                //check and see if this person is subscriber, if not add them.
                if (ar.isLoggedIn()) {
                    NGRole subscribers = note.getSubscriberRole();
                    UserProfile user = ar.getUserProfile();
                    if (!subscribers.isExpandedPlayer(user, ngw)) {
                        subscribers.addPlayer(user.getAddressListEntry());
                    }
                }
            }
            ngw.saveFile(ar, "saving comment using SaveReply");
            sendJson(ar, repo);
        }
        catch (Exception ex) {
            Exception ee = new Exception("Unable to update the comment in SaveReply", ex);
            streamException(ee, ar);
        }
    }


    @RequestMapping(value = "/{siteId}/{pageId}/CleanAtt.htm", method = RequestMethod.GET)
    public void cleanAtt(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        ar.reqParam("path");
        BaseController.showJSPMembers(ar, siteId, pageId, "CleanAtt.jsp");
    }
    @RequestMapping(value = "/{siteId}/{pageId}/CleanDebug.htm", method = RequestMethod.GET)
    public void cleanDebug(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        ar.reqParam("path");
        BaseController.showJSPMembers(ar, siteId, pageId, "CleanDebug.jsp");
    }

    /**
     * Both get and update the list of documents attached to either a meeting agenda item,
     * a discussion topic (Note), or a comment  This standard form is easier for the
     * pop up dialog box to use.
     *
     * attachedDocs.json?meet=333&ai=4444
     * attachedDocs.json?note=5555
     * attachedDocs.json?cmt=5342342342
     * attachedDocs.json?goal=6262
     * attachedDocs.json?email=5342342342
     *
     * {
     *   "list": [
     *      "YPNYCMXCH@weaverdesigncirclecl@2779",
     *      "YPEJJSJDH@weaverdesigncirclecl@0031"
     *   ]
     * }
     */
    @RequestMapping(value = "/{siteId}/{pageId}/attachedDocs.json")
    public void attachedDocs(@PathVariable String siteId,
            @PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try {
            NGWorkspace ngw = registerRequiredProject(ar, siteId, pageId);
            List<String> docList = null;

            String meetId = request.getParameter("meet");
            String noteId = request.getParameter("note");
            String cmtId  = request.getParameter("cmt");
            String goalId  = request.getParameter("goal");
            String emailId  = request.getParameter("email");


            if ("POST".equalsIgnoreCase(request.getMethod())) {
                JSONObject posted = this.getPostedObject(ar);
                JSONArray postedList = posted.getJSONArray("list");
                List<String> newDocs = new ArrayList<String>();
                for (int i=0; i<postedList.length(); i++) {
                    String docId = postedList.getString(i);
                    AttachmentRecord aRec = ngw.findAttachmentByUidOrNull(docId);
                    if (aRec!=null) {
                        //check that there really is a document with that id
                        if (!newDocs.contains(aRec.getUniversalId())) {
                            //make sure only unique values get stored once
                            newDocs.add(aRec.getUniversalId());
                        }
                    }
                }
                if (meetId != null) {
                    MeetingRecord mr = ngw.findMeeting(meetId);
                    String agendaId = request.getParameter("ai");
                    AgendaItem ai = mr.findAgendaItem(agendaId);
                    ai.setDocList(newDocs);
                    MeetingControler.meetingCache.updateCacheFull(ngw, ar, meetId);
                    docList = ai.getDocList();
                }
                else if (noteId!=null) {
                    TopicRecord nr = ngw.getNoteOrFail(noteId);
                    nr.setDocList(newDocs);
                    docList = nr.getDocList();
                }
                else if (cmtId!=null) {
                    CommentRecord cr = ngw.getCommentOrFail(DOMFace.safeConvertLong(cmtId));
                    cr.setDocList(newDocs);
                    docList = cr.getDocList();
                }
                else if (goalId!=null) {
                    GoalRecord gr = ngw.getGoalOrFail(goalId);
                    gr.setDocLinks(newDocs);
                    docList = gr.getDocLinks();
                }
                else if (emailId!=null) {
                    EmailGenerator eg = ngw.getEmailGeneratorOrFail(emailId);
                    eg.setAttachments(newDocs);
                    docList = eg.getAttachments();
                }
                else {
                    throw new Exception("attachedDocs.json requires a meet, note, cmt, goal, or email parameter on this POST URL");
                }
                ngw.save();
            }
            else if ("GET".equalsIgnoreCase(request.getMethod())) {
                if (meetId != null) {
                    MeetingRecord mr = ngw.findMeeting(meetId);
                    String agendaId = request.getParameter("ai");
                    AgendaItem ai = mr.findAgendaItem(agendaId);
                    docList = ai.getDocList();
                }
                else if (noteId!=null) {
                    TopicRecord nr = ngw.getNoteOrFail(noteId);
                    docList = nr.getDocList();
                }
                else if (cmtId!=null) {
                    CommentRecord cr = ngw.getCommentOrFail(DOMFace.safeConvertLong(cmtId));
                    docList = cr.getDocList();
                }
                else if (goalId!=null) {
                    GoalRecord gr = ngw.getGoalOrFail(goalId);
                    docList = gr.getDocLinks();
                }
                else if (emailId!=null) {
                    EmailGenerator eg = ngw.getEmailGeneratorOrFail(emailId);
                    docList = eg.getAttachments();
                }
                else {
                    throw new Exception("attachedDocs.json requires a meet, note, cmt, goal, or email parameter on this GET URL");
                }
            }
            else {
                throw new Exception("attachedDocs.json only allows GET or POST");
            }

            JSONObject repo = new JSONObject();
            JSONArray ja = new JSONArray();
            for (String docId : docList) {
                AttachmentRecord aRec = ngw.findAttachmentByUidOrNull(docId);
                if (aRec!=null) {
                    //check that there really is a document with that id
                    ja.put(aRec.getUniversalId());
                }
            }
            repo.put("list", ja);
            sendJson(ar, repo);
        }
        catch (Exception ex) {
            Exception ee = new Exception("Unable to GET/POST attachedDocs.json", ex);
            streamException(ee, ar);
        }
    }

    @RequestMapping(value = "/{siteId}/{pageId}/allActionsList.json", method = RequestMethod.GET)
    public void allActionsList(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try{
            NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail( siteId, pageId ).getWorkspace();
            ar.setPageAccessLevels(ngw);

            JSONArray attachmentList = new JSONArray();
            for (GoalRecord goal : ngw.getAllGoals()) {
                attachmentList.put(goal.getJSON4Goal(ngw));
            }

            JSONObject repo = new JSONObject();
            repo.put("list", attachmentList);
            sendJson(ar, repo);
        }catch(Exception ex){
            Exception ee = new Exception("Unable to get the list of all action items ", ex);
            streamException(ee, ar);
        }
    }


    /**
     * Both get and update the list of action items attached to either a meeting agenda item
     * or a discussion topic (Note).  This standard form is easier for the pop up dialog box to
     * use.
     *
     * attachedActions.json?meet=333&ai=4444
     * attachedActions.json?note=5555
     *
     * {
     *   "list": [
     *      "YPNYCMXCH@weaverdesigncirclecl@2779",
     *      "YPEJJSJDH@weaverdesigncirclecl@0031"
     *   ]
     * }
     */
    @RequestMapping(value = "/{siteId}/{pageId}/attachedActions.json")
    public void attachedActions(@PathVariable String siteId,
            @PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try {
            NGWorkspace ngw = registerRequiredProject(ar, siteId, pageId);
            List<String> actionItemList = null;

            String meetId = request.getParameter("meet");
            String noteId = request.getParameter("note");


            if ("POST".equalsIgnoreCase(request.getMethod())) {
                JSONObject posted = this.getPostedObject(ar);
                JSONArray postedList = posted.getJSONArray("list");
                List<String> newActionItems = new ArrayList<String>();
                for (int i=0; i<postedList.length(); i++) {
                    String actionId = postedList.getString(i);
                    if (!newActionItems.contains(actionId)) {
                        //make sure unique values get stored only once
                        newActionItems.add(actionId);
                    }
                }
                if (meetId != null) {
                    MeetingRecord mr = ngw.findMeeting(meetId);
                    String agendaId = request.getParameter("ai");
                    if (agendaId == null) {
                        throw new Exception("must specify the agenda item with an 'ai' parameter");
                    }
                    AgendaItem ai = mr.findAgendaItem(agendaId);
                    ai.setActionItems(newActionItems);
                    MeetingControler.meetingCache.updateCacheFull(ngw, ar, meetId);
                    actionItemList = ai.getActionItems();
                }
                else if (noteId!=null) {
                    TopicRecord nr = ngw.getNoteOrFail(noteId);
                    nr.setActionList(newActionItems);
                    actionItemList = nr.getActionList();
                }
                else {
                    throw new Exception("attachedActions.json requires a meet or note parameter on this URL");
                }
                ngw.save();
            }
            else if ("GET".equalsIgnoreCase(request.getMethod())) {
                if (meetId != null) {
                    MeetingRecord mr = ngw.findMeeting(meetId);
                    String agendaId = request.getParameter("ai");
                    if (agendaId == null) {
                        throw new Exception("must specify the agenda item with an 'ai' parameter");
                    }
                    AgendaItem ai = mr.findAgendaItem(agendaId);
                    actionItemList = ai.getActionItems();
                }
                else if (noteId!=null) {
                    TopicRecord nr = ngw.getNoteOrFail(noteId);
                    actionItemList = nr.getActionList();
                }
                else {
                    throw new Exception("attachedActions.json requires a meet or note parameter on this URL");
                }
            }
            else {
                throw new Exception("attachedActions.json only allows GET or POST");
            }

            JSONObject repo = new JSONObject();
            JSONArray ja = new JSONArray();
            for (String docId : actionItemList) {
                ja.put(docId);
            }
            repo.put("list", ja);
            sendJson(ar, repo);
        }
        catch (Exception ex) {
            Exception ee = new Exception("Unable to GET/POST attachedActions.json", ex);
            streamException(ee, ar);
        }
    }
    
    
    @RequestMapping(value = "/{siteId}/{pageId}/GetScratchpad.json", method = RequestMethod.GET)
    public void getScratchpad(@PathVariable String siteId,
            @PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try{
            ar.assertLoggedIn("ScratchPad is available only when logged in.");
            Cognoscenti cog = ar.getCogInstance();
            String key = ar.getUserProfile().getKey();
            UserCache uc = cog.getUserCacheMgr().getCache(key);

            JSONObject repo = new JSONObject();
            repo.put("scratchpad", uc.getScratchPad());
            sendJson(ar, repo);
        }catch(Exception ex){
            Exception ee = new Exception("Unable to get email", ex);
            streamException(ee, ar);
        }
    }
    @RequestMapping(value = "/{siteId}/{pageId}/UpdateScratchpad.json", method = RequestMethod.POST)
    public void updateScratchpad(@PathVariable String siteId,
            @PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try{
            ar.assertLoggedIn("ScratchPad is available only when logged in.");
            Cognoscenti cog = ar.getCogInstance();
            String key = ar.getUserProfile().getKey();
            UserCache uc = cog.getUserCacheMgr().getCache(key);

            JSONObject posted = getPostedObject(ar);
            uc.updateScratchPad(posted);
            uc.save();
            
            JSONObject repo = new JSONObject();
            repo.put("scratchpad", uc.getScratchPad());
            sendJson(ar, repo);
        }catch(Exception ex){
            Exception ee = new Exception("Unable to get email", ex);
            streamException(ee, ar);
        }
    }
    
    
    
    
    
    
    
    
    
    
    
    ///////////////////// DEPRECATED ////////////////////////////
    
    //This is the OLD pattern we want to get rid of with aid embedded in the page name
    //instead use DocDetails.htm?aid={aid}
    @Deprecated
    @RequestMapping(value = "/{siteId}/{pageId}/docinfo{aid}.htm", method = RequestMethod.GET)
    private void docInfoView(@PathVariable String siteId,
             @PathVariable String pageId, @PathVariable String aid,
             HttpServletRequest request,  HttpServletResponse response) throws Exception {
        System.out.println("Deprecated address docinfo{aid}.htm is still being used, please replace with DocDetail.htm");
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        request.setAttribute("aid", aid);
        NGWorkspace ngw = registerRequiredProject(ar, siteId, pageId);
        AttachmentRecord att = ngw.findAttachmentByID(aid);
        boolean specialAccess = AccessControl.canAccessDoc(ar, ngw, att);
        BaseController.showJSPDepending(ar, ngw, "DocDetail.jsp", specialAccess);
    }

    
}
