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

import java.util.List;
import org.w3c.dom.Document;
import org.w3c.dom.Element;

/**
* A StatusReport is a record that holds the specification of a status
* report that can be generated at any time.  It will point to a set of
* projects, and will also have a set of tasks to exclude.
*/
public class StatusReport extends DOMFace
{

    public StatusReport(Document nDoc, Element nEle, DOMFace p)
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
        setAttribute("id", newVal);
    }

    public String getName()
        throws Exception
    {
        return getScalar("name");
    }

    public void setName(String newVal)
        throws Exception
    {
        setScalar("name", newVal);
    }

    public String getDescription()
        throws Exception
    {
        return getScalar("desc");
    }

    public void setDescription(String newVal)
        throws Exception
    {
        setScalar("desc", newVal);
    }


    public List<ProjectLink> getProjects() throws Exception {
        return getChildren("projLink", ProjectLink.class);
    }

    public ProjectLink getOrCreateProject(String key) throws Exception {

        //first lets make sure that this project is not already in the set
        for (ProjectLink pl : getProjects()) {
            if (pl.getKey().equals(key)) {
                return pl;
            }
        }

        ProjectLink newPl = createChild("projLink", ProjectLink.class);
        newPl.setKey(key);
        return newPl;
    }

    public void deleteProject(String key) throws Exception {

        ProjectLink found = null;
        for (ProjectLink stat : getProjects()) {
            if (key.equals(stat.getKey())) {
                found = stat;
            }
        }

        if (found != null) {
            removeChild(found);
        }
    }
}
