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

import java.util.Hashtable;
import java.util.Vector;

/**
* NGTerm implements the many-to-many linking of pages (with multiple links)
* to pages (with multiple names).  Each term object represents a particular
* simplified name.
*/
public class NGTerm
{
    public String sanitizedName;
    public Vector<NGPageIndex> sourceLeaves = new Vector<NGPageIndex>();
    public Vector<NGPageIndex> targetLeaves = new Vector<NGPageIndex>();

    private static Hashtable<String,NGTerm> allTerms;
    private static Hashtable<String,NGTerm> allTags;

    /**
    * Name must be sanitized before constructing the term object.
    */
    private NGTerm(String name)
    {
        sanitizedName = name;
    }


    /**
    * Set all static values back to their initial states, so that
    * garbage collection can be done, and subsequently, the
    * class will be reinitialized.
    */
    public synchronized static void clearAllStaticVars()
    {
        allTerms = null;
        allTags = null;
    }


    static public void initialize()
    {
        allTerms  = new Hashtable<String,NGTerm>();
        allTags  = new Hashtable<String,NGTerm>();
    }


    /**
    * Pass a NON-sanitized name, and this will return
    * the term object corresponding to that term.
    * It will create one if an existing one is not found.
    */
    static public NGTerm findTerm(String name)
    {
        String sanitizedName = SectionWiki.sanitize(name);
        if (sanitizedName.length()==0)
        {
            return null;
        }
        NGTerm termx = allTerms.get(sanitizedName);
        if (termx==null)
        {
            termx = new NGTerm(sanitizedName);
            allTerms.put(sanitizedName, termx);
        }
        return termx;
    }

    /**
    * Pass a NON-sanitized name, and this will return
    * the term object corresponding to that term.
    * It will create one if an existing one is not found.
    *
    * Tags must have a sanitized value of 3 characters or more.
    * Short tags are ignored.
    *
    * Tags are in a separate pool from terms, so they
    * don't get mixed up or cross linked.  Otherwise
    * tags that are the same as a name gets confused.
    */
    static public NGTerm findOrCreateTag(String name)
    {
        String sanitizedName = SectionWiki.sanitize(name);
        if (sanitizedName.length()<3)
        {
            return null;
        }
        NGTerm termx = allTags.get(sanitizedName);
        if (termx==null)
        {
            termx = new NGTerm(sanitizedName);
            allTags.put(sanitizedName, termx);
        }
        return termx;
    }

    /**
    * If the term exists, return it, otherwise return null
    */
    public static NGTerm findTermIfExists(String name)
    {
        String sanitizedName = SectionWiki.sanitize(name);
        NGTerm termx = allTerms.get(sanitizedName);
        return termx;
    }
    /**
    * If the tag exists, return it, otherwise return null
    */
    public static NGTerm findTagIfExists(String name)
    {
        String sanitizedName = SectionWiki.sanitize(name);
        NGTerm termx = allTags.get(sanitizedName);
        return termx;
    }

    public void removeSource(NGPageIndex idx)
    {
        sourceLeaves.remove(idx);

        //if there are no inbound nor outbound references, then
        //remove the term from the index ... no longer needed
        //and will be recreated later if needed.
        if (sourceLeaves.size()==0 && targetLeaves.size()==0)
        {
            allTerms.remove(this);
        }
    }

    public void removeTarget(NGPageIndex idx)
    {
        targetLeaves.remove(idx);

        //if there are no inbound nor outbound references, then
        //remove the term from the index ... no longer needed
        //and will be recreated later if needed.
        if (sourceLeaves.size()==0 && targetLeaves.size()==0)
        {
            allTerms.remove(this);
        }
    }

}

