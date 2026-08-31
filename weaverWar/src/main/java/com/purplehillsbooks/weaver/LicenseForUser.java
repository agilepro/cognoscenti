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

import com.purplehillsbooks.exception.CommonException;
import com.purplehillsbooks.json.JSONObject;

/**
 * A license is also known as a "free pass".
 *
 * <p>This license is use when a user accesses a project, and does not have a project specific
 * license. In that case the user's privileges are used to control access to the project. This
 * license is necessary when creating a user action item list, so that proper licensed links can be
 * created without actually creating unique licenses in each of the projects involved.
 *
 * <p>This license has a format that can be recognized with two parts. The first part is the users
 * key, the second is a token that is generated occasionally so that others can not just guess the
 * license value and access all the information.
 */
public class LicenseForUser implements License {

    public UserProfile uProf;

    public LicenseForUser(UserProfile up) {
        if (up == null) {
            throw CommonException.newBasic(
                    "Program Logic Error: Unable to create a LicenseForUser on a null user profile");
        }
        uProf = up;
    }

    public static LicenseForUser getUserLicense(License other) throws Exception {
        if (other instanceof LicenseForUser) {
            return (LicenseForUser) other;
        }

        UserProfile up = UserManager.lookupUserByAnyId(other.getCreator());
        if (up == null) {
            throw CommonException.newBasic(
                    "Attempt to use a user license for a user that does not exist");
        }
        return new LicenseForUser(up);
    }

    public String getId() {
        String token = uProf.getLicenseToken();
        return uProf.getKey() + "!" + token;
    }

    public String getNotes() {
        return "This license for the user: " + uProf.getName();
    }

    public void setNotes(String newVal) {
        // ignore this
    }

    public String getCreator() {
        return uProf.getUniversalId();
    }

    public void setCreator(String newVal) {
        // ignore this
    }

    public long getTimeout() {
        return System.currentTimeMillis() + 86000000;
    }

    public void setTimeout(long timeout) {
        // ignore this
    }

    public String getRole() {
        // TODO: we have to return somthing.
        // Member is pretty general.
        return "MembersRole";
    }

    public void setRole(String newRole) {
        // ignore this
    }

    public boolean isReadOnly() {
        return false;
    }

    public void setReadOnly(boolean isReadOnly) {
        // ignore this
    }

    public JSONObject getJSON() {
        JSONObject licenseInfo = new JSONObject();
        licenseInfo.put("id", getId());
        licenseInfo.put("timeout", getTimeout());
        licenseInfo.put("creator", getCreator());
        licenseInfo.put("role", getRole());
        return licenseInfo;
    }
}
