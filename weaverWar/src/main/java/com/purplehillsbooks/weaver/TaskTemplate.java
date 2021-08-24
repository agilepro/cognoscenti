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

import com.purplehillsbooks.weaver.exception.NGException;
import org.w3c.dom.Document;
import org.w3c.dom.Element;

/**
* This is a container for a task, a task template
*/
public class TaskTemplate extends DOMFace
{

    public TaskTemplate(Document definingDoc, Element definingElement, DOMFace p)
        throws Exception
    {
        super(definingDoc, definingElement, p);
    }

    public void readFromTask(GoalRecord tr)
        throws Exception
    {
        setSynopsis(tr.getSynopsis());
        setDescription(tr.getDescription());
        setActionScripts(tr.getActionScripts());
        setPriority(tr.getPriority());
        setDuration(tr.getDuration());
        setAssignee(tr.getAssigneeCommaSeparatedList());
        setCreator(tr.getCreator());
    }

    public void sendToTask(GoalRecord tr)
        throws Exception
    {
        tr.setSynopsis(getSynopsis());
        tr.setDescription(getDescription());
        tr.setActionScripts(getActionScripts());
        tr.setPriority(getPriority());
        tr.setDuration(getDuration());
        tr.setAssigneeCommaSeparatedList(getAssignee());
        tr.setCreator(tr.getCreator());
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
            throw new NGException("nugen.exception.invalid.id",null);
        }
        for (int i=0; i<4; i++)
        {
            if (newVal.charAt(i)<'0' || newVal.charAt(i)>'9')
            {
                throw new NGException("nugen.exception.invalid.id",null);
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

    public int getPriority()
        throws Exception
    {
        String priority = getScalar("priority");
        return safeConvertInt(priority);
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


    public String getAssignee() throws Exception {
        return getScalar("assignee");
    }
    public void setAssignee(String newVal) throws Exception {
        setScalar("assignee", newVal);
    }

    public void setCreator(String newVal)
    throws Exception
    {
    setScalar("creator", newVal);
    }
    public String getCreator()
    throws Exception
    {
        return getScalar("creator");
    }


}
