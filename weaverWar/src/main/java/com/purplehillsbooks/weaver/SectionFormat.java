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

/**
* A section is associated with a section type, and each type is
* assocaited with a format. A format is like a data type: it defines
* how the section is displayed and how it is edited.
*/
public interface SectionFormat
{

    /**
    * get the name of the format
    */
    public String getName();

    /**
    * scans the section information, finds all the link values, and adds them
    * to the vector.
    */
    public void findLinks(List<String> v, NGSection section) throws Exception;

    /**
    * scans the section information, and return the plain text data that can be
    * used for search.
    */
    public void writePlainText(NGSection section, Writer out) throws Exception;

    /**
    * Walk through whatever elements this owns and put all the four digit
    * IDs into the vector so that we can generate another ID and assure it
    * does not duplication any id found here.
    */
    public void findIDs(List<String> v, NGSection sec) throws Exception;

    /**
    * In an attempt to convert all the older display section formats to
    * a common Topic format, this method will be a format specific way to
    * convert the contents to a TopicRecord and place it with the other discussion topics.
    */
    public TopicRecord convertToLeaflet(NGSection leafletSection,
                   NGSection wikiSection) throws Exception;

}
