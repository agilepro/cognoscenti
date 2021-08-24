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

import com.purplehillsbooks.json.JSONObject;

/**
* This is for email messages which are sent to the
* subscriber of a topic
*/
public class OptOutTopicSubscriber extends OptOutAddr {

    String containerID;
    String siteID;
    TopicRecord topic;

    public OptOutTopicSubscriber(AddressListEntry _assignee, String siteKey, String containerKey, TopicRecord tr) {
        super(_assignee);
        if (assignee.getEmail()==null || assignee.getEmail().length()==0) {
            throw new RuntimeException("Somehow got an opt out addressee with a missing email address: "+assignee.getName()+" / "+assignee.getUniversalId() );
        }
        containerID = containerKey;
        siteID = siteKey;
        topic = tr;
    }

    public void writeUnsubscribeLink(AuthRequest clone) throws Exception {
        String emailId = assignee.getEmail();
        if (emailId==null || emailId.length()==0) {
            throw new Exception("There is a problem with this addressee, the email field is blank????");
        }
        NGPageIndex ngpi = clone.getCogInstance().getWSBySiteAndKeyOrFail(siteID, containerID);
        NGWorkspace ngc = ngpi.getWorkspace();

        //if the project no longer exists, then just use the generic response.
        if (ngc==null) {
            super.writeUnsubscribeLink(clone);
            return;
        }

        writeSentToMsg(clone);
        clone.write("\n You have received this message because you are subscribed to the topic <b><a href=\"");
        clone.write(clone.baseURL);
        clone.write("noteZoom"+topic.getId()+".htm\">");
        clone.writeHtml(topic.getSubject());
        clone.write("</a></b> in the '");
        ngc.writeContainerLink(clone, 100);
        clone.write("' workspace.  ");
        clone.write("Visit that topic if you no longer want to be subscribed and receive email for the discussion topic.");
        writeConcludingPart(clone);
    }

    public JSONObject getUnsubscribeJSON(AuthRequest ar) throws Exception {
        JSONObject jo = super.getUnsubscribeJSON(ar);
        NGPageIndex ngpi = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteID, containerID);
        NGWorkspace ngw = ngpi.getWorkspace();
        jo.put("topicName",  topic.getSubject());
        jo.put("topicURL", ar.baseURL + ar.getResourceURL(ngw, "noteZoom"+topic.getId()+".htm"));
        jo.put("wsURL", ar.baseURL + ar.getDefaultURL(ngpi));
        jo.put("wsName", ngpi.containerName);
        return jo;
    }

}
