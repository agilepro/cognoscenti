package com.purplehillsbooks.weaver;

import java.io.File;
import java.util.ArrayList;
import java.util.Hashtable;
import java.util.List;
import java.util.Set;
import java.util.Timer;

import jakarta.servlet.ServletConfig;
import jakarta.servlet.ServletContext;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpSession;

import com.purplehillsbooks.weaver.api.IconServlet;
import com.purplehillsbooks.weaver.api.LightweightAuthServlet;
import com.purplehillsbooks.weaver.exception.WeaverException;
import com.purplehillsbooks.weaver.mail.EmailListener;
import com.purplehillsbooks.weaver.mail.EmailSender;
import com.purplehillsbooks.weaver.rest.ServerInitializer;
import com.purplehillsbooks.weaver.spring.BaseController;

/**
 * This is the main class for the Cognoscenti object package.
 * This is a singleton pattern, and holds all the root configuration information.
 * Stores itself as an attribute on the servlet context
 * Use this class for initialization and accessing
 * the main index to objects within Cognoscenti
 *
 */
public class Cognoscenti {

    public ServerInitializer initializer = new ServerInitializer(this);
    public static Cognoscenti cog = null;

    // public Exception lastFailureMsg = null;
    public boolean isInitialized = false;
    public boolean initializingNow = false;
    //TODO: get rid of this static variable
    private static String serverId = "XXX";

    //hold on to the servlet context in case you need it later
    private ConfigFile theConfig;
    private File rootFolder;
    private UserCacheMgr userCacheMgr;
    private UserManager userManager;

    //managing the known containers
    private List<NGPageIndex> allContainers;
    private Hashtable<String, NGPageIndex> keyToSites;
    private Hashtable<String, NGPageIndex> keyToWorkspace;

    //tracking who is online at the moment.
    private List<Visitation> visitationList = new ArrayList<Visitation>();

    // there may be a number of pages that have unsent email, and so this is a
    // list of keys, but there can be extras in this list without problem
    public List<String> workspacesWithEmailToSend = new ArrayList<String>();

    SearchManager searchManager = null;
    private Cognoscenti(ServletContext sc) {
        System.out.println("Weaver Server Object == Constructing");
        rootFolder = new File(sc.getRealPath(""));
    }


    public static Cognoscenti getInstance(ServletContext sc) {
        Cognoscenti cog = (Cognoscenti) sc.getAttribute("cognoscenti");
        if (cog==null) {
            cog = new Cognoscenti(sc);
            sc.setAttribute("cognoscenti", cog);
        }
        return cog;
    }
    public static Cognoscenti getInstance(HttpSession session) {
        return getInstance(session.getServletContext());
    }
    public static Cognoscenti getInstance(HttpServletRequest req) {
        return getInstance(req.getSession());
    }


    /**
     * Starts the background task to initialize the server from config files.
     * Also attempts to initialize immediately.
     * This should be called ONLY ONCE when the server starts the first time.
     * After that, methods on this can pause and restart the server.
     * @param config the ServletConfig from the hosting TomCat server
     * @param resourceBundle the resource bundle from the wrapped servlet
     */
    public static void startTheServer(ServletConfig config) {
System.out.println("   __    __    ___   ____  __ __    ___  ____       ");
System.out.println("  |  |__|  |  /  _] /    ||  |  |  /  _]|    \\      ");
System.out.println("  |  |  |  | /  [_ |  o  ||  |  | /  [_ |  D  )     ");
System.out.println("  |  |  |  ||    _]|     ||  |  ||    _]|    /      ");
System.out.println("  |  `  '  ||   [_ |  _  ||  :  ||   [_ |    \\      ");
System.out.println("   \\      / |     ||  |  | \\   / |     ||  .  \\     ");
System.out.println("    \\_/\\_/  |_____||__|__|  \\_/  |_____||__|\\_|     ");
System.out.println("");

System.out.println("Weaver Server Object == Start the Server");

        //first thing to do is to get the cognoscenti object associated with this app
        ServletContext sc = config.getServletContext();
        cog = Cognoscenti.getInstance(sc);

        //call it directly to initialize (without waiting 30 seconds) if possible
        cog.initializer.run();
    }

