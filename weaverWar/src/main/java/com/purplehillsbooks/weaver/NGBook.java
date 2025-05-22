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
import java.util.ArrayList;
import java.util.HashSet;
import java.util.Hashtable;
import java.util.List;
import java.util.Set;

import com.purplehillsbooks.weaver.exception.WeaverException;
import com.purplehillsbooks.weaver.mail.EmailSender;
import org.w3c.dom.Document;

import com.purplehillsbooks.json.JSONArray;
import com.purplehillsbooks.json.JSONObject;
import com.purplehillsbooks.streams.MemFile;

/**
 * An site is a collection of pages. This allows a collection of pages to share
 * a single set of members, and a particular look and feel. For archaic reasons
 * called NGBook, should be NGSite
 */
public class NGBook extends ContainerCommon {
    public String key;
    // The following are the indices which are used by book finding and
    // reading. Initialized by scanAllBooks() method.
    private static Hashtable<String, NGBook> keyToSite = null;
    private static List<NGBook> allSites = null;

    private List<String> existingIds = null;
    private String displayName;
    private final SiteInfoRecord siteInfoRec;
    private final NGRole executiveRole;
    private final NGRole ownerRole;

    private List<AddressListEntry> allUserList;
    private RoleDefinitionFile roleDefinitionFile;

    //this is the file system folder where site exists
    //workspaces are underneath this folder
    private File siteFolder = null;
    private Cognoscenti cog;

    public NGBook(File theFile, Document newDoc, Cognoscenti _cog) throws Exception {
        super(theFile, newDoc);
        cog = _cog;
        siteInfoRec = requireChild("bookInfo", SiteInfoRecord.class);
        displayName = siteInfoRec.getSiteName();
        assureNameExists();

        String fileName = theFile.getName();
        if (fileName.equalsIgnoreCase("SiteInfo.xml")) {
            File cogFolder = theFile.getParentFile();
            siteFolder = cogFolder.getParentFile();
        }
        else {
            throw WeaverException.newBasic("Unable to open site file with path: %s", theFile);
        }

        // migration code, make sure there is a stored value for key
        key = siteInfoRec.getScalar("key");
        if (key == null || key.length() == 0) {
            if (siteFolder!=null) {
                key = SectionUtil.sanitize(siteFolder.getName());
                siteInfoRec.setScalar("key", key);
            }
            else if (fileName.endsWith(".book") || fileName.endsWith(".site")) {
                key = fileName.substring(0, fileName.length() - 5);
                siteInfoRec.setScalar("key", key);
            }
            else {
                throw WeaverException.newBasic("Site is missing key, and unable to generate one: %s", 
                        theFile.getAbsolutePath());
            }
        }
        System.out.println("Cached site (" + key + ") from : " + theFile);


        requireChild("process", DOMFace.class);

        executiveRole = getRequiredRole("Executives");
        ownerRole = getRequiredRole("Owners");

        assureColorsExist();
        
        if (getWorkspaceLimit()<4) {
            setWorkspacelimit(4);
        }
        getAllRoleDefs(_cog);
    }

    private void assureNameExists() {
        if (displayName == null || displayName.length()==0) {
            displayName = key;
        }
    }
    private void assureColorsExist() {
        List<String> foundColors = siteInfoRec.getVector("labelColors");
        if (foundColors.size()==0) {
            foundColors.add("Gold");
            foundColors.add("Yellow");
            foundColors.add("CornSilk");
            foundColors.add("PaleGreen");
            foundColors.add("Orange");
            foundColors.add("Bisque");
            foundColors.add("Coral");
            foundColors.add("LightSteelBlue");
            foundColors.add("Aqua");
            foundColors.add("Thistle");
            foundColors.add("Pink");
            siteInfoRec.setVector("labelColors", foundColors);
        }
    }


    public void schemaUpgrade(int fromLevel, int toLevel) throws Exception {
        if (fromLevel<13) {
            // we don't care, there are not and that old, 
            // the schema version will be set when saved.
        }
    }
    public int currentSchemaVersion() {
        return 13;
    }


    public static NGBook readSiteByKey(String key) throws Exception {
        if (keyToSite == null) {
            // this should never happen, but if it does....
            throw WeaverException.newBasic("in readSiteByKey called before the site index initialzed.");
        }
        if (key == null) {
            throw WeaverException.newBasic("Program Logic Error: Site key of null is no longer allowed.");
        }

        NGBook retVal = keyToSite.get(key);
        if (retVal == null) {
            throw WeaverException.newBasic("Unable to find a book with the key %s", key);
        }
        return retVal;
    }

    /**
     * Designed primarily for testing, this throws the current cached copy away
     * and re-reads the file from disk, picking up any changes on the disk
     */
    public static NGBook forceRereadSiteFile(String key, Cognoscenti cog) throws Exception {
        if (keyToSite == null) {
            // this should never happen, but if it does....
            throw WeaverException.newBasic("in readSiteByKey called before the site index initialzed.");
        }
        if (key == null) {
            throw WeaverException.newBasic("Program Logic Error: Site key of null is no longer allowed.");
        }

        NGBook site = keyToSite.get(key);
        if (site == null) {
            throw WeaverException.newBasic("Unable to find a book with the key %s", key);
        }
        File siteFile = site.getFilePath();
        if (siteFile==null) {
            throw WeaverException.newBasic("Site does not have a file???");
        }
        //throw it out of the cache
        unregisterSite(key);
        site = NGBook.readSiteAbsolutePath(cog, siteFile);
        registerSite(site);
        return site;
    }


