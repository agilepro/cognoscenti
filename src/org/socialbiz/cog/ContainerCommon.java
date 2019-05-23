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
import java.util.ArrayList;
import java.util.List;
import java.util.Random;

import org.socialbiz.cog.dms.ConnectionSettings;
import org.socialbiz.cog.dms.ConnectionType;
import org.socialbiz.cog.dms.ResourceEntity;
import org.socialbiz.cog.exception.NGException;
import org.socialbiz.cog.exception.ProgramLogicError;
import org.w3c.dom.Document;

/**
* The three classes: NGPage, NGBook, and UserPage are all DOMFile classes, and there
* are some methods that they can easily share.  This class is an abstract base class
* so that these classes can easily share a few methods.
*/
public abstract class ContainerCommon extends NGContainer
{
    DOMFace attachParent;
    DOMFace noteParent;
    DOMFace roleParent;
    DOMFace historyParent;
    DOMFace infoParent;


    public ContainerCommon(File path, Document doc) throws Exception
    {
        super(path, doc);
        attachParent = getAttachmentParent();
        noteParent   = getNoteParent();
        roleParent   = getRoleParent();
        historyParent = getHistoryParent();
        infoParent    = getInfoParent();
    }


    /**
     * Here is how schema version works.   Each major file object will declare what
     * the current schema version and set it here for saving in the file.
     * A file is ALWAYS written at the current schema version.
     *
     * Every time a file is read, all the schema upgrades are applied on reading, generally
     * in the constructor.  So the version of the file IN MEMORY is always the latest schema,
     * so you can always write out the memory and always the latest schema.
     *
     * But ... lots of files a read but not written.  So the file on disk might be many schema versions
     * behind.
     *
     * Before saving, if the schema had been out of date, then a
     * pass is made to touch all the sub-objects, and make sure that all objects are at the
     * current schema level.  Then the file is written.
     *
     * RULE FOR MANAGING VERSION
     * Every time any schema change is that requires schema update, the whole file schema
     * versions is incremented.  You must make sure that the schema update method touches
     * that component (with a constructor so that it is certain to be upgraded.  The we are
     * assured that the entire file is current and can be written.
     *
     * EXAMPLE
     * You have a file with schema version 68.
     * You make a change in the CommentRecord that requires a schema migration.
     * (1) You bump the schema version to 69.
     * (2) You make a comment that the CommentRecord change is what caused increment to 69.
     * (3) You make sure that the schemaUpgrade method touches (and upgrades) all comments.
     *
     * That is it.  The reason for making the comment is because in the future, we might be able
     * to determine that there no longer exist any files (anywhere in the world) with schema <= 68.
     * When that happens we will be able to remove the code that does the schema migration to 69.
     *
     * The next schema change, anywhere in the code, will bump the schema version to 70 and the
     * same assurances about making sure that schemaUpgrade touches the object in the right way.
     */
    public int getSchemaVersion()  {
        return getAttributeInt("schemaVersion");
    }
    /**
     * Only set schema version AFTER schemaUpgrade has been called and you know that the schema
     * is guaranteed to be up to date.
     */
    private void setSchemaVersion(int val)  {
        setAttributeInt("schemaVersion", val);
    }
    /**
     * The implementation of this must touch all objects in the file and make sure that
     * the internal structure is set to the latest schema.
     */
    abstract public void schemaUpgrade(int fromLevel, int toLevel) throws Exception;
    abstract public int currentSchemaVersion();

    public void save() throws Exception {
        int sv = getSchemaVersion();
        int current = currentSchemaVersion();
        if (sv<current) {
            schemaUpgrade(sv, current);
            setSchemaVersion(current);
        }
        super.save();
    }



    //these are methods that the extending classes need to implement so that this class will work
    public abstract String getUniqueOnPage() throws Exception;
    protected abstract DOMFace getAttachmentParent() throws Exception;
    protected abstract DOMFace getNoteParent() throws Exception;
    protected abstract DOMFace getRoleParent() throws Exception;
    protected abstract DOMFace getHistoryParent() throws Exception;
    protected abstract DOMFace getInfoParent() throws Exception;
    public abstract NGRole getPrimaryRole() throws Exception;
    public abstract NGRole getSecondaryRole() throws Exception;




