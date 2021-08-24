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

import java.net.URL;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;

import org.w3c.dom.Document;
import org.w3c.dom.Element;
import com.purplehillsbooks.json.JSONObject;

/**
 * A RemoteGoal is a reference to a Goal at a remote site, or even the local
 * site, but managed separately from those projects. The purpose is to allow a
 * user's profile to contain a list of action item references, and allow that user to
 * reorganize them and manipulate them, without messing with the original action item
 * or the way that action item appears in the workspace action item list.
 */
public class RemoteGoal extends DOMFace {

    // this is a temporary (non persistent) marker that can be used
    // to garbage collect left over dangling task references.
    public boolean touchFlag = false;

    public RemoteGoal(Document nDoc, Element nEle, DOMFace p) {
        super(nDoc, nEle, p);
    }

    public String getProjectKey() throws Exception {
        return getAttribute("projKey");
    }

    public void setProjectKey(String newVal) throws Exception {
        setAttribute("projKey", newVal);
    }

    public String getId() throws Exception {
        return getAttribute("id");
    }

    public void setId(String newVal) throws Exception {
        setAttribute("id", newVal);
    }

    /**
     * syncFromTask picks up the common values from the task record
     */
    public void syncFromTask(GoalRecord tr) throws Exception {

        setSynopsis(tr.getSynopsis());
        setDescription(tr.getDescription());
        setDueDate(tr.getDueDate());
        setPriority(tr.getPriority());
        setDuration(tr.getDuration());
        setState(tr.getState());
        setStatus(tr.getStatus());
        setPercentComplete(tr.getPercentComplete());
        setUniversalId(tr.getUniversalId());
    }

    public String getSynopsis() throws Exception {
        return getScalar("synopsis");
    }

    public void setSynopsis(String newVal) throws Exception {
        setScalar("synopsis", newVal);
    }

    public String getDescription() throws Exception {
        return getScalar("description");
    }

    public void setDescription(String newVal) throws Exception {
        if (newVal == null) {
            newVal = "";
        }
        setScalar("description", newVal);
    }

    public long getDueDate() throws Exception {
        return safeConvertLong(getScalar("dueDate"));
    }
    public void setDueDate(long newVal) throws Exception {
        setScalar("dueDate", Long.toString(newVal));
    }

    public long getStartDate() throws Exception {
        return safeConvertLong(getScalar("startDate"));
    }
    public void setStartDate(long newVal) throws Exception {
        setScalar("startDate", Long.toString(newVal));
    }

    public long getEndDate() throws Exception {
        return safeConvertLong(getScalar("endDate"));
    }
    public void setEndDate(long newVal) throws Exception {
        setScalar("endDate", Long.toString(newVal));
    }

    public int getPriority() throws Exception {
        return safeConvertInt(getScalar("priority"));
    }

    public static String getPriorityStr(int priority) throws Exception {
        switch (priority) {
        case 0:
            return BaseRecord.PRIORITY_HIGH_STR;
        case 1:
            return BaseRecord.PRIORITY_MIDIUM__STR;
        case 2:
            return BaseRecord.PRIORITY_LOW__STR;
        default:
        }
        return BaseRecord.PRIORITY_LOW__STR;
    }

    public void setPriority(int newVal) throws Exception {
        setScalar("priority", Integer.toString(newVal));
    }

    public long getDuration() throws Exception {
        String duration = getScalar("duration");
        return safeConvertLong(duration);
    }

    public void setDuration(long newVal) throws Exception {
        setScalar("duration", Long.toString(newVal));
    }

    public int getState() throws Exception {
        String stateVal = getScalar("state");
        return safeConvertInt(stateVal);
    }

    public void setState(int newVal) throws Exception {
        setScalar("state", Integer.toString(newVal));
    }

    public int getRank() throws Exception {
        String rank = getScalar("rank");
        return safeConvertInt(rank);
    }

    public void setRank(int newVal) throws Exception {
        setScalar("rank", Integer.toString(newVal));
    }

    public String getStatus() throws Exception {
        return getScalar("status");
    }

    public void setStatus(String newVal) throws Exception {
        setScalar("status", newVal);
    }

    /**
     * A user is allowed to specify what percentage that the task is complete.
     * This is rolled up into the values of the parent tasks
     */
    public int getPercentComplete() throws Exception {
        String stateVal = getScalar("percent");
        return safeConvertInt(stateVal);
    }

    /**
     * A user is allowed to specify what percentage that the task is complete.
     * The value must be 0 at the lowest, and 100 at the highest.
     */
    public void setPercentComplete(int newVal) throws Exception {
        if (newVal < 0 || newVal > 100) {
            throw new Exception(
                    "Percent complete value must be between 0% and 100%, instead received "
                            + newVal + "%");
        }
        setScalar("percent", Integer.toString(newVal));
    }