    public static void shutDownTheServer() {
        System.out.println("STOP - Cognoscenti shutdown");
        System.err.println("\n=======================\nSTOP - Cognoscenti shutdown");
        cog.initializer.shutDown();
        EmailSender.shutDown();
        EmailListener.shutDown();
    }

    /**
     * For most of the server functions, this is the method to test to
     * see if the server is up, running, and handling requests.
     * When this is false, then only very special administrator requests
     * should be handled.
     */
    public boolean isRunning() {
        return (initializer.serverInitState == ServerInitializer.STATE_RUNNING);
    }
    public boolean isPaused() {
        return (initializer.serverInitState == ServerInitializer.STATE_PAUSED);
    }
    public boolean isFailed() {
        return (initializer.serverInitState == ServerInitializer.STATE_FAILED);
    }
    public void pauseServer() {
        initializer.pauseServer();
    }
    public void resumeServer() {
        initializer.reinitServer();
    }
    public ConfigFile getConfig() {
        return theConfig;
    }
    public UserCacheMgr getUserCacheMgr() {
        return userCacheMgr;
    }
    public UserManager getUserManager() {
        return userManager;
    }


    //TODO: get rid of this static
    public static String getServerGlobalId() {
        return serverId;
    }


    /**
     * Call this in order to erase everything in memory and
     * free up all of the cached values.  Returns the module to
     * uninitialized state.  You  need to reinitialize after this.
     * Useful before calling garbage collect and reinitialize.
     */
    public synchronized void clearAllStaticVariables() {
        System.out.println("Weaver Server Object == clear all static variables");
        NGPageIndex.clearAllStaticVars();
        NGBook.clearAllStaticVars();
        NGPage.clearAllStaticVars();
        NGTerm.clearAllStaticVars();
        SectionDef.clearAllStaticVars();
        UserManager.clearAllStaticVars();
        MicroProfileMgr.clearAllStaticVars();
        AuthDummy.clearStaticVariables();
        isInitialized = false;
        initializingNow = false;
        allContainers = null;
        keyToSites = null;
        keyToWorkspace = null;
        workspacesWithEmailToSend = null;
    }

    /**
     * From the passed in values will initialize the module.
     * @param rootFolder is the root on the installed folder and requires that there
     *        be a file at {rootFolder}/WEB-INF/config.txt
     * @param backgroundTimer is used for all the background activity for
     *        sending and receiving email, passing a null in will disable
     *        email sending and receiving
     * @exception will be thrown if anything in the configuration appears to be incorrect
     */
    public synchronized void initializeAll(Timer backgroundTimer) throws Exception {
        System.out.println("Weaver Server Object == Initialize All");
        try {

            //TODO: reexamine this logic
            if (isInitialized) {
                //NOTE: two or more threads might try to call this at the same time.
                //Method is synchronized which will block threads, but when they get in here,
                //the first thing to do is check if you were initialized while blocked.
                if (rootFolder.equals(theConfig.getFileFromRoot(""))) {
                    //all OK, just return
                    return;
                }
                //was initialized to a different location, clean up that
                System.out.print("Reinitialization: changing from "+theConfig.getFileFromRoot("")
                        +" to "+rootFolder);
                clearAllStaticVariables();
            }

            initializingNow = true;
            theConfig = ConfigFile.initialize(rootFolder);
            theConfig.assertConfigureCorrectInternal();
            workspacesWithEmailToSend = new ArrayList<String>();

            AuthDummy.initializeDummyRequest(this);
            userManager = new UserManager(this);
            userManager.loadUpUserProfilesInMemory(this);
            userCacheMgr = new UserCacheMgr(this);

            NGPageIndex.initAllStaticVars();
            MicroProfileMgr.loadMicroProfilesInMemory(this);
            initIndexOfContainers();
            if (backgroundTimer!=null) {
                EmailSender.initSender(backgroundTimer, this);
                EmailListener.initListener(backgroundTimer, this);
            }

            //make sure that all the workspace references include a site
            userManager.assureSiteAndWorkspace(this);

            serverId = theConfig.getServerGlobalId();
            LightweightAuthServlet.init(theConfig.getProperty("identityProvider"));

            IconServlet.init(theConfig);

            BaseController.initBaseController(this);
            LearningPath.init(this);

            isInitialized = true;
        }
        catch (Exception e) {
            initializer.serverInitState = ServerInitializer.STATE_FAILED;
            initializer.lastFailureMsg = e;
            throw e;
        }
        finally {
            initializingNow = false;
        }
    }


