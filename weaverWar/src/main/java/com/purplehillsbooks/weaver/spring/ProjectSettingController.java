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
import java.util.ArrayList;
import java.util.List;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.purplehillsbooks.weaver.AccessControl;
import com.purplehillsbooks.weaver.AddressListEntry;
import com.purplehillsbooks.weaver.AuthRequest;
import com.purplehillsbooks.weaver.Cognoscenti;
import com.purplehillsbooks.weaver.CustomRole;
import com.purplehillsbooks.weaver.LabelRecord;
import com.purplehillsbooks.weaver.NGBook;
import com.purplehillsbooks.weaver.NGContainer;
import com.purplehillsbooks.weaver.NGLabel;
import com.purplehillsbooks.weaver.NGRole;
import com.purplehillsbooks.weaver.NGWorkspace;
import com.purplehillsbooks.weaver.RoleInvitation;
import com.purplehillsbooks.weaver.RoleRequestRecord;
import com.purplehillsbooks.weaver.UserManager;
import com.purplehillsbooks.weaver.UserProfile;
import com.purplehillsbooks.weaver.mail.EmailGenerator;
import com.purplehillsbooks.weaver.mail.EmailSender;
import com.purplehillsbooks.weaver.mail.MailInst;
import com.purplehillsbooks.weaver.mail.OptOutAddr;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import com.purplehillsbooks.json.JSONArray;
import com.purplehillsbooks.json.JSONObject;

@Controller
public class ProjectSettingController extends BaseController {



    //////////////////////// MAIN VIEWS ////////////////////////////
    
    @RequestMapping(value = "/{siteId}/{pageId}/LimitedAccess.htm", method = RequestMethod.GET)
    public void LimitedAccess(@PathVariable String siteId,
            @PathVariable String pageId, HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        NGWorkspace ngw = registerWorkspaceRequired(ar, siteId, pageId);
        showJSPDepending(ar, ngw, "LimitedAccess.jsp", true);
    }

    @RequestMapping(value = "/{siteId}/{pageId}/AddSomething.htm", method = RequestMethod.GET)
    public void AddSomething(@PathVariable String siteId,
            @PathVariable String pageId, HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        NGWorkspace ngw = ar.findAndSetWorkspace(siteId, pageId);
        if (ngw.isFrozen()) {
            showJSPMembers(ar, siteId, pageId, "WarningFrozen.jsp");
            return;
        }
        showJSPMembers(ar, siteId, pageId, "AddSomething.jsp");
    }

    @RequestMapping(value = "/{siteId}/{pageId}/Personal.htm", method = RequestMethod.GET)
    public void showPersonalTab(@PathVariable String siteId,
            @PathVariable String pageId, HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        showJSPMembers(ar, siteId, pageId, "Personal.jsp");
    }

    @RequestMapping(value = "/{siteId}/{pageId}/RoleManagement.htm", method = RequestMethod.GET)
    public void roleManagement(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        showJSPMembers(ar, siteId, pageId, "RoleManagement.jsp");
    }
    
    @RequestMapping(value = "/{siteId}/{pageId}/MultiInvite.htm", method = RequestMethod.GET)
    public void MultiInvite(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        showJSPMembers(ar, siteId, pageId, "MultiInvite.jsp");
    }

    @RequestMapping(value = "/{siteId}/{pageId}/RoleDefine.htm", method = RequestMethod.GET)
    public void roleDefine(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        showJSPMembers(ar, siteId, pageId, "RoleDefine.jsp");
    }

    @RequestMapping(value = "/{siteId}/{pageId}/RoleNomination.htm", method = RequestMethod.GET)
    public void roleNomination(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        showJSPMembers(ar, siteId, pageId, "RoleNomination.jsp");
    }

    @RequestMapping(value = "/{siteId}/{pageId}/RoleRequest.htm", method = RequestMethod.GET)
    public void remindersTab(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        showJSPMembers(ar, siteId, pageId, "RoleRequest.jsp");
    }


