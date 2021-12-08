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

package com.purplehillsbooks.weaver;

import java.io.File;
import java.net.URLEncoder;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;

import com.purplehillsbooks.weaver.mail.ChunkTemplate;
import com.purplehillsbooks.weaver.mail.MailFile;
import com.purplehillsbooks.weaver.mail.ScheduledNotification;
import org.w3c.dom.Document;
import org.w3c.dom.Element;

import com.purplehillsbooks.json.JSONArray;
import com.purplehillsbooks.json.JSONException;
import com.purplehillsbooks.json.JSONObject;
import com.purplehillsbooks.streams.MemFile;

/**
* A TopicRecord represents a Topic in a Workspace.
* Topic exist on projects as quick ways for people to
* write and exchange information about the project.
* Leaflet is the old term for this, we prefer the term Topic now everywhere.
* (Used to be called LeafletRecord, but name changed March 2013)
*/
public class TopicRecord extends CommentContainer {

    public static final String DISCUSSION_PHASE_DRAFT               = "Draft";
    public static final String DISCUSSION_PHASE_FREEFORM            = "Freeform";
    public static final String DISCUSSION_PHASE_PICTURE_FORMING     = "Forming";
    public static final String DISCUSSION_PHASE_PROPOSAL_SHAPING    = "Shaping";
    public static final String DISCUSSION_PHASE_PROPOSAL_FINALIZING = "Finalizing";
    public static final String DISCUSSION_PHASE_RESOLVED            = "Resolved";
    public static final String DISCUSSION_PHASE_TRASH               = "Trash";
    public static final String DISCUSSION_PHASE_MOVED               = "Moved";

    //This is actually one week before the server started, and is used mainly in the
    //startup methods for an arbitrary time long enough ago that automated notifications
    //should be cancelled or ignored.  If the server stays on a long this value will
    //not be updated -- it remains the time a week before starting the server.
    public static final long ONE_WEEK_AGO = System.currentTimeMillis() - 7L*24*60*60*1000;

    public TopicRecord(Document definingDoc, Element definingElement, DOMFace new_ngs) {
        super(definingDoc, definingElement, new_ngs);

        //assure that visibility is set, default to the visibility to member
        int viz = getVisibility();
        if (viz<1 || viz>4) {
            setVisibility(2);
        }

        //convert to using discussion phase instead of older deleted indicator
        //NGWorkspace schema 101 -> 102 migration
        String currentPhase = getDiscussionPhase();
        if (currentPhase==null || currentPhase.length()==0) {
            //by default everything is freeform, unless deleted or possibly draft
            currentPhase = DISCUSSION_PHASE_FREEFORM;

            String delAttr = getAttribute("deleteUser");
            String saveAsDraft = getAttribute("saveAsDraft");
            if (delAttr!=null && delAttr.length()>0) {
                currentPhase = DISCUSSION_PHASE_TRASH;
            }
            else if(saveAsDraft != null && saveAsDraft.equals("yes")) {
                currentPhase = DISCUSSION_PHASE_DRAFT;
            }
            clearAttribute("saveAsDraft");
            setAttribute("discussionPhase", currentPhase);
        }
    }


    public void copyFrom(AuthRequest ar, NGWorkspace otherWorkspace, TopicRecord other) throws Exception {
        JSONObject full = other.getJSONWithComments(ar, otherWorkspace);
        //fake this to avoid the consistency assurance constraints
        full.put("id", getId());
        full.put("universalid", getUniversalId());
        updateNoteFromJSON(full, ar);
        updateHtmlFromJSON(ar, full);
    }


    //This is a callback from container to set the specific fields
    public void addContainerFields(CommentRecord cr) {
        cr.containerType = CommentRecord.CONTAINER_TYPE_TOPIC;
        cr.containerID = getId();
    }

    public String getId() {
        return getAttribute("id");
    }
    public void setId(String newId) {
        setAttribute("id", newId);
    }


    //TODO: is this properly supported?  Should be an AddressListEntry
    public String getOwner() {
        return getScalar("owner");
    }
    public void setOwner(String newOwner) {
        setScalar("owner", newOwner);
    }

    public String getTargetRole()  throws Exception {
        String target = getAttribute("targetRole");
        if (target==null || target.length()==0) {
            return "Members";
        }
        return target;
    }
    public void setTargetRole(String newVal) throws Exception {
        setAttribute("targetRole", newVal);
    }
    public void appendTargetEmails(List<OptOutAddr> sendTo, NGWorkspace ngw) throws Exception {
        NGRole subsRole = getSubscriberRole();
        List<AddressListEntry> subscribers = subsRole.getDirectPlayers();
        if (subscribers.size()>0) {
            for (AddressListEntry ale : subscribers) {
                if (ale.isWellFormed()) {
                    OptOutAddr ooa = new OptOutTopicSubscriber(ale, ngw.getSiteKey(), ngw.getKey(), this);
                    sendTo.add(ooa);
                }
            }
        }
        else {
            OptOutAddr.appendUnmutedUsersFromRole(ngw, getTargetRole(), sendTo);
        }
    }


