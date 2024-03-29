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

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * Tracks a single user visiting a site so taht we can report how many others are
 * there at the same time.
 */
public final class Visitation {

    public static final long THIRTY_MINUTES = 1800000;

    public String userKey;
    public String site;
    public String workspace;
    public long timestamp;

    private Visitation() {
    }

    /**
     * This is the main way that you add a user to a visitation list.
     * It walks through the list passed, and returns a new list with the specified user
     * added, and with all the out-of-date entries removed.
     */
    static List<Visitation> markVisit(List<Visitation> source, String vuser, String vsite, String vworkspace, long vtimestamp) {
        Visitation thisVisit = new Visitation();
        thisVisit.timestamp = vtimestamp;
        thisVisit.userKey = vuser;
        thisVisit.site = vsite;
        thisVisit.workspace = vworkspace;
        long tooOld = vtimestamp - THIRTY_MINUTES;
        ArrayList<Visitation> newList = new ArrayList<Visitation>();
        newList.add(thisVisit);
        for (Visitation v : source) {
            if (v.timestamp < tooOld) {
                //remove this because it is too old
                continue;
            }
            if (v.userKey.equals(vuser) && v.site.equals(vsite) && v.workspace.equals(vworkspace)) {
                //remove this because it will be replaced below
                continue;
            }
            newList.add(v);
        }
        return newList;
    }

    /**
     * Pass a site and workspace, and returns a list of the users that have accessed that
     * site in the past 30 minutes.
     */
    static List<String> getCurrentUsers(List<Visitation> source, String vsite, String vworkspace) {
        long tooOld = System.currentTimeMillis() - THIRTY_MINUTES;
        ArrayList<String> newList = new ArrayList<String>();
        for (Visitation v : source) {
            if (v.timestamp < tooOld) {
                continue;
            }
            if (v.site.equals(vsite) && v.workspace.equals(vworkspace)) {
                newList.add(v.userKey);
            }
        }
        return newList;
    }
    
    /**
     * Simply produce a list of all users accessing in the past 30 minutes
     * without regard to workspace or site
     */
    static Set<String> getGlobalUsers(List<Visitation> source) {
        long tooOld = System.currentTimeMillis() - THIRTY_MINUTES;
        Set<String> newList = new HashSet<String>();
        for (Visitation v : source) {
            if (v.timestamp < tooOld) {
                continue;
            }
            //this will add only if not already there
            newList.add(v.userKey);
        }
        return newList;
    }

    /**
     * gets the most recent visitation
     */
    static Visitation getRecentVisit(List<Visitation> source, String uid) {
        long tooOld = System.currentTimeMillis() - THIRTY_MINUTES;
        Visitation ret = null;
        for (Visitation v : source) {
            if (v.timestamp < tooOld) {
                continue;
            }
            if (uid.equals(v.userKey)) {
                if (ret==null) {
                    ret = v;
                }
                else if (v.timestamp > ret.timestamp) {
                    ret = v;
                }
            }
        }
        return ret;
    }
    static List<Visitation> getAllVisits(List<Visitation> source, String uid) {
        long tooOld = System.currentTimeMillis() - THIRTY_MINUTES;
        List<Visitation> ret = new ArrayList<Visitation>();
        for (Visitation v : source) {
            if (v.timestamp < tooOld) {
                continue;
            }
            if (uid.equals(v.userKey)) {
                ret.add(v);
            }
        }
        return ret;
    }
    

}