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

/**
 * This section format is used whenever a section element is found
 * and the name of the section is not recognized or unknown.
 * Currently this allows the unknown section to persist, but you
 * can not edit it or anything.
 */
public class SectionUnknown extends SectionWiki {

    public SectionUnknown() {

    }

    public String getName() {
        return "(Unknown Format)";
    }

    public void findLinks(Vector<String> v, NGSection section) throws Exception
    {
        //no links to find
    }


    public void writePlainText(NGSection section, Writer out) throws Exception
    {
        // nothing to write
    }

    public NoteRecord convertToLeaflet(NGSection noteSection,
                   NGSection wikiSection) throws Exception
    {
        throw new ProgramLogicError("Method convertToLeaflet not implemented for Unknown Format");
    }

}
