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


/**
* A license is also known as a "free pass".  Actually there can be
* many kinds of license, some of which might be free.  The point is
* that an access using a license ID in the parameters will then give
* the requester the information that is specified as being allowed in
* the license.
*
* Initially a license will be used to give non-authenticated users
* access to a single page or to just the process on that page.
*
* Note: processes now carry a LicenseRecord with some of this information
* but this class fills in the rest with fixed values.
*/
public class LicenseForProcess implements License
{

    public ProcessRecord proc;

    public LicenseForProcess(ProcessRecord newProc)
    {
        proc = newProc;
    }

    public String getId()
        throws Exception
    {
        return proc.accessLicense().getId();
    }

    public String getNotes()
        throws Exception
    {
        return "This license automatically created for the process.";
    }

    public void setNotes(String newVal)
        throws Exception
    {
        //ignore this
    }

    public String getCreator()
        throws Exception
    {
        return "* Process *";
    }

    public void setCreator(String newVal)
        throws Exception
    {
        //ignore this
    }

    public long getTimeout()
        throws Exception
    {
        return System.currentTimeMillis() + 86000000;
    }

    public void setTimeout(long timeout)
        throws Exception
    {
        //ignore this
    }

    public String getRole() throws Exception {
        //we have to return somthing.
        //Member is pretty general.
        return "Member";
    }

    public void setRole(String newRole) throws Exception {
        //ignore this
    }

    public boolean isReadOnly() throws Exception {
        return false;
    }
    public void setReadOnly(boolean isReadOnly) throws Exception {
        //ignore this
    }

    public JSONObject getJSON() throws Exception {
        JSONObject licenseInfo = new JSONObject();
        licenseInfo.put("id", getId());
        licenseInfo.put("timeout", getTimeout());
        licenseInfo.put("creator", getCreator());
        licenseInfo.put("role", getRole());
        return licenseInfo;
    }

}
