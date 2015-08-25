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


/**
 * @author banerjso
 *
 *
 */
public class ErrorLogDetails extends DOMFace {

    public ErrorLogDetails(Document doc, Element ele, DOMFace p) {
        super(doc, ele, p);
    }

    public void setModified(String userId, long time) {
        setAttribute("modUser", userId);
        setAttribute("modTime", Long.toString(time));
    }
    public long getModTime() {
        return safeConvertLong(getAttribute("modTime"));
    }
    public String getModUser() {
        return getAttribute("modUser");
    }
    public void setErrorNo(String errorNo) {
        setAttribute("errorNo", errorNo);
    }
    public String getErrorNo() {
        return getAttribute("errorNo");
    }

    public void setFileName(String fileName) {
        setScalar("errorfileName", fileName);
    }
    public void setErrorMessage(String errorMessage) {
        setScalar("errorMessage", errorMessage);
    }
    public void setURI(String URI) {
        setScalar("errorURI", URI);
    }
    public void setErrorDetails(String errorDetails) {
        setScalar("errorDetails", errorDetails);
    }

    public void setUserComment(String comments) {
        setScalar("userComments", comments);
    }

    public String getErrorDetails() {
        return getScalar("errorDetails");
    }
    public String getErrorMessage() {
        return getScalar("errorMessage");
    }

    public String getFileName() {
        return getScalar("errorfileName");
    }
    public String getURI() {
        return getScalar("errorURI");
    }

    public String getUserComment() {
        return getScalar("userComments");
    }
}
