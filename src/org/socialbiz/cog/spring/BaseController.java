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

import java.io.InputStream;
import java.io.PrintWriter;
import java.io.StringWriter;
import java.net.URLEncoder;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.socialbiz.cog.AuthRequest;
import org.socialbiz.cog.NGBook;
import org.socialbiz.cog.NGContainer;
import org.socialbiz.cog.NGPage;
import org.socialbiz.cog.NGWorkspace;
import org.socialbiz.cog.UserManager;
import org.socialbiz.cog.UserProfile;
import org.socialbiz.cog.exception.NGException;
import org.socialbiz.cog.exception.ServletExit;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.servlet.ModelAndView;
import org.springframework.web.servlet.view.RedirectView;
import org.workcast.json.JSONArray;
import org.workcast.json.JSONObject;
import org.workcast.json.JSONTokener;

@Controller
public class BaseController {

    @ExceptionHandler(Exception.class)
    public ModelAndView handleException(Exception ex, HttpServletRequest request,
            HttpServletResponse response) {

        //if a ServletExit has been thrown, then the browser has already been redirected,
        //so just return null and get out of here.
        if (ex instanceof ServletExit) {
            return null;
        }
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        return displayException(ar, ex);
    }

    /**
     * Logs the exception in the tracker, and generates a 'nice' display of an exception.
     * This can be used when the exception
     * is predictable, such a parsing a URL and not finding the data that it should display.
     * You should also be aware of the problems of displaying an exception when the
     * system is truly breaking -- the support necessary to create the nice display
     * might not be functioning well enough to display anything.
     */
    protected ModelAndView displayException(AuthRequest ar, Exception extd) {
        long exceptionNO=ar.logException("Caught in user interface", extd);
        ar.req.setAttribute("display_exception", extd);
        ar.req.setAttribute("log_number", exceptionNO);
        return new ModelAndView("DisplayException");
    }

    protected static ModelAndView showWarningView(AuthRequest ar, String why) {
        ar.req.setAttribute("property_msg_key", why);
        return new ModelAndView("Warning");
    }

    
    
    //////////////////////// JSP Wrapping and Streaming ////////////////////////////

    protected static void streamJSP(AuthRequest ar, String jspName) throws Exception {
        //just to make sure there are no DOUBLE pages being sent
        if (ar.req.getAttribute("wrappedJSP")!=null) {
            throw new Exception("wrappedJSP has already been set to ("+ar.req.getAttribute("wrappedJSP")
                     +") when trying to set it to ("+jspName+")");
        }
        
        ar.req.setAttribute("wrappedJSP", jspName);
        ar.invokeJSP("/spring/jsp/Wrapper.jsp");
    }

    protected static void streamJSPWarning(AuthRequest ar, String why) throws Exception {
        ar.req.setAttribute("property_msg_key", why);
        streamJSP(ar,"Warning");
    }

    protected static void streamJSPLoggedIn(AuthRequest ar, String jspName) throws Exception {
        if(!ar.isLoggedIn()){
            ar.req.setAttribute("property_msg_key", "nugen.project.login.msg");
            streamJSP(ar, "Warning");
            return;
        }
        if (needsToSetName(ar)) {
            streamJSP(ar, "requiredName");
            return;
        }
        streamJSP(ar, jspName);
    }
    
    public static void showJSPAnonymous(AuthRequest ar, String siteId, String pageId, String jspName) throws Exception {
        try{
            if (pageId==null) {
                prepareSiteView(ar, siteId);
            }
            else {
                registerRequiredProject(ar, siteId, pageId);
            }
            streamJSP(ar, jspName);
        }
        catch(Exception ex){
            System.out.println("Unable to prepare JSP view of "+jspName+": "+ex.toString());
            throw new Exception("Unable to prepare JSP view of "+jspName+" for page ("+pageId+") in ("+siteId+")", ex);
        }
    }

