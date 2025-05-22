package com.purplehillsbooks.weaver;

import java.io.File;
import java.util.ArrayList;
import java.util.List;

import com.purplehillsbooks.weaver.util.NameCounter;

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
    public long recentChange = 0;  //will be date for most recently changed workspace
    public int readUserCount = 0;
    public int editUserCount = 0;
    public int numActive     = 0;
    public int numFrozen     = 0;

    public NameCounter topicsPerUser      = new NameCounter();
    public NameCounter docsPerUser        = new NameCounter();
    public NameCounter commentsPerUser    = new NameCounter();
    public NameCounter meetingsPerUser    = new NameCounter();
    public NameCounter proposalsPerUser   = new NameCounter();
    public NameCounter responsesPerUser   = new NameCounter();
    public NameCounter unrespondedPerUser = new NameCounter();
    public NameCounter anythingPerUser    = new NameCounter();
    public NameCounter historyPerType     = new NameCounter();

    public void gatherFromWorkspace(NGWorkspace ngw) throws Exception {

        long changed = ngw.getLastModifyTime();
        if (changed > recentChange) {
            recentChange = changed;
        }
        for (TopicRecord topic : ngw.getAllDiscussionTopics()) {
            numTopics++;
            String uid = topic.getScalar("modifiedby");
            if (uid!=null && uid.length()>0) {
                UserProfile uProf = assureProfile(uid);
                if (uProf != null) {
                    topicsPerUser.increment(uProf.getUniversalId());
                }
            }
            countComments(topic.getComments());
        }
        for (AttachmentRecord doc : ngw.getAllAttachments()) {
            numDocs++;
            if (!doc.isDeleted()) {
                String modifier = doc.getModifiedBy();
                
                // strangely, it appears that doc modified by was added in Aug 2019
                // and so documents before that have it missing and no information
                // about who loaded the file into the workspace.  
                if (modifier!=null && modifier.length()>0) {
                    UserProfile uProf = assureProfile(modifier);
                    String uid = uProf.getUniversalId();
                    docsPerUser.increment(uid);
                }
            }
            int version = doc.getVersion();
            for (AttachmentVersion ver : doc.getVersions(ngw)) {
                if (ver.getNumber()==version) {
                    sizeDocuments += ver.getFileSize();
                }
                else {
                    sizeArchives += ver.getFileSize();
                }
            }
            countComments(doc.getComments());
        }
        for (MeetingRecord meet : ngw.getMeetings()) {
            numMeetings++;
            String owner = meet.getOwner();
            if (owner!=null && owner.length()>0) {
                UserProfile uProf = assureProfile(owner);
                owner = uProf.getUniversalId();
                meetingsPerUser.increment(owner);
            }
            for (AgendaItem ai : meet.getSortedAgendaItems()) {
                countComments(ai.getComments());
            }
        }
        for (@SuppressWarnings("unused") DecisionRecord dr : ngw.getDecisions()) {
            numDecisions++;
        }
        
        //count assignees of all active action items as members
        for (GoalRecord gr : ngw.getAllGoals()) {
            if (GoalRecord.isFinal(gr.getState())) {
                continue;
            }
            for (AddressListEntry ale: gr.getAssigneeRole().getExpandedPlayers(ngw)) {
                anythingPerUser.increment(ale.getUniversalId());
            }
        }

        //count all the users in all roles
        for (WorkspaceRole role : ngw.getWorkspaceRoles()) {
            for (AddressListEntry ale: role.getExpandedPlayers(ngw)) {
                anythingPerUser.increment(ale.getUniversalId());
            }
        }

        //count all the history of the various types
        for (HistoryRecord hist : ngw.getAllHistory()) {
            String histKey = HistoryRecord.getContextTypeName(hist.getContextType()) 
                    + "-" + HistoryRecord.convertEventTypeToString(hist.getEventType());
            historyPerType.increment(histKey);
        }
        
        //now, let's clean out any old temp documents polluting the space left by a broken upload
        File containingFolder = ngw.containingFolder;
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
        
        if (ngw.isFrozen() || ngw.isDeleted()) {
            numFrozen++;
        }
        else {
            numActive++;
        }
    }
    
    
    private UserProfile assureProfile(String uid) throws Exception {
        UserProfile uProf = UserManager.lookupUserByAnyId(uid);
        if (uProf != null) {
            return uProf;
        }
        
        int atPos = uid.indexOf("@");
        if (atPos>=0) {
            System.out.println("SCANNING WORKSPACE: user with no profile, creating one: "+uid);
            uProf = UserManager.getStaticUserManager().createUserWithId(uid);
            UserManager.getStaticUserManager().saveUserProfiles();
        }
        else {
            System.out.println("SCANNING WORKSPACE: user with no profile, but not email!: "+uid);
            return null;
        }
        return uProf;
    }

    
    public List<UserProfile> listAllUserProfiles() throws Exception {
        List<UserProfile> ret = new ArrayList<>();
        for (String uid : anythingPerUser.keySet()) {
            UserProfile uProf = assureProfile(uid);
            if (uProf != null) {
                ret.add(uProf);
            }
        }
        return ret;
    }
    
    
    /**
     * determine readUserCount and editUserCount
     */
    public void countUsers(SiteUsers userMap) throws Exception {
        readUserCount = 0;
        editUserCount = 0;
        for (String uid : anythingPerUser.keySet()) {
            UserProfile uProf = UserManager.lookupUserByAnyId(uid);
            if (uProf == null) {
                readUserCount++;
            }
            else if (userMap.isUnpaid(uProf)) {
                readUserCount++;
            }
            else {
                editUserCount++;
            }
        }
    }

    private void countComments(List<CommentRecord> comments) throws Exception {
        for (CommentRecord comm : comments) {
            String ownerId = comm.getUser().getUniversalId();
            UserProfile uProf = assureProfile(ownerId);
            if (uProf==null) {
                continue;
            }
            ownerId = uProf.getUniversalId();
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

    public void addAllStats(NGWorkspace ngw, WorkspaceStats other) throws Exception {

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
        if (other.recentChange > recentChange) {
            recentChange = other.recentChange;
        }
        

        topicsPerUser.addAllCounts(other.topicsPerUser);
        docsPerUser.addAllCounts(other.docsPerUser);
        commentsPerUser.addAllCounts(other.commentsPerUser);
        meetingsPerUser.addAllCounts(other.meetingsPerUser);
        proposalsPerUser.addAllCounts(other.proposalsPerUser);
        responsesPerUser.addAllCounts(other.responsesPerUser);
        unrespondedPerUser.addAllCounts(other.unrespondedPerUser);
        anythingPerUser.addAllCounts(other.anythingPerUser);
        historyPerType.addAllCounts(other.historyPerType);
    }
/* 
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
        jo.put("recentChange",  recentChange);
        jo.put("editUserCount",  editUserCount);
        jo.put("readUserCount",  readUserCount);
        jo.put("numActive",      numActive);
        jo.put("numFrozen",      numFrozen);
        
        jo.put("numUsers",       anythingPerUser.size());
        jo.put("topicsPerUser",      topicsPerUser.getJSON());
        jo.put("docsPerUser",        docsPerUser.getJSON());
        jo.put("commentsPerUser",    commentsPerUser.getJSON());
        jo.put("meetingsPerUser",    meetingsPerUser.getJSON());
        jo.put("proposalsPerUser",   proposalsPerUser.getJSON());
        jo.put("responsesPerUser",   responsesPerUser.getJSON());
        jo.put("unrespondedPerUser", unrespondedPerUser.getJSON());
        jo.put("anythingPerUser",    anythingPerUser.getJSON());
        jo.put("historyPerType",     historyPerType.getJSON());
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
        res.numWorkspaces = jo.optInt("numWorkspaces", 0);
        res.recentChange = jo.getLong("recentChange");
        res.editUserCount = jo.getInt("editUserCount");
        res.readUserCount = jo.getInt("readUserCount");
        res.numActive = jo.getInt("numActive");
        res.numFrozen = jo.getInt("numFrozen");

        res.topicsPerUser.fromJSON(jo, "topicsPerUser");
        res.docsPerUser.fromJSON(jo ,"docsPerUser");
        res.commentsPerUser.fromJSON(jo, "commentsPerUser");
        res.meetingsPerUser.fromJSON(jo, "meetingsPerUser");
        res.proposalsPerUser.fromJSON(jo, "proposalsPerUser");
        res.responsesPerUser.fromJSON(jo, "responsesPerUser");
        res.unrespondedPerUser.fromJSON(jo, "unrespondedPerUser");
        res.anythingPerUser.fromJSON(jo, "anythingPerUser");
        res.historyPerType.fromJSON(jo, "historyPerType");
        return res;
    }
*/
}
