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

import java.util.ArrayList;
import java.util.List;

import org.w3c.dom.Document;
import org.w3c.dom.Element;

public class BookInfoRecord  extends DOMFace
{

    public BookInfoRecord(Document nDoc, Element nEle, DOMFace p)
        throws Exception
    {
        super(nDoc, nEle, p);
        //assure that the user list element is there
        requireChild("roleList", DOMFace.class);
        requireChild("Role-Requests", DOMFace.class);

    }

    public long getModTime()
    {
        return safeConvertLong(getAttribute("modTime"));
    }
    public void setModTime(long newTime)
    {
        setAttribute("modTime", Long.toString(newTime));
    }

    public String getModUser()
    {
        return getAttribute("modUser");
    }
    public void setModUser(String newUser)
    {
        setAttribute("modUser", newUser);
    }

    public String getSynopsis()
        throws Exception
    {
        return getScalar("synopsis");
    }

    public void setSynopsis(String newVal)
        throws Exception
    {
        if (newVal == null) {
            newVal = "";
        }
        setScalar("synopsis", newVal);
    }


    public List<String> getPageNames() {
        List<String> vc = getVector("bookName");
        List<String> vccleaned = new ArrayList<String>();
        for (String chl : vc) {
            String aName = chl.trim();
            if (aName.length() > 0) {
                vccleaned.add(aName);
            }
        }
        return vccleaned;
    }

    public void setPageNames(String[] newNames)
    {
        DOMUtils.removeAllNamedChild(fEle, "bookName");
        for (int i=0; i<newNames.length; i++)
        {
            String aName = newNames[i].trim();
            //only save names that are non-null
            if (aName.length()>0)
            {
                addVectorValue("bookName", aName);
            }
        }
    }

    public boolean isDeleted()
    {
        String delAttr = getAttribute("deleteUser");
        return (delAttr!=null&&delAttr.length()>0);
    }

    public void setDeleted(AuthRequest ar)
    {
        setAttribute("deleteDate", Long.toString(ar.nowTime));
        setAttribute("deleteUser", ar.getBestUserId());
    }
    public void clearDeleted()
    {
        setAttribute("deleteDate", null);
        setAttribute("deleteUser", null);
    }
    public long getDeleteDate()
    {
        return getAttributeLong("deleteDate");
    }
    public String getDeleteUser()
    {
        return getAttribute("deleteUser");
    }

    public String getAllowPublic() {
        return getAttribute("allowPublic");
    }

    public void setAllowPublic(String allowPublic) {
        setAttribute("allowPublic", allowPublic);
    }


    /**
    * Different sites can have different style sheets (themes)
    * This is the path to the folder that holds the theme files
    */
    public String getThemePath()
    {
        return getScalar("theme");
    }
    public void setThemePath(String newName)
    {
        setScalar("theme", newName);
    }

    
    public static String themeImg(String theme) {
        return "theme/" + theme + "/themeIcon.gif";
    }



}
