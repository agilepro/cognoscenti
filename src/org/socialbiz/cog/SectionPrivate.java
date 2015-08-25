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

import org.socialbiz.cog.exception.ProgramLogicError;
import java.io.Writer;
import org.w3c.dom.Element;
import org.w3c.dom.NodeList;

public class SectionPrivate extends SectionWiki
{

    private static String NOTE_NODE_NAME = "note";
    private static String OWNER_NODE_NAME = "owner";
    private static String DATA_NODE_NAME = "data";
    //private static String PRIVATE_SECTION_NAME = "Private";

    public SectionPrivate()
    {
    }

    public String getName()
    {
        return "Private Format";
    }

    public void writePlainText(NGSection section, Writer out) throws Exception
    {
        //don't throw exception in this case, because it can effect search function
        return;
    }


    /**
    * Converts a Wiki section to a note, copying appropriate information
    * from the wiki section to the note.  The idea is that all (displayable)
    * sections will become leaflets in the future.
    * This might be called just before deleting the section.
    * Returns NULL if the section is empty.
    *
    * Even though this class is not used in new pages, we have to leave
    * this class around so we can convert old pages.
    */
    public NoteRecord convertToLeaflet(NGSection noteSection,
                   NGSection wikiSection) throws Exception
    {
        SectionDef def = wikiSection.def;
        SectionFormat sf = def.format;
        if (sf != this)
        {
            throw new ProgramLogicError("Method convertToLeaflet must be called on the format object for the section being converted");
        }
        NodeList nl = DOMUtils.findNodesOneLevel(wikiSection.getElement(), NOTE_NODE_NAME);
        int size = nl.getLength();
        for(int i=0; i<size; i++)
        {
            Element ei = (Element)nl.item(i);
            String owner = DOMUtils.getChildText(ei,OWNER_NODE_NAME);
            String data = DOMUtils.getChildText(ei, DATA_NODE_NAME).trim();
            if (data==null || data.length()==0)
            {
                //this section is empty, so don't create any leaflet, and return null
                return null;
            }
            NoteRecord newNote = noteSection.createChildWithID(
                SectionForNotes.LEAFLET_NODE_NAME, NoteRecord.class, "id", IdGenerator.generateKey());
            newNote.setOwner(owner);
            newNote.setModUser(new AddressListEntry(owner));
            newNote.setLastEdited(wikiSection.getLastModifyTime());
            newNote.setEffectiveDate(wikiSection.getLastModifyTime());
            newNote.setSubject("Private Note for "+owner);
            newNote.setWiki(data);
            newNote.setVisibility(SectionDef.PRIVATE_ACCESS);
        }
        return null;
    }


}