    public String getUniversalId() {
        return getScalar("universalId");
    }

    public void setUniversalId(String newId) {
        setScalar("universalId", newId);
    }

    /**
     * This is the UNIQUE key for this set of records, each remote action item has a
     * unique access URL.  Code here assures that you have something non-null
     * to use as a key.
     */
    public String getAccessURL() {
        String au = getScalar("accessUrl");
        if (au==null || au.length()==0) {
            //if none exists, make one up so we have a unique something
            au = "dummy"+IdGenerator.generateKey();
            setAccessURL(au);
        }
        return au;
    }

    public void setAccessURL(String newVal) {
        setScalar("accessUrl", newVal);
    }


    public String getUserInterfaceURL() {
        return getScalar("ui");
    }
    public void setUserInterfaceURL(String newVal) {
        setScalar("ui", newVal);
    }

    public String getProjectName() {
        return getScalar("projectName");
    }
    public void setProjectName(String newVal) {
        setScalar("projectName", newVal);
    }
    public String getSiteName() {
        return getScalar("siteName");
    }
    public void setSiteName(String newVal) {
        setScalar("siteName", newVal);
    }

    public String getProjectAccessURL() {
        return getScalar("projectAccess");
    }
    public void setProjectAccessURL(String newVal) {
        setScalar("projectAccess", newVal);
    }
    public String getSiteAccessURL() {
        return getScalar("siteAccess");
    }
    public void setSiteAccessURL(String newVal) {
        setScalar("siteAccess", newVal);
    }

    public JSONObject getJSONObject() throws Exception {
        JSONObject obj = new JSONObject();
        obj.put("synopsis", getSynopsis());
        obj.put("description", getDescription());
        obj.put("duedate", getDueDate());
        obj.put("priority", getPriority());
        obj.put("duration", getDuration());
        obj.put("state", getState());
        obj.put("status", getStatus());
        obj.put("projectname", getProjectName());
        obj.put("sitename", getSiteName());
        obj.put("percent", getPercentComplete());
        obj.put("universalid", getUniversalId());
        obj.put("ui", getUserInterfaceURL());
        return obj;
    }

    public void setFromJSONObject(JSONObject obj) throws Exception {
        setSynopsis(obj.getString("synopsis"));
        String str = obj.optString("description");
        if (str != null) {
            setDescription(str);
        }
        long duedate = obj.optLong("duedate");
        if (duedate > 0) {
            setDueDate(duedate);
        }
        long startdate = obj.optLong("startdate");
        if (startdate > 0) {
            setStartDate(startdate);
        }
        long enddate = obj.optLong("enddate");
        if (enddate > 0) {
            setEndDate(enddate);
        }
        int duration = obj.optInt("duration");
        if (duration > 0) {
            setDuration(duration);
        }
        int priority = obj.optInt("priority");
        if (priority > 0) {
            setPriority(priority);
        }
        int state = obj.optInt("state");
        if (state > 0) {
            setState(state);
        }
        str = obj.optString("status");
        if (str != null) {
            setStatus(str);
        }
        int percent = obj.optInt("percent");
        if (percent > 0) {
            setPercentComplete(percent);
        }
        str = obj.optString("universalid");
        if (str != null) {
            setUniversalId(str);
        }
        str = obj.optString("goalinfo");
        if (str != null) {
            setAccessURL(str);
        }
        str = obj.optString("ui");
        if (str != null) {
            setUserInterfaceURL(str);
        }
        str = obj.optString("projectname");
        if (str != null) {
            setProjectName(str);
        }
        str = obj.optString("projectinfo");
        if (str != null) {
            setProjectAccessURL(str);
        }
        str = obj.optString("sitename");
        if (str != null) {
            setSiteName(str);
        }
        str = obj.optString("siteinfo");
        if (str != null) {
            setSiteAccessURL(str);
        }
    }

    public void refreshFromRemote() throws Exception {
        try {
            URL url = new URL(getAccessURL());
            JSONObject goalObj = RemoteJSON.getFromRemote(url);
            setFromJSONObject(goalObj);
        }
        catch (Exception e) {
            throw new Exception("Unable to refresh remote action item ("+getSynopsis()+")", e);
        }
    }

    public static void sortTasksByRank(List<RemoteGoal> tasks) {
        Collections.sort(tasks, new TaskRefRankComparator());
    }

    static class TaskRefRankComparator implements Comparator<RemoteGoal> {
        public TaskRefRankComparator() {
        }

        public int compare(RemoteGoal o1, RemoteGoal o2) {
            try {
                int rank1 = o1.getRank();
                int rank2 = o2.getRank();
                if (rank1 == rank2) {
                    return 0;
                }
                if (rank1 < rank2) {
                    return -1;
                }
                return 1;
            }
            catch (Exception e) {
                return 0;
            }
        }
    }

}
