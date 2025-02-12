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

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

import org.w3c.dom.Document;
import org.w3c.dom.Element;
import com.purplehillsbooks.json.JSONObject;
import com.purplehillsbooks.weaver.exception.WeaverException;

public class DecisionRecord extends DOMFace {

    //these codes match those for History record
    public final static int SOURCE_TYPE_TOPIC        = 4;
    public final static int SOURCE_TYPE_MEETING      = 7;
    public final static int SOURCE_TYPE_DOCUMENT     = 8;

    public DecisionRecord(Document nDoc, Element nEle, DOMFace p) {
        super(nDoc, nEle, p);
    }

    public int getNumber() throws Exception {
        return getAttributeInt("num");
    }
    public void setNumber(int newVal) throws Exception {
        setAttributeInt("num", newVal);
    }

    public String getDecision() throws Exception {
        return getScalar("decision");
    }
    public void setDecision(String newVal) throws Exception {
        setScalar("decision", newVal);
    }


    public long getTimestamp() throws Exception {
        return getAttributeLong("timestamp");
    }
    public void setTimestamp(long newVal) throws Exception {
        setAttributeLong("timestamp", newVal);
    }

    //Where did this decision come from???
    public int getSourceType() throws Exception {
        return getAttributeInt("sourceType");
    }
    public void setSourceType(int newVal) throws Exception {
        setAttributeInt("sourceType", newVal);
    }
    public String getSourceId() throws Exception {
        return getAttribute("sourceId");
    }
    public void setSourceId(String newVal) throws Exception {
        setAttribute("sourceId", newVal);
    }
    public long getSourceCmt() throws Exception {
        return getAttributeLong("sourceCmt");
    }
    public void setSourceCmt(long newVal) throws Exception {
        setAttributeLong("sourceCmt", newVal);
    }

    public String getSourceUrl(AuthRequest ar, NGWorkspace ngw) throws Exception {
        return ar.getResourceURL(ngw, "CommentZoom.htm?cid="+getSourceCmt());
    }


    /**
     * the universal id is a globally unique ID for this decision, composed of the
     * id for the server, the workspace, and the action item. This is set at the point
     * where the action item is created and remains with the note as it is carried
     * around the system as long as it is moved as a clone from a workspace to a
     * clone of a workspace. If it is copied or moved to another workspace for any
     * other reason, then the universal ID should be reset.
     */
    public String getUniversalId() throws Exception {
        return getScalar("universalid");
    }

    public void setUniversalId(String newID) throws Exception {
        setScalar("universalid", newID);
    }


    /**
     * get the labels on a document -- only labels valid in the workspace,
     * and no duplicates
     */
    public List<NGLabel> getLabels(NGWorkspace ngw) throws Exception {
        List<NGLabel> res = new ArrayList<NGLabel>();
        for (String name : getVector("labels")) {
            NGLabel aLabel = ngw.getLabelRecordOrNull(name);
            if (aLabel!=null) {
                if (!res.contains(aLabel)) {
                    res.add(aLabel);
                }
            }
        }
        return res;
    }

    /**
     * set the list of labels on a document
     */
    public void setLabels(List<NGLabel> values) throws Exception {
        List<String> labelNames = new ArrayList<String>();
        for (NGLabel aLable : values) {
            labelNames.add(aLable.getName());
        }
        //Since this is a 'set' type vector, always sort them so that they are
        //stored in a consistent way ... so files are more easily compared
        Collections.sort(labelNames);
        setVector("labels", labelNames);
    }


    public JSONObject getJSON4Decision(NGWorkspace ngw, AuthRequest ar) throws Exception {
        JSONObject thisDecision = new JSONObject();
        thisDecision.put("universalid", getUniversalId());
        thisDecision.put("num", getNumber());
        extractAttributeLong(thisDecision, "timestamp");
        JSONObject labelMap = new JSONObject();
        for (NGLabel lRec : getLabels(ngw) ) {
            labelMap.put(lRec.getName(), true);
        }
        extractScalarString(thisDecision, "decision");
        thisDecision.put("labelMap",  labelMap);
        thisDecision.put("sourceUrl", getSourceUrl(ar, ngw));
        extractAttributeString(thisDecision, "sourceId");
        extractAttributeInt(thisDecision, "sourceType");
        extractAttributeLong(thisDecision, "sourceCmt");
        extractAttributeLong(thisDecision, "reviewDate");
        return thisDecision;
    }

    public void updateDecisionFromJSON(JSONObject decisionObj, NGWorkspace ngw, AuthRequest ar) throws Exception {
        String universalid = decisionObj.getString("universalid");
        if (!universalid.equals(getUniversalId())) {
            //just checking, this should never happen
            throw WeaverException.newBasic("Error trying to update the record for a decision with UID (%s) with post from decision with UID %s)",
                   getUniversalId(), universalid);
        }
        
        // Two ways to update, either with a decisionMerge object which contains a new 
        // and old value,  or by setting the decision value outright.
        // Only one of these should be used generally.
        mergeIfPresent(decisionObj, "decision");

        updateAttributeLong("timestamp", decisionObj);
        if (decisionObj.has("labelMap")) {
            JSONObject labelMap = decisionObj.getJSONObject("labelMap");
            List<NGLabel> selectedLabels = new ArrayList<NGLabel>();
            for (NGLabel stdLabel : ngw.getAllLabels()) {
                String labelName = stdLabel.getName();
                if (labelMap.optBoolean(labelName)) {
                    selectedLabels.add(stdLabel);
                }
            }
            setLabels(selectedLabels);
        }

        updateAttributeInt("sourceType", decisionObj);
        updateAttributeString("sourceId", decisionObj);
        updateAttributeLong("sourceCmt", decisionObj);
        updateAttributeLong("reviewDate", decisionObj);

    }

}
