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

public class FileRecord extends DOMFace
{
    //TODO: remove this redundant element
    private NGSection section = null;

    public FileRecord(Document doc, Element definingElement,
            DOMFace containingSection)
    {
        super(doc, definingElement, containingSection);
        section = (NGSection) containingSection;
    }

    public String getId() {
        return checkAndReturnAttributeValue("id");
    }

    public void setId(String id) {
        setAttribute("id", id);
    }

    public String sectionName() throws Exception {
        return section.getName();
    }

    /**
     * The display name default to the file name.
     */
    public String getDisplayName() {
        return getAttribute("name");
    }

    public void setName(String fileName) {
        setAttribute("name", fileName);
    }

    public String getResourceId() {
        return getAttribute("rid");
    }

    public void setResourceId(String rid) {
        setAttribute("rid", rid);
    }

    public long getFileTime() {
        return safeConvertLong(checkAndReturnAttributeValue("ftime"));
    }

    public void setFileTime(long ftime) {
        setAttribute("ftime", Long.toString(ftime));
    }

    public long getFileStatus() {
        return safeConvertLong(checkAndReturnAttributeValue("fstatus"));
    }

    public void setFileStatus(long fstatus) {
        setAttribute("fstatus", Long.toString(fstatus));
    }

    public boolean equivalentName(String name) {
        if (name == null) {
            return false;
        }
        String dName = getDisplayName();
        return name.equalsIgnoreCase(dName);
    }

    public String getURI() {
        return checkAndReturnAttributeValue("file");
    }

    public void setURI(String newURI) {
        setAttribute("file", newURI);
    }

    public String getModifiedBy() {
        return checkAndReturnAttributeValue("modifiedBy");
    }

    public void setModifiedBy(String modifiedBy) {
        setAttribute("modifiedBy", modifiedBy);
    }

    public long getModifiedDate() {
        return safeConvertLong(checkAndReturnAttributeValue("modifiedDate"));
    }

    public void setModifiedDate(long modifiedDate) {
        setAttribute("modifiedDate", Long.toString(modifiedDate));
    }

    public long getFileSize() {
        return safeConvertLong(checkAndReturnAttributeValue("fileSize"));
    }

    public void setFileSize(long fileSize) {
        setAttribute("fileSize", Long.toString(fileSize));
    }

    private String checkAndReturnAttributeValue(String attrName) {
        String val = getAttribute(attrName);
        if (val == null) {
            return "";
        }
        return val;
    }

    public void createHistory(AuthRequest ar, NGPage ngp, int event,
            String comment) throws Exception {
        HistoryRecord.createHistoryRecord(ngp, getId(),
                HistoryRecord.CONTEXT_TYPE_DOCUMENT, getModifiedDate(), event,
                ar, comment);
    }
}
