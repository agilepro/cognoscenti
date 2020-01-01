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

package org.socialbiz.cog;

import java.io.File;
import java.io.InputStream;
import java.net.URLEncoder;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;

import org.socialbiz.cog.dms.RemoteLinkCombo;
import org.socialbiz.cog.exception.NGException;
import org.socialbiz.cog.exception.ProgramLogicError;
import org.socialbiz.cog.mail.ScheduledNotification;
import org.w3c.dom.Document;
import org.w3c.dom.Element;

import com.purplehillsbooks.json.JSONArray;
import com.purplehillsbooks.json.JSONObject;

public class AttachmentRecord extends CommentContainer {
    private static String ATTACHMENT_ATTB_RLINK = "rlink";
    private static String ATTACHMENT_ATTB_RCTIME = "rctime";
    public static String ATTACHMENT_ATTB_RLMTIME = "rlmtime";

    private String niceName = null;
    protected NGWorkspace container = null;

    public AttachmentRecord(Document doc, Element definingElement, DOMFace attachmentContainer) {
        super(doc, definingElement, attachmentContainer);

        //retire the separate roleAccess and labels records, and make a single
        //consolidated list.  This migrates any existing roleAccess entries to the
        //labels vector.  Migration added June 2015, however roles on attachments
        //was never fully implemented in the UI and rarely used.
        for (String roleName : getVector("accessRole")) {
            this.addVectorValue("labels", roleName);
        }
        clearVector("accessRole");
    }

    public void setContainer(NGWorkspace newCon) throws Exception {
        container = newCon;
    }

    /**
     * Copy all the members from another attachment into this attachment
     * Remember to maintain this as new members are added.
     */
    public void copyFrom(AttachmentRecord other) throws Exception {
        setDisplayName(other.getDisplayName());
        setModifiedBy(other.getModifiedBy());
        setModifiedDate(other.getModifiedDate());
        setDescription(other.getDescription());
        setPublic(other.isPublic());
        setType(other.getType());
        setURLValue(other.getURLValue());
    }

    public String getId() {
        return checkAndReturnAttributeValue("id");
    }

    public void setId(String id) {
        setAttribute("id", id);
    }

    public String getUniversalId() {
        return getScalar("universalid");
    }

    public void setUniversalId(String id) {
        setScalar("universalid", id);
    }

    /* the description of the document that is displayed
    * when you access the document.  Technically, it is a description of
    * why this document is relevant to this case.  It is not a comment
    * about an action, but really a description of the document.
    * TODO: change this name to getDescription and setDescription
    */
    public String getDescription() {
        return checkAndReturnAttributeValue("comment");
    }

    public void setDescription(String comment) {
        setAttribute("comment", comment);
    }

    /**
     * The display name default to the file name, if one has not been set. If
     * file name is empty, then set to AttachmentXXXX where XXXX is the id of
     * the attachment.
     */
    public String getNiceName() {
        if (niceName != null) {
            return niceName;
        }
        String val = getAttribute("displayName");
        if (val != null && val.length() > 0) {
            niceName = val;
            return niceName;
        }
        val = getAttribute("file");
        if (val != null && val.length() > 0) {
            niceName = val;
            return niceName;
        }
        niceName = "Attachment" + getId();
        return niceName;
    }

    public String getNiceNameTruncated(int maxLen) {
        String displayName = getNiceName();
        if (displayName.length() > maxLen) {
            int dotPos = displayName.lastIndexOf(".");
            if (dotPos == displayName.length() - 1 || dotPos < displayName.length() - 7) {
                // three situations to truncate without worrying about
                // extension:
                // 1 there is no dot, no extension, so just truncate
                // 2 there is a dot at the end, still no extension, so just
                // truncate
                // 3 the dot is more than six from the end, so this is a dot in
                // the middle
                // somewhere, and probably not an extension at all. This can
                // happen when
                // the display name is a URL or something like that.
                displayName = displayName.substring(0, maxLen - 3) + "...";
            }
            else {
                String ext = displayName.substring(dotPos + 1);
                int parsePos = maxLen - 3 - ext.length();
                displayName = displayName.substring(0, parsePos) + "..." + ext;
            }
        }
        return displayName;
    }

    public String getDisplayName() {
        return getAttribute("displayName");
    }

    public void setDisplayName(String newDisplayName) throws Exception {
        String oldName = getDisplayName();

        if (newDisplayName.equals(oldName)) {
            return; // nothing to do
        }

        if (equivalentName(newDisplayName)) {
            // only difference is in upper/lower case, or some other change
            // that remains equivalent, so set to the new form.
            setAttribute("displayName", newDisplayName);
            niceName = newDisplayName;
            return;
        }

        // consistency check, the display name and file name (in case of file)
        // must not
        // have any slash characters in them
        if (newDisplayName.indexOf("/") > 0 || newDisplayName.indexOf("\\") > 0) {
            throw new NGException("nugen.exception.display.name.have.slash",
                    new Object[] { newDisplayName });
        }

        // also, display name needs to be unique within the project
        AttachmentRecord otherFileWithSameName = container.findAttachmentByName(newDisplayName);
        if (otherFileWithSameName!=null) {
            throw new Exception("Can't rename this attachment because there is another attachment named "
                    + otherFileWithSameName.getDisplayName() + " in this project.");
        }

        setAttribute("displayName", newDisplayName);
        niceName = newDisplayName;

        updateActualFile(oldName, newDisplayName);
    }

