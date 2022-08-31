package com.purplehillsbooks.weaver;

import java.util.List;

import com.purplehillsbooks.weaver.mail.MailInst;

/**
 * What a mess!
 * 
 * This attempts to carry all the information necessary to create
 * a comment email from the various places that a comment
 * email can come from.  These methods are needed for 
 * composing the email message for a comment.
 */
public class EmailContext {
    
    private TopicRecord discussionTopic;
    private MeetingRecord meet;
    private AgendaItem agenda;
    private AttachmentRecord attach;
    
    public EmailContext(TopicRecord _discussionTopic) {
        discussionTopic = _discussionTopic;
    }

    public EmailContext(MeetingRecord _m, AgendaItem _a) {
        meet = _m;
        agenda = _a;
    }

    public EmailContext(AttachmentRecord _att) {
        attach = _att;
    }
    
    public String emailSubject() throws Exception {
        if (discussionTopic!=null) {
            return discussionTopic.getSubject();
        }
        else if (meet!=null) {
            return meet.getName();
        }
        else {
            return attach.emailSubject();
        }
    }
    public String selfDescription() throws Exception {
        if (discussionTopic!=null) {
            return "(Topic) "+discussionTopic.getSubject();
        }
        else if (meet!=null) {
            return meet.selfDescription();
        }
        else  {
            return attach.selfDescription();
        }
    }


    public void appendTargetEmails(List<OptOutAddr> sendTo, NGWorkspace ngw)  throws Exception {
        if (discussionTopic!=null) {
            discussionTopic.appendTargetEmails(sendTo, ngw);
        }
        else if (meet!=null) {
            meet.appendTargetEmails(sendTo, ngw);
        }
        else {
            attach.appendTargetEmails(sendTo, ngw);
        }
    }
    
    public String getEmailURL(AuthRequest ar, NGWorkspace ngw) throws Exception {
        if (discussionTopic!=null) {
            return discussionTopic.getEmailURL(ar, ngw);
        }
        else if (meet!=null) {
            return meet.getEmailURL(ar, ngw);
        }
        else {
            return attach.getEmailURL(ar, ngw);
        }
    }
    
    public String getReplyURL(AuthRequest ar, NGWorkspace ngw, long commentId, MailInst msg) throws Exception {
        if (discussionTopic!=null) {
            return ar.getResourceURL(ngw,  "Reply.htm?topicId="+discussionTopic.getId()+"&commentId="+commentId)+"&" 
                    + AccessControl.getAccessTopicParams(ngw, discussionTopic);
        }
        else if (meet!=null) {
            return ar.getResourceURL(ngw,  "Reply.htm?meetId="+meet.getId()
                    +"&agendaId="+agenda.getId()
                    +"&commentId="+commentId)+"&"
                    + AccessControl.getAccessMeetParams(ngw, meet);
        }
        else {
            return ar.getResourceURL(ngw,  "CommentZoom.htm?cid="+commentId);
        }
    }
    
    public String getUnsubURL(AuthRequest ar, NGWorkspace ngw, long commentId) throws Exception {
        if (discussionTopic!=null) {
            return discussionTopic.getUnsubURL(ar, ngw, commentId);
        }
        else if (meet!=null) {
            return meet.getUnsubURL(ar, ngw, commentId);
        }
        else {
            return attach.getUnsubURL(ar, ngw, commentId);
        }
    }
    
    /*
     * The comment will call this when the email is sent, which is the official
     * time of the change, allowing the note to mark that it has been changed
     * because of the sending of the comment.  Draft comments don't count.
     * Only posted comments at the time of the sending of the email.
     * Meetings don't care about this.
     */
    public void markTimestamp(long newTime) throws Exception {
        if (discussionTopic!=null) {
            discussionTopic.setLastEdited(newTime);
        }
        else if (meet!=null) {
            meet.markTimestamp(newTime);
        }
    }

    /**
     * The comment can have new people to notify, and this informs the container of the these
     * new recipients.
     */
    public void extendNotifyList(List<AddressListEntry> addressList) throws Exception{
        if (discussionTopic!=null) {
            discussionTopic.extendNotifyList(addressList);
        }
        else if (meet!=null) {
            meet.extendNotifyList(addressList);
        }
        else {
            attach.extendNotifyList(addressList);
        }
    }
    
    /**
     * Get all the comments on this comment container
     */
    public List<CommentRecord> getPeerComments()  throws Exception {
        if (discussionTopic!=null) {
            return discussionTopic.getComments();
        }
        else if (meet!=null) {
            return agenda.getComments();
        }
        else {
            return attach.getComments();
        }
    }
    
    public CommentContainer getcontainer() {
        if (discussionTopic!=null) {
            return discussionTopic;
        }
        if (agenda!=null) {
            return agenda;
        }
        if (attach!=null) {
            return attach;
        }
        throw new RuntimeException("Program Logic Error: EmailContext is missing the CommentContainer for some reason.");
    }
    
}
