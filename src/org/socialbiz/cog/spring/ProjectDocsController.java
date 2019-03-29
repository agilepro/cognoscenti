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

import java.io.InputStream;
import java.net.URLEncoder;
import java.util.ArrayList;
import java.util.List;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.socialbiz.cog.AccessControl;
import org.socialbiz.cog.AgendaItem;
import org.socialbiz.cog.AttachmentRecord;
import org.socialbiz.cog.AttachmentVersion;
import org.socialbiz.cog.AuthRequest;
import org.socialbiz.cog.CommentRecord;
import org.socialbiz.cog.DOMFace;
import org.socialbiz.cog.GoalRecord;
import org.socialbiz.cog.HistoryRecord;
import org.socialbiz.cog.MeetingRecord;
import org.socialbiz.cog.MimeTypes;
import org.socialbiz.cog.NGPage;
import org.socialbiz.cog.NGPageIndex;
import org.socialbiz.cog.NGWorkspace;
import org.socialbiz.cog.SectionAttachments;
import org.socialbiz.cog.SharePortRecord;
import org.socialbiz.cog.TopicRecord;
import org.socialbiz.cog.UserProfile;
import org.socialbiz.cog.WikiToPDF;
import org.socialbiz.cog.dms.FolderAccessHelper;
import org.socialbiz.cog.exception.NGException;
import org.socialbiz.cog.util.PDFUtil;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;

import com.purplehillsbooks.json.JSONArray;
import com.purplehillsbooks.json.JSONObject;

@Controller
public class ProjectDocsController extends BaseController {


    @RequestMapping(value = "/{siteId}/{pageId}/listAttachments.htm", method = RequestMethod.GET)
    public void listAttachments(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        BaseController.showJSPMembers(ar, siteId, pageId, "ListAttachments");
    }


    @RequestMapping(value = "/{siteId}/{pageId}/docsFolder.htm", method = RequestMethod.GET)
    public void docsFolder(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        BaseController.showJSPMembers(ar, siteId, pageId, "DocsFolder");
    }

    @RequestMapping(value = "/{siteId}/{pageId}/docsDeleted.htm", method = RequestMethod.GET)
    public void showDeletedAttachments(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        BaseController.showJSPMembers(ar, siteId, pageId, "DocsDeleted");
    }