    public long getLastEdited()
    {
        return safeConvertLong(getScalar("created"));
    }
    public void setLastEdited(long newCreated)
    {
        setScalar("created", Long.toString(newCreated));
    }

    public AddressListEntry getModUser() {
         String userId = getScalar("modifiedby");
         return new AddressListEntry(userId);
    }
    public void setModUser(UserRef newModifier) {
        setScalar("modifiedby", newModifier.getUniversalId());
    }

    public String getSubject()
    {
        return getScalar("subject");
    }
    public void setSubject(String newSubj)
    {
        setScalar("subject", newSubj);
    }

    public String getWiki()
    {
        return getScalar("data");
    }
    public void setWiki(String newData)
    {
        setScalar("data", newData);
    }


    /**
    * Each topic can be controlled as being public, member, or private,
    * so that it can be moved over the course of lifespan.  When it is
    * private, it can be seen only by the owner.
    *
    * The default setting inherits view from the container.  This is really
    * a migration mode which should be purposefully used.  Data from
    * before this setting will have 0, and thus will be public if in a
    * public comments section, and member only if in a member only section.
    * New comments should be created specifically with a visibility that
    * is non-zero, and when edited the visibility should be set appropriately.
    * Ideally, the concept of a "public comments" section will disappear,
    * there will be one pool of comments with visibility set here.
    *
    * These constants declared in SectionDef
    * SectionDef.PUBLIC_ACCESS = 1;
    * SectionDef.MEMBER_ACCESS = 2;
    * SectionDef.AUTHOR_ACCESS = 3;
    * SectionDef.PRIVATE_ACCESS = 4;
    *
    */
    public int getVisibility() {
        return (int) safeConvertLong(getScalar("visibility"));
    }
    public void setVisibility(int newData) {
        //the "anonymous" case must be converted to public
        if (newData<1) {
            newData=1;
        }
        else if (newData>4) {
            newData=2;
        }
        setScalar("visibility", Integer.toString(newData));
    }
    /**
     * Visibility value of 1 means that this topic is publicly viewable.
     * This convenience method makes the test for this easy.
     * Also, deleted topics are never considered public (for obvious reasons)
     */
    public boolean isPublic() {
        return (getVisibility()==1) && !isDeleted();
    }

    /**
    * given a display level and a user (AuthRequest) tells whether
    * this topic is to be displayed at that level.  Note this is
    * an "exact" match to a level, not a "greater than" match.
    */
    public boolean isVisible(AuthRequest ar, int displayLevel)
        throws Exception
    {
        int visibility = getVisibility();
        if (visibility != displayLevel)
        {
            return false;
        }
        if (visibility != 4)
        {
            return true;
        }
        // must test ownership
        return (ar.getUserProfile().hasAnyId(getOwner()));
    }




    /**
    * This date used to sort the comments.  Set to the date that
    * the comment was first made or published.  That date remains
    * fixed even if the comment continues to be edited.
    *
    * When effective date is not set, use last saved date instead.
    * These will be the same a lot of the time.
    */
    public long getEffectiveDate() {
        long effDate = safeConvertLong(getScalar("effective"));
        if (effDate==0)  {
            return getLastEdited();
        }
        return effDate;
    }
    public void setEffectiveDate(long newEffective) {
        setScalar("effective", Long.toString(newEffective));
    }

    /**
    * If the comment is "pinned" to the top of the page, then
    * this pin order will be set with a positive integer value
    * so that comments are in the order 1, 2, 3, etc.
    * A value of zero (or negative) means that the comment is
    * not pinned to the top, and should instead be sorted by
    * effective date.
    * Default: 0
    */
    public long getPinOrder() {
        long pin = safeConvertLong(getScalar("pin"));
        if (pin < 0) {
            pin = 0;
        }
        return pin;
    }
    public void setPinOrder(long newPinOrder) {
        if (newPinOrder < 0) {
            newPinOrder = 0;
        }
        setScalar("pin", Long.toString(newPinOrder));
    }

    /**
    * Given a vector, this will fill the vector with tag terms
    */
    public void fillTags(List<String> result) {
        fillVectorValues(result, "tag");
    }


    /**
    * Returns a vector of string tag values
    */
    public List<String> getTags() {
        return getVector("tag");
    }
    /**
    * Given a vector of string, this tag terms for this comment
    */
    public void setTags(List<String> newVal) {
        setVector("tag", newVal);
    }

