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

import java.io.Writer;
import java.util.Vector;
import org.socialbiz.cog.exception.ProgramLogicError;

@Deprecated
public class SectionFolders extends SectionUtil implements SectionFormat {

    public static final int TYPE_FOLDER = 0;
    public static final int TYPE_FILE = 1;
    public static final String PTCL_LOCAL = "Local";
    public static final String PTCL_SMB = "SMB";
    public static final String PTCL_WEBDAV = "WEBDAV";

    public SectionFolders() {

    }

    /**
     * get the name of the format
     */
    public String getName() {
        return "Folders Format";
    }


    public void deleteFolder(AuthRequest ar, NGPage ngp, NGSection section,
            String folderId) throws Exception {

        throw new ProgramLogicError("Method Not implemented");
    }

    public void writePlainText(NGSection section, Writer out) throws Exception {
        //silently ignore this request ... no text to produce.
        //necessary for search function
    }

    /*
     * Walk through whatever elements this owns and put all the four digit IDs
     * into the vector so that we can generate another ID and assure it does not
     * duplication any id found here.
     */
    public void findIDs(Vector<String> v, NGSection sec) throws Exception {

    }

    /**
     * This is a method to find a file, and output the file as a stream of bytes
     * to the request output stream.
     */
    public static void serveUpFile(AuthRequest ar, NGPage ngp, String fileId)
            throws Exception {

        throw new ProgramLogicError("Method Not implemented");

    }

    public void displaySubFolder(AuthRequest ar, NGPage ngp, NGSection section,
            String folderId) throws Exception {
        throw new ProgramLogicError("Method Not implemented");
    }

}
