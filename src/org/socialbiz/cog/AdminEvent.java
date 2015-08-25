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


public class AdminEvent extends DOMFace {


    public static final String SITE_CREATED ="1";
    public static final String SITE_DENIED = "2";
    public static final String NEW_USER_REGISTRATION = "3";



    public AdminEvent(Document doc, Element ele, DOMFace p) {
        super(doc, ele, p);

        //schema migration, unique id was being put in a child tag, but an attribute
        //is more efficient for this sort of thing
        //Schema migration can be removed one year after Jun 2011
        String testCase = getScalar("uniqueId");
        if (testCase!=null && testCase!="" )
        {
            //if we see a child named uniqueId, move that value to the attribute
            setAttribute("id", testCase);

            //remove the child
            setScalar("uniqueId", null);

            //if this file is saved, then these changes are save.  But if not
            //then the conversion happens again until ultimately it is saved.
        }
    }


    /**
    * This is the ID of the object being referred to.
    * If this is a user registration, then this is the key of the user profile.
    * If this is a site creation, then this holds the key to the site.
    */
    public String getObjectId() {
        return getAttribute("id");
    }
    public void setObjectId(String uniqueId) {
        setAttribute("id", uniqueId);
    }

    public void setContext(String context) {
        setAttribute("context", context);
    }
    public String getContext() {
        return getAttribute("context");
    }

    /**
    * Set the user who modifed the record, and the time of modification
    * at the same operation, because both should be set at the same time
    */
    public void setModified(String userId, long time) {
        setAttribute("modUser", userId);
        setAttribute("modTime", Long.toString(time));
    }
    public long getModTime() {
        return safeConvertLong(getAttribute("modTime"));
    }
    public String getModUser() {
        return getAttribute("modUser");
    }

}
