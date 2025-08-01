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

import com.purplehillsbooks.weaver.exception.WeaverException;

public class SectionForNotes extends SectionUtil implements SectionFormat {

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

    private static List<TopicRecord> getAllNotesInSection(NGSection section)
            throws Exception {
        return section.getChildren(LEAFLET_NODE_NAME, TopicRecord.class);
    }

    public static TopicRecord getLeaflet(String cmtId, NGSection section)
            throws Exception {
        for (TopicRecord lr : getAllNotesInSection(section)) {
            String id = lr.getId();
            if (cmtId.equals(id)) {
                return lr;
            }
        }
        return null;
    }

    public void findLinks(List<String> v, NGSection section) throws Exception {

        for (TopicRecord cr : getAllNotesInSection(section)) {
            String tv = cr.getWiki();
            LineIterator li = new LineIterator(tv);
            while (li.moreLines()) {
                String thisLine = li.nextLine();
                scanLineForLinks(thisLine, v);
            }
        }
    }

    protected void scanLineForLinks(String thisLine, List<String> v) {
        int bracketPos = thisLine.indexOf('[');
        int startPos = 0;
        while (bracketPos >= startPos) {
            int endPos = thisLine.indexOf(']', bracketPos);
            if (endPos <= startPos) {
                return; // could not find any more closing brackets, leave
            }
            String link = thisLine.substring(bracketPos + 1, endPos);
            v.add(link);
            startPos = endPos + 1;
            bracketPos = thisLine.indexOf('[', startPos);
        }
    }

    /**
     * Copies the topics from on section to another. The idea is that all
     * (displayable) sections will become topics in the future. This might be
     * called just before deleting the section. Returns NULL if the section is
     * empty.
     */
    public TopicRecord convertToLeaflet(NGSection noteSection,
            NGSection wikiSection) throws Exception {
        SectionDef def = wikiSection.def;
        SectionFormat sf = def.format;
        if (sf != this) {
            throw WeaverException.newBasic(
                    "Method convertToLeaflet must be called on the format object for the section being converted");
        }
        for (TopicRecord cr : getAllNotesInSection(wikiSection)) {
            TopicRecord newNote = noteSection
                    .createChildWithID(SectionForNotes.LEAFLET_NODE_NAME,
                            TopicRecord.class, "id", IdGenerator.generateKey());
            newNote.setOwner(cr.getOwner());
            newNote.setLastEdited(cr.getLastEdited());
            newNote.setModUser(AddressListEntry.findOrCreate(cr.getOwner()));
            newNote.setEffectiveDate(cr.getEffectiveDate());
            newNote.setSubject(cr.getSubject());
            newNote.setWiki(cr.getWiki());
        }
        return null;
    }

}
