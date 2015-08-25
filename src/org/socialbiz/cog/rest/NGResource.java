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

package org.socialbiz.cog.rest;

import org.w3c.dom.Document;

public interface NGResource
{
    public static String RESOURCE_SECTION = "s";
    public static String RESOURCE_SEARCH = "q";
    public static String RESOURCE_LICENCE = "l";
    public static String RESOURCE_RELAY = "relay";

    public static String TYPE_XML = "xml";
    public static String TYPE_FILe = "file";

    public static String OP_SUCCEEDED = "SUCCESS";
    public static String OP_FAILED = "FAILED";
    public static String OP_PARTIAL = "PARTIAL";

    public static String ACCESS_AUTHOR = "A";
    public static String ACCESS_PAUTHOR = "PA";
    public static String ACCESS_MEMBER = "M";
    public static String ACCESS_PMEMBER = "PM";
    public static String ACCESS_REMOVE = "REMOVE";

    public static String DATA_BOOK_XML = "book.xml";
    public static String DATA_USERLIST = "userlist.xml";
    public static String DATA_PAGELIST = "pagelist.xml";
    public static String DATA_PAGE_XML = "leaf.xml";
    public static String DATA_PARENT_XML = "parent.xml";
    public static String DATA_SECTION_XML = "section.xml";
    public static String DATA_SECCONTENT_XML = "data.xml";
    public static String DATA_SUBPROCESS_XML = "subprocess.xml";
    public static String DATA_HISTORY_XML = "history.xml";
    public static String DATA_ALLTASK_XML = "alltask.xml";
    public static String DATA_ACTIVETASK_XML = "activetask.xml";
    public static String DATA_COMPLETETASK_XML = "completetask.xml";
    public static String DATA_FUTURETASK_XML = "futuretask.xml";
    public static String DATA_SEARCH_XML = "search.xml";
    public static String DATA_LICENSE_XML = "license.xml";
    public static String DATA_PROFILE_XML = "profile.xml";


    public static String SCHEMA_BOOK = "rest/xsd/Leaf.xsd";
    public static String SCHEMA_USERLIST = "rest/xsd/Leaf.xsd";
    public static String SCHEMA_STATUS = "rest/xsd/Leaf.xsd";
    public static String SCHEMA_PAGE = "rest/xsd/Leaf.xsd";
    public static String SCHEMA_PAGELIST = "rest/xsd/Leaf.xsd";
    public static String SCHEMA_TASKLIST = "rest/xsd/Leaf.xsd";
    public static String SCHEMA_SECTION_WIKI = "rest/xsd/Leaf.xsd";
    public static String SCHEMA_SECTION_LINK = "rest/xsd/Leaf.xsd";
    public static String SCHEMA_SECTION_ATTTACH = "rest/xsd/Leaf.xsd";
    public static String SCHEMA_SECTION_COMMENT = "rest/xsd/Leaf.xsd";
    public static String SCHEMA_SECTION_PROCESS = "rest/xsd/Leaf.xsd";
    public static String SCHEMA_SECTION_TASKS = "rest/xsd/Leaf.xsd";
    public static String SCHEMA_SECTION_HISTORY = "rest/xsd/Leaf.xsd";
    public static String SCHEMA_SECTION_POLL = "rest/xsd/Leaf.xsd";
    public static String SCHEMA_SEARCH = "rest/xsd/Leaf.xsd";
    public static String SCHEMA_GEOSPATIAL = "rest/xsd/Leaf.xsd";
    public static String SCHEMA_USERPROFILE = "rest/xsd/Leaf.xsd";

    public String    getType();
    public Document  getDocument() throws Exception;
    public String    getFilePath();
    public int       getStatusCode();

}