    /**
     * returns true if the name supplied is considered equivalent to the name of
     * this attachment. This comparison will take into account any limitations
     * on what names are allowed to be.
     */
    public boolean equivalentName(String name) throws Exception {
        if (name == null) {
            return false;
        }
        String dName = getNiceName();
        return name.equalsIgnoreCase(dName);
    }

    public void updateActualFile(String oldName, String newName) throws Exception
    {
        if (container==null) {
            throw new Exception("ProjectAttachment record has not be innitialized correctly, there is no container setting.");
        }
        File folder = container.containingFolder;
        File docFile = new File(folder, oldName);
        File newFile = new File(folder, newName);
        if (docFile.exists()) {
            //this will fail if the file already exists.
            docFile.renameTo(newFile);
        }
        else {
            //it is possible that user is 'fixing' the project by changing the name of an attachment
            //record to the name of an existing file.  IF this is the case, there may have been a
            //record of an "extra" file.  This will eliminate that.
            container.removeExtrasByName(newName);
        }
    }

    public String getLicensedAccessURL(AuthRequest ar, NGWorkspace ngp, String licenseId)
            throws Exception {
        String relativeLink = "a/" + SectionUtil.encodeURLData(getNiceName());
        LicensedURL attPath = new LicensedURL(ar.baseURL + ar.getResourceURL(ngp, relativeLink),
                null, licenseId);
        return attPath.getCombinedRepresentation();
    }

    /**
     * confusingly named originally getStorageName
     * For LINK: 
     *     This holds the URL.
     * For an uploaded file:  
     *     this contains the original name that the file
     *     was uploaded as, but after that it has no meaning.   If you change the name
     *     of an attachment, then the name field is changed, and the actual file name
     *     is changed, but this field remains the original name.
     *     The REAL name is the NAME.  do not use this field for uploaded file.
     * @return
     */
    public String getURLValue() {
        return checkAndReturnAttributeValue("file");
    }

    public void setURLValue(String newURI) {
        setAttribute("file", newURI);
    }

    /**
     * There are three types of attachment:
     *
     * FILE: this is a local path into the
     *    attachments repository
     * URL: this is a URL to an external web addressable
     *    content store
     * EXTERN: this is also a URL which is launched in a
     *    separate window, but it migh also have a local copy.
     * EXTRA: this file appeared in the project folder (all by
     *    itself) but not yet tracked
     * GONE: this file is missing from the folder,
     *    might have been deleted by user
     * DEFER: deprecated, not supported any more
     * except legacy
     */
    public String getType() {
        String val = getAttribute("type");
        if (val == null || val.length() == 0) {
            return "FILE";
        }
        // some data file created with lower case terms ... need to migrate
        // them.
        if (val.equals("file")) {
            setAttribute("type", "FILE");
            return "FILE";
        }
        return val;
    }

    public void setType(String type) {
        // check that a valid string id being passed
        // this is a program logic exception since the user never enters
        // the type of attachment
        if (!type.equals("FILE") && !type.equals("URL") && !type.equals("EXTRA")
                && !type.equals("GONE")) {
            throw new RuntimeException("Attachment type has to be either FILE, EXTRA, GONE, or URL");
        }
        setAttribute("type", type);
    }

    /**
     * Returns true if this document has appeared in the folder, and the project
     * does not have any former knowledge of it ==> EXTRA or GONE Returns false
     * if this is an otherwise expected document where the type is URL or FILE
     */
    public boolean isUnknown() {
        String ftype = getType();
        return ("EXTRA".equals(ftype) || "GONE".equals(ftype));
    }

    public String getModifiedBy() {
        return checkAndReturnAttributeValue("modifiedBy");
    }

    public void setModifiedBy(String modifiedBy) {
        setAttribute("modifiedBy", modifiedBy);
    }

    public long getModifiedDate() {
        return safeConvertLong(checkAndReturnAttributeValue("modifiedDate"));
    }

    public void setModifiedDate(long modifiedDate) {
        setAttribute("modifiedDate", Long.toString(modifiedDate));
    }

    private String checkAndReturnAttributeValue(String attrName) {
        String val = getAttribute(attrName);
        if (val == null) {
            return "";
        }
        return val;
    }

    public void createHistory(AuthRequest ar, NGWorkspace ngp, int event, String comment)
            throws Exception {
        HistoryRecord.createHistoryRecord(ngp, getId(), HistoryRecord.CONTEXT_TYPE_DOCUMENT,
                getModifiedDate(), event, ar, comment);
    }

