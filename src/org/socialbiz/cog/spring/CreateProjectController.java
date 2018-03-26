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
 * Anamika Chaudhari, Ajay Kakkar, Rajeev Rastogi, Pawan Chopra
 */

package org.socialbiz.cog.spring;

import java.util.ArrayList;
import java.util.List;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.socialbiz.cog.AddressListEntry;
import org.socialbiz.cog.AgentRule;
import org.socialbiz.cog.AuthRequest;
import org.socialbiz.cog.BaseRecord;
import org.socialbiz.cog.Cognoscenti;
import org.socialbiz.cog.GoalRecord;
import org.socialbiz.cog.LicensedURL;
import org.socialbiz.cog.NGBook;
import org.socialbiz.cog.NGPage;
import org.socialbiz.cog.NGRole;
import org.socialbiz.cog.NGWorkspace;
import org.socialbiz.cog.ProcessRecord;
import org.socialbiz.cog.RemoteGoal;
import org.socialbiz.cog.UserManager;
import org.socialbiz.cog.UserPage;
import org.socialbiz.cog.UserProfile;
import org.socialbiz.cog.api.ProjectSync;
import org.socialbiz.cog.api.RemoteProject;
import org.socialbiz.cog.exception.NGException;
import org.springframework.stereotype.Controller;
import org.springframework.ui.ModelMap;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;

import com.purplehillsbooks.json.JSONArray;
import com.purplehillsbooks.json.JSONObject;

/**
 * This class will handle all requests that are coming to create a new Workspace.
 * Currently this is handling only requests that are coming to create a new
 * project from scratch. Later this can be extended to edit a project or to
 * create a project from Template.
 */
@Controller
public class CreateProjectController extends BaseController {

    @RequestMapping(value = "/{siteId}/$/createWorkspace.json", method = RequestMethod.POST)
    public void createWorkspaceAPI(@PathVariable String siteId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try{
            NGBook site = ar.getCogInstance().getSiteById(siteId);
            ar.setPageAccessLevels(site);
            if (!site.primaryOrSecondaryPermission(ar.getUserProfile())) {
                throw new NGException("nugen.exception.not.a.member.of.account",
                        new Object[] { site.getFullName() });
            }

            JSONObject newConfig = getPostedObject(ar);
            UserProfile uProf  = ar.getUserProfile();
            long nowTime       = ar.nowTime;
            String workspaceName = newConfig.getString("newName");
            String upstream    = newConfig.optString("upstream", null);

            //first, if given a template, check to make sure it exists else error before creating workspace
            String template    = newConfig.optString("template", null);
            NGWorkspace templateWorkspace = null;
            if (template!=null && template.length()>0) {
                templateWorkspace = ar.getCogInstance().getWSByCombinedKeyOrFail(template).getWorkspace();
            }
            
            //now actually create it
            NGWorkspace newWorkspace = createWorkspace(uProf, site, workspaceName, upstream, nowTime, ar.getCogInstance());
            
            //set the purpose / description
            String purpose     = newConfig.optString("purpose", "");
            newWorkspace.setPurpose(purpose);
            
            //do the members if any specified
            JSONArray members  = newConfig.optJSONArray("members");
            if (members!=null) {
                NGRole memberRole = newWorkspace.getRole("Members");
                for (int i=0; i<members.length(); i++) {
                    JSONObject memberObj = members.getJSONObject(i);
                    String memberAddress = memberObj.getString("uid");
                    memberRole.addPlayerIfNotPresent(new AddressListEntry(memberAddress));
                }
            }

            //now apply template if found
            if (templateWorkspace!=null) {
                newWorkspace.injectTemplate(ar, templateWorkspace);
            }
            newWorkspace.saveContent(ar, "Workspace created from web api");

            JSONObject repo = newWorkspace.getConfigJSON();
            sendJson(ar, repo);
        }catch(Exception ex){
            Exception ee = new Exception("Unable to a workspace.", ex);
            streamException(ee, ar);
        }
    }

    
    

