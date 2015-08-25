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

package org.socialbiz.cog.spring;

import java.io.IOException;
import java.io.PrintWriter;
import java.io.StringWriter;
import java.io.Writer;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Vector;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.socialbiz.cog.AccessControl;
import org.socialbiz.cog.AddressListEntry;
import org.socialbiz.cog.AttachmentRecord;
import org.socialbiz.cog.AuthDummy;
import org.socialbiz.cog.AuthRequest;
import org.socialbiz.cog.EmailSender;
import org.socialbiz.cog.HistoryRecord;
import org.socialbiz.cog.NGContainer;
import org.socialbiz.cog.NGRole;
import org.socialbiz.cog.NoteRecord;
import org.socialbiz.cog.OptOutAddr;
import org.socialbiz.cog.RoleRequestRecord;
import org.socialbiz.cog.SectionUtil;
import org.socialbiz.cog.UserPage;
import org.socialbiz.cog.UserProfile;
import org.socialbiz.cog.exception.NGException;
import org.workcast.json.JSONObject;

public class NGWebUtils {

    public static void nicePrintDate(Writer out, long timestamp)
            throws Exception {
        SectionUtil.nicePrintDate(out, timestamp);
    }

    public static String getNicePrintDate(long timestamp) throws Exception {
        StringWriter out = new StringWriter();
        nicePrintDate(out, timestamp);
        return out.toString();
    }

    public static void writePadded(Writer out, int desiredLen, String value)
            throws Exception {
        int len = desiredLen - value.length();
        while (len > 0) {
            len--;
            out.write(" ");
        }
        out.write(value);
    }

    public static int getNotesCount(NGContainer container, AuthRequest ar,
            int displayLevel) throws Exception {
        int count = 0;
        List<NoteRecord> notes = container.getVisibleNotes(ar, displayLevel);
        if (notes != null) {
            count = notes.size();
        }
        return count;
    }

    public static int getDeletedNotesCount(NGContainer container, AuthRequest ar)
            throws Exception {
        List<NoteRecord> notes = container.getDeletedNotes(ar);
        if (notes == null) {
            return 0;
        }
        return notes.size();
    }

    public static int getDraftNotesCount(NGContainer container, AuthRequest ar)
            throws Exception {
        int count = 0;
        List<NoteRecord> notes = container.getDraftNotes(ar);
        if (notes != null) {
            count = notes.size();
        }
        return count;
    }

    public static int getDocumentCount(NGContainer ngc, int displayLevel)
            throws Exception {
        int noOfDocs = 0;
        for (AttachmentRecord attachment : ngc.getAllAttachments()) {
            if (attachment.getVisibility() != displayLevel
                    || attachment.isDeleted()) {
                continue;
            }
            noOfDocs++;
        }
        return noOfDocs;
    }

    public static int getDeletedDocumentCount(NGContainer ngc) throws Exception {
        int noOfDocs = 0;
        for (AttachmentRecord attachment : ngc.getAllAttachments()) {
            if (!attachment.isDeleted()) {
                continue;
            }
            noOfDocs++;
        }
        return noOfDocs;
    }



    public static void sendRoleRequestEmail(AuthRequest ar,
            RoleRequestRecord roleRequestRecord, NGContainer container)
            throws Exception {
        UserProfile up = ar.getUserProfile();
        if (up == null) {
            throw new Exception(
                    "Program Logic Error: only logged in users can request to join a role, and got such a request when there appears to be nobody logged in");
        }

        //This is a magic URL that contains a magic token that will allow people
        //who are not logged in, to approve this request.
        String resourceURL = ar.getResourceURL(container, "approveOrRejectRoleReqThroughMail.htm")
            +"?requestId="  + roleRequestRecord.getRequestId()
            + "&isAccessThroughEmail=yes&"
            + AccessControl.getAccessRoleRequestParams(container, roleRequestRecord);

        Vector<OptOutAddr> initialList = new Vector<OptOutAddr>();
        OptOutAddr.appendUsersFromRole(container, "Administrators", initialList);
        OptOutAddr.appendUsersFromRole(container, "Members", initialList);

        // filter out users that who have no profile and have never logged in.
        // Only send this request to real users, not just email addresses
        Vector<OptOutAddr> sendTo = new Vector<OptOutAddr>();
        for (OptOutAddr ooa : initialList) {
            if (ooa.isUserWithProfile()) {
                sendTo.add(ooa);
            }
        }

        if (sendTo.size() == 0) {
            throw new Exception(
                    "sendRoleRequestEmail has been called when there are no valid Members or Administrators of the project to send the email to.");
        }

        String baseURL = ar.baseURL;

        StringWriter bodyWriter = new StringWriter();
        AuthRequest clone = new AuthDummy(ar.getUserProfile(), bodyWriter, ar.getCogInstance());
        clone.setNewUI(true);
        clone.retPath = baseURL;
        clone.write("<html><body>\n");
        clone.write("<p>");
        ar.getUserProfile().writeLink(clone);
        clone.write(" has requested to join the role <b>'");
        clone.writeHtml(roleRequestRecord.getRoleName());
        clone.write("'</b> in the project '");
        container.writeContainerLink(clone, 100);
        clone.write("'.   <br/>Comment: <i>");
        clone.writeHtml(roleRequestRecord.getRequestDescription());
        clone.write("</i></p>\n");

        clone.write("<p><a href=\"");
        clone.write(baseURL);
        clone.write(resourceURL);
        clone.write("\">Click here to Accept/Deny</a></p>");

        clone.write("<p>You can accept or deny this request because you are either an ");
        clone.write("Administrator or Member of this project.   If you are not responsible for ");
        clone.write("approving/rejecting this request  you can safely ignore and delete this message.</p>");
        clone.write("\n<hr/>\n");
        clone.write("</body></html>");

        EmailSender.queueEmailNGC(sendTo, container,
                "Role Requested by " + ar.getBestUserId(),
                bodyWriter.toString(), null, new Vector<String>(), ar.getCogInstance());

    }