    public abstract List<AttachmentRecord> getAllAttachments() throws Exception;

    /**
     * This determines the subset of all the documents that a particular user
     * can access, either because the document is public, because the user is
     * a Member or Owner, or because they are in a role that has access.
     */
    public List<AttachmentRecord> getAccessibleAttachments(UserProfile up) throws Exception {
        List<NGRole> rolesPlayed = findRolesOfPlayer(up);
        List<AttachmentRecord> aList = new ArrayList<AttachmentRecord>();
        for(AttachmentRecord attachment : getAllAttachments()) {
            if (attachment.isDeleted()) {
                continue;
            }
            if (attachment.isPublic()) {
                aList.add(attachment);
                continue;
            }
            if (up==null) {
                continue;
            }
            if (primaryOrSecondaryPermission(up)) {
                aList.add(attachment);
                continue;
            }
            for (NGRole ngr : rolesPlayed) {
                if (attachment.roleCanAccess(ngr.getName())) {
                    aList.add(attachment);
                    break;
                }
            }
        }
        return aList;
    }


    /**
     * Can use either the short ID or the Universal ID
     */
    public AttachmentRecord findAttachmentByID(String id) throws Exception {
        for (AttachmentRecord att : getAllAttachments()) {
            if (id.equals(att.getId()) || id.equals(att.getUniversalId())) {
                return att;
            }
        }
        return null;
    }

    public AttachmentRecord findAttachmentByIDOrFail(String id) throws Exception {

        AttachmentRecord ret =  findAttachmentByID( id );

        if (ret==null)
        {
            throw new NGException("nugen.exception.unable.to.locate.att.with.id", new Object[]{id, getFullName()});
        }
        return ret;
    }

    public AttachmentRecord findAttachmentByName(String name) throws Exception {
        for (AttachmentRecord att : getAllAttachments()) {
            if (att.equivalentName( name )) {
                return att;
            }
        }
        return null;
    }
    public AttachmentRecord findAttachmentByUidOrNull(String universalId) throws Exception {
        for (AttachmentRecord att : getAllAttachments()) {
            if (universalId.equals(att.getUniversalId())) {
                return att;
            }
        }
        return null;
    }
    public AttachmentRecord findAttachmentByNameOrFail(String name) throws Exception {

        AttachmentRecord ret =  findAttachmentByName( name );

        if (ret==null)
        {
            throw new NGException("nugen.exception.unable.to.locate.att.with.name", new Object[]{name, getFullName()});
        }
        return ret;
    }

    public abstract AttachmentRecord createAttachment() throws Exception;
    /* {
        AttachmentRecord attach = attachParent.createChild("attachment", AttachmentRecord.class);
        String newId = getUniqueOnPage();
        attach.setId(newId);
        attach.setContainer(this);

        //this is the default, but it might be overridden in case of sync from another workspace
        attach.setUniversalId( getContainerUniversalId() + "@" + newId );
        return attach;
    }*/

    public void deleteAttachment(String id,AuthRequest ar) throws Exception {
        AttachmentRecord att = findAttachmentByIDOrFail( id );
        att.setDeleted( ar );
    }


    public void unDeleteAttachment(String id) throws Exception {
        AttachmentRecord att = findAttachmentByIDOrFail( id );
        att.clearDeleted();
    }

    public void eraseAttachmentRecord(String id) throws Exception {
        AttachmentRecord att = findAttachmentByIDOrFail( id );
        attachParent.removeChild(att);
    }
    public void purgeDeletedAttachments() throws Exception {
        List<AttachmentRecord> cleanList = new ArrayList<AttachmentRecord>();
        for (AttachmentRecord ar : getAllAttachments()) {
            if (!ar.isDeleted()) {
                //don't purge or do anything to non-deleted attachments
                continue;
            }
            ar.purgeAllVersions(this);
            cleanList.add(ar);
        }
        for (AttachmentRecord ar : cleanList) {
            eraseAttachmentRecord(ar.getId());
        }
    }


