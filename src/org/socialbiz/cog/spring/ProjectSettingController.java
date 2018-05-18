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
import java.util.ArrayList;
import java.util.List;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.socialbiz.cog.AccessControl;
import org.socialbiz.cog.AddressListEntry;
import org.socialbiz.cog.AuthRequest;
import org.socialbiz.cog.Cognoscenti;
import org.socialbiz.cog.CustomRole;
import org.socialbiz.cog.EmailGenerator;
import org.socialbiz.cog.LabelRecord;
import org.socialbiz.cog.NGContainer;
import org.socialbiz.cog.NGLabel;
import org.socialbiz.cog.NGPage;
import org.socialbiz.cog.NGRole;
import org.socialbiz.cog.NGWorkspace;
import org.socialbiz.cog.OptOutAddr;
import org.socialbiz.cog.RoleRequestRecord;
import org.socialbiz.cog.UserManager;
import org.socialbiz.cog.UserProfile;
import org.socialbiz.cog.mail.EmailSender;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;

import com.purplehillsbooks.json.JSONArray;
import com.purplehillsbooks.json.JSONObject;

@Controller
public class ProjectSettingController extends BaseController {



    //////////////////////// MAIN VIEWS ////////////////////////////

    @RequestMapping(value = "/{siteId}/{pageId}/personal.htm", method = RequestMethod.GET)
    public void showPersonalTab(@PathVariable String siteId,
            @PathVariable String pageId, HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        showJSPLoggedIn(ar,siteId,pageId, "leaf_personal");
    }

    @RequestMapping(value = "/{siteId}/{pageId}/roleManagement.htm", method = RequestMethod.GET)
    public void roleManagement(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        showJSPMembers(ar, siteId, pageId, "RoleManagement");
    }

    @RequestMapping(value = "/{siteId}/{pageId}/MultiInvite.htm", method = RequestMethod.GET)
    public void MultiInvite(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        showJSPMembers(ar, siteId, pageId, "MultiInvite");
    }
    
    @RequestMapping(value = "/{siteId}/{pageId}/roleDefine.htm", method = RequestMethod.GET)
    public void roleDefine(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        showJSPMembers(ar, siteId, pageId, "RoleDefine");
    }

    @RequestMapping(value = "/{siteId}/{pageId}/roleNomination.htm", method = RequestMethod.GET)
    public void roleNomination(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        showJSPMembers(ar, siteId, pageId, "RoleNomination");
    }

    @RequestMapping(value = "/{siteId}/{pageId}/roleRequest.htm", method = RequestMethod.GET)
    public void remindersTab(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        showJSPMembers(ar, siteId, pageId, "RoleRequest");
    }


    @RequestMapping(value = "/{siteId}/{pageId}/admin.htm", method = RequestMethod.GET)
    public void showAdminTab(@PathVariable String siteId,
            @PathVariable String pageId, HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        registerSiteOrProject(ar, siteId, pageId);
        if (ar.isAdmin()) {
            streamJSP(ar, "leaf_admin");
        }
        else {
            showJSPMembers(ar, siteId, pageId, "leaf_admin");
        }
    }

    @RequestMapping(value = "/{siteId}/{pageId}/labelList.htm", method = RequestMethod.GET)
    public void labelList(
            @PathVariable String pageId, @PathVariable String siteId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        showJSPMembers(ar, siteId, pageId, "LabelList");
    }

    @RequestMapping(value = "/{siteId}/{pageId}/listEmail.htm", method = RequestMethod.GET)
    public void getEmailRecordsPage( @PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        showJSPMembers(ar, siteId, pageId, "ListEmail");
    }

    @RequestMapping(value = "/{siteId}/{pageId}/emailSent.htm", method = RequestMethod.GET)
    public void emailSent( @PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        showJSPMembers(ar, siteId, pageId, "EmailSent");
    }


    @RequestMapping(value = "/{siteId}/{pageId}/emailMsg.htm", method = RequestMethod.GET)
    public void emailMsg( @PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        showJSPMembers(ar, siteId, pageId, "EmailMsg");
    }


