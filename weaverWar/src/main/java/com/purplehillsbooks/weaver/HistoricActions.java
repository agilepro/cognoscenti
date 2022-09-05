package com.purplehillsbooks.weaver;

import java.io.Writer;
import java.util.ArrayList;
import java.util.List;

import com.purplehillsbooks.weaver.mail.ChunkTemplate;
import com.purplehillsbooks.weaver.mail.EmailSender;
import com.purplehillsbooks.weaver.mail.MailInst;
import com.purplehillsbooks.weaver.mail.OptOutAddr;
import com.purplehillsbooks.weaver.mail.OptOutIndividualRequest;
import com.purplehillsbooks.json.JSONObject;
import com.purplehillsbooks.streams.MemFile;

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
    public SiteRequest createNewSiteRequest(JSONObject newSiteObj) throws Exception {
        SiteRequest accountDetails = SiteReqFile.createNewSiteRequest(newSiteObj, ar);

        accountDetails.sendSiteRequestEmail(ar);
        return accountDetails;
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
    public NGBook completeSiteRequest(SiteRequest siteRequest, boolean granted) throws Exception {
        AddressListEntry ale = new AddressListEntry(siteRequest.getRequester());
        NGBook ngb = null;
        if (granted) {
            //Create new Site
            siteRequest.assertSiteNotExist(cog);
            
            ngb = NGBook.createNewSite(siteRequest.getSiteId(), siteRequest.getSiteName(), cog);
            ngb.setKey(siteRequest.getSiteId());
            ngb.setDescription(siteRequest.getDescription());
            ngb.getPrimaryRole().addPlayer(ale);
            ngb.getSecondaryRole().addPlayer(ale);
            ngb.saveFile(ar, "New Site created");
            cog.makeIndexForSite(ngb);

            siteRequest.setStatus("Granted");
            ar.getSuperAdminLogFile().createAdminEvent(ngb.getKey(), ar.nowTime,
                ar.getBestUserId(), AdminEvent.SITE_CREATED);
        }
        else {
            siteRequest.setStatus("Denied");
            ar.getSuperAdminLogFile().createAdminEvent(siteRequest.getRequestId(), ar.nowTime,
                ar.getBestUserId(), AdminEvent.SITE_DENIED);
        }
        siteResolutionEmail(ale, siteRequest);
        return ngb;
    }

    private void siteResolutionEmail(AddressListEntry owner, SiteRequest siteRequest) throws Exception {
        if (!owner.isWellFormed()) {
            //no email is sent if there is no email address of the owner, or any other
            //problem with the owner user profile.
            return;
        }
        OptOutIndividualRequest ooir = new OptOutIndividualRequest(owner);

        JSONObject jo = new JSONObject();
        jo.put("req", siteRequest.getJSON());
        jo.put("owner", owner.getJSON());
        jo.put("admin", ar.getUserProfile().getJSON());
        jo.put("baseURL", ar.baseURL);

        MemFile body = new MemFile();
        Writer w = body.getWriter();
        ChunkTemplate.streamAuthRequest(w, ar, "SiteRequestStatus", jo, ooir.getCalendar());
        w.flush();

        List<OptOutAddr> v = new ArrayList<OptOutAddr>();
        v.add(ooir);
        
        MailInst msg = MailInst.genericEmail("$", "$", "Site Request Resolution for " + owner.getName(), body.toString());
        EmailSender.generalMailToOne(msg, ar.getUserProfile().getAddressListEntry(), ooir);
    }

}
