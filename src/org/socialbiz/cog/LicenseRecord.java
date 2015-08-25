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

import org.workcast.json.JSONObject;
import org.w3c.dom.Document;
import org.w3c.dom.Element;


/**
* A license is also known as a "free pass".  Actually there can be
* many kinds of license, some of which might be free.  The point is
* that an access using a license ID in the parameters will then give
* the requester the information that is specified as being allowed in
* the license.
* Initially a license will be used to give non-authenticated users
* access to a single page or to just the process on that page.
*/
public class LicenseRecord extends DOMFace  implements License
{
    public LicenseRecord(Document d, Element e, DOMFace p)
    {
        super(d,e,p);
    }


    public String getId()
        throws Exception
    {
        return getAttribute("id");
    }

    public void setId(String newVal)
        throws Exception
    {
        setAttribute("id", newVal);
    }


    public String getNotes()
        throws Exception
    {
        return getScalar("notes");
    }

    public void setNotes(String newVal)
        throws Exception
    {
        if (newVal == null) {
            newVal = "";
        }
        setScalar("notes", newVal);
    }

    public String getCreator()
        throws Exception
    {
        return getScalar("creator");
    }

    public void setCreator(String newVal)
        throws Exception
    {
        setScalar("creator", newVal);
    }

    public long getTimeout()
        throws Exception
    {
        return safeConvertLong(getScalar("timeout"));
    }

    public void setTimeout(long timeout)
        throws Exception
    {
        setScalar("timeout", Long.toString(timeout));
    }

    public String getRole() throws Exception {
        String ret = getScalar("role");
        if (ret==null || ret.length()==0) {
            //default on the fly to Members
            return "Members";
        }
        return ret;
    }

    public void setRole(String newRole) throws Exception {
        setScalar("role", newRole);
    }

    public boolean isReadOnly() throws Exception {
        String readOnly = getAttribute("readOnly");
        return readOnly!=null && "yes".equals(readOnly);
    }
    public void setReadOnly(boolean isReadOnly) throws Exception {
        if (isReadOnly) {
            setAttribute("readOnly", "yes");
        }
        else {
            setAttribute("readOnly", null);
        }
    }

    public JSONObject getJSON() throws Exception {
        JSONObject licenseInfo = new JSONObject();
        licenseInfo.put("id", getId());
        licenseInfo.put("timeout", getTimeout());
        licenseInfo.put("creator", getCreator());
        licenseInfo.put("role", getRole());
        licenseInfo.put("readonly", isReadOnly());
        return licenseInfo;
    }

}
