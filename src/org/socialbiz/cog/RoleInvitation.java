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

import java.util.ArrayList;
import java.util.Date;

import org.socialbiz.cog.api.LightweightAuthServlet;
import org.socialbiz.cog.mail.JSONWrapper;
import org.socialbiz.cog.mail.MailFile;
import org.socialbiz.cog.mail.ScheduledNotification;

import com.purplehillsbooks.json.JSONObject;

public class RoleInvitation extends JSONWrapper {

    public static String STATUS_NEW     = "New";
    public static String STATUS_INVITED = "Invited";
    public static String STATUS_JOINED  = "Joined";
    public static String STATUS_FAILED  = "Failed";


    public RoleInvitation(JSONObject jo) throws Exception {
        super(jo);
        if (!kernel.has("status")) {
            kernel.put("status", STATUS_NEW);
        }
    }

    public String getEmail() throws Exception {
        return kernel.getString("email");
    }
    public String getStatus() throws Exception {
        return kernel.optString("status", STATUS_NEW);
    }
    public String getRole() throws Exception {
        return kernel.getString("role");
    }
    public String getName() throws Exception {
        return kernel.getString("name");
    }
    public void setName(String newName) throws Exception {
        kernel.put("name", newName);
    }

    public boolean isJoined() throws Exception {
        return STATUS_JOINED.equals(getStatus());
    }

    public void markJoined() throws Exception {
        kernel.put("status", STATUS_JOINED);
        kernel.put("joinTime", System.currentTimeMillis());
    }
    public void resendInvite() throws Exception {
        kernel.put("status", STATUS_NEW);
    }

    public JSONObject getInvitationJSON() throws Exception {
        JSONObject thisPort = new JSONObject();
        extractString(thisPort, "email");  //the key
        extractString(thisPort, "role");
        extractString(thisPort, "name");
        extractString(thisPort, "msg");
        extractString(thisPort, "status");
        extractLong(thisPort, "timestamp");
        extractLong(thisPort, "joinTime");
        return thisPort;
    }


    public boolean updateFromJSON(JSONObject input) throws Exception {
        //email is never updated because that is the key field
        boolean changed = copyStringToKernel(input, "role");
        changed = copyStringToKernel(input, "name") || changed;
        changed = copyStringToKernel(input, "msg") || changed;
        if (changed) {
            kernel.put("timestamp", System.currentTimeMillis());
        }
        return changed;
    }

    public void sendEmail(AuthRequest ar) throws Exception {

        if (!STATUS_NEW.equals(kernel.getString("status"))) {
            throw new Exception("Program Logic Error: send is being called when the invite is not in NEW status");
        }

        //var msg1 = {userId:item,msg:$scope.message,return:$scope.retAddr};
        String msg = null;
        if (kernel.has("msg")) {
            msg = kernel.getString("msg");
        }
        else {
            msg = "Hello,\n\nYou have been invited to"
                +" participate in a workspace on Weaver."
                +"\n\nThe links below will make registration quick and easy, and"
                +" after that you will be able to"
                +" participate directly with the others through the site.";
        }
        String returnUrl = ar.baseURL + ar.getResourceURL(ar.ngp, "frontPage.htm");

        JSONObject jo = new JSONObject();
        jo.put("userId", kernel.getString("email"));
        jo.put("msg", msg);
        jo.put("return", returnUrl);

        JSONObject res = LightweightAuthServlet.postToTrustedProvider("?openid.mode=apiSendInvite", jo);
        if (res.has("result") && "ok".equals(res.getString("result"))) {
            kernel.put("status", STATUS_INVITED);
        }
        else {
            kernel.put("status", STATUS_FAILED);
            System.out.println("ROLE INVITATION FAILED: "+res.toString());
        }
    }

    public void gatherUnsentScheduledNotification(NGWorkspace ngp, ArrayList<ScheduledNotification> resList, long timeout) throws Exception {
        if ("New".equals(this.getStatus())) {
            RIScheduledNotification sn = new RIScheduledNotification(this);
            if (sn.needsSendingBefore(timeout)) {
                resList.add(sn);
            }
        }
    }


    private class RIScheduledNotification implements ScheduledNotification {
        RoleInvitation ri;

        public RIScheduledNotification( RoleInvitation _ri) {
            ri = _ri;
        }
        @Override
        public boolean needsSendingBefore(long timeout) throws Exception {
            return ("New".equals(ri.getStatus()));
        }

        @Override
        public long futureTimeToSend() throws Exception {
            if (!"New".equals(ri.getStatus())) {
                return -1;
            }
            return System.currentTimeMillis()-100000;   //one hundred seconds ago
        }

        @Override
        public void sendIt(AuthRequest ar, MailFile mailFile) throws Exception {
            if ("New".equals(ri.getStatus())) {
                System.out.println("ROLE INVITATION: "+SectionUtil.currentTimeString()+" to "+ri.getEmail()+" sending.");
                ri.sendEmail(ar);
            }
        }

        @Override
        public String selfDescription() throws Exception {
            return "Role Invitation to "+ri.getEmail();
        }

    }

}
