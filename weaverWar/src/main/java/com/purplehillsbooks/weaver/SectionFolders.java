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

import java.util.List;

@Deprecated
public class SectionFolders extends SectionUtil implements SectionFormat {

    public static final int TYPE_FOLDER = 0;
    public static final int TYPE_FILE = 1;
    public static final String PTCL_WEBDAV = "WEBDAV";

    public SectionFolders() {

    }

    /**
     * get the name of the format
     */
    public String getName() {
        return "Folders Format";
    }

    /*
     * Folders is no longer a valid sectoin format
     */
    public void findIDs(List<String> v, NGSection sec) throws Exception {
        //no content, nothing to check
    }

}