    /**
     * This method must not be called by any method that is used during the
     * actual initialization itself. It is designed to be called by threads that
     * are NOT involved in initialization, in order to cleanly wait for initialization
     * to be completed.  This method will wait for up to 20 seconds
     * for initialization to complete with either a failure or a successful
     * initialization.
     */
    public boolean isInitialized() {
        // if the server is currently actively being initialized, then it if
        // probably worth
        // waiting a few seconds instead of failing
        int countDown = 40;
        while (initializingNow && --countDown > 0) {
            // test every 1/5 second, and wait up to 8 seconds for the
            // server to finish initializing, otherwise give up
            try {
                Thread.sleep(200);
            }
            catch (Exception e) {
                countDown = 0;
                // don't care what the exception is
                // just exit loop if sleep throws exception
            }
        }

        return (isInitialized);
    }
    /**
     * provides compatibility with earlier version that would attempt to
     * initialize on any given page refresh, and throw an exception if it
     * failed. Newer approach is to initialize once, but this will throw the
     * exception anyway if one was found attempting to initialize.
     */
    public void assertInitialized() throws Exception {
        if (!isInitialized()) {
            if (initializer.lastFailureMsg != null) {
                throw WeaverException.newWrap("Weaver server has not initialized correctly", initializer.lastFailureMsg);
            }
            throw WeaverException.newBasic("Weaver server has never been initialized");
        }
    }


    public List<NGPageIndex> getAllContainers() {
        List<NGPageIndex> ret = new ArrayList<NGPageIndex>();
        if (allContainers == null) {
            return ret;
        }
        // if system is not initialized then return an empty vector
        for (NGPageIndex ngpi : allContainers) {
            if (!ngpi.isDeleted) {
                ret.add(ngpi);
            }
        }
        NGPageIndex.sortByName(ret);
        return ret;
    }

    public List<NGPageIndex> getDeletedContainers() {
        List<NGPageIndex> ret = new ArrayList<NGPageIndex>();
        for (NGPageIndex ngpi : allContainers) {
            if (ngpi.isDeleted) {
                ret.add(ngpi);
            }
        }
        return ret;
    }



    public NGPageIndex getSiteByKey(String key) throws Exception {
        assertInitialized();
        if (key == null) {
            // this programming mistake should never happen
            throw WeaverException.newBasic("null value passed as key to getSiteByKey");
        }
        return keyToSites.get(key);
    }

    public NGPageIndex getSiteByKeyOrFail(String key) throws Exception {
        NGPageIndex ngpi = getSiteByKey(key);
        if (ngpi == null) {
            throw WeaverException.newBasic("No site is found with the id %s", key);
        }
        return ngpi;
    }

    public NGPageIndex getWSBySiteAndKey(String siteKey, String key) throws Exception {
        if (siteKey == null) {
            // this programming mistake should never happen
            throw WeaverException.newBasic("null value passed as siteKey to getWorkspaceBySiteAndKey");
        }
        if (key == null) {
            // this programming mistake should never happen
            throw WeaverException.newBasic("null value passed as key to getWorkspaceBySiteAndKey");
        }
        assertInitialized();
        String realKey = siteKey + "|" + key;
        return keyToWorkspace.get(realKey);
    }
    public NGPageIndex getWSBySiteAndKeyOrFail(String siteKey, String key) throws Exception {
        NGPageIndex ngpi = getWSBySiteAndKey(siteKey, key);
        if (ngpi == null) {
            throw WeaverException.newBasic("Unable to find a workspace with the site (%s) and key (%s)", siteKey, key);
        }
        return ngpi;
    }



