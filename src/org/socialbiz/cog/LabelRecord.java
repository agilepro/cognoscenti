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
 * Projects will have a set of labels to label documents, action items, and topics with.
 * This will put them into groups, and allow for a display somewhat like a folder.
 *
 */
public class LabelRecord extends DOMFace implements NGLabel {

    public LabelRecord(Document doc, Element upEle, DOMFace p) {
        super(doc, upEle, p);
    }

    public String getName() {
        return getAttribute("name");
    }

    public void setName(String name) {
        setAttribute("name", name);
    }

    public String getColor() {
        return getAttribute("color");
    }

    public void setColor(String color) {
        setAttribute("color", color);
    }

    public JSONObject getJSON() throws Exception {
        JSONObject jObj = new JSONObject();
        jObj.put("name",  getName());
        jObj.put("color",  getColor());
        return jObj;
    }
}
