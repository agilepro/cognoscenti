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

import java.io.Writer;
import java.util.List;

import com.purplehillsbooks.weaver.exception.ProgramLogicError;
import org.w3c.dom.Element;
import org.w3c.dom.NodeList;

/**
 * Implements the Wiki formatting
 */
public class SectionWiki extends SectionUtil implements SectionFormat {

    public SectionWiki() {

    }

    public String getName() {
        return "Wiki Format";
    }

    public void findLinks(List<String> v, NGSection section) throws Exception {
        LineIterator li = new LineIterator(section.asText().trim());
        while (li.moreLines())
        {
            String thisLine = li.nextLine();
            scanLineForLinks(thisLine, v);
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

/*     //TODO: should take an AuthRequest, and WikiConverter
    public void writePlainText(NGSection section, Writer out) throws Exception {

        if (section == null || out == null) {
            return;
        }

        LineIterator li = new LineIterator(section.asText().trim());
        while (li.moreLines()) {
            String thisLine = li.nextLine();
            removeWikiFormattings(out, thisLine);
            out.write(" ");
        }
    }
 */
    //TODO: should take an AuthRequest, and WikiConverter
    private void removeWikiFormattings(Writer out, String line)
            throws Exception {
        if (line == null || ((line = line.trim()).length()) == 0) {
            return;
        }

        if (line.startsWith("----")) {
            line = subString(line, 4);
        } else if (line.startsWith("!!!") || (line.startsWith("***"))) {
            line = subString(line, 3);
        } else if (line.startsWith("!!") || (line.startsWith("**"))) {
            line = subString(line, 2);
        } else if (line.startsWith("!") || (line.startsWith("*"))) {
            line = subString(line, 1);
        }
        writeTextWithLB(line, out);
    }

    //TODO: should take an AuthRequest, and WikiConverter
    private String subString(String line, int length) {
        if (line == null) {
            return "";
        }

        if (line.length() > length) {
            return line.substring(length);
        }
        return "";
    }

    // this method is used for Section comments and for private sections.
    public void writePlainTextForComments(NGSection section, Writer out)
            throws Exception {

        if (section == null || out == null) {
            return;
        }

        Element secElem = section.getElement();
        NodeList nl = DOMUtils.findNodesOneLevel(secElem,
                SectionForNotes.LEAFLET_NODE_NAME);

        for (int i = 0; i < nl.getLength(); i++) {
            Element ei = (Element) nl.item(i);
            if (ei == null) {
                continue; // there are strange cases where it can be null
            }
            String owner = DOMUtils.getChildText(ei,
                    SectionForNotes.OWNER_NODE_NAME);
            SectionUtil.writeTextWithLB(owner, out);

            String cTime = DOMUtils.getChildText(ei,
                    SectionForNotes.CREATE_NODE_NAME);
            SectionUtil.writeTextWithLB(cTime, out);

            String subject = DOMUtils.getChildText(ei,
                    SectionForNotes.SUBJECT_NODE_NAME);
            SectionUtil.writeTextWithLB(subject, out);

            String tv = DOMUtils.getChildText(ei,
                    SectionForNotes.DATA_NODE_NAME).trim();
            LineIterator li = new LineIterator(tv);
            while (li.moreLines()) {
                String thisLine = li.nextLine();
                removeWikiFormattings(out, thisLine);
                out.write(" ");
            }
        }
    }

    /**
    * Converts a Wiki section to a topic, copying appropriate information
    * from the wiki section to the topic.  The idea is that all (displayable)
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
            //this section is empty, so don't create any leaflet, and return null
            return null;
        }
        TopicRecord newNote = noteSection.createChildWithID(
            SectionForNotes.LEAFLET_NODE_NAME, TopicRecord.class, "id", IdGenerator.generateKey());
        newNote.setOwner(wikiSection.getLastModifyUser());
        newNote.setModUser(new AddressListEntry(wikiSection.getLastModifyUser()));
        newNote.setLastEdited(wikiSection.getLastModifyTime());
        newNote.setEffectiveDate(wikiSection.getLastModifyTime());
        newNote.setSubject(def.displayName + " - " + wikiSection.parent.getFullName());
        newNote.setWiki(data);
        return newNote;
    }

}
