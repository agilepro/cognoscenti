package org.socialbiz.cog.spring;

import java.util.Hashtable;
import java.util.List;

import org.socialbiz.cog.AddressListEntry;
import org.socialbiz.cog.AuthRequest;
import org.socialbiz.cog.CustomRole;
import org.socialbiz.cog.MeetingRecord;
import org.socialbiz.cog.NGWorkspace;
import org.socialbiz.cog.UserRef;
import com.purplehillsbooks.json.JSONObject;

public class MeetingNotesCache {
    
    private Hashtable<String,NoteHolder> cache;
    
    private class NoteHolder {
        List<AddressListEntry> members;
        String targetRole;
        long cacheTime = 0;
        JSONObject notesObject;
        JSONObject fullObject;
        String meetingId;

        boolean canAccess(UserRef user) throws Exception {
            if (user==null) {
                return false;
            }
            return CustomRole.isPlayerOfAddressList(user, members);
        }
        void assertMeetingParticipant(UserRef user) throws Exception {
            if (user==null) {
                throw new Exception("Must be logged in to access meeting "+meetingId+".");
            }
            if (!canAccess(user)) {
                throw new Exception("User ("+user.getUniversalId()+") is not in the target role ("+targetRole+") for meeting "+meetingId+" and can not access the meeting");
            }
        }
    }
    
    public MeetingNotesCache() {
        cache = new Hashtable<String,NoteHolder>();
    }
    
    public boolean canAcccessMeeting(String site, String workspace, AuthRequest ar, 
            String meetingId) throws Exception {
        String key = site + "|" + workspace + "|" + meetingId;
        NoteHolder nh = cache.get(key);
        if (nh==null) {
            //this gets a lock and that can block....
            NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail( site, workspace ).getWorkspace();
            ar.setPageAccessLevels(ngw);
            nh = cacheMeeting(ngw,ar,meetingId);
        }
        return nh.canAccess(ar.getUserProfile());
    }

    
    public JSONObject getOrCacheNotes(String site, String workspace, AuthRequest ar, 
            String meetingId) throws Exception {
        String key = site + "|" + workspace + "|" + meetingId;
        NoteHolder nh = cache.get(key);
        if (nh!=null) {
            nh.assertMeetingParticipant(ar.getUserProfile());
            return nh.notesObject;
        }
        
        //this requires waiting for and getting the lock
        NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail( site, workspace ).getWorkspace();
        ar.setPageAccessLevels(ngw);
        return updateCacheNotes(ngw, ar, meetingId);
    }

    public JSONObject getOrCacheFull(String site, String workspace, AuthRequest ar, 
            String meetingId) throws Exception {
        String key = site + "|" + workspace + "|" + meetingId;
        NoteHolder nh = cache.get(key);
        if (nh!=null) {
            nh.assertMeetingParticipant(ar.getUserProfile());
            return nh.fullObject;
        }
        
        //this requires waiting for and getting the lock
        NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail( site, workspace ).getWorkspace();
        ar.setPageAccessLevels(ngw);
        return updateCacheFull(ngw, ar, meetingId);
    }

    public JSONObject updateCacheNotes(NGWorkspace ngw, AuthRequest ar, 
            String meetingId) throws Exception {
        NoteHolder nh = cacheMeeting(ngw,ar,meetingId);
        return nh.notesObject;
    }

    public JSONObject updateCacheFull(NGWorkspace ngw, AuthRequest ar, 
            String meetingId) throws Exception {
        NoteHolder nh = cacheMeeting(ngw,ar,meetingId);
        return nh.fullObject;
    }
    
    
    private NoteHolder cacheMeeting(NGWorkspace ngw, AuthRequest ar, 
            String meetingId) throws Exception {
        String key = ngw.getSiteKey() + "|" + ngw.getKey() + "|" + meetingId;
        MeetingRecord meeting = ngw.findMeeting(meetingId);
        NoteHolder nh = new NoteHolder();
        nh.cacheTime = System.currentTimeMillis();
        nh.notesObject = meeting.getMeetingNotes();
        nh.fullObject = meeting.getFullJSON(ar, ngw);
        nh.targetRole = meeting.getTargetRole();
        nh.members = ngw.getRoleOrFail(nh.targetRole).getExpandedPlayers(ngw);
        nh.meetingId = meeting.getId();
        //nh.assertMeetingParticipant(ar.getUserProfile());
        cache.put(key, nh);
        return nh;
    }
    
}
