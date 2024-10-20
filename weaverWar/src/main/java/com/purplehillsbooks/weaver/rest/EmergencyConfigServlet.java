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

package com.purplehillsbooks.weaver.rest;

import java.io.File;
import java.io.Writer;

import jakarta.servlet.ServletConfig;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import com.purplehillsbooks.weaver.Cognoscenti;
import com.purplehillsbooks.weaver.HttpServletResponseWithoutBug;
import com.purplehillsbooks.weaver.exception.ProgramLogicError;
import com.purplehillsbooks.weaver.exception.WeaverException;
import com.purplehillsbooks.json.JSONException;
import com.purplehillsbooks.json.JSONObject;
import com.purplehillsbooks.temps.TemplateJSONRetriever;
import com.purplehillsbooks.temps.TemplateStreamer;

/**
 * The emergency config servlet is used for special server states when the
 * server is
 * <ol>
 *   <li> unable to initialize itself due to configuration problem</li>
 *   <li> 'paused' off line for some administrative procedure</li>
 *   <li> starting up</li>
 *   <li> some administrative commands and functions</li>
 * </ol>
 *
 * When the server starts up, it reads configuration files, and other files
 * as necessary, in order to start up.  It is possible for files to be
 * corrupted or otherwise changed so that it is impossible for the server
 * to start up.  The server is responsible not only to read the configuration
 * settings, but to test the values that are necessary for basic running.
 *
 * If it detects a problem, then the server goes into the "uninitialized"
 * state.  When it is uninitialized, then any request for a page MUST
 * redirect to this emergency config page.
 *
 * The emergency config page allows for particular settings to be adjusted
 * in order to get the server running again.
 *
 * It is important that it test ONLY the situation that absolutely must
 * be correct for the server to operate.  It is naturally possible that some
 * aspects of the server might not be available, and it is assumed that
 * that capability is controlled by some administrator function or administrator
 * user interface.  This emergency config page is used when the server fails
 * to initialize itself, and can run without any assumptions about the
 * rest of the server running.
 *
 * SECURITY CONCERNS: Clearly we do not want unsecured access to be able to
 * change the configuration.  It might be possible to make the server point
 * at a different directory, and to serve up files it otherwise would
 * protect.  The security concerns are addressed because the emergency config
 * page is ONLY available when the server fails to initialize itself.
 * Any attempt to access this page when the server is initialized should
 * cause a redirect back to the original page, or an error report.
 * Any hacker who could cause the server to be mis-configured and fail to start,
 * would gain no additional capability from this page -- in other words
 * to cause the server to fail to start would require a far more intimate
 * access to the server than this emergency config form gives.
 *
 * Most people will see this form only the very first time a server starts,
 * and that is because the server is NOT YET configured, and this page allows
 * the user to do that.   Once configured, however, this page should never appear.
 *
 * IMPLEMENTATION: the page is very very simple: no graphics or colors, just the
 * most basic form possible.  This is to ensure that the page works without anything
 * else in the server working.
 *
 * TIME CONSIDERATIONS: there is a possibility that the server is hit with a number
 * of requests at the moment it is starting up.  This might lead people to get
 * the configuration page simply because they hit the server at exactly the
 * initialization time.   To guard against this, the requests should be delayed
 * and the initialization variable checked again after a delay.  Also, the browser
 * should be redirected to the config page, and if by the time the request for
 * the config page is made, the server is already initialized, then the browser
 * should be redirected back to the original page.
 *
 * USAGE: This servlet should be mapped to /init/*
 * All other servlets should test NGLeafIndex.isInitialized(), and if false
 * redirect to   /init/config.htm?go=<return address>
 *
 */
@SuppressWarnings("serial")
public class EmergencyConfigServlet extends jakarta.servlet.http.HttpServlet {