    @RequestMapping(value = "/{siteId}/{pageId}/AdminSettings.htm", method = RequestMethod.GET)
    public void showAdminTab(@PathVariable String siteId,
            @PathVariable String pageId, HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        registerWorkspaceRequired(ar, siteId, pageId);
        if (ar.isAdmin()) {
            streamJSP(ar, "AdminSettings.jsp");
        }
        else {
            showJSPMembers(ar, siteId, pageId, "AdminSettings.jsp");
        }
    }
    @RequestMapping(value = "/{siteId}/{pageId}/AdminStats.htm", method = RequestMethod.GET)
    public void showAdminStats(@PathVariable String siteId,
            @PathVariable String pageId, HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        registerWorkspaceRequired(ar, siteId, pageId);
        showJSPMembers(ar, siteId, pageId, "AdminStats.jsp");
    }
    @RequestMapping(value = "/{siteId}/{pageId}/AdminAPI.htm", method = RequestMethod.GET)
    public void showAdminAPI(@PathVariable String siteId,
            @PathVariable String pageId, HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        registerWorkspaceRequired(ar, siteId, pageId);
        showJSPMembers(ar, siteId, pageId, "AdminAPI.jsp");
    }

    @RequestMapping(value = "/{siteId}/{pageId}/LabelList.htm", method = RequestMethod.GET)
    public void labelList(
            @PathVariable String pageId, @PathVariable String siteId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        showJSPMembers(ar, siteId, pageId, "LabelList.jsp");
    }

    @RequestMapping(value = "/{siteId}/{pageId}/EmailCreated.htm", method = RequestMethod.GET)
    public void getEmailRecordsPage( @PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        showJSPMembers(ar, siteId, pageId, "EmailCreated.jsp");
    }

    @RequestMapping(value = "/{siteId}/{pageId}/EmailSent.htm", method = RequestMethod.GET)
    public void emailSent( @PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        showJSPMembers(ar, siteId, pageId, "EmailSent.jsp");
    }


    @RequestMapping(value = "/{siteId}/{pageId}/EmailMsg.htm", method = RequestMethod.GET)
    public void emailMsg( @PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        NGWorkspace ngw = registerWorkspaceRequired(ar, siteId, pageId);
        long msgId = ar.reqParamLong("msg");
        MailInst emailMsg = EmailSender.findEmailById(ngw, msgId);
        if (emailMsg==null) {
            showWarningDepending(ar, "Unable to find an existing email message with id: "+msgId);
            return;
        }
        showJSPDepending(ar, ngw, "EmailMsg.jsp", true);
    }




    @RequestMapping(value = "/{siteId}/{pageId}/SendNote.htm", method = RequestMethod.GET)
    public void sendNote(
            @PathVariable String pageId, @PathVariable String siteId,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        NGWorkspace ngw = registerWorkspaceRequired(ar, siteId, pageId);
        String eGenId = ar.defParam("id", null);
        if (eGenId!=null) {
        EmailGenerator eGen = ngw.getEmailGeneratorOrFail(eGenId);
            if (eGen==null) {
                showWarningDepending(ar, "Can not find an email generator with the id: "+eGenId);
            }
        }
        showJSPMembers(ar, siteId, pageId, "SendNote.jsp");
    }


    @RequestMapping(value = "/{siteId}/{pageId}/sendNoteView.htm", method = RequestMethod.GET)
    public void sendNoteView(
            @PathVariable String pageId, @PathVariable String siteId,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        showJSPMembers(ar, siteId, pageId, "sendNoteView.jsp");
    }



    @RequestMapping(value = "/{siteId}/{pageId}/RoleInvite.htm", method = RequestMethod.GET)
    public void RoleInvite(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        showJSPMembers(ar, siteId, pageId, "RoleInvite.jsp");
    }





    //////////////////////// REST REQUESTS ///////////////////////////