    public static NGBook readSiteAbsolutePath(Cognoscenti cog, File theFile) throws Exception {
        try {
            if (!theFile.exists()) {
                throw WeaverException.newBasic("The file '%s' does not exist, so it can not be read.", theFile.getAbsolutePath());
            }
            Document newDoc = readOrCreateFile(theFile, "book");
            NGBook newSite = new NGBook(theFile, newDoc, cog);

            //now fix up the site settings
            File cogFolder = theFile.getParentFile();
            File siteFolder = cogFolder.getParentFile();
            String siteKey = siteFolder.getName();
            if (!siteKey.equals(newSite.getKey())) {
                System.out.println("Site ("+siteKey+") != ("+newSite.getKey()+") FIXING UP site "+theFile);
                newSite.setKey(siteKey);
                System.out.println("        Site now ("+newSite.getKey()+") ");
            }
            return newSite;
        }
        catch (Exception e) {
            throw WeaverException.newWrap("Unable to read the file %s", e,
                    theFile.getAbsolutePath());
        }
    }

    public static List<NGBook> getAllSites() {
        // might do a copy here if we fear that the receiver will corrupt this
        // vector
        if (allSites!=null) {
            return allSites;
        }

        //never return a null when the return value is a collection
        return new ArrayList<NGBook>();
    }

    public static void registerSite(NGBook foundSite) throws Exception {
        if (allSites==null) {
            throw WeaverException.newBasic("Can not register a site when the NGBook class has not completed initialization.  (allSites is null)");
        }
        if (keyToSite==null) {
            throw WeaverException.newBasic("Can not register a site when the NGBook class has not completed initialization.  (keyToSite is null)");
        }
        allSites.add(foundSite);
        keyToSite.put(foundSite.getKey(), foundSite);
    }

    /**
     * Erase the memory of a particular site
     * Used when deleting a site
     */
    public static void unregisterSite(String siteKey) throws Exception {
        if (allSites==null) {
            throw WeaverException.newBasic("Can not unregister a site when the NGBook class has not completed initialization.  (allSites is null)");
        }
        if (keyToSite==null) {
            throw WeaverException.newBasic("Can not unregister a site when the NGBook class has not completed initialization.  (keyToSite is null)");
        }
        NGBook fSite = keyToSite.get(siteKey);
        if (fSite!=null) {
            allSites.remove(fSite);
            keyToSite.remove(siteKey);
        }
    }


    @Override
    public String getKey() {
        return key;
    }

    public String getDescription() {
        String ss = getScalar("description");
        if (ss == null) {
            return "";
        }
        return ss;
    }

    public void setDescription(String newDescr) {
        setScalar("description", newDescr.trim());
    }

    /**
     * Set all static values back to their initial states, so that garbage
     * collection can be done, and subsequently, the class will be
     * reinitialized.
     */
    public synchronized static void clearAllStaticVars() {
        keyToSite = null;
        allSites = null;
    }

    //TODO:get rid of statics, put them into the Cognoscenti object
    public synchronized static void initStaticVars() {
        keyToSite = new Hashtable<String, NGBook>();
        allSites = new ArrayList<NGBook>();
    }

    public static NGBook createNewSite(String key, String name, Cognoscenti cog) throws Exception {
        // where is the site going to go?
        List<File> allSiteFiles = cog.getConfig().getSiteFolders();

        File domFolder = allSiteFiles.get(0);
        if (!domFolder.exists()) {
            throw WeaverException.newBasic(
                    "Config setting 'libFolder' is not correct, first value must be an existing folder: (%s)",
                    domFolder);
        }
        File newSiteFolder = new File(domFolder, key);
        if (newSiteFolder.exists()) {
            throw WeaverException.newBasic("Can't create site because folder already exists: (%s)",
                    newSiteFolder);
        }
        newSiteFolder.mkdirs();

        File cogFolder = new File(newSiteFolder, ".cog");
        cogFolder.mkdirs();

        File theFile = new File(cogFolder, "SiteInfo.xml");
        if (theFile.exists()) {
            throw WeaverException.newBasic("Unable to create new site, a site with ID (%s) already exists.", key);
        }

        Document newDoc = readOrCreateFile(theFile, "book");
        NGBook newSite = new NGBook(theFile, newDoc, cog);

        // set default value
        newSite.setContainerName(name);

        registerSite(newSite);
        return newSite;
    }

