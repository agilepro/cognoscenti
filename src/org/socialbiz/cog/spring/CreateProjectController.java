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

import java.io.File;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.socialbiz.cog.AgentRule;
import org.socialbiz.cog.AuthRequest;
import org.socialbiz.cog.BaseRecord;
import org.socialbiz.cog.Cognoscenti;
import org.socialbiz.cog.GoalRecord;
import org.socialbiz.cog.HistoricActions;
import org.socialbiz.cog.IdGenerator;
import org.socialbiz.cog.LicensedURL;
import org.socialbiz.cog.NGBook;
import org.socialbiz.cog.NGPage;
import org.socialbiz.cog.NGPageIndex;
import org.socialbiz.cog.ProcessRecord;
import org.socialbiz.cog.RemoteGoal;
import org.socialbiz.cog.SectionWiki;
import org.socialbiz.cog.UserManager;
import org.socialbiz.cog.UserPage;
import org.socialbiz.cog.UserProfile;
import org.socialbiz.cog.api.ProjectSync;
import org.socialbiz.cog.api.RemoteProject;
import org.socialbiz.cog.exception.NGException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.ApplicationContext;
import org.springframework.stereotype.Controller;
import org.springframework.ui.ModelMap;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.servlet.ModelAndView;
import org.springframework.web.servlet.view.RedirectView;

/**
 * This class will handle all requests that are coming to create a new Project.
 * Currently this is handling only requests that are coming to create a new
 * project from scratch. Later this can be extended to edit a project or to
 * create a project from Template.
 */
@Controller
public class CreateProjectController extends BaseController {


    private ApplicationContext context;
    @Autowired
    public void setContext(ApplicationContext context) {
        this.context = context;
    }

