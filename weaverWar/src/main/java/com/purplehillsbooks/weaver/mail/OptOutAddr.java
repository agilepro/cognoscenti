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

package com.purplehillsbooks.weaver.mail;

import java.net.URLEncoder;
import java.util.Calendar;
import java.util.List;
import java.util.TimeZone;

import com.purplehillsbooks.weaver.AddressListEntry;
import com.purplehillsbooks.weaver.AuthDummy;
import com.purplehillsbooks.weaver.AuthRequest;
import com.purplehillsbooks.weaver.Cognoscenti;
import com.purplehillsbooks.weaver.NGBook;
import com.purplehillsbooks.weaver.NGRole;
import com.purplehillsbooks.weaver.NGWorkspace;
import com.purplehillsbooks.weaver.UserManager;
import com.purplehillsbooks.weaver.UserProfile;
import com.purplehillsbooks.weaver.exception.WeaverException;
import com.purplehillsbooks.json.JSONObject;
import com.purplehillsbooks.streams.MemFile;

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

    public AddressListEntry assignee;
    public String messageForAssignee = "";
    public Calendar cal = null;
    public boolean fromRealUser = false;

    public OptOutAddr(AddressListEntry _assignee) {
        if (!_assignee.isWellFormed()) {
            throw new RuntimeException("Can't create an OptOutAddr object for a user without an email address: "+_assignee.getUniversalId());
        }
        assignee = _assignee;
        UserProfile up = assignee.getUserProfile();
        if (up!=null) {
            cal = up.getCalendar();
            fromRealUser = up.canAcceptRealUserFromAddress();
        }
        else {
            String tzid = UserProfile.defaultTimeZone;
            if (tzid==null || tzid.length()==0) {
                //this is the default calendar for the server environment
                throw new RuntimeException("UserProfile.defaultTimeZone is not set!");
            }
            TimeZone tz = TimeZone.getTimeZone(tzid);
            cal = Calendar.getInstance(tz);
        }
    }

    /**
    * Checks the current assignee, and throws a standard exception
    * if the assignee does not have an email address, or for any other
    * reason that it appears this addressee is not valid.
    */
    public void assertValidEmail() throws Exception {
        String useraddress = assignee.getEmail();
        if (useraddress==null || useraddress.length()==0) {
            throw WeaverException.newBasic("Email address is missing from the assignee for opt out");
        }
    }

    public AddressListEntry getAssignee() {
        return assignee;
    }

    /**
     * Returns the email address portion only, should look like a standard email address
     */
    public String getEmail() {
        return assignee.getEmail();
    }
    public boolean hasEmailAddress() {
        String email = getEmail();
        return (email!=null && email.length()>0);
    }
    
    /**
     * This is the name of the user that this is referring to, the name that should
     * go along with the email address.
     */
    public String getName() {
        return assignee.getName();
    }
    
    public Calendar getCalendar() {
        return cal;
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
        UserProfile up = UserManager.lookupUserByAnyId(getEmail());
        return (up!=null);
    }


    public void prepareInternalMessage(Cognoscenti cog) throws Exception {
        MemFile body = new MemFile();
        UserProfile up = UserManager.lookupUserByAnyId(getEmail());
        AuthRequest clone = new AuthDummy(up, body.getWriter(), cog);
        writeUnsubscribeLink(clone);
        clone.flush();
        messageForAssignee = body.toString();
    }

    public String getUnSubscriptionAsString() throws Exception {
        return messageForAssignee;
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
        UserProfile up = UserManager.lookupUserByAnyId(emailId);
        if(up != null){
            clone.write("  To change the e-mail communication you receive from ");
            clone.write("Weaver in future, you can ");
            clone.write("<a href=\"");
            clone.writeHtml(clone.baseURL);
            clone.write("v/unsubscribe.htm?accessCode=");
            clone.writeURLData(up.getAccessCode());
            clone.write("&userKey=");
            clone.writeURLData(up.getKey());
            clone.write("&emailId=");
            clone.writeURLData(emailId);
            clone.write("\">alter your subscriptions</a>.");
            clone.write("</font></p>");
        }
        else {
            clone.write("  You have not created a profile at Weaver, or have not ");
            clone.write("associated this address with your existing profile.");
            clone.write("</font></p>");
        }
    }

    public JSONObject getUnsubscribeJSON(AuthRequest ar) throws Exception {
        assertValidEmail();
        UserProfile up = UserManager.lookupUserByAnyId(assignee.getEmail());
        JSONObject jo = new JSONObject();
        String emailId = assignee.getEmail();
        jo.put("emailId", emailId);
        if (up!=null) {
            jo.put("unsubscribe", ar.baseURL+"v/unsubscribe.htm?accessCode="+up.getAccessCode()
                +"&userKey="+up.getKey()
                +"&emailId="+URLEncoder.encode(emailId,"UTF-8"));
            jo.put("accessCode", up.getAccessCode());
            jo.put("userKey", up.getKey());
            jo.put("userId", up.getUniversalId());
        }
        return jo;
    }


    /**
     * Get the users from the role, and add them, only if they are not already
     * in the list. Adds a OptOutRolePlayer type of address.
     */
    public static void appendUsersFromRole(NGWorkspace ngc, String roleName,
            List<OptOutAddr> collector) throws Exception {
        try {
            List<AddressListEntry> players = ngc.getRoleOrFail(roleName)
                    .getExpandedPlayers(ngc);
            for (AddressListEntry ale : players) {
                if (!ale.isWellFormed()) {
                    //do not include users who have partial user profiles and might
                    //cause problems with email sending
                    continue;
                }
                String email = ale.getEmail();
                if (email!=null && email.length()>0) {
                    OptOutAddr.appendOneUser(new OptOutRolePlayer(ale, ngc.getSiteKey(), ngc.getKey(), roleName),
                            collector);
                }
            }
        }
        catch (Exception e) {
            throw WeaverException.newWrap(
                "Unable to append users from the role (%s) in workspace (%s)",
                e, roleName, ngc.getFullName());
        }
    }
    public static void appendUnmutedUsersFromRole(NGWorkspace ngw, String roleName,
            List<OptOutAddr> collector) throws Exception {
        try {
            NGRole muteRole = ngw.getMuteRole();
            List<AddressListEntry> players = ngw.getRoleOrFail(roleName)
                    .getExpandedPlayers(ngw);
            for (AddressListEntry ale : players) {
                if (!muteRole.isPlayer(ale)) {
                    String email = ale.getEmail();
                    if (email!=null && email.length()>0) {
                        OptOutAddr.appendOneUser(new OptOutRolePlayer(ale, ngw.getSiteKey(), ngw.getKey(), roleName),
                                collector);
                    }
                }
            }
        }
        catch (Exception e) {
            throw WeaverException.newWrap(
                "Unable to append users from the role (%s) in workspace (%s)",
                e, roleName, ngw.getFullName());
        }
    }
    public static void appendUsersFromSiteRole(NGRole role, NGBook ngb, List<OptOutAddr> collector) throws Exception {
        for (AddressListEntry ale : role.getExpandedPlayers(ngb)) {
            OptOutAddr ooa = new OptOutRolePlayer(ale, ngb.getKey(), "$",  role.getName());
            collector.add(ooa);
        }
    }    


    /**
     * Get the users from the role, and add them, only if they are not already
     * in the list. Adds a OptOutDirectAddress type of address.
     */
    public static void appendUsers(List<AddressListEntry> members,
            List<OptOutAddr> collector) throws Exception {
        for (AddressListEntry ale : members) {
            if (ale.isWellFormed()) {
                appendOneUser(new OptOutDirectAddress(ale), collector);
            }
        }
    }
    public static void appendUsersEmail(List<String> emailList,
            List<OptOutAddr> collector) throws Exception {
        for (String email : emailList) {
            AddressListEntry ale = AddressListEntry.findOrCreate(email);
            if (ale.isWellFormed()) {
                appendOneUser(new OptOutDirectAddress(ale), collector);
            }
        }
    }

    /**
     * Only add the user if the user is not already present.
     * Remember ... the user might have more than one email address, so this
     * checks all the email addresses that a user might have registered here.
     */
    public static void appendOneUser(OptOutAddr newser,
            List<OptOutAddr> collector) throws Exception {
        for (OptOutAddr ooa : collector) {
            if (ooa.matches(newser)) {
                return;
            }
        }
        collector.add(newser);
    }
    public static void appendOneDirectUser(AddressListEntry enteredAddress,
            List<OptOutAddr> collector) throws Exception {
        if (enteredAddress.isWellFormed()) {
            appendOneUser(new OptOutDirectAddress(enteredAddress), collector);
        }
    }
    
    

    public static void removeFromList(List<OptOutAddr> sendTo, String email) {
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