    /**
     * Note: this is a powerful method.  There is no undo from this.
     * The site folder, and all containing files are deleted.
     * You should destroy all projects contained in the site
     * before calling this.
     */
    public static void destroySiteAndAllWorkspaces(NGBook site, Cognoscenti cog) throws Exception {

        for (NGPageIndex ngpi : cog.getNonDelWorkspacesInSite(site.getKey())) {
            //for now, just avoid the project with projects.
            throw WeaverException.newBasic("Remove all the projects from site '%s' before trying to destroy it: %s", site.getKey(), ngpi.containerKey);
        }

        File siteFolder = site.getSiteRootFolder();
        if (siteFolder==null) {
            throw WeaverException.newBasic("Something is wrong, the site folder is null");
        }
        if (!siteFolder.exists()) {
            throw WeaverException.newBasic("Something is wrong, the parent of the site folder does not exist: %s",
                       siteFolder.getAbsolutePath());
        }

        File parent = siteFolder.getParentFile();
        if (parent==null || !parent.exists()) {
            throw WeaverException.newBasic("Something is wrong, the parent of the site folder does not exist: %s",
                       siteFolder.toString());
        }

        //be extra careful that this parent is the expected parent, don't delete anything otherwise
        if (!NGBook.isLibFolder(parent, cog)) {
            throw WeaverException.newBasic("Something is wrong, the parent of the site folder is not configured as valid library folder: %s",
                      siteFolder.toString());
        }

        //so now everything looks OK, delete the folder for the project
        NGBook.unregisterSite(site.getKey());
        recursivelyDestroyFolder(siteFolder);
    }

    private static void recursivelyDestroyFolder(File folder) throws Exception  {
        if (!folder.exists()) {
            return;
        }

        //listFiles will return a null if it is empty!
        if (folder.isDirectory()) {
            File[] children = folder.listFiles();
            if (children!=null) {
                for (File child : children) {
                    recursivelyDestroyFolder(child);
                }
            }
        }

        if (!folder.delete()) {
            throw WeaverException.newBasic("Unable to delete folder: %s", folder.getAbsolutePath());
        }
    }



    /**
     * Tests a passed in folder to verify that it is a valid lib folder
     */
    public static boolean isLibFolder(File folder, Cognoscenti cog) throws Exception {
        // where is the site going to go?
        List<String> libFolders = cog.getConfig().getArrayProperty("libFolder");
        if (libFolders.size() == 0) {
            throw WeaverException.newBasic("You must have a setting for 'libFolder' in order to create a new site.");
        }

        for (String oneLib : libFolders) {

            File oneFolder = new File(oneLib);
            if (oneFolder.equals(folder)) {
                return true;
            }
        }
        return false;
    }


    public void setKey(String newKey) {
        key = newKey.trim();
        setScalar("key", key);
    }

    /**
     * Walk through whatever elements this owns and put all the four digit IDs
     * into the vector so that we can generate another ID and assure it does not
     * duplication any id found here.
     */
    public void findIDs(List<String> v) throws Exception {
        // no objects with IDs
    }

    @Override
    public String getUniqueOnPage() throws Exception {
        if (existingIds == null) {
            existingIds = new ArrayList<String>();
            findIDs(existingIds);
        }
        return IdGenerator.generateFourDigit(existingIds);
    }

    @Override
    public String getFullName() {
        return displayName;
    }


    public int getWorkspaceLimit() {
        return siteInfoRec.getAttributeInt("workspaceLimit");
    }
    public void setWorkspacelimit(int limit) {
        siteInfoRec.setAttributeInt("workspaceLimit", limit);
    }
    public int countUnfrozenWorkspaces() throws Exception {
        int unfrozenCount = 0;
        for (NGPageIndex aWorkspace : cog.getNonDelWorkspacesInSite(getKey())) {
            if (aWorkspace.isFrozen() || aWorkspace.isDeleted()) {
                continue;
            }
            unfrozenCount++;
        }
        return unfrozenCount;
    }
    
    // ////////////////// ROLES /////////////////////////

    @Override
    public NGRole getPrimaryRole() {
        return executiveRole;
    }

    @Override
    public NGRole getSecondaryRole() {
        return ownerRole;
    }


    @Override
    protected DOMFace getRoleParent() throws Exception {
        return requireChild("roleList", DOMFace.class);
    }

    @Override
    protected DOMFace getInfoParent() throws Exception {
        return siteInfoRec;
    }

    // ////////////////// NOTES /////////////////////////

    public void setLastModify(AuthRequest ar) throws Exception {
        ar.assertLoggedIn("Must be logged in in order to modify site.");
        siteInfoRec.setModTime(ar.nowTime);
        siteInfoRec.setModUser(ar.getBestUserId());
    }

    //Override
    public void saveFile(AuthRequest ar, String comment) throws Exception {
        try {
            setLastModify(ar);
            save();
        }
        catch (Exception e) {
            throw WeaverException.newWrap("Unable to write the site file to '%s'.",
                    e, getFilePath().getAbsolutePath());
        }
    }

    //override
    public void saveModifiedSite(AuthRequest ar, String comment) throws Exception {
        saveFile(ar, comment);
    }

    @Override
    public String getContainerName() {
        return displayName;
    }


    private void setContainerName(String newName) {
        if (newName==null) {
            throw new RuntimeException("setContainerName was passed a null string");
        }
        newName = newName.trim();
        if (newName.length()<1) {
            throw new RuntimeException("setContainerName was passed a zero length string");
        }
        siteInfoRec.setSiteName(newName);
        displayName = siteInfoRec.getSiteName();
        assureNameExists();
    }


    @Override
    public long getLastModifyTime() throws Exception {
        return siteInfoRec.getModTime();
    }

    @Override
    public boolean isDeleted() {
        return siteInfoRec.getAttributeBool("isDeleted");
    }


    public void changeVisibility(String oid, AuthRequest ar) throws Exception {
        throw WeaverException.newBasic("Can not change the visibility of a note on a book, because there are no notes on books");
    }





