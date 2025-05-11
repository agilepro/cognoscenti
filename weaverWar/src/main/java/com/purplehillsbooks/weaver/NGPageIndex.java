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

import java.io.File;
import java.io.PrintStream;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Hashtable;
import java.util.Iterator;
import java.util.List;
import java.util.Set;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.TimeUnit;

import com.purplehillsbooks.weaver.exception.WeaverException;
import com.purplehillsbooks.json.JSONException;
import com.purplehillsbooks.json.JSONObject;

/**
 * NGPageIndex is an index entry in an index of pages
 *
 * There exists a collection of NGWorkspace objects (process leaves). This class
 * helps to form an index to those objects and to provide basic metadata about
 * those pages without having to have all pages (all leaves) in memory at the
 * same time. The index holds the page name, page key, references from that
 * page, pages that refer to that page, which book, last change, whether a
 * request for membership is pending, and who the admins (authors) of the page
 * are. These values are selected in order to allow for quick searching and
 * listing of exisitng pages according to certain common criteria. Most
 * importantly, this allows for back-links to be detected readily: since we have
 * a list of forward links, we can scan through there and build a list of back
 * links.
 *
 * Forward links are found by using a method on NGWorkspace to find all the outbound
 * links. In this case, a link is string using wiki-link rules (can be a name
 * and link together separated by vertical bar). This can also include external
 * links, which are ignored by this index. Internal links are simply the name of
 * leaf being addressed. This name is case-insensitive and
 * punctuation-insensitive. This is accomplished by converting the name to a
 * lowercase and stripping all non alpha-num characters out. This simplified
 * version of the name is compared between what the page is linking to and the
 * simplified names of the other pages.
 *
 * Leaves (pages) can have multiple names, so that the name can be changed
 * without breaking links -- old reference will continue to work.
 *
 * Names are not necessarily unique: there can be multiple leaves with the same
 * name, because users are not prevented from entering a particular name. This
 * means that there needs to be a "disambiguation" step in the case that there
 * are other pages with the same name.
 *
 * The approach is to have two objects: one object NGPageIndex represents the
 * leaf (page) and the other represents a particular name value (NGTerm). The
 * term object represents a many-to-many association between all the pages that
 * link to a term, and all the pages that can be targets of that term. Thus the
 * NGPageIndex object has a "name" collection of terms, and a "links" collection
 * of terms. Each NGTerm has a "target pages" collection of index entries, and a
 * "source links" collection of index entries.
 *
 * For example, a page "p1" may have three names: "a", "b", and "c". The page
 * "p1" will be represented by an NGPageIndex object. There will be three NGTerm
 * objects, one for each name. Each of those NGTerm objects will have a single
 * target reference back to the page "p1". If a page "p2" links to "a", then in
 * the link collection for "p2" it will have a pointer to the term "a", and term
 * "a" will include "p2" in the "source link" collection.
 *
 * If you are on page "p1", and want to find all the pages that point to "p1",
 * then you find all the terms that represent the names of "p1", and find all
 * the pages that link to that term.
 *
 * This has the effect of over counting in the case of non-unique names. If
 * there are three pages that have a single link to "a", and there are three
 * pages that have the single name "a", then each of the three target pages will
 * show three pages linking to them. And each page will effectively link to all
 * three of the pages with the same name. Even though the page has only one
 * link. In practice, the user will have to choose the page when traversing the
 * link.
 */
public class NGPageIndex {

    public List<NGTerm> nameTerms;
    public List<NGTerm> refTerms;
    public long lastChange;
    public boolean requestWaiting;
    public boolean isDeleted;
    private boolean isFrozen;
    private boolean isMoved;
    public String[] admins; // a.k.a. authors
    public long nextScheduledAction;

    public File containerPath;   // full path to the workspace XML file
    public String containerName; // The nicest name to use for this container
    public String containerKey;
    public String wsSiteName;
    public String wsSiteKey;
    public String parentKey;     // Key for the 'circle' hierarchy parent workspace
    public Set<String> allUsers; // all users mentioned anywhere


