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

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import com.purplehillsbooks.weaver.AddressListEntry;
import com.purplehillsbooks.weaver.AuthRequest;
import com.purplehillsbooks.weaver.Cognoscenti;
import com.purplehillsbooks.weaver.ErrorLog;
import com.purplehillsbooks.weaver.ErrorLogDetails;
import com.purplehillsbooks.weaver.HistoricActions;
import com.purplehillsbooks.weaver.SiteReqFile;
import com.purplehillsbooks.weaver.SiteRequest;
import com.purplehillsbooks.weaver.exception.WeaverException;
import com.purplehillsbooks.weaver.mail.EmailSender;
import com.purplehillsbooks.weaver.mail.MailInst;
import com.purplehillsbooks.weaver.mail.OptOutAddr;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import com.purplehillsbooks.json.JSONObject;

@Controller
public class SuperAdminController extends BaseController {


    private static void streamAdminJSP(AuthRequest ar, String jspName) {
        try {
            if (!ar.isLoggedIn()) {
                showDisplayWarning(ar, "In order to see this section, you need to be logged in.");
                return;
            }
            if (!ar.isSuperAdmin()) {
                showDisplayWarning(ar, "In order to see this section, you need to be a system administrator.");
                return;
            }
            ar.req.setAttribute("wrappedJSP", jspName);
            ar.invokeJSP("/spring/admin/Wrapper.jsp");
        }
        catch (Exception e) {
            showDisplayException(ar, WeaverException.newWrap(
                "Failed to open administration page (%s) for user (%s).",
                e, jspName, ar.getBestUserId()));            
        }
    }


    @RequestMapping(value = "/su/ErrorList.htm", method = RequestMethod.GET)
    public void errorList(HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        streamAdminJSP(ar, "ErrorList.jsp");
    }

     @RequestMapping(value = "/su/EmailTest.htm", method = RequestMethod.GET)
     public void emailTest(HttpServletRequest request,
             HttpServletResponse response) {
         AuthRequest ar = AuthRequest.getOrCreate(request, response);
         streamAdminJSP(ar, "EmailTest.jsp");
     }

     @RequestMapping(value = "/su/EmailListnerSettings.htm", method = RequestMethod.GET)
     public void emailListnerSettings(HttpServletRequest request, HttpServletResponse response) {
         AuthRequest ar = AuthRequest.getOrCreate(request, response);
         streamAdminJSP(ar, "EmailListnerSettings.jsp");
     }

     @RequestMapping(value = "/su/NotificationStatus.htm", method = RequestMethod.GET)
     public void notificationStatus(HttpServletRequest request, HttpServletResponse response) {
         AuthRequest ar = AuthRequest.getOrCreate(request, response);
         streamAdminJSP(ar, "NotificationStatus.jsp");
     }

     @RequestMapping(value = "/su/BlockedEmail.htm", method = RequestMethod.GET)
     public void blockedEmail(HttpServletRequest request, HttpServletResponse response) {
         AuthRequest ar = AuthRequest.getOrCreate(request, response);
         streamAdminJSP(ar, "BlockedEmail.jsp");
     }

     @RequestMapping(value = "/su/UserList.htm", method = RequestMethod.GET)
     public void userList(HttpServletRequest request, HttpServletResponse response) {
         AuthRequest ar = AuthRequest.getOrCreate(request, response);
         streamAdminJSP(ar, "UserList.jsp");
     }

     @RequestMapping(value = "/su/SiteRequests.htm", method = RequestMethod.GET)
     public void siteRequests(HttpServletRequest request, HttpServletResponse response) {
         AuthRequest ar = AuthRequest.getOrCreate(request, response);
         streamAdminJSP(ar, "SiteRequests.jsp");
     }

     @RequestMapping(value = "/su/ListSites.htm", method = RequestMethod.GET)
     public void listSites(HttpServletRequest request, HttpServletResponse response) {
         AuthRequest ar = AuthRequest.getOrCreate(request, response);
         streamAdminJSP(ar, "ListSites.jsp");
     }

     @RequestMapping(value = "/su/EstimateCosts.htm", method = RequestMethod.GET)
     public void estimateCosts(HttpServletRequest request, HttpServletResponse response) {
         AuthRequest ar = AuthRequest.getOrCreate(request, response);
         streamAdminJSP(ar, "EstimateCosts.jsp");
     }

     @RequestMapping(value = "/su/SiteDetails.htm", method = RequestMethod.GET)
     public void siteDetails(HttpServletRequest request, HttpServletResponse response) {
         AuthRequest ar = AuthRequest.getOrCreate(request, response);
         streamAdminJSP(ar, "SiteDetails.jsp");
     }
     
