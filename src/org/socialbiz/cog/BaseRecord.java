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

import org.socialbiz.cog.exception.NGException;
import org.w3c.dom.Document;
import org.w3c.dom.Element;

public class BaseRecord extends DOMFace
{

    public final static int STATE_ERROR     = 0;
    public final static int STATE_UNSTARTED = 1;
    public final static int STATE_STARTED   = 2;
    public final static int STATE_ACCEPTED  = 3;
    public final static int STATE_WAITING   = 4;
    public final static int STATE_COMPLETE  = 5;
    public final static int STATE_SKIPPED   = 6;
    public final static int STATE_REVIEW    = 7;    //Never used
    public final static int STATE_FROZEN    = 8;
    public final static int STATE_DELETED   = 9;

    public final static String STATE_ERROR_STR     = "Error";
    public final static String STATE_UNSTARTED_STR = "Unstarted";
    public final static String STATE_STARTED_STR   = "Offered";
    public final static String STATE_ACCEPTED_STR  = "Accepted";
    public final static String STATE_WAITING_STR   = "Waiting";
    public final static String STATE_COMPLETE_STR  = "Completed";
    public final static String STATE_SKIPPED_STR   = "Skipped";
    public final static String STATE_REVIEW_STR    = "Review";     //Never used
    public final static String STATE_FROZEN_STR    = "Frozen";
    public final static String STATE_DELETED_STR   = "Deleted";
    public final static String STATE_UNKNOWN_STR   = "Unknown";

    public final static long MAX_TASK_DURATION  = 365;
    public final static long MAX_TASK_PRIORITY  = 100;

    public final static String PRIORITY_HIGH_STR     = "High";
    public final static String PRIORITY_MIDIUM__STR = "Medium";
    public final static String PRIORITY_LOW__STR   = "Low";

    public BaseRecord(Document nDoc, Element nEle, DOMFace p)
    {
        super(nDoc, nEle, p);
    }

    public String getId()
        throws Exception
    {
        return getAttribute("id");
    }

    public void setId(String newVal)
        throws Exception
    {
        if (newVal.length()!=4)
        {
            throw new NGException("nugen.exception.invalid.id", null);
        }
        for (int i=0; i<4; i++)
        {
            if (newVal.charAt(i)<'0' || newVal.charAt(i)>'9')
            {
                throw new NGException("nugen.exception.invalid.id", null);
            }
        }
        setAttribute("id", newVal);
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

    public String getDescription()
        throws Exception
    {
        return getScalar("description");
    }
    public void setDescription(String newVal)
        throws Exception
    {
        if (newVal == null) {
            newVal = "";
        }
        setScalar("description", newVal);
    }

    public String getActionScripts()
        throws Exception
    {
        return getScalar("actionScripts");
    }
    public void setActionScripts(String newVal)
        throws Exception
    {
        if (newVal == null)
        {
            newVal = "";
        }
        setScalar("actionScripts", newVal);
    }

    public long getDueDate()
        throws Exception
    {
        String endDate = getScalar("dueDate");
        return safeConvertLong(endDate);
    }
    public void setDueDate(long newVal)
        throws Exception
    {
        setScalar("dueDate", Long.toString(newVal));
    }

    public long getStartDate()
        throws Exception
    {
        String startDate = getScalar("startDate");
        return safeConvertLong(startDate);
    }
    public void setStartDate(long newVal)
        throws Exception
    {
        setScalar("startDate", Long.toString(newVal));
    }

    public long getEndDate()
        throws Exception
    {
        String endDate = getScalar("endDate");
        return safeConvertLong(endDate);
    }
    public void setEndDate(long newVal)
        throws Exception
    {
        setScalar("endDate", Long.toString(newVal));
    }

    public int getPriority()
        throws Exception
    {
        String priority = getScalar("priority");
        return safeConvertInt(priority);
    }
    public static String getPriorityStr(int priority)
    throws Exception
    {
        switch (priority)
        {
            case 0:
                return PRIORITY_HIGH_STR;
            case 1:
                return PRIORITY_MIDIUM__STR;
            case 2:
                return PRIORITY_LOW__STR;
            default:
        }
        return PRIORITY_LOW__STR;
    }
    public void setPriority(int newVal)
        throws Exception
    {
        setScalar("priority", Integer.toString(newVal));
    }

    public long getDuration()
        throws Exception
    {
        String duration = getScalar("duration");
        return safeConvertLong(duration);
    }
    public void setDuration(long newVal)
        throws Exception
    {
        setScalar("duration", Long.toString(newVal));
    }

    public static String stateName(int state)
    {
        switch (state)
        {
            case STATE_ERROR:
                return STATE_ERROR_STR;
            case STATE_UNSTARTED:
                return STATE_UNSTARTED_STR;
            case STATE_STARTED:
                return STATE_STARTED_STR;
            case STATE_ACCEPTED:
                return STATE_ACCEPTED_STR;
            case STATE_WAITING:
                return STATE_WAITING_STR;
            case STATE_COMPLETE:
                return STATE_COMPLETE_STR;
            case STATE_SKIPPED:
                return STATE_SKIPPED_STR;
            case STATE_REVIEW:
                return STATE_REVIEW_STR;
            case STATE_FROZEN:
                return STATE_FROZEN_STR;
            case STATE_DELETED:
                return STATE_DELETED_STR;
            default:
        }
        return STATE_UNKNOWN_STR;
    }

/**
* In June 2015 this was changed to the new location and names of the
* image files, and this time it includes the full path from the root
* of the application, requiring migration of code that uses this.
*/
    public static String stateImg(int state) {
        return "assets/goalstate/small"+state+".gif";
    }

    /**
    * Tasks, ParentLinks and Processes can have licenses.
    * The license is automatically created when the object is created.
    * Use this to get a reference to the license record.  Changes
    * to the record are immediately reflected into the document.
    * Older files will have inappropriately formed licenses, and existing
    * must be converted to the appropriate form.
    */
    public LicenseRecord accessLicense()
        throws Exception
    {
        assureLicenseIsCorrectFormat();
        return getChild("license", LicenseRecord.class);
    }



    //TODO: can be removed when oldest data page is after Feb 2010
    private void assureLicenseIsCorrectFormat()
        throws Exception
    {
        //this is special code for converting and upgrading files to a new format
        //this use of DOM Utils should be eliminated after migrating all existing documents.
        Element licEle = DOMUtils.getChildElement(fEle, "license");
        String licId = null;

        if (licEle!=null)
        {
            licId = licEle.getAttribute("id");
            if (licId!=null && licId.length()>0)
            {
                //everything is fine, return the record
                return;
            }
        }

        //if we get here, then we either need to generate a license
        //automatically, or we need to to convert from the old form
        //to the new form.

        if (licEle==null)
        {
            //create a license if it does not already exist
            licEle = createChildElement("license");
        }
        else
        {
            //migration, there was a time when the id was placed in the contents of the
            //tag, instead of in an attribute.  If that attribute is missing, assume that
            //it is because the value is in the content.
            //Remove this migration after the oldest known file is after May 2010
            //
            licId = DOMUtils.textValueOf(licEle, false);
            DOMUtils.removeAllChildren(licEle);
        }

        if (licId==null || licId.length()==0)
        {
            licId = IdGenerator.generateKey();
        }

        licEle.setAttribute("id", licId);

       //end of upgrade code
    }





}
