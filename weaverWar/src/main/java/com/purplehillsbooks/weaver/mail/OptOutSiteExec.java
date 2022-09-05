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

import java.util.List;

import com.purplehillsbooks.json.JSONObject;
import com.purplehillsbooks.weaver.AddressListEntry;
import com.purplehillsbooks.weaver.AuthRequest;
import com.purplehillsbooks.weaver.NGBook;
import com.purplehillsbooks.weaver.NGRole;

/**
* This is for email messages which are sent to the Super Admin
* and you really can't opt out of that responsibility.
* So this makes a message that says that.
*/
public class OptOutSiteExec extends OptOutAddr {

    public OptOutSiteExec(AddressListEntry _assignee) {
        super(_assignee);
    }

    public void writeUnsubscribeLink(AuthRequest clone) throws Exception {
        writeSentToMsg(clone);
        clone.write("You have received this message because you are either the owner or the executive of the site. ");
        writeConcludingPart(clone);
    }
    
    public JSONObject getUnsubscribeJSON(AuthRequest ar) throws Exception {
        JSONObject jo = super.getUnsubscribeJSON(ar);
        jo.put("isDirectAddress", true);
        return jo;
    }

    public static void appendUsersFromSiteRole(NGRole role, NGBook ngb, List<OptOutAddr> collector) throws Exception {
        for (AddressListEntry ale : role.getExpandedPlayers(ngb)) {
            boolean found = false;
            for (OptOutAddr existing : collector) {
                if (ale.equals(existing.getAssignee())) {
                    found = true;
                }
            }
            if (!found) {
                OptOutAddr ooa = new OptOutSiteExec(ale);
                collector.add(ooa);
            }
        }
    }    
    
}
