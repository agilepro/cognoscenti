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
import java.util.List;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.purplehillsbooks.weaver.AddressListEntry;
import com.purplehillsbooks.weaver.AuthRequest;
import com.purplehillsbooks.weaver.Cognoscenti;
import com.purplehillsbooks.weaver.CustomRole;
import com.purplehillsbooks.weaver.HistoricActions;
import com.purplehillsbooks.weaver.NGBook;
import com.purplehillsbooks.weaver.NGPageIndex;
import com.purplehillsbooks.weaver.NGWorkspace;
import com.purplehillsbooks.weaver.SiteMailGenerator;
import com.purplehillsbooks.weaver.SiteReqFile;
import com.purplehillsbooks.weaver.SiteRequest;
import com.purplehillsbooks.weaver.UserManager;
import com.purplehillsbooks.weaver.UserProfile;
import com.purplehillsbooks.weaver.WorkspaceStats;
import com.purplehillsbooks.weaver.exception.NGException;
import com.purplehillsbooks.weaver.mail.EmailSender;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import com.purplehillsbooks.json.JSONArray;
import com.purplehillsbooks.json.JSONException;
import com.purplehillsbooks.json.JSONObject;
import com.purplehillsbooks.streams.MemFile;
import com.purplehillsbooks.streams.StreamHelper;

@Controller
public class SiteController extends BaseController {


    ////////////////////// MAIN VIEWS ///////////////////////

