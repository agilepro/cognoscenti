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
import java.io.InputStream;
import java.net.URLEncoder;
import java.util.ArrayList;
import java.util.List;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import com.purplehillsbooks.weaver.AccessControl;
import com.purplehillsbooks.weaver.AgendaItem;
import com.purplehillsbooks.weaver.AttachmentRecord;
import com.purplehillsbooks.weaver.AttachmentVersion;
import com.purplehillsbooks.weaver.AuthRequest;
import com.purplehillsbooks.weaver.Cognoscenti;
import com.purplehillsbooks.weaver.CommentContainer;
import com.purplehillsbooks.weaver.CommentRecord;
import com.purplehillsbooks.weaver.DOMFace;
import com.purplehillsbooks.weaver.GoalRecord;
import com.purplehillsbooks.weaver.HistoryRecord;
import com.purplehillsbooks.weaver.IdGenerator;
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
import com.purplehillsbooks.weaver.capture.WebFile;
import com.purplehillsbooks.weaver.exception.WeaverException;
import com.purplehillsbooks.weaver.mail.EmailGenerator;
import com.purplehillsbooks.weaver.mail.EmailSender;
import com.purplehillsbooks.weaver.mail.MailInst;
import com.purplehillsbooks.weaver.util.MimeTypes;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;

import com.purplehillsbooks.json.JSONArray;
import com.purplehillsbooks.json.JSONObject;
import com.purplehillsbooks.streams.StreamHelper;

@Controller
public class ProjectDocsController extends BaseController {

    @RequestMapping(value = "/{siteId}/{pageId}/DocsList.htm", method = RequestMethod.GET)
    public void docsList(@PathVariable String siteId, @PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        BaseController.showJSPMembers(ar, siteId, pageId, "DocsList.jsp");
    }

    @RequestMapping(value = "/{siteId}/{pageId}/DocsFolder.htm", method = RequestMethod.GET)
    public void docsFolder(@PathVariable String siteId, @PathVariable String pageId,
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
        BaseController.showJSPMembers(ar, siteId, pageId, "DocsAdd.jsp");
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

    /**
     * This is a view that prompts the user to specify how they want the PDF to be
     * produced.
     */
    @RequestMapping(value = "/{siteId}/{pageId}/PDFExport.htm", method = RequestMethod.GET)
    public void pdfExport(HttpServletRequest request, HttpServletResponse response,
            @PathVariable String pageId, @PathVariable String siteId) throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        showJSPMembers(ar, siteId, pageId, "PDFExport.jsp");
    }

    // this will be DocDetail.htm??aid={aid}&lic={license}
    @RequestMapping(value = "/{siteId}/{pageId}/DocDetail.htm", method = RequestMethod.GET)
    protected void docDetail(@PathVariable String siteId,
            @PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        String aid = ar.reqParam("aid");

        request.setAttribute("aid", aid);
        NGWorkspace ngw = registerWorkspaceRequired(ar, siteId, pageId);
        AttachmentRecord att = ngw.findAttachmentByIDOrFail(aid);
        boolean specialAccess = AccessControl.canAccessDoc(ar, ngw, att);
        BaseController.showJSPDepending(ar, ngw, "DocDetail.jsp", specialAccess);
    }

    @RequestMapping(value = "/{siteId}/{pageId}/DocsVersions.htm", method = RequestMethod.GET)
    protected void docsVersions(@PathVariable String siteId,
            @PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);

        // special behavior. On the list versions page, if someone hits this when NOT
        // LOGGED IN
        // then redirect to the document information page, which is allowed when not
        // logged in,
        // and from there they can decide whether to log in or not, and then to list the
        // versions.
        // Seems better than just saying you are not logged in.
        if (!ar.isLoggedIn()) {
            ar.resp.sendRedirect("DocDetail.htm?aid=" + URLEncoder.encode(ar.reqParam("aid"), "UTF-8"));
            return;
        }

