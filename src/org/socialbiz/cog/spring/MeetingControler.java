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
import java.util.Calendar;
import java.util.Date;
import java.util.HashSet;
import java.util.TimeZone;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.socialbiz.cog.AccessControl;
import org.socialbiz.cog.AgendaItem;
import org.socialbiz.cog.AttachmentRecord;
import org.socialbiz.cog.AuthRequest;
import org.socialbiz.cog.BaseRecord;
import org.socialbiz.cog.GoalRecord;
import org.socialbiz.cog.HistoryRecord;
import org.socialbiz.cog.MeetingRecord;
import org.socialbiz.cog.NGPage;
import org.socialbiz.cog.NGRole;
import org.socialbiz.cog.NGWorkspace;
import org.socialbiz.cog.TopicRecord;
import org.socialbiz.cog.UserProfile;
import org.socialbiz.cog.exception.NGException;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;

import com.purplehillsbooks.json.JSONArray;
import com.purplehillsbooks.json.JSONObject;
import com.purplehillsbooks.streams.MemFile;


@Controller
public class MeetingControler extends BaseController {
    
    public static MeetingNotesCache meetingCache = new MeetingNotesCache();

    @RequestMapping(value = "/{siteId}/{pageId}/meetingFull.htm", method = RequestMethod.GET)
    public void meetingFull(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            NGWorkspace ngw = registerRequiredProject(ar, siteId, pageId);
            ar.setPageAccessLevels(ngw);

            String id = ar.reqParam("id");
            MeetingRecord meet = ngw.findMeeting(id);
            boolean canAccess = AccessControl.canAccessMeeting(ar, ngw, meet);
            if (!canAccess) {
                showJSPMembers(ar, siteId, pageId, "MeetingFull");
                return;
            }
            if(!ar.isLoggedIn()) {
                specialAnonJSP(ar, siteId, pageId, "MeetingAnon.jsp");
                return;
            }
            if (ar.isMember() || canAccess) {
                streamJSP(ar, "MeetingFull");
                return;
            }
            String roleName = meet.getTargetRole();
            NGRole role = ngw.getRole(roleName);
            if (role!=null) {
                UserProfile user = ar.getUserProfile();
                if (user!=null) {
                    if (!role.isPlayer(user)) {
                        ar.req.setAttribute("roleName", roleName);
                        ar.req.setAttribute("objectName", "Meeting");
                        streamJSP(ar, "WarningNotTargetRole");
                        return;
                    }
                }
            }

            streamJSP(ar, "MeetingFull");
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.project.process.page", new Object[]{pageId,siteId} , ex);
        }
    }


    @RequestMapping(value = "/{siteId}/{pageId}/meetingHtml.htm", method = RequestMethod.GET)
    public void meetingHtml(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            NGWorkspace ngw = registerRequiredProject(ar, siteId, pageId);

            String id = ar.reqParam("id");
            MeetingRecord meet = ngw.findMeeting(id);
            boolean canAccess = AccessControl.canAccessMeeting(ar, ngw, meet);
            if (!canAccess) {
                showJSPMembers(ar, siteId, pageId, "MeetingHtml");
                return;
            }

            streamJSP(ar, "MeetingHtml");
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.project.process.page", new Object[]{pageId,siteId} , ex);
        }
    }

    @RequestMapping(value = "/{siteId}/{pageId}/meetingMinutes.htm", method = RequestMethod.GET)
    public void meetingMinutes(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);         
            String id = ar.reqParam("id");
            if (!meetingCache.canAcccessMeeting(siteId, pageId, ar, id)) {
                showJSPMembers(ar, siteId, pageId, "MeetingMinutes");
                return;
            }
            
            registerRequiredProject(ar, siteId, pageId);

            ar.setParam("id", id);
            ar.setParam("pageId", pageId);
            ar.invokeJSP("/spring/jsp/MeetingMinutes.jsp");
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
            //NOTE: you do NOT need to be logged in to get the calendar file
            //It is important to allow anyone to receive these links in an email
            //and not be logged in, and still be able to get the calendar on 
            //their calendar.  So allow this information to ANYONE who has a link.
            
            NGWorkspace ngw = registerRequiredProject(ar, siteId, pageId);
            MeetingRecord meet = ngw.findMeeting(meetId);
            
            MemFile mf = new MemFile();
            
            meet.streamICSFile(ar, mf.getWriter(), ngw);

            ar.resp.setContentType("text/calendar");
            mf.outToWriter(ar.w);
            ar.flush();

        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.project.process.page", new Object[]{pageId,siteId} , ex);
        }
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




      @RequestMapping(value = "/{siteId}/{pageId}/meetingCreate.json", method = RequestMethod.POST)
      public void meetingCreate(@PathVariable String siteId,@PathVariable String pageId,
              HttpServletRequest request, HttpServletResponse response) {
          AuthRequest ar = AuthRequest.getOrCreate(request, response);
          try{
              NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail( siteId, pageId ).getWorkspace();
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
              HistoryRecord.createHistoryRecord(ngw, newMeeting.getId(),
                      HistoryRecord.CONTEXT_TYPE_MEETING,
                      HistoryRecord.EVENT_TYPE_CREATED, ar, "");
              saveAndReleaseLock(ngw, ar, "Created new Meeting");
              JSONObject repo = newMeeting.getFullJSON(ar, ngw);
              sendJson(ar, repo);
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
              NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail( siteId, pageId ).getWorkspace();
              ar.setPageAccessLevels(ngw);
              ar.assertNotFrozen(ngw);
              String id = ar.reqParam("id");
              MeetingRecord meeting = ngw.findMeeting(id);
              if (!AccessControl.canAccessMeeting(ar, ngw, meeting)) {
                  throw new Exception("Not able to access meeting "+id);
              }
              
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

              JSONObject repo = meetingCache.updateCacheFull(ngw, ar, id);
              saveAndReleaseLock(ngw, ar, "Updated Meeting");
              //this is so that clients can calculate the offset for their particular clock.
              repo.put("serverTime", System.currentTimeMillis());
              sendJson(ar, repo);
          }catch(Exception ex){
              Exception ee = new Exception("Unable to update meeting information.", ex);
              streamException(ee, ar);
          }
      }
      

      @RequestMapping(value = "/{siteId}/{pageId}/proposedTimes.json", method = RequestMethod.POST)
      public void meetingTimes(@PathVariable String siteId,@PathVariable String pageId,
              HttpServletRequest request, HttpServletResponse response) {
          AuthRequest ar = AuthRequest.getOrCreate(request, response);
          try{
              NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail( siteId, pageId ).getWorkspace();
              ar.setPageAccessLevels(ngw);
              String id = ar.reqParam("id");
              ar.assertNotFrozen(ngw);
              MeetingRecord meeting = ngw.findMeeting(id);
              boolean canAccess = AccessControl.canAccessMeeting(ar, ngw, meeting);
              if (!canAccess) {
                  throw new Exception("not a member and no magic number");
              }
              JSONObject timeUpdateInfo = getPostedObject(ar);

              meeting.actOnProposedTime(timeUpdateInfo);

              JSONObject repo = meetingCache.updateCacheFull(ngw, ar, id);
              saveAndReleaseLock(ngw, ar, "Updated Meeting");
              //this is so that clients can calculate the offset for their particular clock.
              repo.put("serverTime", System.currentTimeMillis());
              sendJson(ar, repo);
          }catch(Exception ex){
              Exception ee = new Exception("Unable to update meeting proposed times.", ex);
              streamException(ee, ar);
          }
      }
      

      @RequestMapping(value = "/{siteId}/{pageId}/meetingRead.json", method = RequestMethod.GET)
      public void meetingRead(@PathVariable String siteId,@PathVariable String pageId,
              HttpServletRequest request, HttpServletResponse response) {
          AuthRequest ar = AuthRequest.getOrCreate(request, response);
          try{
              String id = ar.reqParam("id");
              
              JSONObject jo = meetingCache.getOrCacheFull(siteId, pageId, ar, id);
              sendJson(ar, jo);
          }catch(Exception ex){
              Exception ee = new Exception("Unable to access meeting information.", ex);
              streamException(ee, ar);
          }
      }

      
      @RequestMapping(value = "/{siteId}/{pageId}/getMeetingNotes.json", method = RequestMethod.GET)
      public void getMeetingNotes(@PathVariable String siteId,@PathVariable String pageId,
              HttpServletRequest request, HttpServletResponse response) {
          AuthRequest ar = AuthRequest.getOrCreate(request, response);
          try{
              String id = ar.reqParam("id");
              
              JSONObject jo = meetingCache.getOrCacheNotes(siteId, pageId, ar, id);

              sendJson(ar, jo);
          }catch(Exception ex){
              Exception ee = new Exception("Unable to access meeting notes.", ex);
              streamException(ee, ar);
          }
      }
      @RequestMapping(value = "/{siteId}/{pageId}/updateMeetingNotes.json", method = RequestMethod.POST)
      public void updateMeetingNotes(@PathVariable String siteId,@PathVariable String pageId,
              HttpServletRequest request, HttpServletResponse response) {
          AuthRequest ar = AuthRequest.getOrCreate(request, response);
          try{
              String id = ar.reqParam("id");
              JSONObject meetingInfo = getPostedObject(ar);
              if (!meetingInfo.has("minutes") || meetingInfo.getJSONArray("minutes").length()==0) {
                  //this is the case that you are not actually updating anything, so just return 
                  //the cached notes.
                  sendJson(ar, meetingCache.getOrCacheNotes(siteId, pageId, ar, id));
                  return;
              }
              
              NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail( siteId, pageId ).getWorkspace();
              ar.setPageAccessLevels(ngw);
              MeetingRecord meeting = ngw.findMeeting(id);
              boolean canAccess = AccessControl.canAccessMeeting(ar, ngw, meeting);
              if (!canAccess) {
                  throw new Exception("Unable to access meeting "+id);
              }
              meeting.updateMeetingNotes(meetingInfo);
              JSONObject repo = meetingCache.updateCacheNotes(ngw, ar, id);
              saveAndReleaseLock(ngw, ar, "Updated Meeting Notes");
              sendJson(ar, repo);
          }catch(Exception ex){
              Exception ee = new Exception("Unable to read meeting notes.", ex);
              streamException(ee, ar);
          }
      }
      
      

      @RequestMapping(value = "/{siteId}/{pageId}/meetingDelete.json", method = RequestMethod.POST)
      public void meetingDelete(@PathVariable String siteId,@PathVariable String pageId,
              HttpServletRequest request, HttpServletResponse response) {
          AuthRequest ar = AuthRequest.getOrCreate(request, response);
          String meetingId = "";
          try{
              NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail( siteId, pageId ).getWorkspace();
              ar.setPageAccessLevels(ngw);
              ar.assertMember("Must be a member to delete a meeting.");
              ar.assertNotFrozen(ngw);
              JSONObject meetingInfo = getPostedObject(ar);
              meetingId = meetingInfo.getString("id");
              ngw.removeMeeting(meetingId);
              saveAndReleaseLock(ngw, ar, "Deleted new Meeting");
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
              NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail( siteId, pageId ).getWorkspace();
              ar.setPageAccessLevels(ngw);
              ar.assertNotFrozen(ngw);
              String id = ar.reqParam("id");
              MeetingRecord meeting = ngw.findMeeting(id);
              boolean canAccess = AccessControl.canAccessMeeting(ar, ngw, meeting);
              if (!canAccess) {
                  throw new Exception("Unable to update meeting "+id);
              }
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
              JSONObject repo = ai.getJSON(ar, ngw, meeting);
              meetingCache.updateCacheNotes(ngw, ar, id);
              saveAndReleaseLock(ngw, ar, "Created new Agenda Item");
              sendJson(ar, repo);
          }catch(Exception ex){
              Exception ee = new Exception("Unable to create agenda item on meeting", ex);
              streamException(ee, ar);
          }
      }

      @RequestMapping(value = "/{siteId}/{pageId}/agendaDelete.json", method = RequestMethod.POST)
      public void agendaDelete(@PathVariable String siteId,@PathVariable String pageId,
              HttpServletRequest request, HttpServletResponse response) {
          AuthRequest ar = AuthRequest.getOrCreate(request, response);
          try{
              NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail( siteId, pageId ).getWorkspace();
              ar.setPageAccessLevels(ngw);
              ar.assertNotFrozen(ngw);
              String id = ar.reqParam("id");
              MeetingRecord meeting = ngw.findMeeting(id);
              boolean canAccess = AccessControl.canAccessMeeting(ar, ngw, meeting);
              if (!canAccess) {
                  throw new Exception("Unable to update meeting "+id);
              }
              JSONObject agendaInfo = getPostedObject(ar);

              String agendaId = agendaInfo.getString("id");
              meeting.removeAgendaItem(agendaId);
              meeting.renumberItems();
              meetingCache.updateCacheNotes(ngw, ar, id);
              saveAndReleaseLock(ngw, ar, "Deleted Agenda Item");
              ar.write("deleted agenda item "+agendaId);
              ar.flush();
          } catch(Exception ex){
              Exception ee = new Exception("Unable to delete agenda item from meeting.", ex);
              streamException(ee, ar);
          }
      }


      @RequestMapping(value = "/{siteId}/{pageId}/agendaMove.json", method = RequestMethod.POST)
      public void agendaMove(@PathVariable String siteId,@PathVariable String pageId,
              HttpServletRequest request, HttpServletResponse response) {
          AuthRequest ar = AuthRequest.getOrCreate(request, response);
          try{
              NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail( siteId, pageId ).getWorkspace();
              ar.setPageAccessLevels(ngw);
              ar.assertNotFrozen(ngw);
              String src = ar.reqParam("src");
              String dest = ar.reqParam("dest");
              MeetingRecord meeting = ngw.findMeeting(src);
              boolean canAccess = AccessControl.canAccessMeeting(ar, ngw, meeting);
              if (!canAccess) {
                  throw new Exception("Unable to update meeting "+src);
              }
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
              JSONObject repo = ai.getJSON(ar, ngw, meeting);
              meetingCache.updateCacheNotes(ngw, ar, src);
              meetingCache.updateCacheNotes(ngw, ar, dest);
              saveAndReleaseLock(ngw, ar, "Move Agenda Item");
              sendJson(ar, repo);
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
              NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail( siteId, pageId ).getWorkspace();
              ar.setPageAccessLevels(ngw);
              ar.assertNotFrozen(ngw);
              String id = ar.reqParam("id");
              MeetingRecord meeting = ngw.findMeeting(id);
              boolean canAccess = AccessControl.canAccessMeeting(ar, ngw, meeting);
              if (!canAccess) {
                  throw new Exception("Unable to update agenda of meeting "+id);
              }
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

              JSONObject repo = ai.getJSON(ar, ngw, meeting);
              meetingCache.updateCacheNotes(ngw, ar, id);
              saveAndReleaseLock(ngw, ar, "Updated Agenda Item");
              sendJson(ar, repo);
          }catch(Exception ex){
              Exception ee = new Exception("Unable to update agenda item.", ex);
              streamException(ee, ar);
          }
      }


      @RequestMapping(value = "/{siteId}/{pageId}/createMinutes.json", method = RequestMethod.POST)
      public void createMinutes(@PathVariable String siteId,@PathVariable String pageId,
              HttpServletRequest request, HttpServletResponse response) {
          AuthRequest ar = AuthRequest.getOrCreate(request, response);
          try{
              NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail( siteId, pageId ).getWorkspace();
              ar.setPageAccessLevels(ngw);
              ar.assertNotFrozen(ngw);
              String id = ar.reqParam("id");
              MeetingRecord meeting = ngw.findMeeting(id);
              boolean canAccess = AccessControl.canAccessMeeting(ar, ngw, meeting);
              if (!canAccess) {
                  throw new Exception("Unable to create minutes of meeting "+id);
              }

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
              for (AgendaItem ai : meeting.getSortedAgendaItems()) {
                  for (String aid : ai.getDocList()) {
                      AttachmentRecord att = ngw.findAttachmentByID(aid);
                      if (att!=null) {
                          nr.addDocId(aid);
                      }
                  }
              }
              nr.setLastEdited(ar.nowTime);
              JSONObject repo = meeting.getFullJSON(ar, ngw);
              meetingCache.updateCacheNotes(ngw, ar, id);
              saveAndReleaseLock(ngw, ar, "Created Topic for minutes of meeting.");
              sendJson(ar, repo);
          }catch(Exception ex){
              Exception ee = new Exception("Unable to create Topic for minutes of meeting.", ex);
              streamException(ee, ar);
          }
      }





      @RequestMapping(value = "/{siteId}/{pageId}/timeZoneList.json", method = RequestMethod.POST)
      public void timeZoneList(@PathVariable String siteId,@PathVariable String pageId,
              HttpServletRequest request, HttpServletResponse response) {
          AuthRequest ar = AuthRequest.getOrCreate(request, response);
          try{
              JSONObject timeZoneRequest = getPostedObject(ar);
              
              Date sourceDate = new Date(timeZoneRequest.getLong("date"));
              String template = "MMM dd, YYYY  HH:mm";
              if (timeZoneRequest.has("template")) {
                  template = timeZoneRequest.getString("template");
              }
              
              SimpleDateFormat sdf = new SimpleDateFormat(template);
              
              HashSet<String> allZones = new HashSet<String>();
              
              if (timeZoneRequest.has("zones")) {
                  JSONArray zones = timeZoneRequest.getJSONArray("zones");
                  for (int i=0; i<zones.length(); i++) {
                      String oneZone = zones.getString(i);
                      allZones.add(oneZone);
                  }
              }
              if (timeZoneRequest.has("users")) {
                  JSONArray users = timeZoneRequest.getJSONArray("users");
                  for (int i=0; i<users.length(); i++) {
                      String oneUser = users.getString(i);
                      UserProfile up = ar.getCogInstance().getUserManager().lookupUserByAnyId(oneUser);
                      if (up!=null) {
                          String tx = up.getTimeZone();
                          if (tx!=null && tx.length()>0) {
                              allZones.add(tx);
                          }
                      }
                  }
              }
              JSONObject jo = new JSONObject();
              JSONArray dates = new JSONArray();
              for (String aZone : allZones) {
                  TimeZone tz = TimeZone.getTimeZone(aZone);
                  if (tz!=null) {
                      Calendar cal = Calendar.getInstance(tz);
                      sdf.setCalendar(cal);
                      dates.put(sdf.format(sourceDate) + " ("+aZone+")");
                  }
              }
              jo.put("dates", dates);
              jo.put("sourceDate", sourceDate.getTime());


              sendJson(ar, jo);
          }catch(Exception ex){
              Exception ee = new Exception("Unable to calculate time zone list.", ex);
              streamException(ee, ar);
          }
      }


}
