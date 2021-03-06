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

import java.util.List;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.socialbiz.cog.AccessControl;
import org.socialbiz.cog.AddressListEntry;
import org.socialbiz.cog.AuthRequest;
import org.socialbiz.cog.HistoryRecord;
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


@Controller
public class TopicController extends BaseController {

    /////////////////////////// MAIN VIEWS //////////////////////////////////////////

    @RequestMapping(value = "/{siteId}/{pageId}/NotesList.htm", method = RequestMethod.GET)
    public void notesList(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        showJSPMembers(ar, siteId, pageId, "NotesList");
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


    /////////////////////////// DATA //////////////////////////////////////////
    
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



    @RequestMapping(value = "/{siteId}/{pageId}/getTopic.json", method = RequestMethod.GET)
    public void getTopic(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        String nid = "";
        try{
            NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail( siteId, pageId ).getWorkspace();
            ar.setPageAccessLevels(ngw);
            nid = ar.reqParam("nid");
            TopicRecord topic = ngw.getNoteOrFail(nid);

            JSONObject repo = topic.getJSONWithComments(ar, ngw);
            sendJson(ar, repo);
        }catch(Exception ex){
            Exception ee = new Exception("Unable to updated topic "+nid+" contents", ex);
            streamException(ee, ar);
        }
    }
    @RequestMapping(value = "/{siteId}/{pageId}/mergeTopicDoc.json", method = RequestMethod.POST)
    public void mergeTopicDoc(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        String nid = "";
        try{
            NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail( siteId, pageId ).getWorkspace();
            ar.setPageAccessLevels(ngw);
            nid = ar.reqParam("nid");
            JSONObject noteInfo = getPostedObject(ar);
            String oldMarkDown = noteInfo.optString("old", "");
            String newMarkDown = noteInfo.getString("new");
            
            TopicRecord topic = ngw.getNoteOrFail(nid);
            topic.mergeDoc(oldMarkDown, newMarkDown);

            JSONObject repo = topic.getJSONWithComments(ar, ngw);
            saveAndReleaseLock(ngw, ar, "Updated Topic Contents");
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

}