        request.setAttribute("aid", ar.reqParam("aid"));
        BaseController.showJSPAnonymous(ar, siteId, pageId, "DocsVersions.jsp");
    }

    @RequestMapping(value = "/{siteId}/{pageId}/DocsRevise.htm", method = RequestMethod.GET)
    protected void docsRevise(@PathVariable String siteId,
            @PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);

        // special behavior. On the Upload New Version page, if someone hits this when
        // NOT LOGGED IN then redirect to the document information page, which is allowed 
        // when not logged in, and from there they can decide whether to log in or not, 
        // and then to add a new version.
        // Seems better than just saying you are not logged in.
        if (!ar.isLoggedIn()) {
            ar.resp.sendRedirect("DocDetail.htm?aid=" + URLEncoder.encode(ar.reqParam("aid"), "UTF-8"));
            return;
        }

        // ngp.findAttachmentByIDOrFail(aid);
        request.setAttribute("aid", ar.reqParam("aid"));
        BaseController.showJSPAnonymous(ar, siteId, pageId, "DocsRevise.jsp");
    }

    @RequestMapping(value = "/{siteId}/{pageId}/a/{docName}.{ext}", method = RequestMethod.GET)
    public void loadDocument(
            @PathVariable String siteId,
            @PathVariable String pageId,
            @PathVariable String docName,
            @PathVariable String ext,
            HttpServletRequest request,
            HttpServletResponse response) throws Exception {
        try {
            NGPageIndex.assertNoLocksOnThread();
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            NGWorkspace ngw = registerWorkspaceRequired(ar, siteId, pageId);

            String attachmentName = docName + "." + ext;
            AttachmentRecord att = ngw.findAttachmentByNameOrFail(attachmentName);

            boolean canAccessDoc = AccessControl.canAccessDoc(ar, ngw, att);

            if (!canAccessDoc) {
                sendRedirectToLogin(ar);
                return;
            }

            int version = DOMFace.safeConvertInt(ar.defParam("version", null));

            // get the mime type from the file extension
            String mimeType = MimeTypes.getMimeType(attachmentName);
            ar.resp.setContentType(mimeType);
            // set expiration to about 1 year from now
            ar.resp.setDateHeader("Expires", ar.nowTime + 31000000000L);

            // Temporary fix: To force the browser to show 'SaveAs' dialogbox with right
            // format.
            // Note this originally had some code that assumed that old versions of a file
            // might have a different extension. I don't see how this can happen.
            // The attachment has a name, and that name holds for all versions. If you
            // change the name, it changes all the versions. I don't see how old
            // versions might have a different extension.... Removed complicated logic.
            ar.resp.setHeader("Content-Disposition", "attachment; filename=\"" + attachmentName + "\"");

            AttachmentVersion attachmentVersion = SectionAttachments.getVersionOrLatest(ngw, attachmentName, version);
            ar.resp.setHeader("Content-Length", Long.toString(attachmentVersion.getFileSize()));

            att.createHistory(ar, ngw, HistoryRecord.EVENT_DOC_DOWNLOADED, "Downloaded document " + attachmentName);

            InputStream fis = attachmentVersion.getInputStream();

            // NOTE: now that we have the input stream, we can let go of the project. This
            // is important
            // to prevent holding the lock for the entire time that it takes for the client
            // to download
            // the file. Remember, slow clients might take minutes to download a large file.
            ngw.save();
            NGPageIndex.releaseLock(ngw);
            ngw = null;

            ar.streamBytesOut(fis);
            fis.close();
        } catch (Exception ex) {
            // why sleep? Here, this is VERY IMPORTANT
            // Someone might be trying all the possible file names just to
            // see what is here. A three second sleep makes that more difficult.
            Thread.sleep(3000);
            throw WeaverException.newWrap(
                    "Failed to perform operation while downloading document of workspace %s in site %s.", ex, pageId,
                    siteId);
        }
    }

    /**
     * note that the docid in the path is not needed, but it will be different for
     * every file for convenience of auto-generating a file name to save to.
     *
     * following the name is a bunch of query paramters listing the topics to
     * include in the output.
     */
    @RequestMapping(value = "/{siteId}/{pageId}/pdf/{docId}.pdf", method = RequestMethod.GET)
    public void generatePDFDocument(
            @PathVariable String siteId,
            @PathVariable String pageId,
            @PathVariable String docId,
            HttpServletRequest request,
            HttpServletResponse response) throws Exception {

        try {
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            ar.getCogInstance().getSiteByIdOrFail(siteId);
            NGWorkspace ngw = registerWorkspaceRequired(ar, siteId, pageId);

            // this constructs and outputs the PDF file to the output stream
            WikiToPDF.handlePDFRequest(ar, ngw);

        } catch (Exception ex) {
            throw WeaverException.newWrap(
                    "Failed to perform operation while downloading document of workspace %s in site %s.", ex, pageId,
                    siteId);
        }
    }

    @RequestMapping(value = "/{siteId}/{pageId}/docInfo.json", method = RequestMethod.GET)
    public void docInfo(@PathVariable String siteId, @PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        String did = "";
        try {
            did = ar.reqParam("did");
            NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
            ar.setPageAccessLevels(ngw);
            AttachmentRecord attachment = ngw.findAttachmentByIDOrFail(did);
            boolean canAccessDoc = AccessControl.canAccessDoc(ar, ngw, attachment);
            if (!canAccessDoc) {
                throw WeaverException.newBasic("Unable for user %s to access document %s", did, ar.getBestUserId());
            }

            JSONObject repo = attachment.getJSON4Doc(ar, ngw);
            sendJson(ar, repo);
        } catch (Exception ex) {
            Exception ee = WeaverException.newWrap("Failure accessing document " + did, ex);
            streamException(ee, ar);
        }
    }

    @RequestMapping(value = "/{siteId}/{pageId}/docsUpdate.json", method = RequestMethod.POST)
    public void docsUpdate(@PathVariable String siteId, @PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        String did = "";
        try {
            did = ar.reqParam("did");
            NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
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
            } else {
                aDoc = ngw.findAttachmentByIDOrFail(did);
                historyEventType = HistoryRecord.EVENT_DOC_UPDATED;
            }

            // everything else updated here
            aDoc.updateDocFromJSON(docInfo, ar);

            HistoryRecord.createHistoryRecord(ngw, aDoc.getId(), HistoryRecord.CONTEXT_TYPE_DOCUMENT,
                    ar.nowTime, historyEventType, ar, "");

            ngw.saveFile(ar, "Updated Agenda Item");
            JSONObject repo = aDoc.getJSON4Doc(ar, ngw);
            sendJson(ar, repo);
        } catch (Exception ex) {
            Exception ee = WeaverException.newWrap("Unable to update document $s", ex, did);
            streamException(ee, ar);
        }
    }

    @RequestMapping(value = "/{siteId}/{pageId}/docsList.json", method = RequestMethod.GET)
    public void docsListJSON(@PathVariable String siteId, @PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try {
            NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
            ar.setPageAccessLevels(ngw);
            String meetId = ar.defParam("meet", null);
            if (meetId != null) {
                MeetingRecord meet = ngw.findMeeting(meetId);
                boolean canAccess = AccessControl.canAccessMeeting(ar, ngw, meet);
                if (!canAccess) {
                    ar.assertAccessWorkspace("User is not a member of meeting.");
                }
            } else {
                ar.assertAccessWorkspace("Must have access to a workspace to get the document list.");
            }

            JSONArray attachmentList = new JSONArray();
            for (AttachmentRecord doc : ngw.getAllAttachments()) {
                attachmentList.put(doc.getJSON4Doc(ar, ngw));
            }

            JSONObject repo = new JSONObject();
            repo.put("docs", attachmentList);
            sendJson(ar, repo);
        } catch (Exception ex) {
            Exception ee = WeaverException.newWrap("Unable to get the list of attachments ", ex);
            streamException(ee, ar);
        }
    }

    @RequestMapping(value = "/{siteId}/{pageId}/copyDocument.json", method = RequestMethod.POST)
    public void copyAttachment(@PathVariable String siteId, @PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) {
        copyMoveDocument(siteId, pageId, false, request, response);
    }

    @RequestMapping(value = "/{siteId}/{pageId}/moveDocument.json", method = RequestMethod.POST)
    public void moveDocument(@PathVariable String siteId, @PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) {
        copyMoveDocument(siteId, pageId, true, request, response);
    }

    public void copyMoveDocument(String siteId, String pageId, boolean deleteOld,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try {
            JSONObject postBody = this.getPostedObject(ar);
            String fromCombo = postBody.getString("from");
            String docId = postBody.getString("id");

            Cognoscenti cog = ar.getCogInstance();
            NGWorkspace thisWS = cog.getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
            NGWorkspace fromWS = cog.getWSByCombinedKeyOrFail(fromCombo).getWorkspace();

            ar.setPageAccessLevels(thisWS);
            ar.assertNotFrozen(thisWS);
            ar.assertUpdateWorkspace("You must be able to update the workspace you are copying to");
            ar.assertNotReadOnly("Cannot copy a document");
            ar.setPageAccessLevels(fromWS);
            ar.assertAccessWorkspace("You must be able to access the workspace you are copying from");

            AttachmentRecord oldDoc = fromWS.findAttachmentByID(docId);
            if (oldDoc == null) {
                throw WeaverException.newBasic("Unable to find a document with id=%s", docId);
            }

            String docName = oldDoc.getDisplayName();
            AttachmentRecord newCopy = thisWS.findAttachmentByName(docName);
            if (newCopy == null) {
                newCopy = thisWS.createAttachment();
                newCopy.setDisplayName(docName);
            } else {
                if (newCopy.isDeleted()) {
                    newCopy.clearDeleted();
                }
            }
            newCopy.setDescription(oldDoc.getDescription());
            newCopy.setUniversalId(oldDoc.getUniversalId());
            String docType = oldDoc.getType();
            newCopy.setType(docType);

            if (oldDoc.isFile()) {
                AttachmentVersion av = oldDoc.getLatestVersion(fromWS);
                InputStream is = av.getInputStream();
                newCopy.streamNewVersion(ar, thisWS, is);
                is.close();
            } else if (oldDoc.isURL()) {
                newCopy.setURLValue(oldDoc.getURLValue());
            } else {
                throw WeaverException.newBasic("Don't understand how to move document '%s' type %s ", docName,
                        oldDoc.getType());
            }

            if (deleteOld) {
                oldDoc.setDeleted(ar);
                fromWS.saveFile(ar, "Document '" + docName + "' transferred to workspace: " + thisWS.getFullName());
            }

            JSONObject repo = new JSONObject();
            repo.put("created", newCopy.getJSON4Doc(ar, thisWS));

            thisWS.saveFile(ar, "Document '" + docName + "' copied from workspace: " + fromWS.getFullName());

            sendJson(ar, repo);
        } catch (Exception ex) {
            Exception ee = WeaverException.newWrap("Unable to copy/move the document", ex);
            streamException(ee, ar);
        }
    }

    @RequestMapping(value = "/{siteId}/{pageId}/SharePorts.htm", method = RequestMethod.GET)
    public void sharePorts(@PathVariable String siteId, @PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        BaseController.showJSPMembers(ar, siteId, pageId, "SharePorts.jsp");
    }

    @RequestMapping(value = "/{siteId}/{pageId}/sharePorts.json", method = RequestMethod.GET)
    public void sharePortsJSON(@PathVariable String siteId, @PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try {
            NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
            JSONObject repo = new JSONObject();
            JSONArray shareList = new JSONArray();
            for (SharePortRecord spr : ngw.getSharePorts()) {
                shareList.put(spr.getMinJSON());
            }
            repo.put("shares", shareList);
            sendJson(ar, repo);
        } catch (Exception ex) {
            Exception ee = WeaverException.newWrap("Unable to get the list of share ports ", ex);
            streamException(ee, ar);
        }
    }

    @RequestMapping(value = "/{siteId}/{pageId}/share/{id}.json")
    public void onePortJSON(@PathVariable String siteId,
            @PathVariable String pageId,
            @PathVariable String id,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try {
            NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
            SharePortRecord spr = null;
            boolean needSave = false;
            if ("~new~".equals(id)) {
                ar.assertNotFrozen(ngw);
                spr = ngw.createSharePort();
                id = spr.getPermId();
                needSave = true;
            } else {
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
        } catch (Exception ex) {
            Exception ee = WeaverException.newWrap("Unable to get the list of share ports ", ex);
            streamException(ee, ar);
        }
    }

    @RequestMapping(value = "/{siteId}/{pageId}/share/{id}.htm", method = RequestMethod.GET)
    public void specialShare(@PathVariable String siteId,
            @PathVariable String pageId,
            @PathVariable String id,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        NGWorkspace ngw = registerWorkspaceRequired(ar, siteId, pageId);
        SharePortRecord spr = ngw.findSharePortOrNull(id);
        if (spr == null) {
            showDisplayWarning(ar, "Unable to find a Share Port Side with the id: "
                    + id + ".  Maybe it was deleted, or maybe the link was damaged?");
            return;
        }

        ar.setParam("id", id);
        ar.setParam("pageId", pageId);
        ar.setParam("siteId", siteId);
        streamJSPAnon(ar, "Share.jsp");
    }

    // this is the old pattern, harder to accommodate in the ring scheme, so change
    // to a
    // new one which is more the regular pattern. This needed in case there are
    // old emails around with the old pattern.
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
        if (hyphenPos > 0) {
            meetId = topicId.substring(0, hyphenPos);
            agendaId = topicId.substring(hyphenPos + 1);
            topicId = null;
        }
        String responseUrl = "../../Reply.htm?commentId=" + URLEncoder.encode(commentId, "UTF-8");
        if (topicId != null) {
            responseUrl += "&topicId=" + URLEncoder.encode(topicId, "UTF-8");
        }
        if (meetId != null) {
            responseUrl += "&meetId=" + URLEncoder.encode(meetId, "UTF-8");
        }
        if (agendaId != null) {
            responseUrl += "&agendaId=" + URLEncoder.encode(agendaId, "UTF-8");
        }
        String emailId = ar.defParam("emailId", null);
        if (emailId != null) {
            responseUrl += "&emailId=" + URLEncoder.encode(emailId, "UTF-8");
        }
        String mnnote = ar.defParam("mnnote", null);
        if (mnnote != null) {
            responseUrl += "&mnnote=" + URLEncoder.encode(mnnote, "UTF-8");
        }
        String mnm = ar.defParam("mnm", null);
        if (mnm != null) {
            responseUrl += "&mnm=" + URLEncoder.encode(mnm, "UTF-8");
        }

        ar.resp.sendRedirect(responseUrl);
    }

    @RequestMapping(value = "/{siteId}/{pageId}/Reply.htm", method = RequestMethod.GET)
    public void specialReply(@PathVariable String siteId,
            @PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        NGWorkspace ngw = registerWorkspaceRequired(ar, siteId, pageId);

        String msgLocator = ar.reqParam("msg");
        System.out.println("Reply.htm - got message locator=" + msgLocator);

        long msgId = MailInst.getCreateDateFromLocator(msgLocator);
        if (msgId == 0) {
            // this is a special case where the message prototype is being displayed
            // but no email sent yet, and so we don't have any message in the DB to look at.
            showJSPDepending(ar, ngw, "ReplyNoEmail.jsp", false);
            return;
        }
        if (msgId <= 0) {
            showDisplayWarning(ar, "Can not find that email, the id passed appears to be invalid: " + msgId);
            return;
        }
        long commentId = MailInst.getCommentIdFromLocator(msgLocator);

        MailInst foundMsg = EmailSender.findEmailById(msgId);
        if (foundMsg == null) {
            showDisplayWarning(ar, "Can not find that email with id=" + msgId + ".  Maybe the email has been deleted?");
            return;
        }

        String containerKey = foundMsg.getCommentContainer();
        if (containerKey == null) {
            throw WeaverException.newBasic("stored email message is missing container key,   msgLocator=%s",
                    msgLocator);
        }

        // check for consistency as a way to avoid hacking
        if (commentId > 0 && commentId != foundMsg.getCommentId()) {
            throw WeaverException.newBasic("Can msg locator has wrong comment id in it: %s", msgLocator);
        }

        // if you get here, then you have a link and the email msg id and the comment id
        // match
        // which means you are not a hacker, so we can allow access to the content.

        CommentContainer container = ngw.findContainerByKey(containerKey);
        if (container == null) {
            throw WeaverException.newBasic("Unable to find a container comment with key=%s", containerKey);
        }
        if (!containerKey.contentEquals(container.getGlobalContainerKey(ngw))) {
            throw WeaverException.newBasic("Something is wrong, container keys don't match: %s AND %s", containerKey,
                    container.getGlobalContainerKey(ngw));
        }

        if (container instanceof AgendaItem) {
            AgendaItem ai = (AgendaItem) container;
            MeetingRecord meet = ai.meeting;
            AccessControl.allowSpecialAccessMeeting(ar, ngw, meet);
            ar.setParam("meetId", meet.getId());
            ar.setParam("agendaId", ai.getId());
        } else if (container instanceof TopicRecord) {
            TopicRecord topic = (TopicRecord) container;
            // normally the permission comes from a license in the URL for anonymous access
            AccessControl.allowSpecialAccessTopic(ar, ngw, topic);
            ar.setParam("topicId", topic.getId());
        } else if (container instanceof AttachmentRecord) {
            AttachmentRecord doc = (AttachmentRecord) container;
            // normally the permission comes from a license in the URL for anonymous access
            AccessControl.allowSpecialAccessDoc(ar, ngw, doc);
            ar.setParam("docId", doc.getId());
        } else {
            throw WeaverException.newBasic("Can not understand why comment container is a %s",
                    container.getClass().getCanonicalName());
        }
        ar.setParam("emailId", foundMsg.getFromAddress());
        ar.setParam("commentId", commentId);
        ar.setParam("msgId", msgId);
        ar.setParam("pageId", pageId);
        ar.setParam("siteId", siteId);
        showJSPDepending(ar, ngw, "../anon/Reply.jsp", true);
    }

    @RequestMapping(value = "/{siteId}/{pageId}/unsub/{topicId}/{commentId}.htm", method = RequestMethod.GET)
    public void specialUnsub(@PathVariable String siteId,
            @PathVariable String pageId,
            @PathVariable String topicId,
            @PathVariable String commentId,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        NGWorkspace ngw = registerWorkspaceRequired(ar, siteId, pageId);
        ngw.getNoteOrFail(topicId);
        ar.setParam("topicId", topicId);
        ar.setParam("commentId", commentId);
        ar.setParam("pageId", pageId);
        ar.setParam("siteId", siteId);
        streamJSPAnon(ar, "Unsub.jsp"); /* needtest */
    }

    @RequestMapping(value = "/su/Feedback.htm", method = RequestMethod.GET)
    public void Feedback(HttpServletRequest request, HttpServletResponse response) throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        streamJSPAnon(ar, "Feedback.jsp"); /* needtest */
    }

    @RequestMapping(value = "/{siteId}/{pageId}/SaveReply.json", method = RequestMethod.POST)
    public void specialReplySave(@PathVariable String siteId,
            @PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try {
            NGWorkspace ngw = registerWorkspaceRequired(ar, siteId, pageId);
            ar.setPageAccessLevels(ngw);
            ar.assertNotFrozen(ngw);
            JSONObject input = getPostedObject(ar);
            if (!input.has("comments")) {
                throw WeaverException.newBasic("posted object to specialReplySave needs to have a comments list");
            }
            String topicId = input.optString("topicId");
            String docId = input.optString("docId");
            String meetId = input.optString("meetId");
            String agendaId = input.optString("agendaId");

            if (!ar.isLoggedIn()) {
                String emailId = input.optString("emailId", null);
                UserManager userMgr = UserManager.getStaticUserManager();
                UserProfile possUser = UserManager.lookupUserByAnyId(emailId);
                if (possUser == null) {
                    // what to do here? User has created or updated a comment on an email address
                    // that does not have a user profile. Create one.

                    possUser = userMgr.createUserWithId(emailId);
                    possUser.setName(input.optString("userName", ""));
                    possUser.setDescription("Profile created by entering an anonymous reply to a comment in workspace: "
                            + ngw.getFullName());
                    userMgr.saveUserProfiles();
                } else {
                    // not logged in, but if user object does not have a name try to set it
                    String currentName = possUser.getName();
                    if (currentName == null || currentName.length() == 0) {
                        possUser.setName(input.optString("userName", ""));
                        userMgr.saveUserProfiles();
                    }
                }
                ar.setPossibleUser(possUser);
            }
            JSONObject repo = null;
            if (meetId != null && meetId.length() > 0) {
                MeetingRecord meet = ngw.findMeeting(meetId);
                AgendaItem ai = meet.findAgendaItem(agendaId);
                boolean canAccessMeet = AccessControl.canAccessMeeting(ar, ngw, meet);
                if (!canAccessMeet) {
                    ar.assertAccessWorkspace("must have permission to make a reply");
                }
                ai.updateCommentsFromJSON(input, ar);
                repo = ai.getJSON(ar, ngw, meet, true);
                // make sure the meeting cache is refreshed with latest
                MeetingControler.meetingCache.updateCacheFull(ngw, ar, meetId);
            } else if (topicId != null && topicId.length() > 0) {
                TopicRecord note = ngw.getNoteOrFail(topicId);
                // normally the permission comes from a license in the URL for anonymous access
                boolean canAccessNote = AccessControl.canAccessTopic(ar, ngw, note);
                if (!canAccessNote) {
                    ar.assertAccessWorkspace("must have permission to make a reply");
                }
                note.updateCommentsFromJSON(input, ar);
                repo = note.getJSONWithComments(ar, ngw);

                // check and see if this person is subscriber, if not add them.
                if (ar.isLoggedIn()) {
                    NGRole subscribers = note.getSubscriberRole();
                    UserProfile user = ar.getUserProfile();
                    if (!subscribers.isExpandedPlayer(user, ngw)) {
                        subscribers.addPlayer(user.getAddressListEntry());
                    }
                }
            } else if (docId != null && docId.length() > 0) {
                AttachmentRecord doc = ngw.findAttachmentOrNull(docId);
                // normally the permission comes from a license in the URL for anonymous access
                boolean canAccessNote = AccessControl.canAccessDoc(ar, ngw, doc);
                if (!canAccessNote) {
                    ar.assertAccessWorkspace("must have permission to make a reply");
                }
                doc.updateCommentsFromJSON(input, ar);
                repo = doc.getJSON4Doc(ar, ngw);
            } else {
                throw WeaverException.newBasic("SaveReply call was missing a parameter or two");
            }
            ngw.saveFile(ar, "saving comment using SaveReply");
            sendJson(ar, repo);
        } catch (Exception ex) {
            Exception ee = WeaverException.newWrap("Unable to update the comment in SaveReply", ex);
            streamException(ee, ar);
        }
    }

    @RequestMapping(value = "/{siteId}/{pageId}/CleanAtt.htm", method = RequestMethod.GET)
    public void cleanAtt(@PathVariable String siteId, @PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        ar.reqParam("path");
        BaseController.showJSPMembers(ar, siteId, pageId, "CleanAtt.jsp");
    }

    @RequestMapping(value = "/{siteId}/{pageId}/CleanDebug.htm", method = RequestMethod.GET)
    public void cleanDebug(@PathVariable String siteId, @PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        ar.reqParam("path");
        BaseController.showJSPMembers(ar, siteId, pageId, "CleanDebug.jsp");
    }

    @RequestMapping(value = "/{siteId}/{pageId}/WebFileShow.htm", method = RequestMethod.GET)
    public void webFileShow(@PathVariable String siteId, @PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        ar.reqParam("aid");
        BaseController.showJSPMembers(ar, siteId, pageId, "WebFileShow.jsp");
    }

    @RequestMapping(value = "/{siteId}/{pageId}/WebFileEdit.htm", method = RequestMethod.GET)
    public void webFileEdit(@PathVariable String siteId, @PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        ar.reqParam("aid");
        ar.reqParam("sec");
        BaseController.showJSPMembers(ar, siteId, pageId, "WebFileEdit.jsp");
    }

    /**
     * Both get and update the list of documents attached to either a meeting agenda
     * item, a discussion topic (Note), or a comment This standard form is easier 
     * for the pop up dialog box to use.
     *
     * attachedDocs.json?meet=333&ai=4444
     * attachedDocs.json?note=5555
     * attachedDocs.json?cmt=5342342342
     * attachedDocs.json?goal=6262
     * attachedDocs.json?email=5342342342
     *
     * {
     *   "list": [
     *     "YPNYCMXCH@weaverdesigncirclecl@2779",
     *     "YPEJJSJDH@weaverdesigncirclecl@0031"
     *   ]
     * }
     */
    @RequestMapping(value = "/{siteId}/{pageId}/attachedDocs.json")
    public void attachedDocs(@PathVariable String siteId,
            @PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try {
            NGWorkspace ngw = registerWorkspaceRequired(ar, siteId, pageId);
            List<String> docList = null;

            String meetId = request.getParameter("meet");
            String noteId = request.getParameter("note");
            String cmtId = request.getParameter("cmt");
            String goalId = request.getParameter("goal");
            String emailId = request.getParameter("email");

            if ("POST".equalsIgnoreCase(request.getMethod())) {
                JSONObject posted = this.getPostedObject(ar);
                JSONArray postedList = posted.getJSONArray("list");
                List<String> newDocs = new ArrayList<String>();
                for (int i = 0; i < postedList.length(); i++) {
                    String docId = postedList.getString(i);
                    AttachmentRecord aRec = ngw.findAttachmentByUidOrNull(docId);
                    if (aRec != null) {
                        // check that there really is a document with that id
                        if (!newDocs.contains(aRec.getUniversalId())) {
                            // make sure only unique values get stored once
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
                } else if (noteId != null) {
                    TopicRecord nr = ngw.getNoteOrFail(noteId);
                    nr.setDocList(newDocs);
                    docList = nr.getDocList();
                } else if (cmtId != null) {
                    CommentRecord cr = ngw.getCommentOrFail(DOMFace.safeConvertLong(cmtId));
                    cr.setDocList(newDocs);
                    docList = cr.getDocList();
                } else if (goalId != null) {
                    GoalRecord gr = ngw.getGoalOrFail(goalId);
                    gr.setDocLinks(newDocs);
                    docList = gr.getDocLinks();
                } else if (emailId != null) {
                    EmailGenerator eg = ngw.getEmailGeneratorOrFail(emailId);
                    eg.setAttachments(newDocs);
                    docList = eg.getAttachments();
                } else {
                    throw WeaverException.newBasic(
                            "attachedDocs.json requires a meet, note, cmt, goal, or email parameter on this POST URL");
                }
                ngw.save();
            } else if ("GET".equalsIgnoreCase(request.getMethod())) {
                if (meetId != null) {
                    MeetingRecord mr = ngw.findMeeting(meetId);
                    String agendaId = request.getParameter("ai");
                    AgendaItem ai = mr.findAgendaItem(agendaId);
                    docList = ai.getDocList();
                } else if (noteId != null) {
                    TopicRecord nr = ngw.getNoteOrFail(noteId);
                    docList = nr.getDocList();
                } else if (cmtId != null) {
                    CommentRecord cr = ngw.getCommentOrFail(DOMFace.safeConvertLong(cmtId));
                    docList = cr.getDocList();
                } else if (goalId != null) {
                    GoalRecord gr = ngw.getGoalOrFail(goalId);
                    docList = gr.getDocLinks();
                } else if (emailId != null) {
                    EmailGenerator eg = ngw.getEmailGeneratorOrFail(emailId);
                    docList = eg.getAttachments();
                } else {
                    throw WeaverException.newBasic(
                            "attachedDocs.json requires a meet, note, cmt, goal, or email parameter on this GET URL");
                }
            } else {
                throw WeaverException.newBasic("attachedDocs.json only allows GET or POST");
            }

            JSONObject repo = new JSONObject();
            JSONArray ja = new JSONArray();
            for (String docId : docList) {
                AttachmentRecord aRec = ngw.findAttachmentByUidOrNull(docId);
                if (aRec != null) {
                    // check that there really is a document with that id
                    ja.put(aRec.getUniversalId());
                }
            }
            repo.put("list", ja);
            sendJson(ar, repo);
        } catch (Exception ex) {
            Exception ee = WeaverException.newWrap("Unable to GET/POST attachedDocs.json", ex);
            streamException(ee, ar);
        }
    }

    @RequestMapping(value = "/{siteId}/{pageId}/allActionsList.json", method = RequestMethod.GET)
    public void allActionsList(@PathVariable String siteId, @PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try {
            NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
            ar.setPageAccessLevels(ngw);

            JSONArray attachmentList = new JSONArray();
            for (GoalRecord goal : ngw.getAllGoals()) {
                attachmentList.put(goal.getJSON4Goal(ngw));
            }

            JSONObject repo = new JSONObject();
            repo.put("list", attachmentList);
            sendJson(ar, repo);
        } catch (Exception ex) {
            Exception ee = WeaverException.newWrap("Unable to get the list of all action items ", ex);
            streamException(ee, ar);
        }
    }

    /**
     * Both get and update the list of action items attached to either a meeting
     * agenda item
     * or a discussion topic (Note). This standard form is easier for the pop up
     * dialog box to
     * use.
     *
     * attachedActions.json?meet=333&ai=4444
     * attachedActions.json?note=5555
     *
     * {
     * "list": [
     * "YPNYCMXCH@weaverdesigncirclecl@2779",
     * "YPEJJSJDH@weaverdesigncirclecl@0031"
     * ]
     * }
     */
    @RequestMapping(value = "/{siteId}/{pageId}/attachedActions.json")
    public void attachedActions(@PathVariable String siteId,
            @PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try {
            NGWorkspace ngw = registerWorkspaceRequired(ar, siteId, pageId);
            List<String> actionItemList = null;

            String meetId = request.getParameter("meet");
            String noteId = request.getParameter("note");

            if ("POST".equalsIgnoreCase(request.getMethod())) {
                JSONObject posted = this.getPostedObject(ar);
                JSONArray postedList = posted.getJSONArray("list");
                List<String> newActionItems = new ArrayList<String>();
                for (int i = 0; i < postedList.length(); i++) {
                    String actionId = postedList.getString(i);
                    if (!newActionItems.contains(actionId)) {
                        // make sure unique values get stored only once
                        newActionItems.add(actionId);
                    }
                }
                if (meetId != null) {
                    MeetingRecord mr = ngw.findMeeting(meetId);
                    String agendaId = request.getParameter("ai");
                    if (agendaId == null) {
                        throw WeaverException.newBasic("must specify the agenda item with an 'ai' parameter");
                    }
                    AgendaItem ai = mr.findAgendaItem(agendaId);
                    ai.setActionItems(newActionItems);
                    MeetingControler.meetingCache.updateCacheFull(ngw, ar, meetId);
                    actionItemList = ai.getActionItems();
                } else if (noteId != null) {
                    TopicRecord nr = ngw.getNoteOrFail(noteId);
                    nr.setActionList(newActionItems);
                    actionItemList = nr.getActionList();
                } else {
                    throw WeaverException
                            .newBasic("attachedActions.json requires a meet or note parameter on this URL");
                }
                ngw.save();
            } else if ("GET".equalsIgnoreCase(request.getMethod())) {
                if (meetId != null) {
                    MeetingRecord mr = ngw.findMeeting(meetId);
                    String agendaId = request.getParameter("ai");
                    if (agendaId == null) {
                        throw WeaverException.newBasic("must specify the agenda item with an 'ai' parameter");
                    }
                    AgendaItem ai = mr.findAgendaItem(agendaId);
                    actionItemList = ai.getActionItems();
                } else if (noteId != null) {
                    TopicRecord nr = ngw.getNoteOrFail(noteId);
                    actionItemList = nr.getActionList();
                } else {
                    throw WeaverException
                            .newBasic("attachedActions.json requires a meet or note parameter on this URL");
                }
            } else {
                throw WeaverException.newBasic("attachedActions.json only allows GET or POST");
            }

            JSONObject repo = new JSONObject();
            JSONArray ja = new JSONArray();
            for (String docId : actionItemList) {
                ja.put(docId);
            }
            repo.put("list", ja);
            sendJson(ar, repo);
        } catch (Exception ex) {
            Exception ee = WeaverException.newWrap("Unable to GET/POST attachedActions.json", ex);
            streamException(ee, ar);
        }
    }


    @RequestMapping(value = "/{siteId}/{pageId}/GetTempName.json", method = RequestMethod.GET)
    public void GetTempName(@PathVariable String siteId,
            @PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try {
            ar.assertLoggedIn("Temp Files are available only when logged in.");
            NGWorkspace ngw = registerWorkspaceRequired(ar, siteId, pageId);
            ngw.assertNotFrozen("Must be an active workspace to attach a document");

            File folder = ngw.getContainingFolder();
            boolean nameIsAcceptable = false;
            String tempName = null;
            while (!nameIsAcceptable) {
                // we just want to make sure that the temp file does not already exist here
                tempName = "~tmp~"+IdGenerator.generateKey()+"~tmp~";
                File tempFile = new File(folder, tempName);
                nameIsAcceptable = !tempFile.exists();
            }

            JSONObject res = new JSONObject();
            res.put("tempFileName", tempName);
            res.put("tempFileURL", "UploadTempFile.json?tempName=" + tempName);

            sendJson(ar, res);
        } catch (Exception ex) {
            Exception ee = WeaverException.newWrap("Unable to create a temp name in workspace (%s)", ex, pageId);
            streamException(ee, ar);
        }
    }

    @RequestMapping(value = "/{siteId}/{pageId}/UploadTempFile.json", method = RequestMethod.PUT)
    public void UploadTempFile(@PathVariable String siteId,
            @PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try {
            ar.assertLoggedIn("Temp Files can up uploaded only when logged in.");
            NGWorkspace ngw = registerWorkspaceRequired(ar, siteId, pageId);
            ngw.assertNotFrozen("Must be an active workspace to attach a document");

            String tempName = ar.reqParam("tempName");
            if (!tempName.startsWith("~tmp")) {
                throw WeaverException.newBasic("Got an upload request to a non-temp file name: %s", tempName);
            }
            File folder = ngw.getContainingFolder();
            File tempFile = new File(folder, tempName);
            if (tempFile.exists()) {
                throw WeaverException.newBasic("Temp file %s already exists in workspace %s, should never happen, name should only be used once", 
                        tempFile, ngw.getFullName());
            }
            InputStream is = ar.req.getInputStream();
            StreamHelper.copyStreamToFile(is, tempFile);

            JSONObject res = new JSONObject();
            res.put("tempFileName", tempName);
            res.put("tempFileURL", "AttachTempFile.json?tempName=" + tempName);

            sendJson(ar, res);
        } catch (Exception ex) {
            Exception ee = WeaverException.newWrap("Unable to create a temp file in workspace (%s)", ex, pageId);
            streamException(ee, ar);
        }
    }

    @RequestMapping(value = "/{siteId}/{pageId}/AttachTempFile.json", method = RequestMethod.POST)
    public void AttachTempFile(@PathVariable String siteId,
            @PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        String tempName = "UNKNOWN";
        try {
            ar.assertLoggedIn("Temp Files can be attached only when logged in.");
            NGWorkspace ngw = registerWorkspaceRequired(ar, siteId, pageId);
            ngw.assertNotFrozen("Must be an active workspace to attach a document");
            ngw.assertUpdateWorkspace(ar.getUserProfile(), 
                    "Only users that can update the workspace can attach documents");

            tempName = ar.reqParam("tempName");
            File folder = ngw.getContainingFolder();
            File tempFile = new File(folder, tempName);
            if (!tempFile.exists()) {
                throw WeaverException.newBasic("Temp file %s does not exist in workspace %s", 
                        tempFile, ngw.getFullName());
            }
            
            JSONObject input = getPostedObject(ar);
            JSONObject newDocObj = input.getJSONObject("doc");
            long size = newDocObj.optLong("size", -1);

            // if the temp file is still being uploaded, then wait a bit
            int count = 0;
            while (tempFile.length()<size) {
                if (count++ > 20) {
                    throw WeaverException.newBasic("Attach temp file failed because file size is %s, should be %s", 
                            Long.toString(tempFile.length()), Long.toString(size));
                }
                System.out.println("WAITING "+count+" FOR ("+tempFile.toString()
                    +") to get from "+tempFile.length()+" to "+size+" bytes.");
                Thread.sleep(300);
            }

            AttachmentRecord att;
            int historyEventType = HistoryRecord.EVENT_TYPE_CREATED;
            String updateReason = "Created new document attachment";
            String docId = newDocObj.optString("id");
            if (docId == null || docId.isEmpty()) {
                att = ngw.createAttachment();
            }
            else {
                att = ngw.findAttachmentByIDOrFail(docId);
                historyEventType = HistoryRecord.EVENT_TYPE_MODIFIED;
                updateReason = "Modified document attachment with new version";
            }

            // this is to satisfy a protection in the update method 
            newDocObj.put("universalid", att.getUniversalId());
            att.updateDocFromJSON(newDocObj, ar);

            // Now, actually create an attachment version from the temp file
            String userUpdate = ar.getBestUserId();
            long timeUpdate = newDocObj.optLong("modifiedtime", ar.nowTime);
            FileInputStream fis = new FileInputStream(tempFile);
            att.streamNewVersion(ngw, fis, userUpdate, timeUpdate);
            fis.close();
            tempFile.delete();

            HistoryRecord.createHistoryRecord(ngw, att.getId(),  HistoryRecord.CONTEXT_TYPE_DOCUMENT,
                    0, historyEventType, ar, updateReason);
            System.out.println("DOCUMENT: updated: "+att.getNiceName()+" ("+size+" bytes) and history created.");
            ngw.saveFile(ar, updateReason);

            JSONObject res = att.getJSON4Doc(ar, ngw);
            sendJson(ar, res);
        } catch (Exception ex) {
            Exception ee = WeaverException.newWrap("Unable to attach a temp file %s in workspace (%s)", ex, tempName, pageId);
            streamException(ee, ar);
        }
    }

    
    @RequestMapping(value = "/{siteId}/{pageId}/GetScratchpad.json", method = RequestMethod.GET)
    public void getScratchpad(@PathVariable String siteId,
            @PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try {
            ar.assertLoggedIn("ScratchPad is available only when logged in.");
            Cognoscenti cog = ar.getCogInstance();
            String key = ar.getUserProfile().getKey();
            UserCache uc = cog.getUserCacheMgr().getCache(key);

            JSONObject repo = new JSONObject();
            repo.put("scratchpad", uc.getScratchPad());
            sendJson(ar, repo);
        } catch (Exception ex) {
            Exception ee = WeaverException.newWrap("Unable to GetScratchpad in workspace (%s)", ex, pageId);
            streamException(ee, ar);
        }
    }

    @RequestMapping(value = "/{siteId}/{pageId}/UpdateScratchpad.json", method = RequestMethod.POST)
    public void updateScratchpad(@PathVariable String siteId,
            @PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try {
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
        } catch (Exception ex) {
            Exception ee = WeaverException.newWrap("Unable to UpdateScratchpad in workspace (%s)", ex, pageId);
            streamException(ee, ar);
        }
    }

    @RequestMapping(value = "/{siteId}/{pageId}/WebFilePrint.htm", method = RequestMethod.GET)
    public void webFilePrint(@PathVariable String siteId, @PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        try {
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            NGWorkspace ngw = registerWorkspaceRequired(ar, siteId, pageId);

            String id = ar.reqParam("aid");

            // check that the attachment exists
            ngw.findAttachmentByIDOrFail(id);

            ar.invokeJSP("/spring/anon/WebFilePrint.jsp");

        } catch (Exception ex) {
            throw WeaverException.newWrap("Unable to construct the WebFile Print page for workspace (%s) in site (%s)",
                    ex, pageId, siteId);
        }
    }

    @RequestMapping(value = "/{siteId}/{pageId}/GetWebFile.json", method = RequestMethod.GET)
    public void getWebFile(@PathVariable String siteId,
            @PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);

        String aid = request.getParameter("aid");
        try {
            ar.assertLoggedIn("WebFiles are available only when logged in.");
            Cognoscenti cog = ar.getCogInstance();
            NGWorkspace ngw = cog.getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
            ar.setPageAccessLevels(ngw);
            AttachmentRecord att = ngw.findAttachmentByIDOrFail(aid);
            WebFile wf = att.getWebFile();

            JSONObject repo = wf.getJson();
            sendJson(ar, repo);
        } catch (Exception ex) {
            Exception ee = WeaverException.newWrap("Unable to GetWebFile for attachement %s in workspace (%s)", ex, aid,
                    pageId);
            streamException(ee, ar);
        }
    }

    @RequestMapping(value = "/{siteId}/{pageId}/UpdateWebFile.json", method = RequestMethod.POST)
    public void updateWebFile(@PathVariable String siteId,
            @PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        String aid = request.getParameter("aid");
        try {
            ar.assertLoggedIn("WebFiles are available only when logged in.");
            Cognoscenti cog = ar.getCogInstance();
            NGWorkspace ngw = cog.getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
            ar.setPageAccessLevels(ngw);
            AttachmentRecord att = ngw.findAttachmentByIDOrFail(aid);
            WebFile wf = att.getWebFile();

            JSONObject posted = getPostedObject(ar);
            wf.updateData(posted);
            wf.save();

            JSONObject repo = wf.getJson();
            sendJson(ar, repo);
        } catch (Exception ex) {
            Exception ee = WeaverException.newWrap("Unable to UpdateWebFile for attachement %s in workspace (%s)", ex,
                    aid, pageId);
            streamException(ee, ar);
        }
    }

    @RequestMapping(value = "/{siteId}/{pageId}/UpdateWebFileComments.json", method = RequestMethod.POST)
    public void updateWebFileComments(@PathVariable String siteId,
            @PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        String aid = request.getParameter("aid");
        String userKey = ar.getUserProfile().getKey();
        try {
            int sec = (int) ar.reqParamLong("sec");
            ar.assertLoggedIn("WebFiles are available only when logged in.");
            Cognoscenti cog = ar.getCogInstance();
            NGWorkspace ngw = cog.getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
            ar.setPageAccessLevels(ngw);
            AttachmentRecord att = ngw.findAttachmentByIDOrFail(aid);
            WebFile wf = att.getWebFile();

            JSONObject posted = getPostedObject(ar);
            wf.updateUserComments(sec, userKey, posted);
            wf.save();

            JSONObject repo = wf.getJson();
            sendJson(ar, repo);
        } catch (Exception ex) {
            Exception ee = WeaverException.newWrap(
                    "Unable to UpdateWebFileComments for attachement %s in workspace (%s) for user (%s)",
                    ex, aid, pageId, userKey);
            streamException(ee, ar);
        }
    }
    
    @RequestMapping(value = "/{siteId}/{pageId}/linkURLToProject.htm", method = RequestMethod.GET)
    protected void getLinkURLToProjectForm(@PathVariable String siteId,
            @PathVariable String pageId, HttpServletRequest request,
            HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try{
            NGWorkspace ngw =  registerWorkspaceRequired(ar, siteId, pageId);

            if (warnFrozenOrNotMember(ar, ngw)) {
                return;
            }

            showJSPMembers(ar, siteId, pageId, "linkURLToProject.jsp");
        }
        catch(Exception e){
            showDisplayException(ar, WeaverException.newWrap(
                "Failed to open create link url to workspace page in workspace (%s) of site (%s).", 
                e, pageId, siteId));
        }
    }

}
