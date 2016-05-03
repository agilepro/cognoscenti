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
import java.util.List;

import org.socialbiz.cog.dms.ResourceEntity;

/**
* NGCommonFile is a set of methods that are are needed
* on the three main file types: NGPage, NGBook, and UserPage
*/
public interface NGContainer
{

    /**
    * @deprecated DO NOT USE THESE
    * These are the old way of calculating whether someone had access to a page
    * but no longer useful.
    * Please remove these as soon as possible.
    */
    public static final int ROLE_MEMBER           = 2;
    public static final int ROLE_AUTHOR           = 4;

    /**
    * Every container has a key that uniquely identifies it from all other containers.
    * In many cases the key is used as the name of the file that stores it, or as a key
    * value for a query to retrieve all the data.  The key is generated at the time of
    * creation, and it remains a constant, permanent, identified for this batch of information.
    * The exact key structure is not important, and may not be consistent over time or
    * across different container types.  It should be treated as an obaque values.
    * The only thing that matters is that it uniquely identifies one container.
    */
    public  String getKey();


    /*
     * output links to display in history logs
     */
    public void writeContainerLink(AuthRequest ar, int len) throws Exception;
    public void writeNoteLink(    AuthRequest ar, String noteId,     int len) throws Exception;
    public void writeTaskLink(    AuthRequest ar, String taskId,     int len) throws Exception;
    public void writeReminderLink(AuthRequest ar, String reminderId, int len) throws Exception;
    public void writeDocumentLink(AuthRequest ar, String documentId, int len) throws Exception;



    /**
     * This is effectively the "empty trashcan" operation.  Documents that
     * have been marked as deleted will actually, finally, be deleted with
     * this operation.
     */
    public void purgeDeletedAttachments() throws Exception;

    /**
    * Returns the ResourceEntity that represents the remote folder that files
    * can be stored in.  Returns null if not set.
    *
    * When attachments are made to the container, they might be linked to a document
    * in a repository, or they might not.  If they are not, the members have the
    * option of copying the document to a repository.  The defaultRepositoryLocation can be set
    * so that documents stored this way tend get grouped in one place.
    * While project documents are not forced to be backed up in this location,
    * it is most convenient for the user if the simplest UI action is to store the
    * document in the same place that all the other project documents are stored.
    * When browsing for a place to store a document, the browsing should start at
    * this location.
    */
    public ResourceEntity getDefRemoteFolder() throws Exception;
    /**
    * Construct a valid ResourceEntity that points to a folder to set this.
    * Pass a null to clear the setting
    */
    public void setDefRemoteFolder(ResourceEntity loc) throws Exception;


    /**
    * A role is a collection of user reference objects with a name, description
    * and some other metadata.  Roles can exist on projects (NGPage), sites (NGBook)
    * or user profiles (UserPage).  In this last case, the role object holds what
    * might better be called a "Relationship".
    *
    * Every role must have a unique name within the container.
    */
    public List<CustomRole> getAllRoles() throws Exception;

    /**
    * Finds and returns the role with the specified name, or null if
    * that role can not be found.
    */
    public CustomRole getRole(String name) throws Exception;

    /**
    * Finds and returns the role with the specified name.
    * This is 'Failure' version should be used when you know that the role should exist
    * if not found, this will throw a standard message announcing that.
    */
    public CustomRole getRoleOrFail(String name) throws Exception;


    public CustomRole createRole(String roleName, String description) throws Exception;

    public void deleteRole(String name) throws Exception;


    public abstract RoleRequestRecord getRoleRequestRecord(String roleName, String requestedBy) throws Exception;

    public abstract List<RoleRequestRecord> getAllRoleRequestByState(String state, boolean completedReq) throws Exception;

    public abstract RoleRequestRecord getRoleRequestRecordById(String requestId)throws Exception;

    public abstract List<RoleRequestRecord> getAllRoleRequest() throws Exception;

