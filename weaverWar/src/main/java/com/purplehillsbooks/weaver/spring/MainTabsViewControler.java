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

import java.util.ArrayList;
import java.util.List;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.purplehillsbooks.weaver.AddressListEntry;
import com.purplehillsbooks.weaver.AuthRequest;
import com.purplehillsbooks.weaver.GoalRecord;
import com.purplehillsbooks.weaver.HistoryRecord;
import com.purplehillsbooks.weaver.NGRole;
import com.purplehillsbooks.weaver.NGWorkspace;
import com.purplehillsbooks.weaver.SearchResultRecord;
import com.purplehillsbooks.weaver.TopicRecord;
import com.purplehillsbooks.weaver.UserProfile;
import com.purplehillsbooks.weaver.exception.NGException;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.servlet.ModelAndView;

import com.purplehillsbooks.json.JSONArray;
import com.purplehillsbooks.json.JSONObject;


@Controller
public class MainTabsViewControler extends BaseController {

    public static MeetingNotesCache meetingCache = new MeetingNotesCache();


    //////////////////////////////// REDIRECTS ///////////////////////////////////

    @RequestMapping(value = "/{siteId}/{pageId}/frontPage.htm", method = RequestMethod.GET)
    public void redFrontPage(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response)throws Exception {
        response.sendRedirect("FrontPage.htm");
    }
    @RequestMapping(value = "/{siteId}/{pageId}/", method = RequestMethod.GET)
    public void redIndex(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response)throws Exception {
        response.sendRedirect("FrontPage.htm");
    }




    /////////////////////////// MAIN VIEWS //////////////////////////////////////////

    @RequestMapping(value = "/{siteId}/{pageId}/FrontTop.htm", method = RequestMethod.GET)
    public void frontTop(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        showJSPLoggedIn(ar, siteId, pageId, "FrontTop");
    }

    @RequestMapping(value = "/{siteId}/{pageId}/FrontPage.htm", method = RequestMethod.GET)
    public void frontPage(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        if ("$".equals(pageId)) {
            //if this is a site instead of a workspace, display something else
            response.sendRedirect("SiteWorkspaces.htm");
        }
        showJSPLoggedIn(ar, siteId, pageId, "../jsp/FrontPage");
    }


    @RequestMapping(value = "/{siteId}/{pageId}/History.htm", method = RequestMethod.GET)
    public void showHistoryTab(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        showJSPMembers(ar, siteId, pageId, "History.jsp");
    }