    /**
     * tells whether this attachment is a public attachment, or a member only
     * attachment. Value are:
     *
     * SectionDef.PUBLIC_ACCESS = 1; SectionDef.MEMBER_ACCESS = 2;
     * SectionDef.ADMIN_ACCESS = 3; -- future expansion possibility
     * SectionDef.PRIVATE_ACCESS = 4; -- future expansion possibility
     */
    private int getVisibility() {
        return (int) safeConvertLong(getScalar("visibility"));
    }

    private void setVisibility(int viz) {
        if (viz < SectionDef.PUBLIC_ACCESS) {
            throw new RuntimeException("Visibility of an attachment can not be set to a value "
                    + "less than one.  Attempt to set visibility to " + viz);
        }
        if (viz > SectionDef.MEMBER_ACCESS) {
            throw new RuntimeException("Visibility of an attachment can not be set to a value "
                    + "greater than two.  Attempt to set visibility to " + viz);
        }
        setScalar("visibility", Integer.toString(viz));
    }
    public boolean isPublic() {
        return (getVisibility()==1);
    }
    public void setPublic(boolean pubval) {
        if (pubval) {
            setVisibility(SectionDef.PUBLIC_ACCESS);
        }
        else {
            setVisibility(SectionDef.MEMBER_ACCESS);
        }
    }

    public int getVersion() {
        return getAttributeInt("version");
    }

    public void setVersion(int version) {
        setAttributeInt("version", version);
    }

    public String getOriginalFilename() {
        return getAttribute("originalFilename");
    }

    public void setOriginalFilename(String actualFileName) {
        setAttribute("originalFilename", actualFileName);
    }

    // ////////////////////// VERSIONING STUFF ////////////

    /**
    * Get a list of all the versions of this attachment that exist.
    * The container is needed so that each attachment can caluculate
    * its own name properly.
    */
    public List<AttachmentVersion> getVersions(NGContainer ngc)
        throws Exception {
        if (!(ngc instanceof NGWorkspace)) {
            throw new Exception("Problem: ProjectAttachment should only belong to NGProject, "
                    +"but somehow got a different kind of container.");
        }

        File projectFolder = ((NGWorkspace)ngc).containingFolder;
        if (projectFolder==null) {
            throw new Exception("NGProject container has no containing folder????");
        }

        List<AttachmentVersion> list =
            AttachmentVersionProject.getProjectVersions(projectFolder, getNiceName(), getId());

        sortVersions(list);

        return list;
    }

    /**
     * Just get the last version. This is the one the user is most often
     * interested in. Can also get this by passing negative version number into
     * getSpecificVersion.
     *
     * Can return null if the file has been found missing, and there are no
     * committed versions.
     */
    public AttachmentVersion getLatestVersion(NGContainer ngc) throws Exception {

        // code must determine HERE what kind of versioning system is being used
        // currently we only have the simple versioning system.
        // When another system is provided, the switch to choose between them
        // will be here.

        // NOTE: this code is fine for the simple versioning system, but with
        // CVS or the others
        // you do not want to get all versions just to get the latest. This code
        // should be a
        // a little smarter in order to run better.

        List<AttachmentVersion> list = getVersions(ngc);

        if (list.size() == 0) {
            //this can happen if a folder had files, a refresh allowed the attachment
            //record to get created, and then the user deletes the file before
            //it gets checked in.  Technically this makes the attachment a "GHOST"
            return null;
        }

        return list.get(list.size() - 1);
    }

    /**
     * Just get the specified version, or null if that version can not be found
     * Pass a negative version number to get the latest version
     */
    public AttachmentVersion getSpecificVersion(NGContainer ngc, int version) throws Exception {

        // code must determine HERE what kind of versioning system is being used
        // currently we only have the simple versioning system.
        // When another system is provided, the switch to choose between them
        // will be here.

        // negative means get the latest version
        if (version < 0) {
            return getLatestVersion(ngc);
        }

        // NOTE: this code is fine for the simple versioning system, but with
        // CVS or the others
        // you do not want to get all versions just to get the latest. This code
        // should be a
        // a little smarter in order to run better.

        List<AttachmentVersion> list = getVersions(ngc);

        for (AttachmentVersion att : list) {
            if (att.getNumber() == version) {
                return att;
            }
        }

        return null;
    }

    /**
     * In some versioning schemes, there is a 'checked-out' copy of the file that
     * is the working version -- the user can modify that directly.  This gets
     * a version object pointing to it.
     *
     * Returns null if versioning system does not have working copy.
     */
    public AttachmentVersion getWorkingCopy(NGContainer ngc) throws Exception {
        AttachmentVersion highest = getHighestCommittedVersion(ngc);
        int ver = 0;
        if (highest!=null) {
            ver = highest.getNumber();
        }
        File projectFolder = ((NGWorkspace)ngc).containingFolder;
        String attachName = getDisplayName();
        for (File testFile : projectFolder.listFiles())
        {
            String testName = testFile.getName();
            if (attachName.equalsIgnoreCase(testName)) {
                return new AttachmentVersionProject(testFile, ver+1, true, true);
            }
        }
        return null;
    }

