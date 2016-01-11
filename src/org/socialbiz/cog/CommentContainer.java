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

package org.socialbiz.cog;

import java.util.List;

import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.workcast.json.JSONArray;
import org.workcast.json.JSONObject;

/**
* A NoteRecord represents a Topic in a Workspace.
* Topic exist on projects as quick ways for people to
* write and exchange information about the project.
* Leaflet is the old term for this, we prefer the term Topic now everywhere.
* (Used to be called LeafletRecord, but name changed March 2013)
*/
public class CommentContainer extends DOMFace {


    public CommentContainer(Document definingDoc, Element definingElement, DOMFace new_ngs) {
        super(definingDoc, definingElement, new_ngs);
    }


    public List<CommentRecord> getComments()  throws Exception {
        return getChildren("comment", CommentRecord.class);
    }
    public CommentRecord findComment(long timestamp)  throws Exception {
        for (CommentRecord cr : getComments()) {
            if (cr.getTime() == timestamp) {
                return cr;
            }
        }
        return null;
    }
    public CommentRecord addComment(AuthRequest ar)  throws Exception {
        CommentRecord newCR = createChild("comment", CommentRecord.class);
        newCR.setTime(ar.nowTime);
        newCR.setUser(ar.getUserProfile());
        return newCR;
    }
    public void deleteComment(long timeStamp)  throws Exception {
        CommentRecord selectedForDelete = findComment(timeStamp);
        if (selectedForDelete!=null) {
            this.removeChild(selectedForDelete);
        }
    }



/////////////////////////// JSON ///////////////////////////////


    public void addJSONComments(AuthRequest ar, JSONObject thisContainer) throws Exception {
        JSONArray allCommentss = new JSONArray();
        UserProfile thisUser = ar.getUserProfile();
        for (CommentRecord cr : getComments()) {
            if (cr.getState()==CommentRecord.COMMENT_STATE_DRAFT
                    && (thisUser==null
                    || !thisUser.hasAnyId(cr.getUser().getEmail()))) {
                //skip draft email from other people
                continue;
            }
            allCommentss.put(cr.getHtmlJSON(ar));
        }
        thisContainer.put("comments",  allCommentss);
    }

    public void addJSONComments(AuthRequest ar, JSONObject thisContainer, long startTime, long endTime) throws Exception {
        JSONArray allCommentss = new JSONArray();
        UserProfile thisUser = ar.getUserProfile();
        for (CommentRecord cr : getComments()) {
            if (cr.getState()==CommentRecord.COMMENT_STATE_DRAFT
                    && (thisUser==null
                    || !thisUser.hasAnyId(cr.getUser().getEmail()))) {
                //skip draft email from other people
                continue;
            }
            if (cr.getTime()<startTime || cr.getTime()>endTime) {
                //ignore comment created before or after the period
                continue;
            }
            allCommentss.put(cr.getHtmlJSON(ar));
        }
        thisContainer.put("comments",  allCommentss);
    }

    public void updateCommentsFromJSON(JSONObject noteObj, AuthRequest ar) throws Exception {

        //if there is a comments, then IF the creator of the comment is the currently
        //logged in user, and the timestamps match, then update the html part
        //a timeStamp -1 means it is new.
        if (noteObj.has("comments")) {
            updateAllComments(noteObj.getJSONArray("comments"), ar);
        }
    }

    private void updateAllComments(JSONArray allComments, AuthRequest ar) throws Exception  {
        for (int i=0; i<allComments.length(); i++) {
            JSONObject oneComment = allComments.getJSONObject(i);
            long timeStamp = oneComment.getLong("time");
            if (timeStamp <= 0) {
                CommentRecord newComment = addComment(ar);
                newComment.updateFromJSON(oneComment, ar);
                linkReplyToSource(newComment);
            }
            else {
                CommentRecord cr = findComment(timeStamp);
                if (cr!=null) {
                    if (oneComment.has("deleteMe")) {
                        //a special flag in the comment indicates it should be removed
                        //setting to draft will UNLINK this comment from the other
                        cr.setState(CommentRecord.COMMENT_STATE_DRAFT);
                        linkReplyToSource(cr);
                        deleteComment(timeStamp);
                    }
                    else {
                        cr.updateFromJSON(oneComment, ar);
                        linkReplyToSource(cr);
                    }
                }
            }
        }
    }
    private void linkReplyToSource(CommentRecord cr) throws Exception {
        long replyto = cr.getReplyTo();
        if (replyto<=0) {
            //not a reply, nothing to link to
            return;
        }
        CommentRecord source = findComment(replyto);
        if (source!=null) {
            if (cr.getState()==CommentRecord.COMMENT_STATE_DRAFT) {
                //don't link up draft replies.
                source.removeFromReplies(cr.getTime());
            }
            else {
                source.addOneToReplies(cr.getTime());
            }
        }
        else {
            //did not find the other, but otherwise silently ignore the problem
            System.out.println("New comment reply to time value, cannot find corresponding comment: "+replyto);
        }
    }

}