    /**
     * This is the path to a folder (on disk) that new projects should be
     * created in for this site. Not all projects will actually be there because
     * older ones may have been created elsewhere, or moved, but new ones
     * created there. If this has a value, then a new folder is created inside
     * this one for the project.
     * Modern sites have a folder on disk, and all the projects are inside that
     * folder. If this site has such a folder, return it, otherwise, return null
     */
    public File getSiteRootFolder() {
        return siteFolder;
    }

    /**
     * Just a security measure, if given a path on the file system this check
     * quickly to see if the path is a valid folder within the file system.
     */
    public boolean isPathInSite(File testPath) throws Exception {
        File siteRoot = getSiteRootFolder();
        if (siteRoot == null) {
            // if no preferred location, then site has no root, and always false
            return false;
        }
        String rootPath = siteRoot.getCanonicalPath();
        String testStr = testPath.getCanonicalPath();
        return (testStr.startsWith(rootPath));
    }

    /**
     * Given a new project with a key 'p', this will return the File for the new
     * project file (which does not exist yet). There are two methods:
     *
     * a new workspace folder is created in the site folder, as long as one does not already exist.
     */
    private File newWorkspaceFolderOrFail(String workspaceKey) throws Exception {
        File rootFolder = getSiteRootFolder();
        if (rootFolder == null) {
            throw WeaverException.newBasic("Site Root folder is missing from configuration");
        }
        File newFolder = new File(rootFolder, workspaceKey);
        if (newFolder.exists()) {
            throw WeaverException.newBasic("Can not create workspace, that name that already exists: %s", newFolder);
        }

        File cogFolder = new File(newFolder, ".cog");
        cogFolder.mkdirs();
        File newProjFile = new File(cogFolder, "ProjInfo.xml");
        return newProjFile;

    }


    /**
     * Confirm that this is a good unique key, or extend the passed value until
     * is is good by adding hyphen and a number on the end.
     */
    public String genUniqueWSKeyInSite(String workspaceKey) throws Exception {

        // if it is already unique, use that. This tests ALL sites currently
        // loaded, but might consider a site-specific test when there is a
        // site specific search for a project.
        NGPageIndex ngpi = cog.getWSBySiteAndKey(this.key, workspaceKey);
        if (ngpi == null) {
            return workspaceKey;
        }

        // NOPE, there is a container already with that key, so we have to find
        // another one. If there is already a numeral on the end, strip it off
        // so that the new numeral will most likely be one more that that, but
        // only for single digit numerals after a hyphen. Not worth dealing with
        // more elaborate than that
        if (workspaceKey.length() > 6) {
            if (workspaceKey.charAt(key.length() - 2) == '-') {
                char lastChar = workspaceKey.charAt(workspaceKey.length() - 1);
                if (lastChar >= '0' && lastChar <= '9') {
                    workspaceKey = workspaceKey.substring(0, workspaceKey.length() - 2);
                }
            }
        }

        int testNum = 1;
        while (true) {
            String testKey = workspaceKey + "-" + Integer.toString(testNum);
            ngpi = cog.getWSBySiteAndKey(this.key, testKey);
            if (ngpi == null) {
                return testKey;
            }
            testNum++;
        }
    }



    @Override
    public boolean isFrozen() {
        if (isDeleted()) {
            return true;
        }
        return siteInfoRec.getAttributeBool("frozen");
    }

    /**
     * Whether to show or hide experimental features.
     */
    public boolean getShowExperimental() throws Exception {
        return siteInfoRec.getAttributeBool("showExperimental");
    }
    public void setShowExperimental(boolean val) throws Exception {
        siteInfoRec.setAttributeBool("showExperimental", val);
    }


    // //////////////////// DEPRECATED METHODS//////////////////

    //Override
    public void saveWithoutAuthenticatedUser(String modUser, long modTime, String comment, Cognoscenti cog) throws Exception {
        try {
            siteInfoRec.setModTime(modTime);
            siteInfoRec.setModUser(modUser);
            save();
        }
        catch (Exception e) {
            throw WeaverException.newWrap("Unable to write the site file to '%s'.",
                    e, getFilePath().getAbsolutePath());
        }

    }



    private void assertPermissionToCreateProject(AuthRequest ar) throws Exception {
        if (ar.isLoggedIn()) {
            if (!isSiteExecutive(ar.getUserProfile())) {
                throw WeaverException.newBasic("Must be an executive of the site to create new projects");
            }
            return;
        }

        String licVal = ar.reqParam("lic");
        if (licVal == null || licVal.length() == 0) {
            throw WeaverException.newBasic("Have to be logged in, or have a licensed link, "
                    + "to create a new workspace");
        }
        License lic = this.getLicense(licVal);
        if (lic == null) {
            throw WeaverException.newBasic("Specified license (" + lic + ") not found");
        }
        if (ar.nowTime > lic.getTimeout()) {
            throw WeaverException.newBasic("Specified license (%s) is no longer valid.  You will need an updated licensed link to create a new workspace.", lic);
        }
        // TODO: check that the user for this license is still in the role

    }