    public AttachmentVersion getHighestCommittedVersion(NGContainer ngc) throws Exception {
        List<AttachmentVersion> list = getVersions(ngc);
        AttachmentVersion highest = null;
        int ver = 0;
        for (AttachmentVersion av : list) {
            if (av.getNumber()>ver) {
                ver = av.getNumber();
                highest = av;
            }
        }
        return highest;
    }

    /**
     * Takes the working copy, and make a new internal, backed up copy.
     */
    public void commitWorkingCopy(NGContainer ngc) throws Exception {
        File projectFolder = ((NGWorkspace)ngc).containingFolder;
        if (!projectFolder.exists()) {
            throw new Exception("Strange, this workspace's folder does not exist.  "
                    + "Something must be wrong: "+projectFolder);
        }
        File cogFolder = new File(projectFolder,".cog");
        if (!cogFolder.exists()) {
            //this might be the first thing in the COG folder
            cogFolder.mkdirs();
        }
        if (!cogFolder.exists()) {
            throw new Exception("Unable to create the COG folder: "+cogFolder);
        }
        AttachmentVersion workCopy = getWorkingCopy(ngc);
        String attachmentId = getId();
        String fileExtension = getFileExtension();
        File tempCogFile = File.createTempFile("~newP_"+attachmentId, fileExtension, cogFolder);
        File workFile = workCopy.getLocalFile();
        AttachmentVersionProject.copyFileContents(workFile, tempCogFile);

        //rename the special copy to have the right version number
        String specialVerFileName = "att"+attachmentId+"-"+Integer.toString(workCopy.getNumber())
                +fileExtension;
        File specialVerFile = new File(cogFolder, specialVerFileName);
        if (!tempCogFile.renameTo(specialVerFile)) {
            throw new NGException("nugen.exception.unable.to.rename.temp.file",
                new Object[]{tempCogFile,specialVerFile});
        }
    }


    /**
     * Pass the version list in to find out whether this attachment is
     * has uncommitted changes.
     */
    public boolean hasUncommittedChanges( List<AttachmentVersion> list) {
        AttachmentVersion externalCopy = null;
        AttachmentVersion latestInternal = null;
        int ver = -1;
        for (AttachmentVersion av : list) {
            if (av.isWorkingCopy()) {
                externalCopy = av;
            }
            else if (av.getNumber()>ver) {
                ver = av.getNumber();
                latestInternal = av;
            }
        }
        if (externalCopy==null) {
            //no external, nothing to commit
            return false;
        }
        if (latestInternal == null) {
            //external, but no internal, then you need commit
            return true;
        }
        long externalLen = externalCopy.getFileSize();
        long internalLen = latestInternal.getFileSize();
        return (externalLen != internalLen);
    }

    /**
     * Provide an input stream to the contents of the new version, and this
     * method will copy the contents into here, and then create a new version
     * for that file, and return the AttachmentVersion object that represents
     * that new version.
     */
    public AttachmentVersion streamNewVersion(AuthRequest ar, NGContainer ngc, InputStream contents)
            throws Exception {
        return streamNewVersion(ngc, contents, ar.getBestUserId(), ar.nowTime);
    }

    /**
    * Provide an input stream to the contents of the new version, and this method will
    * copy the contents into here, and then create a new version for that file, and
    * return the AttachmentVersion object that represents that new version.
    */
    public AttachmentVersion streamNewVersion(NGContainer ngc, InputStream contents,
            String userId, long timeStamp) throws Exception {

        if (!(ngc instanceof NGWorkspace)) {
            throw new Exception("Problem: ProjectAttachment should only belong to NGProject, but somehow got a different kind of container.");
        }
        File projectFolder = ((NGWorkspace)ngc).containingFolder;
        if (projectFolder==null) {
            throw new Exception("NGProject container has no containing folder????");
        }

        String displayName = getNiceName();
        AttachmentVersion av = AttachmentVersionProject.getNewProjectVersion(projectFolder,
                 displayName, getId(), contents);

        //update the record
        setVersion(av.getNumber());
        setURLValue("N/A");
        setModifiedDate(timeStamp);
        setModifiedBy(userId);

        return av;
    }

    public static void sortVersions(List<AttachmentVersion> list) {
        Collections.sort(list, new AttachmentVersionComparator());
    }

    static class AttachmentVersionComparator implements Comparator<AttachmentVersion> {
        public AttachmentVersionComparator() {
        }

        @Override
        public int compare(AttachmentVersion o1, AttachmentVersion o2) {
            try {
                int rank1 = o1.getNumber();
                int rank2 = o2.getNumber();
                if (rank1 == rank2) {
                    return 0;
                }
                if (rank1 < rank2) {
                    return -1;
                }
                return 1;
            }
            catch (Exception e) {
                return 0;
            }
        }
    }

    /**
     * Marking an Attachment as deleted means that we SET the deleted time. If
     * there is no deleted time, then it is not deleted. A Attachment that is
     * deleted remains in the archive until a later date, when garbage has been
     * collected.
     */
    public boolean isDeleted() {
        String delAttr = getAttribute("deleteUser");
        return (delAttr != null && delAttr.length() > 0);
    }