    /**
     * Combined key is   "site|workspace"
     * That is, the site key, a vertical bar, and the workspace key
     */
    public NGPageIndex getWSByCombinedKey(String combinedKey) throws Exception {
        NGPageIndex ngpi = keyToWorkspace.get(combinedKey);
        if (ngpi != null) {
            return ngpi;
        }

        //did not find it correctly, but maybe this is a legacy link with just the workspace key?
        //we can handle that for the time being.   BUT REMOVE THIS LATER!
        return lookForWSBySimpleKeyOnly(combinedKey);

        //return null;
    }
    public NGPageIndex getWSByCombinedKeyOrFail(String combinedKey) throws Exception {
        NGPageIndex ngpi = getWSByCombinedKey(combinedKey);
        if (ngpi==null) {
            throw WeaverException.newBasic("Unable to find a workspace with the combined key (%s)", combinedKey);
        }
        return ngpi;
    }

    /**
     * Note, the simply workspace key is NOT UNIQUE.
     * This will work only as long as it is, otherwise you might get the
     * wrong key.   This method is meant only as a temporary solution
     * to allow people with old lists of just the workspace, to
     * migrate to the combined keys.
     */
    public NGPageIndex lookForWSBySimpleKeyOnly(String nonUniqueSimpleKey) {
        for (NGPageIndex ngps : allContainers) {
            if (ngps.containerKey.equals(nonUniqueSimpleKey)) {
                return ngps;
            }
        }
        return null;
    }


    /**
     * Finding pages by name means that you might find more than one so you get
     * a vector back, which might be empty, it might have one or it might have
     * more pages.
     */
    public List<NGPageIndex> getPageIndexByName(String pageName) throws Exception {
        assertInitialized();

        NGTerm term = NGTerm.findTerm(pageName);
        if (term == null) {
            throw WeaverException.newBasic("No workspace can be found for %s", pageName);
        }
        return term.targetLeaves;
    }

    public boolean pageExists(String pageName) throws Exception {
        NGTerm term = NGTerm.findTermIfExists(pageName);
        if (term == null) {
            return false;
        }
        return (term.targetLeaves.size() > 0);
    }


    /**
     * This is a convenience function that looks a particular workspace
     * up in the index, finds the index entry, and then IF it is a
     * workspace, returns that with the right type (NGWorkspace).
     * Fails if the key is not matched with anything, or if the key
     * is for a site.
     */
    public NGWorkspace getWorkspaceByKeyOrFail(String siteKey, String key) throws Exception {
        NGPageIndex ngpi = getWSBySiteAndKey(siteKey, key);
        return ngpi.getWorkspace();
    }
    public NGWorkspace findWorkspaceByCombinedKey(String combined) throws Exception {
        NGPageIndex ngpi = getWSByCombinedKey(combined);
        if (ngpi==null) {
            return null;
        }
        return ngpi.getWorkspace();
    }


    public List<NGPageIndex> getAllSites() {
        ArrayList<NGPageIndex> res = new ArrayList<NGPageIndex>();
        for (NGPageIndex ngpi : allContainers) {
            if (!ngpi.isWorkspace()) {
                res.add(ngpi);
            }
        }
        return res;
    }




    /**
     * This is a convenience function that looks a particular site
     * up in the index, finds the index entry, and then IF it is a
     * site, returns that with the right type (NGBook)
     * Fails if the key is not matched with anything, or if the key
     * is for a workspace.
     */
    public NGBook getSiteById(String key) throws Exception {
        NGPageIndex ngpi = getSiteByKey(key);
        if (ngpi==null) {
            return null;
        }
        return ngpi.getSite();
    }
    /**
     * This is a convenience function that looks a particular site
     * up in the index, finds the index entry, and then IF it is a
     * site, returns that with the right type (NGBook)
     * Fails if the key is not matched with anything, or if the key
     * is for a workspace.
     */
    public NGBook getSiteByIdOrFail(String key) throws Exception {
        NGPageIndex ngpi = getSiteByKeyOrFail(key);
        return ngpi.getSite();
    }



