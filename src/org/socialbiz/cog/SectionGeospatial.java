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
import java.io.Writer;
import java.util.Vector;
import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.socialbiz.cog.exception.ProgramLogicError;

public class SectionGeospatial extends SectionUtil implements SectionFormat
{
    public SectionGeospatial()
    {
    }

    public String getName()
    {
        return "Geospatial";
    }

    public void findLinks(Vector<String> v, NGSection section) throws Exception
    {
        //not implemented yet, no links from this section found
        throw new ProgramLogicError("Geospatial not supported");
    }


    public void writePlainText(NGSection section, Writer out) throws Exception
    {
        throw new ProgramLogicError("Geospatial not supported");
    }

    public void findIDs(Vector<String> v, NGSection sec) throws Exception
    {
        throw new ProgramLogicError("Geospatial not supported");
    }

    public void addGeoData(AuthRequest ar, NGSection section, Element geospatial)
    {
        DOMUtils.removeAllNamedChild(section.getElement(), "geospatial");
        Node tempNode = section.getDocument().importNode(geospatial, true);
        section.getElement().appendChild(tempNode);
    }

}
