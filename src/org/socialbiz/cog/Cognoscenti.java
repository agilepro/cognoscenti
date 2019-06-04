package org.socialbiz.cog;

import java.io.File;
import java.util.ArrayList;
import java.util.Hashtable;
import java.util.List;
import java.util.Timer;

import javax.servlet.ServletConfig;
import javax.servlet.ServletContext;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;

import org.socialbiz.cog.api.LightweightAuthServlet;
import org.socialbiz.cog.dms.FolderAccessHelper;
import org.socialbiz.cog.exception.NGException;
import org.socialbiz.cog.exception.ProgramLogicError;
import org.socialbiz.cog.mail.EmailSender;
import org.socialbiz.cog.rest.ServerInitializer;
import org.socialbiz.cog.spring.BaseController;

/**
 * This is the main class for the Cognoscenti object package.
 * This is a singleton pattern, and holds all the root configuration information.
 * Stores itself as an attribute on the servlet context
 * Use this class for initialization and accessing
 * the main index to objects within Cognoscenti
 *
 */
public class Cognoscenti {


    public ServerInitializer initializer = null;

    public Exception lastFailureMsg = null;
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
    private Hashtable<String, NGPageIndex> upstreamToContainer;

    //tracking who is online at the moment.
    private List<Visitation> visitationList = new ArrayList<Visitation>();

    // there may be a number of pages that have unsent email, and so this is a
    // list of keys, but there can be extras in this list without problem
    public List<String> projectsWithEmailToSend = new ArrayList<String>();

    SearchManager searchManager = null;
    private long searchIndexBuildtime = 0;

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
        Cognoscenti cog = Cognoscenti.getInstance(sc);

        if (cog.initializer != null) {
            //report this, but otherwise ignore it.  Not bad enough to throw exception.
            System.out.println("Somthing wrong, the server is being initialized when it already has an initializer!");
        }

        cog.initializer = new ServerInitializer(cog);

