package org.socialbiz.cog;

import java.io.File;
import java.io.Writer;
import java.util.ArrayList;
import java.util.List;

import org.socialbiz.cog.mail.ChunkTemplate;
import org.socialbiz.cog.mail.EmailSender;
import org.workcast.json.JSONObject;
import org.workcast.streams.MemFile;

public class HistoricActions {

    private AuthRequest ar;
    private Cognoscenti cog;

    /**
     * Actions that create history and/or send
     * email messages, are consolidated into this layer.
     */
    public HistoricActions(AuthRequest _ar) throws Exception {
        ar = _ar;
        ar.assertLoggedIn("Action on this resource allowed only when you are logged in.");
        cog = ar.getCogInstance();
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

        sendSiteRequestEmail(accountDetails);
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

    private void sendSiteRequestEmail(SiteRequest siteRequest) throws Exception {
        for (UserProfile up : cog.getUserManager().getAllSuperAdmins(ar)) {
            JSONObject jo = new JSONObject();
            jo.put("req", siteRequest.getJSON());
            jo.put("baseURL", ar.baseURL);
            jo.put("admin", up.getJSON());
            
            File templateFile = cog.getConfig().getFileFromRoot("email/SiteRequest.chtml");
            MemFile body = new MemFile();
            Writer w = body.getWriter();
            ChunkTemplate.streamIt(w, templateFile, jo, up.getCalendar());
            w.flush();

            EmailSender.generalMailToList(cog.getUserManager().getSuperAdminMailList(ar), ar.getBestUserId(),
                    "Site Approval for " + ar.getBestUserId(),
                    body.toString(), cog);
        }
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
            ngb = NGBook.createNewSite(siteRequest.getSiteId(), siteRequest.getName(), cog);
            ngb.setKey(siteRequest.getSiteId());
            ngb.setDescription(siteRequest.getDescription());
            ngb.getPrimaryRole().addPlayer(ale);
            ngb.getSecondaryRole().addPlayer(ale);
            ngb.saveFile(ar, "New Site created");
            cog.makeIndex(ngb);

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
        AddressListEntry ale = new AddressListEntry(owner);
        if (!ale.isWellFormed()) {
        	//no email is sent if there is no email address of the owner, or any other 
        	//problem with the owner user profile.
        	return;
        }
        OptOutIndividualRequest ooir = new OptOutIndividualRequest(ale);
        
        JSONObject jo = new JSONObject();
        jo.put("req", siteRequest.getJSON());
        jo.put("owner", owner.getJSON());
        jo.put("admin", ar.getUserProfile().getJSON());
        jo.put("baseURL", ar.baseURL);
        
        File templateFile = cog.getConfig().getFileFromRoot("email/SiteRequestStatus.chtml");
        MemFile body = new MemFile();
        Writer w = body.getWriter();
        ChunkTemplate.streamIt(w, templateFile, jo, ooir.getCalendar());
        w.flush();

        List<OptOutAddr> v = new ArrayList<OptOutAddr>();
        v.add(ooir);

        EmailSender.generalMailToList(v, ar.getBestUserId(), "Site Request Resolution for " + owner.getName(),
                body.toString(), cog);
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
        AuthRequest clone = new AuthDummy(receivingUser, body.getWriter(), cog);
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