    public static void writeLocalizedHistoryMessage(HistoryRecord hr,
            NGContainer ngp, AuthRequest ar) throws Exception {
        hr.writeLocalizedHistoryMessage(ngp, ar);
    }

    public static String getExceptionMessageForAjaxRequest(Exception e,
            Locale locale) throws Exception {
        StringWriter stackOutput = new StringWriter();
        e.printStackTrace(new PrintWriter(stackOutput));
        return getJSONMessage(Constant.FAILURE,
                NGException.getFullMessage(e, locale), stackOutput.toString());
    }

    public static String getJSONMessage(String msgType, String message,
            String comments) throws Exception {
        JSONObject jsonMsg = new JSONObject();
        jsonMsg.put(Constant.MSG_TYPE, msgType);
        jsonMsg.put(Constant.MESSAGE, message);
        jsonMsg.put(Constant.COMMENTS, comments);
        String res = jsonMsg.toString();
        return res;
    }

    public static void sendResponse(AuthRequest ar, String responseMessage)
            throws IOException {
        ar.resp.setContentType("text/xml; charset=UTF-8");
        ar.resp.setHeader("Cache-Control", "no-cache");
        Writer writer = ar.resp.getWriter();
        writer.write(responseMessage);
        writer.close();
    }


    public static AuthRequest getAuthRequest(HttpServletRequest request,
            HttpServletResponse response, String assertLoggedInMsg)
            throws Exception {

        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        ar.assertLoggedIn(assertLoggedInMsg);
        return ar;
    }

    public static List<AttachmentRecord> getSelectedAttachments(AuthRequest ar,
            NGContainer ngp) throws Exception {
        List<AttachmentRecord> res = new ArrayList<AttachmentRecord>();
        for (AttachmentRecord att : ngp.getAllAttachments()) {
            String paramId = "attach" + att.getId();
            if (ar.defParam(paramId, null) != null) {
                res.add(att);
            }
        }
        return res;
    }

    public static List<AddressListEntry> getExistingContacts(UserPage up)
            throws Exception {
        List<AddressListEntry> existingContacts = null;
        NGRole aRole = up.getRole("Contacts");
        if (aRole != null) {
            existingContacts = aRole.getExpandedPlayers(up);
        } else {
            existingContacts = new ArrayList<AddressListEntry>();
        }
        return existingContacts;
    }

    public static void addMembersInContacts(AuthRequest ar,
            List<AddressListEntry> contactList) throws Exception {
        UserPage up = ar.getUserPage();
        if (contactList != null) {
            NGRole role = up.getContactsRole();
            for (AddressListEntry ale : contactList) {
                role.addPlayerIfNotPresent(ale);
            }
            up.saveFile(ar, "Added contacts");
        }
    }

    public static void updateUserContactAndSaveUserPage(AuthRequest ar,
            String op, String emailIds) throws Exception {
        int eventType = 0;
        UserPage up = ar.getUserPage();
        if (emailIds.length() > 0) {
            if (op.equals("Remove")) {
                NGRole role = up.getContactsRole();
                AddressListEntry ale = AddressListEntry
                        .newEntryFromStorage(emailIds);
                eventType = HistoryRecord.EVENT_PLAYER_REMOVED;
                role.removePlayer(ale);
                up.saveFile(ar, "removed user " + emailIds + " from role "
                        + role.getName());
            } else if (op.equals("Add")) {
                eventType = HistoryRecord.EVENT_PLAYER_ADDED;

                Vector<AddressListEntry> contactList = AddressListEntry
                        .parseEmailList(emailIds);
                NGWebUtils.addMembersInContacts(ar, contactList);
            }
        }
        HistoryRecord.createHistoryRecord(up, "Updating contacts",
                HistoryRecord.CONTEXT_TYPE_ROLE, 0, eventType, ar, "");
    }

}
