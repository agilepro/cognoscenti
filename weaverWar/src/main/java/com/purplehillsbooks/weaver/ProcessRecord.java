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

import java.util.List;

import com.purplehillsbooks.weaver.exception.WeaverException;

import org.w3c.dom.Document;
import org.w3c.dom.Element;


public class ProcessRecord extends BaseRecord
{
    //NGSection section;
    public ProcessRecord(Document definingDoc, Element definingElement, DOMFace p)
        throws Exception
    {
        super(definingDoc, definingElement, p);

        // the process has a license token for RECEIVING interaction requests
        // someday parent links will have such licenses as well, but for now
        // we can use this.
        // force generation of license, & force cleanup of old XML
        accessLicense();
    }

   public int getState() {
        String stateVal = getScalar("state");
        return (int) safeConvertLong(stateVal);
    }

    public void setState(int newVal) throws Exception {
        if (getState() != newVal) {
            setScalar("state", Integer.toString(newVal));
        }
    }

    public void updateStatusFromGoals(List<GoalRecord> allGoals)  throws Exception
    {
        //if any task is in the waiting state, then the process is also.
        for (GoalRecord tr : allGoals) {
            if (tr.getState() == BaseRecord.STATE_WAITING) {
                setState(BaseRecord.STATE_WAITING);
                return;
            }
        }

        //nothing is waiting, so check if anything preventing being done
        for (GoalRecord goal : allGoals)
        {
            int state = goal.getState();
            if (state == BaseRecord.STATE_UNSTARTED ||
                    state == BaseRecord.STATE_OFFERED ||
                    state == BaseRecord.STATE_ACCEPTED ||
                    state == BaseRecord.STATE_ERROR) {
                //don't change anything
                return;
            }
        }

        //OK, we can mark this as complete now.
        setState(BaseRecord.STATE_COMPLETE);
    }


    /**
    * Generates a fully qualified, licensed,  Wf-XML link for this process
    * This is the link someone else would use to get to this process.
    * AuthRequest is needed to know the current server context path
    *
    public LicensedURL getWfxmlLink(AuthRequest ar)
        throws Exception
    {
        NGContainer ngp = ar.ngp;
        if (ngp==null)
        {
            throw WeaverException.newBasic("the NGWorkspace must be loaded into the AuthRequest for getWfxmlLink to work");
        }
        return new LicensedURL(
            ar.baseURL + "p/" + ngp.getKey() + "/process.xml",
            ngp.getKey(),
            accessLicense().getId());
    }
    */


    public LicensedURL[] getLicensedParents()
        throws Exception
    {
        DOMFace ppEle = getChild("parentProcesses", DOMFace.class);
        if (ppEle == null)
        {
            return new LicensedURL[0];
        }

        List<DOMFace> vect = ppEle.getChildren("parentProcess", DOMFace.class);
        LicensedURL[] parents = new LicensedURL[vect.size()];
        int i=0;
        for (DOMFace ele : vect) {

            //need to migrate old documents in some cases
            //used to put the URL in the attribute called name
            //so if that exists, convert it over.
            String nameAttr = ele.getAttribute("name");
            if (nameAttr.length()>0) {
                ele.setAttribute("name", null);
                ele.setTextContents(nameAttr);
            }

            parents[i++] = LicensedURL.parseDOMElement(ele);
        }
        return parents;
    }

    public void setLicensedParents(LicensedURL[] parentProcesses)
        throws Exception
    {
        if (parentProcesses == null)
        {
            throw WeaverException.newBasic("null value passed to setLicensedParents, this should never happen");
        }

        DOMFace ppEle = requireChild("parentProcesses", DOMFace.class);

        ppEle.clearVector("parentProcess");

        for (int i=0; i<parentProcesses.length; i++)
        {
            LicensedURL parent = parentProcesses[i];
            DOMFace child = ppEle.createChild("parentProcess", DOMFace.class);
            parent.setDOMElement(child);
        }
    }


    public void addLicensedParent(LicensedURL newParent)
        throws Exception
    {
        if (newParent == null)
        {
            throw WeaverException.newBasic("null value passed to addLicensedParent, this should never happen");
        }

        DOMFace ppEle = requireChild("parentProcesses", DOMFace.class);
        DOMFace child = ppEle.createChild("parentProcess", DOMFace.class);
        newParent.setDOMElement(child);
    }



 


    public List<HistoryRecord> getAllHistory()
            throws Exception
    {
        DOMFace historyContainer = requireChild("history", DOMFace.class);
        List<HistoryRecord> vect = historyContainer.getChildren("event", HistoryRecord.class);
        HistoryRecord.sortByTimeStamp(vect);
        return vect;
    }



    /**
    * the ID is missing
    */
    public HistoryRecord createPartialHistoryRecord()
        throws Exception
    {
        DOMFace historyContainer = requireChild("history", DOMFace.class);
        return historyContainer.createChild("event", HistoryRecord.class);
    }


}
