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
 */
package org.socialbiz.cog.api;

import java.util.ArrayList;
import java.util.List;

import org.socialbiz.cog.AddressListEntry;
import org.socialbiz.cog.AttachmentRecord;
import org.socialbiz.cog.AuthRequest;
import org.socialbiz.cog.DOMFace;
import org.socialbiz.cog.License;
import org.socialbiz.cog.LicenseForUser;
import org.socialbiz.cog.NGBook;
import org.socialbiz.cog.NGPage;
import org.socialbiz.cog.NGRole;
import org.socialbiz.cog.TopicRecord;
import org.socialbiz.cog.UserManager;
import org.socialbiz.cog.UserProfile;
import org.socialbiz.cog.exception.ProgramLogicError;

public class ResourceDecoder {

    public String siteId;
    public NGBook site;
    public String projId;
    public NGPage workspace;

    public boolean isSwagger;
    public boolean isSite;

    public boolean isListing;
    public String resource;

    public boolean isDoc;
    public String docId;
    public int docVersion;

    public boolean isGoal;
    public String goalId;

    public boolean isNote;
    public String noteId;
    public boolean isHtmlFormat;

    public boolean isTempDoc;
    public String tempName;

    public String licenseId;
    public License lic;
    private AddressListEntry licenseOwner;

    public ResourceDecoder(AuthRequest ar) throws Exception {

        licenseId = ar.defParam("lic", null);

        //this will only be the part AFTER the /api/
        String path = ar.req.getPathInfo();

        // TEST: check to see that the servlet path starts with /
        if (!path.startsWith("/")) {
            throw new ProgramLogicError("Path should start with / but instead it is: "
                            + path);
        }
        if (path.startsWith("/swagger.json")) {
            //swagger representation of API is freely available to anyone
            isSwagger = true;
            return;
        }

        int curPos = 1;
        int slashPos = path.indexOf("/", curPos);
        if (slashPos<=curPos) {
            throw new Exception("Can't find a site ID in the URL.");
        }
        siteId = path.substring(curPos, slashPos);
        site = ar.getCogInstance().getSiteByIdOrFail(siteId);

        curPos = slashPos+1;
        slashPos = path.indexOf("/", curPos);
        if (slashPos<=curPos) {
            throw new Exception("Can't find a workspace ID in the URL.");
        }
        projId = path.substring(curPos, slashPos);

        if ("$".equals(projId)) {
            isSite = true;
            if (licenseId==null) {
                throw new Exception("Can not access the site '"+site.getKey()+"' without any license.");
            }
            lic = site.getLicense(licenseId);
            if (lic==null) {
                throw new Exception("Can not find the license '"+licenseId+"' on site '"+site.getKey()+"'");
            }
            setUserFromLicense(ar);
            return;
        }
        workspace = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId,projId).getWorkspace();
        ar.setPageAccessLevels(workspace);
        lic = workspace.getLicense(licenseId);
        if (lic==null) {
            throw new Exception("Can not find the license '"+licenseId+"' on workspace '"+projId+"'");
        }
        licenseOwner = new AddressListEntry(lic.getCreator());
        setUserFromLicense(ar);

        curPos = slashPos+1;
        resource = path.substring(curPos);
        slashPos = resource.indexOf("/");

        if (resource.equals("summary.json") || resource.length()==0) {
            isListing = true;
            return;
        }
        if (resource.startsWith("doc")) {
            isDoc = true;
            if (slashPos<=3) {
                throw new Exception("malformed document access URL, did not find a document ID");
            }
            int hyphenPos = resource.indexOf("-");
            if (hyphenPos>0 && hyphenPos<slashPos) {
                String verStr = resource.substring(hyphenPos+1, slashPos);
                docId = resource.substring(3, hyphenPos);
                docVersion = DOMFace.safeConvertInt(verStr);
            }
            else {
                docId = resource.substring(3, slashPos);
                docVersion = -1;
            }
            return;
        }
        if (resource.startsWith("note")) {
            isNote = true;
            if (slashPos<=4) {
                throw new Exception("malformed topic access URL, did not find a topic ID");
            }
            noteId = resource.substring(4, slashPos);
            if (resource.endsWith("htm")) {
                isHtmlFormat = true;
            }
            return;
        }
        if (resource.startsWith("goal")) {
            isGoal = true;
            if (slashPos<=4) {
                throw new Exception("malformed action item access URL, did not find a goal ID");
            }
            goalId = resource.substring(4, slashPos);
            return;
        }
        if (resource.startsWith("temp")) {
            isTempDoc = true;
            tempName = resource.substring(slashPos);
        }
    }

    private void setUserFromLicense(AuthRequest ar) throws Exception {
        if (lic!=null) {
            String userId = lic.getCreator();
            UserProfile up = UserManager.findUserByAnyId(userId);
            if (up==null) {
                throw new Exception("This license '"+licenseId+"' is no longer valid because the creator of the license can not be found.");
            }
            //check that user is still valid
            if (up.getDisabled()) {
                throw new Exception("This license '"+licenseId+"' is no longer valid because the creator of the license is no longer enabled.");
            }
            //check that user is in the role of this license
            //as long as this does not throw exception, everything is ok
            ar.setUserForOneRequest(up);
            getLicensedRoles();
        }
    }

    /**
     * License is for full member access if the name of the role is "Members"
     * and the user is a member or an owner.
     */
    public boolean hasFullMemberAccess() throws Exception {
        if (workspace==null || lic==null) {
            return false;
        }
        return lic.getRole().equalsIgnoreCase("Members") && ownerIsMemberofWorkspace();
    }

    public boolean ownerIsMemberofWorkspace() throws Exception {
        if (workspace==null || lic==null || licenseOwner==null) {
            return false;
        }
        return workspace.primaryOrSecondaryPermission(licenseOwner);
    }

    public List<NGRole> getLicensedRoles() throws Exception {
        List<NGRole> licensedRoles = new ArrayList<NGRole>();
        String restrictRole = lic.getRole();
        
        if (site==null) {
            throw new Exception("Program Logic Error: getLicensedRoles called before site is known");
        }
        if (workspace==null) {
            //this is the case that you are being called on a site
            NGRole specifiedRole = site.getRole(restrictRole);
            licensedRoles.add(specifiedRole);
        }
        else if (lic instanceof LicenseForUser) {
            //for user license, find all the roles they play
            licensedRoles = workspace.findRolesOfPlayer(licenseOwner);
        }
        else {
            //for specified license, use only the role specified.
            NGRole specifiedRole = workspace.getRole(restrictRole);

            //if the license owner is not a member, then the license owner must be
            //a member of the specified role.
            if (!ownerIsMemberofWorkspace() && !specifiedRole.isExpandedPlayer(licenseOwner, workspace)) {
                throw new Exception("The license ("+licenseId
                        +") is invalid because the user who created license is no longer a "
                        +"member of the role ("+restrictRole+")");
            }
            licensedRoles.add(specifiedRole);
        }
        return licensedRoles;
    }

    public boolean canAccessAttachment(AttachmentRecord att) throws Exception {
        if (hasFullMemberAccess()) {
            return true;
        }
        for (NGRole lRole : getLicensedRoles()) {
            if (att.roleCanAccess(lRole.getName())) {
                return true;
            }
        }
        return false;
    }

    public boolean canAccessNote(TopicRecord note) throws Exception {
        if (hasFullMemberAccess()) {
            return true;
        }
        for (NGRole lRole : getLicensedRoles()) {
            if (note.roleCanAccess(lRole.getName())) {
                return true;
            }
        }
        return false;
    }
}
