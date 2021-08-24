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

import java.net.URLEncoder;
import java.util.Enumeration;
import java.util.Hashtable;
import java.util.Properties;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.purplehillsbooks.weaver.AttachmentRecord;
import com.purplehillsbooks.weaver.AuthRequest;
import com.purplehillsbooks.weaver.NGWorkspace;
import com.purplehillsbooks.weaver.UserManager;
import com.purplehillsbooks.weaver.UserPage;
import com.purplehillsbooks.weaver.dms.ConnectionSettings;
import com.purplehillsbooks.weaver.dms.ConnectionType;
import com.purplehillsbooks.weaver.dms.FolderAccessHelper;
import com.purplehillsbooks.weaver.dms.ResourceEntity;
import com.purplehillsbooks.weaver.exception.NGException;
import com.purplehillsbooks.weaver.exception.ProgramLogicError;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.multipart.MultipartFile;

@Controller
public class RemoteLinkController extends BaseController {



    public String reqParamSpecial(Hashtable<String, String> params, String paramName)
        throws Exception
    {
        String val = params.get(paramName);
        if (val == null || val.length()==0) {
            throw new NGException("nugen.exception.param.required", new Object[]{paramName});
        }
        return val;
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
            NGWorkspace nGPage = registerRequiredProject(ar, siteId, pageId);
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
                redirectBrowser(ar, "DocsList.htm");
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


    @RequestMapping(value = "/{siteId}/{pageId}/fileExists.htm", method = RequestMethod.GET)
    protected void fileExists(@PathVariable String siteId,
            @PathVariable String pageId, HttpServletRequest request,
            HttpServletResponse response) throws Exception {
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            registerRequiredProject(ar, siteId, pageId);
            if (warnNotMember(ar)) {
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
        NGWorkspace nGPage = registerRequiredProject(ar, siteId, pageId);
        String aid = ar.reqParam("aid");
        String path = ar.reqParam("path");
        try{
            if(nGPage.isFrozen()){
                throw new NGException("nugen.project.freezed.msg",null);
            }

            String actionVal = ar.reqParam("actionVal");
            if(actionVal.equals("Cancel")){
                redirectBrowser(ar, "DocsList.htm");
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
                redirectBrowser(ar, "DocsList.htm");
                return;

            }else if(action.equals("overwrite the existing document")){

                fah.copyAttachmentToRemote(nGPage, aid, remoteFile, true);
                redirectBrowser(ar, "DocsList.htm");
                return;

            }else if(action.equals("store using different name")){
                String newName = ar.reqParam("newName");

                ResourceEntity parent = remoteFile.getParent();
                ResourceEntity child = parent.getChild(newName);

                fah.copyAttachmentToRemote(nGPage, aid, child, false);
                redirectBrowser(ar, "DocsList.htm");
                return;

            }else if(action.equals("try again")){
                Properties props = new Properties();
                props.setProperty("aid", aid);
                redirectBrowser(ar, "DocsList.htm", props);
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
