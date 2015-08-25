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

public class RoleRequestRecord extends DOMFace {

    public static final long HISTORY_MAX_DAYS = 30;

    public RoleRequestRecord(Document doc, Element upEle, DOMFace p) {
        super(doc, upEle, p);
    }

    public String getRequestId() {
        return getAttribute("id");
    }

    public void setRequestId(String id) {
        setAttribute("id", id);
    }

    public String getState() {
        return getAttribute("state");
    }

    public void setState(String state) {
        setAttribute("state", state);
    }

    public long getCreatedDate() {
        String timeAttrib = getAttribute("createdDate");
        return safeConvertLong(timeAttrib);
    }

    public String getRequestedBy() {
        return getScalar("requestedBy");
    }

    public void setRequestedBy(String requestedBy) {
        setScalar("requestedBy", requestedBy);
    }

    public String getRoleName() {
        return getScalar("roleName");
    }

    public void setRoleName(String roleName) {
        setScalar("roleName", roleName);
    }

    public long getModifiedDate() {
        String timeAttrib = getAttribute("modifiedDate");
        return safeConvertLong(timeAttrib);
    }

    public void setModifiedDate(long modifiedDate) {
        setAttribute("modifiedDate", Long.toString(modifiedDate));
    }

    public String getModifiedBy() {
        return getAttribute("modifiedBy");
    }

    public void setModifiedBy(String modifiedBy) {
        setAttribute("modifiedBy", modifiedBy);
    }

    public boolean isCompleted() {
        return Boolean.parseBoolean(getAttribute("isCompleted"));
    }

    public void setCompleted(boolean isCompleted) {
        setAttribute("isCompleted", String.valueOf(isCompleted));
    }

    public String getRequestDescription() {
        return getScalar("requestDescription");
    }

    public void setRequestDescription(String requestDescription) {
        setScalar("requestDescription", requestDescription);
    }

    public String getResponseDescription() {
        return getScalar("responseDescription");
    }

    public void setResponseDescription(String responseDescription) {
        setScalar("responseDescription", responseDescription);
    }

    public boolean showRecord() throws Exception {
        long oldestLegalRecord = System.currentTimeMillis()-(HISTORY_MAX_DAYS*24*60*60*1000);
        return getModifiedDate()>oldestLegalRecord;
    }
}
