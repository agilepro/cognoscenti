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

import java.util.Collections;
import java.util.Comparator;
import java.util.List;

import org.w3c.dom.Document;
import org.w3c.dom.Element;


/**
* The user may watch a number of pages, in order to be informed of when
* they change.
*/
public class WatchRecordXML extends DOMFace
{
    //I figure this will be hit quite a bit, so remembering the
    //id when fetched the first time will probably make a difference,
    //and should not cause any additional memory bloat
    String cachedId;

    public WatchRecordXML(Document doc, Element upEle, DOMFace p)
    {
        super(doc,upEle, p);
    }

    /**
    * Pattern is "create" and the class name, is the proper way to
    * create a new element in the DOM tree, and return the wrapper class
    * Must pass the user that this is an ID of.
    */
    public static WatchRecordXML createWatchRecord(UserProfileXML user, String newId, long now)
        throws Exception
    {
        if (newId==null)
        {
            throw new RuntimeException("null value for newId passed to createWatchRecord");
        }
        WatchRecordXML newSR = user.createChildWithID("watch",
                WatchRecordXML.class, "pagekey", newId);
        newSR.setLastSeen(now);
        return newSR;
    }

    /**
    * Pattern is "remove" and the class name, is the proper way to
    * create a new element in the DOM tree, and return the wrapper class
    * Must pass the user that this is an ID of.
    */
    public void removeWatchRecord(UserProfileXML user)
        throws Exception
    {
        user.removeChild(this);
    }

    /**
    * Pattern is "find" and the class name, is the proper way to
    * read the DOM tree for all the elements of thsi type
    */
    public static void findWatchRecord(UserProfileXML user, List<WatchRecordXML> results)
            throws Exception {
        List<WatchRecordXML> chilluns = user.getChildren("watch", WatchRecordXML.class);
        for (WatchRecordXML wr : chilluns) {
            results.add(wr);
        }
    }

    public String getPageKey()
    {
        if (cachedId==null)
        {
            cachedId = getAttribute("pagekey");
        }
        return cachedId;
    }


    public void setLastSeen(long seenTime)
    {
        setAttributeLong("lastseen",seenTime);
    }

    public long getLastSeen()
    {
        return getAttributeLong("lastseen");
    }


    public static void sortBySeenDate(List<WatchRecordXML> watchList) {
        Collections.sort(watchList, new WatchSeenComparator());
    }
    public static void sortByChangeDate(List<WatchRecordXML> watchList, Cognoscenti cog) {
        Collections.sort(watchList, new WatchChangeComparator(cog));
    }

    private static class WatchSeenComparator implements Comparator<WatchRecordXML> {
        public WatchSeenComparator() {
        }

        @Override
        public int compare(WatchRecordXML arg0, WatchRecordXML arg1) {
            return (int)(arg0.getLastSeen() - arg1.getLastSeen());
        }
    }

    private static class WatchChangeComparator implements Comparator<WatchRecordXML> {
        Cognoscenti cog;

        public WatchChangeComparator(Cognoscenti _cog) {
            cog = _cog;
        }

        @Override
        public int compare(WatchRecordXML arg0, WatchRecordXML arg1) {
            try {
                NGPageIndex ngpi0 = cog.getWSByCombinedKeyOrFail(arg0.getPageKey());
                long time0 = 0;
                if (ngpi0!=null) {
                    time0 = ngpi0.lastChange;
                }
                NGPageIndex ngpi1 = cog.getWSByCombinedKeyOrFail(arg1.getPageKey());
                long time1 = 0;
                if (ngpi1!=null) {
                    time1 = ngpi1.lastChange;
                }
                if (time0 > time1) {
                    return 1;
                }
                else if (time0==time1) {
                    return 0;
                }
                else {
                    return -1;
                }
            }
            catch (Exception e) {
                throw new RuntimeException(e);
            }
        }
    }



}