    /**
     * containerType is the type of container whether it is Site, Workspace or
     * User See constants below
     */
    public int containerType = 0;
    // use these constants for containerType
    public static final int CONTAINER_TYPE_SITE = 1;
    public static final int CONTAINER_TYPE_WORKSPACE = 4;

    private long lockedBy = 0;
    private long lockedTime = 0;
    //private Exception lockedByAuditException = new Exception("Audit Lock Trail");

    private ArrayBlockingQueue<String> lockBlq;


    /*********************** STATIC VARS ******************************/


    private static int blqSize = 10;

    public static Hashtable<String, List<ArrayBlockingQueue<String>>> blqList = new Hashtable<String, List<ArrayBlockingQueue<String>>>();

    public static Hashtable<String, ArrayBlockingQueue<String>> bsnList = new Hashtable<String, ArrayBlockingQueue<String>>();

    public static final long   PAGE_NTFX_WAIT = 10;
    public static final String LOCK_ID = "lock";
    public static final String NO_LOCK_ID = "nolock";
    private static HashMap<String, List<NGPageIndex>> lockMap = new HashMap<String, List<NGPageIndex>>();



    public String getCombinedKey() {
        return wsSiteKey + "|" + containerKey;
    }


    /**
     * Returns the collection of all target pages that are linked FROM this
     * page. List contains NGPageIndex objects. Remember, this may contain
     * multiple pages for a single link if there are multiple pages with the
     * same name.
     */
    public List<NGPageIndex> getOutLinkPages() {
        List<NGPageIndex> ret = new ArrayList<NGPageIndex>();
        for (NGTerm term : refTerms) {
            for (NGPageIndex target : term.targetLeaves) {
                if (!ret.contains(target)) {
                    ret.add(target);
                }
            }
        }
        sortByName(ret);
        return ret;
    }

    /**
     * Returns the collection of all source pages that link TO this page. List
     * contains NGPageIndex objects. Remember, this may contain multiple pages
     * for a single link if there are multiple pages with the same name.
     */
    public List<NGPageIndex> getInLinkPages() {
        List<NGPageIndex> ret = new ArrayList<NGPageIndex>();
        for (NGTerm term : nameTerms) {
            for (NGPageIndex target : term.sourceLeaves) {
                if (!ret.contains(target)) {
                    ret.add(target);
                }
            }
        }
        sortByName(ret);
        return ret;
    }

    /**
     * Determine whether there are any inbound links, and if so it is not an
     * orphan, but if there are none, then it is an orphan.
     */
    public boolean isOrphan() {
        for (NGTerm term : nameTerms) {
            // if there are any pages pointing to this term, then
            // this page is not an orphan.
            if (term.sourceLeaves.size() > 0) {
                // found one workspace that points to this term that points
                // to this workspace. That is enough to not be an orphan.
                return false;
            }
        }
        // if we found none, then it is an orphan
        return true;
    }


    /**
     * Given a string tag value, looks for and returns all the pages that are
     * tagged with that tag.
     *
     * Must NOT manipulate resulting vector in any way!
     */
    public static List<NGPageIndex> getContainersForTag(String tag) throws Exception {
        if (tag == null) {
            throw WeaverException.newBasic("null value tag given to getPagesForTag");
        }
        NGTerm tagTerm = NGTerm.findTagIfExists(tag);
        if (tagTerm == null) {
            return new ArrayList<NGPageIndex>();
        }
        return tagTerm.targetLeaves;
    }

    public NGWorkspace getWorkspace() throws Exception {
        return (NGWorkspace) getContainer();
    }
    public NGBook getSite() throws Exception {
        return (NGBook) getContainer();
    }
    public NGBook getSiteForWorkspace() throws Exception {
        return NGBook.readSiteByKey(wsSiteKey);
    }

