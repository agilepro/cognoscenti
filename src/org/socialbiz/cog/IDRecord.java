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
import java.util.Enumeration;
import java.util.List;
import java.util.Vector;
import java.util.Comparator;
import java.util.Collections;
import org.w3c.dom.Document;
import org.w3c.dom.Element;


/**
* The user may have a number of different open ids and email addresses
* this class will hold the id, and the user profile will have a collection
* of these.
*/
public class IDRecord extends DOMFace
{
    //I figure this will be hit quite a bit, so remembering the
    //id when fetched the first time will probably make a difference,
    //and should not cause any additional memory bloat
    String cachedId;

    public IDRecord(Document doc, Element upEle, DOMFace p)
    {
        super(doc,upEle,p);
    }

    /**
    * Pattern is "create" and the class name, is the proper way to
    * create a new element in the DOM tree, and return the wrapper class
    * Must pass the user that this is an ID of.
    */
    public static IDRecord createIDRecord(UserProfile user, String newId)
        throws Exception
    {
        if (newId==null)
        {
            throw new RuntimeException("null value for newId passed to createIDRecord");
        }
        IDRecord newIdRec = user.createChild("idrec", IDRecord.class);
        newIdRec.setLoginId(newId);
        return newIdRec;
    }

    /**
    * remove the id from the user profile
    */
    public void removeIDRecord(UserProfile user)
        throws Exception
    {
        user.removeChild(this);
    }

    /**
    * add all of the id records for a particular user into
    * the provided vector.
    */
    public static void findIDRecords(UserProfile user, Vector<IDRecord> results)
        throws Exception
    {
        Vector<IDRecord> chilluns = user.getChildren("idrec", IDRecord.class);
        Enumeration<IDRecord> e = chilluns.elements();
        while (e.hasMoreElements())
        {
            IDRecord ele = e.nextElement();
            results.add(ele);
        }
    }

    public String getLoginId()
    {
        if (cachedId==null)
        {
            cachedId = getAttribute("loginid");

            //migration code .. some values were saved with spaces.  This eliminates
            //the spaces from the values.   Remove after Dec 2012.
            if (cachedId.indexOf(" ")>=0) {
                setLoginId(removeAllSpaces(cachedId));
            }
        }
        return cachedId;
    }


    /**
    * returns a string will all spaces removed
    * not very efficient ... designed for low performance use.
    */
    private String removeAllSpaces(String val)
    {
        val = val.trim();
        int spacePos = val.indexOf(" ");
        while (spacePos >= 0) {
            val = val.substring(0,spacePos) + val.substring(spacePos+1);
            spacePos = val.indexOf(" ");
        }
        return val;
    }


    private void setLoginId(String newId)
    {
        //id should never have any spaces in it, and if it is, there is an error
        //in the UI code.  Warn about this so the other code can be fixed.
        if (newId.indexOf(" ")>=0) {
            throw new ProgramLogicError("an id with a space was passed to IDRecord.setLoginId: ("+newId+")");
        }

        cachedId = newId;
        setAttribute("loginid", newId);
    }


    public boolean isEmail()
    {
        String login = getLoginId();
        return login.indexOf("@")>0
            && !startsWithIgnoreCase(login, "http://")
            && !startsWithIgnoreCase(login, "https://");
    }

    private boolean startsWithIgnoreCase(String dataVal, String testVal) {
        if (dataVal.length()<testVal.length()) {
            return false;
        }
        return dataVal.substring(0, testVal.length()).equalsIgnoreCase(testVal);
    }

    //should consider saving the simplified value and using that for
    //a faster compare.
    public boolean equalsId(String testVal)
    {
        String val = getLoginId();
        if (val.equalsIgnoreCase(testVal))
        {
            return true;
        }
        String simplifiedVal = simplifyOpenId(testVal);
        String simplifiedId = simplifyOpenId(val);
        if (simplifiedId.equalsIgnoreCase(simplifiedVal))
        {
            return true;
        }
        return false;
    }


    public static String simplifyOpenId(String openId)
    {
        int start = 0;
        int end = openId.length();
        if (openId.startsWith("https://"))
        {
            start = 8;
        }
        else if (openId.startsWith("http://"))
        {
            start = 7;
        }

        if (openId.endsWith("/"))
        {
            end--;
        }
        return openId.substring(start, end);
    }

    public static void sortByType(List<IDRecord> list)
    {
        Collections.sort(list, new IDRecord.IDComparator());
    }

    public static class IDComparator implements Comparator<IDRecord>
    {
        public IDComparator() {}

        public int compare(IDRecord o1, IDRecord o2)
        {
            IDRecord id1 = o1;
            IDRecord id2 = o2;
            boolean email1 = id1.isEmail();
            boolean email2 = id2.isEmail();

            //if they are both email, or both open id, then just sort by ID
            if (email1==email2)
            {
                return id1.getLoginId().compareTo(id2.getLoginId());
            }
            if (email1)
            {
                return -1;
            }
            return 1;
        }
    }

}
