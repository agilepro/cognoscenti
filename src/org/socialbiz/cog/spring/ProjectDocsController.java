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

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.socialbiz.cog.AccessControl;
import org.socialbiz.cog.AttachmentRecord;
import org.socialbiz.cog.AttachmentVersion;
import org.socialbiz.cog.AuthRequest;
import org.socialbiz.cog.DOMFace;
import org.socialbiz.cog.MimeTypes;
import org.socialbiz.cog.NGPage;
import org.socialbiz.cog.NGPageIndex;
import org.socialbiz.cog.NGWorkspace;
import org.socialbiz.cog.SectionAttachments;
import org.socialbiz.cog.WikiToPDF;
import org.socialbiz.cog.dms.FolderAccessHelper;
import org.socialbiz.cog.exception.NGException;
import org.socialbiz.cog.util.PDFUtil;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.workcast.json.JSONArray;
import org.workcast.json.JSONObject;

@Controller
public class ProjectDocsController extends BaseController {


    @RequestMapping(value = "/{siteId}/{pageId}/listAttachments.htm", method = RequestMethod.GET)
    public void listAttachments(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        BaseController.showJSPAnonymous(ar, siteId, pageId, "ListAttachments");
    }


    @RequestMapping(value = "/{siteId}/{pageId}/docsFolder.htm", method = RequestMethod.GET)
    public void docsFolder(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        BaseController.showJSPAnonymous(ar, siteId, pageId, "DocsFolder");
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
        BaseController.showJSPMembers(ar, siteId, pageId, "DocsAdd");
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
        //ngp.findAttachmentByIDOrFail(aid);
        request.setAttribute("aid", aid);
        BaseController.showJSPAnonymous(ar, siteId, pageId, "editDetails");
    }

    @RequestMapping(value = "/{siteId}/{pageId}/fileVersions.htm", method = RequestMethod.GET)
    protected void fileVersions(@PathVariable String siteId,
             @PathVariable String pageId,
             HttpServletRequest request,  HttpServletResponse response) throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        //ngp.findAttachmentByIDOrFail(aid);
        request.setAttribute("aid", ar.reqParam("aid"));
        BaseController.showJSPAnonymous(ar, siteId, pageId, "fileVersions");
    }

    @RequestMapping(value = "/{siteId}/{pageId}/docsRevise.htm", method = RequestMethod.GET)
    protected void docsRevise(@PathVariable String siteId,
             @PathVariable String pageId,
             HttpServletRequest request,  HttpServletResponse response) throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        //ngp.findAttachmentByIDOrFail(aid);
        request.setAttribute("aid", ar.reqParam("aid"));
        BaseController.showJSPAnonymous(ar, siteId, pageId, "DocsRevise");
    }


    //////////////////////// REDIRECTS //////////////////////////////

    @RequestMapping(value = "/{siteId}/{pageId}/attachment.htm", method = RequestMethod.GET)
    public void showProjectHomeTab(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        response.sendRedirect("listAttachments.htm");
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

            InputStream fis = attachmentVersion.getInputStream();

            //NOTE: now that we have the input stream, we can let go of the project.  This is important
            //to prevent holding the lock for the entire time that it takes for the client to download
            //the file.  Remember, slow clients might take minutes to download a large file.
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
            ar.getCogInstance().getProjectByKeyOrFail(pageId);

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
            pdfUtil.serveUpFile(ar, pageId);
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

/*
//This is the OLD way
    @RequestMapping(value = "/{siteId}/{pageId}/uploadDocument.htm", method = RequestMethod.GET)
    protected ModelAndView getUploadDocumentForm(@PathVariable String siteId,
            @PathVariable String pageId, HttpServletRequest request,
            HttpServletResponse response) throws Exception {
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            NGPage ngp =  registerRequiredProject(ar, siteId, pageId);

            if(!ar.isLoggedIn()){
                return showWarningView(ar, "nugen.project.upload.doc.login.msg");
            }
            if(!ar.isMember()){
                request.setAttribute("roleName", "Members");
                return new ModelAndView("WarningNotMember");
            }
            if(ngp.isFrozen()){
                return showWarningView(ar, "nugen.generatInfo.Frozen");
            }

            ModelAndView modelAndView = createNamedView(siteId, pageId, ar, "uploadDocumentForm");
            request.setAttribute("isNewUpload", "yes");
            request.setAttribute("realRequestURL", ar.getRequestURL());
            request.setAttribute("title", ngp.getFullName());
            return modelAndView;

        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.project.upload.document.page", new Object[]{pageId,siteId} , ex);
        }
    }
*/


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
            NGPage ngp = ar.getCogInstance().getProjectByKeyOrFail( pageId );
            ar.setPageAccessLevels(ngp);
            ar.assertMember("Must be a member to update a document information.");
            ar.assertNotFrozen(ngp);
            JSONObject docInfo = getPostedObject(ar);

            AttachmentRecord aDoc = null;
            if ("~new~".equals(did)) {
                aDoc = ngp.createAttachment();
                docInfo.put("universalid", aDoc.getUniversalId());
                aDoc.setModifiedDate(ar.nowTime);
                aDoc.setModifiedBy(ar.getBestUserId());
                aDoc.setType(docInfo.getString("attType"));
            }
            else {
                aDoc = ngp.findAttachmentByIDOrFail(did);
            }

            //everything else updated here
            aDoc.updateDocFromJSON(docInfo, ar);

            ngp.saveFile(ar, "Updated Agenda Item");
            JSONObject repo = aDoc.getJSON4Doc(ar, ngp);
            repo.write(ar.w, 2, 2);
            ar.flush();
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
            NGWorkspace ngw = ar.getCogInstance().getProjectByKeyOrFail( pageId );
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
            repo.write(ar.w, 2, 2);
            ar.flush();
        }catch(Exception ex){
            Exception ee = new Exception("Unable to get the list of attachments ", ex);
            streamException(ee, ar);
        }
    }

}
