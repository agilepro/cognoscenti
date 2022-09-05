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

import com.purplehillsbooks.json.JSONObject;
import com.purplehillsbooks.weaver.AddressListEntry;
import com.purplehillsbooks.weaver.AuthRequest;

/**
* This is for email messages which are send in order to satisfy a
* request that a user makes themselves.  For example, requesting
* to be in a particular role, you get the message confirming that,
* there is nothing you can (or would want) to do to avoid that.
*/
public class OptOutIndividualRequest extends OptOutAddr {

    public OptOutIndividualRequest(AddressListEntry _assignee) {
        super(_assignee);
    }

    public void writeUnsubscribeLink(AuthRequest clone) throws Exception {
        writeSentToMsg(clone);
        clone.write("You have received this message in order to carry out the request that you made. ");
        writeConcludingPart(clone);
    }
    
    public JSONObject getUnsubscribeJSON(AuthRequest ar) throws Exception {
        JSONObject jo = super.getUnsubscribeJSON(ar);
        jo.put("isIndividualRequest", true);
        return jo;
    }

}
