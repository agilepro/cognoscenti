package org.socialbiz.cog;

import java.io.File;
import java.util.List;

import org.socialbiz.cog.util.NameCounter;

import com.purplehillsbooks.json.JSONObject;

public class WorkspaceStats {

    public int numTopics     = 0;  //notes
    public int numDocs       = 0;
    public int numMeetings   = 0;
    public int numDecisions  = 0;
    public int numComments   = 0;
    public int numProposals  = 0;
    public long sizeDocuments= 0;
    public long sizeArchives = 0;
    public int numWorkspaces = 0;  //only for a site will this be anything other than 1

    public NameCounter topicsPerUser      = new NameCounter();
    public NameCounter docsPerUser        = new NameCounter();
    public NameCounter commentsPerUser    = new NameCounter();
    public NameCounter meetingsPerUser    = new NameCounter();
    public NameCounter proposalsPerUser   = new NameCounter();
    public NameCounter responsesPerUser   = new NameCounter();
    public NameCounter unrespondedPerUser = new NameCounter();
    public NameCounter anythingPerUser    = new NameCounter();

    public void gatherFromWorkspace(NGWorkspace ngp) throws Exception {

        for (TopicRecord topic : ngp.getAllDiscussionTopics()) {
            numTopics++;
            AddressListEntry modUser = topic.getModUser();
            String uid = modUser.getUniversalId();
            topicsPerUser.increment(uid);
            countComments(topic.getComments());
        }
        for (AttachmentRecord doc : ngp.getAllAttachments()) {
            numDocs++;
            if (!doc.isDeleted()) {
                AddressListEntry modUser = new AddressListEntry(doc.getModifiedBy());
                String uid = modUser.getUniversalId();
                docsPerUser.increment(uid);
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
            AddressListEntry modUser = new AddressListEntry(meet.getOwner());
            String owner = modUser.getUniversalId();
            if (owner!=null && owner.length()>0) {
                meetingsPerUser.increment(owner);
            }
            for (AgendaItem ai : meet.getSortedAgendaItems()) {
                countComments(ai.getComments());
            }
        }
        for (@SuppressWarnings("unused") DecisionRecord dr : ngp.getDecisions()) {
            numDecisions++;
        }
        
        //count assignees of all active action items as members
        for (GoalRecord gr : ngp.getAllGoals()) {
            if (GoalRecord.isFinal(gr.getState())) {
                continue;
            }
            for (AddressListEntry ale: gr.getAssigneeRole().getExpandedPlayers(ngp)) {
                anythingPerUser.increment(ale.getUniversalId());
            }
        }

        //count all the users in all roles
        for (CustomRole role : ngp.getAllRoles()) {
            for (AddressListEntry ale: role.getExpandedPlayers(ngp)) {
                anythingPerUser.increment(ale.getUniversalId());
            }
        }
        
        //now, let's clean out any old temp documents polluting the space left by a broken upload
        File containingFolder = ngp.containingFolder;
        long beforeYesterday = System.currentTimeMillis() - 24L*60*60*1000;
        for (File child : containingFolder.listFiles()) {
            if (child.getName().startsWith("~tmp~")) {
                if (child.lastModified() < beforeYesterday) {
                    //here is a file that begins with ~tmp~ that was created more than 24 hours ago
                    //so clearly it is abandoned.   A tmp file should never site for more than a few
                    //minutes, and anything 24 hours old is junk
                    child.delete();
                }
            }
        }
    }

    private void countComments(List<CommentRecord> comments) throws Exception {
        for (CommentRecord comm : comments) {
            String ownerId = comm.getUser().getUniversalId();
            if (comm.getCommentType()==CommentRecord.COMMENT_TYPE_SIMPLE) {
                numComments++;
                commentsPerUser.increment(ownerId);
            }
            else {
                numProposals++;
                proposalsPerUser.increment(ownerId);
            }
        }
    }

    public void addAllStats(WorkspaceStats other) {

        //this is incremented to count the number of smaller collections that have
        //been aggregated into this statistics collection.  This is useful mainly
        //for sites which collect all the values from their workspaces.
        numWorkspaces++;

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
        anythingPerUser.addAllCounts(other.anythingPerUser);
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
        jo.put("numWorkspaces",  numWorkspaces);
        jo.put("numUsers",       anythingPerUser.size());
        jo.put("topicsPerUser",      topicsPerUser.getJSON());
        jo.put("docsPerUser",        docsPerUser.getJSON());
        jo.put("commentsPerUser",    commentsPerUser.getJSON());
        jo.put("meetingsPerUser",    meetingsPerUser.getJSON());
        jo.put("proposalsPerUser",   proposalsPerUser.getJSON());
        jo.put("responsesPerUser",   responsesPerUser.getJSON());
        jo.put("unrespondedPerUser", unrespondedPerUser.getJSON());
        jo.put("anythingPerUser",    anythingPerUser.getJSON());
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
        if (jo.has("numWorkspaces")) {
            res.numWorkspaces = jo.getInt("numWorkspaces");
        }
        res.topicsPerUser.fromJSON(jo.getJSONObject("topicsPerUser"));
        res.docsPerUser.fromJSON(jo.getJSONObject("docsPerUser"));
        res.commentsPerUser.fromJSON(jo.getJSONObject("commentsPerUser"));
        res.meetingsPerUser.fromJSON(jo.getJSONObject("meetingsPerUser"));
        res.proposalsPerUser.fromJSON(jo.getJSONObject("proposalsPerUser"));
        res.responsesPerUser.fromJSON(jo.getJSONObject("responsesPerUser"));
        res.unrespondedPerUser.fromJSON(jo.getJSONObject("unrespondedPerUser"));
        if (jo.has("anythingPerUser")) {
            //schema migration
            res.anythingPerUser.fromJSON(jo.getJSONObject("anythingPerUser"));
        }
        return res;
    }

}