    /**
     * Get the container object associated with this index entry, or return a
     * null if one can not be found.
     */
    private NGContainer getContainer() throws Exception {
        setLock();
        if (containerType == CONTAINER_TYPE_WORKSPACE) {
            return NGWorkspace.readWorkspaceAbsolutePath(containerPath);
        }
        else if (containerType == CONTAINER_TYPE_SITE) {
            return NGBook.readSiteByKey(containerKey);
        }
        else {
            throw WeaverException.newBasic("Unspecified or illegal containerType value: %s", containerType);
        }
    }

    /**
     * Get the container object associated with this index entry, or throw an
     * exception if that container can not be found. This method never returns a
     * null;
     */
    public NGContainer getContainerOrFail() throws Exception {
        NGContainer val = getContainer();
        if (val != null) {
            return val;
        }
        throw WeaverException.newBasic("Unable to locate the container object for '%s'.  The index entry for %s' exists, but appears to be invalid.",
                containerName, containerKey);
    }

    public void writeTruncatedLink(AuthRequest ar, int len) throws Exception {
        String linkName = containerName;

        ar.write("\n    <a href=\"");
        ar.writeHtml(ar.retPath);
        ar.writeHtml(ar.getResourceURL(this, "FrontPage.htm"));
        ar.write("\"  title=\"Navigate to workspace: ");
        ar.writeHtml(linkName);
        ar.write("\">");
        if (linkName.length() > len) {
            linkName = linkName.substring(0, len);
        }
        ar.writeHtml(linkName);
        if (isDeleted) {
            ar.write("<img src=\"");
            ar.writeHtml(ar.retPath);
            ar.write("deletedLink.gif\">");
        }
        ar.write("</a>");
    }

    /**
     * Set all static values back to their initial states, so that garbage
     * collection can be done, and subsequently, the class will be
     * reinitialized.
     *
     * NGPageIndex is the master, which calls NGBook and NGWorkspace.
     */
    public synchronized static void clearAllStaticVars() {
        blqSize = 10;
        blqList = null;
        bsnList = null;
        lockMap = null;
    }

    public synchronized static void initAllStaticVars() {
        blqSize = 10;
        blqList = new Hashtable<String, List<ArrayBlockingQueue<String>>>();
        bsnList = new Hashtable<String, ArrayBlockingQueue<String>>();
        lockMap = new HashMap<String, List<NGPageIndex>>();
    }



    public boolean isInVector(List<NGPageIndex> v) {
        boolean isWorkspace = isWorkspace();
        for (NGPageIndex y : v) {
            if (containerKey.equals(y.containerKey)) {
                if (!isWorkspace) {
                    return true;
                }
                if (wsSiteKey!=null && y.wsSiteKey!=null && wsSiteKey.equals(y.wsSiteKey)) {
                    return true;
                }
            }
        }
        return false;
    }

    /**
     * Implement sorting and comparator classes
     */
    public static void sortByName(List<NGPageIndex> v) {
        Collections.sort(v, new NGPIByName());
    }

    public static void sortInverseChronological(List<NGPageIndex> v) {
        Collections.sort(v, new NGPIByInverseChange());
    }

    private static class NGPIByName implements Comparator<NGPageIndex> {
        NGPIByName() {
        }

        public int compare(NGPageIndex o1, NGPageIndex o2) {
            String n1 = o1.containerName.toLowerCase();
            String n2 = o2.containerName.toLowerCase();
            return n1.compareTo(n2);
        }

    }

    /**
     * Used to sort NGPI entries from most recent change, to least recent change
     */
    private static class NGPIByInverseChange implements Comparator<NGPageIndex> {
        NGPIByInverseChange() {
        }

        public int compare(NGPageIndex o1, NGPageIndex o2) {
            long n1 = o1.lastChange;
            long n2 = o2.lastChange;
            if (n1 < n2) {
                return 1;
            }
            else if (n1 == n2) {
                return 0;
            }
            else {
                return -1;
            }
        }

    }

    public boolean isWorkspace() {
        return (containerType == CONTAINER_TYPE_WORKSPACE);
    }

