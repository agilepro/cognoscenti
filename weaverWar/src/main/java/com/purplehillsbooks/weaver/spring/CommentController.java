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

import com.purplehillsbooks.weaver.AgendaItem;
import com.purplehillsbooks.weaver.AttachmentRecord;
import com.purplehillsbooks.weaver.AuthRequest;
import com.purplehillsbooks.weaver.CommentRecord;
import com.purplehillsbooks.weaver.DOMFace;
import com.purplehillsbooks.weaver.MeetingRecord;
import com.purplehillsbooks.weaver.NGWorkspace;
import com.purplehillsbooks.weaver.TopicRecord;
import com.purplehillsbooks.weaver.exception.WeaverException;
import com.purplehillsbooks.weaver.mail.EmailSender;
import com.purplehillsbooks.weaver.mail.MailInst;
import com.purplehillsbooks.xml.Mel;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;

import com.purplehillsbooks.json.JSONArray;
import com.purplehillsbooks.json.JSONObject;


@Controller
public class CommentController extends BaseController {

    @RequestMapping(value = "/{siteId}/{pageId}/CommentList.htm", method = RequestMethod.GET)
    public void commentList(@PathVariable String siteId, @PathVariable String pageId,
            HttpServletRequest request,   HttpServletResponse response)  throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        showJSPMembers(ar, siteId, pageId, "CommentList.jsp");
    }
    @RequestMapping(value = "/{siteId}/{pageId}/CommentZoom.htm", method = RequestMethod.GET)
    public void commentZoom(@PathVariable String siteId, @PathVariable String pageId,
            HttpServletRequest request,   HttpServletResponse response)  throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        NGWorkspace ngw = registerWorkspaceRequired(ar, siteId, pageId);
        long cid = Mel.safeConvertLong(ar.reqParam("cid"));
        CommentRecord selectedComment = ngw.getCommentOrNull(cid);
        if (selectedComment==null) {
            showDisplayWarningF(ar, 
                "Can not find comment, proposal, or question with the id (%d).  Was it deleted?",
                cid);
            return;
        }
        showJSPMembers(ar, siteId, pageId, "CommentZoom.jsp");
    }

    @RequestMapping(value = "/{siteId}/{pageId}/getComment.json", method = RequestMethod.GET)
    public void getTopic(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        long cid = 0;
        try{
            NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail( siteId, pageId ).getWorkspace();
            ar.setPageAccessLevels(ngw);
            ar.assertAccessWorkspace("must be a member to get comment");
            
            cid = Mel.safeConvertLong(ar.reqParam("cid"));
            CommentRecord topic = ngw.getCommentOrFail(cid);


            JSONObject repo = topic.getCompleteJSON();
            sendJson(ar, repo);
        }
        catch(Exception ex){
            Exception ee = new Exception("Unable to get comment ("+cid+") contents", ex);
            streamException(ee, ar);
        }
    }
    @RequestMapping(value = "/{siteId}/{pageId}/getCommentList.json", method = RequestMethod.GET)
    public void getCommentList(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try{
            NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail( siteId, pageId ).getWorkspace();
            ar.setPageAccessLevels(ngw);
            ar.assertAccessWorkspace("must havea access to workspace to get comment list");
            
            JSONArray allComments = new JSONArray();
            for (CommentRecord cmt : ngw.getAllComments()) {
                allComments.put(cmt.getJSONWithDocs(ngw));
            }

            JSONObject jo = new JSONObject();
            jo.put("list",  allComments);
            sendJson(ar, jo);
        }
        catch(Exception ex){
            Exception ee = new Exception("Unable to get list of all comments", ex);
            streamException(ee, ar);
        }
    }
    @RequestMapping(value = "/{siteId}/{pageId}/updateComment.json", method = RequestMethod.POST)
    public void updateComment(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        long cid = 0;
        try{
            NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail( siteId, pageId ).getWorkspace();
            ar.setPageAccessLevels(ngw);
            ar.assertAccessWorkspace("must be a member to update comment");
            JSONObject postObject = this.getPostedObject(ar);
            cid = Mel.safeConvertLong(ar.reqParam("cid"));
            JSONObject repo = null;
            String meetingId = ngw.findMeetingIdForComment(cid);
            if (postObject.has("deleteMe")) {
                ngw.deleteComment(cid);
                repo = new JSONObject().put("delete", "success");
            }
            else {
                CommentRecord cmt = ngw.getCommentOrFail(cid);
                cmt.updateFromJSON(postObject, ar);
    
                repo = cmt.getJSONWithDocs(ngw);
            }
            
            //re-link (or unlink) replies links to all comments
            ngw.correctAllRepliesLinks();
            
            //if the comment was on a meeting, then refresh the meeting cache
            if (meetingId!=null) {
                MeetingControler.meetingCache.updateCacheFull(ngw, ar, meetingId);
            }
            saveAndReleaseLock(ngw, ar, "updated a comment");
            sendJson(ar, repo);
        }
        catch(Exception ex){
            Exception ee = new Exception("Unable to update comment ("+cid+") contents", ex);
            streamException(ee, ar);
        }
    }
    @RequestMapping(value = "/{siteId}/{pageId}/updateCommentAnon.json", method = RequestMethod.POST)
    public void updateCommentAnon(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        long cid = 0;
        try{
            NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail( siteId, pageId ).getWorkspace();
            ar.setPageAccessLevels(ngw);
            JSONObject postObject = this.getPostedObject(ar);
            
            cid = Mel.safeConvertLong(ar.reqParam("cid"));
            
            //in order to allow an anonymous update of a comment, there must be a valid email
            //message id, and the email in question must be about the comment being upated
            long msgId = Mel.safeConvertLong(ar.reqParam("msg"));
            MailInst mail = EmailSender.findEmailById(msgId);
            if (mail == null) {
                throw WeaverException.newBasic("Can't find an email message for %s", msgId);
            }
            if (cid != mail.getCommentId()) {
                throw WeaverException.newBasic("Comment and email message id do not match");
            }
                    
            JSONObject repo = null;
            String meetingId = ngw.findMeetingIdForComment(cid);
            if (postObject.has("deleteMe")) {
                throw WeaverException.newBasic("delete is not allowed anonymously");
            }
            else {
                CommentRecord cmt = ngw.getCommentOrFail(cid);
                cmt.updateFromJSON(postObject, ar);
    
                repo = cmt.getJSONWithDocs(ngw);
            }
            
            //re-link (or unlink) replies links to all comments
            ngw.correctAllRepliesLinks();
            
            //if the comment was on a meeting, then refresh the meeting cache
            if (meetingId!=null) {
                MeetingControler.meetingCache.updateCacheFull(ngw, ar, meetingId);
            }
            saveAndReleaseLock(ngw, ar, "updated a comment");
            sendJson(ar, repo);
        }
        catch(Exception ex){
            Exception ee = new Exception("Unable to update comment ("+cid+") contents", ex);
            streamException(ee, ar);
        }
    }

    private void countComments(NGWorkspace ngw) throws Exception {
        int count = 0;
        StringBuilder sb = new StringBuilder();
        for (MeetingRecord meet : ngw.getMeetings()) {
            for (AgendaItem ai : meet.getAgendaItems()) {
                for (CommentRecord cr : ai.getComments()) {
                    count++;
                    sb.append(",");
                    sb.append(Long.toString(cr.getTime()%1000));
                }
            }
        }
        System.out.println("*** CommentController: Number of comments: "+count+sb.toString());
    }

    @RequestMapping(value = "/{siteId}/{pageId}/info/{command}")
    public void fetchInfo(@PathVariable String siteId,@PathVariable String pageId,
            @PathVariable String command,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try{
            ar.assertLoggedIn("Must be logged in to access workspace information.");
            NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail( siteId, pageId ).getWorkspace();
            countComments(ngw);
            ar.setPageAccessLevels(ngw);
            ar.assertAccessWorkspace("Must be a member to access workspace information.");
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
                throw WeaverException.newBasic("Unrecognized command: %s", command);
            }
            sendJson(ar, repo);
        }
        catch(Exception ex){
            Exception ee = new Exception("Unable to fetch "+command+ " info from workspace "+siteId+"/"+pageId, ex);
            streamException(ee, ar);
        }
    }

    private JSONObject handleComment(AuthRequest ar, NGWorkspace ngw, JSONObject postObject) throws Exception {
        long cid = DOMFace.safeConvertLong(ar.reqParam("cid"));
        System.out.println("Comment Controller: handling comment: "+cid);
        CommentRecord cr = null;
        if (cid>0) {
            cr = ngw.getCommentOrFail(cid);
        }
        else {
            cr = createNewComment(ar, ngw, postObject);
        }
        if (postObject != null) {
            cr.updateFromJSON(postObject, ar);
            
            ngw.saveModifiedWorkspace(ar, "updated comment "+cid);
            //now we have to tell the meeting controlled to update cache if meeting comment
            if (cr.containerType == CommentRecord.CONTAINER_TYPE_MEETING) {
                int pos = cr.containerID.indexOf(":");
                String meetingId = cr.containerID.substring(0,pos);
                MeetingControler.meetingCache.updateCacheFull(ngw, ar, meetingId);
            }
            System.out.println("Comment Controller: workspace is saved for: "+cid);
        }
        return cr.getJSONWithDocs(ngw);
    }

    private CommentRecord createNewComment(AuthRequest ar, NGWorkspace ngw, JSONObject postObject) throws Exception {
        
        if (postObject == null) { 
            throw WeaverException.newBasic("Creating a comment requires a POST of JSON parameters");
        }
        
        char containerType = postObject.getString("containerType").charAt(0);
        String containerID   = postObject.getString("containerID");
        CommentRecord cr = null;
        if ('M' == containerType) {
            int pos = containerID.indexOf(":");
            if (pos<0) {
                throw WeaverException.newBasic("Meeting ID must contain a colon.  Got: %s", containerID);
            }
            String meetID = containerID.substring(0, pos);
            String agendaID = containerID.substring(pos+1);
            MeetingRecord mr = ngw.findMeeting(meetID);
            AgendaItem ai = mr.findAgendaItem(agendaID);
            cr = ai.addComment(ar);
            
        }
        else if ('T' == containerType) {
            TopicRecord tr = ngw.getDiscussionTopic(containerID);
            cr = tr.addComment(ar);
        }
        else if ('A' == containerType) {
            AttachmentRecord att = ngw.findAttachmentByIDOrFail(containerID);
            cr = att.addComment(ar);
        }
        else {
            throw WeaverException.newBasic(
                "CreateComment is unable to understand the containerType: %s", 
                containerType);
        }
        return cr;
    }
    

}

