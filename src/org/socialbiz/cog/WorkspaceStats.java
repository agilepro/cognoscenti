package org.socialbiz.cog;

import java.util.List;

import org.socialbiz.cog.util.NameCounter;
import org.workcast.json.JSONObject;

public class WorkspaceStats {

    public int numTopics     = 0;  //notes
    public int numDocs       = 0;
    public int numMeetings   = 0;
    public int numDecisions  = 0;
    public int numComments   = 0;
    public int numProposals  = 0;
    public long sizeDocuments= 0;
    public long sizeArchives = 0;

    public NameCounter topicsPerUser      = new NameCounter();
    public NameCounter docsPerUser        = new NameCounter();
    public NameCounter commentsPerUser    = new NameCounter();
    public NameCounter meetingsPerUser    = new NameCounter();
    public NameCounter proposalsPerUser   = new NameCounter();
    public NameCounter responsesPerUser   = new NameCounter();
    public NameCounter unrespondedPerUser = new NameCounter();

    public void gatherFromWorkspace(NGPage ngp) throws Exception {

        for (NoteRecord topic : ngp.getAllNotes()) {
            numTopics++;
            topicsPerUser.increment(topic.getOwner());
            countComments(topic.getComments());
        }
        for (AttachmentRecord doc : ngp.getAllAttachments()) {
            numDocs++;
            if (!doc.isDeleted()) {
                docsPerUser.increment(doc.getModifiedBy());
            }
            int version = doc.getVersion();
            for (AttachmentVersion ver : doc.getVersions(ngp)) {
                if (ver.getNumber()==version) {
                    sizeDocuments += ver.getFileSize();
                }
                else {
                    sizeArchives += ver.getFileSize();
                }
            }
            countComments(doc.getComments());
        }
        for (MeetingRecord meet : ngp.getMeetings()) {
            numMeetings++;
            String owner = meet.getOwner();
            if (owner!=null && owner.length()>0) {
                meetingsPerUser.increment(owner);
            }
            for (AgendaItem ai : meet.getAgendaItems()) {
                countComments(ai.getComments());
            }
        }
        for (@SuppressWarnings("unused") DecisionRecord dr : ngp.getDecisions()) {
            numDecisions++;
        }
    }

    private void countComments(List<CommentRecord> comments) throws Exception {
        for (CommentRecord comm : comments) {
            if (comm.getCommentType()==CommentRecord.COMMENT_TYPE_SIMPLE) {
                numComments++;
                commentsPerUser.increment(comm.getUser().getUniversalId());
            }
            else {
                numProposals++;
                proposalsPerUser.increment(comm.getUser().getUniversalId());
            }
        }
    }

    public void addAllStats(WorkspaceStats other) {
        numTopics     += other.numTopics;
        numDocs       += other.numDocs;
        numMeetings   += other.numMeetings;
        numDecisions  += other.numDecisions;
        numComments   += other.numComments;
        numProposals  += other.numProposals;
        sizeDocuments += other.sizeDocuments;
        sizeArchives  += other.sizeArchives;

        topicsPerUser.addAllCounts(other.topicsPerUser);
        docsPerUser.addAllCounts(other.docsPerUser);
        commentsPerUser.addAllCounts(other.commentsPerUser);
        meetingsPerUser.addAllCounts(other.meetingsPerUser);
        proposalsPerUser.addAllCounts(other.proposalsPerUser);
        responsesPerUser.addAllCounts(other.responsesPerUser);
        unrespondedPerUser.addAllCounts(other.unrespondedPerUser);
    }

    public JSONObject getJSON() throws Exception {
        JSONObject jo = new JSONObject();
        jo.put("numTopics",     numTopics);
        jo.put("numDocs",       numDocs);
        jo.put("numMeetings",   numMeetings);
        jo.put("numDecisions",  numDecisions);
        jo.put("numComments",   numComments);
        jo.put("numProposals",  numProposals);
        jo.put("sizeDocuments", sizeDocuments);
        jo.put("sizeArchives",  sizeArchives);
        jo.put("topicsPerUser",      topicsPerUser.getJSON());
        jo.put("docsPerUser",        docsPerUser.getJSON());
        jo.put("commentsPerUser",    commentsPerUser.getJSON());
        jo.put("meetingsPerUser",    meetingsPerUser.getJSON());
        jo.put("proposalsPerUser",   proposalsPerUser.getJSON());
        jo.put("responsesPerUser",   responsesPerUser.getJSON());
        jo.put("unrespondedPerUser", unrespondedPerUser.getJSON());
        return jo;
    }

    public static WorkspaceStats fromJSON(JSONObject jo) throws Exception {
        WorkspaceStats res = new WorkspaceStats();
        res.numTopics = jo.getInt("numTopics");
        res.numDocs = jo.getInt("numDocs");
        res.numMeetings = jo.getInt("numMeetings");
        res.numDecisions = jo.getInt("numDecisions");
        res.numComments = jo.getInt("numComments");
        res.numProposals = jo.getInt("numProposals");
        res.sizeDocuments = jo.getLong("sizeDocuments");
        res.sizeArchives = jo.getLong("sizeArchives");
        res.topicsPerUser.fromJSON(jo.getJSONObject("topicsPerUser"));
        res.docsPerUser.fromJSON(jo.getJSONObject("docsPerUser"));
        res.commentsPerUser.fromJSON(jo.getJSONObject("commentsPerUser"));
        res.meetingsPerUser.fromJSON(jo.getJSONObject("meetingsPerUser"));
        res.proposalsPerUser.fromJSON(jo.getJSONObject("proposalsPerUser"));
        res.responsesPerUser.fromJSON(jo.getJSONObject("responsesPerUser"));
        res.unrespondedPerUser.fromJSON(jo.getJSONObject("unrespondedPerUser"));
        return res;
    }

}
