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

import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.TimeZone;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.socialbiz.cog.AccessControl;
import org.socialbiz.cog.AddressListEntry;
import org.socialbiz.cog.AgendaItem;
import org.socialbiz.cog.AttachmentRecord;
import org.socialbiz.cog.AuthRequest;
import org.socialbiz.cog.BaseRecord;
import org.socialbiz.cog.GoalRecord;
import org.socialbiz.cog.HistoryRecord;
import org.socialbiz.cog.MeetingRecord;
import org.socialbiz.cog.NGBook;
import org.socialbiz.cog.NGPage;
import org.socialbiz.cog.NGRole;
import org.socialbiz.cog.NGWorkspace;
import org.socialbiz.cog.SearchManager;
import org.socialbiz.cog.SearchResultRecord;
import org.socialbiz.cog.SectionDef;
import org.socialbiz.cog.TopicRecord;
import org.socialbiz.cog.UserManager;
import org.socialbiz.cog.UserProfile;
import org.socialbiz.cog.exception.NGException;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.servlet.ModelAndView;
import org.workcast.json.JSONArray;
import org.workcast.json.JSONObject;

@Controller
public class MainTabsViewControler extends BaseController {


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
        showJSPAnonymous(ar, siteId, pageId, "NotesList");
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
        showJSPLoggedIn(ar, siteId, pageId, "../jsp/FrontPage");
    }


    @RequestMapping(value = "/{siteId}/{pageId}/SiteHome.htm", method = RequestMethod.GET)
    public void siteHome(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        showJSPMembers(ar, siteId, pageId, "../jsp/SiteHome");
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
           request.setAttribute("lid", lid);
           NGPage ngp = registerRequiredProject(ar, siteId, pageId);
           TopicRecord note = ngp.getNoteOrFail(lid);
           boolean canAccessNote  = AccessControl.canAccessNote(ar, ngp, note);
           if (canAccessNote) {
               showJSPAnonymous(ar, siteId, pageId, "NoteZoom");
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

    @RequestMapping(value = "/{siteId}/{pageId}/meetingFull.htm", method = RequestMethod.GET)
    public void meetingFull(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            NGWorkspace ngw = registerRequiredProject(ar, siteId, pageId);

            String id = ar.reqParam("id");
            MeetingRecord meet = ngw.findMeeting(id);
            boolean canAccess = AccessControl.canAccessMeeting(ar, ngw, meet);
            if (!canAccess) {
                showJSPMembers(ar, siteId, pageId, "MeetingFull");
                return;
            }

            streamJSP(ar, "MeetingFull");
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.project.process.page", new Object[]{pageId,siteId} , ex);
        }
    }


    @RequestMapping(value = "/{siteId}/{pageId}/meetingTime{meetId}.ics", method = RequestMethod.GET)
    public void meetingTime(@PathVariable String siteId,@PathVariable String pageId,
            @PathVariable String meetId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            ar.assertLoggedIn("must be logged in to access calendar file");
            NGWorkspace ngw = registerRequiredProject(ar, siteId, pageId);
            MeetingRecord meet = ngw.findMeeting(meetId);
            boolean canAccess = AccessControl.canAccessMeeting(ar, ngw, meet);
            if (!canAccess) {
                throw new Exception("Unable to access that meeting with user "+ar.getBestUserId());
            }

            AddressListEntry ale = new AddressListEntry(meet.getOwner());

            StringBuilder sb = new StringBuilder();
            sb.append("BEGIN:VCALENDAR\n");
            sb.append("VERSION:2.0\n");
            sb.append("PRODID:-//Fujitsu/Weaver//NONSGML v1.0//EN\n");
            sb.append("BEGIN:VEVENT\n");
            sb.append("UID:"+ngw.getSiteKey()+ngw.getKey()+meet.getId()+"\n");
            sb.append("DTSTAMP:"+getSpecialDateFormat(System.currentTimeMillis())+"\n");
            sb.append("ORGANIZER:CN="+ale.getName()+":MAILTO:"+ale.getEmail()+"\n");
            sb.append("DTSTART:"+getSpecialDateFormat(meet.getStartTime())+"\n");
            sb.append("DTEND:"+getSpecialDateFormat(meet.getStartTime()+(meet.getDuration()*60*1000))+"\n");
            sb.append("SUMMARY:"+meet.getName()+"\n");
            sb.append("DESCRIPTION:"+specialEncode(meet.getMeetingDescription())+"\n");
            sb.append("END:VEVENT\n");
            sb.append("END:VCALENDAR\n");

            ar.resp.setContentType("text/calendar");
            ar.write(sb.toString());
            ar.flush();

        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.project.process.page", new Object[]{pageId,siteId} , ex);
        }
    }

    private String getSpecialDateFormat(long date) {
        SimpleDateFormat formatter = new SimpleDateFormat("yyyyMMdd'T'HHmmss'Z'");
        formatter.setTimeZone(TimeZone.getTimeZone("UTC"));
        return formatter.format(new Date(date));
    }
    private String specialEncode(String input) {
        StringBuilder sb = new StringBuilder();
        for (int i=0; i<input.length(); i++) {
            char ch = input.charAt(i);
            if (ch=='\n') {
                sb.append("\\n");
            }
            else if (ch<' ') {
                //do nothing
            }
            else {
                sb.append(ch);
            }
        }
        return sb.toString();
    }

    @RequestMapping(value = "/{siteId}/{pageId}/cloneMeeting.htm", method = RequestMethod.GET)
    public void cloneMeeting(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        showJSPMembers(ar, siteId, pageId, "CloneMeeting");
    }

    @RequestMapping(value = "/{siteId}/{pageId}/meeting.htm", method = RequestMethod.GET)
    public void meeting(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        showJSPMembers(ar, siteId, pageId, "Meeting");
    }

    @RequestMapping(value = "/{siteId}/{pageId}/agendaBacklog.htm", method = RequestMethod.GET)
    public void agendaBacklog(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        showJSPMembers(ar, siteId, pageId, "AgendaBacklog");
    }

    @RequestMapping(value = "/{siteId}/{pageId}/agendaItem.htm", method = RequestMethod.GET)
    public void agendaItem(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        showJSPMembers(ar, siteId, pageId, "AgendaItem");
    }

    @RequestMapping(value = "/{siteId}/{pageId}/meetingList.htm", method = RequestMethod.GET)
    public void meetingList(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        showJSPMembers(ar, siteId, pageId, "MeetingList");
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
                 response.sendRedirect(ar.retPath+"v/"+ar.getUserProfile().getKey()+"/watchedProjects.htm");
                 return null;
             }

             ModelAndView modelAndView=new ModelAndView("landingPage");
             request.setAttribute("realRequestURL", ar.getRequestURL());
             List<NGBook> list=new ArrayList<NGBook>();
             for (NGBook ngb : NGBook.getAllSites()) {
                 list.add(ngb);
             }

             request.setAttribute("headerType", "blank");
             //TODO: see if bookList is really needed
             modelAndView.addObject("bookList",list);
             return modelAndView;
         }catch(Exception ex){
             throw new NGException("nugen.operation.fail.project.welcome.page", null , ex);
         }
     }




     @RequestMapping(value = "/{siteId}/{pageId}/getTopics.json", method = RequestMethod.GET)
     public void getTopics(@PathVariable String siteId,@PathVariable String pageId,
             HttpServletRequest request, HttpServletResponse response) {
         AuthRequest ar = AuthRequest.getOrCreate(request, response);
         try{
             NGWorkspace ngw = ar.getCogInstance().getWorkspaceByKeyOrFail( pageId );
             ar.setPageAccessLevels(ngw);
             boolean isMember = ar.isMember();

             List<TopicRecord> aList = ngw.getAllNotes();

             JSONArray notes = new JSONArray();
             for (TopicRecord aNote : aList) {

                 String discussionPhase = aNote.getDiscussionPhase();

                 if (aNote.isPublic()) {
                     notes.put( aNote.getJSONWithHtml(ar, ngw) );
                 }
                 else if (!ar.isLoggedIn()) {
                     continue;
                 }
                 else if ("Draft".equals(discussionPhase)) {
                     if (ar.getUserProfile().hasAnyId(aNote.getModUser().getUniversalId())) {
                         notes.put( aNote.getJSONWithHtml(ar, ngw) );
                     }
                 }
                 else if (isMember) {
                     notes.put( aNote.getJSONWithHtml(ar, ngw) );
                 }
                 else {
                     //run through all the roles here and see if any role
                     //has access to the note
                 }
             }

             notes.write(ar.w, 2, 2);
             ar.flush();
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
             NGWorkspace ngw = ar.getCogInstance().getWorkspaceByKeyOrFail( pageId );
             ar.setPageAccessLevels(ngw);
             ar.assertMember("Must be a member to update a topic contents.");
             ar.assertNotFrozen(ngw);
             nid = ar.reqParam("nid");
             JSONObject noteInfo = getPostedObject(ar);

             TopicRecord note = null;
             int eventType = HistoryRecord.EVENT_TYPE_MODIFIED;
             if ("~new~".equals(nid)) {
                 note = ngw.createNote();
                 noteInfo.put("universalid", note.getUniversalId());
                 eventType = HistoryRecord.EVENT_TYPE_CREATED;
             }
             else {
                 note = ngw.getNote(nid);
             }

             note.updateNoteFromJSON(noteInfo, ar);
             note.updateHtmlFromJSON(ar, noteInfo);
             note.setLastEdited(ar.nowTime);
             note.setModUser(new AddressListEntry(ar.getBestUserId()));
             HistoryRecord.createHistoryRecord(ngw, note.getId(), HistoryRecord.CONTEXT_TYPE_LEAFLET,
                     0, eventType, ar, "");

             ngw.saveFile(ar, "Updated Topic Contents");

             JSONObject repo = note.getJSONWithComments(ar, ngw);
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
             NGWorkspace ngw = ar.getCogInstance().getWorkspaceByKeyOrFail( pageId );
             ar.setPageAccessLevels(ngw);
             boolean isMember = ar.isMember();

             JSONArray allTopics = new JSONArray();
             for (TopicRecord aNote : ngw.getAllNotes()) {
                 if (!isMember && !aNote.isPublic()) {
                     //skip non public if not member
                     continue;
                 }
                 allTopics.put(aNote.getJSON(ngw));
             }

             JSONObject repo = new JSONObject();
             repo.put("topics", allTopics);
             repo.write(ar.w, 2, 2);
             ar.flush();
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
             NGWorkspace ngw = ar.getCogInstance().getWorkspaceByKeyOrFail( pageId );
             NGBook ngb = ngw.getSite();
             ar.setPageAccessLevels(ngw);
             ar.assertMember("Must be a member to update a topic contents.");
             ar.assertNotFrozen(ngw);
             nid = ar.reqParam("nid");
             JSONObject noteInfo = getPostedObject(ar);
             TopicRecord note = ngw.getNote(nid);

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

             //enforce no private BEFORE saving the update
             if (!ngb.getAllowPrivate()) {
                 if (note.getVisibility()!=SectionDef.PUBLIC_ACCESS) {
                     throw new Exception("This workspace belongs to a site that does not allow private topics.  "
                             +"See your site's license requirements to understand what restrictions exist there.");
                 }
             }

             ngw.saveFile(ar, "Updated Topic Contents");

             JSONObject repo = note.getJSONWithComments(ar, ngw);
             repo.write(ar.w, 2, 2);
             ar.flush();
         }catch(Exception ex){
             Exception ee = new Exception("Unable to updated topic "+nid+" contents", ex);
             streamException(ee, ar);
         }
     }

     @RequestMapping(value = "/{siteId}/{pageId}/topicSubscribe.json", method = RequestMethod.POST)
     public void topicSubscribe(@PathVariable String siteId,@PathVariable String pageId,
             HttpServletRequest request, HttpServletResponse response) {
         AuthRequest ar = AuthRequest.getOrCreate(request, response);
         String nid = "";
         try{
             NGWorkspace ngw = ar.getCogInstance().getWorkspaceByKeyOrFail( pageId );
             ar.setPageAccessLevels(ngw);
             ar.assertMember("Must be a member to subscribe to a topic.");
             ar.assertNotFrozen(ngw);
             nid = ar.reqParam("nid");
             TopicRecord note = ngw.getNote(nid);
             UserProfile up = ar.getUserProfile();

             boolean found = false;
             List<AddressListEntry> subs = note.getSubscribers();
             for (AddressListEntry ale : subs) {
                 if (up.hasAnyId(ale.getUniversalId())) {
                     found = true;
                 }
             }
             if (!found) {
                 subs.add( new AddressListEntry(up.getUniversalId()) );
                 note.setSubscribers(subs);
                 ngw.saveFile(ar, "Added subscriber");
             }


             JSONObject repo = note.getJSONWithComments(ar, ngw);
             repo.write(ar.w, 2, 2);
             ar.flush();
         }catch(Exception ex){
             Exception ee = new Exception("Unable to subscribe to topic "+nid+" contents", ex);
             streamException(ee, ar);
         }
     }


     @RequestMapping(value = "/{siteId}/{pageId}/topicUsubscribe.json", method = RequestMethod.POST)
     public void topicUsubscribe(@PathVariable String siteId,@PathVariable String pageId,
             HttpServletRequest request, HttpServletResponse response) {
         AuthRequest ar = AuthRequest.getOrCreate(request, response);
         String nid = "";
         try{
             NGWorkspace ngw = ar.getCogInstance().getWorkspaceByKeyOrFail( pageId );
             ar.setPageAccessLevels(ngw);
             ar.assertNotFrozen(ngw);
             nid = ar.reqParam("nid");
             TopicRecord note = ngw.getNote(nid);
             UserProfile up = ar.getUserProfile();

             AddressListEntry found = null;
             List<AddressListEntry> subs = note.getSubscribers();
             for (AddressListEntry ale : subs) {
                 if (up.hasAnyId(ale.getUniversalId())) {
                     found = ale;
                 }
             }
             if (found!=null) {
                 subs.remove( found );
                 note.setSubscribers(subs);
                 ngw.saveFile(ar, "Removed subscriber");
             }


             JSONObject repo = note.getJSONWithComments(ar, ngw);
             repo.write(ar.w, 2, 2);
             ar.flush();
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
         StringBuffer res = new StringBuffer();
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
             NGPage ngp = ar.getCogInstance().getWorkspaceByKeyOrFail( pageId );
             ar.setPageAccessLevels(ngp);
             String nid = ar.reqParam("nid");
             TopicRecord note = ngp.getNoteOrFail(nid);

             JSONArray repo = new JSONArray();
             for (HistoryRecord hist : note.getNoteHistory(ngp)) {
                 repo.put(hist.getJSON(ngp, ar));
             }
             repo.write(ar.w, 2, 2);
             ar.flush();
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

            NGPage ngp = ar.getCogInstance().getWorkspaceByKeyOrFail(p);
            String expectedMn = ngp.emailDependentMagicNumber(email);
            if (!expectedMn.equals(mn)) {
                throw new Exception("Something is wrong, improper request for email address "+email);
            }

            String cmd = ar.reqParam("cmd");
            if ("Remove Me".equals(cmd)) {
                String role = ar.reqParam("role");
                NGRole specRole = ngp.getRoleOrFail(role);
                specRole.removePlayer(new AddressListEntry(email));
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
            NGPage ngp = ar.getCogInstance().getWorkspaceByKeyOrFail(p);
            String role = ar.reqParam("role");
            NGRole specRole = ngp.getRoleOrFail(role);
            specRole.removePlayer(ar.getUserProfile().getAddressListEntry());
            ngp.saveFile(ar, "user removed themself from role "+role);

            JSONObject results = new JSONObject();
            results.put("result", "ok");
            results.write(ar.w, 2, 2);
            ar.flush();
        }catch(Exception ex){
            Exception ee = new Exception("Unable to remove user from role.", ex);
            streamException(ee, ar);
        }
    }





    /**
     * This is search page that you get when NOT LOGGED IN from the
     * landing page.  However, you can also see this when logged in.
     */
    @RequestMapping(value = "/searchPublicNotes.htm")
    public ModelAndView searchPublicNotes(
              HttpServletRequest request, HttpServletResponse response) throws Exception {
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            String searchText   = ar.defParam("searchText", "");
            String b = ar.defParam("b", null);
            if ("All Books".equals(b)) {
                b = null;
            }
            String pf = ar.defParam("pf", "all");

            SearchManager.initializeIndex(ar.getCogInstance());
            List<SearchResultRecord> searchResults = null;
            if (searchText.length()>0) {
                searchResults = SearchManager.performSearch(ar, searchText, pf, b);
            }
            else {
                searchResults = new ArrayList<SearchResultRecord>();
            }
            request.setAttribute("searchResults",searchResults);
            return  new ModelAndView("showSearchResult");
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.project.search.public.note.page", null , ex);
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

            SearchManager.initializeIndex(ar.getCogInstance());
            List<SearchResultRecord> searchResults = null;
            if (searchText.length()>0) {
                searchResults = SearchManager.performSearch(ar, searchText, searchProject, siteId);
            }
            else {
                searchResults = new ArrayList<SearchResultRecord>();
            }

            JSONArray resultList = new JSONArray();
            for (SearchResultRecord srr : searchResults) {
                resultList.put(srr.getJSON());
            }
            resultList.write(ar.w, 2, 2);
            ar.flush();
        }catch(Exception ex){
            Exception ee = new Exception("Unable to search for topics.", ex);
            streamException(ee, ar);
        }
    }



      @RequestMapping(value = "/isNoteDeleted.ajax", method = RequestMethod.POST)
      public void isNoteDeleted(HttpServletRequest request, HttpServletResponse response)
             throws Exception {
         String responseText = null;
         AuthRequest ar = AuthRequest.getOrCreate(request, response);
         try {
             ar.assertLoggedIn("Must be logged in to create a topic.");
             String p = ar.reqParam("p");
             NGPage ngp = ar.getCogInstance().getWorkspaceByKeyOrFail( p );
             ar.setPageAccessLevels(ngp);

             String oid = ar.reqParam("oid");
             JSONObject paramMap = new JSONObject();
             TopicRecord note = ngp.getNoteOrFail(oid);
             if(note.isDeleted()){
                 paramMap.put("msgType", "yes");
             }else{
                 paramMap.put("msgType", "no");
             }

             responseText = paramMap.toString();
         }
         catch (Exception ex) {
             responseText = NGWebUtils.getExceptionMessageForAjaxRequest(ex, ar.getLocale());
             ar.logException("Caught by isNoteDeleted.ajax", ex);
         }
         NGWebUtils.sendResponse(ar, responseText);
     }


      @RequestMapping(value = "/{siteId}/{pageId}/meetingCreate.json", method = RequestMethod.POST)
      public void meetingCreate(@PathVariable String siteId,@PathVariable String pageId,
              HttpServletRequest request, HttpServletResponse response) {
          AuthRequest ar = AuthRequest.getOrCreate(request, response);
          try{
              NGWorkspace ngw = ar.getCogInstance().getWorkspaceByKeyOrFail( pageId );
              ar.setPageAccessLevels(ngw);
              ar.assertMember("Must be a member to create a meeting.");
              ar.assertNotFrozen(ngw);
              JSONObject meetingInfo = getPostedObject(ar);
              String name = meetingInfo.getString("name");
              if (name==null || name.length()==0) {
                  throw new Exception("You must supply a meeting name to create a meeting.");
              }
              MeetingRecord newMeeting = ngw.createMeeting();
              newMeeting.setOwner(ar.getBestUserId());
              removeCompletedActionItems(ngw, meetingInfo);
              newMeeting.updateFromJSON(meetingInfo, ar);
              newMeeting.createAgendaFromJSON(meetingInfo, ar, ngw);
              newMeeting.setState(1);
              HistoryRecord.createHistoryRecord(ngw, newMeeting.getId(),
                      HistoryRecord.CONTEXT_TYPE_MEETING,
                      HistoryRecord.EVENT_TYPE_CREATED, ar, "");

              ngw.saveFile(ar, "Created new Meeting");
              JSONObject repo = newMeeting.getFullJSON(ar, ngw);
              repo.write(ar.w, 2, 2);
              ar.flush();
          }catch(Exception ex){
              Exception ee = new Exception("Unable to create meeting.", ex);
              streamException(ee, ar);
          }
      }

      /*
       * The point is that uncompleted action items should get dragged to the next copy
       * of the meeting.  Completed or skipped action items should NOT be dragged along.
       * They are no longer useful.
       */
      private void removeCompletedActionItems(NGPage ngp, JSONObject meetingInfo) throws Exception {
          if (!meetingInfo.has("agenda")) {
              return;
          }
          JSONArray agenda = meetingInfo.getJSONArray("agenda");
          for (int i=0; i<agenda.length(); i++) {
              JSONObject agendaItem = agenda.getJSONObject(i);
              if (!agendaItem.has("actionItems")) {
                  continue;
              }
              JSONArray actionItems = agendaItem.getJSONArray("actionItems");
              JSONArray approvedItems = new JSONArray();
              for (int j=0; j<actionItems.length(); j++) {
                  String universalId = actionItems.getString(j);
                  GoalRecord gr = ngp.getGoalOrNull(universalId);
                  if (gr==null) {
                      continue;
                  }
                  if (gr.getState()==BaseRecord.STATE_COMPLETE) {
                      continue;
                  }
                  if (gr.getState()==BaseRecord.STATE_SKIPPED) {
                      continue;
                  }
                  approvedItems.put(universalId);
              }
              agendaItem.put("actionItems", approvedItems);
          }

      }

      @RequestMapping(value = "/{siteId}/{pageId}/meetingUpdate.json", method = RequestMethod.POST)
      public void meetingUpdate(@PathVariable String siteId,@PathVariable String pageId,
              HttpServletRequest request, HttpServletResponse response) {
          AuthRequest ar = AuthRequest.getOrCreate(request, response);
          try{
              NGWorkspace ngw = ar.getCogInstance().getWorkspaceByKeyOrFail( pageId );
              ar.setPageAccessLevels(ngw);
              ar.assertMember("Must be a member to update a meeting.");
              ar.assertNotFrozen(ngw);
              String id = ar.reqParam("id");
              MeetingRecord meeting = ngw.findMeeting(id);
              JSONObject meetingInfo = getPostedObject(ar);

              meeting.updateFromJSON(meetingInfo, ar);
              meeting.updateAgendaFromJSON(meetingInfo, ar, ngw);

              if (meetingInfo.has("agenda")) {
                  JSONArray agenda = meetingInfo.getJSONArray("agenda");
                  for (int i=0; i<agenda.length(); i++) {
                      JSONObject aItem = agenda.getJSONObject(i);
                      if (aItem.has("newComment")) {
                          JSONObject newComment = aItem.getJSONObject("newComment");
                          if (newComment.has("html")) {
                              String comment = newComment.getString("html");
                              comment = GetFirstHundredNoHtml(comment);
                              HistoryRecord.createHistoryRecord(ngw, meeting.getId(),
                                      HistoryRecord.CONTEXT_TYPE_MEETING,
                                      HistoryRecord.EVENT_COMMENT_ADDED, ar, comment);
                          }
                      }
                  }
              }


              ngw.saveFile(ar, "Updated Meeting");
              JSONObject repo = meeting.getFullJSON(ar, ngw);
              repo.write(ar.w, 2, 2);
              ar.flush();
          }catch(Exception ex){
              Exception ee = new Exception("Unable to create meeting.", ex);
              streamException(ee, ar);
          }
      }


      @RequestMapping(value = "/{siteId}/{pageId}/meetingDelete.json", method = RequestMethod.POST)
      public void meetingDelete(@PathVariable String siteId,@PathVariable String pageId,
              HttpServletRequest request, HttpServletResponse response) {
          AuthRequest ar = AuthRequest.getOrCreate(request, response);
          String meetingId = "";
          try{
              NGPage ngp = ar.getCogInstance().getWorkspaceByKeyOrFail( pageId );
              ar.setPageAccessLevels(ngp);
              ar.assertMember("Must be a member to delete a meeting.");
              ar.assertNotFrozen(ngp);
              JSONObject meetingInfo = getPostedObject(ar);
              meetingId = meetingInfo.getString("id");
              ngp.removeMeeting(meetingId);
              ngp.saveFile(ar, "Deleted new Meeting");
              ar.write("deleted Meeting "+meetingId);
              ar.flush();
          } catch(Exception ex){
              Exception ee = new Exception("Unable to delete meeting "+meetingId, ex);
              streamException(ee, ar);
          }
      }



      @RequestMapping(value = "/{siteId}/{pageId}/agendaAdd.json", method = RequestMethod.POST)
      public void agendaAdd(@PathVariable String siteId,@PathVariable String pageId,
              HttpServletRequest request, HttpServletResponse response) {
          AuthRequest ar = AuthRequest.getOrCreate(request, response);
          try{
              NGWorkspace ngw = ar.getCogInstance().getWorkspaceByKeyOrFail( pageId );
              ar.setPageAccessLevels(ngw);
              ar.assertMember("Must be a member to add an agenda item.");
              ar.assertNotFrozen(ngw);
              String id = ar.reqParam("id");
              MeetingRecord meeting = ngw.findMeeting(id);
              JSONObject agendaInfo = getPostedObject(ar);

              String subject = agendaInfo.getString("subject");
              if (subject==null || subject.length()==0) {
                  throw new Exception("You must supply a agenda subject to create an agenda item.");
              }
              AgendaItem ai = meeting.createAgendaItem(ngw);
              ai.setPosition(99999);
              ai.setSubject(subject);
              ai.updateFromJSON(ar, agendaInfo, ngw);

              meeting.renumberItems();
              ngw.saveFile(ar, "Created new Agenda Item");
              JSONObject repo = ai.getJSON(ar, ngw, meeting);
              repo.write(ar.w, 2, 2);
              ar.flush();
          }catch(Exception ex){
              Exception ee = new Exception("Unable to create agenda item.", ex);
              streamException(ee, ar);
          }
      }

      @RequestMapping(value = "/{siteId}/{pageId}/agendaDelete.json", method = RequestMethod.POST)
      public void agendaDelete(@PathVariable String siteId,@PathVariable String pageId,
              HttpServletRequest request, HttpServletResponse response) {
          AuthRequest ar = AuthRequest.getOrCreate(request, response);
          try{
              NGPage ngp = ar.getCogInstance().getWorkspaceByKeyOrFail( pageId );
              ar.setPageAccessLevels(ngp);
              ar.assertMember("Must be a member to delete a meeting.");
              ar.assertNotFrozen(ngp);
              String id = ar.reqParam("id");
              MeetingRecord meeting = ngp.findMeeting(id);
              JSONObject agendaInfo = getPostedObject(ar);

              String agendaId = agendaInfo.getString("id");
              meeting.removeAgendaItem(agendaId);
              meeting.renumberItems();
              ngp.saveFile(ar, "Deleted Agenda Item");
              ar.write("deleted agenda item "+agendaId);
              ar.flush();
          } catch(Exception ex){
              Exception ee = new Exception("Unable to delete agenda item.", ex);
              streamException(ee, ar);
          }
      }


      @RequestMapping(value = "/{siteId}/{pageId}/agendaMove.json", method = RequestMethod.POST)
      public void agendaMove(@PathVariable String siteId,@PathVariable String pageId,
              HttpServletRequest request, HttpServletResponse response) {
          AuthRequest ar = AuthRequest.getOrCreate(request, response);
          try{
              NGWorkspace ngw = ar.getCogInstance().getWorkspaceByKeyOrFail( pageId );
              ar.setPageAccessLevels(ngw);
              ar.assertMember("Must be a member to move an agenda item.");
              ar.assertNotFrozen(ngw);
              String src = ar.reqParam("src");
              String dest = ar.reqParam("dest");
              MeetingRecord meeting = ngw.findMeeting(src);
              MeetingRecord destMeeting = ngw.findMeeting(dest);
              JSONObject agendaInfo = getPostedObject(ar);
              String agendaId = agendaInfo.getString("id");
              meeting.removeAgendaItem(agendaId);
              meeting.renumberItems();

              AgendaItem ai = destMeeting.findAgendaItemOrNull(agendaId);
              if (ai==null) {
                  ai = destMeeting.createAgendaItem(ngw);
              }
              agendaInfo.put("position", 99999);
              ai.updateFromJSON(ar,agendaInfo, ngw);
              destMeeting.renumberItems();
              ngw.saveFile(ar, "Move Agenda Item");
              JSONObject repo = ai.getJSON(ar, ngw, meeting);
              repo.write(ar.w, 2, 2);
              ar.flush();
          } catch(Exception ex){
              Exception ee = new Exception("Unable to move agenda item.", ex);
              streamException(ee, ar);
          }
      }



      @RequestMapping(value = "/{siteId}/{pageId}/agendaUpdate.json", method = RequestMethod.POST)
      public void agendaUpdate(@PathVariable String siteId,@PathVariable String pageId,
              HttpServletRequest request, HttpServletResponse response) {
          AuthRequest ar = AuthRequest.getOrCreate(request, response);
          try{
              NGWorkspace ngw = ar.getCogInstance().getWorkspaceByKeyOrFail( pageId );
              ar.setPageAccessLevels(ngw);
              ar.assertMember("Must be a member to update an agenda item.");
              ar.assertNotFrozen(ngw);
              String id = ar.reqParam("id");
              MeetingRecord meeting = ngw.findMeeting(id);
              String aid = ar.reqParam("aid");
              AgendaItem ai = null;
              if (!"~new~".equals(aid)) {
                  ai = meeting.findAgendaItem(aid);
                  if (ai==null) {
                      throw new Exception("Can not find an agenda item ("+aid+") in meeting ("+id+")");
                  }
              }
              else {
                  ai = meeting.createAgendaItem(ngw);
              }
              JSONObject agendaInfo = getPostedObject(ar);

              //handle the position here to update the meeting order correctly
              int newPos = agendaInfo.optInt("position");
              int oldPos = ai.getPosition();
              if (newPos>0 && newPos!=oldPos) {
                  meeting.openPosition(newPos);
                  ai.setPosition(newPos);
                  meeting.renumberItems();
                  //put the final position (wherever it ended up)
                  //back into the JSON for the update below
                  agendaInfo.optInt("position", ai.getPosition());
              }

              //everything else updated here
              ai.updateFromJSON(ar, agendaInfo, ngw);

              ngw.saveFile(ar, "Updated Agenda Item");
              JSONObject repo = ai.getJSON(ar, ngw, meeting);
              repo.write(ar.w, 2, 2);
              ar.flush();
          }catch(Exception ex){
              Exception ee = new Exception("Unable to create agenda item.", ex);
              streamException(ee, ar);
          }
      }


      @RequestMapping(value = "/{siteId}/{pageId}/createMinutes.json", method = RequestMethod.POST)
      public void createMinutes(@PathVariable String siteId,@PathVariable String pageId,
              HttpServletRequest request, HttpServletResponse response) {
          AuthRequest ar = AuthRequest.getOrCreate(request, response);
          try{
              NGWorkspace ngw = ar.getCogInstance().getWorkspaceByKeyOrFail( pageId );
              ar.setPageAccessLevels(ngw);
              ar.assertMember("Must be a member to update an agenda item.");
              ar.assertNotFrozen(ngw);
              String id = ar.reqParam("id");
              MeetingRecord meeting = ngw.findMeeting(id);

              TopicRecord nr = null;
              //
              //commented out:  ALWAYS create a new minutes, never overwrite an existing one.
              //
              //String minId =  meeting.getMinutesId();
              //if (minId!=null && minId.length()>0) {
              //    nr = ngw.getNoteByUidOrNull(minId);
              //}
              if (nr==null) {
                  nr = ngw.createNote();
                  nr.setSubject("Minutes for Meeting: "+meeting.getName());
                  meeting.setMinutesId(nr.getUniversalId());
                  ngw.findOrCreateLabelRecord("Minutes", "SkyBlue");
                  nr.assureLabel("Minutes");
              }
              nr.setWiki(meeting.generateMinutes(ar,  ngw));
              nr.setModUser(ar.getUserProfile());
              nr.setDiscussionPhase(TopicRecord.DISCUSSION_PHASE_DRAFT, ar);

              //now copy all the attachment references across
              for (AgendaItem ai : meeting.getAgendaItems()) {
                  for (String aid : ai.getDocList()) {
                      AttachmentRecord att = ngw.findAttachmentByID(aid);
                      if (att!=null) {
                          nr.addDocId(aid);
                      }
                  }
              }
              nr.setLastEdited(ar.nowTime);

              ngw.saveFile(ar, "Created Topic for minutes of meeting.");
              JSONObject repo = meeting.getFullJSON(ar, ngw);
              repo.write(ar.w, 2, 2);
              ar.flush();
          }catch(Exception ex){
              Exception ee = new Exception("Unable to create Topic for minutes of meeting.", ex);
              streamException(ee, ar);
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
              NGPage ngp = ar.getCogInstance().getWorkspaceByKeyOrFail( pageId );
              ar.setPageAccessLevels(ngp);
              ar.assertMember("Must be a member to create a action item.");
              ar.assertNotFrozen(ngp);

              JSONObject goalInfo = getPostedObject(ar);
              GoalRecord gr = ngp.createGoal(ar.getBestUserId());

              //create the history record here.
              HistoryRecord.createHistoryRecord(ngp, gr.getId(),
                      HistoryRecord.CONTEXT_TYPE_TASK, HistoryRecord.EVENT_TYPE_CREATED, ar,
                      "action item synopsis: "+gr.getSynopsis());

              //currently the update from JSON is designed for upstream sync.
              //There is a check that requires this to do the update.
              goalInfo.put("universalid", gr.getUniversalId());
              gr.updateGoalFromJSON(goalInfo, ngp, ar);
              gr.setCreator(ar.getBestUserId());
              System.out.println("SETTING creator toL "+ar.getBestUserId());
              if (gr.getCreator()==null || gr.getCreator().length()==0) {
                  throw new Exception("can not set the creator");
              }

              ngp.saveFile(ar, "Created action item for minutes of meeting.");
              JSONObject repo = gr.getJSON4Goal(ngp);
              repo.write(ar.w, 2, 2);
              ar.flush();
          }catch(Exception ex){
              Exception ee = new Exception("Unable to create Action Item for minutes of meeting.", ex);
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
                  UserManager.writeUserProfilesToFile();
              }
              response.sendRedirect(go);
          }catch(Exception ex){
              throw new NGException("nugen.operation.fail.project.sent.note.by.email.page", null , ex);
          }
      }


}
