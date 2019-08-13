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
import java.net.URLEncoder;
import java.util.Properties;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.socialbiz.cog.AuthRequest;
import org.socialbiz.cog.Cognoscenti;
import org.socialbiz.cog.DOMFace;
import org.socialbiz.cog.NGBook;
import org.socialbiz.cog.NGContainer;
import org.socialbiz.cog.NGPageIndex;
import org.socialbiz.cog.NGWorkspace;
import org.socialbiz.cog.UserProfile;
import org.socialbiz.cog.exception.NGException;
import org.socialbiz.cog.exception.ServletExit;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.ExceptionHandler;

import com.purplehillsbooks.json.JSONArray;
import com.purplehillsbooks.json.JSONException;
import com.purplehillsbooks.json.JSONObject;
import com.purplehillsbooks.json.JSONTokener;

@Controller
public class BaseController {

    static boolean indentJson = false;
    static int latencyMillis = 0;

    /**
     * Call this from the initialization classes in order to configure how
     * the spring controller classes operate.
     */
    public static void initBaseController(Cognoscenti cog) {
        String indentStr = cog.getConfig().getProperty("indentJson");
        if (indentStr!=null && "true".equals(indentStr)) {
            indentJson = true;
        }
        String latencyStr = cog.getConfig().getProperty("latencyMillis");
        if (latencyStr!=null) {
            //number of milliseconds to delay for every call
            latencyMillis = DOMFace.safeConvertInt(latencyStr);
        }
    }


    @ExceptionHandler(Exception.class)
    public void handleException(Exception ex, HttpServletRequest request,
            HttpServletResponse response) {

        //if a ServletExit has been thrown, then the browser has already been redirected,
        //so just return null and get out of here.
        if (ex instanceof ServletExit) {
            return;
        }
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        displayException(ar, ex);
    }

    /**
     * Logs the exception in the tracker, and generates a 'nice' display of an exception.
     * This can be used when the exception
     * is predictable, such a parsing a URL and not finding the data that it should display.
     * You should also be aware of the problems of displaying an exception when the
     * system is truly breaking -- the support necessary to create the nice display
     * might not be functioning well enough to display anything.
     */
    private void displayException(AuthRequest ar, Exception extd) {
        try {
            long exceptionNO=ar.logException("Caught in user interface", extd);
            ar.req.setAttribute("display_exception", extd);
            ar.req.setAttribute("log_number", exceptionNO);
            ar.invokeJSP("/spring/anon/Error.jsp");
        }
        catch (Exception e) {
            JSONException.traceException(System.out, e,
                    "%%%%%% Exception while reporting exception in BaseController");
        }
    }

    protected static void showWarningView(AuthRequest ar, String why) throws Exception {
        ar.req.setAttribute("property_msg_key", why);
        streamJSP(ar, "Warning");
    }



    //////////////////////// JSP Wrapping and Streaming ////////////////////////////


    /**
     * This is a set of checks that results in different views depending on the state
     * of the user.  Particularly: must be logged in, must have a name, must have an email
     * address, and must be a member of the page, so the page has to be set as well.
     * @return a boolean: true means it produced a UI output, and false means it didnt
     */
    protected static boolean checkLogin(AuthRequest ar) throws Exception {
        if(!ar.isLoggedIn()){
            showWarningView(ar, "nugen.project.login.msg");
            return true;
        }
        if (needsToSetName(ar)) {
            streamJSP(ar, "requiredName");
            return true;
        }
        return false;
    }

    /**
     * If the site has been moved, display a page indicating this
     */
    protected static boolean checkMoved(AuthRequest ar) throws Exception {
        if (ar.ngp!=null && ar.ngp instanceof NGWorkspace) {
            NGWorkspace ngw = (NGWorkspace) ar.ngp;
            NGBook site = ngw.getSite();
            if (site.isMoved()) {
                streamJSP(ar, "Redirected");
                return true;
            }
        }
        return false;
    }

    /**
     * This is a set of checks that results in different views depending on the state
     * of the user.  Particularly: must be logged in, must have a name, must have an email
     * address, and must be a member of the page, so the page has to be set as well.
     * @return a boolean: true means it produced a UI output, and false means it didnt
     */
    protected static boolean checkLoginMember(AuthRequest ar) throws Exception {
        if (checkLogin(ar)) {
            return true;
        }
        if (ar.ngp==null) {
            throw new Exception("Program Logic Error: the method checkLoginMember was called BEFORE setting the NGWorkspace on the AuthRequest.");
        }
        if (ar.isSuperAdmin()) {
            //super admin is automatically a member of every group, no need to check further
            return false;
        }
        if(!ar.isMember()){
            ar.req.setAttribute("roleName", "Members");
            streamJSP(ar, "WarningNotMember");
            return true;
        }
        if (ar.getCogInstance().getUserManager().getAllSuperAdmins(ar).size()==0) {
            showWarningView(ar, "nugen.missingSuperAdmin");
            return true;
        }
        if (checkMoved(ar)) {
            return true;
        }
        return false;
    }