    /**
    * Returns a vector of string choice values
    */
    public String getChoices() {
        return getScalar("choices");
    }

    /**
    * Given a vector of string, this choices for this topic
    */
    public void setChoices(String choices) {
        setScalar("choices", choices);
    }



    /**
    * gets all the response that exist on the topic.
    */
    public List<LeafletResponseRecord> getResponses()
        throws Exception
    {
        //there was a bug ...  that puts response records in for uses BY KEY, but later accesses by
        //global ID (which is the right way).  This code strips out the records that are created with a
        //nine-letter ID, and not an email address ....
        List<LeafletResponseRecord> temp = getChildren("response", LeafletResponseRecord.class);
        List<LeafletResponseRecord> res = new ArrayList<LeafletResponseRecord>();
        for (LeafletResponseRecord llr : temp) {
            String userId = llr.getUser();
            if (userId.length()==9 && userId.indexOf("@")<0 && userId.indexOf("/")<0) {
                //ignore all records that have a user id which is exactly 9 characters long
                //and have no @ sign and no slashes.  Can only be a key!
                continue;
            }
            res.add(llr);
        }
        return res;
    }

    /**
    * returns the response for a particular user, creating one if it does
    * not already exist.
    */
    public LeafletResponseRecord getOrCreateUserResponse(UserProfile up)
                throws Exception {
        List<LeafletResponseRecord> temp = getChildren("response", LeafletResponseRecord.class);
        for (LeafletResponseRecord child : temp) {
            String childUser = child.getUser();
            if (up.hasAnyId(childUser)) {
                //update record with user's current universal ID
                child.setUser(up.getUniversalId());
                return child;
            }
        }
        //did not find it, so we need to create it
        LeafletResponseRecord newChild = createChildWithID(
                "response", LeafletResponseRecord.class, "user", up.getUniversalId());
        return newChild;
    }

    /**
    * This is needed for finding responses from people with email addresses
    * who have been asked to respond to a topic, but who do not have any profile.
    * In this case ID must match exactly.
    */
    public LeafletResponseRecord accessResponse(String userId)
        throws Exception
    {
        List<LeafletResponseRecord> nl = getChildren("response", LeafletResponseRecord.class);
        for (LeafletResponseRecord child : nl) {
            String childUser = child.getUser();
            if (userId.equals(childUser)) {
                return child;
            }
        }
        //did not find it, so we need to create it
        LeafletResponseRecord newChild = createChildWithID(
                "response", LeafletResponseRecord.class, "user", userId);
        return newChild;
    }


    /**
    * output a HTML link to this topic, truncating the name (subject)
    * to maxlength if it is longer than that.
    */
    public void writeLink(AuthRequest ar, int maxLength)
        throws Exception
    {
        ar.write("<a href=\"");
        ar.write(ar.retPath);
        ar.write("\">");
        String name = getSubject();
        if (name.length()>maxLength)
        {
            name = name.substring(0,maxLength);
        }
        ar.writeHtml(name);
        ar.write("</a>");
    }


    public void findTags(List<String> v)
        throws Exception
    {
        String tv = getWiki();
        LineIterator li = new LineIterator(tv);
        while (li.moreLines())
        {
            String thisLine = li.nextLine();
            scanLineForTags(thisLine, v);
        }
    }

    protected void scanLineForTags(String thisLine, List<String> v) {
        int hashPos = thisLine.indexOf('#');
        int startPos = 0;
        int last = thisLine.length();
        while (hashPos >= startPos) {
            hashPos++;
            int endPos = WikiConverter.findIdentifierEnd(thisLine, hashPos);
            if (endPos > hashPos+2) {
                if (endPos >= last) {
                    //this includes everything to the end of the string, and we are done
                    v.add(thisLine.substring(hashPos));
                    return;
                }

                v.add(thisLine.substring(hashPos, endPos));
            }
            else if (endPos >= last) {
                return;
            }
            startPos = endPos;
            hashPos = thisLine.indexOf('#', startPos);
        }
    }



    public static void sortNotesInPinOrder(List<TopicRecord> v) {
        Collections.sort(v, new NotesInPinOrder());
    }

    /**
    * Compares its two arguments for order.
    * First compares their pin order value which the user has placed
    * on them to pin them in a particular position.  The order
    * is 1, 2, 3, ... and then 0 at the end denoting that there is
    * no pin order set.
    * If no pin order is set (or if pin order is equal) then
    * compared by effective date order, which is usually the date
    * that the comment was first created.
    */
    private static class NotesInPinOrder implements Comparator<TopicRecord> {
        NotesInPinOrder() {
        }

