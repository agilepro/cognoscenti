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

import com.purplehillsbooks.json.JSONObject;

/**
 * A license is also known as a "free pass". Actually there can be many kinds of license, some of
 * which might be free. The point is that an access using a license ID in the parameters will then
 * give the requester the information that is specified as being allowed in the license.
 *
 * <p>Initially a license will be used to give non-authenticated users access to a single page or to
 * just the process on that page.
 *
 * <p>Note: processes now carry a LicenseRecord with some of this information but this class fills
 * in the rest with fixed values.
 */
public class LicenseForProcess implements License {

    public ProcessRecord proc;

    public LicenseForProcess(ProcessRecord newProc) {
        proc = newProc;
    }

    public String getId() {
        return proc.accessLicense().getId();
    }

    public String getNotes() {
        return "This license automatically created for the process.";
    }

    public void setNotes(String newVal) {
        // ignore this
    }

    public String getCreator() {
        return "* Process *";
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
        // we have to return somthing.
        // Member is pretty general.
        return "Member";
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