    @RequestMapping(value = "/{siteId}/{pageId}/personalUpdate.json", method = RequestMethod.POST)
    public void personalUpdate(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        String op = "Unknown";
        try{
            NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail( siteId, pageId ).getWorkspace();
            ar.setPageAccessLevels(ngw);
            ar.assertLoggedIn("Must be logged in to set personal settings.");
            JSONObject personalInfo = getPostedObject(ar);
            UserProfile up = ar.getUserProfile();
            String siteWorkspaceCombo = ngw.getSiteKey()+"|"+ngw.getKey();

            op = personalInfo.getString("op");
            UserManager userManager = ar.getCogInstance().getUserManager();
            if ("SetWatch".equals(op)) {
                up.setWatch(siteWorkspaceCombo);
                userManager.saveUserProfiles();
            }
            else if ("SetReviewTime".equals(op)) {
                up.setReviewTime(siteWorkspaceCombo, ar.nowTime);
                userManager.saveUserProfiles();
            }
            else if ("ClearWatch".equals(op)) {
                up.clearWatch(siteWorkspaceCombo);
                userManager.saveUserProfiles();
            }
            else if ("SetNotify".equals(op)) {
                up.setNotification(siteWorkspaceCombo);
                userManager.saveUserProfiles();
            }
            else if ("ClearNotify".equals(op)) {
                up.clearNotification(siteWorkspaceCombo);
                userManager.saveUserProfiles();
            }
            else if ("SetEmailMute".equals(op)) {
                ngw.getMuteRole().addPlayerIfNotPresent(up.getAddressListEntry());
                ngw.save(); //just save flag, don't mark workspace as changed
            }
            else if ("ClearEmailMute".equals(op)) {
                ngw.getMuteRole().removePlayerCompletely(up);
                ngw.save(); //just save flag, don't mark workspace as changed
            }
            else {
                throw new Exception("Unable to understand the operation "+op);
            }

            JSONObject repo = new JSONObject();
            repo.put("wsSettings", up.getWorkspaceSettings(siteWorkspaceCombo));
            sendJson(ar, repo);
        }
        catch(Exception ex){
            Exception ee = new Exception("Unable to update the user setting for "+op+" on workspace "+pageId, ex);
            streamException(ee, ar);
        }
    }
    
    @RequestMapping(value = "/{siteId}/{pageId}/setPersonal.json", method = RequestMethod.POST)
    public void setPersonal(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try{
            NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail( siteId, pageId ).getWorkspace();
            ar.setPageAccessLevels(ngw);
            ar.assertLoggedIn("Must be logged in to set personal settings.");
            JSONObject personalInfo = getPostedObject(ar);
            UserProfile up = ar.getUserProfile();
            
            ngw.updatePersonalWorkspaceSettings(up, personalInfo);

            JSONObject repo = ngw.getPersonalWorkspaceSettings(up);
            sendJson(ar, repo);
        }
        catch(Exception ex){
            Exception ee = new Exception("Unable to update user setting for workspace "+pageId, ex);
            streamException(ee, ar);
        }
    }    

    @RequestMapping(value = "/{siteId}/{pageId}/rolePlayerUpdate.json", method = RequestMethod.POST)
    public void rolePlayerUpdate(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        String op = "Unknown";
        String roleId= "Unknown";
        try{
            NGWorkspace ngw = registerWorkspaceRequired(ar, siteId, pageId );
            ar.setPageAccessLevels(ngw);
            ar.assertLoggedIn("Must be logged in to manipuate roles.");
            ar.assertNotFrozen(ngw);
            JSONObject personalInfo = getPostedObject(ar);
            UserProfile up = ar.getUserProfile();

            op = personalInfo.getString("op");
            roleId = personalInfo.getString("roleId");

            NGRole role = ngw.getRoleOrFail(roleId);
            AddressListEntry ale = up.getAddressListEntry();
            RoleRequestRecord rrr = ngw.getRoleRequestRecord(role.getName(),up.getUniversalId());


            if ("Join".equals(op)) {
                if (role.isPlayer(up)) {
                    //don't do anything
                }
                else {
                    String requestDesc = "";
                    if (personalInfo.has("desc")) {
                        requestDesc = personalInfo.getString("desc");
                    }
                    rrr = ngw.createRoleRequest(roleId, up.getUniversalId(), ar.nowTime, up.getUniversalId(), requestDesc);

                    NGRole adminRole = ngw.getSecondaryRole();
                    boolean hasSpecialPermission = adminRole.isPlayer(ale);

                    if (!hasSpecialPermission && ngw instanceof NGWorkspace)  {
                        NGRole executiveRole = ngw.getSite().getRole("Executives");//getSecondaryRole();
                        hasSpecialPermission = executiveRole.isPlayer(ale);
                    }

                    //Note: if there is no administrator for the project, then ANYONE is allowed to
                    //sign up as ANY role.  Once grabbed, that person is administrator.
                    boolean noAdmin = adminRole.getDirectPlayers().size()==0;

                    if(hasSpecialPermission || noAdmin ) {
                        rrr.setState("Approved");
                        ngw.addPlayerToRole(roleId,up.getUniversalId());
                    }
                    else{
                        sendRoleRequestEmail(ar,rrr,ngw);
                    }
                }
            }
            else if ("Leave".equals(op)) {
                if (role.isPlayer(up)) {
                    role.removePlayer(ale);
                }
                if (rrr!=null && !rrr.isCompleted()) {
                    rrr.setResponseDescription("Cancelled by user");
                    rrr.setCompleted(true);
                }
            }
            else {
                throw new Exception("Unable to understand the operation "+op);
            }

            ngw.getSite().flushUserCache();  //calculate the users again
            ngw.saveFile(ar, "Updated role "+roleId);
            JSONObject repo = new JSONObject();
            repo.put("op",  op);
            repo.put("success",  true);
            repo.put("player", role.isPlayer(up));
            RoleRequestRecord rrr2 = ngw.getRoleRequestRecord(role.getName(),up.getUniversalId());
            repo.put("reqPending", (rrr2!=null && !rrr2.isCompleted()));
            sendJson(ar, repo);
        }
        catch(Exception ex){
            Exception ee = new Exception("Unable to update the user setting for "+op+" on role "+roleId+" workspace  "+pageId, ex);
            streamException(ee, ar);
        }
    }