    /**
     * Set deleted date to the date that it is effectively deleted, which is the
     * current time in most cases. Set the date to zero in order to clear the
     * deleted flag and make the Attachment to be not-deleted
     */
    public void setDeleted(AuthRequest ar) {
        setAttribute("deleteDate", Long.toString(ar.nowTime));
        setAttribute("deleteUser", ar.getBestUserId());
    }

    public void clearDeleted() {
        setAttribute("deleteDate", null);
        setAttribute("deleteUser", null);
    }

    public long getDeleteDate() {
        return getAttributeLong("deleteDate");
    }

    public String getDeleteUser() {
        return getAttribute("deleteUser");
    }

    /**
     * Specifies whether this document should be synchronized with the upstream
     * project or not.  If 'true' then this document should be shared and
     * synchronized upstream.  If 'false' then this project is NOT sharing this
     * document with the upstream project.
     */
    public boolean isUpstream() {
        return "true".equals(getAttribute("upstream"));
    }
    public void setUpstream(boolean bVal) {
        if (bVal) {
            setAttribute("upstream", "true");
            if (!isUpstream()) {
                throw new RuntimeException("tried to set upstream and it didn't work");
            }
        }
        else {
            setAttribute("upstream", null);
            if (isUpstream()) {
                throw new RuntimeException("Can't figure out why setting the attribute is not working");
            }
        }
    }


    /**
     * when a doc is moved to another project, use this to record where it was
     * moved to, so that we can link there.
     */
    public void setMovedTo(String project, String otherId) throws Exception {
        setScalar("MovedToProject", project);
        setScalar("MovedToId", otherId);
    }

    /**
     * get the project that this doc was moved to.
     */
    public String getMovedToProjectKey() throws Exception {
        return getScalar("MovedToProject");
    }

    /**
     * get the id of the doc in the other project that this doc was moved to.
     */
    public String getMovedToAttachId() throws Exception {
        return getScalar("MovedToId");
    }

    /**
     * If an attachment has a remote link, then it came originally from a
     * repository and can be synchronized with that remote copy as well.
     */
    public RemoteLinkCombo getRemoteCombo() throws Exception {
        return RemoteLinkCombo.parseLink(getAttribute(ATTACHMENT_ATTB_RLINK));
    }

    public void setRemoteCombo(RemoteLinkCombo combo) {
        if (combo == null) {
            setAttribute(ATTACHMENT_ATTB_RLINK, null);
        }
        else {
            setAttribute(ATTACHMENT_ATTB_RLINK, combo.getComboString());
        }
    }
    public boolean hasRemoteLink() {
        String rl = getAttribute(ATTACHMENT_ATTB_RLINK);
        return (rl!=null && rl.length()>0);
    }


    /**
     * This is the time that the user actually made the attachment, regardless
     * of the time that the document was edited, or any other time that the doc
     * might have.
     */
    public long getAttachTime() {
        return safeConvertLong(getAttribute(ATTACHMENT_ATTB_RCTIME));
    }

    public void setAttachTime(long attachTime) {
        setAttribute(ATTACHMENT_ATTB_RCTIME, Long.toString(attachTime));
    }

    /**
     * This is the timestamp of the document on the remote server at the time
     * that it was last synchronized. Thus if the remote file was modified on
     * Monday, and someone synchronized that version to the project on Tuesday,
     * this date will hold the Monday date. The purpose is to compare with the
     * current remote time to see if it has been modified since the last
     * synchronization.
     */
    public long getFormerRemoteTime() {
        return safeConvertLong(getAttribute(ATTACHMENT_ATTB_RLMTIME));
    }

    public void setFormerRemoteTime(long attachTime) {
        setAttribute(ATTACHMENT_ATTB_RLMTIME, Long.toString(attachTime));
    }

    public String getRemoteFullPath() {
        return getAttribute("remotePath");
    }

    public void setRemoteFullPath(String path) {
        setAttribute("remotePath", path);
    }

    /***
     * This is the flag which tells that file download in the project is read
     * only type or not. And if it is read only type then it prohibits user to
     * upload newer version of that file and synchronization of that file should
     * be one directional only
     */
    public String getReadOnlyType() {
        return getAttribute("readonly");
    }

    public void setReadOnlyType(String readonly) {
        setAttribute("readonly", readonly);
    }

    /**
     * If isInEditMode() returns false, then the document is not in editing
     * mode, or nobody is maintaining the document. We do not restrict other
     * users to edit the document but we warn the user that "this document is
     * editing/maintaining by other user and if you still upload document over
     * it then your data may be lost".
     */
    public boolean isInEditMode() {
        String isInEditMode = getAttribute("editMode");
        if (isInEditMode == null) {
            return false;
        }
        else {
            return "true".equals(isInEditMode);
        }
    }

    /**
     * Set editModeDate to the date when user opts to become editor/ maintainer
     * of the document Set editModeUser to the editor's (logged in) user key.
     */
    public void setEditMode(AuthRequest ar) {
        setAttribute("editModeDate", Long.toString(ar.nowTime));
        setAttribute("editModeUser", ar.getUserProfile().getKey());
        setAttribute("editMode", "true");
    }