    /**
     * Checks that the project is OK to be updated.  Should be used for
     * forms that prompt for information to update the workspace.  In that
     * case a frozen (or deleted) workspace should not prompt for that update.
     * @throws Exception
     */
    protected static boolean checkLoginMemberFrozen(AuthRequest ar, NGContainer ngc) throws Exception {
        if (checkLoginMember(ar)) {
            return true;
        }
        boolean frozen = ngc.isFrozen();
        if (!frozen && (ngc instanceof NGWorkspace)) {
            frozen = ((NGWorkspace)ngc).getSite().isFrozen();
        }
        if (frozen) {
            streamJSP(ar, "WarningFrozen");
            return true;
        }
        return false;
    }




    protected static void streamJSP(AuthRequest ar, String jspName) throws Exception {
        //just to make sure there are no DOUBLE pages being sent
        if (ar.req.getAttribute("wrappedJSP")!=null) {
            throw new Exception("wrappedJSP has already been set to ("+ar.req.getAttribute("wrappedJSP")
                     +") when trying to set it to ("+jspName+")");
        }

        ar.req.setAttribute("wrappedJSP", jspName);
        ar.invokeJSP("/spring/jsp/Wrapper.jsp");
    }

    protected static void streamJSPLoggedIn(AuthRequest ar, String jspName) throws Exception {
        if (checkLogin(ar)){
            return;
        }
        streamJSP(ar, jspName);
    }


    /**
     * This is useful for pages that work on Containers, both Projects and Sites
     */
    public static NGContainer registerSiteOrProject(AuthRequest ar, String siteId, String pageId) throws Exception
    {
        if (pageId==null || "$".equals(pageId)) {
            ar.req.setAttribute("pageId",    "$");
            return prepareSiteView(ar, siteId);
        }
        else {
            return registerRequiredProject(ar, siteId, pageId );
        }
    }



    public static void showJSPAnonymous(AuthRequest ar, String siteId, String pageId, String jspName) throws Exception {
        try{
            registerSiteOrProject(ar, siteId, pageId);
            if (checkMoved(ar)) {
                return;
            }
            streamJSP(ar, jspName);
        }
        catch(Exception ex){
            throw new Exception("Unable to prepare JSP view of "+jspName+" for page ("+pageId+") in ("+siteId+")", ex);
        }
    }

    public static void showJSPLoggedIn(AuthRequest ar, String siteId, String pageId, String jspName) throws Exception {
        try{
            registerSiteOrProject(ar, siteId, pageId);
            if (checkLogin(ar)){
                return;
            }
            if (checkMoved(ar)) {
                return;
            }
            streamJSP(ar, jspName);
        }
        catch(Exception ex){
            throw new Exception("Unable to prepare JSP view of "+jspName+" for page ("+pageId+") in ("+siteId+")", ex);
        }
    }


    public static void showJSPMembers(AuthRequest ar, String siteId, String pageId, String jspName) throws Exception {
        try{
            registerSiteOrProject(ar, siteId, pageId);
            if (checkLoginMember(ar)){
                return;
            }
            streamJSP(ar, jspName);
        }
        catch(Exception ex){
            throw new Exception("Unable to prepare JSP view of "+jspName+" for page ("+pageId+") in ("+siteId+")", ex);
        }
    }


    public static void specialAnonJSP(AuthRequest ar, String siteId, String pageId, String jspName) throws Exception {
        try{
            ar.setParam("pageId", pageId);
            ar.setParam("siteId", siteId);
            ar.invokeJSP("/spring/anon/"+jspName);
        }
        catch(Exception ex){
            throw new Exception("Unable to prepare JSP view of anon/"+jspName+" for page ("+pageId+") in ("+siteId+")", ex);
        }
    }