    /**
     * Returns a vector of NGPageIndex objects which represent workspaces which
     * are all part of a single site which are not deleted.
     */
    public List<NGPageIndex> getNonDelWorkspacesInSite(String accountKey) throws Exception {
        List<NGPageIndex> ret = new ArrayList<NGPageIndex>();
        for (NGPageIndex ngpi : allContainers) {
            if (!ngpi.isWorkspace()) {
                // only consider workspace style containers
                continue;
            }
            if (ngpi.isDeleted) {
                continue;
            }
            if (!accountKey.equals(ngpi.wsSiteKey)) {
                // only consider if the workspace is in the site we look for
                continue;
            }
            ret.add(ngpi);
        }
        return ret;
    }
    public List<NGPageIndex> getAllWorkspacesInSiteIncludeDeleted(String accountKey) throws Exception {
        List<NGPageIndex> ret = new ArrayList<NGPageIndex>();
        for (NGPageIndex ngpi : allContainers) {
            if (!ngpi.isWorkspace()) {
                // only consider workspace style containers
                continue;
            }
            if (!accountKey.equals(ngpi.wsSiteKey)) {
                // only consider if the workspace is in the site we look for
                continue;
            }
            ret.add(ngpi);
        }
        return ret;
    }

    public List<NGPageIndex> getAllPagesForAdmin(UserProfile user) {
        List<NGPageIndex> ret = new ArrayList<NGPageIndex>();
        for (NGPageIndex ngpi : getAllContainers()) {
            if (!ngpi.isWorkspace()) {
                // only consider workspace style containers
                continue;
            }
            for (String admin : ngpi.admins) {
                if (user.hasAnyId(admin)) {
                    ret.add(ngpi);
                    break;
                }
            }
        }
        return ret;
    }

    public List<NGPageIndex> getWorkspacesUserIsIn(UserProfile ale) throws Exception {
        List<NGPageIndex> ret = new ArrayList<NGPageIndex>();
        String userKey = ale.getKey();
        for (NGPageIndex ngpi : getAllContainers()) {
            if (!ngpi.isWorkspace()) {
                // only consider workspace style containers
                continue;
            }
            if (ngpi.allUsers.contains(userKey)) {
                ret.add(ngpi);
            }
        }
        NGPageIndex.sortByName(ret);
        return ret;
    }


    private synchronized void initIndexOfContainers() throws Exception {
        if (allContainers == null) {
            scanAllPages();
        }
    }

    private synchronized void scanAllPages() throws Exception {
        System.out.println("Beginning SCAN for all pages in system");
        List<File> allWorkspaceFiles = new ArrayList<File>();
        NGTerm.initialize();
        keyToSites = new Hashtable<String, NGPageIndex>();
        keyToWorkspace = new Hashtable<String, NGPageIndex>();
        allContainers = new ArrayList<NGPageIndex>();

        //TODO: eliminate statics, put them as members of this Cognoscenti class!
        NGBook.initStaticVars();

        List<File> allSiteFiles = new ArrayList<File>();
        for (File libDirectory : theConfig.getSiteFolders()) {
            seekSitesAndWorkspaces(libDirectory, allWorkspaceFiles, allSiteFiles);
        }

        // now process the site files if any
        for (File aSitePath : allSiteFiles) {
            try {
                NGBook ngb = NGBook.readSiteAbsolutePath(this, aSitePath);
                NGBook.registerSite(ngb);
                makeIndexForSite(ngb);
            }
            catch (Exception eig) {
                reportUnparseableFile(aSitePath, eig);
            }
        }
        // now process the workspace files if any
        for (File aProjPath : allWorkspaceFiles) {
            try {
                NGWorkspace aProj = NGWorkspace.readWorkspaceAbsolutePath(aProjPath);
                boolean changed = aProj.convertOldRoleDefinitions(this);
                makeIndexForWorkspace(aProj);
                if (changed) {
                    aProj.save();
                }
            }
            catch (Exception eig) {
                reportUnparseableFile(aProjPath, eig);
            }
        }
        System.out.println("Concluded SCAN for all pages in system.");
    }



    private void reportUnparseableFile(File badFile, Exception eig) {
        AuthRequest dummy = AuthDummy.serverBackgroundRequest();
        Exception wrapper = new Exception("Failure reading file during Initialization: "
                + badFile.toString(), eig);
        dummy.logException("Initialization Loop Continuing After Failure", wrapper);
    }

