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
* A license is also known as a "free pass".
*
* This license is use when a user accesses a project, and does not have
* a project specific license.  In that case the user's privileges are
* used to control access to the project.  This license is necessary
* when creating a user goal list, so that proper licensed links can be created
* without actually creating unique licenses in each of the projects
* involved.
*
* This license has a format that can be recognized with two parts.
* The first part is the users key, the second is a token that is
* generated occasionally so that others can not just guess the
* license value and access all the information.
*/
public class LicenseForUser implements License
{

    public UserProfile uProf;

    public LicenseForUser(UserProfile up) throws Exception {
        if (up==null) {
            throw new Exception("Program Logic Error: Unable to create a LicenseForUser on a null user profile");
        }
        uProf = up;
    }

    public static LicenseForUser getUserLicense(License other) throws Exception {
        if (other instanceof LicenseForUser) {
            return (LicenseForUser)other;
        }

        UserProfile up = UserManager.findUserByAnyId(other.getCreator());
        if (up==null) {
            throw new Exception("Attempt to use a user license for a user that does not exist");
        }
        return new LicenseForUser(up);
    }

    public String getId() throws Exception {
        String token = uProf.getLicenseToken();
        if (token==null || token.length()==0) {
            uProf.genNewLicenseToken();
            token = uProf.getLicenseToken();

            //TODO: this is dangerous if two threads do this at the same time.
            //Should figure out a threadsafe way to do this.
            UserManager.writeUserProfilesToFile();
        }
        return uProf.getKey()+"!"+token;
    }

    public String getNotes() throws Exception {
        return "This license for the user: "+uProf.getName();
    }

    public void setNotes(String newVal) throws Exception {
        //ignore this
    }

    public String getCreator() throws Exception  {
        return uProf.getUniversalId();
    }

    public void setCreator(String newVal) throws Exception {
        //ignore this
    }

    public long getTimeout() throws Exception {
        return System.currentTimeMillis() + 86000000;
    }

    public void setTimeout(long timeout) throws Exception {
        //ignore this
    }

    public String getRole() throws Exception {
        //TODO: we have to return somthing.
        //Member is pretty general.
        return "Members";
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