        //call it directly to initialize (without waiting 30 seconds) if possible
        cog.initializer.run();
    }



    /**
     * For most of the server functions, this is the method to test to
     * see if the server is up, running, and handling requests.
     * When this is false, then only very special administrator requests
     * should be handled.
     */
    public boolean isRunning() {
        return (initializer!=null && initializer.serverInitState == ServerInitializer.STATE_RUNNING);
    }
    public boolean isPaused() {
        return (initializer!=null && initializer.serverInitState == ServerInitializer.STATE_PAUSED);
    }
    public boolean isFailed() {
        return (initializer!=null && initializer.serverInitState == ServerInitializer.STATE_FAILED);
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
        upstreamToContainer = null;
        projectsWithEmailToSend = null;
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
            projectsWithEmailToSend = new ArrayList<String>();

            AuthDummy.initializeDummyRequest(this);
            userManager = new UserManager(this);
            userManager.loadUpUserProfilesInMemory(this);
            userCacheMgr = new UserCacheMgr(this);

            NGPageIndex.initAllStaticVars();
            MicroProfileMgr.loadMicroProfilesInMemory(this);
            initIndexOfContainers();
            if (backgroundTimer!=null) {
                EmailSender.initSender(backgroundTimer, this);
                //SendEmailTimerTask.initEmailSender(backgroundTimer, this);
                EmailListener.initListener(backgroundTimer);
            }

            FolderAccessHelper.initLocalConnections(this);
            FolderAccessHelper.initCVSConnections(this);
            serverId = theConfig.getServerGlobalId();
            LightweightAuthServlet.init(theConfig.getProperty("identityProvider"));

            BaseController.initBaseController(this);
            isInitialized = true;
        }
        catch (Exception e) {
            lastFailureMsg = e;
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
            if (lastFailureMsg != null) {
                throw new NGException("nugen.exception.sys.not.initialize.correctly", null, lastFailureMsg);
            }
            throw new ProgramLogicError("NGPageIndex has never been initialized");
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
            throw new ProgramLogicError("null value passed as key to getSiteByKey");
        }
        return keyToSites.get(key);
    }

    public NGPageIndex getSiteByKeyOrFail(String key) throws Exception {
        NGPageIndex ngpi = getSiteByKey(key);
        if (ngpi == null) {
            throw new NGException("nugen.exception.container.not.found", new Object[] { key });
        }
        return ngpi;
    }

    public NGPageIndex getWSBySiteAndKey(String siteKey, String key) throws Exception {
        if (siteKey == null) {
            // this programming mistake should never happen
            throw new ProgramLogicError("null value passed as siteKey to getWorkspaceBySiteAndKey");
        }
        if (key == null) {
            // this programming mistake should never happen
            throw new ProgramLogicError("null value passed as key to getWorkspaceBySiteAndKey");
        }
        assertInitialized();
        String realKey = siteKey + "|" + key;
        return keyToWorkspace.get(realKey);
    }
    public NGPageIndex getWSBySiteAndKeyOrFail(String siteKey, String key) throws Exception {
        NGPageIndex ngpi = getWSBySiteAndKey(siteKey, key);
        if (ngpi == null) {
            throw new Exception("Unable to find a workspace with the site ("+siteKey+") and key ("+key+")");
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

        //did not find it correctly, but maybe this is a legacy link with just the project key?
        //we can handle that for the time being.   BUT REMOVE THIS LATER!
        return lookForWSBySimpleKeyOnly(combinedKey);

        //return null;
    }
    public NGPageIndex getWSByCombinedKeyOrFail(String combinedKey) throws Exception {
        NGPageIndex ngpi = getWSByCombinedKey(combinedKey);
        if (ngpi==null) {
            throw new Exception("Unable to find a workspace with the combined key ("+combinedKey+")");
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
            throw new NGException("nugen.exception.key.dont.have.alphanum", null);
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
     * project, returns that with the right type (NGPage).
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
            if (!ngpi.isProject()) {
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
     * is for a project.
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
     * is for a project.
     */
    public NGBook getSiteByIdOrFail(String key) throws Exception {
        NGPageIndex ngpi = getSiteByKeyOrFail(key);
        return ngpi.getSite();
    }



    /**
     * Returns a vector of NGPageIndex objects which represent projects which
     * are all part of a single site. Should be called get all projects in site
     */
    public List<NGPageIndex> getAllProjectsInSite(String accountKey) throws Exception {
        List<NGPageIndex> ret = new ArrayList<NGPageIndex>();
        for (NGPageIndex ngpi : getAllContainers()) {
            if (!ngpi.isProject()) {
                // only consider book/project style containers
                continue;
            }
            if (!accountKey.equals(ngpi.wsSiteKey)) {
                // only consider if the project is in the site we look for
                continue;
            }
            ret.add(ngpi);
        }
        return ret;
    }

    public List<NGPageIndex> getAllPagesForAdmin(UserProfile user) {
        List<NGPageIndex> ret = new ArrayList<NGPageIndex>();
        for (NGPageIndex ngpi : getAllContainers()) {
            if (!ngpi.isProject()) {
                // only consider project style containers
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

    public List<NGPageIndex> getProjectsUserIsPartOf(UserRef ale) throws Exception {
        List<NGPageIndex> ret = new ArrayList<NGPageIndex>();
        for (NGPageIndex ngpi : getAllContainers()) {
            if (!ngpi.isProject()) {
                // only consider project style containers
                continue;
            }
            NGWorkspace container = ngpi.getWorkspace();

            for (CustomRole role : container.getAllRoles()) {
                if (role.isPlayer(ale)) {
                    ret.add(ngpi);
                    break;
                }
            }
        }
        NGPageIndex.sortByName(ret);
        return ret;
    }

    public NGWorkspace getWorkspaceByUpstreamLink(String upstream) throws Exception {
        if (upstream==null || upstream.length()==0) {
            return null;
        }
        int lastSlash = upstream.lastIndexOf("/");
        if (lastSlash<10) {
            throw new Exception("upstream value was passed that does not look like a URL: "+upstream);
        }
        NGPageIndex ngpi = upstreamToContainer.get(upstream.substring(0,lastSlash+1));
        if (ngpi != null) {
            return ngpi.getWorkspace();
        }
        return null;
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
        upstreamToContainer = new Hashtable<String, NGPageIndex>();
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
                NGBook ngb = NGBook.readSiteAbsolutePath(aSitePath);
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
                makeIndexForWorkspace(aProj);
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
            throw new Exception("uninitialized ngpi.containerType in makeIndex");
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
            throw new Exception("uninitialized ngpi.containerType in makeIndex");
        }
        allContainers.add(bIndex);
        keyToWorkspace.put(workspaceKey, bIndex);

        //special upstream link handling
        String upstream = ngw.getUpstreamLink();
        if (upstream!=null && upstream.length()>0) {
            int lastSlash = upstream.lastIndexOf("/");
            upstreamToContainer.put(upstream.substring(0,lastSlash+1), bIndex);
        }

        // look for email and remember if there is some
        if (ngw.countEmailToSend() > 0) {
            projectsWithEmailToSend.add(key);
        }
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
        if (projectsWithEmailToSend.size() == 0) {
            return null;
        }
        return projectsWithEmailToSend.get(0);
    }

    /**
     * When you find that a project does not have any more email to send,
     * call removePageFromEmailToSend to remove from the cached list.
     */
    public void removePageFromEmailToSend(String key) {
        projectsWithEmailToSend.remove(key);
    }

    public void reinitializeServer(ServletConfig config) {
        clearAllStaticVariables();
        initializer = null;
        lastFailureMsg = null;
        isInitialized = false;
        initializingNow = false;
        startTheServer(config);
    }

    public synchronized List<SearchResultRecord> performSearch(AuthRequest ar,
            String queryStr, String relationship, String siteId) throws Exception {
        if (searchManager==null) {
            searchManager = new SearchManager(this);
        }
        //if it has not been built this hour, rebuild
        if (searchIndexBuildtime < System.currentTimeMillis()- (60 * 60 * 1000)) {
            searchManager.initializeIndex();
            searchIndexBuildtime = System.currentTimeMillis();
        }
        return searchManager.performSearch(ar, queryStr, relationship, siteId);
    }

    public synchronized void recordVisit(String userKey, String site, String workspace, long timestamp) {
        visitationList = Visitation.markVisit(visitationList, userKey, site, workspace, timestamp);
    }
    public List<String> whoIsVisiting(String site, String workspace) {
        return Visitation.getCurrentUsers(visitationList, site, workspace);
    }

}