    /**
     * Sept 2017 change this algorithm.  the sites must be children of the
     * library file folders pased in, and only direct children.
     *
     * Then the workspaces can only be the direct chidlren of sites.
     *
     * A workspace found in a site is automatically associated with that site.
     *
     * @param folder
     * @param allWorkspaces
     * @param allSites
     * @throws Exception
     */
    private void seekSitesAndWorkspaces(File folder, List<File> allWorkspaces, List<File> allSites)
            throws Exception {

        for (File child : folder.listFiles()) {
            if (!child.isDirectory()) {
                //skip any files in the library folder
                continue;
            }

            File cogFolder = new File(child, ".cog");
            if (!cogFolder.exists()) {
                continue;
            }
            File siteFile = new File(cogFolder, "SiteInfo.xml");
            if (!siteFile.exists()) {
                continue;
            }
            allSites.add(siteFile);
            seekAllWorkspaces(child, allWorkspaces);
        }
    }

    private void seekAllWorkspaces(File siteFolder, List<File> allWorkspaces) throws Exception {
        for (File child : siteFolder.listFiles()) {
            if (!child.isDirectory()) {
                //ignore all files in the site folder
                continue;
            }
            File cogFolder = new File(child, ".cog");
            if (!cogFolder.exists()) {
                continue;
            }
            File workspaceFile = new File(cogFolder, "ProjInfo.xml");
            if (!workspaceFile.exists()) {
                continue;
            }
            allWorkspaces.add(workspaceFile);
        }
    }

    public void makeIndexForSite(NGBook ngb) throws Exception {
        String key = ngb.getKey();

        // clean up old index entries using old name
        NGPageIndex foundPage = keyToSites.get(key);
        if (foundPage != null) {
            foundPage.unlinkAll();
            allContainers.remove(foundPage);
            keyToSites.remove(foundPage.containerKey);
        }

        NGPageIndex bIndex = new NGPageIndex(ngb);
        if (bIndex.containerType == 0) {
            throw WeaverException.newBasic("uninitialized ngpi.containerType in makeIndex");
        }
        allContainers.add(bIndex);
        keyToSites.put(key, bIndex);
    }

    /**
     * When a site is physically removed from the disk, this method must be
     * called to make it disappear from the running index in memory.
     */
    public void eliminateIndexForSite(NGBook site) throws Exception {
        String key = site.getKey();
        NGPageIndex foundPage = keyToSites.get(key);
        if (foundPage != null) {
            keyToSites.remove(key);
        }
        ArrayList<NGPageIndex> cleanList = new ArrayList<NGPageIndex>();
        for (NGPageIndex ngpi : allContainers) {
            if (ngpi.containerKey.equals(key)) {
                foundPage.unlinkAll();
                System.out.println("Site removed from index: "+key);
            }
            else {
                cleanList.add(ngpi);
            }
        }
        allContainers = cleanList;
        NGBook.unregisterSite(key);
    }

    public void makeIndexForWorkspace(NGWorkspace ngw) throws Exception {
        String key = ngw.getKey();
        String workspaceKey = ngw.getSiteKey() + "|" + key;

        // clean up old index entries using old name
        NGPageIndex foundPage = keyToWorkspace.get(workspaceKey);
        if (foundPage != null) {
            foundPage.unlinkAll();
            allContainers.remove(foundPage);
            keyToWorkspace.remove(workspaceKey);
        }

        NGPageIndex bIndex = new NGPageIndex(ngw);
        if (bIndex.containerType == 0) {
            throw WeaverException.newBasic("uninitialized ngpi.containerType in makeIndex");
        }
        allContainers.add(bIndex);
        keyToWorkspace.put(workspaceKey, bIndex);
    }

    public void eliminateIndexForWorkspace(NGWorkspace ngw) {
        String key = ngw.getKey();
        String workspaceKey = ngw.getSiteKey() + "|" + key;

        // clean up old index entries using old name
        NGPageIndex foundPage = keyToWorkspace.get(workspaceKey);
        if (foundPage != null) {
            foundPage.unlinkAll();
            allContainers.remove(foundPage);
            keyToWorkspace.remove(workspaceKey);
        }
    }

