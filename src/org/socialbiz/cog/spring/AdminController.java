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

import java.io.StringWriter;
import java.util.List;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.socialbiz.cog.AuthDummy;
import org.socialbiz.cog.AuthRequest;
import org.socialbiz.cog.BaseRecord;
import org.socialbiz.cog.EmailSender;
import org.socialbiz.cog.ErrorLog;
import org.socialbiz.cog.GoalRecord;
import org.socialbiz.cog.NGBook;
import org.socialbiz.cog.NGPage;
import org.socialbiz.cog.ProcessRecord;
import org.socialbiz.cog.SectionWiki;
import org.socialbiz.cog.UserManager;
import org.socialbiz.cog.UserPage;
import org.socialbiz.cog.dms.ResourceEntity;
import org.socialbiz.cog.exception.NGException;
import org.socialbiz.cog.exception.ProgramLogicError;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.servlet.ModelAndView;
import org.springframework.web.servlet.view.RedirectView;
import org.workcast.json.JSONObject;

@Controller
public class AdminController extends BaseController {

    @RequestMapping(value = "/{siteId}/{project}/changeGoal.form", method = RequestMethod.POST)
    public ModelAndView changeGoalHandler(@PathVariable String siteId,@PathVariable String project,
            HttpServletRequest request,
            HttpServletResponse response)
    throws Exception {
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            if(!ar.isLoggedIn()){
                return showWarningView(ar, "message.loginalert.see.page");
            }
            NGPage ngp = ar.getCogInstance().getProjectByKeyOrFail(project);
            ar.setPageAccessLevels(ngp);
            ar.assertAdmin("Unable to change the name of this page.");
            ar.assertNotFrozen(ngp);

            ProcessRecord process = ngp.getProcess();
            process.setSynopsis(ar.reqParam("goal"));
            process.setDescription(ar.reqParam("purpose"));

            ngp.saveFile(ar, "Changed Goal and/or Purpose of Project");
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.admin.change.goal", new Object[]{project,siteId} , ex);
        }
        return new ModelAndView(new RedirectView( "admin.htm"));
    }


    @RequestMapping(value = "/{siteId}/{project}/changeProjectName.form", method = RequestMethod.POST)
    public ModelAndView changeProjectNameHandler(@PathVariable String siteId,@PathVariable String project,
            HttpServletRequest request,
            HttpServletResponse response)
    throws Exception {

        ModelAndView modelAndView = null;
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            ar.assertLoggedIn("User must be logged in to change the name of project.");
            NGPage ngp = ar.getCogInstance().getProjectByKeyOrFail(project);
            ar.setPageAccessLevels(ngp);
            ar.assertAdmin("Unable to change the name of this page.");

            String newName = ar.reqParam("newName");
            String[] nameSet = ngp.getPageNames();

            //first, see if the new name is one of the old names, and if so
            //just rearrange the list
            int oldPos = findString(nameSet, newName);
            if (oldPos<0)
            {
                //we did not find the value, so just insert it
                nameSet = insertFront(nameSet, newName);
            }
            else
            {
                insertRemove(nameSet, newName, oldPos);
            }
            ngp.setPageNames(nameSet);

            ngp.saveFile(ar, "Change Name Action");

            modelAndView = new ModelAndView(new RedirectView( "admin.htm"));
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.admin.change.project.name", new Object[]{project,siteId} , ex);
        }
        return modelAndView;
    }

    @RequestMapping(value = "/{siteId}/{project}/deletePreviousProjectName.htm", method = RequestMethod.GET)
    public ModelAndView deletePreviousAccountNameHandler(@PathVariable String siteId, @PathVariable String project,
            HttpServletRequest request,
            HttpServletResponse response)
    throws Exception {

        ModelAndView modelAndView = null;
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            ar.assertLoggedIn("User must be logged in to delete previous name of project.");
            NGPage ngp = ar.getCogInstance().getProjectByKeyOrFail(project);
            ar.setPageAccessLevels(ngp);
            ar.assertAdmin("Unable to change the name of this page.");

            String oldName = ar.reqParam("oldName");

            String[] nameSet = ngp.getPageNames();
            int oldPos = findString(nameSet, oldName);

            if (oldPos>=0)
            {
                nameSet = shrink(nameSet, oldPos);
                ngp.setPageNames(nameSet);
            }
            ngp.saveFile(ar, "Change Name Action");

            modelAndView = new ModelAndView(new RedirectView( "admin.htm") );
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.admin.delete.previous.project.name", new Object[]{project,siteId} , ex);
        }
        return modelAndView;
    }

    @RequestMapping(value = "/{siteId}/$/changeAccountName.form", method = RequestMethod.POST)
    public ModelAndView changeAccountNameHandler(@PathVariable String siteId,
            HttpServletRequest request,
            HttpServletResponse response)
    throws Exception {
        ModelAndView modelAndView = null;
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            ar.assertLoggedIn("User must be logged in to delete previous name of site.");
            NGBook ngb = ar.getCogInstance().getSiteByIdOrFail(siteId);
            ar.setPageAccessLevels(ngb);
            ar.assertAdmin("Unable to change the name of this page.");

            String newName = ar.reqParam("newName");
            String[] nameSet = ngb.getSiteNames();
            //first, see if the new name is one of the old names, and if so
            //just rearrange the list
            int oldPos = findString(nameSet, newName);
            if (oldPos<0)
            {
                //we did not find the value, so just insert it
                nameSet = insertFront(nameSet, newName);
            }
            else
            {
                insertRemove(nameSet, newName, oldPos);
            }
            ngb.setSiteNames(nameSet);

            ngb.saveFile(ar, "Change Name Action");

            modelAndView = new ModelAndView(new RedirectView( "admin.htm"));
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.admin.change.account.name", new Object[]{siteId} , ex);
        }
        return modelAndView;
    }

    @RequestMapping(value = "/{siteId}/$/changeAccountDescription.form", method = RequestMethod.POST)
    public ModelAndView changeAccountDescriptionHandler(@PathVariable String siteId,
            HttpServletRequest request,
            HttpServletResponse response)
    throws Exception {

        ModelAndView modelAndView = null;
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            ar.assertLoggedIn("User must be logged in to change description of site.");
            NGBook site = ar.getCogInstance().getSiteByIdOrFail(siteId);
            ar.setPageAccessLevels(site);
            String action = ar.reqParam("action");
            ar.assertAdmin("Unable to change site settings.");
            if(action.equals("Change Description")){
                String newDesc = ar.reqParam("desc");
                site.setDescription( newDesc );
            }
            else if(action.equals("Change Theme")){
                String theme = ar.reqParam("theme");
                site.setThemeName(theme);
            }

            site.saveFile(ar, "Change Site Settings");

            modelAndView = new ModelAndView(new RedirectView( "admin.htm"));
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.admin.change.account.description", new Object[]{siteId} , ex);
        }
        return modelAndView;

    }

    @RequestMapping(value = "/{siteId}/$/deletePreviousAccountName.htm", method = RequestMethod.GET)
    public ModelAndView deletePreviousProjectNameHandler(@PathVariable String siteId,
            HttpServletRequest request,
            HttpServletResponse response)
    throws Exception {

        ModelAndView modelAndView = null;
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            ar.assertLoggedIn("User must be logged in to delete previous name of site.");
            NGBook site = ar.getCogInstance().getSiteByIdOrFail(siteId);
            ar.setPageAccessLevels(site);
            ar.assertAdmin("Unable to change the name of this page.");

            String oldName = ar.reqParam("oldName");

            String[] nameSet = site.getSiteNames();
            int oldPos = findString(nameSet, oldName);

            if (oldPos>=0)
            {
                nameSet = shrink(nameSet, oldPos);
                site.setSiteNames(nameSet);
            }

            site.saveFile(ar, "Change Name Action");

            modelAndView = new ModelAndView(new RedirectView( "admin.htm") );
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.admin.delete.previous.account.name", new Object[]{siteId} , ex);
        }
        return modelAndView;
    }

    // compare the sanitized versions of the names in the array, and if
    // the val equals one, return the index of that string, otherwise
    // return -1
    public int findString(String[] array, String val)
    {
        String sanVal = SectionWiki.sanitize(val);
        for (int i=0; i<array.length; i++)
        {
            String san2 = SectionWiki.sanitize(array[i]);
            if (sanVal.equals(san2))
            {
                return i;
            }
        }
        return -1;
    }

    //insert the specified value into the array, and shift the values
    //in the array up to the specified point.  The value at that position
    //will be effectively removed.  The values after that position remain
    //unchanged.
    public void insertRemove(String[] array, String val, int position)
    {
        String replaceVal = val;
        for (int i=0; i<position; i++)
        {
            String tmp = array[i];
            array[i] = replaceVal;
            replaceVal = tmp;
        }
        array[position] = replaceVal;
    }

    //insert at beginning, Returns a new string array that is
    //one value larger
    public String[] insertFront(String[] array, String val)
    {
        int len = array.length;
        String[] ret = new String[len+1];
        ret[0] = val;
        for (int i=0; i<len; i++)
        {
            ret[i+1] = array[i];
        }
        return ret;
    }

    //insert at beginning, Returns a new string array that is
    //one value larger
    public String[] shrink(String[] array, int pos)
    {
        int len = array.length;
        String[] ret = new String[len-1];
        for (int i=0; i<pos; i++)
        {
            ret[i] = array[i];
        }
        for (int i=pos+1; i<len; i++)
        {
            ret[i-1] = array[i];
        }
        return ret;
    }

    /**
     * The source of a web page is placed in a form field (in the browser) and posted
     * to this address.  That HTML page is validated, and the results displayed
     * as the resulting page.
     *
     * The validation is done by JTidyValidator which seems at this time to catch very
     * few errors.  We probably need to look for a better validator, or figure out
     * how to get it to be more careful.
     */
    @RequestMapping(value = "/validateHtml.validate", method = RequestMethod.POST)
    public ModelAndView validateHtml(HttpServletRequest request,
            HttpServletResponse response)
    throws Exception {
        ModelAndView modelAndView = null;
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            ar.assertLoggedIn("User must be logged in to validate HTML.");
            String htmlDom = ar.reqParam("output");

            JTidyValidator validator = new JTidyValidator();
            List<XHTMLError> errors = validator.validate(htmlDom, ar.w);

            modelAndView = new ModelAndView("htmlValidator");
            modelAndView.addObject("errors", errors);
            modelAndView.addObject("htmlSource", htmlDom);
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.admin.validate.html", null , ex);
        }
        return modelAndView;
    }

    @RequestMapping(value = "/sendErrortoAdmin.ajax", method = RequestMethod.POST)
    public void sendErrorToAdmin(HttpServletRequest request,
            HttpServletResponse response)
    throws Exception {
        AuthRequest ar = null;
        String message = "";
        try{
            ar = AuthRequest.getOrCreate(request, response);

            String htmlDom = ar.reqParam("errorData");
            String comments = ar.defParam("user_comments","");
            String errorId = ar.reqParam("errorId");
            String searchByDate = ar.reqParam("dateTime");
            long searchDate = Long.parseLong(searchByDate);
            ErrorLog eLog = ErrorLog.getLogForDate(searchDate, ar.getCogInstance());
            eLog.logUserComments(errorId, searchDate, comments);

            sendErrorMessageEmail( ar, htmlDom,comments );

            message = NGWebUtils.getJSONMessage(Constant.SUCCESS, "", "");
        }catch(Exception ex){
            message = NGWebUtils.getExceptionMessageForAjaxRequest(ex, ar.getLocale());
            ar.logException(message, ex);
        }
        NGWebUtils.sendResponse(ar, message);
    }

    private static void sendErrorMessageEmail(AuthRequest ar,String errorDOM,String comments)
    throws Exception
    {
        StringWriter bodyWriter = new StringWriter();
        AuthRequest clone = new AuthDummy(ar.getUserProfile(), bodyWriter, ar.getCogInstance());
        clone.setNewUI(true);
        clone.retPath = ar.baseURL;
        clone.write("<html><body>\n");
        clone.write("<p>User got the following error while using Cognoscenti. ");
        if(ar.getUserProfile()!=null){
            clone.write("Reported by ");
            ar.getUserProfile().writeLink( clone );
            clone.write( ". " );
        }

        clone.write("</p>");

        if(comments!=null && comments.length()>0){
            clone.write("<h3> Comments from User: </h3>");
            clone.write( "<p>" );
            clone.writeHtml( comments );
            clone.write( "</p>" );
        }

        clone.write( errorDOM);

        clone.write("<p>You are receiving this message because you are a Super Admin of this server.</p>");
        clone.write("</body></html>");
        EmailSender.simpleEmail(UserManager.getSuperAdminMailList(ar), null, "Error report",
                bodyWriter.toString(), ar.getCogInstance());
    }

    @RequestMapping(value = "/{siteId}/{project}/updateProjectSettings.ajax", method = RequestMethod.POST)
    public void updateProjectSettings(@PathVariable String siteId,@PathVariable String project,
            HttpServletRequest request,
            HttpServletResponse response)
    throws Exception {
        String responseMessage = "";
        AuthRequest ar = null;
        try{
            ar = NGWebUtils.getAuthRequest(request, response, "User must be logged in to update project settings.");

            NGPage ngp = ar.getCogInstance().getProjectByKeyOrFail(project);
            ar.setPageAccessLevels(ngp);
            ar.assertAdmin("Unable to change project settings.");
            String operation = ar.reqParam("operation");
            if("publicPermission".equals(operation)){
                ngp.setAllowPublic(ar.reqParam("allowPublic"));
            }else if("freezeProject".equals(operation)){
                ngp.freezeProject(ar);
            }else if("unfreezeProject".equals(operation)){
                ngp.unfreezeProject();
            }
            ngp.saveFile(ar, "Updated allow public document.");

            JSONObject jo = new JSONObject();
            jo.put(Constant.MSG_TYPE , Constant.SUCCESS);
            responseMessage = jo.toString();
        }
        catch(Exception ex){
            responseMessage = NGWebUtils.getExceptionMessageForAjaxRequest(ex, ar.getLocale());
            ar.logException("Caught by updateProjectSettings.ajax", ex);
        }
        NGWebUtils.sendResponse(ar, responseMessage);
    }

    @RequestMapping(value = "/{siteId}/{pageId}/updateProjectSettings.form", method = RequestMethod.POST)
    public ModelAndView updateProjectSettingsForm(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request,
            HttpServletResponse response)
    throws Exception {
        ModelAndView modelAndView = null;
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            ar.assertLoggedIn("User must be logged in to change the goal/purpose of project.");
            NGPage ngp = ar.getCogInstance().getProjectByKeyOrFail(pageId);
            ar.setPageAccessLevels(ngp);
            ar.assertAdmin("Unable to change the name of this page.");
            ar.assertNotFrozen(ngp);

            String symbol = ar.defParam("symbol", null);
            String action = ar.reqParam("action");

            if(action.equals("Update")){

                if (symbol!=null) {
                    UserPage uPage = ar.getUserPage();
                    ResourceEntity defFolder = uPage.getResourceFromSymbol(symbol);

                    //remember, if the default folder belongs to someone else, it will
                    //not be found using the above.
                    if (defFolder!=null) {
                        ngp.setDefRemoteFolder(defFolder);
                    }
                }
                ngp.saveFile(ar, "Updated default location of project.");
                modelAndView = new ModelAndView(new RedirectView( "admin.htm"));
                modelAndView.addObject("folderId", null);
                modelAndView.addObject("path", null);
            }else {
                throw new ProgramLogicError("updateProjectSettingsForm does not understand action '"+action+"'");
            }
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.admin.update.project.settings", new Object[]{siteId,pageId} , ex);
        }
        return modelAndView;
    }

    @RequestMapping(value = "/{siteId}/{project}/changeProjectSettings.form", method = RequestMethod.POST)
    public ModelAndView changeProjectSettings(@PathVariable String siteId,@PathVariable String project,
            HttpServletRequest request,
            HttpServletResponse response)
    throws Exception {
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            ar.assertLoggedIn("User must be logged in to change the settings of project.");
            NGPage ngp = ar.getCogInstance().getProjectByKeyOrFail(project);
            ar.setPageAccessLevels(ngp);
            ar.assertAdmin("Unable to change the name of this page.");

            ProcessRecord process = ngp.getProcess();
            process.setSynopsis(ar.defParam("goal",""));
            process.setDescription(ar.defParam("purpose",null));

            ngp.setUpstreamLink(ar.defParam("upstream",null));

            // setting public
            ngp.setAllowPublic(ar.defParam("allowPublic","no"));

            String projectMode = ar.reqParam("projectMode");
            if("freezedMode".equals(projectMode)){
                ngp.freezeProject(ar);
                ngp.markUnDeleted(ar);
            }else if("normalMode".equals(projectMode)){

                ngp.markUnDeleted(ar);
                ngp.unfreezeProject();
            }else if ("deletedMode".equals(projectMode))
            {

                ngp.markDeleted(ar);
                ngp.freezeProject(ar);
            }

            String symbol    = ar.defParam("symbol",null);
            if (symbol!=null) {
                UserPage uPage = ar.getUserPage();
                ResourceEntity defFolder = uPage.getResourceFromSymbol(symbol);

                if (defFolder!=null) {
                    //setting default location if it belows to the logged in user
                    ngp.setDefLocation(defFolder.getFullPath());
                    ngp.setDefFolderId(defFolder.getFolderId());
                    ngp.setDefUserKey(ar.getUserProfile().getKey());
                }
            }

            List<GoalRecord> tasks = ngp.getAllGoals();
            for (GoalRecord task : tasks){
                if("freezedMode".equals(projectMode) || "deletedMode".equals(projectMode)){
                    if(task.getState() == BaseRecord.STATE_ERROR ||
                            task.getState()  == BaseRecord.STATE_ACCEPTED ||
                            task.getState()  == BaseRecord.STATE_STARTED){
                        task.setLastState(String.valueOf(task.getState()));
                        task.setState(BaseRecord.STATE_FROZEN);
                    }
                }else{
                    if(task.getState() == BaseRecord.STATE_FROZEN){
                        task.setState(GoalRecord.safeConvertInt(task.getLastState()));
                    }
                }
            }

            ngp.setProjectMailId(ar.defParam("projectMailId",""));

            //This update is an admin operation, like changing the name or the
            //froze/deleted status.  We do not want these operations to change
            //the time stamp which is associated mainly with the content.
            //This preserves the old modified date and user.
            String oldModUser = ngp.getLastModifyUser();
            long   oldModTime = ngp.getLastModifyTime();
            ngp.save(oldModUser, oldModTime, "Changed Goal and/or Purpose of Project", ar.getCogInstance());
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.admin.update.project.settings",
                    new Object[]{project,siteId} , ex);
        }
        return new ModelAndView(new RedirectView( "admin.htm"));
    }
}