    public static void postEventMsg(String emsg) {
        if (blqList==null) {
            //during initialization all messages are ignored
            return;
        }
        String result = "evt_" + emsg;
        List<ArrayBlockingQueue<String>> v = blqList.get(emsg);
        if (v != null) {
            // copied out to an array because I had concurrent update problems
            // otherwise.
            Object[] olist = v.toArray();
            for (Object ooo : olist) {
                try {
                    @SuppressWarnings("unchecked")
                    ArrayBlockingQueue<String> queue = (ArrayBlockingQueue<String>) ooo;
                    queue.add(result);
                }
                catch (Exception e) {
                    // Queue may be full ignore
                }
            }
        }
    }

    public static String getEvtMsg(String id, String emsg) throws Exception {
        if (blqList==null) {
            //during initialization all messages are ignored
            return null;
        }
        long l = PAGE_NTFX_WAIT;

        List<ArrayBlockingQueue<String>> v = blqList.get(emsg);
        if (v == null) {
            v = new ArrayList<ArrayBlockingQueue<String>>();
            blqList.put(emsg, v);
        }
        ArrayBlockingQueue<String> blq = new ArrayBlockingQueue<String>(blqSize);

        if (id.endsWith("ie6")) {
            try {
                ArrayBlockingQueue<String> oblq = bsnList.put(id, blq);
                if (oblq != null) {
                    oblq.add("cancel");
                }
            }
            catch (Exception e) {
                // Queue may be full ignore
            }
        }

        v.add(blq);
        String rmsg = blq.poll(l, TimeUnit.SECONDS);
        v.remove(blq);
        return rmsg;
    }

    public void setLock() throws Exception {
        if (lockBlq==null) {
            //during initialization all locks are ignored
            return;
        }
        long thisThread = Thread.currentThread().threadId();
        try {
            if (lockedBy == thisThread) {
                // thread already has this lock, so ignore this. Everything is
                // unlocked at once at the end of the web request
                return;
            }

            boolean wasLocked = lockedBy!=0;
            if (wasLocked) {
                long lockAge = System.currentTimeMillis() - lockedTime;
                System.out.println("    LOCKWAIT: tid="+thisThread+" spaceId="+containerKey+" held by tid="+lockedBy+" for age="+lockAge+"ms");
                if (lockBlq.size()>0) {
                    System.out.println("    LOCKTWIST: tid="+thisThread+" blocking queue is NOT EMPTY so not really locked!");
                }
            }

            //pull the one item out of the blocking array so that other threads are blocked
            //if they get here before this thread is done.
            String lockObj = lockBlq.poll(10, TimeUnit.SECONDS);
            if (lockObj == null) {
                //rusty lock feature.   Ignore any lock that is more than 10 seconds old
                if (lockedBy!=0) {
                    long lockAge = System.currentTimeMillis() - lockedTime;
                    System.out.println("    LOCKSTEAL: tid="+thisThread+" grabbing lock from tid="+lockedBy+" age="+lockAge+"ms");
                }
            }
            else if (wasLocked) {
                System.out.println("    LOCKRCV: tid="+thisThread+" successfully got lock for spaceId="+containerKey);
            }

            lockedBy = thisThread;
            lockedTime = System.currentTimeMillis();
            String ctid = "tid:" + thisThread;
            //lockedByAuditException = new Exception("    LOCKED: tid="+thisThread+"  spaceId=" + containerKey);
            List<NGPageIndex> ngpiList = NGPageIndex.lockMap.get(ctid);
            if (ngpiList == null) {
                ngpiList = new ArrayList<NGPageIndex>();
                NGPageIndex.lockMap.put(ctid, ngpiList);
            }
            ngpiList.add(this);
        }
        catch (Exception e) {
            throw WeaverException.newWrap("Failed to set up the lock for Edit of (%s) tid=%s", e, this.containerKey, thisThread);
        }
    }

