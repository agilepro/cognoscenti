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

package com.purplehillsbooks.weaver.rest;

import com.purplehillsbooks.weaver.AuthRequest;
import com.purplehillsbooks.weaver.NGBook;
import com.purplehillsbooks.weaver.NGWorkspace;
import com.purplehillsbooks.weaver.exception.WeaverException;

/**

 */

public class RestHandler {

    AuthRequest ar;
    String siteId;
    String workspaceKey;
    String resource;
    NGBook prjSite;
    NGWorkspace ngw;

    /**
     * This servlet handles REST style requests for XML content
     */
    public RestHandler(AuthRequest _ar) {
        ar = _ar;
    }

    public void doAuthenticatedGet()  throws Exception {

        findResource();

    }

    private void findResource()  throws Exception {
        //if this servlet is mapped with /r/*
        //getPathInfo return only the path AFTER the r
        String path = ar.req.getPathInfo();
        // TEST: check to see that the servlet path starts with /
        if (!path.startsWith("/")) {
            throw WeaverException.newBasic("Path should start with / but instead it is: "
                            + path);
        }

        int slashPos = path.indexOf("/",1);
        if (slashPos<1) {
            throw WeaverException.newBasic("could not find a second slash in: " + path);
        }
        siteId = path.substring(1, slashPos);
        prjSite = ar.getCogInstance().getSiteByIdOrFail(siteId);
        int nextSlashPos = path.indexOf("/",slashPos+1);
        if (nextSlashPos<0) {
            throw WeaverException.newBasic("could not find a third slash in: " + path);
        }
        workspaceKey = path.substring(slashPos+1, nextSlashPos);
        ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, workspaceKey).getWorkspace();

        resource = path.substring(nextSlashPos+1);
        if (!"case.xml".equals(resource)) {
            throw WeaverException.newBasic("the only resource supported is case.xml, but got: "+resource);
        }
    }
}
