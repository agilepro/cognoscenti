package org.socialbiz.cog;

import java.io.File;
import java.util.ArrayList;
import java.util.List;

import org.socialbiz.cog.mail.EmailSender;
import org.workcast.json.JSONObject;
import org.workcast.streams.MemFile;

public class HistoricActions {

    private AuthRequest ar;

    /**
     * Actions that create history and/or send
     * email messages, are consolidated into this layer.
     */
    public HistoricActions(AuthRequest _ar) throws Exception {
        ar = _ar;
        ar.assertLoggedIn("Action on this resource allowed only when you are logged in.");
    }

    /**
     * When a user wants to create a new site, a request object must be created, and
     * a notification sent to the administrator.  This function performs all that
     *
     * @param siteId is the proposed site id
     * @param siteName
     * @param siteDescription
     * @return
     * @throws Exception
     */
    public SiteRequest createNewSiteRequest(String siteId, String siteName,
            String siteDescription) throws Exception {
        SiteRequest accountDetails = SiteReqFile.createNewSiteRequest(siteId,
            siteName, siteDescription, ar);

        sendSiteRequestEmail( ar,  accountDetails);
        return accountDetails;
    }

    /**
     * Do all the things necessary for creating and recording the creation of a site
     * but don't send email, and don't wait for the administrator to approve
     * the new site.
     */
    public NGBook createNewSiteImmediately(String siteId, String siteName,
            String siteDescription) throws Exception {
        SiteRequest immediateRequest = SiteReqFile.createNewSiteRequest(siteId,
            siteName, siteDescription, ar);
        return completeSiteRequest(immediateRequest, true,
                "Granted immediately without administrator involvement");
    }

    private static void sendSiteRequestEmail(AuthRequest ar,
            SiteRequest accountDetails) throws Exception {
        MemFile body = new MemFile();
        UserProfile up = UserManager.getSuperAdmin(ar);
        AuthRequest clone = new AuthDummy(ar.getUserProfile(), body.getWriter(), ar.getCogInstance());
        clone.setNewUI(true);
        clone.retPath = ar.baseURL;
        clone.write("<html><body>\n");
        clone.write("<table>\n<tr><td>Purpose: &nbsp;</td><td>New Site Request</td></tr>");
        clone.write("\n<tr><td>Site Name: &nbsp;</td><td>");
        clone.writeHtml(accountDetails.getName());
        clone.write("</td></tr>");
        clone.write("\n<tr><td>Description: &nbsp;</td><td>");
        clone.writeHtml(accountDetails.getDescription());
        clone.write("</td></tr>");
        clone.write("\n<tr><td>Requested By: &nbsp;</td><td>");
        ar.getUserProfile().writeLink(clone);
        clone.write("</td></tr>");
        clone.write("\n<tr><td>Action: &nbsp;</td><td>");
        clone.write("<a href=\"");
        clone.write(ar.baseURL);
        clone.write("v/");
        clone.write(up.getKey());
        clone.write("/requestedAccounts.htm\">Click here to review the requested sites list</a>");
        clone.write("</td></tr>");
        clone.write("</table>\n");
        clone.write("<p>Being a <b>Super Admin</b> of the Weaver console, you have rights to accept or deny this request.</p>");
        clone.write("</body></html>");
        clone.flush();

        EmailSender.generalMailToList(UserManager.getSuperAdminMailList(ar), ar.getBestUserId(),
                "Site Approval for " + ar.getBestUserId(),
                body.toString(), ar.getCogInstance());
    }

    /**
     * When a user has requested a site, the administrator is involved to approve or deny
     * the site.  This method accomplishes that, and it sends an email to the originating
     * user to let them know what has transpired.
     * @param siteRequest should be looked up and passed in
     * @param granted a boolean true=granted,  false=denied
     * @param adminComment = the comment from the administrator about why to do it
     * @return the site created, or null if denied
     */
    public NGBook completeSiteRequest(SiteRequest siteRequest, boolean granted, String adminComment) throws Exception {
        siteRequest.setAdminComment(adminComment);
        AddressListEntry ale = new AddressListEntry(siteRequest.getUniversalId());
        NGBook ngb = null;
        if (granted) {
            //Create new Site
            ngb = NGBook.createNewSite(siteRequest.getSiteId(), siteRequest.getName(), ar.getCogInstance());
            ngb.setKey(siteRequest.getSiteId());
            ngb.setDescription(siteRequest.getDescription());
            ngb.getPrimaryRole().addPlayer(ale);
            ngb.getSecondaryRole().addPlayer(ale);
            ngb.saveFile(ar, "New Site created");
            ar.getCogInstance().makeIndex(ngb);

            siteRequest.setStatus("Granted");
            ar.getSuperAdminLogFile().createAdminEvent(ngb.getKey(), ar.nowTime,
                ar.getBestUserId(), AdminEvent.SITE_CREATED);
        }
        else {
            siteRequest.setStatus("Denied");
            ar.getSuperAdminLogFile().createAdminEvent(siteRequest.getRequestId(), ar.nowTime,
                ar.getBestUserId(), AdminEvent.SITE_DENIED);
        }
        siteResolutionEmail(ale.getUserProfile(), siteRequest);
        SiteReqFile.saveAll();
        return ngb;
    }

