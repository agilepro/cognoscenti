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

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.purplehillsbooks.weaver.AddressListEntry;
import com.purplehillsbooks.weaver.AuthRequest;
import com.purplehillsbooks.weaver.Cognoscenti;
import com.purplehillsbooks.weaver.ErrorLog;
import com.purplehillsbooks.weaver.ErrorLogDetails;
import com.purplehillsbooks.weaver.HistoricActions;
import com.purplehillsbooks.weaver.OptOutAddr;
import com.purplehillsbooks.weaver.SiteReqFile;
import com.purplehillsbooks.weaver.SiteRequest;
import com.purplehillsbooks.weaver.exception.NGException;
import com.purplehillsbooks.weaver.mail.EmailSender;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.ApplicationContext;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;

import com.purplehillsbooks.json.JSONException;
import com.purplehillsbooks.json.JSONObject;

@Controller
public class SuperAdminController extends BaseController {

     @Autowired
     public void setContext(ApplicationContext context) {
         //NGWebUtils.srvContext = context;
     }


     private static void streamAdminJSP(AuthRequest ar,
             String jspName) throws Exception {

        if(!ar.isLoggedIn()){
            streamJSPAnon(ar, "","","Admin.jsp");
            return;
        }
        if(!ar.isSuperAdmin()){
            throw new NGException("nugen.exceptionhandling.system.admin.rights",null);
        }
        ar.req.setAttribute("wrappedJSP", jspName);
        ar.invokeJSP("/spring/admin/Wrapper.jsp");
    }



     @RequestMapping(value = "/su/errorLog.htm", method = RequestMethod.GET)
     public void errorLogPage(HttpServletRequest request,
             HttpServletResponse response)
     throws Exception {
         AuthRequest ar = AuthRequest.getOrCreate(request, response);
         try{
             streamAdminJSP(ar, "errorLog");

         }catch(Exception ex){
             throw new NGException("nugen.operation.fail.administration.page", new Object[]{ar.getBestUserId()} , ex);
         }
     }

     @RequestMapping(value = "/su/testEmail.htm", method = RequestMethod.GET)
     public void testEmail(HttpServletRequest request,
             HttpServletResponse response)
     throws Exception {
         AuthRequest ar = AuthRequest.getOrCreate(request, response);
         try{
             streamAdminJSP(ar, "testEmail");

         }catch(Exception ex){
             throw new NGException("nugen.operation.fail.administration.page", new Object[]{ar.getBestUserId()} , ex);
         }
     }

     @RequestMapping(value = "/su/emailListnerSettings.htm", method = RequestMethod.GET)
     public void emailListnerSettings(HttpServletRequest request, HttpServletResponse response)
             throws Exception {


         AuthRequest ar = AuthRequest.getOrCreate(request, response);
         try{
             streamAdminJSP(ar, "emailListnerSettings");

         }catch(Exception ex){
             throw new NGException("nugen.operation.fail.administration.page", new Object[]{ar.getBestUserId()} , ex);
         }
     }

     @RequestMapping(value = "/su/lastNotificationSend.htm", method = RequestMethod.GET)
     public void lastNotificationSend(HttpServletRequest request, HttpServletResponse response)
             throws Exception {
         AuthRequest ar = AuthRequest.getOrCreate(request, response);
         try{
             streamAdminJSP(ar, "lastNotificationSend");

         }catch(Exception ex){
             throw new NGException("nugen.operation.fail.administration.page", new Object[]{ar.getBestUserId()} , ex);
         }
     }

     @RequestMapping(value = "/su/newUsers.htm", method = RequestMethod.GET)
     public void newUsers(HttpServletRequest request, HttpServletResponse response)
             throws Exception {
         AuthRequest ar = AuthRequest.getOrCreate(request, response);
         try{
             streamAdminJSP(ar, "newUsers");
         }catch(Exception ex){
             throw new NGException("nugen.operation.fail.administration.page", new Object[]{ar.getBestUserId()} , ex);
         }
     }

     @RequestMapping(value = "/su/requestedAccounts.htm", method = RequestMethod.GET)
     public void requestedAccounts(HttpServletRequest request, HttpServletResponse response)
             throws Exception {
         AuthRequest ar = AuthRequest.getOrCreate(request, response);
         try{
             streamAdminJSP(ar, "requestedAccounts");
         }catch(Exception ex){
             throw new NGException("nugen.operation.fail.administration.page", new Object[]{ar.getBestUserId()} , ex);
         }
     }

     @RequestMapping(value = "/su/allSites.htm", method = RequestMethod.GET)
     public void allSites(HttpServletRequest request, HttpServletResponse response)
             throws Exception {
         AuthRequest ar = AuthRequest.getOrCreate(request, response);
         try{
             streamAdminJSP(ar, "allSites");
         }catch(Exception ex){
             throw new NGException("nugen.operation.fail.administration.page", new Object[]{ar.getBestUserId()} , ex);
         }
     }

     @RequestMapping(value = "/su/oneSite.htm", method = RequestMethod.GET)
     public void oneSite(HttpServletRequest request, HttpServletResponse response)
             throws Exception {
         AuthRequest ar = AuthRequest.getOrCreate(request, response);
         try{
             streamAdminJSP(ar, "oneSite");
         }catch(Exception ex){
             throw new NGException("nugen.operation.fail.administration.page", new Object[]{ar.getBestUserId()} , ex);
         }
     }