    private static void sendRoleRequestEmail(AuthRequest ar,
            RoleRequestRecord roleRequestRecord, NGWorkspace ngw)
            throws Exception {
        Cognoscenti cog = ar.getCogInstance();
        UserProfile up = ar.getUserProfile();
        if (up == null) {
            throw new Exception(
                    "Program Logic Error: only logged in users can request to join a role, and got such a request when there appears to be nobody logged in");
        }

        //This is a magic URL that contains a magic token that will allow people
        //who are not logged in, to approve this request.
        String resourceURL = ar.getResourceURL(ngw, "approveOrRejectRoleReqThroughMail.htm")
            +"?requestId="  + roleRequestRecord.getRequestId()
            + "&isAccessThroughEmail=yes&"
            + AccessControl.getAccessRoleRequestParams(ngw, roleRequestRecord);

        List<OptOutAddr> initialList = new ArrayList<OptOutAddr>();
        OptOutAddr.appendUsersFromRole(ngw, ngw.getPrimaryRole().getName(), initialList);
        OptOutAddr.appendUsersFromRole(ngw, ngw.getSecondaryRole().getName(), initialList);

        JSONObject data = new JSONObject();
        data.put("baseURL", ar.baseURL);
        data.put("requester", ar.getUserProfile().getJSON());
        data.put("wsBaseURL", ar.baseURL + ar.getWorkspaceBaseURL(ngw));
        data.put("wsName", ngw.getFullName());
        data.put("roleName", roleRequestRecord.getRoleName());
        data.put("comment", roleRequestRecord.getRequestDescription());
        data.put("resourceURL", ar.baseURL + resourceURL);

        File templateFile = cog.getConfig().getFileFromRoot("email/RoleRequest.chtml");

        MailInst msg = ngw.createMailInst();
        msg.setSubject("Role Requested by " + ar.getBestUserId());
        AddressListEntry from =  ar.getUserProfile().getAddressListEntry();
        
        // filter out users that who have no profile and have never logged in.
        // Only send this request to real users, not just email addresses
        for (OptOutAddr ooa : initialList) {
            if (ooa.isUserWithProfile()) {
                data.put("optout", ooa.getUnsubscribeJSON(ar));
                msg.setBodyFromTemplate(templateFile, data, ooa);
                EmailSender.generalMailToOne(msg, from, ooa);
            }
        }
    }


    @RequestMapping(value = "/{siteId}/{pageId}/roleRequestResolution.json", method = RequestMethod.POST)
    public void roleRequestResolution(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        String op = "Unknown";
        String roleName= "Unknown";
        try{
            NGWorkspace ngw = registerWorkspaceRequired(ar, siteId, pageId );
            ar.setPageAccessLevels(ngw);
            ar.assertNotFrozen(ngw);
            JSONObject personalInfo = getPostedObject(ar);
            op = personalInfo.getString("op");
            String roleRequestId = personalInfo.getString("rrId");
            RoleRequestRecord rrr = ngw.getRoleRequestRecordById(roleRequestId);
            roleName = rrr.getRoleName();
            boolean canAccess = AccessControl.canAccessRoleRequest(ar, ngw, rrr);

            if (!canAccess) {
                throw new Exception("Unable to access that RoleRequestRecord.  You might need to be logged in.");
            }

            if ("Approve".equals(op)) {
                String requestedBy = rrr.getRequestedBy();
                ngw.addPlayerToRole(roleName,requestedBy);
                rrr.setState("Approved");
                rrr.setCompleted(true);
            }
            else if ("Reject".equals(op)) {
                rrr.setState("Rejected");
                rrr.setCompleted(true);
            }
            else {
                throw new Exception("roleRequestResolution doesn't understand the request for "+op);
            }

            if (ar.isLoggedIn()) {
                ngw.saveFile(ar, "Resolved role "+roleName);
            }
            else {
                ngw.saveWithoutAuthenticatedUser("Unknown", ar.nowTime, "Resolved role "+roleName, ar.getCogInstance());
            }
            JSONObject repo = new JSONObject();
            repo.put("state", rrr.getState());
            repo.put("completed", rrr.isCompleted());
            sendJson(ar, repo);
        }
        catch(Exception ex){
            Exception ee = new Exception("Unable to update the user setting for "+op+" on role "+roleName+" workspace  "+pageId, ex);
            streamException(ee, ar);
        }
    }



