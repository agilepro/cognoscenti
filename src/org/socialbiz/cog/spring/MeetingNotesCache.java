package org.socialbiz.cog.spring;

import java.util.Hashtable;
import java.util.List;

import org.socialbiz.cog.AddressListEntry;
import org.socialbiz.cog.AuthRequest;
import org.socialbiz.cog.CustomRole;
import org.socialbiz.cog.MeetingRecord;
import org.socialbiz.cog.NGRole;
import org.socialbiz.cog.NGWorkspace;
import org.socialbiz.cog.UserRef;

import com.purplehillsbooks.json.JSONObject;

public class MeetingNotesCache {

    private Hashtable<String,NoteHolder> cache;

    private class NoteHolder {
        List<AddressListEntry> members;
        String targetRole;
        JSONObject notesObject;
        JSONObject fullObject;
        String meetingId;
        String siteKey;
        String workspaceKey;

        boolean canAccess(AuthRequest ar) throws Exception {
            UserRef user = ar.getUserProfile();
            if (user==null) {
                return false;
            }
            if (ar.isSuperAdmin()) {
                //superadmin can access anything
                return true;
            }
            if (CustomRole.isPlayerOfAddressList(user, members)) {
                return true;
            }

            //here is the problem, the list of users was cached, and if the role has changed
            //we should check one more time to see if the user is in the official list
            calculateMemberList(ar);
            return CustomRole.isPlayerOfAddressList(user, members);
        }

        private void calculateMemberList(AuthRequest ar) throws Exception {
            NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail( siteKey, workspaceKey ).getWorkspace();
            CustomRole meetRole = ngw.getRole(targetRole);
            List<AddressListEntry> targetPlayers = meetRole.getExpandedPlayers(ngw);

            //now add the regular workspace members
            NGRole memberRole = ngw.getPrimaryRole();
            for (AddressListEntry one : memberRole.getExpandedPlayers(ngw)) {
                AddressListEntry.addIfNotPresent(targetPlayers,one);
            }

            //now add the participants if any
            MeetingRecord meet = ngw.findMeeting(this.meetingId);
            for (String part : meet.getParticipants()) {
                AddressListEntry.addIfNotPresent(targetPlayers, new AddressListEntry(part));
            }
            members = targetPlayers;
        }

        void assertMeetingParticipant(AuthRequest ar) throws Exception {
            if (!ar.isLoggedIn()) {
                throw new Exception("Must be logged in to access meeting "+meetingId+".");
            }
            if (!canAccess(ar)) {
                throw new Exception("User ("+ar.getBestUserId()+") is not a participant for meeting "+meetingId+" and can not access the meeting");
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
        return nh.canAccess(ar);
    }


    public JSONObject getOrCacheNotes(String site, String workspace, AuthRequest ar,
            String meetingId) throws Exception {
        String key = site + "|" + workspace + "|" + meetingId;
        NoteHolder nh = cache.get(key);
        if (nh!=null) {
            nh.assertMeetingParticipant(ar);
            //if workspace object is not actually read, then it would not normally remember a visit
            //because setPageAccessLevels is not called, so we need to supply that here.
            ar.recordVisit(site, workspace);
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
            nh.assertMeetingParticipant(ar);
            //if workspace object is not actually read, then it would not normally remember a visit
            //because setPageAccessLevels is not called, so we need to supply that here.
            ar.recordVisit(site, workspace);
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
        nh.notesObject = meeting.getMeetingNotes();
        nh.fullObject = meeting.getFullJSON(ar, ngw, true);
        nh.targetRole = meeting.getTargetRole();
        nh.meetingId = meeting.getId();
        nh.siteKey = ngw.getSiteKey();
        nh.workspaceKey = ngw.getKey();
        nh.calculateMemberList(ar);
        cache.put(key, nh);
        return nh;
    }

}
