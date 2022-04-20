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
import java.util.List;

import com.purplehillsbooks.weaver.exception.ProgramLogicError;
import org.w3c.dom.Document;

/**
* NGCommonFile is a set of methods that are are needed
* on the three main file types: NGWorkspace, NGBook, and UserPage
*/
public abstract class NGContainer extends DOMFile
{
    public NGContainer(File path, Document doc) throws Exception {
        super(path,doc);
    }

    /**
    * Every container has a key that uniquely identifies it from all other containers.
    * In many cases the key is used as the name of the file that stores it, or as a key
    * value for a query to retrieve all the data.  The key is generated at the time of
    * creation, and it remains a constant, permanent, identified for this batch of information.
    * The exact key structure is not important, and may not be consistent over time or
    * across different container types.  It should be treated as an obaque values.
    * The only thing that matters is that it uniquely identifies one container.
    */
    public abstract  String getKey();


    /*
     * output links to display in history logs
     */
    public abstract void writeContainerLink(AuthRequest ar, int len) throws Exception;
    public abstract void writeNoteLink(    AuthRequest ar, String noteId,     int len) throws Exception;
    public abstract void writeTaskLink(    AuthRequest ar, String taskId,     int len) throws Exception;
    public abstract void writeDocumentLink(AuthRequest ar, String documentId, int len) throws Exception;





    /**
    * A role is a collection of user reference objects with a name, description
    * and some other metadata.  Roles can exist on projects (NGWorkspace), sites (NGBook)
    * or user profiles (UserPage).  In this last case, the role object holds what
    * might better be called a "Relationship".
    *
    * Every role must have a unique name within the container.
    */
    public abstract List<CustomRole> getAllRoles() throws Exception;

    /**
    * Finds and returns the role with the specified name, or null if
    * that role can not be found.
    */
    public abstract CustomRole getRole(String name) throws Exception;

    /**
    * Finds and returns the role with the specified name.
    * This is 'Failure' version should be used when you know that the role should exist
    * if not found, this will throw a standard message announcing that.
    */
    public abstract CustomRole getRoleOrFail(String name) throws Exception;
    public abstract CustomRole createRole(String roleName, String description) throws Exception;
    public abstract void deleteRole(String name) throws Exception;
    public abstract void addPlayerToRole(String roleName,String newMember)throws Exception;
    public abstract List<NGRole> findRolesOfPlayer(UserRef user) throws Exception;


    public abstract RoleRequestRecord getRoleRequestRecord(String roleName, String requestedBy) throws Exception;
    public abstract List<RoleRequestRecord> getAllRoleRequestByState(String state, boolean completedReq) throws Exception;
    public abstract RoleRequestRecord getRoleRequestRecordById(String requestId)throws Exception;
    public abstract List<RoleRequestRecord> getAllRoleRequest() throws Exception;
    public abstract RoleRequestRecord createRoleRequest(String roleName, String requestedBy,long modifiedDate, String modifiedBy, String requestDescription) throws Exception;




    ////////////// Other container bookkeeping methods ////////////////////

    public abstract void saveContent(AuthRequest ar, String comment)  throws Exception;

    public abstract  License getLicense(String id) throws Exception;

    public abstract  String getFullName();

    public abstract  String getUniqueOnPage() throws Exception;

    public abstract boolean isDeleted();

    public abstract long getLastModifyTime()throws Exception;

    public abstract List<String> getContainerNames();
    public abstract void setContainerNames(List<String> nameSet);


    /**
    * Primary level permissions are for "participants" of the container.
    */
    public boolean primaryPermission(UserRef user) throws Exception {
        if (user==null) {
            throw new ProgramLogicError("primaryPermission called with null user object.");
        }
        return getPrimaryRole().isExpandedPlayer(user, this);
    }
    public abstract NGRole getPrimaryRole() throws Exception;

    /*
    * If you are in the secondary role, you automatically get included in the primary
    * permissions.  This method checks both roles easily.
    */
    public boolean primaryOrSecondaryPermission(UserRef user) throws Exception {
        if (primaryPermission(user))
        {
            return true;
        }
        if (secondaryPermission(user))
        {
            return true;
        }
        if (this instanceof NGWorkspace)
        {
            throw new ProgramLogicError("NGWorkspace overrides this, so this should never happen");
        }
        return false;
    }

    /**
    * Secondary level permissions are "owner" permissions for people who own
    * or are majorly responsible for the container.
    */
    public boolean secondaryPermission(UserRef user) throws Exception {
        if (user==null) {
            throw new ProgramLogicError("secondaryPermission called with null user object.");
        }
        return getSecondaryRole().isExpandedPlayer(user, this);
    }
    public abstract NGRole getSecondaryRole() throws Exception;


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
    public abstract String emailDependentMagicNumber(String emailId) throws Exception;

    public abstract boolean isFrozen() throws Exception;

    public abstract boolean isAlreadyRequested(String roleName, String requestedBy) throws Exception;


    public abstract void saveFile(AuthRequest ar, String comment) throws Exception;
    public abstract void saveWithoutAuthenticatedUser(String modUser, long modTime, String comment, Cognoscenti cog)throws Exception;

    /**
    * Returns a globally unique for the container (project/book/userpage) by combining
    * the server's universal id with the project key.  Note: the server id is not
    * guaranteed to remain constant unless specified by the server administrator.
    */
    public abstract String getContainerUniversalId();


    /**
     * returns all the email records in this container
     */
    public abstract List<EmailRecord> getAllEmail() throws Exception;

    /**
     * creates an email record and sets the ID to a unique value for this project
     */
    public abstract EmailRecord createEmail() throws Exception;

    /**
     * Scan through the email on this project, and return the number of
     * email messages on the page that have not been sent yet.
     */
    //public abstract boolean hasEmailToSend() throws Exception;

    /**
     * figure out when the next background event is scheduled
     */
    public long nextActionDue() throws Exception {
        throw new Exception("nextActionDue not implemented");
    }

 }
