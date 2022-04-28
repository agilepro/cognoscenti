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

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.purplehillsbooks.weaver.AuthRequest;
import com.purplehillsbooks.weaver.NGPageIndex;

/**
 * This servlet serves up pages using the following URL format:
 *
 * http://machine:port/{application}/p/{pageid}/leaf.htm
 *
 * {application} is whatever you install the application to on Tomcat could be
 * multiple levels deep.
 *
 * "p" is fixed. This is the indicator within the nugen application that says
 * this servlet will be invoked.
 *
 * {pageid} unique identifier for the page. Obviously depends on the page
 *
 * leaf.htm is the resource-id of the main page presented as HTML page. This is
 * a fixed resource id for the page. There are other resources as well.
 *
 * http://machine:port/{application}/p/{pageid}/leaf.xml
 *
 * There is a subspace for attachments using the name "a" Thus an attachment
 * "MyReport.doc" would be found at:
 *
 * http://machine:port/{application}/p/{pageid}/a/MyReport.doc
 *
 */
@SuppressWarnings("serial")
public class RestServlet extends javax.servlet.http.HttpServlet {

    /**
     * This servlet handles REST style requests for XML content
     */
    public void doGet(HttpServletRequest req, HttpServletResponse resp) {
        AuthRequest ar = AuthRequest.getOrCreate(req, resp);
        try {
            NGPageIndex.assertNoLocksOnThread();
            if (!ar.getCogInstance().isInitialized()) {
                throw new Exception("not initialized", ar.getCogInstance().lastFailureMsg);
            }

            RestHandler rh = new RestHandler(ar);
            rh.doAuthenticatedGet();
        }
        catch (Exception e) {
            //do something better
        }
        finally {
            NGPageIndex.clearLocksHeldByThisThread();
        }
        ar.logCompletedRequest();
    }
}
