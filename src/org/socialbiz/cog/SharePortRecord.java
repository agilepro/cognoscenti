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

import org.socialbiz.cog.mail.JSONWrapper;
import org.workcast.json.JSONArray;
import org.workcast.json.JSONObject;

public class SharePortRecord extends JSONWrapper {
    
    public SharePortRecord(JSONObject jo) {
        super(jo);
    }

    public String getPermId() {
        try {
            return kernel.getString("id");
        }
        catch (Exception e) {
            throw new RuntimeException("SharePointRecord does not have an id????");
        }
    }
    public void setPermId(String newId) throws Exception {
        kernel.put("id", newId);
    }

    public JSONObject getMinJSON() throws Exception {
        JSONObject thisPort = new JSONObject();
        extractString(thisPort, "id");
        extractString(thisPort, "name");
        extractString(thisPort, "purpose");
        extractString(thisPort, "message");
        extractBoolean(thisPort, "isActive");
        extractString(thisPort, "filter");
        extractArray(thisPort, "labels");
        extractInt(thisPort, "days");
        extractLong(thisPort, "startTime");
        return thisPort;
    }
    public JSONObject getFullJSON(NGWorkspace ngw) throws Exception {
        JSONObject thisPort = getMinJSON();
        String filter = kernel.optString("filter");
        JSONArray labels = kernel.getJSONArray("labels");
        JSONArray docs = new JSONArray();
        for (AttachmentRecord doc : ngw.getAllAttachments()) {
            if (doc.isDeleted()) {
                //skip all deleted documents
                continue;
            }
            if (filter!=null && filter.length()>0) {
                String docName = doc.getDisplayName();
                String docDesc = doc.getDescription();
                if (!docName.contains(filter) && !docDesc.contains(filter) ) {
                    continue;
                }
            }
            boolean missingLabel = false;
            for (int i=0; i<labels.length(); i++) {
                String thisLabel = labels.getString(i);
                if (!doc.hasLabel(thisLabel)) {
                    missingLabel = true;
                }
            }
            if (missingLabel) {
                continue;
            }
            
            //OK, this is in the set, get the details...
            JSONObject docJSON = doc.getMinJSON(ngw);
            String accessParams = AccessControl.getAccessDocParams(ngw, doc);
            if (accessParams==null) {
                accessParams = "UNKNOWN";
            }
            docJSON.put("access", accessParams);
            docs.put(docJSON);
        }
        thisPort.put("docs", docs);
        
        return thisPort;
    }

    public void updateFromJSON(JSONObject input) throws Exception {
        boolean changed = copyStringToKernel(input, "name");
        changed = copyStringToKernel(input, "purpose") || changed;
        changed = copyStringToKernel(input, "message") || changed;
        changed = copyBooleanToKernel(input, "isActive") || changed;
        changed = copyStringToKernel(input, "filter") || changed;
        changed = copyArrayToKernel(input, "labels") || changed;
        changed = copyIntToKernel(input, "days") || changed;
        if (changed) {
            kernel.put("startTime", System.currentTimeMillis());
        }
    }

}
