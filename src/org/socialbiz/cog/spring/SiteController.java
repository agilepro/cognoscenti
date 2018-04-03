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
import java.util.List;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.socialbiz.cog.AuthRequest;
import org.socialbiz.cog.Cognoscenti;
import org.socialbiz.cog.CustomRole;
import org.socialbiz.cog.HistoricActions;
import org.socialbiz.cog.NGBook;
import org.socialbiz.cog.NGPageIndex;
import org.socialbiz.cog.NGWorkspace;
import org.socialbiz.cog.SiteReqFile;
import org.socialbiz.cog.SiteRequest;
import org.socialbiz.cog.UserProfile;
import org.socialbiz.cog.exception.NGException;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.servlet.ModelAndView;
import org.springframework.web.servlet.view.RedirectView;

import com.purplehillsbooks.json.JSONObject;

@Controller
public class SiteController extends BaseController {

    
    ////////////////////// MAIN VIEWS ///////////////////////
    
    @RequestMapping(value = "/{siteId}/$/SiteAdmin.htm", method = RequestMethod.GET)
    public void SiteAdmin(@PathVariable String siteId,
            HttpServletRequest request, HttpServletResponse response)throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        showJSPMembers(ar,siteId,null,"SiteAdmin");
    }
    @RequestMapping(value = "/{siteId}/$/SiteStats.htm", method = RequestMethod.GET)
    public void SiteStats(@PathVariable String siteId,
            HttpServletRequest request, HttpServletResponse response)throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        showJSPLoggedIn(ar,siteId,null,"SiteStats");
    }
    
    @RequestMapping(value = "/{userKey}/requestAccount.htm", method = RequestMethod.GET)
    public void requestSite(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            if (checkLogin(ar)) {
                return;
            }
            if (needsToSetName(ar)) {
                streamJSP(ar, "requiredName");
            }
            if (ar.getCogInstance().getUserManager().getAllSuperAdmins(ar).size()==0) {
                showWarningView(ar, "nugen.missingSuperAdmin");
                return;
            }

            streamJSP(ar, "RequestAccount");
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.account.request.page", null, ex);
        }
    }

    @RequestMapping(value = "/{userKey}/accountRequests.form", method = RequestMethod.POST)
    public void requestNewSite(@PathVariable
            String userKey, HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            ar.assertLoggedIn("Must be logged in to request a site.");

            String action = ar.reqParam( "action" );

            if(action.equals( "Submit" )){

                JSONObject reqObj = new JSONObject();
                reqObj.put("siteId", ar.reqParam("accountID"));
                reqObj.put("siteName", ar.reqParam("accountName"));
                reqObj.put("purpose", ar.defParam("accountDesc",""));
                reqObj.put("requester", ar.getBestUserId());

                HistoricActions ha = new HistoricActions(ar);
                ha.createNewSiteRequest(reqObj);
            }
            else {
                throw new Exception("Method requestNewSite does not understand the action: "+action);
            }

            redirectBrowser(ar, "userAccounts.htm");
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.new.account.request", null , ex);
        }
    }

    
    @RequestMapping(value = "/siteRequest.json", method = RequestMethod.POST)
    public void siteRequest(HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try{
            JSONObject incoming = getPostedObject(ar);

            SiteRequest newSiteRequest = SiteReqFile.createNewSiteRequest(incoming, ar.getCogInstance());

            newSiteRequest.sendSiteRequestEmail(ar);
            
            sendJson(ar, newSiteRequest.getJSON());
        } catch(Exception ex){
            Exception ee = new Exception("Unable to a request a site", ex);
            streamException(ee, ar);
        }
    }
    
    
    @RequestMapping(value = "/su/takeOwnershipSite.json", method = RequestMethod.POST)
    public void takeOwnershipSite(HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        AuthRequest ar = AuthRequest.getOrCreate(request, response); 
        try{
            
            ar.assertLoggedIn("Must be logged in to take ownership of a site.");
            if(!ar.isSuperAdmin()){
                throw new Exception("Must be super admin in to take ownership of a site.");
            }
            UserProfile uProf = ar.getUserProfile();
            JSONObject incoming = getPostedObject(ar);
            if (!incoming.has("key")) {
                throw new Exception("Must specify 'key' of the site you want to take ownership of");
            }
            String siteKey = incoming.getString("key");
            Cognoscenti cog = ar.getCogInstance();
            NGBook site = cog.getSiteById(siteKey);
            if (site==null) {
                throw new Exception("Unable to find a site with the key: "+siteKey);
            }
            CustomRole owners = (CustomRole) site.getSecondaryRole();
            owners.addPlayerIfNotPresent(uProf.getAddressListEntry());
            if (!owners.isPlayer(uProf)) {
                throw new Exception("Failure to add to owners role this user: "+uProf.getUniversalId());
            }
            site.saveFile(ar, "adding super admin to site owners");
            
            JSONObject jo = site.getConfigJSON();
            sendJson(ar, jo);
        }catch(Exception ex){
            Exception ee = new Exception("Unable to take ownership of the site.", ex);
            streamException(ee, ar);
        }
    }

    @RequestMapping(value = "/su/garbageCollect.json", method = RequestMethod.POST)
    public void garbageCollect(HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        AuthRequest ar = AuthRequest.getOrCreate(request, response); 
        try{
            ar.assertLoggedIn("Must be logged to garbage collect a site.");
            if(!ar.isSuperAdmin()){
                throw new Exception("Must be super admin to garbage collect a site.");
            }
            JSONObject incoming = getPostedObject(ar);
            if (!incoming.has("key")) {
                throw new Exception("Must specify 'key' of the site you want to take ownership of");
            }
            String siteKey = incoming.getString("key");
            Cognoscenti cog = ar.getCogInstance();
            NGBook site = cog.getSiteById(siteKey);
            if (site==null) {
                throw new Exception("Unable to find a site with the key: "+siteKey);
            }
            String operation = "nothing";
            if (site.isDeleted()) {
                operation = "delete entire site";
                File folder = site.getFilePath();
                File cogFolder = folder.getParentFile();
                File siteFolder = cogFolder.getParentFile();
                if (!siteKey.equalsIgnoreCase(siteFolder.getName())) {
                    throw new Exception("Something strange: expected site named ("+siteKey+") but folder is "+siteFolder);
                }
                for (NGPageIndex ngpi : cog.getAllProjectsInSite(siteKey)) {
                    NGWorkspace ngw = ngpi.getWorkspace();
                    cog.eliminateIndexForWorkspace(ngw);
                }
                cog.eliminateIndexForSite(site);
                deleteRecursive(siteFolder);
            }
            else {
                
            }
            
            
            JSONObject jo = new JSONObject();
            jo.put("key", siteKey);
            jo.put("op", operation);
            jo.put("status", "success");
            sendJson(ar, jo);
        }catch(Exception ex){
            Exception ee = new Exception("Unable to garbage collect the site.", ex);
            streamException(ee, ar);
        }
    }
    
    private void deleteRecursive(File f) throws Exception {
        try {
            if (f.isDirectory()) {
                for (File c : f.listFiles()) {
                    deleteRecursive(c);
                }
            }
            if (!f.delete()) {
                throw new Exception("Delete command returned false for file: " + f);
            }
        } 
        catch (Exception e) {
            throw new Exception("Failed to delete the folder: " + f, e);
        }
    }

    @RequestMapping(value = "/{userKey}/acceptOrDeny.form", method = RequestMethod.POST)
    public void acceptOrDeny(HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            if (checkLogin(ar)) {
                return;
            }
            if(!ar.isSuperAdmin()){
                showWarningView(ar, "message.superadmin.required");
                return;
            }

            String requestId = ar.reqParam("requestId");
            SiteReqFile siteReqFile = new SiteReqFile(ar.getCogInstance());
            SiteRequest siteRequest = siteReqFile.getRequestByKey(requestId);
            if (siteRequest==null) {
                throw new NGException("nugen.exceptionhandling.not.find.account.request",new Object[]{requestId});
            }

            String action = ar.reqParam("action");
            String description = ar.defParam("description", "");
            HistoricActions ha = new HistoricActions(ar);
            if ("Granted".equals(action)) {
                ha.completeSiteRequest(siteRequest, true, description);
            }
            else if("Denied".equals(action)) {
                ha.completeSiteRequest(siteRequest, false, description);
            }
            else{
                throw new Exception("Unrecognized action '"+action+"' in acceptOrDeny.form");
            }
            
            //if we made any changes save them
            siteReqFile.save();

            //TODO: need a go parameter
            redirectBrowser(ar, "requestedAccounts.htm");
        }
        catch(Exception ex){
            throw new NGException("nugen.operation.fail.acceptOrDeny.account.request", null, ex);
        }
    }


    /**
    * This displays the page of site requests that have been made by others
    * and their current status.  Thus, only current executives and owners should see this.
    */
    @RequestMapping(value = "/{siteId}/$/roleRequest.htm", method = RequestMethod.GET)
    public void siteRoleRequest(@PathVariable String siteId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            if (checkLogin(ar)) {
                return;
            }
            prepareSiteView(ar, siteId);
            if (executiveCheckViews(ar)) {
                return;
            }
            streamJSP(ar, "leaf_accountRoleRequest");
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.account.role.request.page", new Object[]{siteId} , ex);
        }
    }


    @RequestMapping(value = "/{siteId}/$/accountListProjects.htm", method = RequestMethod.GET)
    public void showSiteTaskTab(@PathVariable String siteId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        showJSPLoggedIn(ar, siteId, null, "accountListProjects");
    }

    @RequestMapping(value = "/{siteId}/$/accountCreateProject.htm", method = RequestMethod.GET)
    public void accountCreateProject(@PathVariable String siteId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        showJSPMembers(ar, siteId, null, "accountCreateProject");
    }
    
    @RequestMapping(value = "/{siteId}/$/accountCloneProject.htm", method = RequestMethod.GET)
    public void accountCloneProject(@PathVariable String siteId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            if(checkLogin(ar)){
                return;
            }
            prepareSiteView(ar, siteId);
            if (executiveCheckViews(ar)) {
                return;
            }

            streamJSP(ar, "accountCloneProject");
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.account.process.page", new Object[]{siteId} , ex);
        }
    }

    @RequestMapping(value = "/{siteId}/$/SiteUsers.htm", method = RequestMethod.GET)
    public void SiteUsers(@PathVariable String siteId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            if (checkLogin(ar)) {
                return;
            }
            prepareSiteView(ar, siteId);
            if (executiveCheckViews(ar)) {
                return;
            }

            streamJSP(ar, "SiteUsers");
        }catch(Exception ex){
            throw new Exception("Unable to handle SiteUsers.htm for site '"+siteId+"'", ex);
        }
    }


    @RequestMapping(value = "/{siteId}/$/account_settings.htm", method = RequestMethod.GET)
    public ModelAndView showProjectSettingsTab(@PathVariable String siteId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        ModelAndView modelAndView = new ModelAndView(new RedirectView("personal.htm"));
        return modelAndView;
    }


    @RequestMapping(value = "/approveAccountThroughMail.htm", method = RequestMethod.GET)
    public ModelAndView approveSiteThroughEmail(
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        ModelAndView modelAndView = null;
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);

            String requestId = ar.reqParam("requestId");
            if (checkLogin(ar)) {
                return null;
            }
            if(!ar.isSuperAdmin()){
                showWarningView(ar, "message.superadmin.required");
                return null;
            }

            //Note: the approval page works in two modes.
            //1. if you are super admin, you have buttons to grant or deny
            //2. if you are not super admin, you can see status, but can not change status

            modelAndView = new ModelAndView("AccountApproval");
            modelAndView.addObject("requestId", requestId);
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.account.approve.through.mail", null, ex);
        }
        return modelAndView;
    }

    @RequestMapping(value = "/{siteId}/$/CreateAccountRole.form", method = RequestMethod.POST)
    public ModelAndView createRole(@PathVariable String siteId,HttpServletRequest request,
            HttpServletResponse response)
    throws Exception {
        try {
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            if (checkLogin(ar)) {
                return null;
            }
            NGBook site = prepareSiteView(ar, siteId);
            if (executiveCheckViews(ar)) {
                return null;
            }

            String roleName=ar.reqParam("rolename");
            String des=ar.reqParam("description");

            site.createRole(roleName,des);
            site.saveFile(ar, "Add New Role "+roleName+" to roleList");

            return new ModelAndView(new RedirectView("roleManagement.htm"));
        } catch (Exception e) {
            throw new NGException("nugen.operation.fail.account.create.role",new Object[]{siteId}, e);
        }
    }





    @RequestMapping(value = "/{siteId}/$/public.htm", method = RequestMethod.GET)
    public void sitePublic(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        redirectBrowser(ar, "accountListProjects.htm");
    }
    @RequestMapping(value = "/{siteId}/$/member.htm", method = RequestMethod.GET)
    public void member(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        redirectBrowser(ar, "accountListProjects.htm");
    }

    
    @RequestMapping(value = "/{siteId}/$/replaceUsers.json", method = RequestMethod.POST)
    public void getGoalHistory(@PathVariable String siteId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try{
            JSONObject incoming = getPostedObject(ar);
            String sourceUser = incoming.getString("sourceUser");
            String destUser = incoming.getString("destUser");
            List<NGPageIndex> listOfSpaces = null;
            {
                NGBook site = ar.getCogInstance().getSiteById(siteId);
                ar.setPageAccessLevels(site);
                ar.assertAdmin("Must be owner of a site to replace users.");
                listOfSpaces = ar.getCogInstance().getAllProjectsInSite(siteId);
                NGPageIndex.clearLocksHeldByThisThread();
            }
            int count = 0;
            for(NGPageIndex ngpi : listOfSpaces) {
                if (!ngpi.isProject()) {
                    continue;
                }
                NGWorkspace ngw = ngpi.getWorkspace();
                System.out.println("Changing '"+sourceUser+"' to '"+destUser+"' in ("+ngw.getFullName()+")");
                int found = ngw.replaceUserAcrossWorkspace(sourceUser, destUser);
                if (found>0) {
                    System.out.println("     found "+found+" and saving.");
                    ngpi.nextScheduledAction = ngw.nextActionDue();
                    ngw.save();
                }
                count += found;
                NGPageIndex.clearLocksHeldByThisThread();
            }
                    
            JSONObject jo = new JSONObject();
            jo.put("updated", count);
            sendJson(ar, jo);
        }catch(Exception ex){
            Exception ee = new Exception("Unable to replace users in site ("+siteId+")", ex);
            streamException(ee, ar);
        }
    }
    
    
    
}