    @RequestMapping(value = "/{siteId}/{pageId}/streamingLinks.htm", method = RequestMethod.GET)
    public void streamingLinks(@PathVariable String siteId, @PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        showJSPMembers(ar, siteId, pageId, "StreamingLinks");
    }



    @RequestMapping(value = "/{siteId}/{pageId}/sendNote.htm", method = RequestMethod.GET)
    public void sendNote(
            @PathVariable String pageId, @PathVariable String siteId,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        showJSPMembers(ar, siteId, pageId, "SendNote");
    }


    @RequestMapping(value = "/{siteId}/{pageId}/sendNoteView.htm", method = RequestMethod.GET)
    public void sendNoteView(
            @PathVariable String pageId, @PathVariable String siteId,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        showJSPMembers(ar, siteId, pageId, "sendNoteView");
    }


    @RequestMapping(value = "/{siteId}/{pageId}/synchronizeUpstream.htm", method = RequestMethod.GET)
    public void synchronizeUpstream(@PathVariable String siteId, @PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        showJSPMembers(ar, siteId, pageId, "synchronizeUpstream");
    }






    ////////////////////////////// REDIRECTS ///////////////////////////////////


    @RequestMapping(value = "/{siteId}/{pageId}/permission.htm", method = RequestMethod.GET)
    public void permission(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        redirectBrowser(ar, "roleManagement.htm");
    }

