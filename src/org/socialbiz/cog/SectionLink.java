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
import java.util.List;

import org.socialbiz.cog.exception.ProgramLogicError;

/**
* Implements the Bidirectional Link formatting
*
* This format is very simple: it is a block of text where every line
* is a link to another page.  Each line contains the name of a page
* the HTML generated is a link to that page.
*
* Currently the editor is a manual editor, but a more sophisticated
* editor will allow for list style editing: a list of links, ADD, and
* DELETE buttons.
*
* FUTURE:
* This should define bi-directional links: a link from page 1 to page 2
* causes a reverse link from page 2 to page 1.  This will require the
* pages to be read, and an index of reverse links to be formed across
* all pages, so that page 2 can find out about all the pages pointing to
* it.  The section pointing one direction, and there will be an opposite
* section pointing back.  For example: a company page may have a
* "products" section, and the pointed to product page will then get a
* "product of" section pointing back.  The section def will include the
* name of the forward link section name, and the backward link section name
*/
public class SectionLink extends SectionWiki
{

    public SectionLink()
    {

    }

    public String getName()
    {
        return "Link Format";
    }


    public void findLinks(List<String> v, NGSection section)
        throws Exception
    {
        String tv = section.asText().trim();
        int pos = 0;

        int returnPos = tv.indexOf("\n");
        while (returnPos>=pos) {
            String thisLine = tv.substring(pos, returnPos).trim();
            if (thisLine.length()>0)
            {
                v.add(thisLine);
            }

            pos = returnPos+1;
            //strip the line feed if there is one.
            if (tv.charAt(pos)=='\r')
            {
                pos++;
            }
            returnPos = tv.indexOf("\n", pos);
        }
        if (pos<tv.length())
        {
            String thisLine = tv.substring(pos).trim();
            if (thisLine.length()>0)
            {
                v.add(thisLine);
            }
        }
    }

   public void writePlainText(NGSection section, Writer out) throws Exception
   {

        if (section == null || out == null) {
            return;
        }

        LineIterator li = new LineIterator(section.asText());
        while (li.moreLines())
        {
            String thisLine = li.nextLine();
            writeTextWithLB(thisLine, out);
        }
   }

    /**
    * Converts a Link section to a topic, converting the links
    * appropriately.  The idea is that all (displayable)
    * sections will become topics in the future.
    * This might be called just before deleting the section.
    * Returns NULL if the section is empty.
    */
    public TopicRecord convertToLeaflet(NGSection noteSection,
                   NGSection wikiSection) throws Exception
    {
        SectionDef def = wikiSection.def;
        SectionFormat sf = def.format;
        if (sf != this)
        {
            throw new ProgramLogicError("Method convertToLeaflet must be called on the format object for the section being converted");
        }
        String data = wikiSection.asText();
        if (data==null || data.length()==0)
        {
            //this section is empty, so don't create any topic, and return null
            return null;
        }
        StringBuilder modifiedSource = new StringBuilder();
        LineIterator li = new LineIterator(data);
        while (li.moreLines())
        {
            String thisLine = li.nextLine().trim();
            if (thisLine.length()>0)
            {
                modifiedSource.append("* [");
                modifiedSource.append(thisLine);
                modifiedSource.append("]\n");
            }
        }

        TopicRecord newNote = noteSection.createChildWithID(
            SectionForNotes.LEAFLET_NODE_NAME, TopicRecord.class, "id", IdGenerator.generateKey());
        newNote.setOwner(wikiSection.getLastModifyUser());
        newNote.setModUser(new AddressListEntry(wikiSection.getLastModifyUser()));
        newNote.setLastEdited(wikiSection.getLastModifyTime());
        newNote.setEffectiveDate(wikiSection.getLastModifyTime());
        newNote.setSubject(def.displayName + " - " + wikiSection.parent.getFullName());
        newNote.setWiki(modifiedSource.toString());
        newNote.setVisibility(def.viewAccess);
        return newNote;
    }

}