    public static void showJSPLoggedIn(AuthRequest ar, String siteId, String pageId, String jspName) throws Exception {
        try{
            if(!ar.isLoggedIn()){
                ar.req.setAttribute("property_msg_key", "nugen.project.login.msg");
                streamJSP(ar, "Warning");
                return;
            }
            if (needsToSetName(ar)) {
                streamJSP(ar, "requiredName");
                return;
            }
            registerRequiredProject(ar, siteId, pageId);
            streamJSP(ar, jspName);
        }
        catch(Exception ex){
            System.out.println("Unable to prepare JSP view of "+jspName+": "+ex.toString());
            throw new Exception("Unable to prepare JSP view of "+jspName+" for page ("+pageId+") in ("+siteId+")", ex);
        }
    }
    
    
    public static void showJSPMembers(AuthRequest ar, String siteId, String pageId, String jspName) throws Exception {
        try{
            if(!ar.isLoggedIn()){
                ar.req.setAttribute("property_msg_key", "nugen.project.login.msg");
                streamJSP(ar, "Warning");
                return;
            }
            if (needsToSetName(ar)) {
                streamJSP(ar, "requiredName");
                return;
            }
            if (pageId==null) {
                prepareSiteView(ar, siteId);
            }
            else {
                registerRequiredProject(ar, siteId, pageId);
            }
            if(!ar.isMember()){
                ar.req.setAttribute("roleName", "Members");
                streamJSP(ar, "WarningNotMember");
                return;
            }
            if (UserManager.getAllSuperAdmins(ar).size()==0) {
                ar.req.setAttribute("property_msg_key", "nugen.missingSuperAdmin");
                streamJSP(ar, "Warning");
                return;
            }
            streamJSP(ar, jspName);
        }
        catch(Exception ex){
            System.out.println("Unable to prepare JSP view of "+jspName+": "+ex.toString());
            throw new Exception("Unable to prepare JSP view of "+jspName+" for page ("+pageId+") in ("+siteId+")", ex);
        }
    }
    
    

    /**
     * This is a convenience function for all handlers that have the account and project
     * in the URL.
     *
     * (1) This will validate those values.
     * (2) Read the project.
     * (3) Sets the access level to the page
     * (4) Set the header type to be project
     * (5) Throws and exception if anything is wrong.
     *
     * Will ALSO set two request attributes needed by the JSP files.
     */
    public static NGWorkspace registerRequiredProject(AuthRequest ar, String siteId, String pageId) throws Exception
    {
        ar.req.setAttribute("pageId",     pageId);
        ar.req.setAttribute("book",       siteId);
        ar.req.setAttribute("headerType", "project");
        ar.getCogInstance().getSiteByIdOrFail(siteId);
        NGWorkspace ngw = ar.getCogInstance().getProjectByKeyOrFail( pageId );
        if (!siteId.equals(ngw.getSiteKey())) {
            throw new NGException("nugen.operation.fail.account.match", new Object[]{pageId,siteId});
        }
        ar.setPageAccessLevels(ngw);
        ar.req.setAttribute("title", ngw.getFullName());
        return ngw;
    }

    public static NGBook prepareSiteView(AuthRequest ar, String siteId) throws Exception
    {
        ar.req.setAttribute("accountId", siteId);
        ar.req.setAttribute("book",      siteId);
        ar.req.setAttribute("headerType", "site");
        NGBook account = ar.getCogInstance().getSiteByIdOrFail( siteId );
        ar.setPageAccessLevels(account);
        ar.req.setAttribute("title", account.getFullName());
        return account;
    }

    /**
     * This is useful for pages that work on Containers, both Projects and Sites
     */
    public static NGContainer registerSiteOrProject(AuthRequest ar, String siteId, String pageId) throws Exception
    {
        if ("$".equals(pageId)) {
            ar.req.setAttribute("pageId",    "$");
            return prepareSiteView(ar, siteId);
        }
        else {
            return registerRequiredProject(ar, siteId, pageId );
        }
    }


    public static AuthRequest getLoggedInAuthRequest(HttpServletRequest request,
            HttpServletResponse response, String assertLoggedInMsgKey) throws Exception {

        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        ar.assertLoggedIn(ar.getMessageFromPropertyFile(assertLoggedInMsgKey, null));
        return ar;
    }

    public ModelAndView createRedirectView(AuthRequest ar, String redirectAddress) throws Exception {
        return new ModelAndView(new RedirectView(redirectAddress));
    }

    public ModelAndView createNamedView(String siteId, String pageId,
            AuthRequest ar,  String viewName)
            throws Exception {
        ar.req.setAttribute("book", siteId);
        ar.req.setAttribute("pageId", pageId);
        ar.req.setAttribute("realRequestURL", ar.getRequestURL());
        return new ModelAndView(viewName);
    }


    public static void sendRedirectToLogin(AuthRequest ar) throws Exception {
        String go = ar.getCompleteURL();
        String loginUrl = ar.getSystemProperty("identityProvider")+"?openid.mode=quick&go="+URLEncoder.encode(go, "UTF-8");
        ar.resp.sendRedirect(loginUrl);
        return;
    }


    /*
    * Pass in the relative URL and
    * this will redirect the browser to that address.
    * It will return a null ModelAndView object so that you can
    * say "return redirectToURL(myurl);"
    */
    protected ModelAndView redirectBrowser(AuthRequest ar, String pageURL) throws Exception
    {
        ar.resp.sendRedirect(pageURL);
        return null;
    }

    protected static boolean needsToSetName(AuthRequest ar) throws Exception {
        if (!ar.isLoggedIn()) {
            return false;
        }
        UserProfile up = ar.getUserProfile();
        String displayName = up.getName();
        return displayName == null || displayName.length()==0;
    }


