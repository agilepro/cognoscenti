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

package org.socialbiz.cog.spring;

import java.io.IOException;
import java.io.Writer;
import java.util.ArrayList;
import java.util.List;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.socialbiz.cog.AddressListEntry;
import org.socialbiz.cog.AuthRequest;
import org.socialbiz.cog.HistoryRecord;
import org.socialbiz.cog.NGRole;
import org.socialbiz.cog.UserPage;
import com.purplehillsbooks.json.JSONObject;

public class NGWebUtils {

    public static String getJSONMessage(String msgType, String message,
            String comments) throws Exception {
        JSONObject jsonMsg = new JSONObject();
        jsonMsg.put("msgType", msgType);
        jsonMsg.put("msg", message);
        jsonMsg.put("comments", comments);
        String res = jsonMsg.toString();
        return res;
    }

    public static void sendResponse(AuthRequest ar, String responseMessage)
            throws IOException {
        ar.resp.setContentType("text/xml; charset=UTF-8");
        ar.resp.setHeader("Cache-Control", "no-cache");
        Writer writer = ar.resp.getWriter();
        writer.write(responseMessage);
        writer.close();
    }


    public static AuthRequest getAuthRequest(HttpServletRequest request,
            HttpServletResponse response, String assertLoggedInMsg)
            throws Exception {

        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        ar.assertLoggedIn(assertLoggedInMsg);
        return ar;
    }

    public static List<AddressListEntry> getExistingContacts(UserPage up)
            throws Exception {
        List<AddressListEntry> existingContacts = null;
        NGRole aRole = up.getRole("Contacts");
        if (aRole != null) {
            existingContacts = aRole.getExpandedPlayers(up);
        } else {
            existingContacts = new ArrayList<AddressListEntry>();
        }
        return existingContacts;
    }

    public static void addMembersInContacts(AuthRequest ar,
            List<AddressListEntry> contactList) throws Exception {
        UserPage up = ar.getUserPage();
        if (contactList != null) {
            NGRole role = up.getContactsRole();
            for (AddressListEntry ale : contactList) {
                role.addPlayerIfNotPresent(ale);
            }
            up.saveFile(ar, "Added contacts");
        }
    }

    public static void updateUserContactAndSaveUserPage(AuthRequest ar,
            String op, String emailIds) throws Exception {
        int eventType = 0;
        UserPage up = ar.getUserPage();
        if (emailIds.length() > 0) {
            if (op.equals("Remove")) {
                NGRole role = up.getContactsRole();
                AddressListEntry ale = AddressListEntry
                        .newEntryFromStorage(emailIds);
                eventType = HistoryRecord.EVENT_PLAYER_REMOVED;
                role.removePlayer(ale);
                up.saveFile(ar, "removed user " + emailIds + " from role "
                        + role.getName());
            } else if (op.equals("Add")) {
                eventType = HistoryRecord.EVENT_PLAYER_ADDED;

                List<AddressListEntry> contactList = AddressListEntry
                        .parseEmailList(emailIds);
                NGWebUtils.addMembersInContacts(ar, contactList);
            }
        }
        HistoryRecord.createHistoryRecord(up, "Updating contacts",
                HistoryRecord.CONTEXT_TYPE_ROLE, 0, eventType, ar, "");
    }

}
