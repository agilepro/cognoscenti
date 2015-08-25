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

public class VoteRecord extends DOMFace
{

    public VoteRecord(Document doc, Element ele, DOMFace p)
    {
        super(doc, ele, p);
    }

    public String getWho()
        throws Exception
    {
        return getScalar("who");
    }
    public void setWho(String id)
        throws Exception
    {
        setScalar("who", id);
    }

    public String getChoice()
        throws Exception
    {
        return getScalar("choice");
    }
    public void setChoice(String choice)
        throws Exception
    {
        setScalar("choice", choice);
    }
    public String getComment()
        throws Exception
    {
        return getScalar("comment");
    }
    public void setComment(String comment)
        throws Exception
    {
        setScalar("comment", comment);
    }
    public long getTimestamp()
    {
        String ts = getScalar("time");
        if (ts==null)
        {
            return 0;
        }
        return safeConvertLong(ts);
    }
    public void setTimestamp(long newTime)
    {
        setScalar("time", Long.toString(newTime));
    }
}