    //This works for Sites as well as Projects
    @RequestMapping(value = "/{siteId}/{pageId}/roleUpdate.json", method = RequestMethod.POST)
    public void roleUpdate(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        String op = "";
        boolean saveSite = false;
        NGBook site = null;
        try{
            NGContainer ngc = registerSiteOrProject(ar, siteId, pageId );
            //get this early so that the error message is proper
            op = ar.reqParam("op");
            ar.setPageAccessLevels(ngc);
            
            if (ngc instanceof NGWorkspace) {
                ar.assertUpdateWorkspace("Must be a member to modify roles.");
            }
            else {
                ar.assertExecutive("Must be an executive of site to modify roles.");
            }
            ar.assertNotReadOnly("Cannot modify roles");
            JSONObject roleInfo = getPostedObject(ar);
            JSONObject repo = new JSONObject();
            System.out.println("UPDATEROLE: "+roleInfo.toString());

            if ("Update".equals(op)) {
                ar.assertNotFrozen(ngc);
                String roleName = roleInfo.getString("name");
                CustomRole role = ngc.getRoleOrFail(roleName);
                String priorLinkedRole = role.getLinkedRole();
                role.updateFromJSON(roleInfo);
                if (ngc instanceof NGWorkspace) {

                    //if there is a linked role on the site, then use the same
                    //posted information to update that
                    String linkedRole = role.getLinkedRole();
                    System.out.println("ROLE: "+roleName+", LinkedRole: "+linkedRole);
                    if (linkedRole!=null && linkedRole.length()>0) {
                        String actualName = "~"+linkedRole;
                        site = ((NGWorkspace)ngc).getSite();
                        CustomRole siteRole = site.getRole(actualName);
                        boolean wasCreated = false;
                        if (siteRole==null) {
                            siteRole = site.createRole(actualName, role.getDescription());
                            //make a log trace when a role is created
                            System.out.println("NEW ROLE in site: "+site.getFullName()+" named: "+actualName
                                    +". because of link from "+ngc.getFullName());
                            wasCreated = true;
                        }
                        if (linkedRole.equals(priorLinkedRole) || wasCreated) {
                            //if the name is the same as before, or if it was just created
                            //push these changed to the site version of the role
                            //Don't do this just when setting the link name for existing role
                            siteRole.updateFromJSON(roleInfo);
                            saveSite = true;
                        }
                        //to complete, pull the current
                        //state of the site role to this role.
                        role.updateFromJSON(siteRole.getJSON());
                    }

                    ((NGWorkspace)ngc).getSite().flushUserCache();  //calculate the users again
                }
                repo = role.getJSONDetail();
            }
            else if ("Create".equals(op)) {
                ar.assertNotFrozen(ngc);
                CustomRole role = ngc.createRole(roleInfo.getString("name"), "");
                role.updateFromJSON(roleInfo);
                repo = role.getJSONDetail();
            }
            else if ("Delete".equals(op)) {
                ar.assertNotFrozen(ngc);
                ngc.deleteRole(roleInfo.getString("name"));
                repo.put("success",  true);
            }
            else if ("GetAll".equals(op)) {
                JSONArray ja = new JSONArray();
                for (CustomRole ngr : ngc.getAllRoles()) {
                    ja.put(ngr.getJSONDetail());
                }
                repo.put("roles", ja);
            }

            if (ngc instanceof NGWorkspace) {
                ((NGWorkspace)ngc).saveModifiedWorkspace(ar, op + " Role ");
            }
            else {
                ((NGBook)ngc).saveModifiedSite(ar, op + " Role ");
            }
            if (saveSite & site!=null) {
                site.save();
            }
            sendJson(ar, repo);
        }catch(Exception ex){
            Exception ee = new Exception("Unable to '"+op+"' the role.", ex);
            streamException(ee, ar);
        }
    }

