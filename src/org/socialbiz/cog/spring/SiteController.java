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

import org.socialbiz.cog.AddressListEntry;
import org.socialbiz.cog.AuthRequest;
import org.socialbiz.cog.Cognoscenti;
import org.socialbiz.cog.CustomRole;
import org.socialbiz.cog.HistoricActions;
import org.socialbiz.cog.IdGenerator;
import org.socialbiz.cog.NGBook;
import org.socialbiz.cog.NGPageIndex;
import org.socialbiz.cog.NGWorkspace;
import org.socialbiz.cog.SiteMailGenerator;
import org.socialbiz.cog.SiteReqFile;
import org.socialbiz.cog.SiteRequest;
import org.socialbiz.cog.UserManager;
import org.socialbiz.cog.UserProfile;
import org.socialbiz.cog.WorkspaceStats;
import org.socialbiz.cog.exception.NGException;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.servlet.ModelAndView;
import org.springframework.web.servlet.view.RedirectView;

import com.purplehillsbooks.json.JSONArray;
import com.purplehillsbooks.json.JSONException;
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
            if (warnNotLoggedIn(ar)) {
                return;
            }
            if (needsToSetName(ar)) {
                streamJSP(ar, "RequiredName");
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
                reqObj.put("siteId", ar.reqParam("accountID").toLowerCase());
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

            SiteRequest newSiteRequest = SiteReqFile.createNewSiteRequest(incoming, ar);

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
        String siteKey = "???";
        try{
            ar.assertLoggedIn("Must be logged to garbage collect a site.");
            if(!ar.isSuperAdmin()){
                throw new Exception("Must be super admin to garbage collect a site.");
            }
            JSONObject incoming = getPostedObject(ar);
            if (!incoming.has("key")) {
                throw new Exception("Must specify 'key' of the site you want to take ownership of");
            }
            siteKey = incoming.getString("key");
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
                throw new Exception("Site '"+siteKey+"' must be deleted before it can be garbage collected");
            }


            JSONObject jo = new JSONObject();
            jo.put("key", siteKey);
            jo.put("op", operation);
            jo.put("status", "success");
            sendJson(ar, jo);
        }catch(Exception ex){
            Exception ee = new Exception("Unable to garbage collect the site "+siteKey, ex);
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
            if (warnNotLoggedIn(ar)) {
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
    @RequestMapping(value = "/{siteId}/$/SiteRoleRequest.htm", method = RequestMethod.GET)
    public void siteRoleRequest(@PathVariable String siteId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            if (warnNotLoggedIn(ar)) {
                return;
            }
            prepareSiteView(ar, siteId);
            if (executiveCheckViews(ar)) {
                return;
            }
            streamJSP(ar, "SiteRoleRequest");
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.account.role.request.page", new Object[]{siteId} , ex);
        }
    }


    @RequestMapping(value = "/{siteId}/$/SiteWorkspaces.htm", method = RequestMethod.GET)
    public void showSiteTaskTab(@PathVariable String siteId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        showJSPLoggedIn(ar, siteId, null, "SiteWorkspaces");
    }

    @RequestMapping(value = "/{siteId}/$/SiteCreateWorkspace.htm", method = RequestMethod.GET)
    public void accountCreateProject(@PathVariable String siteId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        showJSPMembers(ar, siteId, null, "SiteCreateWorkspace");
    }


    @RequestMapping(value = "/{siteId}/$/SiteUsers.htm", method = RequestMethod.GET)
    public void SiteUsers(@PathVariable String siteId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            showJSPMembers(ar,siteId,null,"SiteUsers");
        }catch(Exception ex){
            throw new Exception("Unable to handle SiteUsers.htm for site '"+siteId+"'", ex);
        }
    }
    @RequestMapping(value = "/{siteId}/$/SiteUserInfo.htm", method = RequestMethod.GET)
    public void SiteUserInfo(@PathVariable String siteId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            showJSPMembers(ar,siteId,null,"SiteUserInfo");
        }catch(Exception ex){
            throw new Exception("Unable to handle SiteUserInfo.htm for site '"+siteId+"'", ex);
        }
    }


    @RequestMapping(value = "/{siteId}/$/account_settings.htm", method = RequestMethod.GET)
    public ModelAndView showProjectSettingsTab(@PathVariable String siteId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        ModelAndView modelAndView = new ModelAndView(new RedirectView("Personal.htm"));
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
            if (warnNotLoggedIn(ar)) {
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
            if (warnNotLoggedIn(ar)) {
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

            return new ModelAndView(new RedirectView("RoleManagement.htm"));
        } catch (Exception e) {
            throw new NGException("nugen.operation.fail.account.create.role",new Object[]{siteId}, e);
        }
    }




    @RequestMapping(value = "/{siteId}/$/replaceUsers.json", method = RequestMethod.POST)
    public void replaceUsers(@PathVariable String siteId,
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

    @RequestMapping(value = "/{siteId}/$/assureUserProfile.json", method = RequestMethod.POST)
    public void assureUserProfile(@PathVariable String siteId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try{
            NGBook site = ar.getCogInstance().getSiteById(siteId);
            ar.setPageAccessLevels(site);
            ar.assertAdmin("Must be owner of a site to replace users.");

            JSONObject incoming = getPostedObject(ar);
            String userID = incoming.getString("uid");

            UserManager um = UserManager.getStaticUserManager();
            UserProfile user = um.lookupUserByAnyId(userID);

            if (user==null) {
            	user = um.createUserWithId(userID);
            	String name = user.getName();
            	if (name==null || name.length()==0) {
            		user.setName(userID);
            	}
        		um.saveUserProfiles();
            }

            sendJson(ar, user.getFullJSON());
        }catch(Exception ex){
            Exception ee = new Exception("Unable to replace users in site ("+siteId+")", ex);
            streamException(ee, ar);
        }
    }

    /**
     * This is the Site Administrator version of updating user settings
     */
    @RequestMapping(value = "/{siteId}/$/updateUserProfile.json", method = RequestMethod.POST)
    public void updateUserProfile(@PathVariable String siteId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try{
            NGBook site = ar.getCogInstance().getSiteById(siteId);
            ar.setPageAccessLevels(site);
            ar.assertAdmin("Must be owner of a site to replace users.");

            JSONObject incoming = getPostedObject(ar);
            String userId = incoming.getString("uid");

            UserManager um = UserManager.getStaticUserManager();
            UserProfile user = um.findUserByAnyIdOrFail(userId);

            user.updateFromJSON(incoming);
            um.saveUserProfiles();

            sendJson(ar, user.getFullJSON());
        }catch(Exception ex){
            Exception ee = new Exception("Unable to replace users in site ("+siteId+")", ex);
            streamException(ee, ar);
        }
    }
    /**
     * This is the Site Administrator version of adding user to role
     */
    @RequestMapping(value = "/{siteId}/$/manageUserRoles.json", method = RequestMethod.POST)
    public void manageUserRoles(@PathVariable String siteId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try{
            NGBook site = ar.getCogInstance().getSiteById(siteId);
            ar.setPageAccessLevels(site);
            ar.assertAdmin("Must be owner of a site to replace users.");

            JSONObject incoming = getPostedObject(ar);
            String userId = incoming.getString("uid");
            String workspace = incoming.getString("workspace");
            String roleName = incoming.getString("role");
            boolean add = incoming.getBoolean("add");

            UserManager um = UserManager.getStaticUserManager();
            UserProfile user = um.findUserByAnyIdOrFail(userId);

            NGPageIndex ngpi = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, workspace);
            NGWorkspace ngw = ngpi.getWorkspace();
            CustomRole roleObj = ngw.getRole(roleName);

            if (add) {
            	roleObj.addPlayer(user.getAddressListEntry());
            }
            else {
            	roleObj.removePlayer(user.getAddressListEntry());
            }

            ngw.save();

            sendJson(ar, user.getFullJSON());
        }catch(Exception ex){
            Exception ee = new Exception("Unable to replace users in site ("+siteId+")", ex);
            streamException(ee, ar);
        }
    }

    @RequestMapping(value = "/{siteId}/$/SiteMail.json", method = RequestMethod.POST)
    public void siteMail(@PathVariable String siteId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        String id = "";
        try{
            ar.assertSuperAdmin("Site Mail can be scheduled only by super administrators");
            NGPageIndex ngpi = ar.getCogInstance().getSiteByKey(siteId);
            NGBook ngb = ngpi.getSite();
            ar.setPageAccessLevels(ngb);
            JSONObject eGenInfo = getPostedObject(ar);

            id = eGenInfo.getString("id");
            SiteMailGenerator eGen = null;
            if ("~new~".equals(id)) {
                eGen = ngb.createSiteMail();
                eGen.setId(IdGenerator.generateKey());
                eGen.setState(SiteMailGenerator.SM_STATE_SCHEDULED);
            }
            else {
                eGen = ngb.getSiteMailOrFail(id);
            }

            //this is a non persistent flag in the body ... could be a URL parameter
            boolean deleteIt = eGenInfo.optBoolean("deleteIt");
            if (deleteIt) {
                ngb.deleteSiteMail(eGen.getId());
            }
            else {
                eGen.updateFromJSON(eGenInfo);
            }

            ngpi.nextScheduledAction = ngb.nextActionDue();
            //save, but don't update the recently changed date, site mail does not represent real site activity
            ngb.save();
            JSONObject repo = eGen.getJSON();
            sendJson(ar, repo);
        }
        catch(Exception ex){
            Exception ee = new Exception("Unable to update Email Generator "+id, ex);
            streamException(ee, ar);
        }
    }

    @RequestMapping(value = "/{siteId}/$/SitePeople.json", method = RequestMethod.GET)
    public void AllPeople(HttpServletRequest request,
            HttpServletResponse response, @PathVariable String siteId) throws Exception {

        AuthRequest ar = null;
        try{
            ar = AuthRequest.getOrCreate(request, response);
            if (!ar.isLoggedIn()) {
                throw new Exception("Must be logged in to get users");
            }

            NGBook site = ar.getCogInstance().getSiteByIdOrFail(siteId);

            JSONArray peopleList = new JSONArray();
            List<AddressListEntry> userList = site.getSiteUsersList(ar.getCogInstance());
            for (AddressListEntry ale : userList) {
                JSONObject person = ale.getJSON();
                peopleList.put(person);
            }
            JSONObject result = new JSONObject();
            result.put("people", peopleList);
            sendJson(ar, result);
        }
        catch(Exception ex){
            Exception ee = new Exception("Unable to generate people information.", ex);
            streamException(ee, ar);
        }
    }


    @RequestMapping(value = "/{siteId}/$/SiteStatistics.json", method = RequestMethod.GET)
    public void SiteStatistics(HttpServletRequest request,
            HttpServletResponse response, @PathVariable String siteId) throws Exception {

        AuthRequest ar = null;
        try{
            ar = AuthRequest.getOrCreate(request, response);
            if (!ar.isLoggedIn()) {
                throw new Exception("Must be logged in to get users");
            }
            NGBook site = ar.getCogInstance().getSiteByIdOrFail(siteId);

            String recalc = ar.defParam("recalc", null);
            if (recalc!=null) {
                site.flushUserCache();
            }
            WorkspaceStats ws = site.getRecentStats(ar.getCogInstance());

            JSONObject result = new JSONObject();
            result.put("siteId",  siteId);
            result.put("stats", ws.getJSON());
            sendJson(ar, result);
        }
        catch(Exception ex){
            Exception ee = new JSONException("Unable to generate site statistics for {0}", ex, siteId);
            streamException(ee, ar);
        }
    }

    @RequestMapping(value = "/{siteId}/$/GarbageCollect.json", method = RequestMethod.GET)
    public void GarbageCollect(HttpServletRequest request,
            HttpServletResponse response, @PathVariable String siteId) throws Exception {

        AuthRequest ar = null;
        try{
            ar = AuthRequest.getOrCreate(request, response);
            NGBook site = ar.getCogInstance().getSiteByIdOrFail(siteId);
            ar.setPageAccessLevels(site);
            ar.assertAdmin("Must be admin to garbage collect items");

            JSONObject result = site.actuallyGarbageCollect(ar.getCogInstance());
            sendJson(ar, result);
        }
        catch(Exception ex){
            Exception ee = new JSONException("Unable to garbage collect for site '{0}'", ex, siteId);
            streamException(ee, ar);
        }
    }

}