    /**
     * NGBook object is created in memory, and can be manipulated in memory, but
     * be sure to call "savePage" before finished otherwise nothing is created
     * on disk.
     */
    public NGWorkspace createWorkspaceByKey(AuthRequest ar, String workspaceKey) throws Exception {
        assertPermissionToCreateProject(ar);
        if (workspaceKey.indexOf('/') >= 0) {
            throw WeaverException.newBasic(
                    "Expecting a key value, but got something with a slash in it: " + workspaceKey);
        }
        if (workspaceKey.endsWith(".sp")) {
            throw WeaverException.newBasic(
                    "this has changed, and the key should no longer end with .sp: " + workspaceKey);
        }

        // get the sanitized form, just in case
        String sanitizedKey = SectionUtil.sanitize(workspaceKey);
        File newFilePath = newWorkspaceFolderOrFail(sanitizedKey);
        return createProjectAtPath(ar.getUserProfile(), newFilePath, sanitizedKey, ar.nowTime);
    }



    private NGWorkspace createProjectAtPath(UserProfile up, File newFilePath, String newKey, long nowTime)
            throws Exception {
        if (newFilePath.exists()) {
            throw WeaverException.newBasic("Somehow the file given already exists: %s", newFilePath.getAbsolutePath());
        }

        Document newDoc = readOrCreateFile(newFilePath, "page");
        NGWorkspace newWorkspace = new NGWorkspace(newFilePath, newDoc, this);
        newWorkspace.setKey(newKey);

        // make the current user to ALL roles of the new page
        for (NGRole role : newWorkspace.getAllRoles()) {
            role.addPlayer(up.getAddressListEntry());
        }

        // register this into the page index
        cog.makeIndexForWorkspace(newWorkspace);

        // add this new project into the user's watched projects list
        // so it is easy for them to find later.
        // Only do this if creating directly, and not through API
        if (up != null) {
            up.setWatch(newWorkspace.getCombinedKey());
            cog.getUserManager().saveUserProfiles();
        }

        return newWorkspace;
    }

    /**
     * Sites have a set of licenses
     */
    @Override
    public List<License> getLicenses() throws Exception {
        List<LicenseRecord> vc = siteInfoRec.getChildren("license", LicenseRecord.class);
        List<License> v = new ArrayList<License>();
        for (License child : vc) {
            v.add(child);
        }
        return v;
    }

    @Override
    public boolean removeLicense(String id) throws Exception {
        List<LicenseRecord> vc = siteInfoRec.getChildren("license", LicenseRecord.class);
        for (LicenseRecord child : vc) {
            if (id.equals(child.getId())) {
                siteInfoRec.removeChild(child);
                return true;
            }
        }
        // maybe this should throw an exception?
        return false;
    }

    @Override
    public License addLicense(String id) throws Exception {
        LicenseRecord lr = siteInfoRec.createChildWithID("license", LicenseRecord.class, "id", id);
        return lr;
    }

    public License createLicense(String userId, String role, long endDate, boolean readOnly)
            throws Exception {
        String id = IdGenerator.generateKey();
        License lr = addLicense(id);
        lr.setTimeout(endDate);
        lr.setCreator(userId);
        lr.setRole(role);
        lr.setReadOnly(false);
        return lr;
    }

    @Override
    public boolean isValidLicense(License lr, long time) throws Exception {
        if (lr==null) {
            //no license passed, then not valid, handle this quietly so that
            //this can be used with getLicense operations.
            return false;
        }
        if (time>lr.getTimeout()) {
            return false;
        }

        NGRole ngr = getRole(lr.getRole());
        if (ngr==null) {
            //can not be valid if the role no longer exists
            return false;
        }

        //check to see if the user who created it, is still in the
        //role or in the member's role
        AddressListEntry ale = AddressListEntry.findOrCreate(lr.getCreator());
        if (!ngr.isExpandedPlayer(ale,  this) && !primaryOrSecondaryPermission(ale)) {
            return false;
        }

        return true;
    }

    public File getStatsFilePath() {
        File siteFolder = getSiteRootFolder();
        File cogFolder = new File(siteFolder, ".cog");
        return new File(cogFolder, "stats.json");

    }

    public WorkspaceStats getRecentStats() throws Exception {
        return getRecentStats(false);
    }

    public WorkspaceStats getRecentStats(boolean force) throws Exception {

        File statsFile = getStatsFilePath();
        if (!statsFile.exists()) {
            // if it does not exist, then go ahead and generate it
            return recalculateStats(cog);
        }
        long siteTimestamp = associatedFile.lastModified();
        long statsTimeStamp = statsFile.lastModified();
        if (statsTimeStamp < siteTimestamp) {
            // if the site has changed since stats, then regerate it no matter what
            return recalculateStats(cog);
        }
        long recentEnough = System.currentTimeMillis() - 60*60*1000;
        if (statsTimeStamp < recentEnough || force) {
            // otherwise recalc stats if it has been an hour
            return recalculateStats(cog);
        }
        return getStatsFile();
    }