    public void clearEditMode() {
        setAttribute("editModeDate", null);
        setAttribute("editModeUser", null);
        setAttribute("editMode", null);

    }

    /***
     * We get the getEditModeDate to check from when the user is maintaining the
     * attachment.
     */
    public long getEditModeDate() {
        return getAttributeLong("editModeDate");
    }

    public String getEditModeUser() {
        return getAttribute("editModeUser");
    }

    /**
     * Tells whether there is a file behind this that can be served up
     */
    public boolean hasContents() {
        // url is the oly type without contents
        return !("URL".equals(getType()));
    }

    /**
     * return the size of the file in bytes
     */
    public long getFileSize(NGContainer ngc) throws Exception {
        if (!"FILE".equals(getType()) || isDeleted()) {
            return -1;
        }
        AttachmentVersion av = getLatestVersion(ngc);
        if (av==null) {
            return -1;
        }
        File f = av.getLocalFile();
        return f.length();
    }

    /**
     * getAccessRoles retuns a list of NGRoles which have access to this document.
     * Admin role and Member role are assumed automatically, and are not in this list.
     * This list contains only the extra roles that have access for non-members.
     */
    public List<NGRole> getAccessRoles() throws Exception {
        if (container==null) {
            throw new ProgramLogicError("call to rolesWithAccess must be made AFTER the container is set.");
        }
        List<NGRole> res = new ArrayList<NGRole>();
        List<String> roleNames = getVector("labels");
        for (String name : roleNames) {
            NGRole aRole = container.getRole(name);
            if (aRole!=null) {
                if (!res.contains(aRole)) {
                    res.add(aRole);
                }
            }
        }
        return res;
    }


    /**
    * check if a particular role has access to the particular file.
    * Just handles the 'special' roles, and does not take into consideration
    * the Members or Admin roles, nor whether the attachment is public.
    */
    public boolean roleCanAccess(String roleName) {
        for (String name : getVector("accessRole")) {
            if (roleName.equals(name)) {
                return true;
            }
        }
        return false;
    }


    /**
     * get the labels on a document -- only labels valid in the project,
     * and no duplicates
     */
    public List<NGLabel> getLabels() throws Exception {
        if (container==null) {
            throw new ProgramLogicError("call to getLabels must be made AFTER the container is set.");
        }
        if (!(container instanceof NGWorkspace)) {
            throw new ProgramLogicError("Container must be a Workspace style container.");
        }
        NGWorkspace ngp = container;
        List<NGLabel> res = new ArrayList<NGLabel>();
        for (String name : getVector("labels")) {
            NGLabel aLabel = ngp.getLabelRecordOrNull(name);
            if (aLabel!=null) {
                if (!res.contains(aLabel)) {
                    res.add(aLabel);
                }
            }
        }
        return res;
    }

    /**
     * set the list of labels on a document
     */
    public void setLabels(List<NGLabel> values) throws Exception {
        List<String> labelNames = new ArrayList<String>();
        for (NGLabel aLable : values) {
            labelNames.add(aLable.getName());
        }
        //Since this is a 'set' type vector, always sort them so that they are
        //stored in a consistent way ... so files are more easily compared
        Collections.sort(labelNames);
        setVector("labels", labelNames);
    }

    /**
    * check if document marked with a label
    */
    public boolean hasLabel(String roleName) {
        List<String> labelNames = getVector("labels");
        for (String name : labelNames) {
            if (roleName.equals(name)) {
                return true;
            }
        }
        return false;
    }

    /**
     * Given the current name of this attachment, figure out what the
     * file extension is.  The last dot and the stuff that is after the dot.
     */
    public String getFileExtension() {
        String attachName = getNiceName();
        int dotPos = attachName.lastIndexOf(".");
        if (dotPos>0) {
            return attachName.substring(dotPos);
        }
        return "";
    }


    /**
     * Returns all the meetinsg that have agenda items that are linked to this document
     * attachment.  Should this return agenda items, as well?
     */
    public List<MeetingRecord> getLinkedMeetings(NGWorkspace ngc) throws Exception {
        ArrayList<MeetingRecord> allMeetings = new ArrayList<MeetingRecord>();
        String nid = this.getUniversalId();
        for (MeetingRecord meet : ngc.getMeetings()) {
            boolean found = false;
            if (nid.equals(meet.getMinutesId())) {
                //include the meeting that declared this topic to be its minutes
                found = true;
            }
            else {
                for (AgendaItem ai : meet.getAgendaItems()) {
                    for (String docId : ai.getDocList()) {
                        if (nid.equals(docId)) {
                            found = true;
                        }
                    }
                }
            }
            if (found) {
                allMeetings.add(meet);
            }
        }
        return allMeetings;
    }