    public void doGet(HttpServletRequest req, HttpServletResponse resp) {
        try {
            resp = new HttpServletResponseWithoutBug(resp);
            String cmd = req.getParameter("cmd");
            if (cmd!=null && "admin".equals(cmd)) {
                //need to restrict this to logged in person who is an admin.....
                displayMsgPage(req, resp, new Exception(), "Admin.htm");
                return;
            }

            String go = req.getParameter("go");
            if (go==null) {
                //accessing without a go parameter might be an attempt to crawl all the pages
                //and this is simply an error.
                displayMsgPage(req, resp, new Exception("Problem with this request: URL must have a 'go' parameter"), "Error.htm");
                return;
            }

            Cognoscenti cog = Cognoscenti.getInstance(req);

            if (cog.isRunning()) {
                //this is the case that possibly the server was just now initialized, and now it has become
                //initialized since the browser was directed here, so redirect back to where you came from.
                //It is also possible that someone bookmarked the config page, and attempting to reach it
                //again, but the server is initialized now, and we can not allow access to config page.
                resp.sendRedirect(go);
                return;
            }
            if (cog.isPaused()) {
                displayMsgPage(req, resp, new Exception(), "Paused.htm");
                return;
            }
            if (cog.isFailed()) {
                displayConfigPage(req, resp);
                return;
            }
            //all other situations, display the testing/startup page
            displayMsgPage(req, resp, new Exception(), "Testing.htm");
        }
        catch (Exception e) {
            handleException(e, req, resp);
        }
    }



    public void doPost(HttpServletRequest req, HttpServletResponse resp) {
        try {

            String go = req.getParameter("go");

            if (go==null) {
                //accessing without a go parameter might be an attempt to crawl all the pages
                //and this is simply an error.
                throw WeaverException.newBasic("Emergency config page needs a 'go' parameter, none found.");
            }

            resp = new HttpServletResponseWithoutBug(resp);

            handleFormPost(req, resp);

            resp.sendRedirect(go);

        } 
        catch (Exception e) {
            handleException(e, req, resp);
        }
    }

    public void doPut(HttpServletRequest req, HttpServletResponse resp) {
        handleException(new Exception("Put operation not allowed on the emergency config servlet,"), req, resp);
    }

    public void doDelete(HttpServletRequest req, HttpServletResponse resp) {
        handleException(new Exception("Delete operation not allowed on the emergency config servlet,"), req, resp);
    }

    public void init(ServletConfig config)
          throws ServletException {
        //no initialization necessary
    }

    private void handleException(Exception e, HttpServletRequest req, HttpServletResponse resp) {
        try {
            displayMsgPage(req, resp, e, "Error.htm");
            return;
        } 
        catch (Exception eeeee) {
            // nothing we can do here...
        }
    }


    /**
    * This method needs to display the page without requiring any other service from the system
    * It does assume that the ConfigFile class is working properly.
    * There should be no fancy embellishments to the page, just very plain config page.
    */
    private void displayConfigPage(HttpServletRequest req, HttpServletResponse resp) throws Exception {

        Writer out = resp.getWriter();
        resp.setContentType("text/html;charset=UTF-8");
        Cognoscenti cog = Cognoscenti.getInstance(req);

        TemplateJSONRetriever ctr = getRetriever(req, cog);

        File templateFile = cog.getConfig().getFileFromRoot("init/InitErrorDisplay.htm");
        TemplateStreamer.streamTemplate(out, templateFile, "UTF-8", ctr);

        out.flush();
    }