    /**
     * Forces the recalculation of the site states and puts the result
     * in the cache.
     */
    public WorkspaceStats recalculateStats(Cognoscenti cog) throws Exception {

        System.out.println(String.format(
            "SCANNING STATS: for site (%s) at %s", 
            this.key, SectionUtil.currentTimestampString()));
        //we should figure out how to do this at a time when all the
        //projects are being scanned for some other purpose....
        WorkspaceStats siteStats = new WorkspaceStats();

        for (NGPageIndex ngpi : cog.getNonDelWorkspacesInSite(this.getKey())) {
            NGWorkspace ngw = ngpi.getWorkspace();
            siteStats.gatherFromWorkspace(ngw);
            siteStats.numWorkspaces++;
        }
        
        // Update the SiteUsers with this information, removing all the entries
        // that do not match to a user with a profile
        SiteUsers siteUsers = getUserMap();
        siteUsers.keepTheseUsers(siteStats.listAllUserProfiles());
        File cogFolder = new File(siteFolder, ".cog");
        siteUsers.writeUsers(cogFolder);
        
        // Now with updated site users, count the users active and inactive
        siteStats.countUsers(siteUsers);
        saveStatsFile(siteStats);
        return siteStats;
    }
    
    
    public JSONObject getStatsJSON(Cognoscenti cog) throws Exception {
        WorkspaceStats ws = getRecentStats();
        String buffer = JsonUtil.convertToJsonString(ws);
        return new JSONObject(buffer);
    }

    public WorkspaceStats getStatsFile() throws Exception {
        //JSONObject jo = JSONObject.readFromFile(getStatsFilePath());
        //return WorkspaceStats.fromJSON(jo);
        return JsonUtil.loadJsonFile(getStatsFilePath(), WorkspaceStats.class);
    }

    public void saveStatsFile(WorkspaceStats stats) throws Exception {
        //JSONObject jo = stats.getJSON();
        //jo.writeToFile(getStatsFilePath());
        JsonUtil.saveJsonFile(getStatsFilePath(), stats);
    }

    public boolean isMoved() {
        String moveURL = this.getScalar("movedTo");
        return (moveURL!=null && !moveURL.isEmpty());
    }
    public String getMovedTo() {
        return this.getScalar("movedTo");
    }



    public JSONObject getConfigJSON() throws Exception {
        
        //all deleted site should also be frozen
        if (this.isDeleted() && !this.isFrozen()) {
            siteInfoRec.setAttributeBool("frozen", true);
        }
        
        JSONObject jo = new JSONObject();
        jo.put("key", this.getKey());

        // there used to be multiple name, but now there is only one
        // but the client side has not been switched
        JSONArray nameArray = new JSONArray();
        nameArray.put(getContainerName());
        jo.put("names", nameArray);

        jo.put("rootFolder", this.getSiteRootFolder());
        this.extractScalarString(jo, "description");
        jo.put("showExperimental", getShowExperimental());
        jo.put("changed", getLastModifyTime());
        siteInfoRec.extractAttributeBool(jo, "isDeleted");
        siteInfoRec.extractAttributeString(jo, "siteMsg");
        siteInfoRec.extractVectorString(jo, "labelColors");

        // these are settable with update config web service
        siteInfoRec.extractAttributeBool(jo, "frozen");
        siteInfoRec.extractAttributeBool(jo, "offLine");
        siteInfoRec.extractAttributeInt(jo, "workspaceLimit", 4);
        siteInfoRec.extractAttributeInt(jo, "workspaceGratis", 1);
        siteInfoRec.extractAttributeInt(jo, "frozenLimit", 12);
        siteInfoRec.extractAttributeInt(jo, "editUserLimit", 3);
        siteInfoRec.extractAttributeInt(jo, "editUserGratis", 1);
        siteInfoRec.extractAttributeInt(jo, "viewUserLimit", 50);
        siteInfoRec.extractAttributeInt(jo, "emailLimit", 100);
        siteInfoRec.extractAttributeInt(jo, "fileSpaceLimit", 100);

        this.extractScalarString(jo, "movedTo");
        NGRole owners = getSecondaryRole();
        JSONArray ja = new JSONArray();
        for (AddressListEntry ale : owners.getDirectPlayers()) {
            ja.put( ale.getJSON() );
        }
        jo.put("owners", ja);
        NGRole execs = getPrimaryRole();
        ja = new JSONArray();
        for (AddressListEntry ale : execs.getDirectPlayers()) {
            ja.put( ale.getJSON() );
        }
        jo.put("executives", ja);
        return jo;
    }

    public void updateConfigJSON(JSONObject jo) throws Exception {
        this.updateScalarString("description", jo);
        if (jo.has("names")) {
            setContainerName( jo.getJSONArray("names").getString(0));
        }
        siteInfoRec.updateAttributeBool("showExperimental", jo);
        if (jo.has("isDeleted")) {
            boolean isDel = jo.getBoolean("isDeleted");
            siteInfoRec.setAttributeBool("isDeleted", isDel);
            if (isDel) {
                siteInfoRec.setAttributeBool("frozen", true);
            }
        }
        siteInfoRec.updateAttributeString("siteMsg", jo);
        siteInfoRec.updateUniqueVectorString("labelColors", jo);
        this.updateScalarString("movedTo", jo);
    }

