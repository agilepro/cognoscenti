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

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.socialbiz.cog.AgendaItem;
import org.socialbiz.cog.AttachmentRecord;
import org.socialbiz.cog.AuthRequest;
import org.socialbiz.cog.CommentRecord;
import org.socialbiz.cog.DOMFace;
import org.socialbiz.cog.MeetingRecord;
import org.socialbiz.cog.NGWorkspace;
import org.socialbiz.cog.TopicRecord;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;

import com.purplehillsbooks.json.JSONObject;


@Controller
public class CommentController extends BaseController {



    @RequestMapping(value = "/{siteId}/{pageId}/info/{command}")
    public void fetchInfo(@PathVariable String siteId,@PathVariable String pageId,
            @PathVariable String command,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try{
            ar.assertLoggedIn("Must be logged in to access workspace information.");
            NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail( siteId, pageId ).getWorkspace();
            ar.setPageAccessLevels(ngw);
            ar.assertMember("Must be a member to access workspace information.");
            boolean isPost = request.getMethod().equalsIgnoreCase("POST");
            JSONObject postObject = null;
            if (isPost) {
                postObject = this.getPostedObject(ar);
            }
            JSONObject repo = null;
            if ("comment".equals(command)) {
                repo = handleComment(ar, ngw, postObject);
            }
            else {
                throw new Exception("Unrecognized command: "+command);
            }
            sendJson(ar, repo);
        }catch(Exception ex){
            Exception ee = new Exception("Unable to fetch "+command+ " info from workspace "+siteId+"/"+pageId, ex);
            streamException(ee, ar);
        }
    }

    private JSONObject handleComment(AuthRequest ar, NGWorkspace ngw, JSONObject postObject) throws Exception {
        long cid = DOMFace.safeConvertLong(ar.reqParam("cid"));
        CommentRecord cr = null;
        if (cid>0) {
            cr = ngw.getCommentOrFail(cid);
        }
        else {
            cr = createNewComment(ar, ngw, postObject);
        }
        if (postObject != null) {
            cr.updateFromJSON(postObject, ar);
            
            //now we have to tell the meeting controlled to update cache if meeting comment
            if (cr.containerType == CommentRecord.CONTAINER_TYPE_MEETING) {
                int pos = cr.containerID.indexOf(":");
                String meetingId = cr.containerID.substring(0,pos);
                MeetingControler.meetingCache.updateCacheFull(ngw, ar, meetingId);
            }
        }
        return cr.getHtmlJSON(ar);
    }

    private CommentRecord createNewComment(AuthRequest ar, NGWorkspace ngw, JSONObject postObject) throws Exception {
        
        if (postObject == null) { 
            throw new Exception("Creating a comment requires a POST of JSON parameters");
        }
        
        String containerType = postObject.getString("containerType");
        String containerID   = postObject.getString("containerID");
        CommentRecord cr = null;
        if ("M".equals(containerType)) {
            int pos = containerID.indexOf(":");
            if (pos<0) {
                throw new Exception("Meeting ID must contain a colon.  Got: "+containerID);
            }
            String meetID = containerID.substring(0, pos);
            String agendaID = containerID.substring(pos+1);
            MeetingRecord mr = ngw.findMeeting(meetID);
            AgendaItem ai = mr.findAgendaItem(agendaID);
            cr = ai.addComment(ar);
            
        }
        else if ("T".equals(containerType)) {
            TopicRecord tr = ngw.getNote(containerID);
            cr = tr.addComment(ar);
        }
        else if ("A".equals(containerType)) {
            AttachmentRecord att = ngw.findAttachmentByIDOrFail(containerID);
            cr = att.addComment(ar);
        }
        else {
            throw new Exception("CreateComment is unable to understand the containerType: "+containerType);
        }
        return cr;
    }

}