    @RequestMapping(value = "/{siteId}/{pageId}/addmemberrole.htm", method = RequestMethod.GET)
    public ModelAndView addMemberRole(@PathVariable String siteId,@PathVariable String pageId,HttpServletRequest request,
            HttpServletResponse response) throws Exception
    {
        ModelAndView modelAndView = null;
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            if(!ar.isLoggedIn()){
                return showWarningView(ar, "message.loginalert.see.page");
            }
            NGPage page = registerRequiredProject(ar, siteId, pageId);

            String invitedUser = ar.defParam( "invitedUser","false" );

            String action = ar.defParam( "action","submit" );
            if(!action.equals( "cancel" )){
                String roleName = ar.reqParam("roleList");
                String userList = ar.reqParam("rolemember");
                HistoricActions ha = new HistoricActions(ar);
                ha.addMembersToRole(page, page.getRoleOrFail(roleName), userList, true);
                page.saveFile(ar, "Add New Members ("+userList+") to Role "+roleName);
            }
            if(invitedUser.equals( "true" )){
                modelAndView = new ModelAndView(new RedirectView("projectActiveTasks.htm"));
            }else{
                modelAndView = new ModelAndView(new RedirectView("permission.htm"));
            }
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.project.add.member.role", new Object[]{pageId,siteId} , ex);
        }
        return modelAndView;
    }

    @RequestMapping(value = "/getProjectNames.ajax", method = RequestMethod.POST)
    public void getProjectNames(HttpServletRequest request,
            HttpServletResponse response) throws Exception {
        String message="";
        AuthRequest ar = null;
        try{
            ar = NGWebUtils.getAuthRequest(request, response, "Could not find project name.");

            String matchKey = ar.defParam("matchkey", "").trim();
            String projects = getAllProjectFullNameList(matchKey, ar.getCogInstance());

            if(projects.length() >0){
                message = NGWebUtils.getJSONMessage(Constant.SUCCESS , projects , "");
            }else{
                message = NGWebUtils.getJSONMessage(Constant.FAILURE , context.getMessage("nugen.no.project.found",null, ar.getLocale()) , "");
            }
        }
        catch(Exception ex){
            message = NGWebUtils.getExceptionMessageForAjaxRequest(ex, ar.getLocale());
            ar.logException(message, ex);
        }
        NGWebUtils.sendResponse(ar, message);
    }

    private String getAllProjectFullNameList(String matchKey, Cognoscenti cog) throws Exception {
        StringBuffer sb = new StringBuffer();
        boolean addComma = false;

        for (NGPageIndex page : cog.getAllContainers()) {
            if (page.containerName.toLowerCase().startsWith(matchKey.toLowerCase())) {
                if (addComma) {
                    sb.append(",");
                }
                sb.append(page.containerName);
                sb.append(":");
                sb.append(page.pageBookKey);
                sb.append("/");
                sb.append(page.containerKey);
                addComma = true;
            }
        }
        return sb.toString();
    }


    @RequestMapping(value = "/getProjects.ajax", method = RequestMethod.GET)
    public void getProjects(HttpServletRequest request,
            HttpServletResponse response) throws Exception {
        AuthRequest ar = null;
        try{
            ar = NGWebUtils.getAuthRequest(request, response, "can not get projects");
            String matchKey = ar.defParam("matchkey", "").trim();
            String bookKey = ar.defParam("book", "").trim();

            String projects = getProjectFullNameList(matchKey,bookKey,
                    ar.getCogInstance());
            NGWebUtils.sendResponse(ar, projects);
        }
        catch(Exception ex){
            String message = NGWebUtils.getExceptionMessageForAjaxRequest(ex, ar.getLocale());
            ar.logException(message, ex);
        }
    }


    public String getProjectFullNameList(String matchKey, String bookKey,
            Cognoscenti cog) throws Exception {
        StringBuffer sb = new StringBuffer();
        boolean addComma = false;

        for (NGPageIndex page : cog.getAllProjectsInSite(bookKey)) {
            if (page.containerName.toLowerCase().startsWith(matchKey.toLowerCase())) {
                if (addComma) {
                    sb.append(",");
                }
                sb.append(page.containerName);
                addComma = true;
            }
        }
        String str = sb.toString();
        return str;
    }


    //the unknown part of the path may be either a user id or an account id
    //because this is used in two different places.  Should reconsider this.
    @RequestMapping(value = "/{siteId}/$/createprojectFromTemplate.form", method = RequestMethod.POST)
    public void createprojectFromTemplate(@PathVariable String siteId, HttpServletRequest request,
            HttpServletResponse response) throws Exception
    {
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            if(!ar.isLoggedIn()){
                sendRedirectToLogin(ar, "message.login.to.create.page",null);
                return;
            }
            NGPage project= createTemplateProject(ar,siteId);
            project.saveFile(ar, "Created new project");

            String upstream = project.getUpstreamLink();
            if (upstream!=null && upstream.length()>0) {
                //instead of synchronizing in a single action, redirecting allows us to free up the
                //locks on the site object before trying to synchronize.  Otherwise we get a
                //deadlock when pulling from the same site.  It also gives better feedback to the
                //user about progress, and educates first time users about synchronizing.
                response.sendRedirect(ar.retPath+"t/"+siteId+"/"+project.getKey()+"/SyncAttachment.htm");
            }
            else {
                response.sendRedirect(ar.retPath+ar.getDefaultURL(project));
            }
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.create.project.from.template", new Object[]{siteId} , ex);
        }
    }


    @RequestMapping(value = "/{siteId}/$/createClone.form", method = RequestMethod.POST)
    public void createClone(@PathVariable String siteId, HttpServletRequest request,
            HttpServletResponse response) throws Exception
    {
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            if(!ar.isLoggedIn()){
                sendRedirectToLogin(ar, "message.login.to.create.page",null);
                return;
            }

            String upstream = ar.reqParam("upstream");
            RemoteProject rp = new RemoteProject(upstream);

            String remoteName = rp.getName();

            NGBook site = ar.getCogInstance().getSiteByIdOrFail(siteId);

            NGPage project = createPage(ar.getUserProfile(), site, remoteName+"(clone)", null, upstream, ar.nowTime, ar.getCogInstance());
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
                sendRedirectToLogin(ar, "message.login.create.template.from.project",null);
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
                sendRedirectToLogin(ar, "message.login.create.template.from.project",null);
                return;
            }
            String goUrl = ar.reqParam("goUrl");
            String siteId=ar.reqParam("siteId");

            NGPage project= createTemplateProject(ar,siteId);

            if (goUrl==null) {
                goUrl = ar.retPath+ar.getDefaultURL(project);
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
                sendRedirectToLogin(ar, "message.login.create.template.from.project",null);
                return;
            }
            NGPage created = createProjectFromAgentRules(ar);
            String goUrl = "Agents.htm";
            if (created!=null){
                goUrl = ar.baseURL + ar.getDefaultURL(created);
            }
            response.sendRedirect(goUrl);
        }catch(Exception ex){
            throw new Exception("Failed to create project for user "+userId, ex);
        }
    }

    private NGPage createProjectFromAgentRules(AuthRequest ar) throws Exception {
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
                NGPage newPage = ar.getCogInstance().getProjectByUpstreamLink(upstream);
                if (newPage!=null) {
                    //looks like a clone already exists, so nothing more to do with this one
                    continue;
                }

                //found one, now use it
                String siteId = rule.getSiteKey();
                String templateKey = rule.getTemplate();
                String projectName = rg.getProjectName() + " (clone)";
                UserProfile owner = UserManager.findUserByAnyIdOrFail(rule.getOwner());
                NGBook site = ar.getCogInstance().getSiteByIdOrFail(siteId);
                newPage = createPage(owner, site, projectName, null, upstream, ar.nowTime, ar.getCogInstance());
                if (templateKey!=null && templateKey.length()>0) {
                    NGPage template_ngp = ar.getCogInstance().getProjectByKeyOrFail(templateKey);
                    newPage.injectTemplate(ar, template_ngp);
                }
                if (upstream!=null && upstream.length()>0) {
                    RemoteProject remProj = new RemoteProject(upstream);
                    ProjectSync ps = new ProjectSync(newPage, remProj, ar, "xxx");
                    ps.downloadAll();
                }

                return newPage;
            }
        }
        return null;
    }

    ////////////////// HELPER FUNCTIONS /////////////////////////////////


    private static String sanitizeHyphenate(String p) throws Exception {
        String plc = p.toLowerCase();
        StringBuffer result = new StringBuffer();
        boolean wasPunctuation = false;
        for (int i = 0; i < plc.length(); i++) {
            char ch = plc.charAt(i);
            boolean isAlphaNum = ((ch >= 'a') && (ch <= 'z'))
                    || ((ch >= '0') && (ch <= '9'));
            if (isAlphaNum) {
                if (wasPunctuation) {
                    result.append('-');
                    wasPunctuation = false;
                }
                result.append(ch);
            } else {
                wasPunctuation = true;
            }
        }
        return result.toString();
    }

    private static String findGoodFileName(String pt) throws Exception {
        String p = sanitizeHyphenate(pt);
        if (p.length() == 0) {
            p = IdGenerator.generateKey();
        }
        String extp = p;
        int incrementedExtension = 0;
        while (true) {
            File theFile = NGPage.getPathInDataFolder(extp + ".sp");
            if (!theFile.exists()) {
                return extp;
            }
            extp = p + "-" + (++incrementedExtension);
        }
    }


    private static NGPage createPage(AuthRequest ar, NGBook site)
            throws Exception {
        UserProfile uProf = ar.getUserProfile();
        long nowTime       = ar.nowTime;
        String projectName = ar.reqParam("projectname");
        String loc         = ar.defParam("loc", null);
        String upstream    = ar.defParam("upstream", null);
        NGPage newPage = createPage(uProf, site, projectName, loc, upstream, nowTime, ar.getCogInstance());
        ar.setPageAccessLevels(newPage);
        return newPage;
    }

    private static NGPage createPage(UserProfile uProf, NGBook site, String projectName,
            String loc, String upstream, long nowTime, Cognoscenti cog) throws Exception {
        if (!site.primaryOrSecondaryPermission(uProf)) {
            throw new NGException("nugen.exception.not.member.of.account",
                    new Object[]{site.getFullName()});
        }

        NGPage ngPage = null;
        if (loc==null){
            String projectFileName = findGoodFileName(projectName);
            String pageKey = SectionWiki.sanitize(projectFileName);
            ngPage = site.createProjectByKey(uProf, pageKey, nowTime, cog);
            String[] nameSet = new String[] { projectName };
            ngPage.setPageNames(nameSet);
        }
        else {
            //in this case, loc is a path from the root of the site
            //to a folder that the project should be created in.
            File siteRoot = site.getSiteRootFolder();
            if (siteRoot == null) {
                throw new Exception("Failed to create project at specified site because site does "
                        +"not have a root folder for some reason: "+site.getFullName());
            }
            File expectedLoc = new File(siteRoot, loc);
            if (!expectedLoc.exists()) {
                throw new Exception("Failed to create project because location does not exist: "
                        + expectedLoc.toString());
            }

            ngPage = site.convertFolderToProj(uProf, expectedLoc, nowTime, cog);
        }


        //check for and set the upstream link
        if (upstream!=null && upstream.length()>0) {
            ngPage.setUpstreamLink(upstream);
        }

        ngPage.setSite(site);
        ngPage.save(uProf.getUniversalId(), nowTime, "Creating a project", cog);

        cog.makeIndex(ngPage);

        return ngPage;
    }

    private static NGPage createTemplateProject(AuthRequest ar, String siteId) throws Exception {
        try {

            NGBook site = ar.getCogInstance().getSiteByIdOrFail(siteId);
            if (!site.primaryOrSecondaryPermission(ar.getUserProfile())) {
                throw new NGException("nugen.exception.not.a.member.of.account",
                        new Object[] { site.getFullName() });
            }

            NGPage project = createPage(ar, site);

            String templateName = ar.defParam("templateName", null);
            if (templateName!=null && templateName.length()>0) {
                NGPage template_ngp = ar.getCogInstance().getProjectByKeyOrFail(templateName);
                project.injectTemplate(ar, template_ngp);
            }
            return project;
        } catch (Exception ex) {
            throw new Exception("Unable to create a project from template for site "
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
        process.setDescription("Purpose of Projec Setting");

        subProject.saveFile(ar, "Changed Goal and/or Purpose of Project");
        LicensedURL parentLicensedURL = null;

        if (parentProcessUrl != null && parentProcessUrl.length() > 0) {
            parentLicensedURL = LicensedURL.parseCombinedRepresentation(parentProcessUrl);
            process.addLicensedParent(parentLicensedURL);
        }
        // link up the project with the parent task link
        if (parentLicensedURL != null) {
            LicensedURL thisUrl = process.getWfxmlLink(ar);

            // this is the subprocess address to link to
            String subProcessURL = thisUrl.getCombinedRepresentation();
            NGPage parentProject = ar.getCogInstance().getProjectByKeyOrFail(projectKey);

            GoalRecord goal = parentProject.getGoalOrFail(goalId);
            goal.setSub(subProcessURL);
            goal.setState(BaseRecord.STATE_WAITING);
            parentProject.saveFile(ar, "Linked with Subprocess");
        }
    }
}
