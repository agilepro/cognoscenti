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
import java.text.SimpleDateFormat;
import java.util.Date;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.socialbiz.cog.AuthRequest;
import org.socialbiz.cog.DOMUtils;
import org.socialbiz.cog.ErrorLog;
import org.socialbiz.cog.HistoricActions;
import org.socialbiz.cog.SiteReqFile;
import org.socialbiz.cog.SiteRequest;
import org.socialbiz.cog.exception.NGException;
import org.socialbiz.cog.exception.ProgramLogicError;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.ApplicationContext;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.ModelAndView;
import org.w3c.dom.Document;
import org.workcast.json.JSONObject;

@Controller
public class SuperAdminController extends BaseController {

     @Autowired
     public void setContext(ApplicationContext context) {
         //NGWebUtils.srvContext = context;
     }

     @RequestMapping(value = "/{userKey}/errorLog.htm", method = RequestMethod.GET)
     public void errorLogPage(@PathVariable String userKey,HttpServletRequest request,
             HttpServletResponse response)
     throws Exception {
         try{
             AuthRequest ar = AuthRequest.getOrCreate(request, response);
             adminModelSetUp(ar, userKey, "errorLog");

         }catch(Exception ex){
             throw new NGException("nugen.operation.fail.administration.page", new Object[]{userKey} , ex);
         }
     }

     @RequestMapping(value = "/{userKey}/emailListnerSettings.htm", method = RequestMethod.GET)
     public void emailListnerSettings(@PathVariable String userKey,
             HttpServletRequest request, HttpServletResponse response)
             throws Exception {


         try{
             AuthRequest ar = AuthRequest.getOrCreate(request, response);
             adminModelSetUp(ar, userKey, "emailListnerSettings");

         }catch(Exception ex){
             throw new NGException("nugen.operation.fail.administration.page", new Object[]{userKey} , ex);
         }
     }

     @RequestMapping(value = "/{userKey}/lastNotificationSend.htm", method = RequestMethod.GET)
     public void lastNotificationSend(@PathVariable String userKey,
             HttpServletRequest request, HttpServletResponse response)
             throws Exception {
         try{
             AuthRequest ar = AuthRequest.getOrCreate(request, response);
             adminModelSetUp(ar, userKey, "lastNotificationSend");

         }catch(Exception ex){
             throw new NGException("nugen.operation.fail.administration.page", new Object[]{userKey} , ex);
         }
     }

     @RequestMapping(value = "/{userKey}/newUsers.htm", method = RequestMethod.GET)
     public void newUsers(@PathVariable String userKey,
             HttpServletRequest request, HttpServletResponse response)
             throws Exception {
         try{
             AuthRequest ar = AuthRequest.getOrCreate(request, response);
             adminModelSetUp(ar, userKey, "newUsers");
         }catch(Exception ex){
             throw new NGException("nugen.operation.fail.administration.page", new Object[]{userKey} , ex);
         }
     }

     @RequestMapping(value = "/{userKey}/requestedAccounts.htm", method = RequestMethod.GET)
     public void requestedAccounts(@PathVariable String userKey,
             HttpServletRequest request, HttpServletResponse response)
             throws Exception {
         try{
             AuthRequest ar = AuthRequest.getOrCreate(request, response);
             adminModelSetUp(ar, userKey, "requestedAccounts");
         }catch(Exception ex){
             throw new NGException("nugen.operation.fail.administration.page", new Object[]{userKey} , ex);
         }
     }

     @RequestMapping(value = "/{userKey}/allSites.htm", method = RequestMethod.GET)
     public void allSites(@PathVariable String userKey,
             HttpServletRequest request, HttpServletResponse response)
             throws Exception {
         try{
             AuthRequest ar = AuthRequest.getOrCreate(request, response);
             adminModelSetUp(ar, userKey, "allSites");
         }catch(Exception ex){
             throw new NGException("nugen.operation.fail.administration.page", new Object[]{userKey} , ex);
         }
     }

     @RequestMapping(value = "/{userKey}/acceptOrDenySite.json", method = RequestMethod.POST)
     public void acceptOrDenySite(HttpServletRequest request, HttpServletResponse response) {
         AuthRequest ar = AuthRequest.getOrCreate(request, response);
         String requestId = "";
         try{
             ar.assertSuperAdmin("Must be a super admin to accept site requests.");
             JSONObject requestInfo = getPostedObject(ar);


             requestId = requestInfo.getString("requestId");
             SiteRequest siteRequest = SiteReqFile.getRequestByKey(requestId);
             if (siteRequest==null) {
                 throw new NGException("nugen.exceptionhandling.not.find.account.request",new Object[]{requestId});
             }

             String newStatus = requestInfo.getString("newStatus");
             String description = requestInfo.getString("description");

             HistoricActions ha = new HistoricActions(ar);
             if ("Granted".equals(newStatus)) {
                 ha.completeSiteRequest(siteRequest, true, description);
             }
             else if("Denied".equals(newStatus)) {
                 ha.completeSiteRequest(siteRequest, false, description);
             }
             else{
                 throw new Exception("Unrecognized new status ("+newStatus+") in acceptOrDenySite.json");
             }

             JSONObject repo = siteRequest.getJSON();
             repo.write(ar.w, 2, 2);
             ar.flush();
         }
         catch(Exception ex){
             Exception ee = new Exception("Unable to update site request ("+requestId+")", ex);
             streamException(ee, ar);
         }
     }