    public abstract RoleRequestRecord createRoleRequest(String roleName, String requestedBy,long modifiedDate, String modifiedBy, String requestDescription) throws Exception;
    public abstract void addPlayerToRole(String roleName,String newMember)throws Exception;
    public abstract List<NGRole> findRolesOfPlayer(UserRef user) throws Exception;



    public List<HistoryRecord> getAllHistory() throws Exception;
    public List<HistoryRecord> getHistoryRange(long startTime, long endTime) throws Exception;

    /**
    * Pass a context type (Topic, Action Item, Document, etc) and a old context id, and all the
    * history for that resource will be copied to the current container for a new context id.
    * The history records are left in the old container.
    * The history records in the new page will have the new ID.
    */
    public void copyHistoryForResource(NGContainer ngc, int contextType, String oldID, String newID) throws Exception;

    public HistoryRecord createNewHistory() throws Exception;


    ////////////// Other container bookkeeping methods ////////////////////

    public void saveContent(AuthRequest ar, String comment)  throws Exception;

    public  License getLicense(String id) throws Exception;

    public  String getFullName();

    public  String getUniqueOnPage() throws Exception;

    public boolean isDeleted();

    public long getLastModifyTime()throws Exception;

    /**
     * This is the actual local file that the container is stored in.
     * This is defined identically to DOMFile method.
     */
    public File getFilePath();

    public List<String> getContainerNames();
    public void setContainerNames(List<String> nameSet);

    public ReminderMgr getReminderMgr() throws Exception;

    /**
    * Primary level permissions are for "participants" of the container.
    */
    public boolean primaryPermission(UserRef user) throws Exception;
    public NGRole getPrimaryRole() throws Exception;

    /*
    * If you are in the secondary role, you automatically get included in the primary
    * permissions.  This method checks both roles easily.
    */
    public boolean primaryOrSecondaryPermission(UserRef user) throws Exception;

    /**
    * Secondary level permissions are "owner" permissions for people who own
    * or are majorly responsible for the container.
    */
    public boolean secondaryPermission(UserRef user) throws Exception;
    public NGRole getSecondaryRole() throws Exception;


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
    * permanently as long as the project lasts.  This is good because
    * there is no real way to migrate to a new algorithm for generating
    * the magic numbers.  But in practice
    * this algorithm might be changed at any time, causing discomfort
    * to those users that just received links, but presumably they
    * would soon receive new links with the new numbers in them.
    * There is no real requirement that the number last *forever*.
    */
    public String emailDependentMagicNumber(String emailId) throws Exception;

    public String getAllowPublic() throws Exception;
    public void setAllowPublic(String allowPublic) throws Exception;

    public boolean isFrozen() throws Exception;

    public boolean isAlreadyRequested(String roleName, String requestedBy) throws Exception;

    /**
    * each container can have a different "theme" color set, etc.
    * default is "theme/blue/"
    */
    public String getThemePath();

    public void saveFile(AuthRequest ar, String comment) throws Exception;
    public void saveWithoutAuthenticatedUser(String modUser, long modTime, String comment, Cognoscenti cog)throws Exception;

    /**
    * Returns a globally unique for the container (project/book/userpage) by combining
    * the server's universal id with the project key.  Note: the server id is not
    * guaranteed to remain constant unless specified by the server administrator.
    */
    public String getContainerUniversalId();


    /**
     * returns all the email records in this container
     */
    public List<EmailRecord> getAllEmail() throws Exception;

    /**
     * creates an email record and sets the ID to a unique value for this project
     */
    public EmailRecord createEmail() throws Exception;

    /**
     * Return a single email message that needs to be sent.
     * It returns whatever happens to be the first one, and if there
     * are multiple, there is no guarantee you will get the same one each time.
     */
    public EmailRecord getEmailReadyToSend() throws Exception;
    /**
     * Scan through the email on this project, and return the number of
     * email messages on the page that have nto been sent yet.
     */
    public int countEmailToSend() throws Exception;

 }