    public void clearLock() {
        if (lockBlq==null) {
            //during initialization all locks are ignored
            return;
        }
        long thisThread = Thread.currentThread().threadId();
        String ctid = "tid:" + thisThread;
        try {
            if (lockedBy != thisThread) {
                // should probably throw an exception here ... but signature is not right
                // and, not sure what we can do about it. Unlocking should continue.
                long lockAge = System.currentTimeMillis() - lockedTime;
                System.out.println("    LOCKVICTIM: tid="+thisThread+" had lock stolen "+lockAge+"ms ago!");
                JSONException.traceException(new Exception("OFFENDING THREAD tried to hold lock too long"),
                        "    LOCKVICTIM: tid="+thisThread+" had lock stolen "+lockAge+"ms ago!");
                if (lockAge<10000) {
                    //don't understand how this lock got taken from this thread, but since it is young
                    //let it remain there.  Older locks get cleared out.
                    return;
                }

            }
            this.lockedBy = 0;
            //this.lockedByAuditException = null;
            if (lockBlq.size()==0) {
                //should be empty, but never add a second one to the queue, because then it could end up
                //allowing multiple threads to have locks.  The blocking relies on the lock taker
                //taking the one and only entry
                lockBlq.add(LOCK_ID);
            }
        }
        catch (IllegalStateException e) {
            // Lock is already available
            System.out.println(SectionUtil.currentTimestampString() + " " + ctid + ": clearLock cid: "
                    + this.containerKey + " lock is available nothing to clear");
        }
    }

    /**
     * Here is the deal:  when you access a workspace or other major object, it is locked
     * to that thread so that we don't have multiple threads working on the same data.
     *
     * However, some routines walk through multiple major objects, and this might lead to
     * them holding lots and lots of locks, causing deadlock problems.  Those routines
     * want to unlock the major objects.
     *
     * Unlocking in a method is safe ONLY if you enter the routine without any locks.
     * Nested locks are not tracked, so you can recursively fetch a major object without
     * locking yourself out.  But if one of those recursive fetches ALSO does an unlock,
     * then you are unlocking for the parent AS WELL, and that is mucho-dangerous.
     *
     * The solution:  every method that is going to walk through major objects, and
     * unlock in the middle of that, must ASSERT that there were no long being held by
     * that thread before entering.  This is the only way to know that unlocking will
     * be safe.  The all calling methods on the way must guarantee that they are not
     * holding a lock whenever such a method is called.
     *
     * This method asserts that no locks are held by the thread, and throws an exception
     * if it finds any locks held by this thread.  That would be a no-no.
     */
    public static void assertNoLocksOnThread() throws Exception {
        if (lockMap==null) {
            //during initialization all locks are ignored
            return;
        }
        long thisThread = Thread.currentThread().threadId();
        String ctid = "tid:" + thisThread;
        if (lockMap.containsKey(ctid)) {

            //This is a pernicious problem that might cause a deadlock, so make a big deal in the
            //log file so that it gets fixed proactively.  You need the stack trace to fix it,
            //so go ahead and put the stack trace in the log file.
            Exception e = new Exception("program logic error: Thread tid="+thisThread+" is holding a lock when it should not.  "
                    +"Method that is controlling locks must only be called when no locks are being held.  "
                    +"Clear all locks and all references to locked objects before calling this method.");
            System.out.println("\n\n~~~~~~ THREAD LOCK VIOLATION ~~~~~~~"+SectionUtil.currentTimestampString());
            PrintStream ps = new PrintStream(System.out);
            JSONException.traceException(ps, e, "THREAD LOCK VIOLATION");
            System.out.println("~~~~~~ THIS IS PROGRAM LOGIC ERROR ~~~~~~~\n\n");
            throw e;
        }
    }


    public static void clearLocksHeldByThisThread() {
        if (lockMap==null) {
            //during initialization all locks are ignored
            return;
        }
        String ctid = "tid:" + Thread.currentThread().threadId();
        List<NGPageIndex> indexList = lockMap.remove(ctid);
        if (indexList == null) {
            return;
        }
        for (NGPageIndex ngpindx : indexList) {
            ngpindx.clearLock();
        }
    }