     @RequestMapping(value = "/{userKey}/getErrorLogXML.ajax", method = RequestMethod.GET)
     public void errorLogXMLData(@PathVariable String userKey,@RequestParam String searchByDate,HttpServletRequest request,
             HttpServletResponse response)
     throws Exception {
         try {
             AuthRequest ar = NGWebUtils.getAuthRequest(request, response,
                     "User must be logged in as a Super admin to see the error Log.");
             Date date = new SimpleDateFormat("MM/dd/yyyy").parse(searchByDate);
             File xmlFile=ErrorLog.getErrorFileFullPath(date, ar.getCogInstance());

             if (!xmlFile.exists()) {
                 Document doc = DOMUtils.createDocument("errorlog");
                 doc.getDocumentElement().setAttribute("missingFile", xmlFile.toString());
                 writeXMLToResponse(ar,doc);
             }
             else {
                 Document doc = ErrorLog.readOrCreateFile(xmlFile, "errorlog");
                 doc.getDocumentElement().setAttribute("fileName", xmlFile.toString());
                 writeXMLToResponse(ar,doc);
             }
         }
         catch (Exception e) {
             //need something better here to return the error as XML
             throw e;
         }
     }

     /**
      * TODO: this is ridiculous having the user ID in the path... not needed, not used
      */
     @RequestMapping(value = "/{userKey}/errorDetails{errorId}.htm", method = RequestMethod.GET)
     public ModelAndView errorDetailsPage(@PathVariable String errorId,
             @RequestParam String searchByDate,HttpServletRequest request,
             HttpServletResponse response)
     throws Exception {

         ModelAndView modelAndView = null;
         try{
             AuthRequest ar=NGWebUtils.getAuthRequest(request, response,
                     "User must be logged in as a Super admin to see the error Log.");
             modelAndView = new ModelAndView("detailsErrorLog");
             modelAndView.addObject("errorId", errorId);
             modelAndView.addObject("errorDate", searchByDate);
             modelAndView.addObject("goURL", ar.getCompleteURL());
         }catch(Exception ex){
             throw new NGException("nugen.operation.fail.error.detail.page", null , ex);
         }
         return modelAndView;
     }

     @RequestMapping(value = "/{userKey}/logUserComents.form", method = RequestMethod.POST)
     public void logUserComents(@RequestParam String errorNo,HttpServletRequest request,
             HttpServletResponse response)
     throws Exception {

         try{
             AuthRequest ar =NGWebUtils.getAuthRequest(request, response,
                     "User must be logged in as a Super admin to see the error Log.");
             String userComments=ar.defParam("comments", "");

             String searchByDate=ar.reqParam("searchByDate");
             long logFileDate = Long.parseLong(searchByDate);

             String goURL=ar.reqParam("goURL");

             ErrorLog eLog = ErrorLog.getLogForDate(logFileDate, ar.getCogInstance());
             eLog.logUserComments(errorNo, logFileDate, userComments);
             redirectBrowser(ar,goURL);
         }catch(Exception ex){
             throw new NGException("nugen.operation.fail.error.log.user.comment", null , ex);
         }
     }
     private void writeXMLToResponse(AuthRequest ar, Document doc) throws Exception {

         if (ar == null){
             throw new ProgramLogicError("writeXMLToResponse requires a non-null AuthRequest parameter");
         }
         ar.resp.setContentType("text/xml;charset=UTF-8");
         DOMUtils.writeDom(doc, ar.w);
         ar.flush();
     }

     private static void adminModelSetUp(AuthRequest ar,
              String userKey, String jspName) throws Exception {

         if(!ar.isLoggedIn()){
             throw new NGException("nugen.project.login.msg",null);
         }
         if(!ar.isSuperAdmin()){
             throw new NGException("nugen.exceptionhandling.system.admin.rights",null);
         }
         ar.req.setAttribute("wrappedJSP", jspName);
         ar.invokeJSP("/spring/admin/Wrapper.jsp");
     }

}
