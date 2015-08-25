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

import org.w3c.dom.Document;
import org.w3c.dom.Element;

public class MicroProfileRecord extends DOMFace {

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
        writeLinkInternal(ar, makeItALink);
    }

    private void writeLinkInternal(AuthRequest ar, boolean makeItALink) throws Exception {
        String cleanName = getDisplayName();

        if (makeItALink)
        {
            writeSpecificLink(ar, getDisplayName(), getId());
        }
        else
        {
            ar.writeHtml(cleanName);
        }

    }


    /**
    * Creates a link for a displayname and id.  If you don't have a display name
    * pass a nullstring in, and the id will be used instead.
    */
    public static void writeSpecificLink(AuthRequest ar, String displayName, String id)
        throws Exception
    {
        ar.write("<a href=\"javascript:\" onclick=\"javascript:editDetail(");
        ar.writeQuote4JS(id);
        ar.write(", ");
        ar.writeQuote4JS(displayName);
        ar.write(",this,");
        ar.writeQuote4JS(ar.getCompleteURL());
        ar.write(");\">");
        ar.write("<span class=\"red\">");

        if(displayName.length() > 0){
            ar.writeHtml(displayName);
        }else{
            ar.write(id);
        }
        ar.write("</span>");
        ar.write("</a>");
    }
}