    public File getAttachmentPathOrNull(String oneId) throws Exception {

        AttachmentRecord attach = this.findAttachmentByID(oneId);
        if (attach==null) {
            //attachments might get removed in the mean time, just ignore them
            //throw new Exception("getAttachmentPathFromContainer was called with an invalid ID?: "+oneId);
            return null;
        }
        AttachmentVersion aVer = attach.getLatestVersion(this);
        if (aVer==null) {
            //throw new Exception("Apparently there are no file versions of ID: "+oneId);
            return null;
        }
        return(aVer.getLocalFile());
    }

    /**
    * Returns the ResourceEntity that represents the remote folder that files
    * can be stored in.  Returns null if not set.
    */
    public ResourceEntity getDefRemoteFolder() throws Exception {
        String userKey = getDefUserKey();
        String connId = getDefFolderId();
        String fullPath = getDefLocation();
        if (userKey==null || userKey.length()==0 || connId==null || connId.length()==0 ||
            fullPath==null || fullPath.length()==0 ) {
            return null;
        }
        UserPage uPage = UserManager.getStaticUserManager().findOrCreateUserPage(userKey);
        ConnectionSettings defCSet = uPage.getConnectionSettingsOrNull(connId);
        if (defCSet==null) {
            //if ID is invalid, treat it like it does not exist
            return null;
        }
        ConnectionType cType = defCSet.getConnectionOrFail();
        return cType.getResource(fullPath);
    }
    /**
    * Pass a null to clear the setting
    */
    public void setDefRemoteFolder(ResourceEntity loc) throws Exception {
        if (loc==null) {
            setDefUserKey(null);
            setDefFolderId(null);
            setDefLocation(null);
            return;
        }

        ConnectionType cType = loc.getConnection();
        setDefUserKey(cType.getOwnerKey());
        setDefFolderId(loc.getFolderId());
        setDefLocation(loc.getFullPath());
    }


    public String getDefLocation() throws Exception {
        DOMFace attachElement  = getAttachmentParent();
        return attachElement.getAttribute("defaultRepository");
    }

    public void setDefLocation(String loc) throws Exception {
        DOMFace attachElement  = getAttachmentParent();
        attachElement.setAttribute("defaultRepository", loc);
    }

    public String getDefFolderId() throws Exception {
        DOMFace attachElement  = getAttachmentParent();
        return attachElement.getAttribute("defaultFolderId");
    }

    public void setDefFolderId(String folderId) throws Exception {
        DOMFace attachElement  = getAttachmentParent();
        attachElement.setAttribute("defaultFolderId", folderId);
    }

    public String getDefUserKey() throws Exception {
        DOMFace attachElement  = getAttachmentParent();
        return attachElement.getAttribute("defaultUserKey");
    }

    public void setDefUserKey(String userKey) throws Exception {
        DOMFace attachElement  = getAttachmentParent();
        attachElement.setAttribute("defaultUserKey", userKey);
    }



    //////////////////// ROLES ///////////////////////


    public boolean primaryPermission(UserRef user) throws Exception {
        if (user==null) {
            throw new ProgramLogicError("primaryPermission called with null user object.");
        }
        return getPrimaryRole().isExpandedPlayer(user, this);
    }
    public boolean primaryOrSecondaryPermission(UserRef user) throws Exception {
        if (primaryPermission(user))
        {
            return true;
        }
        if (secondaryPermission(user))
        {
            return true;
        }
        if (this instanceof NGPage)
        {
            throw new ProgramLogicError("NGPage overrides this, so this should never happen");
        }
        return false;
    }

    public boolean secondaryPermission(UserRef user) throws Exception {
        if (user==null) {
            throw new ProgramLogicError("secondaryPermission called with null user object.");
        }
        return getSecondaryRole().isExpandedPlayer(user, this);
    }



    public List<CustomRole> getAllRoles() throws Exception {
        return roleParent.getChildren("role", CustomRole.class);
    }

    public CustomRole getRole(String roleName) throws Exception {
        for (CustomRole role : getAllRoles()) {
            if (roleName.equals(role.getName())) {
                return role;
            }
        }
        return null;
    }

