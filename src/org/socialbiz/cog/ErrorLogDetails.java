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

import com.purplehillsbooks.json.JSONObject;


public class ErrorLogDetails extends DOMFace {

    public ErrorLogDetails(Document doc, Element ele, DOMFace p) {
        super(doc, ele, p);
    }

    public long getModTime() {
        return safeConvertLong(getAttribute("modTime"));
    }
    public String getModUser() {
        return getAttribute("modUser");
    }
    public void setModified(String userId, long time) {
        setAttribute("modUser", userId);
        setAttribute("modTime", Long.toString(time));
    }
    public void setModTime(long time) {
        setAttribute("modTime", Long.toString(time));
    }
    
    public int getErrorNo() {
        return getAttributeInt("errorNo");
    }
    public void setErrorNo(int errorNo) {
        setAttributeInt("errorNo", errorNo);
    }

    public String getFileName() {
        return getScalar("errorfileName");
    }
    public void setFileName(String fileName) {
        setScalar("errorfileName", fileName);
    }
    
    public String getErrorMessage() {
        return getScalar("errorMessage");
    }
    public void setErrorMessage(String errorMessage) {
        setScalar("errorMessage", errorMessage);
    }
    
    public String getURI() {
        return getScalar("errorURI");
    }
    public void setURI(String URI) {
        setScalar("errorURI", URI);
    }
    
    public String getErrorDetails() {
        return getScalar("errorDetails");
    }
    public void setErrorDetails(String errorDetails) {
        setScalar("errorDetails", errorDetails);
    }

    public String getUserComment() {
        return getScalar("userComments");
    }
    public void setUserComment(String comments) {
        setScalar("userComments", comments);
    }



    
    public JSONObject getJSON() throws Exception {
        JSONObject jo = new JSONObject();
        jo.put("errNo",        this.getErrorNo());
        jo.put("message",      this.getErrorMessage());
        jo.put("stackTrace",   this.getErrorDetails());
        jo.put("comment",      this.getUserComment());
        jo.put("modTime",      this.getModTime());
        jo.put("modUser",      this.getModUser());
        jo.put("uri",          this.getURI());
        return jo;
    }
    public void updateFromJSON(JSONObject input) throws Exception {
        if (input.has("stackTrace")) {
            this.setErrorDetails(input.getString("stackTrace"));
        }
        if (input.has("message")) {
            this.setErrorMessage(input.getString("message"));
        }
        updateAttributeLong("modTime", input);
        updateAttributeString("modUser", input);
        if (input.has("uri")) {
            this.setURI(input.getString("uri"));
        }
        if (input.has("comment")) {
            this.setUserComment(input.getString("comment"));
        }
    }
}
