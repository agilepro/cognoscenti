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
import java.util.Vector;
import org.w3c.dom.Document;
import org.w3c.dom.Element;

public class PageInfoRecord extends DOMFace
{
    DOMFace userList;
    DOMFace roleList;
    DOMFace roleRequestList;


    public PageInfoRecord(Document nDoc, Element nEle, DOMFace p)
        throws Exception
    {
        super(nDoc, nEle, p);
        //assure that the user list element is there
        roleList = requireChild("roleList", DOMFace.class);
        roleRequestList = requireChild("Role-Requests", DOMFace.class);
    }

    /**
    * Book Key is the Site Key
    */
    public String getSiteKey() {
        String siteKey = getAttribute("book");
        //silly default from time when book key was not set
        if (siteKey==null || siteKey.length()==0) {
            setAttribute("book", "mainbook");
            return "mainbook";
        }
        return siteKey;
    }
    public void setSiteKey(String newKey) {
        setAttribute("book", newKey);
    }

    /**
    * This is the unique ID of the entire project
    * across all sites.  It is up to the system to
    * make sure this is created and maintained unique
    * and it must never be changed (or links will be
    * broken).  Linking should be by name if possible.
    */
    public String getKey() {
        return getAttribute("key");
    }
    public void setKey(String newKey) {
        setAttribute("key", newKey);
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


    String[] getPageNames() {
        Vector<String> vc = getVector("pageName");
        Vector<String> vccleaned = new Vector<String>();
        for (String chl : vc) {
            String aName = chl.trim();
            if (aName.length() > 0) {
                vccleaned.add(aName);
            }
        }

        String[] displayNames = new String[vccleaned.size()];
        vccleaned.copyInto(displayNames);
        return displayNames;
    }

    public void setPageNames(String[] newNames)
    {
        DOMUtils.removeAllNamedChild(fEle, "pageName");
        for (int i=0; i<newNames.length; i++)
        {
            String aName = newNames[i].trim();
            //only save names that are non-null
            if (aName.length()>0)
            {
                addVectorValue("pageName", aName);
            }
        }
    }

    /**
    * Marking a project as deleted means that we SET the deleted time.
    * If there is no deleted time, then it is not deleted.
    * A project that is deleted remains in the archive until a later
    * date, when garbage has been collected.  If the project has remained
    * deleted for more than 90 days, then the file is actually
    * removed from the file system (and so are all the attachments)
    */
    public boolean isDeleted()
    {
        String delAttr = getAttribute("deleteUser");
        return (delAttr!=null&&delAttr.length()>0);
    }

    /**
    * Set deleted date to the date that it is effectively deleted,
    * which is the current time in most cases.
    * Set the date to zero in order to clear the deleted flag
    * and make the project to be not-deleted
    */
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


    /**
    * Marking a project as frozen means that we SET the frozen time and user.
    * If there is no frozen time, then it is not frozen.
    *
    * The administrator of a project is allowed to freeze or unfreeze it.
    * It is a lot like deleted, in that users can not make changes,
    * a frozen project will remain in that state indefinitely for future
    * reference.
    */
    public boolean isFrozen()
    {
        //deleted projects are always frozen by definition, even if they
        //were not purposefully frozen at a point in time..
        if (isDeleted())
        {
            return true;
        }
        String frzAttr = getAttribute("freezeUser");
        return (frzAttr!=null&&frzAttr.length()>0);
    }
    /**
    * Set deleted date to the date that it is effectively deleted,
    * which is the current time in most cases.
    * Set the date to zero in order to clear the deleted flag
    * and make the project to be not-deleted
    */
    public void freezeProject(AuthRequest ar)
    {
        setAttribute("freezeDate", Long.toString(ar.nowTime));
        setAttribute("freezeUser", ar.getBestUserId());
    }
    public void unfreezeProject()
    {
        if (isDeleted())
        {
            throw new ProgramLogicError("attempt to unfreeze a project which is deleted.  Undelete the project first.");
        }
        setAttribute("freezeDate", null);
        setAttribute("freezeUser", null);
    }
    public long getFrozenDate()
    {
        return getAttributeLong("freezeDate");
    }
    public String getFrozenUser()
    {
        return getAttribute("freezeUser");
    }

    public void setAllowPublic(String allowPublic)
    {
        setAttribute("allowPublic", allowPublic);
    }

    public String getAllowPublic(){
        return getAttribute("allowPublic");
    }

    public String getProjectMailId() {
        return getAttribute("projectMailId");
    }

    public void setProjectMailId(String id) {
        setAttribute("projectMailId", id);
    }

}