    public CustomRole getRoleOrFail(String roleName) throws Exception {
        CustomRole ret = getRole(roleName);
        if (ret==null)
        {
            throw new NGException("nugen.exception.unable.to.locate.role.with.name", new Object[]{roleName, getFullName()});
        }
        return ret;
    }

    public CustomRole createRole(String roleName, String description)
            throws Exception {
        if (roleName==null || roleName.length()==0) {
            throw new NGException("nugen.exception.role.cant.be.empty",null);
        }

        NGRole existing = getRole(roleName);
        if (existing!=null) {
            throw new NGException("nugen.exception.cant.create.new.role", new Object[]{roleName});
        }
        CustomRole newRole = roleParent.createChild("role", CustomRole.class);
        newRole.setName(roleName);
        newRole.setDescription(description);
        return newRole;
    }

    public void deleteRole(String name) throws Exception {
        NGRole role = getRole(name);
        if (role!=null) {
            roleParent.removeChild((DOMFace)role);
        }
    }


    /**
    * just a shortcut for getRole(roleName).addPlayer(newMember)
    */
    public void addPlayerToRole(String roleName,String newMember)throws Exception
    {
        NGRole role= getRoleOrFail(roleName);
        role.addPlayer(new AddressListEntry(newMember));
    }

    public List<NGRole> findRolesOfPlayer(UserRef user) throws Exception {
        List<NGRole> res = new ArrayList<NGRole>();
        if (user==null) {
            return res;
        }
        for (NGRole role : getAllRoles()) {
            if (role.isExpandedPlayer(user, this)) {
                res.add(role);
            }
        }
        return res;
    }

    //////////////////// HISTORY ///////////////////////

    public List<HistoryRecord> getAllHistory()
            throws Exception
    {
        List<HistoryRecord> vect = historyParent.getChildren("event", HistoryRecord.class);
        HistoryRecord.sortByTimeStamp(vect);
        return vect;
    }

    public List<HistoryRecord>  getHistoryForResource(int contextType, String id) throws Exception {
        List<HistoryRecord> allHist = historyParent.getChildren("event", HistoryRecord.class);
        List<HistoryRecord> newHist = new ArrayList<HistoryRecord>();
        for (HistoryRecord hr : allHist) {
            if (contextType != hr.getContextType()) {
                continue;
            }
            if (!id.equals(hr.getContext())) {
                continue;
            }
            newHist.add(hr);
        }
        HistoryRecord.sortByTimeStamp(newHist);
        return newHist;
    }   
    
    
    public List<HistoryRecord> getHistoryRange(long startTime, long endTime)
            throws Exception
    {
        List<HistoryRecord> allHist = historyParent.getChildren("event", HistoryRecord.class);
        List<HistoryRecord> newHist = new ArrayList<HistoryRecord>();
        for (HistoryRecord hr : allHist)
        {
            long eventTime = hr.getTimeStamp();
            if (eventTime > startTime && eventTime <= endTime)
            {
                newHist.add(hr);
            }
        }
        HistoryRecord.sortByTimeStamp(newHist);
        return newHist;
    }

    public void copyHistoryForResource(NGContainer ngc, int contextType, String oldID, String newID) throws Exception
    {
        for (HistoryRecord oldHist : ngc.getAllHistory())
        {
            int histContextType = oldHist.getContextType();
            if (histContextType!=contextType) {
                continue;
            }
            String contextId = oldHist.getContext();
            if (!oldID.equals(contextId)) {
                continue;
            }

            HistoryRecord newHist = createNewHistory();
            newHist.copyFrom(oldHist);
            newHist.setContext(newID);
        }
    }


    public HistoryRecord createNewHistory()
        throws Exception
    {
        HistoryRecord newHist = historyParent.createChild("event", HistoryRecord.class);
        newHist.setId(getUniqueOnPage());
        return newHist;
    }
    
    public HistoryRecord getLatestHistory() throws Exception {
        List<HistoryRecord> allSortedHist = getAllHistory();
        if (allSortedHist.size()==0) {
            return null;
        }
        return allSortedHist.get(0);
    }


    ////////////////////// WRITE LINKS //////////////////////////

    public void writeContainerLink(AuthRequest ar, int len) throws Exception{
        throw new ProgramLogicError("writeContainerLink not implemented");
    }