    public static void releaseLock(NGContainer ngc) {
        if (lockMap==null) {
            //during initialization all locks are ignored
            return;
        }
        String ckey = ngc.getKey();
        String ctid = "tid:" + Thread.currentThread().threadId();
        List<NGPageIndex> indexList = lockMap.get(ctid);
        if (indexList == null) {
            return;
        }

        Iterator<NGPageIndex> iter = indexList.iterator();
        while (iter.hasNext()) {
            NGPageIndex ngpi = iter.next();
            if (ngpi.containerKey.equalsIgnoreCase(ckey)) {
                ngpi.clearLock();
                indexList.remove(ngpi);
                break;
            }
        }

    }

    public boolean isFrozen() {
        return isFrozen;
    }
    public boolean isDeleted() {
        return isDeleted;
    }

    // ///////////// INTERNAL PRIVATE METHODS ///////////////////

    /**
     * only Cognoscenti object should need to call the constructor, since these are created
     * purely by scanning files, or by adding containers. The index is built and
     * maintained by Cognoscenti.
     */
    NGPageIndex(NGContainer container) throws Exception {
        lockBlq = new ArrayBlockingQueue<String>(1);
        lockBlq.add(LOCK_ID);
        buildLinks(container);
    }

    public void buildLinks(NGContainer container) throws Exception {

        containerName = "~Container Has No Name";
        isDeleted = container.isDeleted();
        isFrozen = container.isFrozen();
        lastChange = container.getLastModifyTime();

        // consistency check, either the nameTerms or refTerms vectors must
        // be missing or empty.
        if (nameTerms != null && nameTerms.size() > 0) {
            throw WeaverException.newBasic(
                    "Program logic is asking for building nameTerms links when it already has some.");
        }
        if (refTerms != null && refTerms.size() > 0) {
            throw WeaverException.newBasic(
                    "Program logic is asking for building refTerms links when it already has some.");
        }

        containerPath = container.getFilePath();
        containerKey = container.getKey();

        if (container instanceof NGWorkspace) {
            containerType = CONTAINER_TYPE_WORKSPACE;
        }
        else if (container instanceof NGBook) {
            containerType = CONTAINER_TYPE_SITE;
        }
        else {
            throw WeaverException.newBasic("Program Logic Error: don't know what kind of container this is: %s",
                    containerPath);
        }

        initNameTerms(container);

        initLinkTerms(container);

        // record the admins (authors) of the page
        NGRole adminRole = container.getSecondaryRole();
        List<AddressListEntry> v = adminRole.getExpandedPlayers(container);
        admins = new String[v.size()];
        int i = 0;
        for (AddressListEntry ale : v) {
            admins[i++] = ale.getUniversalId();
        }

        //initIndexForHashTags(container);

        if (container instanceof NGWorkspace) {
            NGWorkspace ngw = (NGWorkspace) container;
            NGBook ngb = ngw.getSite();
            isMoved = ngb.isMoved();
            if (ngb != null) {
                wsSiteName = ngb.getFullName();
                wsSiteKey = ngb.getKey();
            }
            parentKey = ngw.getParentKey();

            updateAllUsersFromWorkspace(ngw);
        }
        nextScheduledAction = container.nextActionDue();
    }

    public void updateAllUsersFromWorkspace(NGWorkspace ngw) throws Exception {
        //now, get a complete listing of all users in the workspace
        //to optimize the background refresh of user stats
        System.out.println("UPDATE ALL USERS: for workspace: "+ngw.getKey());
        WorkspaceStats wStats = new WorkspaceStats();
        wStats.gatherFromWorkspace(ngw);
        wStats.countUsers(ngw.getSite().getUserMap());
        HashSet<String> userTempKeys = new HashSet<String>();
        for (String email : wStats.anythingPerUser.keySet()) {
            UserProfile uProf = UserManager.lookupUserByAnyId(email);
            if (uProf!=null) {
                //only add users that actually have profiles
                userTempKeys.add(uProf.getKey());
            }
        }
        allUsers = userTempKeys;
    }