    /**
     * Get the first page that has email that still needs to be sent Returns
     * null if there are not any
     */
    public String getPageWithEmailToSend() throws Exception {
        if (workspacesWithEmailToSend.size() == 0) {
            return null;
        }
        return workspacesWithEmailToSend.get(0);
    }

    /**
     * When you find that a workspace does not have any more email to send,
     * call removePageFromEmailToSend to remove from the cached list.
     */
    public void removePageFromEmailToSend(String key) {
        workspacesWithEmailToSend.remove(key);
    }

    public void reinitializeServer(ServletConfig config) {
        clearAllStaticVariables();
        initializer.initializeState();
        isInitialized = false;
        initializingNow = false;
        startTheServer(config);
    }

    public synchronized List<SearchResultRecord> performSearch(AuthRequest ar,
            String queryStr, String relationship, String siteId, String workspaceId) throws Exception {
        if (searchManager==null) {
            searchManager = new SearchManager(this);
        }
        return searchManager.performSearch(ar, queryStr, relationship, siteId, workspaceId);
    }

    public synchronized void recordVisit(String userKey, String site, String workspace, long timestamp) {
        visitationList = Visitation.markVisit(visitationList, userKey, site, workspace, timestamp);
    }
    public List<String> whoIsVisiting(String site, String workspace) {
        return Visitation.getCurrentUsers(visitationList, site, workspace);
    }
    public Set<String> whoIsLoggedIn() {
        return Visitation.getGlobalUsers(visitationList);
    }
    public long getVisitTime(String uid) {
        Visitation visit = Visitation.getRecentVisit(visitationList, uid);
        return visit.timestamp;
    }
    public String getVisitWorkspace(String uid) {
        Visitation visit = Visitation.getRecentVisit(visitationList, uid);
        return visit.workspace;
    }
    public String getVisitSite(String uid) {
        Visitation visit = Visitation.getRecentVisit(visitationList, uid);
        return visit.site;
    }


    public NGPageIndex getParentWorkspace(NGPageIndex child) throws Exception {
        if (!child.isWorkspace()) {
            throw WeaverException.newBasic("You can only get a parent of a workspace, but this is not workspace: %s", child.containerKey);
        }
        String searchKey = child.parentKey;
        if (searchKey == null || searchKey.length()==0) {
            return null;
        }
        String siteKey = child.wsSiteKey;
        if (siteKey == null || siteKey.length()==0) {
            throw WeaverException.newBasic("Can not get parent of a workspace is not in a site: %s", child.containerKey);
        }
        if (searchKey != null && searchKey.length()>0) {
            for (NGPageIndex ngpi : this.allContainers) {
                if (ngpi.containerKey.equals(searchKey) && siteKey.equals(ngpi.wsSiteKey)) {
                    return ngpi;
                }
            }
        }
        return null;
    }
    public List<NGPageIndex> getChildWorkspaces(NGPageIndex parent) throws Exception {
        if (!parent.isWorkspace()) {
            throw WeaverException.newBasic("You can only get children of a workspace, but this is not workspace: %s", parent.containerKey);
        }
        List<NGPageIndex> res = new ArrayList<NGPageIndex>();
        String searchKey = parent.containerKey;
        String siteKey = parent.wsSiteKey;
        if (siteKey == null || siteKey.length()==0) {
            throw WeaverException.newBasic("Can not get children of a workspace that is not in a site: %s", parent.containerKey);
        }
        for (NGPageIndex ngpi : this.allContainers) {
            if (searchKey.equals(ngpi.parentKey) && siteKey.equals(ngpi.wsSiteKey)) {
                res.add(ngpi);
            }
        }
        return res;
    }


    private static long lastTimeValue = System.currentTimeMillis();
    /**
     * This returns the current time EXCEPT it guarantees
     * that it never returns the same time twice, incrementing
     * the time if necessary by a few milliseconds to achieve this.
     */
    public static synchronized long getUniqueTime() {
        long newTime = System.currentTimeMillis();
        if (newTime<=lastTimeValue) {
            newTime = lastTimeValue+1;
        }
        lastTimeValue = newTime;
        return newTime;
    }

}
