package org.socialbiz.cog;

import java.io.StringWriter;
import java.util.Vector;

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
        StringWriter bodyWriter = new StringWriter();
        UserProfile up = UserManager.getSuperAdmin(ar);
        AuthRequest clone = new AuthDummy(ar.getUserProfile(), bodyWriter, ar.getCogInstance());
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
        clone.write("<p>Being a <b>Super Admin</b> of the Cognoscenti console, you have rights to accept or deny this request.</p>");
        clone.write("</body></html>");

        EmailSender.simpleEmail(UserManager.getSuperAdminMailList(ar), null,
                "Site Approval for " + ar.getBestUserId(),
                bodyWriter.toString(), ar.getCogInstance());
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
        StringWriter bodyWriter = new StringWriter();
        AuthRequest clone = new AuthDummy(ar.getUserProfile(), bodyWriter, ar.getCogInstance());
        clone.setNewUI(true);
        clone.retPath = ar.baseURL;
        clone.write("<html><body>\n");
        clone.write("<p>This message was sent automatically from Cognoscenti to keep you up ");
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

        Vector<OptOutAddr> v = new Vector<OptOutAddr>();
        v.add(new OptOutIndividualRequest(new AddressListEntry(owner)));

        EmailSender.simpleEmail(v, null, "Site Request Resolution for " + owner.getName(),
                bodyWriter.toString(), ar.getCogInstance());
    }

    /**
     * When adding a list of people to be players of a role, this method will do that
     * and will also email each one letting them know.
     * @param memberList is a list of names in standard email format.
     * @param sendEmail set to true if you want email sent, false if not.
     */
    public void addMembersToRole(NGContainer ngc, NGRole role, String memberList, boolean sendEmail) throws Exception {
        Vector<AddressListEntry> emailList = AddressListEntry.parseEmailList(memberList);
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
            sendInviteEmail(ngc.getKey(),  ale.getEmail(), role.getName() );
        }
        HistoryRecord.createHistoryRecord(ngc, ale.getUniversalId(), HistoryRecord.CONTEXT_TYPE_PERMISSIONS,
                0, HistoryRecord.EVENT_PLAYER_ADDED, ar, role.getName());
    }

    private void sendInviteEmail(String pageId, String emailId, String role) throws Exception {
        StringWriter bodyWriter = new StringWriter();
        NGContainer container = ar.getCogInstance().getProjectByKeyOrFail(pageId);
        UserProfile receivingUser = UserManager.findUserByAnyId(emailId);
        AuthRequest clone = new AuthDummy(receivingUser, bodyWriter, ar.getCogInstance());
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

        clone.write("<html><body>\n");
        clone.write("<p>");
        requestingUser.writeLink(clone);
        clone.write(" has added you to the '");
        clone.writeHtml(role);
        clone.write("' role of the ");
        container.writeContainerLink(clone, 100);
        clone.write(" project.</p>");

        if (receivingUser==null) {
            clone.write("<p>Cognoscenti is a cloud-based service to help people manage the documents, ");
            clone.write("topics, and action items of a project.  ");
            clone.write("It uses an approach known as Adaptive Case Management (ACM).  ");
            clone.write("By being added to this role, you will have some ability to access that project ");
            clone.write("and to receive email from the people working on the project.</p>");
            clone.write("<p>I've checked, and there is no user profile for you at this email address (");
            clone.writeHtml(emailId);
            clone.write(") so you have two options: create a new login and profile for this email address, ");
            clone.write("or add this email address to an existing user profile that you already have.");
            clone.write("Creating a new login profile is free and easy.</p>");
        }
        //clone.write("<p>If you do not know this person, this project, or for any reason you do not want");
        //clone.write("to be included in this role, you can easily <a href="">unsubscribe</a> from the role.</p>");

        EmailSender.containerEmail(ooa, container, "Added to " + role
                + " role of " + container.getFullName(), bodyWriter.toString(),
                null, new Vector<String>(), clone.getCogInstance());
        NGPageIndex.releaseLock(container);
    }




}