    public void writeDocumentLink(AuthRequest ar, String id, int len) throws Exception{
        throw new ProgramLogicError("not implemented");
    }

    public void writeReminderLink(AuthRequest ar, String id, int len) throws Exception{
        throw new ProgramLogicError("writeDocumentLink not implemented");
    }

    public void writeTaskLink(AuthRequest ar, String id, int len) throws Exception{
        throw new ProgramLogicError("writeTaskLink not implemented");
    }

    public void writeNoteLink(AuthRequest ar, String id, int len) throws Exception{
        throw new ProgramLogicError("writeNoteLink not implemented");
    }


    public String trimName(String nameOfLink, int len)
    {
        if (nameOfLink.length()>len)
        {
            return nameOfLink.substring(0,len-1)+"...";
        }
        return nameOfLink;
    }

    /**
    * get a role, and create it if not found.
    */
    protected NGRole getRequiredRole(String roleName) throws Exception
    {
        NGRole role = getRole(roleName);
        if (role==null)
        {
            String desc = roleName+" of the workspace "+getFullName();
            String elegibility = "";
            if ("Executives".equals(roleName))
            {
                desc = "The role 'Executives' contains a list of people who are assigned to the site "
                +"as a whole, and are automatically members of every workspace in that site.  ";
            }
            else if ("Members".equals(roleName))
            {
                desc = "Members of a project can see and edit any of the content in the workspace.  "
                       +"Members can create, edit, and delete topics, can upload, download, and delete documents."
                       +"Members can approve other people to become members or other roles.";
            }
            else if ("Administrators".equals(roleName))
            {
                desc = "Administrators have all the rights that Members have, but have additional ability "
                       +"to manage the structure of the workspace, to add/remove roles, and to exercise greater "
                       +"control over a workspace, such as renaming and deleting a workspace.";
            }
            else if ("Notify".equals(roleName))
            {
                desc = "People who are not members, but who receive email notifications anyway.";
            }
            else if ("Facilitator".equals(roleName))
            {
                desc = "Selected by the circle members to lead circle meetings. Moves agenda forward, "
                        +"keeps everyone focused on the aim. Helps prepare the meeting agenda.";
                elegibility = "Good judgement. Integrity. Listens and empathizes effectively. Can hold "
                        +"the big picture of an issue. Articulate. Both a sense of humor and able to be firm.";
            }
            else if ("Circle Administrator".equals(roleName))
            {
                desc = "Personally handles or oversees: circle meeting venue, creating agendas, taking "
                        +"minutes in collaboration with facilitator, and keeping the records organized.";
                elegibility = "Familiar with electronic media. Organized. Articulate. Reliable. Takes initiative.";
            }
            else if ("Operations Leader".equals(roleName))
            {
                desc = "Outside of circle meetings, guides the day-to-day operations by directing, "
                        +"coordinating, and conveying news, ideas, suggestions, needs, requests. "
                        +"Selected to role by higher (more abstract) circle. ";
                elegibility = "Inspires respect. Good judgement. Effective interpersonal skills. "
                        +"Takes initiative. Can both hold the big picture and pay attention to details. "
                        +"Both a sense of humor and able to be firm";
            }
            else if ("Representative".equals(roleName))
            {
                desc = "Outside of circle meetings, guides the day-to-day operations by directing, "
                        +"coordinating, and conveying news, ideas, suggestions, needs, requests. "
                        +"Selected to role by higher (more abstract) circle.";
                elegibility = "Inspires respect. Good judgement. Effective interpersonal skills. "
                        +"Takes initiative. Can both hold the big picture and pay attention to details. "
                        +"Both a sense of humor and able to be firm.";
            }
            else if ("External Expert".equals(roleName))
            {
                desc = "Person from outside the company who has expertise about the company�s environment, "
                        +"eg, regulatory, economic, social, technical, or ecology. Able to provide information "
                        +"and feedback not available inside the company and to inform or influence key "
                        +"external institutions. ";
                elegibility = "Expertise in and well-connected to a field important to the company. "
                        +"Experienced. Able to think rationally at the most abstract level of the company�s work. "
                        +"Well-prepared. Forward thinking.";
            }
            else
            {
                //I don't know of any other required roles, if so, we should have a
                //better description than this.
            }
            role = createRole(roleName, desc);
            role.setRequirements(elegibility);
        }
        return role;
    }