    public List<TopicRecord> getLinkedTopics(NGWorkspace ngc) throws Exception {
        ArrayList<TopicRecord> allTopics = new ArrayList<TopicRecord>();
        String nid = this.getUniversalId();
        for (TopicRecord topic : ngc.getAllDiscussionTopics()) {
            boolean found = false;
            for (String docId : topic.getDocList()) {
                if (nid.equals(docId)) {
                    found = true;
                }
            }
            if (found) {
                allTopics.add(topic);
            }
        }
        return allTopics;
    }

    public List<GoalRecord> getLinkedGoals(NGWorkspace ngc) throws Exception {
        ArrayList<GoalRecord> allGoals = new ArrayList<GoalRecord>();
        String nid = this.getUniversalId();
        for (GoalRecord goal : ngc.getAllGoals()) {
            boolean found = false;
            for (String otherId : goal.getDocLinks()) {
                if (nid.equals(otherId)) {
                    found = true;
                }
            }
            if (found) {
                allGoals.add(goal);
            }
        }
        return allGoals;
    }


    /***
     * The purge date is a date that is set up in advance to automatically
     * delete the document.  This is useful for large files that you want to
     * automatically get rid of in the future.
     */
    public long getPurgeDate() {
        return getAttributeLong("purgeDate");
    }
    public void setPurgeDate(long val) {
        setAttributeLong("purgeDate", val);
    }


    public static boolean addEmailStyleAttList(JSONObject jo, AuthRequest ar, NGWorkspace ngp, List<String> docUIDs) throws Exception {
        JSONArray attachInfo = new JSONArray();
        for (String docUID : docUIDs) {
            AttachmentRecord att = ngp.findAttachmentByUidOrNull(docUID);
            if (att!=null) {
                JSONObject jatt = new JSONObject();
                jatt.put("name", att.getNiceName());
                jatt.put("url", ar.baseURL + ar.getResourceURL(ngp, "docinfo" + att.getId() + ".htm?")
                        + AccessControl.getAccessDocParams(ngp, att));
                attachInfo.put(jatt);
            }
        }
        if (attachInfo.length()==0) {
            return false;
        }
        jo.put("attList", attachInfo);
        return true;
    }

    public JSONObject getMinJSON(NGWorkspace ngp) throws Exception {
        JSONObject thisDoc = new JSONObject();
        String univ = getUniversalId();
        thisDoc.put("universalid",  univ);
        thisDoc.put("id",           getId());
        thisDoc.put("name",         getNiceName());
        thisDoc.put("description",  getDescription());
        thisDoc.put("attType",      getType());
        thisDoc.put("size",         getFileSize(ngp));
        thisDoc.put("deleted",      isDeleted());
        thisDoc.put("modifiedtime", getModifiedDate());
        thisDoc.put("modifieduser", getModifiedBy());
        JSONObject labelMap = new JSONObject();
        for (NGLabel lRec : getLabels() ) {
            labelMap.put(lRec.getName(), true);
        }
        thisDoc.put("labelMap",      labelMap);
        if ("URL".equals(getType())) {
            thisDoc.put("url",          getURLValue());
        }
        thisDoc.put("public",       isPublic());
        thisDoc.put("upstream",     isUpstream());
        thisDoc.put("purgeDate",    getPurgeDate());
        return thisDoc;
    }

    public JSONObject getJSON4Doc(AuthRequest ar, NGWorkspace ngp) throws Exception {
        JSONObject thisDoc = getMinJSON(ngp);

        JSONArray allCommentss = new JSONArray();
        for (CommentRecord cr : getComments()) {
            allCommentss.put(cr.getHtmlJSON(ar));
        }
        thisDoc.put("comments",  allCommentss);
        return thisDoc;
    }


    private boolean updateFromJSON(JSONObject docInfo, NGWorkspace ngp, AuthRequest ar) throws Exception {
        boolean changed = false;

        if (docInfo.has("description")) {
            String newDesc = docInfo.getString("description");
            if (!newDesc.equals(this.getDescription())) {
                setDescription(newDesc);
                changed = true;
            }
        }

        if (docInfo.has("public")) {
            if (isPublic() != docInfo.getBoolean("public")) {
                setPublic(docInfo.getBoolean("public"));
                changed = true;
            }
        }

        if (docInfo.has("labelMap")) {
            JSONObject labelMap = docInfo.getJSONObject("labelMap");
            List<NGLabel> selectedLabels = new ArrayList<NGLabel>();
            for (NGLabel stdLabel : ngp.getAllLabels()) {
                String labelName = stdLabel.getName();
                if (labelMap.optBoolean(labelName)) {
                    selectedLabels.add(stdLabel);
                }
            }
            setLabels(selectedLabels);
            changed = true;
        }
        //TODO: this is probably not needed any more
        if (docInfo.has("newComment")) {
            String newValue = docInfo.getString("newComment");
            CommentRecord newCr = addComment(ar);
            newCr.setContentHtml(ar, newValue);
            changed = true;
        }

        if (docInfo.has("url")) {
            if ("URL".equals(getType())) {
                setURLValue(docInfo.getString("url"));
                changed = true;
            }
        }
        if (docInfo.has("purgeDate")) {
            setPurgeDate(docInfo.getLong("purgeDate"));
            changed = true;
        }

        updateCommentsFromJSON(docInfo, ar);

        return changed;
    }