    /**
     * These are settings that can only be set by a super admin
     * because they pertain the account settings that users should
     * never be able to change.  The structure is the same as 
     * regular update, but only allowed if super admin
     */
    public void updateAdminConfigJSON(JSONObject jo) throws Exception {
        siteInfoRec.updateAttributeBool("frozen", jo);
        siteInfoRec.updateAttributeBool("offLine", jo);
        siteInfoRec.updateAttributeInt("workspaceLimit", jo);
        siteInfoRec.updateAttributeInt("workspaceGratis", jo);
        siteInfoRec.updateAttributeInt("frozenLimit", jo);
        siteInfoRec.updateAttributeInt("editUserLimit", jo);
        siteInfoRec.updateAttributeInt("editUserGratis", jo);
        siteInfoRec.updateAttributeInt("viewUserLimit", jo);
        siteInfoRec.updateAttributeInt("emailLimit", jo);
        siteInfoRec.updateAttributeInt("fileSpaceLimit", jo);
    }
    
    /**
     * the only thing you send from a Site is role request emails
     * and SiteMail.
     */
    @Override
    public long nextActionDue() throws Exception {
        
        //first check the site mail
        long hundredSecondsAgo = System.currentTimeMillis() - 100000;
        for (SiteMailGenerator smg : getAllSiteMail()) {
            if (smg.notSentYet()) {
                return hundredSecondsAgo;
            }
        }
        
        //nothing to do, return time for next year
        return System.currentTimeMillis() + 31000000000L;
    }
    


    public static List<File> getAllLayouts(AuthRequest ar) {
        File templateFolder = ar.getCogInstance().getConfig().getFileFromRoot("siteLayouts");
        ArrayList<File> allTemplates = new ArrayList<File>();
        Hashtable<String, File> used = new Hashtable<String, File>();

        File[] children = templateFolder.listFiles();
        if (children!=null) {
            for (File tempName: children) {
                String name = tempName.getName();
                if (!name.endsWith(".chtml")) {
                    continue;
                }
                if (!used.contains(tempName.getName())) {
                    allTemplates.add(tempName);
                    used.put(tempName.getName(), tempName);
                }
            }
        }
        return allTemplates;
    }
    
    public JSONObject getSiteDripContent(AuthRequest ar) throws Exception {
        try {
            File templateFolder = ar.getCogInstance().getConfig().getFileFromRoot("siteLayouts");
            File configFile = new File(templateFolder, "config.json");
            JSONObject fileContents = JSONObject.readFromFile(configFile);
            List<SiteMailGenerator> allMail = getAllSiteMail();
            for (JSONObject oneMail : fileContents.getJSONArray("list").getJSONObjectList()) {
                String thisFile = oneMail.getString("name");
                for(SiteMailGenerator smg : allMail) {
                    if (thisFile.equals(smg.getLayoutName())) {
                        smg.extractAttributeString(oneMail, "id");
                        smg.extractAttributeString(oneMail, "subject");
                        smg.extractAttributeInt(oneMail, "state");
                        smg.extractAttributeLong(oneMail, "sendDate");
                        smg.extractAttributeString(oneMail, "from");
                    }
                }
            }
            return fileContents;
        }
        catch (Exception e) {
            throw WeaverException.newWrap("Unable to read all the site layout drip feed", e);
        }
    }

    public static File findSiteLayout(AuthRequest ar, String layoutName) {
        File meetingLayoutFile = null;
        for (File aLayout : getAllLayouts(ar)) {
            if (aLayout.getName().equals(layoutName)) {
                meetingLayoutFile = aLayout;
            }
        }
        if (meetingLayoutFile==null) {
            if ("SiteIntro1.chtml".equals(layoutName)) {
                throw new RuntimeException("Required file SiteIntro1.chtml does not appear to be installed in the system.");
            }
            //This one must always exist...
            return findSiteLayout(ar, "SiteIntro1.chtml");
        }
        return meetingLayoutFile;
    }
    

    public List<SiteMailGenerator> getAllSiteMail() throws Exception {
        List<SiteMailGenerator> requestList = new ArrayList<SiteMailGenerator>();
        DOMFace rolelist = this.requireChild("SiteMail", DOMFace.class);
        List<SiteMailGenerator> children = rolelist.getChildren("mailGen", SiteMailGenerator.class);
        for (SiteMailGenerator rrr : children) {
            requestList.add(rrr);
        }
        return requestList;
    }
    public SiteMailGenerator createSiteMail() throws Exception {
        DOMFace rolelist = this.requireChild("SiteMail", DOMFace.class);
        SiteMailGenerator newMailGen = rolelist.createChild("mailGen", SiteMailGenerator.class);
        newMailGen.setState(SiteMailGenerator.SM_STATE_SCHEDULED);
        return newMailGen;
    }

    public boolean generateNotificationEmail(AuthRequest ar, EmailSender sender, long nowTime) throws Exception {
        boolean sentMsg = false;
        for (SiteMailGenerator smg : getAllSiteMail()) {
            if (smg.notSentYet()) {
                smg.actuallySendSiteMailNow(ar, this, sender);
                sentMsg = true;
            }
        }
        return sentMsg;
    }


    public List<AddressListEntry> getSiteUsersList() throws Exception {
        if (allUserList!=null) {
            return allUserList;
        }

        List<AddressListEntry> temp = new ArrayList<AddressListEntry>();
        WorkspaceStats ws = getRecentStats();
        List<String> userids = ws.anythingPerUser.getSortedKeys();
        Set<String> alreadyUsed = new HashSet<String>();
        for (String id : userids) {
            if (!id.isEmpty()) {
                AddressListEntry ale = AddressListEntry.findOrCreate(id);
                String correctId = ale.getUniversalId();
                //eliminate duplicates due to synonymous email ids
                if (!alreadyUsed.contains(correctId)) {
                    temp.add(ale);
                    alreadyUsed.add(correctId);
                }
            }
        }
        allUserList =  temp;
        return temp;
    }
    public void flushUserCache() throws Exception {
        allUserList = null;
    }