        public int compare(TopicRecord o1, TopicRecord o2) {
            long p1 = o1.getPinOrder();
            long p2 = o2.getPinOrder();
            if (p1 != p2) {
                if (p1 == 0) {
                    return 1;
                }
                if (p2 == 0) {
                    return -1;
                }
                if (p2 < p1) {
                    return 1;
                }
                if (p2 > p1) {
                    return -1;
                }
            }

            // pin number is equal, so sort by effective date
            long t1 = o1.getEffectiveDate();
            long t2 = o2.getEffectiveDate();
            if (t2 < t1) {
                return -1;
            }
            if (t2 == t1) {
                return 0;
            }
            return 1;
        }

    }

    /**
     * Discussion Phase is an overall state of the note object.
     * These are the phases:
     * Draft - private, not publicized, one person only
     * Freeform - just a general discussion topic, freeform
     * Picture Forming
     * Proposal Shaping
     * Proposal Finalizing
     * Resolved
     * Closed
     * Trash - this overlaps with deleted.
     */
    public String getDiscussionPhase() {
        return getAttribute("discussionPhase");
    }
    public void setDiscussionPhase(String newPhase, AuthRequest ar) throws Exception {
        String oldPhase = getDiscussionPhase();
        if (newPhase.equals(oldPhase)) {
            return;
        }
        CommentRecord cr = this.addComment(ar);
        cr.setCommentType(CommentRecord.COMMENT_TYPE_PHASE_CHANGE);
        cr.setNewPhase(newPhase);
        setAttribute("discussionPhase", newPhase);
    }

    /**
    * Marking a Topic as deleted means that we SET the phase to trash.
    * A Topic that is deleted / trash remains in the archive until a later
    * date, when garbage has been collected.
    */
    public boolean isDeleted() {
        String currentPhase = getDiscussionPhase();
        return (DISCUSSION_PHASE_TRASH.equals(currentPhase));
    }

    /**
    * Set deleted date to the date that it is effectively deleted,
    * which is the current time in most cases.
    * Set the date to zero in order to clear the deleted flag
    * and make the topic to be not-deleted
    */
    public void setTrashPhase(AuthRequest ar) throws Exception {
        setAttribute("deleteDate", Long.toString(ar.nowTime));
        setAttribute("deleteUser", ar.getBestUserId());
        setDiscussionPhase("Trash", ar);
    }
    public void clearTrashPhase(AuthRequest ar) throws Exception {
        setAttribute("deleteDate", null);
        setAttribute("deleteUser", null);
        setDiscussionPhase("Freeform", ar);
    }
    public long getDeleteDate() {
        return getAttributeLong("deleteDate");
    }
    public String getDeleteUser() {
        return getAttribute("deleteUser");
    }

    public boolean isDraftNote() {
        return (DISCUSSION_PHASE_DRAFT.equals(getDiscussionPhase()));
    }

    /**
     * when a topic is moved to another project, use this to record where
     * it was moved to, so that we can link there.
     */
     public void setMovedTo(String project, String otherId)
         throws Exception
     {
         setScalar("MovedToProject", project);
         setScalar("MovedToId", otherId);
     }


     /**
     * get the project that this topic was moved to.
     */
     public String getMovedToProjectKey()
         throws Exception
     {
         return getScalar("MovedToProject");
     }

     /**
     * get the id of the note (leaflet) in the other project that this note was moved to.
     */
     public String getMovedToNoteId()
         throws Exception
     {
         return getScalar("MovedToId");
     }

     /**
     * the universal id is a globally unique ID for this topic, composed of the id for the
     * server, the project, and the topic.  This is set at the point where the topic is created
     * and remains with the topic as it is carried around the system as long as it is moved
     * as a clone from a project to a clone of a project.   If it is copied or moved to another
     * project for any other reason, then the universal ID should be reset.
     */
     public String getUniversalId() throws Exception {
         return getScalar("universalid");
     }
     public void setUniversalId(String newID) throws Exception {
         setScalar("universalid", newID);
     }


     /**
      * getAccessRoles retuns a list of NGRoles which have access to this document.
      * Admin role and Member role are assumed automatically, and are not in this list.
      * This list contains only the extra roles that have access for non-members.
      */
     public List<NGRole> getAccessRoles(NGContainer ngp) throws Exception {
         List<NGRole> res = new ArrayList<NGRole>();
         List<String> roleNames = getVector("accessRole");
         for (String name : roleNames) {
             NGRole aRole = ngp.getRole(name);
             if (aRole!=null) {
                 if (!res.contains(aRole)) {
                     res.add(aRole);
                 }
             }
         }
         return res;
     }


     /**
      * check if a particular role has access to the particular topic.
      * Just handles the 'special' roles, and does not take into consideration
      * the Members or Admin roles, nor whether the attachment is public.
      */
      public boolean roleCanAccess(String roleName) {
          List<String> roleNames = getVector("labels");
          for (String name : roleNames) {
              if (roleName.equals(name)) {
                  return true;
              }
          }
          return false;
      }

