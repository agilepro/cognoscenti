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

import java.io.IOException;
import java.io.Writer;
import java.util.Vector;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.socialbiz.cog.AuthRequest;
import org.socialbiz.cog.NGPageIndex;
import org.socialbiz.cog.exception.ServletExit;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.ApplicationContext;
import org.springframework.stereotype.Controller;
import org.springframework.ui.ModelMap;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.ModelAndView;

/**
 * this class contains all the JSON style REST web service requests
 * because error handling is defined on a class basis, and we need
 * correct error handling for JSON requests.
 */
@Controller
public class JSONController extends BaseController {

    private ApplicationContext context;
    @Autowired
    public void setContext(ApplicationContext context) {
        this.context = context;
    }



    @ExceptionHandler(Exception.class)
    public ModelAndView handleException(Exception ex, HttpServletRequest request, HttpServletResponse response) {

        //if a ServletExit has been thrown, then the browser has already been redirected,
        //so just return null and get out of here.
        if (ex instanceof ServletExit) {
            return null;
        }
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        sendErrorResponse(ar, "Unable to handle that JSON request", ex);
        return null;
    }

    public static void sendJSONResponse(AuthRequest ar, String responseMessage)
            throws IOException {
        ar.resp.setContentType("application/json; charset=UTF-8");
        ar.resp.setHeader("Cache-Control", "no-cache");
        Writer writer = ar.resp.getWriter();
        writer.write(responseMessage);
        writer.close();
    }

    public static void sendErrorResponse(AuthRequest ar, String errorcontext, Exception ex) {
        try {
            ar.resp.setContentType("text; charset=UTF-8");
            ar.resp.setHeader("Cache-Control", "no-cache");
            ar.resp.setStatus(500);
            Writer writer = ar.resp.getWriter();
            writer.write(errorcontext);
            Throwable runner = ex;
            while (runner!=null) {
                writer.write("\n");
                writer.write(runner.toString());
                runner = runner.getCause();
            }
            writer.close();
        }
        catch (Exception eee) {
            System.out.println("CRITICAL FAILURE reporting an exception: "+eee.toString());
            //don't report errors on reporting errors, just quit
        }
    }



    @RequestMapping(value = "/{siteId}/isProjectExist.ajax", method = RequestMethod.POST)
    public void isProjectExist(@RequestParam String siteId,
            ModelMap model, HttpServletRequest request,
            HttpServletResponse response) throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try {
            ar.assertLoggedIn("Must be logged in to check workspace name.");
            String message=projectNameValidity(siteId, ar,context);
            sendJSONResponse(ar, message);
        }
        catch (Exception e) {
            //not sure what to do here.  Expected response is in JSON format
            //but how then do we format errors?  Set the error code
            ar.logException("Unable to tell if workspace exists", e);
            sendErrorResponse(ar, "Unable to tell if workspace exists", e);
        }
    }

    @RequestMapping(value = "/{siteId}/{pageId}/isProjectExistOnSystem.ajax", method = RequestMethod.GET)
    public void isProjectExistOnSystem(@PathVariable String siteId,
            @RequestParam String projectname, HttpServletRequest request,
            HttpServletResponse response)
            throws Exception {
        String message = "";
        AuthRequest ar = null;

        try{
            ar = NGWebUtils.getAuthRequest(request, response,"Could not check workspace name.");

            message=projectNameValidity(siteId, ar,context);

        }catch(Exception ex){
            ar.logException(message, ex);
        }
        NGWebUtils.sendResponse(ar, message);

    }



    private static String projectNameValidity(String book, AuthRequest ar,
            ApplicationContext context) throws Exception {
        String message = "";
        String projectName = ar.reqParam("projectname");
        try {
            ar.getCogInstance().getSiteByIdOrFail(book);
            if (doesProjectExist(ar, projectName)) {
                message = NGWebUtils.getJSONMessage(Constant.YES, context.getMessage(
                        "nugen.userhome.project.name.already.exists",null, ar.getLocale()), "");
            } else {
                message = NGWebUtils.getJSONMessage(Constant.No, projectName,"");
            }
        } catch (Exception ex) {
            message = NGWebUtils.getExceptionMessageForAjaxRequest(ex, ar
                    .getLocale());
            ar.logException(message, ex);
        }
        return message;
    }


    public static boolean doesProjectExist(AuthRequest ar, String projectName) throws Exception {
        Vector<NGPageIndex> foundPages = ar.getCogInstance().getPageIndexByName(projectName);
        if (foundPages.size() > 0) {
            return true;
        }
        return false;
    }



}