    /**
     * The container (workspace or site) can have any number of names. For each
     * name, an associated term is found, and that term is made to point to this
     * container.
     */
    private void initNameTerms(NGContainer container) throws Exception {
        List<NGTerm> nameTermsTmp = new ArrayList<NGTerm>();

        // make a link to the page key first
        String combinedKey = containerKey;
        if (isWorkspace()) {
            combinedKey = wsSiteKey + "|" + containerKey;
        }
        NGTerm term = NGTerm.findTerm(combinedKey);
        if (term == null) {
            throw WeaverException.newBasic("Can not find page because the key given does not contain any alphanum characters and can not be used to find any page.");
        }
        if (isInVector(term.targetLeaves)) {
            throw WeaverException.newBasic("Here is the duplication problem, targetLeaves already has a reference to this key, but 'this' does not know about it.");
        }
        term.targetLeaves.add(this);
        nameTermsTmp.add(term);

        containerName = container.getContainerName();
        term = NGTerm.findTerm(containerName);
        if (term != null) {
            if (!nameTermsTmp.contains(term)) {
                if (isInVector(term.targetLeaves)) {
                    throw WeaverException.newBasic("Here is the duplication problem, targetLeaves already has a reference to this key, but 'this' does not know about it.");
                }
                term.targetLeaves.add(this);
                sortByName(term.targetLeaves);
                nameTermsTmp.add(term);
            }
        }
        nameTerms = nameTermsTmp;
    }

    /**
     * Containers have outbound links. This method finds all the links, and then
     * finds the associated terms, then marks those terms as having source links
     * from this container.
     */
    private void initLinkTerms(NGContainer container) throws Exception {
        List<String> tmpRef = new ArrayList<String>();
        if (container instanceof NGWorkspace) {
            // find the links in the page, right now only the Link type sections

            ((NGWorkspace) container).findLinks(tmpRef);
            Collections.sort(tmpRef);
        }
        // remove duplicate entries in the map
        List<NGTerm> refTermTmp = new ArrayList<NGTerm>();
        for (String entry : tmpRef) {
            int barPos = entry.indexOf("|");
            if (barPos >= 0) {
                entry = entry.substring(barPos + 1).trim();
            }

            // detect external links, any link with a slash in it, is assumed
            // to be a URL. To address a page with a slash in the name, address
            // it without the slash (which is stripped in sanitize anyway).
            if (entry.indexOf("/") >= 0) {
                continue; // skip external links
            }
            NGTerm term = NGTerm.findTerm(entry);
            if (term == null) {
                // this is not a good link, ignore it
                continue;
            }
            if (!refTermTmp.contains(term)) {
                refTermTmp.add(term);
                if (isInVector(term.sourceLeaves)) {
                    throw WeaverException.newBasic("Problem with source leaves while trying to link");
                }
                term.sourceLeaves.add(this);
                sortByName(term.sourceLeaves);
            }
        }
        // update this all at once at the end to avoid multi-threading problems
        // with half-built indices
        refTerms = refTermTmp;
    }

    /**
     * unlinkAll disconnects this NGPageIndex object from the terms so that it
     * can be discarded. This must be called when an index entry is removed from
     * the index.
     */
    public void unlinkAll() {
        for (NGTerm term : nameTerms) {
            term.removeTarget(this);
        }
        nameTerms.clear();

        for (NGTerm term : refTerms) {
            term.removeSource(this);
        }
        refTerms.clear();
    }

    public JSONObject getJSON4List() throws Exception {
        JSONObject wObj = new JSONObject();
        wObj.put("changed", lastChange);
        wObj.put("name",    containerName);
        wObj.put("pageKey", containerKey);
        wObj.put("siteKey", wsSiteKey);
        wObj.put("parentKey", parentKey);
        wObj.put("isDeleted", isDeleted);
        wObj.put("frozen", isFrozen);
        wObj.put("isMoved", isMoved);
        wObj.put("comboKey", getCombinedKey());
        return wObj;
    }

}
