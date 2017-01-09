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
import org.workcast.json.JSONObject;

/**
* A role may have many terms, and they will be played
* by different people each term.  A term will have a
* specific start date, and end date.
* Some roles will not have terms, and they are perpetual
* meaning that the same person holds them forever.
* Old terms become a kind of history behind who
* has played the role in the past.
* 
* Terms have a complete cycle around selecting people
* to play a particular term of a particular role.
*/
public class Responsibility extends DOMFace {

    public Responsibility(Document doc, Element ele, DOMFace p) {
        super(doc, ele, p);
    }

    public String getKey() {
        return getAttribute("key");
    }
    /**
     * Note, this is the 'key',
     * so don't change it if you have references elsewhere.
     */
    public void setKey(String newKey) {
        setAttribute("key", newKey);
    }


    public JSONObject getJSON() throws Exception {
        JSONObject jObj = new JSONObject();
        extractAttributeString(jObj, "key");
        extractScalarString(jObj, "text");
        return jObj;
    }
    public void updateFromJSON(JSONObject termInfo) throws Exception {
        updateAttributeString("key", termInfo);
        updateScalarString("text", termInfo);
    }
}