    @RequestMapping(value = "/{siteId}/{pageId}/getAllLabels.json", method = RequestMethod.GET)
    public void getAllLabels(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try{
            NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail( siteId, pageId ).getWorkspace();
            JSONObject res = new JSONObject();
            res.put("list", ngw.getJSONLabels());
            sendJson(ar, res);
        }
        catch(Exception ex){
            Exception ee = new Exception("Unable to get all labels from the workspace.", ex);
            streamException(ee, ar);
        }
    }
    
    
    //pass the parameter 'role' to see if logged in user is a player of that role
    @RequestMapping(value = "/{siteId}/{pageId}/isRolePlayer.json", method = RequestMethod.GET)
    public void isRolePlayer(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        String roleName = "";
        try{
            NGWorkspace ngc = registerWorkspaceRequired(ar, siteId, pageId );
            ar.assertLoggedIn("Must be logged in to check your role membership");
            ar.setPageAccessLevels(ngc);
            roleName = ar.reqParam("role");
            JSONObject repo = new JSONObject();

            NGRole role = ngc.getRole(roleName);
            if (role==null) {
                throw new Exception("Can not file a role named '"+roleName+"'");
            }
            boolean isPlayer = role.isExpandedPlayer(ar.getUserProfile(), ngc);

            repo.put("isPlayer", isPlayer);
            sendJson(ar, repo);
        }catch(Exception ex){
            Exception ee = new Exception("Unable to determine if user is player of role '"+roleName, ex);
            streamException(ee, ar);
        }
    }


    @RequestMapping(value = "/{siteId}/{pageId}/emailGeneratorUpdate.json", method = RequestMethod.POST)
    public void emailGeneratorUpdate(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        String id = "";
        try{
            NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail( siteId, pageId ).getWorkspace();
            ar.setPageAccessLevels(ngw);
            ar.assertUpdateWorkspace("Must be able to update workspace to create an email generator.");
            ar.assertNotReadOnly("Cannot generate email");
            ar.assertNotFrozen(ngw);
            JSONObject eGenInfo = getPostedObject(ar);

            id = eGenInfo.getString("id");
            EmailGenerator eGen = null;
            if ("~new~".equals(id)) {
                eGen = ngw.createEmailGenerator();
                eGen.setOwner(ar.getBestUserId());
            }
            else {
                eGen = ngw.getEmailGeneratorOrFail(id);
            }

            //the 'owner' is always the last person who saves the record. The email can
            //only include what this person sees.  This avoid a problem with getting around
            //security by finding an email of a highly privileged person, and modifying the
            //email to send confidential stuff.
            eGen.setOwner(ar.getBestUserId());

            //this is a non persistent flag in the body ... could be a URL parameter
            boolean sendIt = eGenInfo.optBoolean("sendIt");
            boolean scheduleIt = eGenInfo.optBoolean("scheduleIt");
            boolean deleteIt = eGenInfo.optBoolean("deleteIt");
            if (deleteIt) {
                ngw.deleteEmailGenerator(eGen.getId());
            }
            else {
                eGen.updateFromJSON(eGenInfo);
                if (sendIt) {
                    //send it 5 seconds from now.  Background thread has to pick it up..
                    eGen.setScheduleTime(ar.nowTime + 5000);
                    eGen.scheduleEmail(ar);
                }
                else if (scheduleIt) {
                    eGen.updateFromJSON(eGenInfo);
                    //time to send must have been set in the updateFromJSON
                    eGen.scheduleEmail(ar);
                }
            }

            ngw.saveFile(ar, "Updated Email Generator "+id);
            JSONObject repo = eGen.getJSON(ar, ngw);
            sendJson(ar, repo);
        }
        catch(Exception ex){
            Exception ee = new Exception("Unable to update Email Generator "+id, ex);
            streamException(ee, ar);
        }
    }