      public boolean isUpstream() {
          String delAttr = getAttribute("upstreamAccess");
          return (delAttr!=null && delAttr.length()>0);
      }
      public void setUpstream(boolean val) {
          if (val) {
              setAttribute("upstreamAccess", "yes");
          }
          else {
              setAttribute("upstreamAccess", null);
          }
      }

      public void writeNoteHtml(AuthRequest ar) throws Exception {
          WikiConverterForWYSIWYG.writeWikiAsHtml(ar, getWiki());
      }

      public String getNoteHtml(AuthRequest ar) throws Exception {
          MemFile htmlChunk = new MemFile();
          AuthDummy dummy = new AuthDummy(ar.getUserProfile(), htmlChunk.getWriter(), ar.getCogInstance());
          dummy.ngp     = ar.ngp;
          dummy.retPath = ar.retPath;
          WikiConverterForWYSIWYG.writeWikiAsHtml(dummy, getWiki());
          dummy.flush();
          return htmlChunk.toString();
      }

      public void setNoteFromHtml(AuthRequest ar, String htmlInput) throws Exception {
          String wikiText = HtmlToWikiConverter.htmlToWiki(ar.baseURL,htmlInput);
          setWiki(wikiText);
      }

      
      
      public void verifyAllAttachments(NGPage ngw) throws Exception {
          List<String> attached = getDocList();
          List<String> newList = new ArrayList<String>();
          List<AttachmentRecord> attaches = ngw.getAllAttachments();
          boolean changed = false;
          for (String attId : attached) {
              boolean found = false;
              for (AttachmentRecord aRec : attaches) {
                  if (aRec.getUniversalId().equals(attId)) {
                      found = true;
                  }
              }
              if (found) {
                  newList.add(attId);
              }
              else {
                  changed = true;
              }
          }
          if (changed) {
              setDocList(newList);
          }
      }
      public List<String> getDocList() {
          return getVector("docList");
      }
      public void addDocId(String goalId) {
          this.addVectorValue("docList", goalId);
      }
      public void setDocList(List<String> newVal) {
          setVector("docList", newVal);
      }

      public List<String> getActionList() {
          return getVector("actionList");
      }
      public void setActionList(List<String> newVal) {
          setVector("actionList", newVal);
      }
      /**
       * Return all the Action Items that were 'live' during the specified
       * time period.  We only know the state that it is now, and timestamp
       * that if was started and ended.   Exclude anything that was closed before the time period
       * began.  Exclude anything that had not yet started by the time period end.
       */
      public List<String> getActionItemsAtTime(NGWorkspace ngw, long startTime, long endTime) throws Exception {
          ArrayList<String> res = new ArrayList<String>();
          for (String possible : getActionList()) {
              GoalRecord gr = ngw.getGoalOrNull(possible);
              if (gr!=null && gr.wasActiveAtTime(startTime, endTime)) {
                  res.add(possible);
              }
          }
          return res;
      }

      /**
       * get the labels on a document -- only labels valid in the project,
       * and no duplicates
       */
      public List<NGLabel> getLabels(NGWorkspace ngp) throws Exception {
          List<NGLabel> res = new ArrayList<NGLabel>();
          for (String name : getVector("labels")) {
              NGLabel aLabel = ngp.getLabelRecordOrNull(name);
              if (aLabel!=null) {
                  if (!res.contains(aLabel)) {
                      res.add(aLabel);
                  }
              }
          }
          return res;
      }

      /**
       * set the list of labels on a document
       */
      public void setLabels(List<NGLabel> values) throws Exception {
          List<String> labelNames = new ArrayList<String>();
          for (NGLabel aLable : values) {
              labelNames.add(aLable.getName());
          }
          //Since this is a 'set' type vector, always sort them so that they are
          //stored in a consistent way ... so files are more easily compared
          Collections.sort(labelNames);
          setVector("labels", labelNames);
      }

      /**
       * Check to see if a label is on the discussion topic,
       * if not, add it
       */
      public void assureLabel(String labelName) throws Exception {
          List<String> labels = getVector("labels");
          for (String name : labels) {
              if (name.equals(labelName)) {
                  //found it, nothing left to do
                  return;
              }
          }
          labels.add(labelName);
          //Since this is a 'set' type vector, always sort them so that they are
          //stored in a consistent way ... so files are more easily compared
          Collections.sort(labels);
          setVector("labels", labels);
      }