    public static void showJSPNotFrozen(AuthRequest ar, String siteId, String pageId, String jspName) throws Exception {
        try{
            NGContainer ngc = registerSiteOrProject(ar, siteId, pageId);
            if (checkLoginMemberFrozen(ar, ngc)){
                return;
            }
            streamJSP(ar, jspName);
        }
        catch(Exception ex){
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
        ar.req.setAttribute("headerType", "project");
        ar.req.setAttribute("siteId",     siteId);
        ar.req.setAttribute("pageId",     pageId);
        NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail( siteId, pageId ).getWorkspace();
        if (!siteId.equals(ngw.getSiteKey())) {
            throw new NGException("nugen.operation.fail.account.match", new Object[]{pageId,siteId});
        }
        ar.setPageAccessLevels(ngw);
        ar.req.setAttribute("title", ngw.getFullName());
        return ngw;
    }

    public static NGBook prepareSiteView(AuthRequest ar, String siteId) throws Exception
    {
        ar.req.setAttribute("headerType", "site");
        ar.req.setAttribute("siteId",    siteId);
        ar.req.setAttribute("pageId",    "$");
        NGBook site = ar.getCogInstance().getSiteByIdOrFail( siteId );
        ar.setPageAccessLevels(site);
        ar.req.setAttribute("title", site.getFullName());
        return site;
    }


    public static AuthRequest getLoggedInAuthRequest(HttpServletRequest request,
            HttpServletResponse response, String assertLoggedInMsgKey) throws Exception {

        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        ar.assertLoggedIn(ar.getMessageFromPropertyFile(assertLoggedInMsgKey, null));
        return ar;
    }


    public static void sendRedirectToLogin(AuthRequest ar) throws Exception {
        String go = ar.getCompleteURL();
        String loginUrl = ar.getSystemProperty("identityProvider")+"?openid.mode=quick&go="+URLEncoder.encode(go, "UTF-8");
        ar.resp.sendRedirect(loginUrl);
        return;
    }


    protected void redirectBrowser(AuthRequest ar, String pageURL, Properties props) throws Exception {
        char joinChar = '?';
        StringBuilder sb = new StringBuilder(pageURL);
        for (String key : props.stringPropertyNames()) {
            String val = props.getProperty(key);
            sb.append(joinChar);
            sb.append(key);
            sb.append("=");
            sb.append(URLEncoder.encode(val, "UTF-8"));
        }
        ar.resp.sendRedirect(sb.toString());
    }

    /*
    * Pass in the relative URL and
    * this will redirect the browser to that address.
    * It will return nothing so that you can
    * say "return redirectToURL(myurl);"
    */
    protected void redirectBrowser(AuthRequest ar, String pageURL) throws Exception {
        ar.resp.sendRedirect(pageURL);
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
     * address, and must be a member of the page.
     * @return a boolean TRUE if UI output produced, FALSE if not.
     */
    protected boolean executiveCheckViews(AuthRequest ar) throws Exception {
        if(checkLogin(ar)){
            return true;
        }
        if(!ar.isMember()){
            ar.req.setAttribute("roleName", "Executive");
            showWarningView(ar, "nugen.project.executive.msg");
            return true;
        }
        if (ar.getCogInstance().getUserManager().getAllSuperAdmins(ar).size()==0) {
            showWarningView(ar, "nugen.missingSuperAdmin");
            return true;
        }
        return false;
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
            System.out.println("EXCEPTION (BaseController) tid="+Thread.currentThread().getId()+", unlock, "+ar.getCompleteURL());

            //if a project was registered, it will be removed from the cache, causing the next
            //access to come from the previously saved disk file
            ar.rollbackChanges();

            //let go of any locks you might have on any objects before entering the 3 second delay!
            NGPageIndex.clearLocksHeldByThisThread();

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

            //all exceptions are delayed by up to 5 seconds to avoid attempts to
            //mine for valid license numbers
            Thread.sleep(ar.ngsession.getErrorResponseDelay());

            ar.logException("EXCEPTION (BaseController)", e);

            JSONObject errorResponse = JSONException.convertToJSON(e, "BaseController Exception tid="+Thread.currentThread().getId());

            ar.resp.setStatus(400);
            ar.resp.setContentType("application/json");
            errorResponse.write(ar.resp.writer, 2, 0);
            ar.flush();
        } catch (Exception eeeee) {
            // nothing we can do here...
            System.out.println("DOUBLE EXCEPTION (BaseController) tid="+Thread.currentThread().getId()+", "+eeeee.toString());
        }
    }

    /**
     * This is a testing tool.  It is simply a delay.  In normal production
     * operation this delay should be zero in order to respond as quickly as
     * possible.  But in order to test latency situations, this can be a
     * one to three to ten second delay to slow down the response time.
     */
    private static void testLatencyDelay() {
        try {
            if (latencyMillis>0) {
                Thread.sleep(latencyMillis);
            }
        }
        catch (Exception e) {
            throw new RuntimeException("Exception during test latency delay", e);
        }
    }
    protected static void releaseLock() throws Exception {
        NGPageIndex.clearLocksHeldByThisThread();
        System.out.println("     locks released tid="+Thread.currentThread().getId()+" time="+(System.currentTimeMillis()%10000));
    }
    /**
     * Call this to properly send the JSON back to the client.
     * This should be the LAST thing of a JSON call
     */
    protected static void sendJson(AuthRequest ar, JSONObject jo) throws Exception {
        releaseLock();

        //this has no effect since getWriter has already been called
        ar.resp.setContentType("application/json");

        jo.put("serverTime", System.currentTimeMillis());
        testLatencyDelay();
        if (indentJson) {
            jo.write(ar.w, 2, 2);
        }
        else {
            jo.write(ar.w, 0, 0);
        }
        ar.flush();
    }

    /**
     * Should probably NEVER be sending an array, but there are some cases where it
     * was done and so this method supports it while cleaning them out.
     */
    protected static void sendJsonArray(AuthRequest ar, JSONArray jo) throws Exception {
        releaseLock();

        //this has no effect since getWriter has already been called
        ar.resp.setContentType("application/json");

        testLatencyDelay();
        if (indentJson) {
            jo.write(ar.w, 2, 2);
        }
        else {
            jo.write(ar.w, 0, 0);
        }
        ar.flush();
    }

    protected static void saveAndReleaseLock(NGWorkspace ngw, AuthRequest ar, String msg) throws Exception {
        ngw.saveFile(ar, msg);
        NGPageIndex.clearLocksHeldByThisThread();
    }
}


