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

import com.purplehillsbooks.json.JSONObject;

public class SearchResultRecord
{
    private String siteName = "";
    private String workspaceName = "";
    private String workspaceKey = "";
    private String workspaceLink = "";
    private long lastModifiedTime = System.currentTimeMillis();
    private String lastModifiedBy = "";
    private static final String NO_DATA = "";

    //Not sure below two properties should be in this class or need to create another class
    //but for time being added here
    private String noteSubject = "";
    private String noteLink = "";

    public String getNoteLink() {
        return noteLink;
    }
    public void setNoteLink(String noteLink) {
        this.noteLink = noteLink;
    }

    public String getNoteSubject() {
        return noteSubject;
    }
    public void setNoteSubject(String noteSubject) {
        if (noteSubject==null || noteSubject.length()==0) {
            noteSubject = "No Subject";
        }
        this.noteSubject = noteSubject;
    }
    public String getBookName() {
        return siteName;
    }
    public void setBookName(String value) {
        if (value == null || value.length() == 0) {
            value = "No Site Name";
        }
        siteName = value;
    }

    public String getPageKey() {
        return workspaceKey;
    }
    public void setPageKey(String value) {
        if (value == null || value.length() == 0) {
            value = "";
        }
        workspaceKey = value;
    }


    public String getPageName() {
        return workspaceName;
    }
    public void setPageName(String value) {
        if (value == null || value.length() == 0) {
            value = "No Workspace Name";
        }
        workspaceName = value;
    }

    public String getPageLink() {
        return workspaceLink;
    }
    public void setPageLink(String value) {
        if (value == null || value.length() == 0) {
            value = NO_DATA;
        }
        workspaceLink = value;
    }

    public long getLastModifiedTime() {
        return lastModifiedTime;
    }
    public void setLastModifiedTime(long value) {
        lastModifiedTime = value;
    }

    public String getLastModifiedBy() {
        return lastModifiedBy;
    }
    public void setLastModifiedBy(String value) {
        if (value == null || value.length() == 0) {
            value = NO_DATA;
        }
        lastModifiedBy = value;
    }

    public String toString() {
        StringBuffer sb = new StringBuffer();
        sb.append("Page Name = ").append(getPageName()).append("\n");
        sb.append("Page Key = ").append(getPageKey()).append("\n");
        sb.append("Book Name = ").append(getBookName()).append("\n");
        sb.append("Page Link = ").append(getPageLink()).append("\n");
        sb.append("Last By").append(getLastModifiedBy()).append("\n");
        sb.append("Last Modified").append(String.valueOf(getLastModifiedTime())).append("\n");
        return sb.toString();
    }

    public JSONObject getJSON() throws Exception {
        JSONObject jObj = new JSONObject();
        jObj.put("projectName", workspaceName);
        jObj.put("projectKey", workspaceKey);
        jObj.put("projectLink", workspaceLink);
        jObj.put("siteName", siteName);
        jObj.put("noteSubject", noteSubject);
        jObj.put("noteLink", noteLink);
        jObj.put("modTime", lastModifiedTime);
        jObj.put("modUser", lastModifiedBy);
        return jObj;
    }

}