    private void siteResolutionEmail(UserProfile owner, SiteRequest siteRequest) throws Exception {
        MemFile body = new MemFile();
        AuthRequest clone = new AuthDummy(ar.getUserProfile(), body.getWriter(), ar.getCogInstance());
        clone.setNewUI(true);
        clone.retPath = ar.baseURL;
        clone.write("<html><body>\n");
        clone.write("<p>This message was sent automatically from Weaver to keep you up ");
        clone.write("to date on the status of your Site.</p>");
        clone.write("\n<table>");
        clone.write("\n<tr><td>Purpose: &nbsp;</td><td>You requested a new account</td></tr>\n");

        if (ar.getUserProfile() != null) {
            clone.write("<tr><td>Updated by: &nbsp;</td><td>");
            clone.getUserProfile().writeLink(clone);
        }

        clone.write("</td></tr>");
        clone.write("\n<tr><td>Result: &nbsp;</td><td>");
        clone.writeHtml(siteRequest.getStatus());
        clone.write("</td></tr>");
        clone.write("\n<tr><td>Comment: &nbsp;</td><td>");
        clone.writeHtml(siteRequest.getAdminComment());
        clone.write("</td></tr>");
        clone.write("\n<tr><td>Site Name: &nbsp;</td><td><a href=\"");
        clone.write(ar.baseURL);
        clone.write("v/approveAccountThroughMail.htm?requestId=");
        clone.write(siteRequest.getRequestId());
        clone.write("\">");
        clone.writeHtml(siteRequest.getName());
        clone.write("</a></td></tr>");
        clone.write("\n<tr><td>Description: &nbsp;</td><td>");
        clone.writeHtml(siteRequest.getDescription());
        clone.write("</td></tr>");
        clone.write("\n<tr><td>Requested by: &nbsp; </td><td>");
        owner.writeLink(clone);
        clone.write("</td></tr>\n</table>\n</body></html>");

        List<OptOutAddr> v = new ArrayList<OptOutAddr>();
        v.add(new OptOutIndividualRequest(new AddressListEntry(owner)));
        clone.flush();

        EmailSender.generalMailToList(v, ar.getBestUserId(), "Site Request Resolution for " + owner.getName(),
                body.toString(), ar.getCogInstance());
    }

    /**
     * When adding a list of people to be players of a role, this method will do that
     * and will also email each one letting them know.
     * @param memberList is a list of names in standard email format.
     * @param sendEmail set to true if you want email sent, false if not.
     */
    public void addMembersToRole(NGContainer ngc, NGRole role, String memberList, boolean sendEmail) throws Exception {
        List<AddressListEntry> emailList = AddressListEntry.parseEmailList(memberList);
        for (AddressListEntry ale : emailList) {
            addMemberToRole(ngc, role, ale, sendEmail);
        }
    }

    public void addMemberToRole(NGContainer ngc, NGRole role, AddressListEntry ale, boolean sendEmail) throws Exception {
        RoleRequestRecord roleRequestRecord = ngc.getRoleRequestRecord(role.getName(),
                ale.getUniversalId());
        if(roleRequestRecord != null){
            roleRequestRecord.setState("Approved");
        }

        role.addPlayerIfNotPresent(ale);
        if (sendEmail) {
            sendInviteEmail(ngc,  ale.getEmail(), role.getName() );
        }
        HistoryRecord.createHistoryRecord(ngc, ale.getUniversalId(), HistoryRecord.CONTEXT_TYPE_PERMISSIONS,
                0, HistoryRecord.EVENT_PLAYER_ADDED, ar, role.getName());
    }

    private void sendInviteEmail(NGContainer container, String emailId, String role) throws Exception {
        MemFile body = new MemFile();
        UserProfile receivingUser = UserManager.findUserByAnyId(emailId);
        AuthRequest clone = new AuthDummy(receivingUser, body.getWriter(), ar.getCogInstance());
        UserProfile requestingUser = ar.getUserProfile();

        String dest = emailId;

        if (receivingUser != null) {
            dest = receivingUser.getPreferredEmail();
            if (dest == null) {
                //if looked up by email address, should at least find that email address!
                throw new Exception("something is wrong with the user information, looked up user '"
                        +emailId+"' but the user object found does not have an email address.");
            }
        } else {
            // first check to see if the passed value looks like an email
            // address if not, OK, it may be an Open ID, and
            // simply don't send the email in that case.
            if (emailId.indexOf('@') < 0) {
                // this is not an email address. Simply return silently, can't
                // send email.
                return;
            }
        }

        AddressListEntry ale = AddressListEntry.parseCombinedAddress(emailId);
        OptOutAddr ooa = new OptOutAddr(ale);

        clone.setNewUI(true);
        clone.retPath = ar.baseURL;


        clone.flush();
        
        Cognoscenti cog = clone.getCogInstance();
        File templateFile = cog.getConfig().getFileFromRoot("email/Invite.chtml");
        
        JSONObject data = new JSONObject();
        data.put("requesting", requestingUser.getJSON());
        data.put("roleName", role);
        data.put("wsURL", clone.baseURL + clone.getDefaultURL(container));
        data.put("wsName", container.getFullName());
        data.put("optout", ooa.getUnsubscribeJSON(ar));
        

        EmailSender.containerEmail(ooa, container, "Added to " + role
                + " role of " + container.getFullName(), templateFile, data,
                null, new ArrayList<String>(), cog);
    }




}
