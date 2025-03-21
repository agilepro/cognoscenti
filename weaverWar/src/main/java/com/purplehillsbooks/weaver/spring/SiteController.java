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
import java.net.URLEncoder;
import java.util.List;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import com.purplehillsbooks.weaver.AddressListEntry;
import com.purplehillsbooks.weaver.AuthRequest;
import com.purplehillsbooks.weaver.Cognoscenti;
import com.purplehillsbooks.weaver.CustomRole;
import com.purplehillsbooks.weaver.NGBook;
import com.purplehillsbooks.weaver.NGPageIndex;
import com.purplehillsbooks.weaver.NGWorkspace;
import com.purplehillsbooks.weaver.Ledger;
import com.purplehillsbooks.weaver.SiteMailGenerator;
import com.purplehillsbooks.weaver.SiteReqFile;
import com.purplehillsbooks.weaver.SiteRequest;
import com.purplehillsbooks.weaver.SiteUsers;
import com.purplehillsbooks.weaver.UserManager;
import com.purplehillsbooks.weaver.UserProfile;
import com.purplehillsbooks.weaver.WorkspaceStats;
import com.purplehillsbooks.weaver.exception.WeaverException;
import com.purplehillsbooks.weaver.mail.EmailSender;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import com.purplehillsbooks.json.JSONArray;
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
    @RequestMapping(value = "/{siteId}/$/SiteLedger.htm", method = RequestMethod.GET)
    public void siteLedger(@PathVariable String siteId,
            HttpServletRequest request, HttpServletResponse response)throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        showJSPExecutives(ar,siteId,"SiteLedger.jsp");
    }
    @RequestMapping(value = "/{siteId}/$/TemplateEdit.htm", method = RequestMethod.GET)
    public void templateEdit(@PathVariable String siteId,
            HttpServletRequest request, HttpServletResponse response)throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        showJSPExecutives(ar,siteId,"TemplateEdit.jsp");
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
                throw WeaverException.newBasic("Must be super admin in to take ownership of a site.");
            }
            UserProfile uProf = ar.getUserProfile();
            JSONObject incoming = getPostedObject(ar);
            if (!incoming.has("key")) {
                throw WeaverException.newBasic("Must specify 'key' of the site you want to take ownership of");
            }
            String siteKey = incoming.getString("key");
            Cognoscenti cog = ar.getCogInstance();
            NGBook site = cog.getSiteById(siteKey);
            if (site==null) {
                throw WeaverException.newBasic("Unable to find a site with the key: %s", siteKey);
            }
            CustomRole owners = (CustomRole) site.getSecondaryRole();
            owners.addPlayerIfNotPresent(uProf.getAddressListEntry());
            if (!owners.isPlayer(uProf)) {
                throw WeaverException.newBasic("Failure to add to owners role this user: %s", uProf.getUniversalId());
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
                throw WeaverException.newBasic("Must be super admin to garbage collect a site.");
            }
            JSONObject incoming = getPostedObject(ar);
            if (!incoming.has("key")) {
                throw WeaverException.newBasic("Must specify 'key' of the site you want to garbage collect");
            }
            siteKey = incoming.getString("key");
            Cognoscenti cog = ar.getCogInstance();
            NGBook site = cog.getSiteByIdOrFail(siteKey);
            String operation = "nothing";
            if (site.isDeleted()) {
                operation = "delete entire site";
                File folder = site.getFilePath();
                File cogFolder = folder.getParentFile();
                File siteFolder = cogFolder.getParentFile();
                if (!siteKey.equalsIgnoreCase(siteFolder.getName())) {
                    throw WeaverException.newBasic(
                        "Something strange: expected site named (%s) but folder is (%s)",
                        siteKey, siteFolder);
                }
                for (NGPageIndex ngpi : cog.getNonDelWorkspacesInSite(siteKey)) {
                    NGWorkspace ngw = ngpi.getWorkspace();
                    cog.eliminateIndexForWorkspace(ngw);
                }
                cog.eliminateIndexForSite(site);
                deleteRecursive(siteFolder);
            }
            else {
                throw WeaverException.newBasic("Site '"+siteKey+"' must be deleted before it can be garbage collected");
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
                throw WeaverException.newBasic("Delete command returned false for file: (%s)", f.getAbsolutePath());
            }
        }
        catch (Exception e) {
            throw WeaverException.newWrap("Failed to delete the folder: %s", e, f.getAbsolutePath());
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
            throw WeaverException.newWrap(
                "Unable to handle SiteUsers.htm for site '%s'", 
                ex, siteId);
        }
    }
    @RequestMapping(value = "/{siteId}/$/SiteUserInfo.htm", method = RequestMethod.GET)
    public void SiteUserInfo(@PathVariable String siteId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            String userKey = ar.reqParam("userKey");
            
            // check to see if the user is being referred to by a email address, or the user key
            // if a key exists, and not using the key, then redirect to the right address with key
            UserProfile uProf = UserManager.lookupUserByAnyId(userKey);
            if (uProf != null) {
                if (!userKey.equals(uProf.getKey())) {
                    ar.resp.sendRedirect("SiteUserInfo.htm?userKey="+URLEncoder.encode(uProf.getKey(), "UTF-8"));
                }
            }
            showJSPExecutives(ar,siteId,"SiteUserInfo.jsp");
        }catch(Exception ex){
            throw WeaverException.newWrap(
                "Unable to handle SiteUserInfo.htm for site '%s'", 
                ex, siteId);
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
                listOfSpaces = ar.getCogInstance().getNonDelWorkspacesInSite(siteId);
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
            {
                NGBook site = ar.getCogInstance().getSiteById(siteId);
                //force recalculation of statistics
                site.getUserMap();
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
            UserProfile user = UserManager.lookupUserByAnyId(userID);

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
     * This is the Site Administrator version of adding user to role.
     * It receives a workspace, role, and user to either add or remove that user
     */
    @RequestMapping(value = "/{siteId}/$/manageUserRoles.json", method = RequestMethod.POST)
    public void manageUserRoles(@PathVariable String siteId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try{
            Cognoscenti cog = ar.getCogInstance();
            NGBook site = cog.getSiteById(siteId);
            ar.setPageAccessLevels(site);
            ar.assertAdmin("Must be owner of a site to replace users.");

            JSONObject incoming = getPostedObject(ar);
            String userId = incoming.getString("uid");
            String workspace = incoming.getString("workspace");
            String roleName = incoming.getString("role");
            boolean add = incoming.getBoolean("add");
            boolean madeChange = false;

            UserManager um = UserManager.getStaticUserManager();
            UserProfile user = um.findUserByAnyIdOrFail(userId);

            NGPageIndex ngpi = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, workspace);
            NGWorkspace ngw = ngpi.getWorkspace();
            CustomRole roleObj = ngw.getRole(roleName);
            
            boolean isPresent = roleObj.isExpandedPlayer(user, ngw);

            if (add) {
                if (isPresent) {
                    System.out.println("ROLE: workspace ("+workspace+") role ("+roleName+") attempt to add when user is already present: "+userId);
                }
                else {
                    roleObj.addPlayer(user.getAddressListEntry());
                    madeChange = true;
                    ngw.save();
                    System.out.println("ROLE: workspace ("+workspace+") role ("+roleName+") added user: "+userId);
                }
            }
            else {
                if (isPresent) {
                	roleObj.removePlayerCompletely(user);
                    madeChange = true;
                	
                	// check to see if removed
                	roleObj = ngw.getRole(roleName);
                	if (roleObj.isExpandedPlayer(user, ngw)) {
                	    throw WeaverException.newBasic("The user did not actually get removed");
                	}
                	
                    ngw.save();
                    System.out.println("ROLE: workspace ("+workspace+") role ("+roleName+") removed user: "+userId);
                }
                else {

                    System.out.println("ROLE: workspace ("+workspace+") role ("+roleName+") attempt to remove when user is not there: "+userId);
                }
            }
            if (madeChange) {
                // everytime a role is changed, the site statistics are updated
                site.recalculateStats(cog);
            }
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
                throw WeaverException.newBasic("Must be logged in to get users");
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
                throw WeaverException.newBasic("Must be logged in to get users");
            }
            NGBook site = ar.getCogInstance().getSiteByIdOrFail(siteId);

            String recalc = ar.defParam("recalc", null);
            if (recalc!=null) {
                site.flushUserCache();
            }
            WorkspaceStats ws = site.getRecentStats(recalc!=null);

            JSONObject result = new JSONObject();
            result.put("siteId",  siteId);
            result.put("stats", ws.getJSON());
            sendJson(ar, result);
        }
        catch(Exception ex){
            Exception ee = WeaverException.newWrap("Unable to generate site statistics for %s", ex, siteId);
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
                throw WeaverException.newBasic("Must be logged in to get users");
            }
            Cognoscenti cog = ar.getCogInstance();
            NGBook site = cog.getSiteByIdOrFail(siteId);
            SiteUsers userMap = site.getUserMap();
            sendJson(ar, userMap.getJson());
        }
        catch(Exception ex){
            Exception ee = WeaverException.newWrap("Unable to get user map for site %s", ex, siteId);
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
                throw WeaverException.newBasic("Must be logged in to get users");
            }
            Cognoscenti cog = ar.getCogInstance();
            NGBook site = cog.getSiteByIdOrFail(siteId);
            ar.setPageAccessLevels(site);
            if (!ar.isAdmin()) {
                throw WeaverException.newBasic("Must be administrator of site to update the permissions");
            }
            JSONObject userMapDelta = getPostedObject(ar);
            SiteUsers userMap = site.updateUserMap(userMapDelta);
            sendJson(ar, userMap.getJson());
        }
        catch(Exception ex){
            Exception ee = WeaverException.newWrap("Unable to update user map for site %s", ex, siteId);
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
            site.recalculateStats(ar.getCogInstance());
            sendJson(ar, result);
        }
        catch(Exception ex){
            Exception ee = WeaverException.newWrap("Unable to garbage collect for site '%s'", ex, siteId);
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
            NGBook site = ar.getCogInstance().getSiteByIdOrFail(siteId);
            JSONObject posted = this.getPostedObject(ar);

            JSONObject repo = EmailSender.querySiteEmail(site, posted);

            sendJson(ar, repo);
        }catch(Exception ex){
            Exception ee = new Exception("Unable to get email", ex);
            streamException(ee, ar);
        }
    }

    @RequestMapping(value = "/su/updateCharge.json", method = RequestMethod.POST)
    public void updateCharge(HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try{
            ar.assertSuperAdmin("Site changes can only be calculated by super admin");
            JSONObject posted = this.getPostedObject(ar);

            int year = posted.getInt("year");
            int month = posted.getInt("month");
            double amount = posted.getDouble("amount");
            String siteId = posted.getString("site");

            NGBook site = ar.getCogInstance().getSiteByIdOrFail(siteId);
            
            Ledger ledger = site.getLedger();
            ledger.setChargeAmt(year, month, amount);
            site.saveLedger(ledger);

            sendJson(ar, ledger.generateJson());
        }catch(Exception ex){
            Exception ee = new Exception("Unable to calculate site charges", ex);
            streamException(ee, ar);
        }
    }
    
    @RequestMapping(value = "/su/recordPayment.json", method = RequestMethod.POST)
    public void recordPayment(HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        String siteId = "UNKNOWN";
        try{
            ar.assertSuperAdmin("Must be super admin to create payment record.");
            JSONObject posted = getPostedObject(ar);
            siteId = posted.getString("site");
            
            int year = posted.getInt("year");
            int month = posted.getInt("month");
            int day = posted.getInt("day");
            double amount = posted.getDouble("amount");
            String detail = posted.getString("detail");
            if (detail == null || detail.isEmpty()) {
                throw WeaverException.newBasic(
                    "Field 'detail' is empty.  When setting a payment include detail about the payment.");
            }
            
            NGBook site = ar.getCogInstance().getSiteByIdOrFail(siteId);
            Ledger ledger = site.getLedger();
            
            long timestamp = Ledger.getTimestamp(year, month, day);
            ledger.createPayment(timestamp, amount, detail);
            site.saveLedger(ledger);

            JSONObject jo = ledger.generateJson();
            sendJson(ar, jo);
        }catch(Exception ex){
            Exception ee = new Exception("Unable to create payment record for site "+siteId, ex);
            streamException(ee, ar);
        }
    }

    @RequestMapping(value = "/su/clearAllSiteCharges.json", method = RequestMethod.POST)
    public void clearAllSiteCharges(HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try{
            ar.assertSuperAdmin("Site charges can only be cleared by super admin");
            JSONObject posted = this.getPostedObject(ar);

            int year = posted.getInt("year");
            int month = posted.getInt("month");

            JSONArray list = new JSONArray();
            for (NGBook site : NGBook.getAllSites()) {
                Ledger ledger = site.getLedger();
                ledger.setChargeAmt(year, month, 0);
                list.put(site.getKey());
            }
            
            JSONObject rslt = new JSONObject();
            rslt.put("list", list);

            sendJson(ar, rslt);
        }catch(Exception ex){
            Exception ee = new Exception("Unable to calculate site charges", ex);
            streamException(ee, ar);
        }
    }

}