    /**
    * The purpose of this, is to generate a unique magic number
    * for any given email id for this page.  Links to this
    * page could include this magic number, and it will allow
    * a person with that email address access to this page.
    * It will prove that they have been sent the magic number,
    * and proof that they received it, and therefor proof that
    * they own the email address.
    *
    * Pass the email address that you are sending to, and this will
    * return the magic number.   When the user clicks on the link
    * match the magic number in the link, with the magic number
    * generated here, to make sure they are not hacking their way in.
    *
    * The URL that the user clisk on must have BOTH the email address
    * and the magic number in it, because they are precisely paired.
    * Don't expect to get the email address from other part of
    * environment, because remember that email addresses are sometimes
    * transformed through the sending of the document.
    *
    * The magic number is ephemeral.  They need to last long enough
    * for someone to receive the email and click on the link,
    * so they have to last for days at least, probably weeks.
    * This algorithm generates a magic number that will last
    * permanently as long as the workspace lasts.  This is good because
    * there is no real way to migrate to a new algorithm for generating
    * the magic numbers.  But in practice
    * this algorithm might be changed at any time, causing discomfort
    * to those users that just received links, but presumably they
    * would soon receive new links with the new numbers in them.
    * There is no real requirement that the number last *forever*.
    */
    public String emailDependentMagicNumber(String emailId)
        throws Exception
    {
        String encryptionPad = getScalar("encryptionPad");
        if (encryptionPad==null || encryptionPad.length()!=30)
        {
            StringBuilder tmp = new StringBuilder();
            Random r = new Random();
            for (int i=0; i<30; i++)
            {
                //generate a random character >32 and <10000
                char ch = (char) (r.nextInt(9967) + 33);
                tmp.append(ch);
            }
            encryptionPad = tmp.toString();
            setScalar("encryptionPad", encryptionPad);
        }

        long chksum = 0;

        for (int i=0; i<30; i++)
        {
            char ch1 = encryptionPad.charAt(i);
            char ch2 = 'x';
            if (i < emailId.length())
            {
                ch2 = emailId.charAt(i);
            }
            int partial = ch1 ^ ch2;
            chksum = chksum + (partial*partial);
        }

        StringBuilder gen = new StringBuilder();

        while (chksum>0)
        {
            char gch = (char)('A' +  (chksum % 26));
            chksum = chksum / 26;
            gen.append(gch);
            gch = (char) ('0' + (chksum % 10));
            chksum = chksum / 10;
            gen.append(gch);
        }

        return gen.toString();
    }

    public RoleRequestRecord getRoleRequestRecordById(String requestId) throws Exception{
        RoleRequestRecord requestRecord = null;
        for (RoleRequestRecord roleRequestRecord : getAllRoleRequest()) {
            if(roleRequestRecord.getAttribute("id").equalsIgnoreCase(requestId)){
                requestRecord = roleRequestRecord;
                break;
            }
        }
        return requestRecord;
    }

    public List<RoleRequestRecord> getAllRoleRequestByState(String state, boolean completedReq) throws Exception{
        List<RoleRequestRecord> resultList = new ArrayList<RoleRequestRecord>();
        for (RoleRequestRecord roleRequestRecord : getAllRoleRequest()) {
            if(roleRequestRecord.getState().equalsIgnoreCase(state)
                    && completedReq == roleRequestRecord.isCompleted()){
                resultList.add(roleRequestRecord);
            }
        }
        return resultList;
    }

    public boolean isAlreadyRequested(String roleName, String requestedBy) throws Exception{
        for (RoleRequestRecord roleRequestRecord : getAllRoleRequestByState("Requested", false)) {
            if(requestedBy.equals(roleRequestRecord.getRequestedBy())
                    && roleName.equals(roleRequestRecord.getRoleName())){
                return true;
            }
        }
        return false;
    }

