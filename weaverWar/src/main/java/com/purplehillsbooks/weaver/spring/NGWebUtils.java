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

package com.purplehillsbooks.weaver.spring;

import java.util.ArrayList;
import java.util.List;

import com.purplehillsbooks.weaver.AddressListEntry;
import com.purplehillsbooks.weaver.AuthRequest;
import com.purplehillsbooks.weaver.NGRole;
import com.purplehillsbooks.weaver.UserPage;

import com.purplehillsbooks.json.JSONObject;

public class NGWebUtils {

    public static JSONObject getJSONMessage(String msgType, String message,
            String comments) throws Exception {
        JSONObject jsonMsg = new JSONObject();
        jsonMsg.put("msgType", msgType);
        jsonMsg.put("msg", message);
        jsonMsg.put("comments", comments);
        return jsonMsg;
    }

/*
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
    */


}