    @RequestMapping(value = "/{siteId}/$/createClone.form", method = RequestMethod.POST)
    public void createClone(@PathVariable String siteId, HttpServletRequest request,
            HttpServletResponse response) throws Exception
    {
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            if(!ar.isLoggedIn()){
                sendRedirectToLogin(ar);
                return;
            }

            String upstream = ar.reqParam("upstream");
            RemoteProject rp = new RemoteProject(upstream);

            String remoteName = rp.getName();

            NGBook site = ar.getCogInstance().getSiteByIdOrFail(siteId);

            NGWorkspace project = createWorkspace(ar.getUserProfile(), site, remoteName+"(clone)", upstream, ar.nowTime, ar.getCogInstance());
            ar.setPageAccessLevels(project);
            project.saveFile(ar, "Created new cloned project");

            response.sendRedirect(ar.retPath+"t/"+siteId+"/"+project.getKey()+"/SyncAttachment.htm");

        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.create.project.from.template", new Object[]{siteId} , ex);
        }
    }


    @RequestMapping(value = "/{siteId}/{pageId}/createProjectFromTask.form", method = RequestMethod.POST)
    public void createProjectFromTask(@PathVariable String siteId,String pageId,
            ModelMap model, HttpServletRequest request,
            HttpServletResponse response)
    throws Exception {

        try {
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            if(!ar.isLoggedIn()){
                sendRedirectToLogin(ar);
                return;
            }
            String goUrl = ar.reqParam("goUrl");
            String parentTaskId=goUrl.substring(goUrl.lastIndexOf("=")+1,goUrl.length());
            String parentProcessUrl=ar.reqParam("parentProcessUrl");

            NGPage subProcess= createTemplateProject(ar,siteId);
            linkSubProcessToTask(ar,subProcess,parentTaskId,parentProcessUrl);

            response.sendRedirect(goUrl);
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.create.template.project", new Object[]{pageId,siteId} , ex);
        }
    }

    @RequestMapping(value = "/{userId}/createProjectFromRemoteGoal.form", method = RequestMethod.POST)
    public void createProjectFromRemoteGoal(@PathVariable String userId,
            ModelMap model, HttpServletRequest request,
            HttpServletResponse response)
    throws Exception {

        try {
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            if(!ar.isLoggedIn()){
                sendRedirectToLogin(ar);
                return;
            }
            String goUrl = ar.reqParam("goUrl");
            String siteId=ar.reqParam("siteId");

            NGWorkspace newWorkspace = createTemplateProject(ar,siteId);

            if (goUrl==null) {
                goUrl = ar.retPath+ar.getDefaultURL(newWorkspace);
            }
            response.sendRedirect(goUrl);
        }catch(Exception ex){
            throw new Exception("Failed to create project for user "+userId, ex);
        }
    }

    @RequestMapping(value = "/{userId}/RunAgentsManually.form", method = RequestMethod.POST)
    public void runAgentsManual(@PathVariable String userId,
            ModelMap model, HttpServletRequest request,
            HttpServletResponse response)
    throws Exception {

        try {
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            if(!ar.isLoggedIn()){
                sendRedirectToLogin(ar);
                return;
            }
            NGWorkspace created = createProjectFromAgentRules(ar);
            String goUrl = "Agents.htm";
            if (created!=null){
                goUrl = ar.baseURL + ar.getDefaultURL(created);
            }
            response.sendRedirect(goUrl);
        }catch(Exception ex){
            throw new Exception("Failed to create project for user "+userId, ex);
        }
    }

    private NGWorkspace createProjectFromAgentRules(AuthRequest ar) throws Exception {
        Cognoscenti cog = ar.getCogInstance();
        UserManager userManager = cog.getUserManager();
        UserProfile uProf = ar.getUserProfile();
        UserPage uPage = uProf.getUserPage();

        for (RemoteGoal rg : uPage.getRemoteGoals()) {
            for (AgentRule rule : uPage.getAgentRules()) {
                String subjExpr = rule.getSubjExpr();
                String descExpr = rule.getDescExpr();
                String subj = rg.getSynopsis();
                String desc = rg.getDescription();
                if (subjExpr!=null & subj!=null & subjExpr.length()>0) {
                    if (!subj.contains(subjExpr)) {
                        continue;
                    }
                }
                if (descExpr!=null & desc!=null & descExpr.length()>0) {
                    if (!desc.contains(descExpr)) {
                        continue;
                    }
                }

                String upstream = rg.getProjectAccessURL();
                NGWorkspace newWorkspace = ar.getCogInstance().getWorkspaceByUpstreamLink(upstream);
                if (newWorkspace!=null) {
                    //looks like a clone already exists, so nothing more to do with this one
                    continue;
                }

                //found one, now use it
                String siteId = rule.getSiteKey();
                String templateKey = rule.getTemplate();
                String projectName = rg.getProjectName() + " (clone)";
                UserProfile owner = userManager.findUserByAnyIdOrFail(rule.getOwner());
                NGBook site = ar.getCogInstance().getSiteByIdOrFail(siteId);
                newWorkspace = createWorkspace(owner, site, projectName, upstream, ar.nowTime, ar.getCogInstance());
                if (templateKey!=null && templateKey.length()>0) {
                    NGPage template_ngp = ar.getCogInstance().getWSByCombinedKeyOrFail(templateKey).getWorkspace();
                    newWorkspace.injectTemplate(ar, template_ngp);
                }
                if (upstream!=null && upstream.length()>0) {
                    RemoteProject remProj = new RemoteProject(upstream);
                    ProjectSync ps = new ProjectSync(newWorkspace, remProj, ar, "xxx");
                    ps.downloadAll();
                }
                newWorkspace.saveContent(ar, "Created by agent rule "+rule.getId());
                return newWorkspace;
            }
        }
        return null;
    }

    ////////////////// HELPER FUNCTIONS /////////////////////////////////


    /**
     * Takes a nice display name and turns it into a 
     * nice URL value.
     * 
     * The input:  "My favorite, usual Hangout!"
     * produces:   "my-favorite-usual-hangout"
     * 
     * All the letters are lower cased.
     * Only A-Z is supported with numerals
     * any gaps of other characters of any kind replaced with hyphen
     * hyphen avoided on either end
     */
    private static String makeGoodSearchableName(String source) {
        StringBuffer result = new StringBuffer();
        source = source.trim();
        int last = source.length();
        boolean betweenWords = false;
        for (int i=0; i<last; i++) {
            char ch = source.charAt(i);
            boolean addableChar = false;
            if (ch >= 'a' && ch <= 'z') {
                addableChar = true;
            }
            else if (ch >= '0' && ch <= '9') {
                addableChar = true;
            }
            else if (ch >= 'A' && ch <= 'Z') {
                ch = (char) (ch + 32);
                addableChar = true;
            }
            if (addableChar) {
                if (betweenWords) {
                    result.append('-');
                }
                result.append(ch);
                betweenWords = false;
            }
            else {
                //this avoid adding a hypen at the beginning if no
                //acceptable character has been seen yet.
                betweenWords = result.length()>0;
            }
        }
        return result.toString();
    }


    /**
     * Creates a workspace, but does not save it.   
     * Caller must save the workspace ... otherwise bad things could happen.
     */
    private static NGWorkspace createWorkspace(UserProfile uProf, NGBook site, String workspaceName,
        String upstream, long nowTime, Cognoscenti cog) throws Exception {
        if (!site.primaryOrSecondaryPermission(uProf)) {
            throw new NGException("nugen.exception.not.member.of.account",
                    new Object[]{site.getFullName()});
        }

        NGWorkspace newWorkspace = null;
        String pageKey = makeGoodSearchableName(workspaceName);
        if (pageKey.length()>30) {
            pageKey = pageKey.substring(0,30);
        }
        newWorkspace = site.createProjectByKey(uProf, pageKey, nowTime, cog);
        List<String> nameSet = new ArrayList<String>();
        nameSet.add(workspaceName);
        newWorkspace.setPageNames(nameSet);

        //check for and set the upstream link
        if (upstream!=null && upstream.length()>0) {
            newWorkspace.setUpstreamLink(upstream);
        }

        newWorkspace.setSite(site);

        cog.makeIndexForWorkspace(newWorkspace);

        return newWorkspace;
    }

    private static NGWorkspace createTemplateProject(AuthRequest ar, String siteId) throws Exception {
        try {

            NGBook site = ar.getCogInstance().getSiteByIdOrFail(siteId);
            if (!site.primaryOrSecondaryPermission(ar.getUserProfile())) {
                throw new NGException("nugen.exception.not.a.member.of.account",
                        new Object[] { site.getFullName() });
            }

            UserProfile uProf = ar.getUserProfile();
            long nowTime       = ar.nowTime;
            String projectName = ar.reqParam("projectname").trim();
            String upstream    = ar.defParam("upstream", null);
            NGWorkspace newWorkspace = createWorkspace(uProf, site, projectName, upstream, nowTime, ar.getCogInstance());
            ar.setPageAccessLevels(newWorkspace);            
            
            String templateName = ar.defParam("templateName", null);
            if (templateName!=null && templateName.length()>0) {
                NGPage template_ngp = ar.getCogInstance().getWSByCombinedKeyOrFail(templateName).getWorkspace();
                newWorkspace.injectTemplate(ar, template_ngp);
            }
            newWorkspace.saveContent(ar, "workspace created from template: "+templateName);
            return newWorkspace;
        } catch (Exception ex) {
            throw new Exception("Unable to create a workspace from template for site "
                    +siteId, ex);
        }
    }

    private static void linkSubProcessToTask(AuthRequest ar, NGPage subProject, String goalId,
            String parentProcessUrl) throws Exception {

        int beginOfPageKey = parentProcessUrl.indexOf("/p/") + 3;
        int endOfPageKey = parentProcessUrl.indexOf("/", beginOfPageKey);
        String projectKey = parentProcessUrl.substring(beginOfPageKey, endOfPageKey);

        ProcessRecord process = subProject.getProcess();
        process.setSynopsis("Goal Setting");
        process.setDescription("Purpose of Workspace Setting");

        subProject.saveFile(ar, "Changed Goal and/or Purpose of Workspace");
        LicensedURL parentLicensedURL = null;

        if (parentProcessUrl != null && parentProcessUrl.length() > 0) {
            parentLicensedURL = LicensedURL.parseCombinedRepresentation(parentProcessUrl);
            process.addLicensedParent(parentLicensedURL);
        }
        // link up the project with the workspace task link
        if (parentLicensedURL != null) {
            LicensedURL thisUrl = process.getWfxmlLink(ar);

            // this is the subprocess address to link to
            String subProcessURL = thisUrl.getCombinedRepresentation();
            NGPage parentProject = ar.getCogInstance().getWSByCombinedKeyOrFail(projectKey).getWorkspace();

            GoalRecord goal = parentProject.getGoalOrFail(goalId);
            goal.setSub(subProcessURL);
            goal.setState(BaseRecord.STATE_WAITING);
            parentProject.saveFile(ar, "Linked with Subprocess");
        }
    }
    
    @RequestMapping(value = "/NewSiteApplication.htm", method = RequestMethod.GET)
    public void NewSiteApplication(HttpServletRequest request, HttpServletResponse response)
           throws Exception {
       try{
           AuthRequest ar = AuthRequest.getOrCreate(request, response);
           specialAnonJSP(ar, "N/A", "N/A", "NewSiteApplication.jsp");
       }catch(Exception ex){
           throw new Exception("Unable to display the Register New Site page", ex);
       }
   }
    
}
