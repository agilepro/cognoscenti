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

import java.io.IOException;
import java.io.Writer;
import java.util.List;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import com.purplehillsbooks.weaver.AuthRequest;
import com.purplehillsbooks.weaver.NGPageIndex;
import com.purplehillsbooks.weaver.exception.ServletExit;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.ExceptionHandler;

/**
 * this class contains all the JSON style REST web service requests
 * because error handling is defined on a class basis, and we need
 * correct error handling for JSON requests.
 */
@Controller
public class JSONController extends BaseController {



    @ExceptionHandler(Exception.class)
    public void handleException(Exception ex, HttpServletRequest request, HttpServletResponse response) {

        //if a ServletExit has been thrown, then the browser has already been redirected,
        //so just return null and get out of here.
        if (ex instanceof ServletExit) {
            return;
        }
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        sendErrorResponse(ar, "Unable to handle that JSON request", ex);
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



    public static boolean doesProjectExist(AuthRequest ar, String projectName) throws Exception {
        List<NGPageIndex> foundPages = ar.getCogInstance().getPageIndexByName(projectName);
        if (foundPages.size() > 0) {
            return true;
        }
        return false;
    }



}