    public JSONObject getJSON4Doc(NGWorkspace ngp, AuthRequest ar, String urlRoot, License license) throws Exception {
        JSONObject thisDoc = getJSON4Doc(ar, ngp);
        String contentUrl = urlRoot + "doc" + getId() + "/"
                    + URLEncoder.encode(getNiceName(), "UTF-8") + "?lic="+ license.getId();
        thisDoc.put("content", contentUrl);
        return thisDoc;
    }

    private static String removeBadChars(String input) {
        StringBuilder ret = new StringBuilder();
        for (int i=0; i<input.length(); i++) {
            char ch = input.charAt(i);
            if (ch<32) {
                continue;
            }
            switch (ch) {
                case '<':
                case '>':
                case ':':
                case '"':
                case '/':
                case '\\':
                case '|':
                case '?':
                case '*':
                    continue;
                default:
                    ret.append(ch);
            }
        }
        return ret.toString();
    }

    public boolean updateDocFromJSON(JSONObject docInfo, AuthRequest ar) throws Exception {
        String universalid = docInfo.getString("universalid");
        if (!universalid.equals(getUniversalId())) {
            //just checking, this should never happen
            throw new Exception("Error trying to update the record for an action item with UID ("
                    +getUniversalId()+") with post from action item with UID ("+universalid+")");
        }
        boolean changed = updateFromJSON(docInfo, (NGWorkspace)ar.ngp, ar);

        if (docInfo.has("name")) {
            String newName = removeBadChars(docInfo.getString("name"));
            if (!newName.equals(getDisplayName())) {
                AttachmentRecord otherFileWithSameName = container.findAttachmentByName(newName);
                if (otherFileWithSameName!=null && (universalid.equals(otherFileWithSameName.getUniversalId()))) {
                    //TODO: better handling duplicate here
                    //This just throws up hands and gives up, and you will get the same next
                    //time.  Better to rename this to a unique name.
                    throw new Exception("Unable to change name to '"+newName
                            +"' because another document already exists with that name.");
                }
                setDisplayName(newName);
                changed = true;
            }
        }

        //Note the following field updates
        //  modifiedtime is set only when a new version is actually created
        //  modifieduser is set only when a new version is actually created
        //  size is the physical size of the file, and never set
        //  local id is an internal local value
        //  universal id has to match before we do anything here
        //  content url is the logical location of the contents, not settable

        if (docInfo.has("deleted")) {
            if (docInfo.getBoolean("deleted")) {
                if (!isDeleted()) {
                    //don't change the deleted user if already deleted
                    setDeleted(ar);
                    changed = true;
                }
            }
            else {
                if (isDeleted()) {
                    clearDeleted();
                    changed = true;
                }
            }
        }
        return changed;
    }

    /**
     * delete all the files on disk or in DB, presumably just
     * before deleting this attachment record.  This effectively
     * clears out the recycle bin, and removes all the physical
     * evidence of a file from the storage.  After calling this
     * the documents are really, truly deleted.
     */
    public void purgeAllVersions(NGContainer ngc) throws Exception {
        AttachmentVersion workCopy = getWorkingCopy(ngc);
        if (workCopy!=null) {
            workCopy.purgeLocalFile();
        }
        for (AttachmentVersion av : getVersions(ngc)) {
            av.purgeLocalFile();
        }
    }



    public String emailSubject() throws Exception {
        return "Attachment: "+getDisplayName();
    }

    public void appendTargetEmails(List<OptOutAddr> sendTo, NGWorkspace ngw) throws Exception {
        OptOutAddr.appendUsersFromRole(ngw, "Members", sendTo);
    }


    public String getEmailURL(AuthRequest ar, NGWorkspace ngw) throws Exception {
        return ar.getResourceURL(ngw,  "docinfo"+this.getId()+".htm");
    }


    public String getUnsubURL(AuthRequest ar, NGWorkspace ngw, long commentId) throws Exception {
        //don't know how to go straight into reply mode, so just go to the meeting
        return getEmailURL(ar, ngw) + "#cmt"+commentId;
    }


    public String selfDescription() throws Exception {
        return "(Attachment) "+getDisplayName();
    }


    public void markTimestamp(long newTime) throws Exception {
        // does not care about timestamp
    }


    public void extendNotifyList(List<AddressListEntry> addressList) throws Exception {
        //there is no subscribers for document attachments
    }

    //This is a callback from container to set the specific fields
    public void addContainerFields(CommentRecord cr) {
        cr.containerType = CommentRecord.CONTAINER_TYPE_TOPIC;
        cr.containerID = this.getId();
    }


    public void gatherUnsentScheduledNotification(NGWorkspace ngw,
            ArrayList<ScheduledNotification> resList, long timeout) throws Exception {
        //only look for comments when the email for the note (topic) has been sent
        //avoids problem of comment getting sent before the topic comes out of draft
        for (CommentRecord cr : getComments()) {
            cr.gatherUnsentScheduledNotification(ngw, new EmailContext(this), resList, timeout);
        }
    }


}