      public boolean getEmailSent()  throws Exception {
          if (getAttributeBool("emailSent")) {
              return true;
          }

          //schema migration.  If the email was not sent, and the item was created
          //more than 1 week ago, then go ahead and mark it as sent, because it is
          //too late to send.   This is important whie adding this automatic email
          //sending becaue there are a lot of old records that have never been marked
          //as being sent.   Need to set them as being sent so they are not sent now.
          if (getLastEdited() < ONE_WEEK_AGO) {
              setEmailSent(true);
              return true;
          }

          return false;
      }
      public void setEmailSent(boolean newVal) throws Exception {
          setAttributeBool("emailSent", newVal);
      }

      public List<HistoryRecord> getNoteHistory(NGWorkspace ngc) throws Exception {
          ArrayList<HistoryRecord> histRecs = new ArrayList<HistoryRecord>();
          String nid = this.getId();
          for (HistoryRecord hist : ngc.getAllHistory()) {
              if (hist.getContextType()==HistoryRecord.CONTEXT_TYPE_LEAFLET
                      && nid.equals(hist.getContext())) {
                  histRecs.add(hist);
              }
          }
          return histRecs;
      }

      public List<MeetingRecord> getLinkedMeetings(NGWorkspace ngc) throws Exception {
          ArrayList<MeetingRecord> allMeetings = new ArrayList<MeetingRecord>();
          String nid = this.getId();
          String uid = this.getUniversalId();
          for (MeetingRecord meet : ngc.getMeetings()) {
              boolean found = false;
              for (AgendaItem ai : meet.getAgendaItems()) {
                  List<String> linkedTopics = ai.getLinkedTopics();
                  if (linkedTopics.contains(uid)) {
                      found = true;
                  } else if (linkedTopics.contains(nid)) {
                      //for a while local id was being saved....so look for that as well.
                      found = true;
                  }
              }
              if (found) {
                  allMeetings.add(meet);
              }
          }
          return allMeetings;
      }

      public NGRole getSubscriberRole() throws Exception {
          return requireChild("subscriberRole", CustomRole.class);
      }


      public void topicEmailRecord(AuthRequest ar, NGWorkspace ngw, MailFile mailFile) throws Exception {
          List<OptOutAddr> sendTo = new ArrayList<OptOutAddr>();

          //The user interface will initialize the subscribers to the members of the target role
          //and will allow editing of those subscribers just before sending the first time
          //so email to the subscribers.
          OptOutAddr.appendUsers(getSubscriberRole().getExpandedPlayers(ngw), sendTo);

          UserRef creator = getModUser();
          UserProfile creatorProfile = ar.getCogInstance().getUserManager().lookupUserByAnyId(creator.getUniversalId());
          if (creatorProfile==null) {
              System.out.println("DATA PROBLEM: discussion topic came from a person without a profile ("+getModUser().getUniversalId()+") ignoring");
              setEmailSent(true);
              return;
          }

          for (OptOutAddr ooa : sendTo) {
              constructEmailRecordOneUser(ar, ngw, this, ooa, creatorProfile, mailFile);
          }
          setEmailSent(true);

          //when the email is sent, update the time
          //of the entire note so that it appears at the top of list.
          setLastEdited(ar.nowTime);
      }

      private void constructEmailRecordOneUser(AuthRequest ar, NGWorkspace ngp, TopicRecord note, OptOutAddr ooa,
              UserProfile commenterProfile, MailFile mailFile) throws Exception  {
          Cognoscenti cog = ar.getCogInstance();
          if (!ooa.hasEmailAddress()) {
              return;  //ignore users without email addresses
          }
          MemFile body = new MemFile();
          AuthRequest clone = new AuthDummy(commenterProfile, body.getWriter(), ar.getCogInstance());
          clone.retPath = ar.baseURL;

          JSONObject data = new JSONObject();
          data.put("baseURL", ar.baseURL);
          data.put("topicURL", ar.baseURL + ar.getResourceURL(ngp, this)
                   + "?" + AccessControl.getAccessTopicParams(ngp, this)
                   + "&emailId=" +URLEncoder.encode(ooa.getEmail(), "UTF-8"));
          data.put("topic", this.getJSONWithHtml(ar, ngp));
          data.put("wsURL", ar.baseURL + ar.getDefaultURL(ngp));
          data.put("wsName", ngp.getFullName());
          data.put("optout", ooa.getUnsubscribeJSON(ar));
          EmailContext emailContext = new EmailContext(note);
          String replyUrl = ar.baseURL + emailContext.getReplyURL(ar,ngp, 0)
                  + "&emailId=" + URLEncoder.encode(ooa.getEmail(), "UTF-8");
          data.put("replyURL", replyUrl);

          AttachmentRecord.addEmailStyleAttList(data, ar, ngp, getDocList());

          File emailFolder = cog.getConfig().getFileFromRoot("email");
          File templateFile = new File(emailFolder, "NewTopic.chtml");

          ChunkTemplate.streamIt(clone.w, templateFile, data, commenterProfile.getCalendar());
          clone.flush();

          String emailSubject = "New Topic: "+note.getSubject();
          mailFile.createEmailRecord(commenterProfile.getAddressListEntry(), ooa.getEmail(), emailSubject, body.toString());
      }


/////////////////////////// JSON ///////////////////////////////