    @RequestMapping(value = "/{siteId}/{pageId}/renderEmail.json", method = RequestMethod.POST)
    public void renderEmail(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        String id = "";
        try{
            NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail( siteId, pageId ).getWorkspace();
            ar.setPageAccessLevels(ngw);
            ar.assertAccessWorkspace("Must be a role player to render an email.");
            JSONObject eGenInfo = getPostedObject(ar);

            id = eGenInfo.getString("id");
            String sampleUser = null;
            if (eGenInfo.has("toUser")) {
                sampleUser = eGenInfo.getString("toUser");
            }
            else {
                sampleUser = ar.getBestUserId();
            }

            JSONObject repo = new JSONObject();

            if ("~new~".equals(id)) {

                repo.put("html", "Click 'save' to see the email rendered");
            }
            else {
                EmailGenerator eGen = ngw.getEmailGeneratorOrFail(id);
                List<OptOutAddr> oList = eGen.expandAddresses(ar,ngw);
                JSONArray addressees = new JSONArray();
                for (OptOutAddr ooa : oList) {
                    addressees.put(ooa.getAssignee().getJSON());
                }

                //would be better if we could capture the actual relationship
                OptOutAddr sampleAddressee = eGen.getOOAForUserID(ar,  ngw, sampleUser);
                MailInst mail = new MailInst();
                mail.markNotReal();
                eGen.generateEmailBody(ar, ngw, sampleAddressee, mail);

                repo.put("subject", mail.getSubject());
                repo.put("html", mail.getBodyText());
                repo.put("addressees", addressees);
            }

            sendJson(ar, repo);
        }
        catch(Exception ex){
            Exception ee = new Exception("Unable to render the email message "+id, ex);
            streamException(ee, ar);
        }
    }


    
    @RequestMapping(value = "/{siteId}/{pageId}/getLabels.json", method = RequestMethod.POST)
    public void getLabels(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try{
            NGWorkspace ngw = ar.findAndSetWorkspace( siteId, pageId );
            ar.assertAccessWorkspace("Must be able to access workspace to get labels.");
            
            JSONObject ret = new JSONObject();
            JSONArray list = new JSONArray();
            
            for (NGLabel label : ngw.getAllLabels()) {
                list.put(label.getJSON());
            }
            ret.put("list", list);
            
            sendJson(ar, ret);
        }
        catch(Exception ex){
            Exception ee = new Exception("Unable to supply all labels.", ex);
            streamException(ee, ar);
        }
    }

    @RequestMapping(value = "/{siteId}/{pageId}/labelUpdate.json", method = RequestMethod.POST)
    public void labelUpdate(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        String op = "";
        try{
            NGWorkspace ngw = ar.findAndSetWorkspace( siteId, pageId );
            ar.assertUpdateWorkspace("Must be able to update workspace to modify labels.");
            ar.assertNotReadOnly("Cannot modify labels");
            ar.assertNotFrozen(ngw);
            op = ar.reqParam("op");
            JSONObject labelInfo = getPostedObject(ar);
            String labelName = labelInfo.getString("name");

            NGLabel label = ngw.getLabelRecordOrNull(labelName);
            if ("Create".equals(op)) {
                String editedName = labelInfo.getString("editedName");
                NGLabel other = ngw.getLabelRecordOrNull(editedName);
                if (label==null) {
                    if (other!=null) {
                        throw new Exception("Cannot create label '"+editedName+"' because a label already exists with that name.");
                    }
                    label = ngw.findOrCreateLabelRecord(editedName, labelInfo.getString("color"));
                }
                else {
                    if (!editedName.equals(labelName)) {
                        if (other!=null) {
                            throw new Exception("Cannot change label '"+labelName+"' to '"+editedName+"' because a label already exists with that name.");
                        }
                    }
                    label.setName(editedName);
                    label.setColor(labelInfo.getString("color"));
                }
            }
            else if ("Delete".equals(op)) {
                if (label!=null && label instanceof LabelRecord) {
                    ngw.removeLabelRecord((LabelRecord)label);
                }
            }

            ngw.saveFile(ar, "Updated Agenda Item");
            JSONObject repo = label.getJSON();
            sendJson(ar, repo);
        }catch(Exception ex){
            Exception ee = new Exception("Unable to modify "+op+" label.", ex);
            streamException(ee, ar);
        }
    }
    @RequestMapping(value = "/{siteId}/{pageId}/copyLabels.json", method = RequestMethod.POST)
    public void copyLabels(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        String op = "";
        try{
            NGWorkspace ngw = ar.findAndSetWorkspace( siteId, pageId );
            ar.assertUpdateWorkspace("Must be able to update workspace to modify labels.");
            ar.assertNotReadOnly("Cannot modify labels");
            ar.assertNotFrozen(ngw);

            JSONArray newLabelsCreated = new JSONArray();
            Cognoscenti cog = ar.getCogInstance();
            JSONObject pojb = getPostedObject(ar);
            String sourceProject = pojb.getString("from");
            NGWorkspace fromWS = cog.getWSByCombinedKeyOrFail( sourceProject ).getWorkspace();

            for (NGLabel aLabel : fromWS.getAllLabels() ) {
                boolean found = false;
                for (NGLabel alreadyThere : ngw.getAllLabels() ) {
                    if (aLabel.getName().equals( alreadyThere.getName() )) {
                        found = true;
                    }
                }
                if (!found) {
                    ngw.findOrCreateLabelRecord(aLabel.getName(), aLabel.getColor());
                    newLabelsCreated.put(aLabel.getJSON());
                }
            }

            ngw.saveFile(ar, "Labels Copied from another project");
            JSONObject repo = new JSONObject();
            repo.put("list", newLabelsCreated);
            sendJson(ar, repo);
        }catch(Exception ex){
            Exception ee = new Exception("Unable to modify "+op+" label.", ex);
            streamException(ee, ar);
        }
    }

