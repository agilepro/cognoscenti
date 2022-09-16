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

package com.purplehillsbooks.weaver;

import org.w3c.dom.Document;
import org.w3c.dom.Element;

/**
* A StatusReport contains a set of ProjectLinks which tell the specific
* information about a workspace to include in the status report.
*/
public class ProjectLink extends DOMFace
{

    //this is a temporary (non persistent) marker that can be used
    //to garbage collect left over dangling workspace references.
    public boolean touchFlag = false;

    public ProjectLink(Document nDoc, Element nEle, DOMFace p) {
        super(nDoc, nEle, p);
    }

    public String getKey() throws Exception {
        return getAttribute("key");
    }

    public String getSiteKey() throws Exception {
        return getAttribute("siteKey");
    }
    
    public void setKeys(String siteKey, String newVal) throws Exception {
        setAttribute("siteKey", siteKey);
        setAttribute("key", newVal);
    }

    /**
    * Convenience function that looks up and returns the index record for the
    * associated workspace.  If the workspace does not exist, this returns null.
    */
    public NGPageIndex getPageIndexOrNull(Cognoscenti cog) throws Exception {
        return cog.getWSBySiteAndKey(getSiteKey(), getKey());
    }

}