    /**
     * This is a set of checks that results in different views depending on the state
     * of the user.  Particularly: must be logged in, must have a name, must have an email
     * address, and must be a member of the page, so the page has to be set as well.
     * @return a ModelAndView object that will tell the user what is wrong.
     *         and return a NULL if logged in, member, and all config is OK
     */
    protected ModelAndView checkLogin(AuthRequest ar) throws Exception {
        if(!ar.isLoggedIn()){
            return showWarningView(ar, "nugen.project.login.msg");
        }
        if (needsToSetName(ar)) {
            return new ModelAndView("requiredName");
        }
        return null;
    }

    /**
     * This is a set of checks that results in different views depending on the state
     * of the user.  Particularly: must be logged in, must have a name, must have an email
     * address, and must be a member of the page, so the page has to be set as well.
     * @return a ModelAndView object that will tell the user what is wrong.
     *         and return a NULL if logged in, member, and all config is OK
     */
    protected ModelAndView checkLoginMember(AuthRequest ar) throws Exception {
        ModelAndView mav = checkLogin(ar);
        if (mav!=null) {
            return mav;
        }
        if (ar.ngp==null) {
            throw new Exception("Program Logic Error: the method checkLoginMember was called BEFORE setting the NGPage on the AuthRequest.");
        }
        if(!ar.isMember()){
            ar.req.setAttribute("roleName", "Members");
            return new ModelAndView("WarningNotMember");
        }
        if (UserManager.getAllSuperAdmins(ar).size()==0) {
            return showWarningView(ar, "nugen.missingSuperAdmin");
        }
        return null;
    }

    /**
     * Checks that the project is OK to be updated.  Should be used for
     * forms that prompt for information to update the workspace.  In that
     * case a frozen (or deleted) workspace should not prompt for that update.
     * @throws Exception
     */
    protected ModelAndView checkLoginMemberFrozen(AuthRequest ar, NGPage ngp) throws Exception {
        ModelAndView modelAndView = checkLoginMember(ar);
        if (modelAndView!=null) {
            return modelAndView;
        }
        if(ngp.isFrozen()){
            return showWarningView(ar, "nugen.generatInfo.Frozen");
        }
        return null;
    }

    /**
     * This is a set of checks that results in different views depending on the state
     * of the user.  Particularly: must be logged in, must have a name, must have an email
     * address, and must be a member of the page.
     * @return a ModelAndView object that will tell the user what is wrong.
     */
    protected ModelAndView executiveCheckViews(AuthRequest ar) throws Exception {
        if(!ar.isLoggedIn()){
            return showWarningView(ar, "nugen.project.login.msg");
        }
        if(!ar.isMember()){
            ar.req.setAttribute("roleName", "Executive");
            return showWarningView(ar, "nugen.project.executive.msg");
        }
        if (UserManager.getAllSuperAdmins(ar).size()==0) {
            return showWarningView(ar, "nugen.missingSuperAdmin");
        }
        return null;
    }

    protected JSONObject getPostedObject(AuthRequest ar) throws Exception {
        InputStream is = ar.req.getInputStream();
        JSONTokener jt = new JSONTokener(is);
        JSONObject objIn = new JSONObject(jt);
        is.close();
        return objIn;
    }

    protected void streamException(Exception e, AuthRequest ar) {
        try {
            //if a project was registered, it will be removed from the cache, causing the next
            //access to come from the previously saved disk file
            ar.rollbackChanges();

            //all exceptions are delayed by 3 seconds to avoid attempts to
            //mine for valid license numbers
            Thread.sleep(ar.ngsession.getErrorResponseDelay());

            System.out.println("USER_CONTROLLER_ERROR: "+ar.getCompleteURL());

            ar.logException("API Servlet", e);

            JSONObject errorResponse = new JSONObject();
            errorResponse.put("responseCode", 500);
            JSONObject exception = new JSONObject();
            errorResponse.put("exception", exception);

            JSONArray msgs = new JSONArray();
            Throwable runner = e;
            while (runner!=null) {
                String oneMsg = runner.toString();
                int pos = oneMsg.indexOf("Exception: ");
                if (pos>=0) {
                    oneMsg = oneMsg.substring(pos+11);
                }
                System.out.println("    ERROR: "+oneMsg);
                msgs.put(oneMsg);
                runner = runner.getCause();
            }
            exception.put("msgs", msgs);

            StringWriter sw = new StringWriter();
            e.printStackTrace(new PrintWriter(sw));
            exception.put("stack", sw.toString());

            ar.resp.setStatus(400);
            ar.resp.setContentType("application/json");
            errorResponse.write(ar.resp.writer, 2, 0);
            ar.flush();
        } catch (Exception eeeee) {
            // nothing we can do here...
            ar.logException("User Controller Error Within Error", eeeee);
        }
    }

}