     @RequestMapping(value = "/su/acceptOrDenySite.json", method = RequestMethod.POST)
     public void acceptOrDenySite(HttpServletRequest request, HttpServletResponse response) {
         AuthRequest ar = AuthRequest.getOrCreate(request, response);
         String requestId = "";
         try{
             ar.assertSuperAdmin("Must be a super admin to accept site requests.");
             JSONObject requestInfo = getPostedObject(ar);


             requestId = requestInfo.getString("requestId");
             SiteReqFile siteReqFile = new SiteReqFile(ar.getCogInstance());
             SiteRequest siteRequest = siteReqFile.getRequestByKey(requestId);
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
             siteReqFile.save();

             JSONObject repo = siteRequest.getJSON();
             sendJson(ar, repo);
         }
         catch(Exception ex){
             Exception ee = new Exception("Unable to update site request ("+requestId+")", ex);
             streamException(ee, ar);
         }
     }


     @RequestMapping(value = "/su/testEmailSend.json", method = RequestMethod.POST)
     public void testEmailSend(HttpServletRequest request, HttpServletResponse response) {
         AuthRequest ar = AuthRequest.getOrCreate(request, response);
         String requestId = "";
         try{
             ar.assertSuperAdmin("Must be a super admin to accept site requests.");
             JSONObject requestInfo = getPostedObject(ar);

             String toAddress = requestInfo.getString("to");
             String from = requestInfo.getString("from");
             AddressListEntry fromAddress = new AddressListEntry(from);
             String body = requestInfo.getString("body");
             String subject = requestInfo.getString("subject");
             OptOutAddr ooa = new OptOutAddr(new AddressListEntry(toAddress));
             EmailSender.generalMailToOne(ooa, fromAddress, subject, body, ar.getCogInstance());

             requestInfo.put("status", "success");
             sendJson(ar, requestInfo);
         }
         catch(Exception ex){
             Exception ee = new Exception("Unable to update site request ("+requestId+")", ex);
             streamException(ee, ar);
         }
     }


     @RequestMapping(value = "/su/submitComment", method = RequestMethod.POST)
     public void submitComment(HttpServletRequest request,
             HttpServletResponse response) throws Exception {
         AuthRequest ar = AuthRequest.getOrCreate(request, response);
         try{
             Cognoscenti cog = ar.getCogInstance();
             JSONObject requestInfo = getPostedObject(ar);
             JSONObject result = null;
             int errNo = requestInfo.getInt("errNo");
             if (errNo<0) {
                 ErrorLog eLog = ErrorLog.getLogForDate(ar.nowTime, cog);
                 ErrorLogDetails det = eLog.createNewError(cog);
                 det.updateFromJSON(requestInfo);
                 det.sendFeedbackEmail(ar);
                 result = det.getJSON();
                 eLog.save();
             }
             else {
                 long logDate = requestInfo.getLong("logDate");
                 ErrorLog eLog = ErrorLog.getLogForDate(logDate, cog);
                 ErrorLogDetails det = eLog.getDetails(errNo);
                 if (det==null) {
                     throw new Exception("Unable to find an error with number "+errNo);
                 }
                 if (errNo != det.getErrorNo()) {
                     throw new Exception("For some reason looked for error "+errNo+" but got error "+det.getErrorNo());
                 }
                 det.updateFromJSON(requestInfo);
                 det.sendFeedbackEmail(ar);
                 result = det.getJSON();
                 eLog.save();
             }
             sendJson(ar, result);
         }catch(Exception ex){
             Exception ee = new Exception("Unable to create or update comment", ex);
             streamException(ee, ar);
         }
     }



     @RequestMapping(value = "/su/errorDetails{errorId}.htm", method = RequestMethod.GET)
     public void errorDetailsPage(@PathVariable String errorId,
             @RequestParam String searchByDate,HttpServletRequest request,
             HttpServletResponse response) throws Exception {
         try{
             AuthRequest ar = AuthRequest.getOrCreate(request, response);
             ar.setParam("errorId", errorId);
             ar.setParam("errorDate", searchByDate);
             ar.setParam("goURL", ar.getCompleteURL());
             streamAdminJSP(ar, "detailsErrorLog");
         }catch(Exception ex){
             throw new NGException("nugen.operation.fail.error.detail.page", null , ex);
         }
     }

     @RequestMapping(value = "/su/logUserComents.form", method = RequestMethod.POST)
     public void logUserComents(@RequestParam int errorNo,HttpServletRequest request,
             HttpServletResponse response)
     throws Exception {

         try{
             AuthRequest ar = AuthRequest.getOrCreate(request, response);
             ar.assertLoggedIn("User must be logged in as a Super admin to see the error Log.");
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

     @RequestMapping(value = "/su/SiteMerge.htm", method = RequestMethod.GET)
     public void siteMerge(HttpServletRequest request, HttpServletResponse response)
             throws Exception {

         String siteId = "UNKNOWN";
         try{
             AuthRequest ar = AuthRequest.getOrCreate(request, response);
             siteId = ar.reqParam("site");
             prepareSiteView(ar, siteId);

             streamAdminJSP(ar, "SiteMerge");
         }catch(Exception ex){
             throw new JSONException("Unable to perform SiteMerge with site {0}", ex, siteId);
         }
     }


}