    private TemplateJSONRetriever getRetriever(HttpServletRequest req, Cognoscenti cog) throws Exception {

        JSONObject jo = new JSONObject();
        Exception ex = cog.initializer.lastFailureMsg;

        if (ex!=null) {
            jo.put("exception", JSONException.convertToJSON(ex, ""));
        }

        jo.put("serverState", cog.initializer.getServerStateString());
        jo.put("go", req.getParameter("go"));
        jo.put("msg", ex.toString());

        paramTest(jo,cog, "baseURL");
        paramTest(jo,cog, "localConnections");
        pathTest(jo, cog, "libFolder");
        pathTest(jo, cog, "userFolder");

        return new TemplateJSONRetriever(jo);
    }
    private void paramTest(JSONObject jo, Cognoscenti cog, String paramName) throws Exception {
        String paramValue = cog.getConfig().getProperty(paramName);
        if (paramValue==null) {
            jo.put("param "+paramName, "-- null value found --");
            jo.put("color "+paramName, "red");
        }
        else if (paramValue.length()==0) {
            jo.put("param "+paramName, "-- zero length value found --");
            jo.put("color "+paramName, "red");
        }
        else {
            jo.put("param "+paramName, paramValue);
            jo.put("color "+paramName, "green");
        }
    }
    private void pathTest(JSONObject jo, Cognoscenti cog, String paramName) throws Exception {
        String paramValue = cog.getConfig().getProperty(paramName);
        if (paramValue==null) {
            jo.put("pathtest "+paramName, "-- null value found --");
            jo.put("color "+paramName, "red");
        }
        else if (paramValue.length()==0) {
            jo.put("pathtest "+paramName, "-- zero length value found --");
            jo.put("color "+paramName, "red");
        }
        else {
            File thisPath = new File(paramValue);
            if (!thisPath.exists()) {
                jo.put("pathtest "+paramName, paramValue + "(Path does NOT exist)");
                jo.put("color "+paramName, "red");
            }
            else {
                jo.put("pathtest "+paramName, paramValue + "(Path exists)");
                jo.put("color "+paramName, "green");
            }
        }

    }

    /**
    * This method needs to display the page without requiring any other service from the system
    * It does assume that the ConfigFile class is working properly.
    * There should be no fancy embellishments to the page, just very plain config page.
    */
    private void displayMsgPage(HttpServletRequest req, HttpServletResponse resp,
            Exception msg, String pageName) throws Exception {

        Cognoscenti cog = Cognoscenti.getInstance(req);
        Writer out = resp.getWriter();
        resp.setContentType("text/html;charset=UTF-8");

        String go = req.getParameter("go");
        if (go==null) {
            go = req.getRequestURL().toString();
        }
        TemplateJSONRetriever ctr = getRetriever(req, cog);

        File templateFile = cog.getConfig().getFileFromRoot("init/"+pageName);
        TemplateStreamer.streamTemplate(out, templateFile, "UTF-8", ctr);

        out.flush();
    }


    public static String getOrDefault(HttpServletRequest req, String paramName) throws Exception
    {
        Cognoscenti cog = Cognoscenti.getInstance(req);

        String val = req.getParameter(paramName);
        if (val==null) {
            val = cog.getConfig().getProperty(paramName);
        }
        return val;
    }


    private static synchronized void handleFormPost(HttpServletRequest req, HttpServletResponse resp) throws Exception
    {
        // IMPORTANT:
        // This method updates the configuration.   It is designed to work when the system is not properly
        // configured.  This means that we can not check authentication, and we can not assure that this is
        // being done by an authenticated user.  THEREFOR it is critical that this method works ONLY when
        // the configuration is broken.  In normal usage, the configuration is not broken, and no hacker,
        // can break in.   Actually, it works only when the server is not initialized, which is presumably
        // because the configuration is incorrect.
        Cognoscenti cog = Cognoscenti.getInstance(req);

        String option = req.getParameter("option");
        if (option == null)
        {
            throw WeaverException.newBasic("Post to config servlet must have an option parameter");
        }

        if (option.equals("Pause the Server")) {
            if (cog.isRunning()) {
                cog.initializer.pauseServer();
            }
            return;
        }
        if (option.equals("Restart the Server")) {
            if (cog.isPaused()) {
                cog.resumeServer();
            }
            return;
        }
        if (option.equals("Reinitialize Server")) {

            if (cog.isRunning()) {
                cog.pauseServer();
                Thread.sleep(3000);
            }

            //reinitialize the server with these settings
            cog.resumeServer();
            return;
        }
    }


    public static String endStringWithBS(String str)
    {
        if (str == null || str.length() == 0) {
            return str;
        }

        str = str.replace('\\', '/');

        if (str.length() > 0  && str.endsWith("/") == false) {
            str = str + "/";
        }

        return str;
    }



}
