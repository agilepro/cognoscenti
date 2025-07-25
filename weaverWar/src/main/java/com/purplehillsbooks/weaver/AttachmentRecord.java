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
import java.io.InputStream;
import java.net.URLEncoder;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;

import com.purplehillsbooks.weaver.capture.WebFile;
import com.purplehillsbooks.weaver.exception.WeaverException;
import com.purplehillsbooks.weaver.mail.OptOutAddr;
import com.purplehillsbooks.weaver.mail.ScheduledNotification;
import org.w3c.dom.Document;
import org.w3c.dom.Element;

import com.purplehillsbooks.json.JSONArray;
import com.purplehillsbooks.json.JSONObject;

public class AttachmentRecord extends CommentContainer {
    private static String ATTACHMENT_ATTB_RCTIME = "rctime";

    private String niceName = null;
    protected NGWorkspace container = null;

    public AttachmentRecord(Document doc, Element definingElement, DOMFace attachmentContainer) {
        super(doc, definingElement, attachmentContainer);
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
        // must not have any slash characters in them
        if (newDisplayName.indexOf("/") > 0 || newDisplayName.indexOf("\\") > 0) {
            throw WeaverException.newBasic("Display name for  a workspace must not have any slashes %s", newDisplayName);
        }

        // also, display name needs to be unique within the workspace
        AttachmentRecord otherFileWithSameName = container.findAttachmentByName(newDisplayName);
        if (otherFileWithSameName!=null) {
            throw WeaverException.newBasic("Can't rename this attachment because there is another attachment named %s  in this workspace.",
                    otherFileWithSameName.getDisplayName());
        }

        setAttribute("displayName", newDisplayName);
        niceName = newDisplayName;
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


    public String getLicensedAccessURL(AuthRequest ar, NGWorkspace ngw, String licenseId)
            throws Exception {
        String relativeLink = "a/" + SectionUtil.encodeURLData(getNiceName());
        LicensedURL attPath = new LicensedURL(ar.baseURL + ar.getResourceURL(ngw, relativeLink),
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

    private File getWebPageFile() {
        String fileName = "webPage"+getId()+".json";
        File workspaceFolder = container.containingFolder;
        File cogFolder = new File(workspaceFolder, ".cog");
        File webFilePath = new File(cogFolder, fileName);
        return webFilePath;
    }

    public boolean doesWebFileExist() {
        File webFilePath = getWebPageFile();
        return webFilePath.exists();
    }

    public WebFile getWebFile() throws Exception {
        if (!isURL()) {
            throw WeaverException.newBasic("Attempt to download web page, but this is not a web page attachment (%s)", getId());
        }
        File webFilePath = getWebPageFile();
        return WebFile.readOrCreate(webFilePath, getURLValue());
    }

    public void refreshWebFile() throws Exception {

        WebFile wf = getWebFile();
        wf.refreshFromWeb();
        wf.save();
    }

    /**
     * There are three types of attachment:
     *
     * FILE: this is a local path into the
     *    attachments repository
     * URL: this is a URL to an external web addressable
     *    content store
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
    public boolean isFile() {
        return "FILE".equals(getType());
    }
    public boolean isURL() {
        return "URL".equals(getType());
    }

    public void setType(String type) {
        // check that a valid string id being passed
        // this is a program logic exception since the user never enters
        // the type of attachment
        if (!type.equals("FILE") && !type.equals("URL")) {
            throw new RuntimeException("Attachment type has to be either FILE, or URL");
        }
        setAttribute("type", type);
    }

    public AddressListEntry getModifier() {
        String modifiedBy = checkAndReturnAttributeValue("modifiedBy");

        //clean up old email addresses, and send latest if found
        return AddressListEntry.findOrCreate(modifiedBy);
    }
    public String getModifiedBy() {
        //clean up old email addresses, and send latest if found
        AddressListEntry user = getModifier();
        return user.getEmail();
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

    public void createHistory(AuthRequest ar, NGWorkspace ngw, int event, String comment)
            throws Exception {
        HistoryRecord.createHistoryRecord(ngw, getId(), HistoryRecord.CONTEXT_TYPE_DOCUMENT,
                getModifiedDate(), event, ar, comment);
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
    public List<AttachmentVersion> getVersions(NGWorkspace ngc)
        throws Exception {
        if (!(ngc instanceof NGWorkspace)) {
            throw WeaverException.newBasic("Problem: workspace Attachment should only belong to NGWorkspace, "
                    +"but somehow got a different kind of container.");
        }

        File workspaceFolder = ngc.containingFolder;
        if (workspaceFolder==null) {
            throw WeaverException.newBasic("NGWorkspace container has no containing folder????");
        }

        List<AttachmentVersion> list =
            AttachmentVersion.getDocVersions(workspaceFolder, this);

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
    public AttachmentVersion getLatestVersion(NGWorkspace ngc) throws Exception {

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
    public AttachmentVersion getSpecificVersion(NGWorkspace ngc, int version) throws Exception {

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



    public AttachmentVersion getHighestCommittedVersion(NGWorkspace ngc) throws Exception {
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
     * Provide an input stream to the contents of the new version, and this
     * method will copy the contents into here, and then create a new version
     * for that file, and return the AttachmentVersion object that represents
     * that new version.
     */
    public AttachmentVersion streamNewVersion(AuthRequest ar, NGWorkspace ngc, InputStream contents)
            throws Exception {
        return streamNewVersion(ngc, contents, ar.getBestUserId(), ar.nowTime);
    }

    /**
    * Provide an input stream to the contents of the new version, and this method will
    * copy the contents into here, and then create a new version for that file, and
    * return the AttachmentVersion object that represents that new version.
    */
    public AttachmentVersion streamNewVersion(NGWorkspace ngw, InputStream contents,
            String userId, long timeStamp) throws Exception {

        if (!(ngw instanceof NGWorkspace)) {
            throw WeaverException.newBasic("Problem: workspace Attachment should only belong to NGWorkspace, but somehow got a different kind of container.");
        }
        File workspaceFolder = ngw.containingFolder;
        if (workspaceFolder==null) {
            throw WeaverException.newBasic("NGWorkspace container has no containing folder????");
        }

        //in case the attachment is deleted, undelete it for this new version
        clearDeleted();

        AttachmentVersion av = AttachmentVersion.getNewWorkspaceVersion(workspaceFolder,
                this, contents);

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
     * Tells whether there is a file behind this that can be served up
     */
    public boolean hasContents() {
        // url is the only type without contents
        return !("URL".equals(getType()));
    }

    /**
     * return the size of the file in bytes
     */
    public long getFileSize(NGWorkspace ngw) throws Exception {
        if (!"FILE".equals(getType()) || isDeleted()) {
            return -1;
        }
        AttachmentVersion av = getLatestVersion(ngw);
        if (av==null) {
            return -1;
        }
        File f = av.getLocalFile();
        return f.length();
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
     * get the labels on a document -- only labels valid in the workspace,
     * and no duplicates
     */
    public List<NGLabel> getLabels() throws Exception {
        if (container==null) {
            throw WeaverException.newBasic("call to getLabels must be made AFTER the container is set.");
        }
        if (!(container instanceof NGWorkspace)) {
            throw WeaverException.newBasic("Container must be a Workspace style container.");
        }
        NGWorkspace ngw = container;
        List<NGLabel> res = new ArrayList<NGLabel>();
        for (String name : getVector("labels")) {
            NGLabel aLabel = ngw.getLabelRecordOrNull(name);
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
    public List<MeetingRecord> getLinkedMeetings(NGWorkspace ngw) throws Exception {
        ArrayList<MeetingRecord> allMeetings = new ArrayList<MeetingRecord>();
        String nid = this.getUniversalId();
        for (MeetingRecord meet : ngw.getMeetings()) {
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


    public List<TopicRecord> getLinkedTopics(NGWorkspace ngw) throws Exception {
        ArrayList<TopicRecord> allTopics = new ArrayList<TopicRecord>();
        String nid = this.getUniversalId();
        for (TopicRecord topic : ngw.getAllDiscussionTopics()) {
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

    public List<GoalRecord> getLinkedGoals(NGWorkspace ngw) throws Exception {
        ArrayList<GoalRecord> allGoals = new ArrayList<GoalRecord>();
        String nid = this.getUniversalId();
        for (GoalRecord goal : ngw.getAllGoals()) {
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


    public static boolean addEmailStyleAttList(JSONObject jo, AuthRequest ar, NGWorkspace ngw, List<String> docUIDs) throws Exception {
        JSONArray attachInfo = new JSONArray();
        for (String docUID : docUIDs) {
            AttachmentRecord att = ngw.findAttachmentByUidOrNull(docUID);
            if (att!=null) {
                JSONObject jatt = new JSONObject();
                jatt.put("name", att.getNiceName());
                jatt.put("url", ar.baseURL + ar.getResourceURL(ngw, "DocDetail.htm?aid=" + att.getId())
                        + "&" + AccessControl.getAccessDocParams(ngw, att));
                attachInfo.put(jatt);
            }
        }
        if (attachInfo.length()==0) {
            return false;
        }
        jo.put("attList", attachInfo);
        return true;
    }

    public JSONObject getLinkableJSON() throws Exception {
        JSONObject thisDoc = new JSONObject();
        thisDoc.put("id", this.getId());
        thisDoc.put("name", this.getNiceName());
        thisDoc.put("universalid",  getUniversalId());
        return thisDoc;
    }

    public JSONObject getMinJSON(NGWorkspace ngw) throws Exception {
        JSONObject thisDoc = getLinkableJSON();
        thisDoc.put("description",  getDescription());
        thisDoc.put("attType",      getType());
        thisDoc.put("size",         getFileSize(ngw));
        thisDoc.put("deleted",      isDeleted());
        thisDoc.put("modifiedtime", getModifiedDate());
        thisDoc.put("modifieduser", getModifiedBy());
        thisDoc.put("modifier",     getModifier().getJSON());
        JSONObject labelMap = new JSONObject();
        for (NGLabel lRec : getLabels() ) {
            labelMap.put(lRec.getName(), true);
        }
        thisDoc.put("labelMap",      labelMap);
        if ("URL".equals(getType())) {
            thisDoc.put("url",          getURLValue());
        }
        thisDoc.put("purgeDate",    getPurgeDate());
        return thisDoc;
    }

    public JSONObject getJSON4Doc(AuthRequest ar, NGWorkspace ngw) throws Exception {
        JSONObject thisDoc = getMinJSON(ngw);

        JSONArray allCommentss = new JSONArray();
        for (CommentRecord cr : getComments()) {
            allCommentss.put(cr.getJSONWithDocs(ngw));
        }
        thisDoc.put("comments",  allCommentss);

        if (ar.canAccessWorkspace()) {
            //this should only be given to members, it allows them to give
            //others access to the document.  Some people getting document
            //info do not have access to the document, and therefor this prevents
            //them from giving themselves (or anyone else) access.
            thisDoc.put("magicNumber", AccessControl.getAccessDocParams(ngw, this));
        }

        JSONArray versions = new JSONArray();
        for (AttachmentVersion av : getVersions(ngw)) {
            versions.put(av.getJSON());
        }
        thisDoc.put("versions",  versions);

        return thisDoc;
    }


    private boolean updateFromJSON(JSONObject docInfo, NGWorkspace ngw, AuthRequest ar) throws Exception {
        boolean changed = false;

        if (docInfo.has("description")) {
            String newDesc = docInfo.getString("description");
            if (!newDesc.equals(this.getDescription())) {
                setDescription(newDesc);
                changed = true;
            }
        }

        if (docInfo.has("labelMap")) {
            JSONObject labelMap = docInfo.getJSONObject("labelMap");
            List<NGLabel> selectedLabels = new ArrayList<NGLabel>();
            for (NGLabel stdLabel : ngw.getAllLabels()) {
                String labelName = stdLabel.getName();
                if (labelMap.optBoolean(labelName)) {
                    selectedLabels.add(stdLabel);
                }
            }
            setLabels(selectedLabels);
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



    public JSONObject getJSON4Doc(NGWorkspace ngw, AuthRequest ar, String urlRoot, License license) throws Exception {
        JSONObject thisDoc = getJSON4Doc(ar, ngw);
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
        ar.assertAccessWorkspace("AuthRequest must be initialized on a Workspace");
        String universalid = docInfo.getString("universalid");
        if (!universalid.equals(getUniversalId())) {
            //just checking, this should never happen
            throw WeaverException.newBasic("Error trying to update the record for an action item with UID (%s) with post from action item with UID (%s)", getUniversalId(), universalid);
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
                    throw WeaverException.newBasic("Unable to change name '%s' because another document already exists with that name.", newName);
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
    public void purgeAllVersions(NGWorkspace ngw) throws Exception {
        for (AttachmentVersion av : getVersions(ngw)) {
            av.purgeLocalFile();
        }
    }



    public String emailSubject() throws Exception {
        return "Document: "+getDisplayName();
    }

    public void appendTargetEmails(List<OptOutAddr> sendTo, NGWorkspace ngw) throws Exception {
        OptOutAddr.appendUsersFromRole(ngw, "MembersRole", sendTo);
    }


    public String getEmailURL(AuthRequest ar, NGWorkspace ngw) throws Exception {
        return ar.getResourceURL(ngw,  "DocDetail.htm?aid="+this.getId());
    }


    public String getUnsubURL(AuthRequest ar, NGWorkspace ngw, long commentId) throws Exception {
        //don't know how to go straight into reply mode, so just go to the meeting
        return ar.getResourceURL(ngw,  "CommentZoom.htm?cid="+commentId);
    }


    public String selfDescription() throws Exception {
        return "(Attachment) "+getDisplayName();
    }


    public void extendNotifyList(List<AddressListEntry> addressList) throws Exception {
        //there is no subscribers for document attachments
    }

    //This is a callback from container to set the specific fields
    public void addContainerFields(CommentRecord cr) {
        cr.containerType = CommentRecord.CONTAINER_TYPE_ATTACHMENT;
        cr.containerID = this.getId();
        cr.containerName = this.getNiceName();
    }


    public void gatherUnsentScheduledNotification(NGWorkspace ngw,
            ArrayList<ScheduledNotification> resList, long timeout) throws Exception {
        //only look for comments when the email for the note (topic) has been sent
        //avoids problem of comment getting sent before the topic comes out of draft
        for (CommentRecord cr : getComments()) {
            cr.gatherUnsentScheduledNotification(ngw, new EmailContext(this), resList, timeout);
        }
    }

    /**
     * We used to keep a duplicate copy of the file in the workspace directory.
     * That is, one copy in the workspace directory, and then a file for
     * every version in the .cog folder.   We only need the versions inside
     * the cog folder, so get rid of the extra copy in the workspace folder.
     */
    public void purgeUnnecessaryDuplicate() {
        File currentFile = new File(container.containingFolder, getNiceName());
        if (currentFile.exists()) {
            currentFile.delete();
        }
        if (currentFile.exists()) {
            throw new RuntimeException("Tried and failed to delete file: "+currentFile.getAbsolutePath());
        }
    }

    public String getGlobalContainerKey(NGWorkspace ngw) {
        return "A"+getId();
    }

}