      public JSONObject getJSON(NGWorkspace ngp) throws Exception {
          JSONObject thisNote = new JSONObject();
          thisNote.put("id",        getId());
          thisNote.put("subject",   getSubject());
          thisNote.put("modTime",   getLastEdited());
          thisNote.put("modUser",   getModUser().getJSON());
          thisNote.put("universalid", getUniversalId());
          thisNote.put("public",    isPublic());
          thisNote.put("deleted",   isDeleted());
          thisNote.put("draft",     isDraftNote());
          thisNote.put("discussionPhase", getDiscussionPhase());
          thisNote.put("pin",       getPinOrder());
          thisNote.put("docList",   constructJSONArray(getDocList()));
          thisNote.put("actionList", constructJSONArray(getActionList()));
          extractAttributeBool(thisNote, "suppressEmail");

          JSONObject labelMap = new JSONObject();
          for (NGLabel lRec : getLabels(ngp) ) {
              labelMap.put(lRec.getName(), true);
          }
          thisNote.put("labelMap",      labelMap);
          JSONArray subs = new JSONArray();
          NGRole subRole = getSubscriberRole();
          for (AddressListEntry ale : subRole.getDirectPlayers()) {
              subs.put(ale.getJSON());
          }
          thisNote.put("subscribers", subs);
          return thisNote;
     }
     public JSONObject getJSONWithHtml(AuthRequest ar, NGWorkspace ngw) throws Exception {
         JSONObject noteData = getJSON(ngw);
         noteData.put("wiki", getWiki());
         return noteData;
     }
     public JSONObject getJSONWithComments(AuthRequest ar, NGWorkspace ngw) throws Exception {
         JSONObject noteData = getJSONWithHtml(ar, ngw);
         JSONArray comments = getAllComments(ar);
         for (MeetingRecord meet : getLinkedMeetings(ngw)) {
             JSONObject specialMeetingComment = new JSONObject();
             specialMeetingComment.put("emailSent", true);
             specialMeetingComment.put("meet", meet.getListableJSON(ar));
             specialMeetingComment.put("time", meet.getStartTime());
             specialMeetingComment.put("commentType", 4);
             comments.put(specialMeetingComment);
         }
         noteData.put("comments", comments);
         return noteData;
     }

     public JSONObject getJSONWithWiki(NGWorkspace ngp) throws Exception {
         JSONObject noteData = getJSON(ngp);
         noteData.put("wiki", getWiki());
         return noteData;
     }
     
     public JSONObject getJSON4Note(String urlRoot, License license, NGWorkspace ngp) throws Exception {
         JSONObject thisNote = getJSON(ngp);
         String contentUrl = urlRoot + "note" + getId() + "/"
                     + SectionWiki.sanitize(getSubject()) + ".txt?lic="+license.getId();
         thisNote.put("content", contentUrl);
         return thisNote;
     }


