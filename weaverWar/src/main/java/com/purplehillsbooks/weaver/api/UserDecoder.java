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
 */
package com.purplehillsbooks.weaver.api;

import com.purplehillsbooks.weaver.AuthRequest;
import com.purplehillsbooks.weaver.License;
import com.purplehillsbooks.weaver.LicenseForUser;
import com.purplehillsbooks.weaver.UserManager;
import com.purplehillsbooks.weaver.UserPage;
import com.purplehillsbooks.weaver.UserProfile;
import com.purplehillsbooks.weaver.exception.WeaverException;

public class UserDecoder {

    public String userKey;
    public UserProfile uProf;
    public UserPage uPage;

    public String resource;

    public String licenseId;
    public License lic;

    public UserDecoder(AuthRequest ar) throws Exception {

        licenseId = ar.defParam("lic", null);

        //this will only be the part AFTER the /api/
        String path = ar.req.getPathInfo();

        // TEST: check to see that the servlet path starts with /
        if (!path.startsWith("/")) {
            throw WeaverException.newBasic("Path should start with / but instead it is: "
                            + path);
        }

        int curPos = 1;
        int slashPos = path.indexOf("/", curPos);
        if (slashPos<=curPos) {
            throw WeaverException.newBasic("Can't find a user key in the URL.");
        }
        userKey = path.substring(curPos, slashPos);
        uProf = UserManager.getUserProfileByKey(userKey);
        uPage = uProf.getUserPage();

        resource = path.substring(slashPos+1);

        if (licenseId!=null && licenseId.equals(uProf.getLicenseToken())) {
            lic = new LicenseForUser(uProf);
        }
    }

}
