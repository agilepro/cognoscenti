package org.socialbiz.cog;

import java.util.HashSet;
import java.util.List;
import java.util.Set;

public class UserCacheMgr {

    Set<String> needsRecalc;
    Cognoscenti cog;

    public UserCacheMgr(Cognoscenti _cog) throws Exception{
        cog = _cog;
        needsRecalc = new HashSet<String>();

        //now initialize all users as needing a recalc sisce we don't know who
        //needed update at the time the server was last shut down.
        for (UserProfile up : cog.getUserManager().getAllUserProfiles()) {
            needsRecalc.add(up.getKey());
        }
    }

    public void needRecalc(List<String> usersWhoMightHaveChanges) {
        for (String aUser :usersWhoMightHaveChanges ) {
            System.out.println("USERCACHE: this user needs recalc: "+aUser);
            needsRecalc.add(aUser);
        }
    }
    public void needRecalc(UserProfile userWhoMightHaveChanges) {
        String aUser = userWhoMightHaveChanges.getKey();
        System.out.println("USERCACHE: this user needs recalc: "+aUser);
        needsRecalc.add(aUser);
    }

    public UserCache getCache(String userKey) throws Exception {
        UserCache theCache = new UserCache(cog, userKey);
        if (needsRecalc.contains(userKey)) {
            System.out.println("USERCACHE: refreshed cache for: "+userKey);
            theCache.refreshCache(cog);
            theCache.save();
            needsRecalc.remove(userKey);
        }
        else {
            System.out.println("USERCACHE: did not refresh cache this time for: "+userKey);
        }
        return theCache;
    }

}