    //TODO: If there are two, it gets the latest, ignoring earlier requests.
    //how do they get removed??
    //Are they reused??
    public RoleRequestRecord getRoleRequestRecord(String roleName, String requestedBy) throws Exception {
        RoleRequestRecord requestRecord = null;
        long modifiedDate = 0;
        for (RoleRequestRecord roleRequestRecord : getAllRoleRequest()) {
            if(requestedBy.equals(roleRequestRecord.getRequestedBy())
                    && roleName.equals(roleRequestRecord.getRoleName())
                    && modifiedDate < roleRequestRecord.getModifiedDate()){

                    requestRecord = roleRequestRecord;
                    modifiedDate = roleRequestRecord.getModifiedDate();
            }
        }
        return requestRecord;
    }

    public String getContainerUniversalId() {
        //TODO: get rid of this static method use
        return Cognoscenti.getServerGlobalId() + "@" + getKey();

    }

    @Override
    public List<EmailRecord> getAllEmail() throws Exception {
        DOMFace mail = requireChild("mail", DOMFace.class);
        return mail.getChildren("email", EmailRecord.class);
    }


    public EmailRecord getEmail(String id) throws Exception {
        for (EmailRecord er : getAllEmail()) {
            if (id.equals(er.getId())) {
                return er;
            }
        }
        throw new Exception("There is no email record with id="+id+" on container "+getKey());
    }

    @Override
    public EmailRecord createEmail() throws Exception {
        DOMFace mail = requireChild("mail", DOMFace.class);
        EmailRecord email = mail.createChild("email", EmailRecord.class);
        email.setId(IdGenerator.generateKey());
        return email;
    }

    /**
     * This will delete all email records in the project (workspace)
     */
    public void clearAllEmail() throws Exception {
        DOMFace mail = requireChild("mail", DOMFace.class);
        mail.clearVector("email");
    }

    @Override
    public int countEmailToSend() throws Exception {
        int count = 0;
        for (EmailRecord er : getAllEmail()) {
            if (er.statusReadyToSend()) {
                count++;
            }
        }
        return count;
    }

    /**
    * Pages have a set of licenses
    */
    public List<License> getLicenses() throws Exception {
        List<LicenseRecord> vc = infoParent.getChildren("license", LicenseRecord.class);
        List<License> v = new ArrayList<License>();
        for (License child : vc) {
            v.add(child);
        }
        return v;
    }

    public License getLicense(String id) throws Exception {
        if (id==null || id.length()==0) {
            //silently ignore the null by returning null
            return null;
        }
        for (License child : getLicenses()) {
            if (id.equals(child.getId())) {
                return child;
            }
        }
        int bangPos = id.indexOf("!");
        if (bangPos>0) {
            String userKey = id.substring(0, bangPos);
            String token = id.substring(bangPos+1);
            UserProfile up = UserManager.getUserProfileOrFail(userKey);
            if (!token.equals(up.getLicenseToken())) {
                throw new Exception("License token does not match for user: "+token);
            }
            return new LicenseForUser(up);
        }
        return null;
    }

    public boolean removeLicense(String id) throws Exception {
        List<LicenseRecord> vc = infoParent.getChildren("license", LicenseRecord.class);
        for (LicenseRecord child : vc) {
            if (id.equals(child.getId())) {
                infoParent.removeChild(child);
                return true;
            }
        }
        //maybe this should throw an exception?
        return false;
    }

    public License addLicense(String id) throws Exception {
        LicenseRecord newLement = infoParent.createChildWithID("license",
                LicenseRecord.class, "id", id);
        return newLement;
    }

    public boolean isValidLicense(License lr, long time) throws Exception {
        if (lr==null) {
            //no license passed, then not valid, handle this quietly so that
            //this can be used with getLicense operations.
            return false;
        }
        if (time>lr.getTimeout()) {
            return false;
        }

        AddressListEntry ale = new AddressListEntry(lr.getCreator());
        NGRole ngr = getRole(lr.getRole());
        if (ngr!=null) {
            //check to see if the user who created it, is still in the
            //role or in the member's role
            if (ngr.isExpandedPlayer(ale,  this)) {
                return true;
            }
        }
        if (primaryOrSecondaryPermission(ale)) {
            return true;
        }
        return false;
    }

}
