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

public class DecisionRecord extends DOMFace {

    public DecisionRecord(Document nDoc, Element nEle, DOMFace p) {
        super(nDoc, nEle, p);
    }

    public int getNumber() throws Exception {
        return getAttributeInt("num");
    }
    public void setNumber(int newVal) throws Exception {
        setAttributeInt("num", newVal);
    }

    public String getDecision() throws Exception {
        return getScalar("decision");
    }
    public void setDecision(String newVal) throws Exception {
        setScalar("decision", newVal);
    }

    public long getTimestamp() throws Exception {
        return getAttributeLong("timestamp");
    }
    public void setTimestamp(long newVal) throws Exception {
        setAttributeLong("timestamp", newVal);
    }


}