     @RequestMapping(value = "/su/EmailScanner.htm", method = RequestMethod.GET)
     public void emailScanner(HttpServletRequest request, HttpServletResponse response) {
         AuthRequest ar = AuthRequest.getOrCreate(request, response);
         streamAdminJSP(ar, "EmailScanner.jsp");
     }


     @RequestMapping(value = "/su/EmailMsgA.htm", method = RequestMethod.GET)
     public void emailMsgA(HttpServletRequest request, HttpServletResponse response) {
         AuthRequest ar = AuthRequest.getOrCreate(request, response);
         streamAdminJSP(ar, "EmailMsgA.jsp");
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
                 throw WeaverException.newBasic("Could not find any site request with id=%s", requestId);
             }
             
             String possiblyChangedSiteId = requestInfo.optString("siteId");
             if (possiblyChangedSiteId!=null) {
                 possiblyChangedSiteId = SiteRequest.cleanUpSiteId(possiblyChangedSiteId);                 
                 siteRequest.setSiteId(possiblyChangedSiteId);
                 siteRequest.validateValues();
             }
             String newStatus = requestInfo.getString("newStatus");

             HistoricActions ha = new HistoricActions(ar);
             if ("Granted".equals(newStatus)) {
                 ha.completeSiteRequest(siteRequest, true);
             }
             else if("Denied".equals(newStatus)) {
                 ha.completeSiteRequest(siteRequest, false);
             }
             else{
                 throw WeaverException.newBasic("Unrecognized new status ("+newStatus+") in acceptOrDenySite.json");
             }
             siteReqFile.save();

             JSONObject repo = siteRequest.getJSON();
             sendJson(ar, repo);
         }
         catch(Exception e){
             Exception ee = WeaverException.newWrap("Unable to update site request (%s)", e, requestId);
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
             AddressListEntry fromAddress = AddressListEntry.findOrCreate(from);
             String body = requestInfo.getString("body");
             String subject = requestInfo.getString("subject");
             OptOutAddr ooa = new OptOutAddr(AddressListEntry.findOrCreate(toAddress));
             
             MailInst msg = MailInst.genericEmail("$", "$", subject, body);
             EmailSender.generalMailToOne(msg, fromAddress, ooa);

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
                     throw WeaverException.newBasic("Unable to find an error with number %s", errNo);
                 }
                 if (errNo != det.getErrorNo()) {
                     throw WeaverException.newBasic("For some reason looked for error "+errNo+" but got error "+det.getErrorNo());
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



     @RequestMapping(value = "/su/ErrorDetail{errorId}.htm", method = RequestMethod.GET)
     public void errorDetailsPage(@PathVariable String errorId,
             @RequestParam String searchByDate,HttpServletRequest request,
             HttpServletResponse response) throws Exception {
         AuthRequest ar = AuthRequest.getOrCreate(request, response);
         try {
             ar.setParam("errorId", errorId);
             ar.setParam("errorDate", searchByDate);
             ar.setParam("goURL", ar.getCompleteURL());
             streamAdminJSP(ar, "ErrorDetail.jsp");
         }catch(Exception e){
             showDisplayException(ar, e);
         }
     }

    @RequestMapping(value = "/su/SiteMerge.htm", method = RequestMethod.GET)
    public void siteMerge(HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        String siteId = "UNKNOWN";
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try {
            siteId = ar.reqParam("site");
            prepareSiteView(ar, siteId);
            streamAdminJSP(ar, "SiteMerge.jsp");
        } catch (Exception e) {
            showDisplayException(ar, WeaverException.newWrap(
                    "Unable to perform SiteMerge with site %s",
                    e, siteId));
        }
    }

     ///////////////////////// Eamil ///////////////////////

     @RequestMapping(value = "/su/QuerySuperAdminEmail.json", method = RequestMethod.POST)
     public void queryEmail(
             HttpServletRequest request, HttpServletResponse response) {
         AuthRequest ar = AuthRequest.getOrCreate(request, response);
         try{
             if (!ar.isSuperAdmin()) {
                 throw WeaverException.newBasic("Super admin email list is accessible only by administrator.");
             }
             JSONObject posted = this.getPostedObject(ar);
             JSONObject repo = EmailSender.querySuperAdminEmail(posted);
             sendJson(ar, repo);
         }catch(Exception ex){
             Exception ee = new Exception("Unable to get email", ex);
             streamException(ee, ar);
         }
     }


}