    public JSONObject actuallyGarbageCollect() throws Exception {
        JSONArray ja = new JSONArray();
        JSONObject jo = new JSONObject();
        jo.put("list",  ja);
        for (NGPageIndex ngpi : cog.getDeletedContainers()) {
            if (!ngpi.isWorkspace()) {
                continue;
            }
            if (!ngpi.wsSiteKey.equals(this.key)) {
                continue;
            }
            NGWorkspace ngw = ngpi.getWorkspace();
            ja.put(ngw.actuallyGarbageCollect(cog));
        }
        for (NGPageIndex ngpi : cog.getNonDelWorkspacesInSite(this.getKey())) {
            NGWorkspace ngw = ngpi.getWorkspace();
            ja.put(ngw.actuallyGarbageCollect(cog));
        }
        return jo;
    }
    
    public int editUserLimit() {
        return siteInfoRec.getAttributeInt("editUserLimit");
    }
    public int readUserLimit() {
        return siteInfoRec.getAttributeInt("readUserLimit");
    }
    
    public boolean isUnpaidUser(String userId) throws Exception {
        if (userId==null || userId.length()==0) {
            throw WeaverException.newBasic("isUnpaidUser requires a non-empty parameter");
        }
        SiteUsers siteUsers = getUserMap();
        AddressListEntry ale = AddressListEntry.findOrCreate(userId);
        return siteUsers.isUnpaid(ale.getUserProfile());
    }
    public boolean isUnpaidUser(UserProfile uProf) throws Exception {
        if (uProf==null) {
            throw WeaverException.newBasic("isUnpaidUser requires a non-empty parameter");
        }
        SiteUsers siteUsers = getUserMap();
        return siteUsers.isUnpaid(uProf);
    }
    
    
    private SiteUsers siteUsers = null;
    public SiteUsers getUserMap() throws Exception {
        if (siteUsers != null) {
            return siteUsers;
        }
        File cogFolder = new File(siteFolder, ".cog");
        siteUsers = SiteUsers.readUsers(cogFolder);
        
        return siteUsers;
    }
    
    public SiteUsers updateUserMap(JSONObject delta) throws Exception {
        File cogFolder = new File(siteFolder, ".cog");
        SiteUsers siteUserTemp = SiteUsers.readUsers(cogFolder);
        
        siteUserTemp.updateUserMap(delta);
        
        siteUserTemp.writeUsers(cogFolder);
        siteUsers = siteUserTemp;
        return siteUserTemp;
    }
    
    public boolean isSiteOwner(UserRef user) throws Exception {
        return this.primaryPermission(user);
    }
    public boolean isSiteExecutive(UserRef user) throws Exception {
        return this.primaryOrSecondaryPermission(user);
    }
    public void assertSiteOwner(UserRef user, String descript) throws Exception {
        if (!isSiteOwner(user)) {
            throw WeaverException.newBasic("User %s is not an owner of the site. %s", 
                    user.getUniversalId(), descript);
        }
    }
    public void assertSiteExecutive(UserRef user, String descript) throws Exception {
        if (!isSiteOwner(user)) {
            throw WeaverException.newBasic("User %s is not an executive of the site. %s", 
                    user.getUniversalId(), descript);
        }
    }

    
    public Ledger getLedger() throws Exception {
        try {
            File sitefolder = getFilePath().getParentFile();
            Ledger ledger = Ledger.readLedger(sitefolder);
            return ledger;
        }
        catch (Exception e) {
            throw WeaverException.newWrap("Failure getting ledger for site (%s)", e, this.getKey());
        }
    }
    public void saveLedger(Ledger ledger) throws Exception {
        File sitefolder = getFilePath().getParentFile();
        ledger.saveLedger(sitefolder);
    }

    public RoleDefinitionFile getAllRoleDefs(Cognoscenti _cog) throws Exception {
        if (roleDefinitionFile == null) {
            File sitefolder = getFilePath().getParentFile();
            File roleDefFile = new File(sitefolder, "RoleDefs.json");
            if (!roleDefFile.exists()) {
                // when the site is created, it gets a set of defaults
                // these will be saved on the first save after a change
                roleDefFile = _cog.getConfig().getFileFromRoot("DefaultRoleDefs.json");
            }
            roleDefinitionFile = RoleDefinitionFile.loadRoleDefs(roleDefFile);
        }
        return roleDefinitionFile;
    }
    public void saveAllRoleDefs() throws Exception {
        if (roleDefinitionFile != null) {
            File sitefolder = getFilePath().getParentFile();
            File roleDefFile = new File(sitefolder, "RoleDefs.json");
            roleDefinitionFile.saveRoleDefs(roleDefFile);
        }
    }
    public RoleDefinition findRoleDef(String symbol) {
        return roleDefinitionFile.findRoleDef(symbol);
    }
    public RoleDefinition findRoleDefOrFail(String symbol) throws Exception {
        return roleDefinitionFile.findRoleDefOrFail(symbol);
    }
}
