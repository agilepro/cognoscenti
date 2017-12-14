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

import org.w3c.dom.Document;
import org.w3c.dom.Element;
import com.purplehillsbooks.json.JSONObject;

/**
* A nomination is the proposal of a particular person
* for a particular role.  It is the storage place for all
* the work around consent based selection of people 
* for roles.  Each selection time, there will be 
* some number of nominations.  They will be discussed
* and ultimately a person selected and agreed upon. 
* 
*/
public class RoleNomination extends DOMFace {

    public RoleNomination(Document doc, Element ele, DOMFace p) {
        super(doc, ele, p);
    }

    /**
     * The owner is the key of this nomination.  Each person can have only
     * one nomination.
     */
    public String getOwner() {
        return getAttribute("owner");
    }
    
    
    public JSONObject getJSON() throws Exception {
        JSONObject jObj = new JSONObject();
        extractAttributeString(jObj, "owner");
        extractScalarString(jObj, "nominee");
        extractScalarString(jObj, "comment");
        extractAttributeLong(jObj, "timestamp");
        return jObj;
    }
    public void updateFromJSON(JSONObject nomInfo) throws Exception {
        updateAttributeString("owner", nomInfo);
        updateScalarString("nominee", nomInfo);
        updateScalarString("comment", nomInfo);
        updateAttributeLong("timestamp", nomInfo);
    }
}
