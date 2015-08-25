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
import java.util.Vector;

import org.socialbiz.cog.exception.ProgramLogicError;

public class SectionForNotes extends SectionWiki {

    public static String LEAFLET_NODE_NAME = "note";
    public static String OWNER_NODE_NAME = "owner";
    public static String CREATE_NODE_NAME = "created";
    public static String DATA_NODE_NAME = "data";
    public static String SUBJECT_NODE_NAME = "subject";
    public static String PRIVATE_SECTION_NAME = "Comments";

    public SectionForNotes() {
    }

    public String getName() {
        return "Note";
    }

/*
    public void removeLeaflet(String oId, NGSection section) throws Exception {
        NoteRecord ei = getLeaflet(oId, section);
        if (ei != null) {
            section.removeChild(ei);
        }
    }


    public static NoteRecord addLeaflet(AuthRequest ar, NGSection section,
            String subject, String data) throws Exception {
        String id = IdGenerator.generateKey();
        NoteRecord newNote = section.createChildWithID(
                LEAFLET_NODE_NAME, NoteRecord.class, "id", id);
        newNote.setOwner(ar.getBestUserId());
        newNote.setLastEditedBy(ar.getBestUserId());
        newNote.setLastEdited(ar.nowTime);
        newNote.setSubject(subject);
        newNote.setData(data);
        return newNote;
    }
*/
    private static List<NoteRecord> getAllNotesInSection(NGSection section)
            throws Exception {
        return section.getChildren(LEAFLET_NODE_NAME, NoteRecord.class);
    }

    public static Vector<NoteRecord> getVisibleComments(NGSection section, int desiredViz,
            UserProfile up) throws Exception {
        Vector<NoteRecord> nl = new Vector<NoteRecord>();
        for (NoteRecord cr : getAllNotesInSection(section)) {
            int visibility = cr.getVisibility();
            if (visibility != desiredViz || cr.isDeleted()) {
                continue;
            }
            if (visibility == 4) {
                // must test ownership
                if (!up.hasAnyId(cr.getOwner())) {
                    continue;
                }
            }
            nl.add(cr);
        }
        NoteRecord.sortNotesInPinOrder(nl);
        return nl;
    }

    public static NoteRecord getLeaflet(String cmtId, NGSection section)
            throws Exception {
        for (NoteRecord lr : getAllNotesInSection(section)) {
            String id = lr.getId();
            if (cmtId.equals(id)) {
                return lr;
            }
        }
        return null;
    }

    public void writePlainText(NGSection section, Writer out) throws Exception {
        writePlainTextForComments(section, out);
    }

    public void findLinks(Vector<String> v, NGSection section) throws Exception {

        for (NoteRecord cr : getAllNotesInSection(section)) {
            String tv = cr.getWiki();
            LineIterator li = new LineIterator(tv);
            while (li.moreLines()) {
                String thisLine = li.nextLine();
                scanLineForLinks(thisLine, v);
            }
        }
    }

    /**
     * Copies the notes from on section to another. The idea is that all
     * (displayable) sections will become notes in the future. This might be
     * called just before deleting the section. Returns NULL if the section is
     * empty.
     */
    public NoteRecord convertToLeaflet(NGSection noteSection,
            NGSection wikiSection) throws Exception {
        SectionDef def = wikiSection.def;
        SectionFormat sf = def.format;
        if (sf != this) {
            throw new ProgramLogicError(
                    "Method convertToLeaflet must be called on the format object for the section being converted");
        }
        for (NoteRecord cr : getAllNotesInSection(wikiSection)) {
            NoteRecord newNote = noteSection
                    .createChildWithID(SectionForNotes.LEAFLET_NODE_NAME,
                            NoteRecord.class, "id", IdGenerator.generateKey());
            newNote.setOwner(cr.getOwner());
            newNote.setLastEdited(cr.getLastEdited());
            newNote.setModUser(new AddressListEntry(cr.getOwner()));
            newNote.setEffectiveDate(cr.getEffectiveDate());
            newNote.setSubject(cr.getSubject());
            newNote.setWiki(cr.getWiki());
            newNote.setVisibility(cr.getVisibility());
        }
        return null;
    }

}
