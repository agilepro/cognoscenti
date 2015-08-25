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

public class LeafletResponseRecord extends DOMFace
{

    public LeafletResponseRecord(Document definingDoc, Element definingElement, DOMFace lr)
    {
        super(definingDoc, definingElement, lr);

        //verify that there is a user attribute on the tag
        String user = getAttribute("user");
        if (user==null || user.length()==0)
        {
            throw new RuntimeException("A note response tag MUST have an "
                         +"attribute 'user' with a valid value");
        }
    }

    /**
    * The user is the key to this record.  There is no way to change
    * the key (no way to set it).  It must be created with a particular
    * key.  You can read it with this method.
    */
    public String getUser()
    {
        return getAttribute("user");
    }
    public void setUser(String u)
    {
        setAttribute("user", u);
    }

    public long getLastEdited()
    {
        return safeConvertLong(getAttribute("edited"));
    }
    public void setLastEdited(long newCreated)
    {
        setAttribute("edited", Long.toString(newCreated));
    }

    public String getData()
    {
        return getScalar("data");
    }
    public void setData(String newData)
    {
        setScalar("data", newData);
    }
    public String getChoice()
    {
        return getScalar("choice");
    }
    public void setChoice(String newData)
    {
        setScalar("choice", newData);
    }

}