     public void updateNoteFromJSON(JSONObject noteObj, AuthRequest ar) throws Exception {
         String universalid = noteObj.getString("universalid");
         if (!universalid.equals(getUniversalId())) {
             //just checking, this should never happen
             throw new JSONException("Error trying to update the record for a note with UID ({0}) with post from topic with UID ({1})",
                     getUniversalId(), universalid);
         }
         if (noteObj.has("subject")) {
             setSubject(noteObj.getString("subject"));
         }
         if (noteObj.has("modifieduser") && noteObj.has("modifiedtime")) {
             setLastEdited(noteObj.getLong("modTime"));
             setModUser(AddressListEntry.fromJSON(noteObj.getJSONObject("modUser")));
         }
         if (noteObj.has("public")) {
             if (noteObj.getBoolean("public")) {
                 //public
                 setVisibility(1);
             }
             else {
                 //only non-public option is member only.  Other visibility
                 //options should not be considered by sync mechanism at all.
                 setVisibility(2);
             }
         }
         if (noteObj.has("deleted")) {
             if (noteObj.getBoolean("deleted")) {
                 //only set if not already set so that the user & date does
                 //not get changed on every update
                 if (!isDeleted()) {
                     setTrashPhase(ar);
                 }
             }
             else {
                  if (isDeleted()) {
                     clearTrashPhase(ar);
                 }
             }
         }
         if (noteObj.has("data")) {
             setWiki(noteObj.getString("data"));
         }

         updateCommentsFromJSON(noteObj, ar);

         if (noteObj.has("docList")) {
             setDocList(constructVector(noteObj.getJSONArray("docList")));
         }
         if (noteObj.has("actionList")) {
             setActionList(constructVector(noteObj.getJSONArray("actionList")));
         }
         if (noteObj.has("labelMap")) {
             JSONObject labelMap = noteObj.getJSONObject("labelMap");
             List<NGLabel> selectedLabels = new ArrayList<NGLabel>();
             for (NGLabel stdLabel : ((NGWorkspace)ar.ngp).getAllLabels()) {
                 String labelName = stdLabel.getName();
                 if (labelMap.optBoolean(labelName)) {
                     selectedLabels.add(stdLabel);
                 }
             }
             setLabels(selectedLabels);
         }
         if (noteObj.has("pin")) {
             setPinOrder(noteObj.getInt("pin"));
         }
         if (noteObj.has("discussionPhase")) {
             setDiscussionPhase(noteObj.getString("discussionPhase"), ar);
         }
         if (noteObj.has("sendEmailNow")) {
             boolean sendEmailNow = noteObj.getBoolean("sendEmailNow");
             setAttributeBool("suppressEmail", !sendEmailNow);
             if (sendEmailNow) {
                 setAttributeBool("emailSent", false);
             }
         }
         else {
             updateAttributeBool("suppressEmail", noteObj);
         }
         if (noteObj.has("wiki")) {
             setWiki(noteObj.getString("wiki"));
         }
         NGRole subRole = getSubscriberRole();
         if (noteObj.has("subscribers")) {
             subRole.clear();
             JSONArray ja = noteObj.getJSONArray("subscribers");
             for (int i=0; i<ja.length(); i++) {
                 JSONObject oneSub = ja.getJSONObject(i);
                 subRole.addPlayerIfNotPresent(AddressListEntry.fromJSON(oneSub));
             }
         }

         //simplistic for now ... if you update anything, you get added to the subscribers
         subRole.addPlayerIfNotPresent(ar.getUserProfile().getAddressListEntry());

     }
     public void updateHtmlFromJSON(AuthRequest ar, JSONObject noteObj) throws Exception {
         if (noteObj.has("html")) {
             setNoteFromHtml(ar, noteObj.getString("html"));
         }
     }
     
     
     public void mergeDoc(String oldMarkDown, String newMarkDown) {
    	 mergeScalar("data", oldMarkDown, newMarkDown);
     }


     /**
      * Needed for the EmailContext interface
      */


     public String getEmailURL(AuthRequest ar, NGWorkspace ngw) throws Exception {
         return ar.getResourceURL(ngw,  "noteZoom"+this.getId()+".htm?")
                 + AccessControl.getAccessTopicParams(ngw, this);
     }

     public String getUnsubURL(AuthRequest ar, NGWorkspace ngw, long commentId) throws Exception {
         return ar.getResourceURL(ngw,  "unsub/"+this.getId()+"/"+commentId+".htm?")
                 + AccessControl.getAccessTopicParams(ngw, this);
     }


     public void extendNotifyList(List<AddressListEntry> addressList) throws Exception {
         getSubscriberRole().addPlayersIfNotPresent(addressList);

     }

     public void gatherUnsentScheduledNotification(NGWorkspace ngw,
             ArrayList<ScheduledNotification> resList, long timeout) throws Exception {
         ScheduledNotification sn = new NScheduledNotification(ngw, this);
         if (sn.needsSendingBefore(timeout)) {
             resList.add(sn);
         }
         else {
             //only look for comments when the email for the note (topic) has been sent
             //avoids problem of comment getting sent before the topic comes out of draft
             for (CommentRecord cr : getComments()) {
                 cr.gatherUnsentScheduledNotification(ngw, new EmailContext(this), resList, timeout);
             }
         }
     }


     private class NScheduledNotification implements ScheduledNotification {
         private NGWorkspace ngw;
         private TopicRecord note;

         public NScheduledNotification( NGWorkspace _ngp, TopicRecord _note) {
             ngw  = _ngp;
             note = _note;
         }
         @Override
         public boolean needsSendingBefore(long timeout) throws Exception {
             if (note.getEmailSent()) {
                 return false;
             }
             if (note.isDraftNote()) {
                 return false;
             }
             if (note.getAttributeBool("suppressEmail")) {
                 return false;
             }
             return true;
         }

         @Override
         public long futureTimeToSend() throws Exception {
             if (note.getEmailSent()) {
                 return -1;
             }
             if (note.isDraftNote()) {
                 return -1;
             }
             if (note.getAttributeBool("suppressEmail")) {
                 return -1;
             }
             return getLastEdited()+1000;
         }

         @Override
         public void sendIt(AuthRequest ar, MailFile mailFile) throws Exception {
             note.topicEmailRecord(ar,ngw, mailFile);
         }

         @Override
         public String selfDescription() throws Exception {
             return "(Note) "+note.getSubject();
         }
     }


}