    ///////////////////////// Eamil ///////////////////////

    @RequestMapping(value = "/{siteId}/{pageId}/QueryEmail.json", method = RequestMethod.POST)
    public void queryEmail(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try{
            NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail( siteId, pageId ).getWorkspace();
            ar.setPageAccessLevels(ngw);
            ar.assertAccessWorkspace("Project email list is accessible only by role players.");
            JSONObject posted = this.getPostedObject(ar);

            JSONObject repo = EmailSender.queryWorkspaceEmail(ngw, posted);

            sendJson(ar, repo);
        }catch(Exception ex){
            Exception ee = new Exception("Unable to get email", ex);
            streamException(ee, ar);
        }
    }



    ///////////////////////// Invitations ///////////////////

    @RequestMapping(value = "/{siteId}/{pageId}/invitations.json", method = RequestMethod.GET)
    public void invitations(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try{
            NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail( siteId, pageId ).getWorkspace();
            JSONObject repo = new JSONObject();
            JSONArray shareList = new JSONArray();
            for (RoleInvitation ta : ngw.getInvitations()) {
                shareList.put(ta.getInvitationJSON());
            }
            repo.put("invitations", shareList);
            sendJson(ar, repo);
        }catch(Exception ex){
            Exception ee = new Exception("Unable to get the list of invitations ", ex);
            streamException(ee, ar);
        }
    }
    @RequestMapping(value = "/{siteId}/{pageId}/invitationUpdate.json", method = RequestMethod.POST)
    public void invitationUpdate(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try{
            NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail( siteId, pageId ).getWorkspace();
            ar.setPageAccessLevels(ngw);
            ar.assertNotFrozen(ngw);
            
            JSONObject posted = this.getPostedObject(ar);
            
            //posted object MUST have a ss field in it to work
            if (!posted.has("ss")) {
            	throw new Exception("Operation 'invitationUpdate.json' requires a 'ss' field in the posted object");
            }

            String email = posted.getString("email");

            //we don't know what the user will enter for the email address
            //but if they do enter a combined address, this will help handle it
            //a bit better.   If it is a pure email address that will work as well
            AddressListEntry ale = AddressListEntry.parseCombinedAddress(email);

            //check that the role exists to avoid getting invitations for non existent roles.
            boolean found = false;
            String roleName = posted.getString("role");
            for (CustomRole existingRole : ngw.getAllRoles()) {
                if (roleName.equals(existingRole.getName())) {
                    existingRole.addPlayerIfNotPresent(ale);
                    found = true;
                }
            }
            if (!found) {
                throw new Exception("Can not find a role named '"+roleName+"' in the workspace "+ngw.getFullName());
            }

            RoleInvitation ri = ngw.findOrCreateInvite(ale);
            ri.updateFromJSON(posted);
            ri.resendInvite();

            JSONObject repo = ri.getInvitationJSON();
            ngw.saveFile(ar, "Created a inviation to join workspace");
            sendJson(ar, repo);
        }catch(Exception ex){
            Exception ee = new Exception("Unable to update an invitation", ex);
            streamException(ee, ar);
        }
    }
}