    @RequestMapping(value = "/{siteId}/$/SiteAdmin.htm", method = RequestMethod.GET)
    public void siteAdmin(@PathVariable String siteId,
            HttpServletRequest request, HttpServletResponse response)throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        showJSPExecutives(ar,siteId,"SiteAdmin.jsp");
    }
    @RequestMapping(value = "/{siteId}/$/SiteStats.htm", method = RequestMethod.GET)
    public void siteStats(@PathVariable String siteId,
            HttpServletRequest request, HttpServletResponse response)throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        showJSPExecutives(ar,siteId,"SiteStats.jsp");
    }
    @RequestMapping(value = "/{siteId}/$/TemplateEdit.htm", method = RequestMethod.GET)
    public void templateEdit(@PathVariable String siteId,
            HttpServletRequest request, HttpServletResponse response)throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        showJSPExecutives(ar,siteId,"TemplateEdit.jsp");
    }



    @RequestMapping(value = "/{userKey}/accountRequests.form", method = RequestMethod.POST)
    public void requestNewSite(@PathVariable String userKey, 
                HttpServletRequest request, HttpServletResponse response)
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

            redirectBrowser(ar, "userSites.htm");
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.new.account.request", null , ex);
        }
    }


    @RequestMapping(value = "/{userKey}/siteRequest.json", method = RequestMethod.POST)
    public void siteRequest(@PathVariable String userKey, 
            HttpServletRequest request, HttpServletResponse response) {
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




    @RequestMapping(value = "/{siteId}/$/SiteWorkspaces.htm", method = RequestMethod.GET)
    public void showSiteTaskTab(@PathVariable String siteId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        showJSPSiteLiberal(ar, siteId, "SiteWorkspaces.jsp");
    }

    @RequestMapping(value = "/{siteId}/$/SiteCreateWorkspace.htm", method = RequestMethod.GET)
    public void accountCreateProject(@PathVariable String siteId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        showJSPExecutives(ar, siteId, "SiteCreateWorkspace.jsp");
    }


    @RequestMapping(value = "/{siteId}/$/SiteUsers.htm", method = RequestMethod.GET)
    public void SiteUsers(@PathVariable String siteId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            showJSPExecutives(ar,siteId,"SiteUsers.jsp");
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
            showJSPExecutives(ar,siteId,"SiteUserInfo.jsp");
        }catch(Exception ex){
            throw new Exception("Unable to handle SiteUserInfo.htm for site '"+siteId+"'", ex);
        }
    }

    @RequestMapping(value = "/{siteId}/$/SiteRoles.htm", method = RequestMethod.GET)
    public void siteRoles(@PathVariable String siteId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        showJSPExecutives(ar, siteId, "SiteRoles.jsp");
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
                if (!ngpi.isWorkspace()) {
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

            SiteMailGenerator eGen = ngb.createSiteMail();
            eGen.updateFromJSON(eGenInfo);

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
            List<AddressListEntry> userList = site.getSiteUsersList();
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
            WorkspaceStats ws = site.getRecentStats();

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
    
    @RequestMapping(value = "/{siteId}/$/SiteUserMap.json", method = RequestMethod.GET)
    public void siteUserMapGet(HttpServletRequest request,
            HttpServletResponse response, @PathVariable String siteId) throws Exception {

        AuthRequest ar = null;
        try{
            ar = AuthRequest.getOrCreate(request, response);
            if (!ar.isLoggedIn()) {
                throw new Exception("Must be logged in to get users");
            }
            Cognoscenti cog = ar.getCogInstance();
            NGBook site = cog.getSiteByIdOrFail(siteId);
            JSONObject userMap = site.getUserMap();
            sendJson(ar, userMap);
        }
        catch(Exception ex){
            Exception ee = new JSONException("Unable to get user map for site {0}", ex, siteId);
            streamException(ee, ar);
        }
    }
    @RequestMapping(value = "/{siteId}/$/SiteUserMap.json", method = RequestMethod.POST)
    public void siteUserMapPost(HttpServletRequest request,
            HttpServletResponse response, @PathVariable String siteId) throws Exception {

        AuthRequest ar = null;
        try{
            ar = AuthRequest.getOrCreate(request, response);
            if (!ar.isLoggedIn()) {
                throw new Exception("Must be logged in to get users");
            }
            Cognoscenti cog = ar.getCogInstance();
            NGBook site = cog.getSiteByIdOrFail(siteId);
            ar.setPageAccessLevels(site);
            if (!ar.isAdmin()) {
                throw new Exception("Must be administrator of site to update the permissions");
            }
            JSONObject userMapDelta = getPostedObject(ar);
            JSONObject userMap = site.updateUserMap(userMapDelta);
            sendJson(ar, userMap);
        }
        catch(Exception ex){
            Exception ee = new JSONException("Unable to update user map for site {0}", ex, siteId);
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

            JSONObject result = site.actuallyGarbageCollect();
            sendJson(ar, result);
        }
        catch(Exception ex){
            Exception ee = new JSONException("Unable to garbage collect for site '{0}'", ex, siteId);
            streamException(ee, ar);
        }
    }
    
    @RequestMapping(value = "/{siteId}/$/getChunkTemplate.chtml", method = RequestMethod.GET)
    public void getChunkTemplate(@PathVariable String siteId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try{
            ar.findAndSetSite( siteId );
            ar.assertExecutive("to retrieve the site template files you must be a site Executive");
            String templateName = ar.reqParam("t");
            File templateFile = ar.findChunkTemplate(templateName);
            StreamHelper.copyFileToOutput(templateFile, ar.resp.out);
            ar.resp.out.flush();
        }
        catch(Exception ex){
            Exception ee = new Exception("Unable to put the chunk template.", ex);
            streamException(ee, ar);
        }
    }
    @RequestMapping(value = "/{siteId}/$/putChunkTemplate.chtml", method = RequestMethod.PUT)
    public void putChunkTemplate(@PathVariable String siteId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try{
            NGBook site = ar.findAndSetSite( siteId );
            ar.assertExecutive("to edit the site template files you must be a site Executive");
            String templateName = ar.reqParam("t");
            File cogFolder = new File(site.getSiteRootFolder(), ".cog");
            File templateFile = new File(cogFolder, templateName);
            if (templateFile.exists()) {
                templateFile.delete();
            }
            MemFile mf = new MemFile();
            mf.fillWithInputStream(ar.req.getInputStream());
            if (mf.totalBytes()>5) {
                mf.outToFile(templateFile);
                ar.write("Template saved correctly: "+templateName);
                ar.flush();
            }
        }
        catch(Exception ex){
            Exception ee = new Exception("Unable to put the chunk template.", ex);
            streamException(ee, ar);
        }
    }    
    
    ///////////////////////// Eamil ///////////////////////

    @RequestMapping(value = "/{siteId}/$/QuerySiteEmail.json", method = RequestMethod.POST)
    public void queryEmail(@PathVariable String siteId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try{
            NGBook ngw = ar.getCogInstance().getSiteByIdOrFail(siteId);
            JSONObject posted = this.getPostedObject(ar);

            JSONObject repo = EmailSender.querySiteEmail(ngw, posted);

            sendJson(ar, repo);
        }catch(Exception ex){
            Exception ee = new Exception("Unable to get email", ex);
            streamException(ee, ar);
        }
    }

}