    @RequestMapping(value = "/{siteId}/{pageId}/docsUpload.htm", method = RequestMethod.GET)
    protected void docsUpload(@PathVariable String siteId,
            @PathVariable String pageId, HttpServletRequest request,
            HttpServletResponse response) throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        BaseController.showJSPMembers(ar, siteId, pageId, "DocsUpload");
    }

    /**
     * Let the user decide how to add a document to the project
     */
    @RequestMapping(value = "/{siteId}/{pageId}/docsAdd.htm", method = RequestMethod.GET)
    protected void docsAdd(@PathVariable String siteId,
            @PathVariable String pageId, HttpServletRequest request,
            HttpServletResponse response) throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        BaseController.showJSPNotFrozen(ar, siteId, pageId, "DocsAdd");
    }

    @RequestMapping(value = "/{siteId}/{pageId}/docinfo{aid}.htm", method = RequestMethod.GET)
    protected void docInfoView(@PathVariable String siteId,
             @PathVariable String pageId, @PathVariable String aid,
             HttpServletRequest request,  HttpServletResponse response) throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        //ngp.findAttachmentByIDOrFail(aid);
        request.setAttribute("aid", aid);
        BaseController.showJSPAnonymous(ar, siteId, pageId, "docinfo");
    }

    @RequestMapping(value = "/{siteId}/{pageId}/editDetails{aid}.htm", method = RequestMethod.GET)
    protected void editDetails(@PathVariable String siteId,
             @PathVariable String pageId, @PathVariable String aid,
             HttpServletRequest request,  HttpServletResponse response) throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);

        //special behavior.  On the Edit Details page, if someone hits this when NOT LOGGED IN
        //then redirect to the document information page, which is allowed when not logged in,
        //and from there they can decide whether to log in or not, and then to edit the details.
        //Seems better than just saying you are not logged in.
        if (!ar.isLoggedIn()) {
            ar.resp.sendRedirect("docinfo"+URLEncoder.encode(aid, "UTF-8")+".htm");
            return;
        }

        request.setAttribute("aid", aid);
        BaseController.showJSPAnonymous(ar, siteId, pageId, "editDetails");
    }

    @RequestMapping(value = "/{siteId}/{pageId}/fileVersions.htm", method = RequestMethod.GET)
    protected void fileVersions(@PathVariable String siteId,
             @PathVariable String pageId,
             HttpServletRequest request,  HttpServletResponse response) throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);

        //special behavior.  On the list versions page, if someone hits this when NOT LOGGED IN
        //then redirect to the document information page, which is allowed when not logged in,
        //and from there they can decide whether to log in or not, and then to list the versions.
        //Seems better than just saying you are not logged in.
        if (!ar.isLoggedIn()) {
            ar.resp.sendRedirect("docinfo"+URLEncoder.encode(ar.reqParam("aid"), "UTF-8")+".htm");
            return;
        }

        request.setAttribute("aid", ar.reqParam("aid"));
        BaseController.showJSPAnonymous(ar, siteId, pageId, "fileVersions");
    }

    @RequestMapping(value = "/{siteId}/{pageId}/docsRevise.htm", method = RequestMethod.GET)
    protected void docsRevise(@PathVariable String siteId,
             @PathVariable String pageId,
             HttpServletRequest request,  HttpServletResponse response) throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);

        //special behavior.  On the Upload New Version page, if someone hits this when NOT LOGGED IN
        //then redirect to the document information page, which is allowed when not logged in,
        //and from there they can decide whether to log in or not, and then to add a new version.
        //Seems better than just saying you are not logged in.
        if (!ar.isLoggedIn()) {
            ar.resp.sendRedirect("docinfo"+URLEncoder.encode(ar.reqParam("aid"), "UTF-8")+".htm");
            return;
        }

        //ngp.findAttachmentByIDOrFail(aid);
        request.setAttribute("aid", ar.reqParam("aid"));
        BaseController.showJSPAnonymous(ar, siteId, pageId, "DocsRevise");
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

    @RequestMapping(value="/{siteId}/{pageId}/f/{docId}.{ext}", method = RequestMethod.GET)
    public void loadRemoteDocument(
            @PathVariable String siteId,
            @PathVariable String pageId,
            @PathVariable String docId,
            @PathVariable String ext,
            HttpServletRequest request,
            HttpServletResponse response) throws Exception {
        try{
            AuthRequest ar  = AuthRequest.getOrCreate(request, response);

            ar.getCogInstance().getSiteByIdOrFail(siteId);
            ar.getCogInstance().getWSBySiteAndKeyOrFail( siteId, pageId );

            String symbol = ar.reqParam("fid");

            FolderAccessHelper fah = new FolderAccessHelper(ar);
            fah.serveUpRemoteFile(symbol);
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.project.download.document", new Object[]{pageId,siteId} , ex);
        }
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
            NGPage ngp = registerRequiredProject(ar, siteId, pageId);

            //this constructs and outputs the PDF file to the output stream
            WikiToPDF.handlePDFRequest(ar, ngp);

        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.project.download.document", new Object[]{pageId,siteId} , ex);
        }
    }

    @RequestMapping(value="/{siteId}/{pageId}/pdf1/{docId}.{ext}", method = RequestMethod.POST)
    public void generatePDFDocument(
            @PathVariable String siteId,
            @PathVariable String pageId,
            @PathVariable String docId,
            @PathVariable String ext,
            HttpServletRequest request,
            HttpServletResponse response) throws Exception {

        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            registerRequiredProject(ar, siteId, pageId);

            PDFUtil pdfUtil = new PDFUtil();
            pdfUtil.serveUpFile(ar, siteId, pageId);
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
            showJSPMembers(ar, siteId, pageId, "reminders");
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.project.reminder.page", new Object[]{pageId,siteId} , ex);
        }
    }



    @RequestMapping(value = "/{siteId}/{pageId}/SyncAttachment.htm", method = RequestMethod.GET)
    protected void syncAttachment(@PathVariable String siteId,
            @PathVariable String pageId, HttpServletRequest request,
            HttpServletResponse response) throws Exception {
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            registerRequiredProject(ar, siteId, pageId);
            showJSPMembers(ar, siteId, pageId, "SyncAttachment");
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.project.sync.share.point.attachment.page",
                    new Object[]{pageId,siteId} , ex);
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
            ar.assertMember("Must be a member to update a document information.");
            ar.assertNotFrozen(ngw);
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
    public void docsList(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try{
            NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail( siteId, pageId ).getWorkspace();
            ar.setPageAccessLevels(ngw);
            boolean isMember = ar.isMember();

            JSONArray attachmentList = new JSONArray();
            for (AttachmentRecord doc : ngw.getAllAttachments()) {
                if (!isMember && !doc.isPublic()) {
                    //skip non public documents if not a member
                    continue;
                }
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


    @RequestMapping(value = "/{siteId}/{pageId}/sharePorts.htm", method = RequestMethod.GET)
    public void sharePorts(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        BaseController.showJSPMembers(ar, siteId, pageId, "SharePorts");
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
                spr = ngw.createSharePort();
                id = spr.getPermId();
                needSave = true;
            }
            else {
                spr = ngw.findSharePortOrFail(id);
            }
            if ("POST".equalsIgnoreCase(request.getMethod())) {
                JSONObject postBody = this.getPostedObject(ar);
                spr.updateFromJSON(postBody);
                needSave = true;
            }
            if (needSave) {
                ngw.saveContent(ar, "updating the share ports");
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
        specialAnonJSP(ar, siteId, pageId, "Share.jsp");
    }

    @RequestMapping(value = "/{siteId}/{pageId}/reply/{topicId}/{commentId}.htm", method = RequestMethod.GET)
    public void specialReply(@PathVariable String siteId,
            @PathVariable String pageId,
            @PathVariable String topicId,
            @PathVariable String commentId,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        NGPage ngp = registerRequiredProject(ar, siteId, pageId);
        
        int hyphenPos = topicId.indexOf("-");
        if (hyphenPos>0) {
            String meetingId = topicId.substring(0,hyphenPos);
            String agendaId = topicId.substring(hyphenPos+1);
            MeetingRecord meet = ngp.findMeeting(meetingId);
            AgendaItem ai = meet.findAgendaItem(agendaId);
            boolean canAccessMeet  = AccessControl.canAccessMeeting(ar, ngp, meet);
            if (!canAccessMeet) {
                ar.assertMember("must have permission to make a reply");
            }
        }
        else {
            TopicRecord note = ngp.getNoteOrFail(topicId);
            //normally the permission comes from a license in the URL for anonymous access
            boolean canAccessNote  = AccessControl.canAccessTopic(ar, ngp, note);
            if (!canAccessNote) {
                ar.assertMember("must have permission to make a reply");
            }
        }
        ar.setParam("topicId", topicId);
        ar.setParam("commentId", commentId);
        specialAnonJSP(ar, siteId, pageId, "Reply.jsp");
    }

    @RequestMapping(value = "/{siteId}/{pageId}/unsub/{topicId}/{commentId}.htm", method = RequestMethod.GET)
    public void specialUnsub(@PathVariable String siteId,
            @PathVariable String pageId,
            @PathVariable String topicId,
            @PathVariable String commentId,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        NGPage ngp = registerRequiredProject(ar, siteId, pageId);
        ngp.getNoteOrFail(topicId);
        //normally the permission comes from a license in the URL for anonymous access
        //boolean canAccessNote  = AccessControl.canAccessTopic(ar, ngp, note);
        //if (!canAccessNote) {
        //    ar.assertMember("must have permission to make a reply");
        //}
        ar.setParam("topicId", topicId);
        ar.setParam("commentId", commentId);
        specialAnonJSP(ar, siteId, pageId, "Unsub.jsp");
    }

    @RequestMapping(value = "/su/Feedback.htm", method = RequestMethod.GET)
    public void Feedback(HttpServletRequest request, HttpServletResponse response) throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        specialAnonJSP(ar, "NA", "NA", "Feedback.jsp");
    }

    @RequestMapping(value = "/{siteId}/{pageId}/reply/{topicId}/{commentId}.json", method = RequestMethod.POST)
    public void specialReplySave(@PathVariable String siteId,
            @PathVariable String pageId,
            @PathVariable String topicId,
            @PathVariable String commentId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try {
            NGWorkspace ngw = registerRequiredProject(ar, siteId, pageId);
            JSONObject input = getPostedObject(ar);
            if (!input.has("comments")) {
                throw new Exception("posted object to specialReplySave needs to have a comments list");
            }
            int hyphenPos = topicId.indexOf("-");
            JSONObject repo =null;
            if (hyphenPos>0) {
                String meetingId = topicId.substring(0,hyphenPos);
                String agendaId = topicId.substring(hyphenPos+1);
                MeetingRecord meet = ngw.findMeeting(meetingId);
                AgendaItem ai = meet.findAgendaItem(agendaId);
                boolean canAccessMeet  = AccessControl.canAccessMeeting(ar, ngw, meet);
                if (!canAccessMeet) {
                    ar.assertMember("must have permission to make a reply");
                }
                ai.updateCommentsFromJSON(input, ar);
                repo = ai.getJSON(ar, ngw, meet);
            }
            else {
                TopicRecord note = ngw.getNoteOrFail(topicId);
                //normally the permission comes from a license in the URL for anonymous access
                boolean canAccessNote  = AccessControl.canAccessTopic(ar, ngw, note);
                if (!canAccessNote) {
                    ar.assertMember("must have permission to make a reply");
                }
                note.updateCommentsFromJSON(input, ar);
                repo = note.getJSONWithComments(ar, ngw);
            }
            //String emailId = ar.reqParam("emailId");
            UserProfile up = ar.getUserProfile();
            if (up==null) {
                throw new Exception("something wrong, user profile is null");
            }
            
            ngw.saveFile(ar, "saving comment using special reply");

            repo.write(ar.w, 2, 2);
            ar.flush();
        }
        catch (Exception ex) {
            Exception ee = new Exception("Unable to update the comment in specialReplySave", ex);
            streamException(ee, ar);
        }
    }


    @RequestMapping(value = "/{siteId}/{pageId}/CleanAtt.htm", method = RequestMethod.GET)
    public void cleanAtt(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        ar.reqParam("path");
        BaseController.showJSPMembers(ar, siteId, pageId, "CleanAtt");
    }
    @RequestMapping(value = "/{siteId}/{pageId}/CleanDebug.htm", method = RequestMethod.GET)
    public void cleanDebug(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        ar.reqParam("path");
        BaseController.showJSPMembers(ar, siteId, pageId, "CleanDebug");
    }

    /**
     * Both get and update the list of documents attached to either a meeting agenda item,
     * a discussion topic (Note), or a comment  This standard form is easier for the
     * pop up dialog box to use.
     *
     * attachedDocs.json?meet=333&ai=4444
     * attachedDocs.json?note=5555
     * attachedDocs.json?cmt=5342342342
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


            if ("POST".equalsIgnoreCase(request.getMethod())) {
                JSONObject posted = this.getPostedObject(ar);
                JSONArray postedList = posted.getJSONArray("list");
                List<String> newDocs = new ArrayList<String>();
                for (int i=0; i<postedList.length(); i++) {
                    String docId = postedList.getString(i);
                    if (!newDocs.contains(docId)) {
                        //make sure only unique values get stored once
                        newDocs.add(docId);
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
                else {
                    throw new Exception("attachedDocs.json requires a meet or note parameter on this URL");
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
                else {
                    throw new Exception("attachedDocs.json requires a meet or note parameter on this URL");
                }
            }
            else {
                throw new Exception("attachedDocs.json only allows GET or POST");
            }

            JSONObject repo = new JSONObject();
            JSONArray ja = new JSONArray();
            for (String docId : docList) {
                ja.put(docId);
            }
            repo.put("list", ja);
            repo.write(ar.w, 2, 2);
            ar.flush();
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
            repo.write(ar.w, 2, 2);
            ar.flush();
        }
        catch (Exception ex) {
            Exception ee = new Exception("Unable to GET/POST attachedActions.json", ex);
            streamException(ee, ar);
        }
    }
}
