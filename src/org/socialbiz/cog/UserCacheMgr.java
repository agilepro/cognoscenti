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
        for (UserProfile up : UserManager.getAllUserProfiles()) {
            needsRecalc.add(up.getKey());
        }
    }

    public void needRecalc(List<String> usersWhoMightHaveChanges) {
        for (String aUser :usersWhoMightHaveChanges ) {
            needsRecalc.add(aUser);
        }
    }
    public void needRecalc(UserProfile userWhoMightHaveChanges) {
        needsRecalc.add(userWhoMightHaveChanges.getKey());
    }

    public UserCache getCache(String userKey) throws Exception {
        UserCache theCache = new UserCache(cog, userKey);
        if (needsRecalc.contains(userKey)) {
            theCache.refreshCache(cog);
            theCache.save();
            needsRecalc.remove(userKey);
        }
        return theCache;
    }

}