    /**
     * This is a view that prompts the user to specify how they want the PDF to be produced.
     */
    @RequestMapping(value = "/{siteId}/{pageId}/exportPDF.htm", method = RequestMethod.GET)
    public void exportPDF(HttpServletRequest request, HttpServletResponse response,
            @PathVariable String pageId, @PathVariable String siteId) throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        showJSPMembers(ar, siteId, pageId, "exportPDF.jsp");
    }





    @RequestMapping(value = "/{siteId}/{pageId}/searchAllNotes.htm", method = RequestMethod.GET)
    public void searchAllNotes(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response)
           throws Exception {

        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            if (warnNotLoggedIn(ar)) {
                return;
            }
            registerSiteOrProject(ar, siteId, pageId);
            streamJSP(ar, "SearchAllNotes.jsp");

        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.project.draft.notes.page", new Object[]{pageId,siteId} , ex);
        }
    }







     @RequestMapping(value = "/index.htm", method = RequestMethod.GET)
     public ModelAndView showLandingPage(HttpServletRequest request, HttpServletResponse response)
                throws Exception {
         try{
             AuthRequest ar = AuthRequest.getOrCreate(request, response);
             ar.getCogInstance().assertInitialized();
             //if the user is logged in, redirect to their own home page instead
             if (ar.isLoggedIn())
             {
                 response.sendRedirect(ar.retPath+"v/"+ar.getUserProfile().getKey()+"/UserHome.htm");
                 return null;
             }

             streamJSPAnon(ar, "Index.jsp");
             return null;
         }catch(Exception ex){
             throw new NGException("nugen.operation.fail.project.welcome.page", null , ex);
         }
     }









     @RequestMapping(value = "/{siteId}/{pageId}/getNoteHistory.json", method = RequestMethod.GET)
     public void getGoalHistory(@PathVariable String siteId,@PathVariable String pageId,
             HttpServletRequest request, HttpServletResponse response) {
         AuthRequest ar = AuthRequest.getOrCreate(request, response);
         try{
             NGWorkspace ngp = ar.getCogInstance().getWSBySiteAndKeyOrFail( siteId, pageId ).getWorkspace();
             ar.setPageAccessLevels(ngp);
             ar.assertMember("Must be a member of workspace to get discussion topic history");
             String nid = ar.reqParam("nid");
             TopicRecord note = ngp.getNoteOrFail(nid);

             JSONArray noteArray = new JSONArray();
             for (HistoryRecord hist : note.getNoteHistory(ngp)) {
                 noteArray.put(hist.getJSON(ngp, ar));
             }
             releaseLock();
             sendJsonArray(ar, noteArray);
         }catch(Exception ex){
             Exception ee = new Exception("Unable to get history for note.", ex);
             streamException(ee, ar);
         }
     }

    //allow a user to change their email subscriptions, including opt out
    //even when not logged in.
    @RequestMapping(value = "/EmailAdjustment.htm", method = RequestMethod.GET)
    public void emailAdjustment(HttpServletRequest request, HttpServletResponse response)
        throws Exception {

        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            ar.preserveRealRequestURL();
            streamJSP(ar, "EmailAdjustment.jsp");
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.project.sent.note.by.email.page", null , ex);
        }
    }

    //allow a user to change their email subscriptions, including opt out
    //even when not logged in.
    @RequestMapping(value = "/EmailAdjustmentAction.form", method = RequestMethod.POST)
    public void emailAdjustmentActionForm(HttpServletRequest request, HttpServletResponse response)
        throws Exception {

        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            ar.preserveRealRequestURL();

            String p = ar.reqParam("p");
            String email = ar.reqParam("email");
            String mn = ar.reqParam("mn");
            String go = ar.defParam("go", ar.baseURL);

            NGWorkspace ngw = ar.getCogInstance().getWSByCombinedKeyOrFail(p).getWorkspace();
            String expectedMn = ngw.emailDependentMagicNumber(email);
            if (!expectedMn.equals(mn)) {
                throw new Exception("Something is wrong, improper request for email address "+email);
            }

            String cmd = ar.reqParam("cmd");
            if ("Remove Me".equals(cmd)) {
                String role = ar.reqParam("role");
                NGRole specRole = ngw.getRoleOrFail(role);
                specRole.removePlayer(new AddressListEntry(email));
                ngw.getSite().flushUserCache();
            }
            else {
                throw new Exception("emailAdjustmentActionForm does not understand the cmd "+cmd);
            }

            response.sendRedirect(go);
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.project.sent.note.by.email.page", null , ex);
        }
    }


    /**
     * This removes the logged in user from a specified role
     * p == workspace id
     * role == role name
     */
    @RequestMapping(value = "removeMe.json", method = RequestMethod.GET)
    public void removeMe(HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try{
            ar.assertLoggedIn("Must be logged in modify role settings");
            String p = ar.reqParam("p");
            NGWorkspace ngw = ar.getCogInstance().getWSByCombinedKeyOrFail(p).getWorkspace();
            String role = ar.reqParam("role");
            NGRole specRole = ngw.getRoleOrFail(role);
            specRole.removePlayer(ar.getUserProfile().getAddressListEntry());
            ngw.getSite().flushUserCache();
            saveAndReleaseLock(ngw, ar, "user removed themself from role "+role);

            JSONObject results = new JSONObject();
            results.put("result", "ok");
            sendJson(ar, results);
        }catch(Exception ex){
            Exception ee = new Exception("Unable to remove user from role.", ex);
            streamException(ee, ar);
        }
    }






    /**
     * This is LOGGED IN search page.
     */
    @RequestMapping(value = "/{siteId}/{pageId}/searchNotes.json", method = RequestMethod.POST)
    public void searchPublicNotesJSON(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try{
            ar.assertLoggedIn("Must be logged in to search the topics");

            JSONObject query = getPostedObject(ar);

            String searchText    = query.getString("searchFilter");
            String searchSite    = query.getString("searchSite");
            String searchProject = query.getString("searchProject");

            if ("all".equals(searchSite)) {
                siteId = null;
            }

            List<SearchResultRecord> searchResults = null;
            if (searchText.length()>0) {
                searchResults = ar.getCogInstance().performSearch(ar, searchText, searchProject, siteId, pageId);
            }
            else {
                searchResults = new ArrayList<SearchResultRecord>();
            }

            JSONArray resultList = new JSONArray();
            for (SearchResultRecord srr : searchResults) {
                resultList.put(srr.getJSON());
            }
            sendJsonArray(ar, resultList);
        }catch(Exception ex){
            Exception ee = new Exception("Unable to search for topics.", ex);
            streamException(ee, ar);
        }
    }



      @RequestMapping(value = "/isNoteDeleted.ajax", method = RequestMethod.POST)
      public void isNoteDeleted(HttpServletRequest request, HttpServletResponse response)
             throws Exception {
         AuthRequest ar = AuthRequest.getOrCreate(request, response);
         try {
             ar.assertLoggedIn("Must be logged in to create a topic.");
             String p = ar.reqParam("p");
             NGWorkspace ngp = ar.getCogInstance().getWSByCombinedKeyOrFail(p).getWorkspace();
             ar.setPageAccessLevels(ngp);

             String oid = ar.reqParam("oid");
             JSONObject paramMap = new JSONObject();
             TopicRecord note = ngp.getNoteOrFail(oid);
             if(note.isDeleted()){
                 paramMap.put("msgType", "yes");
             }else{
                 paramMap.put("msgType", "no");
             }

             sendJson(ar,paramMap);
         }
         catch (Exception ex) {
             streamException(ex,ar);
         }
     }



      /*
       * Creates an action item that is associated with a meeting
       */
      @RequestMapping(value = "/{siteId}/{pageId}/createActionItem.json", method = RequestMethod.POST)
      public void createActionItem(@PathVariable String siteId,@PathVariable String pageId,
              HttpServletRequest request, HttpServletResponse response) {
          AuthRequest ar = AuthRequest.getOrCreate(request, response);
          try{
              NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail( siteId, pageId ).getWorkspace();
              ar.setPageAccessLevels(ngw);
              ar.assertMember("Must be a member to create a action item.");
              ar.assertNotFrozen(ngw);
              ar.assertNotReadOnly("Cannot create a action item");

              JSONObject goalInfo = getPostedObject(ar);
              GoalRecord gr = ngw.createGoal(ar.getBestUserId());

              //create the history record here.
              HistoryRecord.createHistoryRecord(ngw, gr.getId(),
                      HistoryRecord.CONTEXT_TYPE_TASK, HistoryRecord.EVENT_TYPE_CREATED, ar,
                      "action item synopsis: "+gr.getSynopsis());

              //There is a check that requires this to do the update.
              goalInfo.put("universalid", gr.getUniversalId());
              gr.updateGoalFromJSON(goalInfo, ngw, ar);
              gr.setCreator(ar.getBestUserId());
              if (gr.getCreator()==null || gr.getCreator().length()==0) {
                  throw new Exception("can not set the creator");
              }
              JSONObject repo = gr.getJSON4Goal(ngw);
              saveAndReleaseLock(ngw, ar, "Created action item for minutes of meeting.");
              sendJson(ar, repo);
          }catch(Exception ex){
              Exception ee = new Exception("Unable to create Action Item .", ex);
              streamException(ee, ar);
          }
      }






      //A very simple form with a prompt for a user's display name  (dName)
      //and the user name is set with whatever is posted in.
      //Can only set the current logged in user name.
      //User session must be logged in (so you have a profile to set)
      //If not logged in, because maybe timeout, or server restart, then
      //just silently ignore this and try again once logged in.
      @RequestMapping(value = "/RequiredName.form", method = RequestMethod.POST)
      public void requireName_form(HttpServletRequest request, HttpServletResponse response)
          throws Exception {

          try{
              AuthRequest ar = AuthRequest.getOrCreate(request, response);
              String go = ar.defParam("go", ar.baseURL);
              if (ar.isLoggedIn()) {
                  UserProfile up = ar.getUserProfile();
                  String dName = ar.reqParam("dName");
                  up.setName(dName);
                  up.setLastUpdated(ar.nowTime);
                  ar.getCogInstance().getUserManager().saveUserProfiles();
              }
              response.sendRedirect(go);
          }catch(Exception ex){
              throw new Exception("Unable to set your required user full name", ex);
          }
      }



}
