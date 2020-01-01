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

import java.util.ArrayList;
import java.util.List;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.socialbiz.cog.AccessControl;
import org.socialbiz.cog.AddressListEntry;
import org.socialbiz.cog.AuthRequest;
import org.socialbiz.cog.GoalRecord;
import org.socialbiz.cog.HistoryRecord;
import org.socialbiz.cog.NGRole;
import org.socialbiz.cog.NGWorkspace;
import org.socialbiz.cog.SearchResultRecord;
import org.socialbiz.cog.TopicRecord;
import org.socialbiz.cog.UserProfile;
import org.socialbiz.cog.exception.NGException;
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

    @RequestMapping(value = "/{siteId}/{pageId}/projectHome.htm", method = RequestMethod.GET)
    public void projectHome(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response)throws Exception {
        response.sendRedirect("frontPage.htm");
    }

    @RequestMapping(value = "/{siteId}/{pageId}/public.htm", method = RequestMethod.GET)
    public void publicssssss(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        response.sendRedirect("frontPage.htm");
    }
    @RequestMapping(value = "/{siteId}/{pageId}/member.htm", method = RequestMethod.GET)
    public void member(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        response.sendRedirect("frontPage.htm");
    }
    @RequestMapping(value = "/{siteId}/{pageId}/deletedNotes.htm", method = RequestMethod.GET)
    public void deletedNotes(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        response.sendRedirect("frontPage.htm");
    }
    @RequestMapping(value = "/{siteId}/{pageId}/draftNotes.htm", method = RequestMethod.GET)
    public void draftNotes(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        response.sendRedirect("frontPage.htm");
    }

    @RequestMapping(value = "/{siteId}/{pageId}/process.htm", method = RequestMethod.GET)
    public void showProcessTab(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        response.sendRedirect("frontPage.htm");
    }

    @RequestMapping(value = "/{siteId}/{pageId}/projectActiveTasks.htm", method = RequestMethod.GET)
    public void projectActiveTasks(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        response.sendRedirect("frontPage.htm");
    }



    /////////////////////////// MAIN VIEWS //////////////////////////////////////////

    @RequestMapping(value = "/{siteId}/{pageId}/notesList.htm", method = RequestMethod.GET)
    public void notesList(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        showJSPMembers(ar, siteId, pageId, "NotesList");
    }


    @RequestMapping(value = "/{siteId}/{pageId}/automaticLinks.htm", method = RequestMethod.GET)
    public void automaticLinks(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response)
           throws Exception {

        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        showJSPMembers(ar, siteId, pageId, "AutomaticLinks");
    }

    @RequestMapping(value = "/{siteId}/{pageId}/frontTop.htm", method = RequestMethod.GET)
    public void frontTop(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        showJSPLoggedIn(ar, siteId, pageId, "FrontTop");
    }

    @RequestMapping(value = "/{siteId}/{pageId}/frontPage.htm", method = RequestMethod.GET)
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


    @RequestMapping(value = "/{siteId}/{pageId}/history.htm", method = RequestMethod.GET)
    public void showHistoryTab(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        showJSPMembers(ar, siteId, pageId, "leaf_history");
    }

    @RequestMapping(value = "/{siteId}/{pageId}/noteZoom{lid}.htm", method = RequestMethod.GET)
    public void displayOneLeaflet(@PathVariable String lid, @PathVariable String pageId,
           @PathVariable String siteId, HttpServletRequest request, HttpServletResponse response)
           throws Exception {
       try{
           AuthRequest ar = AuthRequest.getOrCreate(request, response);
           boolean reallyLoggedIn = ar.isLoggedIn();
           request.setAttribute("topicId", lid);
           NGWorkspace ngp = registerRequiredProject(ar, siteId, pageId);
           TopicRecord note = ngp.getNoteOrFail(lid);
           boolean canAccessNote  = AccessControl.canAccessTopic(ar, ngp, note);
           if (reallyLoggedIn && canAccessNote) {
               showJSPMembers(ar, siteId, pageId, "NoteZoom");
           }
           else if (canAccessNote) {
               //show to people not logged in, but with special key to access it
               specialAnonJSP(ar, siteId, pageId, "Topic.jsp");
           }
           else {
               showJSPMembers(ar, siteId, pageId, "NoteZoom");
           }
       }catch(Exception ex){
           throw new NGException("nugen.operation.fail.project.zoom.note.page", new Object[]{lid,pageId,siteId} , ex);
       }
   }

    /**
     * This is a view that prompts the user to specify how they want the PDF to be produced.
     */
    @RequestMapping(value = "/{siteId}/{pageId}/exportPDF.htm", method = RequestMethod.GET)
    public void exportPDF(HttpServletRequest request, HttpServletResponse response,
            @PathVariable String pageId, @PathVariable String siteId) throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        showJSPMembers(ar, siteId, pageId, "exportPDF");
    }





    @RequestMapping(value = "/{siteId}/{pageId}/searchAllNotes.htm", method = RequestMethod.GET)
    public void searchAllNotes(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response)
           throws Exception {

        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            if (checkLogin(ar)) {
                return;
            }
            registerSiteOrProject(ar, siteId, pageId);
            streamJSP(ar, "SearchAllNotes");

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

             specialAnonJSP(ar, "N/A", "N/A", "Index.jsp");
             return null;
         }catch(Exception ex){
             throw new NGException("nugen.operation.fail.project.welcome.page", null , ex);
         }
     }




     @RequestMapping(value = "/{siteId}/{pageId}/getTopics.json", method = RequestMethod.GET)
     public void getTopics(@PathVariable String siteId,@PathVariable String pageId,
             HttpServletRequest request, HttpServletResponse response) {
         AuthRequest ar = AuthRequest.getOrCreate(request, response);
         try{
             NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail( siteId, pageId ).getWorkspace();
             ar.setPageAccessLevels(ngw);
             boolean isMember = ar.isMember();

             List<TopicRecord> aList = ngw.getAllDiscussionTopics();

             JSONArray notes = new JSONArray();
             for (TopicRecord aNote : aList) {

                 String discussionPhase = aNote.getDiscussionPhase();

                 if (aNote.isPublic()) {
                     notes.put( aNote.getJSON(ngw) );
                 }
                 else if (!ar.isLoggedIn()) {
                     continue;
                 }
                 else if ("Draft".equals(discussionPhase)) {
                     if (ar.getUserProfile().hasAnyId(aNote.getModUser().getUniversalId())) {
                         notes.put( aNote.getJSON(ngw) );
                     }
                 }
                 else if (isMember) {
                     notes.put( aNote.getJSON(ngw) );
                 }
                 else {
                     //run through all the roles here and see if any role
                     //has access to the note
                 }
             }

             sendJsonArray(ar, notes);
         }catch(Exception ex){
             Exception ee = new Exception("Unable to fetch the list of topics", ex);
             streamException(ee, ar);
         }
     }


     @RequestMapping(value = "/{siteId}/{pageId}/noteHtmlUpdate.json", method = RequestMethod.POST)
     public void noteHtmlUpdate(@PathVariable String siteId,@PathVariable String pageId,
             HttpServletRequest request, HttpServletResponse response) {
         AuthRequest ar = AuthRequest.getOrCreate(request, response);
         String nid = "";
         try{
             NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail( siteId, pageId ).getWorkspace();
             ar.setPageAccessLevels(ngw);
             ar.assertMember("Must be a member to update a topic contents.");
             ar.assertNotFrozen(ngw);
             nid = ar.reqParam("nid");
             JSONObject noteInfo = getPostedObject(ar);

             boolean isAutoSave = noteInfo.has("saveMode") && "autosave".equals(noteInfo.getString("saveMode"));

             TopicRecord note = null;
             int eventType = HistoryRecord.EVENT_TYPE_MODIFIED;
             if ("~new~".equals(nid)) {
                 note = ngw.createNote();
                 noteInfo.put("universalid", note.getUniversalId());
                 eventType = HistoryRecord.EVENT_TYPE_CREATED;
             }
             else {
                 note = ngw.getDiscussionTopic(nid);
             }

             note.updateNoteFromJSON(noteInfo, ar);
             note.updateHtmlFromJSON(ar, noteInfo);
             note.setLastEdited(ar.nowTime);
             note.setModUser(new AddressListEntry(ar.getBestUserId()));
             if (!isAutoSave) {
                 HistoryRecord.createHistoryRecord(ngw, note.getId(), HistoryRecord.CONTEXT_TYPE_LEAFLET,
                     0, eventType, ar, "");
             }

             JSONObject repo = note.getJSONWithComments(ar, ngw);
             saveAndReleaseLock(ngw, ar, "Updated Topic Contents");

             repo.write(ar.w, 2, 2);
             ar.flush();
         }catch(Exception ex){
             Exception ee = new Exception("Unable to updated topic "+nid+" contents", ex);
             streamException(ee, ar);
         }
     }



     @RequestMapping(value = "/{siteId}/{pageId}/topicList.json", method = RequestMethod.GET)
     public void topicList(@PathVariable String siteId,@PathVariable String pageId,
             HttpServletRequest request, HttpServletResponse response) {
         AuthRequest ar = AuthRequest.getOrCreate(request, response);
         String nid = "";
         try{
             NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail( siteId, pageId ).getWorkspace();
             ar.setPageAccessLevels(ngw);
             boolean isMember = ar.isMember();

             JSONArray allTopics = new JSONArray();
             for (TopicRecord aNote : ngw.getAllDiscussionTopics()) {
                 if (!isMember && !aNote.isPublic()) {
                     //skip non public if not member
                     continue;
                 }
                 allTopics.put(aNote.getJSON(ngw));
             }

             JSONObject repo = new JSONObject();
             repo.put("topics", allTopics);
             sendJson(ar, repo);
         }catch(Exception ex){
             Exception ee = new Exception("Unable to updated topic "+nid+" contents", ex);
             streamException(ee, ar);
         }
     }



     @RequestMapping(value = "/{siteId}/{pageId}/updateNote.json", method = RequestMethod.POST)
     public void updateNote(@PathVariable String siteId,@PathVariable String pageId,
             HttpServletRequest request, HttpServletResponse response) {
         AuthRequest ar = AuthRequest.getOrCreate(request, response);
         String nid = "";
         try{
             NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail( siteId, pageId ).getWorkspace();
             ar.setPageAccessLevels(ngw);
             ar.assertMember("Must be a member to update a topic contents.");
             ar.assertNotFrozen(ngw);
             nid = ar.reqParam("nid");
             JSONObject noteInfo = getPostedObject(ar);
             TopicRecord note = ngw.getDiscussionTopic(nid);

             if (noteInfo.has("comments")) {
                 JSONArray commentsToUpdate = noteInfo.getJSONArray("comments");
                 int numCmts = commentsToUpdate.length();
                 for (int i=0; i<numCmts; i++) {
                     JSONObject aCmt = commentsToUpdate.getJSONObject(i);
                     if (aCmt.getLong("time")<=0) {
                         String comment = GetFirstHundredNoHtml(aCmt.getString("html"));
                         HistoryRecord.createHistoryRecord(ngw, note.getId(),
                                 HistoryRecord.CONTEXT_TYPE_LEAFLET,
                                 HistoryRecord.EVENT_COMMENT_ADDED, ar, comment);
                     }
                 }
             };

             note.updateNoteFromJSON(noteInfo, ar);

             JSONObject repo = note.getJSONWithComments(ar, ngw);
             saveAndReleaseLock(ngw, ar, "Updated Topic Contents");
             sendJson(ar, repo);
         }catch(Exception ex){
             Exception ee = new Exception("Unable to updated topic "+nid+" contents", ex);
             streamException(ee, ar);
         }
     }

     @RequestMapping(value = "/{siteId}/{pageId}/topicSubscribe.json", method = RequestMethod.GET)
     public void topicSubscribe(@PathVariable String siteId,@PathVariable String pageId,
             HttpServletRequest request, HttpServletResponse response) {
         AuthRequest ar = AuthRequest.getOrCreate(request, response);
         String nid = "";
         try{
             NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail( siteId, pageId ).getWorkspace();
             ar.setPageAccessLevels(ngw);
             ar.assertNotFrozen(ngw);
             nid = ar.reqParam("nid");
             TopicRecord topic = ngw.getDiscussionTopic(nid);
             boolean canAccessTopic  = AccessControl.canAccessTopic(ar, ngw, topic);
             if (!canAccessTopic) {
                 ar.assertMember("must have permission to subscribe to a topic");
             }
             UserProfile up = ar.getUserProfile();
             AddressListEntry ale;
             if (up==null) {
                 //if they are not logged in, but allowed, then they must have
                 //and emailId parameter
                 ale = new AddressListEntry(ar.reqParam("emailId"));
             }
             else {
                 ale = up.getAddressListEntry();
             }

             topic.getSubscriberRole().addPlayer(ale);
             JSONObject repo = topic.getJSONWithComments(ar, ngw);
             ngw.save(); //just save flag, don't mark page as changed
             sendJson(ar, repo);
         }catch(Exception ex){
             Exception ee = new Exception("Unable to subscribe to topic "+nid+" contents", ex);
             streamException(ee, ar);
         }
     }


     @RequestMapping(value = "/{siteId}/{pageId}/topicUnsubscribe.json", method = RequestMethod.GET)
     public void topicUsubscribe(@PathVariable String siteId,@PathVariable String pageId,
             HttpServletRequest request, HttpServletResponse response) {
         AuthRequest ar = AuthRequest.getOrCreate(request, response);
         String nid = "";
         try{
             NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail( siteId, pageId ).getWorkspace();
             ar.setPageAccessLevels(ngw);
             ar.assertNotFrozen(ngw);
             nid = ar.reqParam("nid");
             TopicRecord topic = ngw.getDiscussionTopic(nid);
             boolean canAccessTopic  = AccessControl.canAccessTopic(ar, ngw, topic);
             if (!canAccessTopic) {
                 //well ... the idea is that anyone can UNSUBSCRIBE.
                 //this might be open to abuse, allowing people to unsubscribe others
                 //but they will be resubscribed on the next comment ... so maybe
                 //harmless?
             }
             UserProfile up = ar.getUserProfile();
             AddressListEntry ale;
             if (up==null) {
                 //if they are not logged in, but allowed, then they must have
                 //and emailId parameter
                 ale = new AddressListEntry(ar.reqParam("emailId"));
             }
             else {
                 ale = up.getAddressListEntry();
             }

             topic.getSubscriberRole().removePlayerCompletely(ale);
             ngw.save(); //just save flag, don't mark page as changed
             JSONObject repo = topic.getJSONWithComments(ar, ngw);
             sendJson(ar, repo);
         }catch(Exception ex){
             Exception ee = new Exception("Unable to subscribe to topic "+nid+" contents", ex);
             streamException(ee, ar);
         }
     }


     /*
      * Pull the first 100 character max from the string, but ignore anything
      * that looks like an HTML tag, and anything inside those tags.
      * Does not handle script tags or other expressions in attributes ... but there should not be any.
      */
     private String GetFirstHundredNoHtml(String input) {
         int limit = 100;
         boolean inTag = false;
         StringBuilder res = new StringBuilder();
         for (int i=0; i<input.length() && limit>0; i++) {
             char ch = input.charAt(i);
             if (inTag) {
                 if ('>' == ch) {
                     inTag=false;
                 }
                 //ignore all other characters while in the tag
             }
             else {
                 if ('<' == ch) {
                     inTag=true;
                 }
                 else {
                     res.append(ch);
                     limit--;
                 }
             }
         }
         return res.toString();
     }


     @RequestMapping(value = "/{siteId}/{pageId}/getNoteHistory.json", method = RequestMethod.GET)
     public void getGoalHistory(@PathVariable String siteId,@PathVariable String pageId,
             HttpServletRequest request, HttpServletResponse response) {
         AuthRequest ar = AuthRequest.getOrCreate(request, response);
         try{
             NGWorkspace ngp = ar.getCogInstance().getWSBySiteAndKeyOrFail( siteId, pageId ).getWorkspace();
             ar.setPageAccessLevels(ngp);
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
            streamJSP(ar, "EmailAdjustment");
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

              JSONObject goalInfo = getPostedObject(ar);
              GoalRecord gr = ngw.createGoal(ar.getBestUserId());

              //create the history record here.
              HistoryRecord.createHistoryRecord(ngw, gr.getId(),
                      HistoryRecord.CONTEXT_TYPE_TASK, HistoryRecord.EVENT_TYPE_CREATED, ar,
                      "action item synopsis: "+gr.getSynopsis());

              //currently the update from JSON is designed for upstream sync.
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
      @RequestMapping(value = "/requiredName.form", method = RequestMethod.POST)
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
