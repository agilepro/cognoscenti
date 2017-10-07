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

import java.net.URLEncoder;
import java.util.Enumeration;
import java.util.Hashtable;
import java.util.Properties;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.socialbiz.cog.AttachmentRecord;
import org.socialbiz.cog.AuthRequest;
import org.socialbiz.cog.NGPage;
import org.socialbiz.cog.NGWorkspace;
import org.socialbiz.cog.UserManager;
import org.socialbiz.cog.UserPage;
import org.socialbiz.cog.dms.ConnectionSettings;
import org.socialbiz.cog.dms.ConnectionType;
import org.socialbiz.cog.dms.FolderAccessHelper;
import org.socialbiz.cog.dms.ResourceEntity;
import org.socialbiz.cog.exception.NGException;
import org.socialbiz.cog.exception.ProgramLogicError;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.multipart.MultipartFile;

@Controller
public class RemoteLinkController extends BaseController {


    @RequestMapping(value = "/{siteId}/{pageId}/syncSharePointAttachment.htm", method = RequestMethod.GET)
    protected void syncAttachmentAction(@PathVariable String siteId,
            @PathVariable String pageId, HttpServletRequest request,
            HttpServletResponse response) throws Exception {
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            NGPage ngp = registerRequiredProject(ar, siteId, pageId);
            if(!ar.isLoggedIn()){
                sendRedirectToLogin(ar);
                return;
            }
            Hashtable<String, String> params = new Hashtable<String, String>();
            @SuppressWarnings("unchecked")
            Enumeration<String> sElements = request.getParameterNames();
            while (sElements.hasMoreElements()) {
               String key = sElements.nextElement();
               String value = ar.defParam(key,"");
               params.put(key, value);
            }

            String aid = reqParamSpecial(params, "aid");

            ar.assertMember("Unable to Synchronize attachments.");

            FolderAccessHelper fah = new FolderAccessHelper(ar);

            String action   = reqParamSpecial(params, "action");

            if ("updateRepository".equals(action)) {
                fah.uploadAttachment(ngp, aid);
            }
            else if ("updateLocal".equals(action)) {
                fah.refreshAttachmentFromRemote(ngp, aid);
            }
            else {
                throw new ProgramLogicError("syncSharePointAttachment.htm does not understand the operation: "+action);
            }

            ngp.saveFile(ar, "Modified attachments");
            response.sendRedirect(ar.baseURL+"t/"+siteId+"/"+pageId+"/listAttachments.htm");

        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.project.sync.share.point.attachment.page",
                    new Object[]{pageId,siteId} , ex);
        }
    }

    public String reqParamSpecial(Hashtable<String, String> params, String paramName)
        throws Exception
    {
        String val = params.get(paramName);
        if (val == null || val.length()==0) {
            throw new NGException("nugen.exception.param.required", new Object[]{paramName});
        }
        return val;
    }

    @RequestMapping(value = "/{userKey}/deleteConnection.form", method = RequestMethod.GET)
    protected void deleteConnection(@PathVariable String userKey,
            HttpServletRequest request,
            HttpServletResponse response) throws Exception {
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            if(!ar.isLoggedIn()){
                sendRedirectToLogin(ar);
                return;
            }
            String folderId = ar.reqParam("folderId");

            FolderAccessHelper.deleteConnection(ar, folderId);
            response.sendRedirect(ar.baseURL+"t/"+userKey+"/userConnections.htm");

        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.project.delete.connection", null , ex);
        }
    }

    @RequestMapping(value = "/{siteId}/{pageId}/Synchronize.form", method = RequestMethod.POST)
    protected void Synchronize(@PathVariable String siteId,
            @PathVariable String pageId, HttpServletRequest request,
            HttpServletResponse response) throws Exception {
        try{
            request.setAttribute("book", siteId);
            request.setAttribute("pageId", pageId);
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            NGPage ngp = registerRequiredProject(ar, siteId, pageId);
            if(!ar.isLoggedIn()){
                sendRedirectToLogin(ar);
                return;
            }
            Hashtable<String, String> params = new Hashtable<String, String>();
            @SuppressWarnings("unchecked")
            Enumeration<String> sElements = request.getParameterNames();
            ar.setPageAccessLevels(ngp);
            ar.assertMember("Unable to Synchronize attachments.");
            ar.assertNotFrozen(ngp);

            while (sElements.hasMoreElements())
            {
               String key = sElements.nextElement();
               String value = ar.reqParam(key);
               params.put(key, value);

               String search = "aid-";
               String aid = "";
               int i;
               i = key.indexOf(search);
               if(i != -1) {
                   aid = key.substring(i+4, key.length());
                   FolderAccessHelper fah = new FolderAccessHelper(ar);

                   if ("checkin".equals(value))
                   {
                       fah.uploadAttachment(ngp, aid);
                       ngp.saveFile(ar, "Modified attachments");
                   }
                   else if ("checkout".equals(value))
                   {
                       fah.refreshAttachmentFromRemote(ngp, aid);
                       ngp.saveFile(ar, "Modified attachments");
                   }
               }
            }
            response.sendRedirect(ar.baseURL+"t/"+siteId+"/"+pageId+"/listAttachments.htm");

        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.project.synchronize",
                    new Object[]{pageId,siteId} , ex);
        }
    }

    @RequestMapping(value = "/{siteId}/{pageId}/linkToRepository.htm", method = RequestMethod.GET)
    protected void linkToRepository(@PathVariable String siteId,
            @PathVariable String pageId, HttpServletRequest request,
            HttpServletResponse response) throws Exception {
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            request.setAttribute("isNewUpload", "yes");
            showJSPMembers(ar, siteId, pageId, "LinkToRepository");
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.project.link.to.repository.page",
                    new Object[]{pageId,siteId} , ex);
        }
    }

    //TODO: do we still need this?
    @RequestMapping(value = "/{siteId}/{pageId}/submitWebDevURL.form", method = RequestMethod.POST)
    protected void submitWebDevURL(@PathVariable String siteId,
            @PathVariable String pageId, HttpServletRequest request,
            HttpServletResponse response) throws Exception {
        try{
            AuthRequest ar = getLoggedInAuthRequest(request, response, "message.must.be.login.to.perform.action");
            registerRequiredProject(ar, siteId, pageId);

            String rLink = ar.reqParam("rLink");

            ar.resp.sendRedirect("WebDevURLForm.htm?rLink="+URLEncoder.encode(rLink, "UTF-8"));
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.project.link.to.repository",
                    new Object[]{pageId,siteId} , ex);
        }
    }

    @RequestMapping(value = "/{siteId}/{pageId}/webDevURL.form", method = RequestMethod.POST)
    protected void webDevURL(@PathVariable String siteId,
            @PathVariable String pageId, HttpServletRequest request,
            HttpServletResponse response) throws Exception {
        try{
            AuthRequest ar = getLoggedInAuthRequest(request, response, "message.must.be.login.to.perform.action");
            registerRequiredProject(ar, siteId, pageId);
            String action = ar.reqParam("action");
            String rlink = ar.reqParam("rlink");

            String dest = null;
            if(action.equals("UseExistingConnection")){
                String folderId = ar.reqParam("folderId");
                dest = "createLinkToRepositoryForm.htm?folderId="+URLEncoder.encode(folderId, "UTF-8")
                            +"&rlink="+ URLEncoder.encode(rlink, "UTF-8");
            }
            else if(action.equals("CreateNewConnection")){
                dest = "createNewConnection.htm?rlink="+ URLEncoder.encode(rlink, "UTF-8");
            }
            else if(action.equals("AccessPublicDocument")){
                dest = "createLinkToRepositoryForm.htm?folderId=PUBLIC&rlink="+ URLEncoder.encode(rlink, "UTF-8");
            }
            else{
                throw new ProgramLogicError("Don't understand the operation: "+ action);
            }
            ar.resp.sendRedirect(dest);

        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.project.link.to.repository.page",
                    new Object[]{pageId,siteId} , ex);
        }
    }

    @RequestMapping(value = "/{siteId}/{pageId}/createConnection.form", method = RequestMethod.POST)
    protected void createConnection(@PathVariable String siteId,
            @PathVariable String pageId, HttpServletRequest request,
            HttpServletResponse response) throws Exception {
        try{
            AuthRequest ar = getLoggedInAuthRequest(request, response, "message.can.not.create.connection");
            registerRequiredProject(ar, siteId, pageId);
            String action = ar.reqParam("action");
            if(!action.equals("createConnection")){
                throw new ProgramLogicError("createConnection.form does not understand the operation: "+ action);
            }
            UserPage uPage = ar.getUserPage();

            ConnectionSettings cSet = uPage.createConnectionSettings();
            FolderAccessHelper.updateSettingsFromRequest(ar, uPage, cSet);
            String connId = cSet.getId();
            ConnectionType cType = uPage.getConnectionOrFail(connId);

            String fullPath = ar.reqParam("rlink");
            ResourceEntity verifyEnt = cType.getResource(fullPath);

            String isNewUpload = ar.defParam("isNewUpload", "yes");
            String aid = ar.defParam("aid", null);

            Properties props = new Properties();
            props.setProperty("aid", aid);
            props.setProperty("rlink", verifyEnt.getFullPath());
            props.setProperty("isNewUpload", isNewUpload);
            props.setProperty("folderId", cSet.getId());
            redirectBrowser(ar, "createLinkToRepositoryForm.htm", props);
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.project.create.connection",
                    new Object[]{pageId,siteId} , ex);
        }
    }

    @RequestMapping(value = "/{siteId}/{pageId}/problemDiagnosePage.htm",method = RequestMethod.GET)
    protected void problemDiagnosePage(@PathVariable String siteId, @PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) throws Exception{
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            showJSPMembers(ar, siteId, pageId, "ProblemDiagnosePage");
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.project.problem.diagnose.page",
                    new Object[]{pageId,siteId} , ex);
        }
    }

    @RequestMapping(value = "/{siteId}/{pageId}/problemDiagnose.form", method = RequestMethod.POST)
    protected void problemDiagnose(@PathVariable String siteId,
            @PathVariable String pageId, HttpServletRequest request,
            HttpServletResponse response) throws Exception {
        try{
            AuthRequest ar = getLoggedInAuthRequest(request, response, "message.must.be.login.to.perform.action");
            NGWorkspace ngw = registerRequiredProject(ar, siteId, pageId);
            if(ngw.isFrozen()){
                throw new NGException("nugen.project.freezed.msg",null);
            }
            UserPage uPage = ar.getUserPage();


            String action = ar.reqParam("action");
            String aid = ar.reqParam("aid");
            FolderAccessHelper fah = new FolderAccessHelper(ar);

            if(action.equals("UseExistingConnection")){

                String folderId = ar.reqParam("folderId");
                String fullPath = ar.reqParam("rlink");
                ResourceEntity verifyEnt = uPage.getResourceFromFullpath(folderId, fullPath);

                Properties params = new Properties();
                params.setProperty("rlink", fullPath);
                params.setProperty("folderId", verifyEnt.getFolderId());
                params.setProperty("aid", aid);
                params.setProperty("isNewUpload", "no");
                params.setProperty("atype", ar.reqParam("atype"));
                redirectBrowser(ar, "listAttachments.htm", params);
            }
            else if(action.equals("CreateNewConnection")){
                Properties params = new Properties();
                params.setProperty("rlink", ar.reqParam("rlink"));
                params.setProperty("aid", aid);
                params.setProperty("isNewUpload", "no");
                params.setProperty("atype", ar.reqParam("atype"));
                redirectBrowser(ar, "createNewConnection.htm", params);
            }
            else if(action.equals("ChangePassword")){
                String folderId = ar.reqParam("folderId");
                fah.changePassword(folderId);
                response.sendRedirect(ar.baseURL+"t/"+siteId+"/"+pageId+"/listAttachments.htm");
            }
            else if(action.equals("CreateCopy")){
                String connectionHealth = ar.reqParam("connectionHealth");
                String folderId = ar.reqParam("folderId");
                if (!connectionHealth.equals("Healthy")) {
                    throw new NGException("nugen.exception.unhealthy.connection", new Object[]{folderId});
                }
                fah.createCopyInRepository(null, ngw, aid, ar.reqParam("rlink"), folderId,false);
                response.sendRedirect(ar.baseURL+"t/"+siteId+"/"+pageId+"/listAttachments.htm");
            }
            else if(action.equals("UnlinkFromRepository")){
                AttachmentHelper.unlinkDocFromRepository(ar, aid, ngw);
                response.sendRedirect(ar.baseURL+"t/"+siteId+"/"+pageId+"/listAttachments.htm");
            }
            else if(action.equals("ChangeURL")){
                String folderId = ar.reqParam("folderId");
                String newPath = ar.reqParam("newPath");
                ConnectionType cType = ar.getUserPage().getConnectionOrFail(folderId);
                String newRelativePath = cType.getInternalPathOrFail(newPath);
                String rFilename = newRelativePath.substring(newRelativePath.lastIndexOf('/') + 1);
                AttachmentHelper.updateRemoteAttachment(ar, ngw, null, newRelativePath, folderId, rFilename, null);
                response.sendRedirect(ar.baseURL+"t/"+siteId+"/"+pageId+"/listAttachments.htm");
            }
            else{
                throw new ProgramLogicError("problemDiagnose.form does not understand the operation: "+ action);
            }

        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.project.problem.diagnose",
                    new Object[]{pageId,siteId} , ex);
        }
    }

    @RequestMapping(value = "/{siteId}/{pageId}/WebDevURLForm.htm", method = RequestMethod.GET)
    protected void getWebDevURLForm(@PathVariable String siteId,
            @PathVariable String pageId, HttpServletRequest request,
            HttpServletResponse response) throws Exception {
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            request.setAttribute("isNewUpload", "yes");
            showJSPMembers(ar, siteId, pageId, "WebDevURLForm");

        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.project.link.to.repository",
                    new Object[]{pageId,siteId} , ex);
        }
    }

    @RequestMapping(value = "/{siteId}/{pageId}/createLinkToRepositoryForm.htm", method = RequestMethod.GET)
    protected void getLinkFromRepositoryForm(@PathVariable String siteId,
            @PathVariable String pageId, HttpServletRequest request,
            HttpServletResponse response) throws Exception {
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);

            UserPage uPage = ar.getUserPage();
            //lets verify that everything is valid at this point.
            String folderId = ar.reqParam("folderId");
            String fullPath = ar.reqParam("rlink");
            ConnectionType cType = uPage.getConnectionOrFail(folderId);
            ResourceEntity remoteFile = cType.getResource(fullPath);
            String aid = ar.defParam("aid", null);

            request.setAttribute("isNewUpload", "yes");
            request.setAttribute("aid", aid);
            request.setAttribute("symbol", remoteFile.getSymbol());
            request.setAttribute("atype", ar.defParam("atype","2"));
            showJSPMembers(ar, siteId, pageId, "createLinkToRepositoryForm");
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.project.link.to.repository.page",
                    new Object[]{pageId,siteId} , ex);
        }
    }

    @RequestMapping(value = "/{siteId}/{pageId}/createNewConnection.htm", method = RequestMethod.GET)
    protected void createNewConnection(@PathVariable String siteId,
            @PathVariable String pageId, HttpServletRequest request,
            HttpServletResponse response) throws Exception {
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            registerRequiredProject(ar, siteId, pageId);
            if (checkLoginMember(ar)) {
                return;
            }

            String rlink = ar.reqParam("rlink");
            request.setAttribute("isNewUpload", "yes");
            request.setAttribute("rlink", rlink);
            request.setAttribute("atype", ar.defParam("atype", "2"));
            request.setAttribute("realRequestURL", ar.getRequestURL());
            showJSPMembers(ar, siteId, pageId, "CreateNewConnection_form");
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.project.create.new.connection.page",
                    new Object[]{pageId,siteId} , ex);
        }
    }

    //TODO: do we still need this?
    @RequestMapping(value = "/{siteId}/{pageId}/CreateCopyForm.form", method = RequestMethod.POST)
    protected void createCopyForm(@PathVariable String siteId,
            @PathVariable String pageId, HttpServletRequest request,
            HttpServletResponse response) throws Exception {
        try{
            AuthRequest ar = getLoggedInAuthRequest(request, response, "message.must.be.login.to.perform.action");
            NGPage nGPage = registerRequiredProject(ar, siteId, pageId);
            if(nGPage.isFrozen()){
                throw new NGException("nugen.project.freezed.msg",null);
            }

            String action = ar.reqParam("action");
            String aid = ar.reqParam("aid");


            if(action.equals("ChooseFolder")){
                Properties props = new Properties();
                props.setProperty("aid", aid);
                props.setProperty("folderId", ar.reqParam("folderId"));
                props.setProperty("path", "/");
                redirectBrowser(ar, "ChooseFolder.htm", props);

            }
            else if(action.equals("CreateNewConnection")){
                Properties props = new Properties();
                props.setProperty("aid", aid);
                props.setProperty("path", "/");
                redirectBrowser(ar, "createConForExistingFile.htm", props);
            }
            else if(action.equals("ChooseDefLocation")){

                ResourceEntity parent = nGPage.getDefRemoteFolder();

                AttachmentRecord att = nGPage.findAttachmentByIDOrFail(aid);
                FolderAccessHelper fah = new FolderAccessHelper(ar);

                ResourceEntity childEnt = parent.getChild(att.getDisplayName());

                boolean isSuccess = fah.copyAttachmentToRemote(nGPage, aid, childEnt, false);

                if(!isSuccess){
                    Properties props = new Properties();
                    props.setProperty("aid", aid);
                    props.setProperty("symbol", childEnt.getSymbol());
                    redirectBrowser(ar, "fileExists.htm", props);
                }else{
                    redirectBrowser(ar, "listAttachments.htm");
                }
            }
            else{
                throw new ProgramLogicError("CreateCopyForm.form does not understand the operation: "+ action);
            }
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.project.create.copy.from",
                    new Object[]{pageId,siteId} , ex);
        }
    }

    @RequestMapping(value = "/{siteId}/{pageId}/ChooseFolder.htm", method = RequestMethod.GET)
    protected void chooseFolder(@PathVariable String siteId,
            @PathVariable String pageId, HttpServletRequest request,
            HttpServletResponse response) throws Exception {
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            String aid    = ar.defParam("aid", "");
            String fndDefLoctn    = ar.defParam("fndDefLoctn", "false");
            String folderId = ar.reqParam("folderId");
            String path = ar.reqParam("path");

            request.setAttribute("aid", aid);
            request.setAttribute("folderId", folderId);
            request.setAttribute("path", path);
            request.setAttribute("fndDefLoctn", fndDefLoctn);
            showJSPMembers(ar, siteId, pageId, "ChooseFolder");

        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.project.choose.folder.page",
                    new Object[]{pageId,siteId} , ex);
        }
    }

    @RequestMapping(value = "/{siteId}/{pageId}/pushToRepository.htm", method = RequestMethod.GET)
    protected void pushToRepository(@PathVariable String siteId,
            @PathVariable String pageId, HttpServletRequest request,
            HttpServletResponse response) throws Exception {
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            showJSPMembers(ar, siteId, pageId, "PushToRepository");
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.project.push.to.repository.page",
                    new Object[]{pageId,siteId} , ex);
        }
    }

    @RequestMapping(value = "/{siteId}/{pageId}/PushToRepository.form", method = RequestMethod.POST)
    protected void pushToRepositoryForm(@PathVariable String siteId,
            @PathVariable String pageId, HttpServletRequest request,
            HttpServletResponse response) throws Exception {
        try{
            AuthRequest ar = getLoggedInAuthRequest(request, response, "message.can.not.push.doc.to.repository");
            NGPage nGPage = registerRequiredProject(ar, siteId, pageId);
            if(nGPage.isFrozen()){
                throw new NGException("nugen.project.freezed.msg",null);
            }

            String aid = ar.reqParam("aid");
            String symbol = ar.reqParam("symbol");

            AttachmentRecord att = nGPage.findAttachmentByIDOrFail(aid);
            UserPage uPage = ar.getUserPage();
            ResourceEntity parent = uPage.getResourceFromSymbol(symbol);

            FolderAccessHelper fah = new FolderAccessHelper(ar);
            ResourceEntity child = parent.getChild(att.getDisplayName());
            boolean isSuccess = fah.copyAttachmentToRemote(nGPage, aid, child, false);

            if(!isSuccess){
                Properties params = new Properties();
                params.setProperty("aid", aid);
                params.setProperty("symbol", child.getSymbol());
                redirectBrowser(ar, "fileExists.htm", params);
            }
            else{
                redirectBrowser(ar, "listAttachments.htm");
            }
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.project.push.to.repository",
                    new Object[]{pageId,siteId} , ex);
        }
    }



    @RequestMapping(value = "/{userKey}/addFileAction.form", method = RequestMethod.POST)
    protected void addFileAction(@PathVariable String userKey,
            HttpServletRequest request,HttpServletResponse response,
            @RequestParam("fname") MultipartFile file)
            throws Exception {
        try{
            AuthRequest ar = getLoggedInAuthRequest(request, response, "message.unable.to.add.file");

            ar.req = request;
            UserManager.getUserProfileOrFail(userKey);

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
            String folderId = ar.reqParam("fid");
            String go = ar.reqParam("go");
            String action = ar.reqParam("action");

            if ("Cancel".equalsIgnoreCase(action))
            {
                redirectBrowser(ar,go);
                return;
            }
            if(!"Create New".equals(action))
            {
                throw new ProgramLogicError("Does not understand the operation: "+action);
            }

            FolderAccessHelper fah = new FolderAccessHelper(ar);
            fah.addFileInRepository(folderId, fileName, file.getBytes());
            redirectBrowser(ar,go);

        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.project.add.file.repository", null , ex);
        }
    }

    @RequestMapping(value = "/{siteId}/{pageId}/createConForExistingFile.htm", method = RequestMethod.GET)
    protected void createConForExistingFile(@PathVariable String siteId,
            @PathVariable String pageId, HttpServletRequest request,
            HttpServletResponse response) throws Exception {
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            showJSPMembers(ar, siteId, pageId, "CreateNewConnection");
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.project.create.connection.for.existing.file",
                    new Object[]{pageId,siteId} , ex);
        }
    }

    @RequestMapping(value = "/{siteId}/{pageId}/createConnectionToPushDoc.form", method = RequestMethod.POST)
    protected void createConnectionToPushDoc(@PathVariable String siteId,
            @PathVariable String pageId, HttpServletRequest request,
            HttpServletResponse response) throws Exception {
        try{
            AuthRequest ar = getLoggedInAuthRequest(request, response, "message.can.not.create.connection");
            ar.getCogInstance().getSiteByIdOrFail(siteId);
            ar.getCogInstance().getWSBySiteAndKeyOrFail( siteId, pageId );
            String action = ar.reqParam("action");
            String aid = ar.defParam("aid", null);

            if(action.equals("createConnection")){
                ConnectionSettings cSet = FolderAccessHelper.updateConnection(ar);
                Properties props = new Properties();
                props.setProperty("folderId", cSet.getId());
                props.setProperty("aid", aid);
                props.setProperty("path", "/");
                redirectBrowser(ar, "ChooseFolder.htm", props);
            }else{
                throw new ProgramLogicError("createConnectionToPushDoc.form does not understand the operation: "+ action);
            }


        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.project.create.connection.to.push.document",
                    new Object[]{pageId,siteId} , ex);
        }
    }

    @RequestMapping(value = "/{siteId}/{pageId}/fileExists.htm", method = RequestMethod.GET)
    protected void fileExists(@PathVariable String siteId,
            @PathVariable String pageId, HttpServletRequest request,
            HttpServletResponse response) throws Exception {
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            registerRequiredProject(ar, siteId, pageId);
            if (checkLoginMember(ar)) {
                return;
            }

            UserPage uPage = ar.getUserPage();
            ResourceEntity verifyEnt = uPage.getResourceFromSymbol(ar.reqParam("symbol"));

            request.setAttribute("aid", ar.reqParam("aid"));
            request.setAttribute("path", verifyEnt.getFullPath());
            request.setAttribute("folderId", verifyEnt.getFolderId());
            request.setAttribute("realRequestURL", ar.getRequestURL());
            showJSPMembers(ar, siteId, pageId, "FileExist");
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.project.check.file.exists.page",
                    new Object[]{pageId,siteId} , ex);
        }
    }

    @RequestMapping(value = "/{siteId}/{pageId}/fileExists.form", method = RequestMethod.POST)
    protected void fileExistsForm(@PathVariable String siteId,
            @PathVariable String pageId, HttpServletRequest request,
            HttpServletResponse response) throws Exception {
        AuthRequest ar = getLoggedInAuthRequest(request, response, "message.must.be.login.to.perform.action");
        NGPage nGPage = registerRequiredProject(ar, siteId, pageId);
        String aid = ar.reqParam("aid");
        String path = ar.reqParam("path");
        try{
            if(nGPage.isFrozen()){
                throw new NGException("nugen.project.freezed.msg",null);
            }

            String actionVal = ar.reqParam("actionVal");
            if(actionVal.equals("Cancel")){
                redirectBrowser(ar, "listAttachments.htm");
                return;
            }

            String action = ar.reqParam("action");
            String folderId = ar.reqParam("folderId");
            UserPage uPage = ar.getUserPage();
            ConnectionType cType = uPage.getConnectionOrFail(folderId);
            ResourceEntity remoteFile = cType.getResource(path);

            FolderAccessHelper fah = new FolderAccessHelper(ar);

            if(action.equals("link to existing document")){

                AttachmentHelper.linkToRemoteFile(ar,nGPage,aid,remoteFile);
                redirectBrowser(ar, "listAttachments.htm");
                return;

            }else if(action.equals("overwrite the existing document")){

                fah.copyAttachmentToRemote(nGPage, aid, remoteFile, true);
                redirectBrowser(ar, "listAttachments.htm");
                return;

            }else if(action.equals("store using different name")){
                String newName = ar.reqParam("newName");

                ResourceEntity parent = remoteFile.getParent();
                ResourceEntity child = parent.getChild(newName);

                fah.copyAttachmentToRemote(nGPage, aid, child, false);
                redirectBrowser(ar, "listAttachments.htm");
                return;

            }else if(action.equals("try again")){
                Properties props = new Properties();
                props.setProperty("aid", aid);
                redirectBrowser(ar, "listAttachments.htm", props);
                return;
            }else {
                throw new Exception("Don't understand action: "+action);
            }

        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.resolve.remote.file.exists",
                    new Object[]{aid, pageId, path} , ex);
        }
    }
}