    @RequestMapping(value = "/{siteId}/{pageId}/EditRole.htm", method = RequestMethod.GET)
    public void editRole(@PathVariable String siteId,@PathVariable String pageId,
            @RequestParam String roleName, HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        redirectBrowser(ar, "roleManagement.htm");
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

            
            op = personalInfo.getString("op");
            UserManager userManager = ar.getCogInstance().getUserManager();
            if ("SetWatch".equals(op)) {
                up.setWatch(pageId, ar.nowTime);
                userManager.saveUserProfiles();
            }
            else if ("ClearWatch".equals(op)) {
                up.clearWatch(pageId);
                userManager.saveUserProfiles();
            }
            else if ("SetTemplate".equals(op)) {
                up.setProjectAsTemplate(siteId, pageId);
                userManager.saveUserProfiles();
            }
            else if ("ClearTemplate".equals(op)) {
                up.removeTemplateRecord(pageId);
                userManager.saveUserProfiles();
            }
            else if ("SetNotify".equals(op)) {
                up.setNotification(pageId);
                userManager.saveUserProfiles();
            }
            else if ("ClearNotify".equals(op)) {
                up.clearNotification(pageId);
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
            repo.put("op",  op);
            repo.put("success",  true);
            sendJson(ar, repo);
        }
        catch(Exception ex){
            Exception ee = new Exception("Unable to update the user setting for "+op+" on workspace "+pageId, ex);
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
            NGWorkspace ngc = (NGWorkspace) registerSiteOrProject(ar, siteId, pageId );
            ar.setPageAccessLevels(ngc);
            ar.assertLoggedIn("Must be logged in to manipuate roles.");
            JSONObject personalInfo = getPostedObject(ar);
            UserProfile up = ar.getUserProfile();

            op = personalInfo.getString("op");
            roleId = personalInfo.getString("roleId");

            NGRole role = ngc.getRoleOrFail(roleId);
            AddressListEntry ale = up.getAddressListEntry();
            RoleRequestRecord rrr = ngc.getRoleRequestRecord(role.getName(),up.getUniversalId());


            if ("Join".equals(op)) {
                if (role.isPlayer(up)) {
                    //don't do anything
                }
                else {
                    String requestDesc = "";
                    if (personalInfo.has("desc")) {
                        requestDesc = personalInfo.getString("desc");
                    }
                    rrr = ngc.createRoleRequest(roleId, up.getUniversalId(), ar.nowTime, up.getUniversalId(), requestDesc);

                    NGRole adminRole = ngc.getSecondaryRole();
                    boolean hasSpecialPermission = adminRole.isPlayer(ale);

                    if (!hasSpecialPermission && ngc instanceof NGWorkspace)  {
                        NGRole executiveRole = ((NGWorkspace)ngc).getSite().getRole("Executives");//getSecondaryRole();
                        hasSpecialPermission = executiveRole.isPlayer(ale);
                    }

                    //Note: if there is no administrator for the project, then ANYONE is allowed to
                    //sign up as ANY role.  Once grabbed, that person is administrator.
                    boolean noAdmin = adminRole.getDirectPlayers().size()==0;

                    if(hasSpecialPermission || noAdmin ) {
                        rrr.setState("Approved");
                        ngc.addPlayerToRole(roleId,up.getUniversalId());
                    }
                    else{
                        sendRoleRequestEmail(ar,rrr,ngc);
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

            ngc.saveFile(ar, "Updated role "+roleId);
            JSONObject repo = new JSONObject();
            repo.put("op",  op);
            repo.put("success",  true);
            repo.put("player", role.isPlayer(up));
            RoleRequestRecord rrr2 = ngc.getRoleRequestRecord(role.getName(),up.getUniversalId());
            repo.put("reqPending", (rrr2!=null && !rrr2.isCompleted()));
            sendJson(ar, repo);
        }
        catch(Exception ex){
            Exception ee = new Exception("Unable to update the user setting for "+op+" on role "+roleId+" workspace  "+pageId, ex);
            streamException(ee, ar);
        }
    }


    private static void sendRoleRequestEmail(AuthRequest ar,
            RoleRequestRecord roleRequestRecord, NGWorkspace container)
            throws Exception {
        Cognoscenti cog = ar.getCogInstance();
        UserProfile up = ar.getUserProfile();
        if (up == null) {
            throw new Exception(
                    "Program Logic Error: only logged in users can request to join a role, and got such a request when there appears to be nobody logged in");
        }

        //This is a magic URL that contains a magic token that will allow people
        //who are not logged in, to approve this request.
        String resourceURL = ar.getResourceURL(container, "approveOrRejectRoleReqThroughMail.htm")
            +"?requestId="  + roleRequestRecord.getRequestId()
            + "&isAccessThroughEmail=yes&"
            + AccessControl.getAccessRoleRequestParams(container, roleRequestRecord);

        List<OptOutAddr> initialList = new ArrayList<OptOutAddr>();
        OptOutAddr.appendUsersFromRole(container, container.getPrimaryRole().getName(), initialList);
        OptOutAddr.appendUsersFromRole(container, container.getSecondaryRole().getName(), initialList);

        JSONObject data = new JSONObject();
        data.put("baseURL", ar.baseURL);
        data.put("requester", ar.getUserProfile().getJSON());
        data.put("wsURL", ar.baseURL + ar.getDefaultURL(container));
        data.put("wsName", container.getFullName());
        data.put("roleName", roleRequestRecord.getRoleName());
        data.put("comment", roleRequestRecord.getRequestDescription());
        data.put("resourceURL", ar.baseURL + resourceURL);

        File templateFile = cog.getConfig().getFileFromRoot("email/RoleRequest.chtml");

        // filter out users that who have no profile and have never logged in.
        // Only send this request to real users, not just email addresses
        for (OptOutAddr ooa : initialList) {
            if (ooa.isUserWithProfile()) {
                data.put("optout", ooa.getUnsubscribeJSON(ar));
                EmailSender.containerEmail(ooa, container,
                    "Role Requested by " + ar.getBestUserId(),
                    templateFile,  data, null, new ArrayList<String>(), ar.getCogInstance());
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
            NGContainer ngc = registerSiteOrProject(ar, siteId, pageId );
            ar.setPageAccessLevels(ngc);
            JSONObject personalInfo = getPostedObject(ar);
            op = personalInfo.getString("op");
            String roleRequestId = personalInfo.getString("rrId");
            RoleRequestRecord rrr = ngc.getRoleRequestRecordById(roleRequestId);
            roleName = rrr.getRoleName();
            boolean canAccess = AccessControl.canAccessRoleRequest(ar, ngc, rrr);

            if (!canAccess) {
                throw new Exception("Unable to access that RoleRequestRecord.  You might need to be logged in.");
            }

            if ("Approve".equals(op)) {
                String requestedBy = rrr.getRequestedBy();
                ngc.addPlayerToRole(roleName,requestedBy);
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
                ngc.saveFile(ar, "Resolved role "+roleName);
            }
            else {
                ngc.saveWithoutAuthenticatedUser("Unknown", ar.nowTime, "Resolved role "+roleName, ar.getCogInstance());
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
        try{
            NGContainer ngc = registerSiteOrProject(ar, siteId, pageId );
            ar.setPageAccessLevels(ngc);
            //maybe this should be for admins?
            ar.assertMember("Must be a member to modify roles.");
            op = ar.reqParam("op");
            JSONObject roleInfo = getPostedObject(ar);
            JSONObject repo = new JSONObject();

            if ("Update".equals(op)) {
                CustomRole role = ngc.getRoleOrFail(roleInfo.getString("name"));
                role.updateFromJSON(roleInfo);
                repo = role.getJSONDetail();
            }
            else if ("Create".equals(op)) {
                CustomRole role = ngc.createRole(roleInfo.getString("name"), "");
                role.updateFromJSON(roleInfo);
                repo = role.getJSONDetail();
            }
            else if ("Delete".equals(op)) {
                ngc.deleteRole(roleInfo.getString("name"));
                repo.put("success",  true);
            }
            else if ("GetAll".equals(op)) {
                JSONArray ja = new JSONArray();
                for (NGRole ngr : ngc.getAllRoles()) {
                    ja.put(ngr.getJSON());
                }
                repo.put("roles", ja);
            }

            ngc.saveFile(ar, "Updated Role");
            sendJson(ar, repo);
        }catch(Exception ex){
            Exception ee = new Exception("Unable to '"+op+"' the role.", ex);
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
            ar.assertMember("Must be a member to create an email generator.");
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
            ar.assertMember("Must be a member to render an email.");
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
                
                String[] subjAndBody = eGen.generateEmailBody(ar, ngw, sampleAddressee);

                repo.put("subject", subjAndBody[0]);
                repo.put("html", subjAndBody[1]);
                repo.put("addressees", addressees);
            }

            sendJson(ar, repo);
        }
        catch(Exception ex){
            Exception ee = new Exception("Unable to update Email Generator "+id, ex);
            streamException(ee, ar);
        }
    }
    

    @RequestMapping(value = "/{siteId}/{pageId}/labelUpdate.json", method = RequestMethod.POST)
    public void labelUpdate(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        String op = "";
        try{
            NGPage ngp = ar.getCogInstance().getWSBySiteAndKeyOrFail( siteId, pageId ).getWorkspace();
            ar.setPageAccessLevels(ngp);
            ar.assertMember("Must be a member to modify labels.");
            op = ar.reqParam("op");
            JSONObject labelInfo = getPostedObject(ar);
            String labelName = labelInfo.getString("name");

            NGLabel label = ngp.getLabelRecordOrNull(labelName);
            if ("Create".equals(op)) {
                String editedName = labelInfo.getString("editedName");
                NGLabel other = ngp.getLabelRecordOrNull(editedName);
                if (label==null) {
                    if (other!=null) {
                        throw new Exception("Cannot create label '"+editedName+"' because a label already exists with that name.");
                    }
                    label = ngp.findOrCreateLabelRecord(editedName, labelInfo.getString("color"));
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
                    ngp.removeLabelRecord((LabelRecord)label);
                }
            }

            ngp.saveFile(ar, "Updated Agenda Item");
            JSONObject repo = label.getJSON();
            sendJson(ar, repo);
        }catch(Exception ex){
            Exception ee = new Exception("Unable to modify "+op+" label.", ex);
            streamException(ee, ar);
        }
    }

}
