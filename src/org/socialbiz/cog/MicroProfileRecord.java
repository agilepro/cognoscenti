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

import java.net.URLEncoder;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.w3c.dom.Document;
import org.w3c.dom.Element;

public class MicroProfileRecord extends DOMFace {
    
    public static final Pattern VALID_EMAIL_ADDRESS_REGEX = 
            Pattern.compile("^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,6}$", Pattern.CASE_INSENSITIVE);

    public static boolean validEmailAddress(String emailStr) {
            Matcher matcher = VALID_EMAIL_ADDRESS_REGEX .matcher(emailStr);
            return matcher.find();
    }

    public MicroProfileRecord(Document doc, Element ele, DOMFace p) {
        super(doc, ele, p);
    }

    public String getId()
    {
        return getAttribute("id");
    }
    public void setId(String id)
    {
        setAttribute("id", id);
    }

    public String getDisplayName() {
        return getAttribute("displayName");
    }

    public void setDisplayName(String displayName) {
        setAttribute("displayName", displayName);
    }


    public void writeLink(AuthRequest ar) throws Exception {
        boolean makeItALink = ar.isLoggedIn() && !ar.isStaticSite();
        writeSpecificLink(ar, getDisplayName(), getId(), makeItALink);
    }

    /**
    * Creates a link for a displayname and id.  If you don't have a display name
    * pass a nullstring in, and the id will be used instead.
    */
    public static void writeSpecificLink(AuthRequest ar, String cleanName, String id, boolean makeItALink)
            throws Exception {
        String olink = "v/FindPerson.htm?uid="+URLEncoder.encode(id, "UTF-8");
        if (cleanName.length()>28)  {
            cleanName = cleanName.substring(0,28);
        }
        if (makeItALink) {
            ar.write("<a href=\"");
            ar.write(ar.retPath);
            ar.write(olink);
            ar.write("\" title=\"access the profile of this user, if one exists\">");
            ar.write("<span class=\"red\">");
            ar.writeHtml(cleanName);
            ar.write("</span>");
            ar.write("</a>");
        }
        else {
            ar.writeHtml(cleanName);
        }
    }
}
