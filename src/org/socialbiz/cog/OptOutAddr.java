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

import java.util.List;
import java.util.Vector;

import org.socialbiz.cog.exception.NGException;

/**
* The purpose of this class it to remember an assignee to an email message
* and to record WHY that person was assigned to a message, so that a link can
* be generated that allows them to "opt out" of getting the email in the
* future.
*
* There is more than one reason that a user might be assigned to receive
* an email address.  This base class provides the most basic, generic unsubscribe
* link (to the user unsubscribe page).
*
* More specialized classes should:
* 1. provide a way to remove yourself from a role when message was sent to role
* 2. complete or cancel an activity if assigned because of an activity
*/
public class OptOutAddr {

    AddressListEntry assignee;

    public OptOutAddr(AddressListEntry _assignee) {
        assignee = _assignee;
    }

    /**
    * Checks the current assignee, and throws a standard exception
    * if the assignee does not have an email address, or for any other
    * reason that it appears this addressee is not valid.
    */
    public void assertValidEmail() throws Exception {
        String useraddress = assignee.getEmail();
        if (useraddress==null || useraddress.length()==0) {
            throw new NGException("nugen.exception.email.address.is.empty", new Object[]{assignee.getUniversalId()});
        }
    }

    public AddressListEntry getAssignee() {
        return assignee;
    }

    public String getEmail() {
        return assignee.getEmail();
    }
    public boolean hasEmailAddress() {
        String email = getEmail();
        return (email!=null && email.length()>0);
    }

    public boolean matches(OptOutAddr ooa) {
        return assignee.hasAnyId(ooa.getEmail());
    }
    public boolean matches(AddressListEntry ale) {
        return assignee.hasAnyId(ale.getUniversalId());
    }
    public boolean matches(String emailAddress) {
        return assignee.hasAnyId(emailAddress);
    }

    public boolean isUserWithProfile() {
        UserProfile up = UserManager.findUserByAnyId(getEmail());
        return (up!=null);
    }


    protected void writeSentToMsg(AuthRequest clone) throws Exception {
        assertValidEmail();
        clone.write("\n<hr/>\n<p><font size=\"-2\">This message was sent to ");
        clone.writeHtml(assignee.getEmail());
        clone.write(".  ");
    }


    public void writeUnsubscribeLink(AuthRequest clone) throws Exception {
        writeSentToMsg(clone);
        writeConcludingPart(clone);
    }

    protected void writeConcludingPart(AuthRequest clone) throws Exception {
        String emailId = assignee.getEmail();
        UserProfile up = UserManager.findUserByAnyId(emailId);
        if(up != null){
            clone.write("  To change the e-mail communication you receive from ");
            clone.write("Cognoscenti in future, you can ");
            clone.write("<a href=\"");
            clone.writeHtml(clone.baseURL);
            clone.write("v/unsubscribe.htm?accessCode=");
            clone.writeURLData(up.getAccessCode());
            clone.write("&userKey=");
            clone.writeURLData(up.getKey());
            clone.write("&emailId=");
            clone.writeURLData(emailId);
            clone.write("\">alter your subscriptions</a>.</font></p>");
        }
        else {
            clone.write("  You have not created a profile at Cognoscenti, or have not ");
            clone.write("associated this address with your existing profile.</font></p>");
        }
    }


    /**
     * Get the users from the role, and add them, only if they are not already
     * in the list. Adds a OptOutRolePlayer type of address.
     */
    public static void appendUsersFromRole(NGContainer ngc, String roleName,
            Vector<OptOutAddr> collector) throws Exception {
        List<AddressListEntry> players = ngc.getRoleOrFail(roleName)
                .getExpandedPlayers(ngc);
        for (AddressListEntry ale : players) {
            OptOutAddr.appendOneUser(new OptOutRolePlayer(ale, ngc.getKey(), roleName),
                    collector);
        }
    }


    /**
     * Get the users from the role, and add them, only if they are not already
     * in the list. Adds a OptOutDirectAddress type of address.
     */
    public static void appendUsers(List<AddressListEntry> members,
            Vector<OptOutAddr> collector) throws Exception {
        for (AddressListEntry ale : members) {
            appendOneUser(new OptOutDirectAddress(ale), collector);
        }
    }

    /**
     * Only add the user if the user is not already present.
     * Remember ... the user might have more than one email address, so this
     * checks all the email addresses that a user might have registered here.
     */
    public static void appendOneUser(OptOutAddr newser,
            Vector<OptOutAddr> collector) throws Exception {
        for (OptOutAddr ooa : collector) {
            if (ooa.matches(newser)) {
                return;
            }
        }
        collector.add(newser);
    }

    public static void removeFromList(Vector<OptOutAddr> sendTo, String email) {
        OptOutAddr found = null;
        for (OptOutAddr ooa : sendTo) {
            if (ooa.matches(email)) {
                found = ooa;
                break;
            }
        }
        if (found!=null) {
            sendTo.remove(found);
        }
    }


}
