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
package com.purplehillsbooks.weaver.api;

import java.util.ArrayList;
import java.util.List;

import com.purplehillsbooks.weaver.AddressListEntry;
import com.purplehillsbooks.weaver.AttachmentRecord;
import com.purplehillsbooks.weaver.AuthRequest;
import com.purplehillsbooks.weaver.License;
import com.purplehillsbooks.weaver.LicenseForUser;
import com.purplehillsbooks.weaver.NGBook;
import com.purplehillsbooks.weaver.NGRole;
import com.purplehillsbooks.weaver.NGWorkspace;
import com.purplehillsbooks.weaver.TopicRecord;
import com.purplehillsbooks.weaver.UserManager;
import com.purplehillsbooks.weaver.UserProfile;
import com.purplehillsbooks.weaver.exception.WeaverException;

public class ResourceDecoder {

    public String siteId;
    public NGBook site;
    public String projId;
    public NGWorkspace workspace;

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
            throw WeaverException.newBasic("Path should start with / but instead it is: "
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
            throw WeaverException.newBasic("Can't find a site ID in the URL.");
        }
        siteId = path.substring(curPos, slashPos);
        site = ar.getCogInstance().getSiteByIdOrFail(siteId);

        curPos = slashPos+1;
        slashPos = path.indexOf("/", curPos);
        if (slashPos<=curPos) {
            throw WeaverException.newBasic("Can't find a workspace ID in the URL.");
        }
        projId = path.substring(curPos, slashPos);

        if ("$".equals(projId)) {
            throw WeaverException.newBasic("ResourceDecoder Access to SITE is not supported");
        }
        workspace = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId,projId).getWorkspace();
        ar.setPageAccessLevels(workspace);
        lic = workspace.getLicense(licenseId);
        if (lic==null) {
            throw WeaverException.newBasic("Can not find the license '%s' on workspace '%s'", licenseId, projId);
        }
        licenseOwner = AddressListEntry.findOrCreate(lic.getCreator());
        setUserFromLicense(ar);

        curPos = slashPos+1;
        resource = path.substring(curPos);
        slashPos = resource.indexOf("/");

        if (resource.equals("summary.json") || resource.length()==0) {
            isListing = true;
            return;
        }
        if (resource.startsWith("temp")) {
            //needed for receiving temporary files
            isTempDoc = true;
            tempName = resource.substring(slashPos);
            return;
        }
        throw WeaverException.newBasic("ResourceDecoder Unable to handle resource=%s", resource);
    }

    private void setUserFromLicense(AuthRequest ar) throws Exception {
        if (lic!=null) {
            String userId = lic.getCreator();
            UserProfile up = UserManager.lookupUserByAnyId(userId);
            if (up==null) {
                throw WeaverException.newBasic("This license '%s' is no longer valid because the creator of the license can not be found.", licenseId);
            }
            //check that user is still valid
            if (up.getDisabled()) {
                throw WeaverException.newBasic("This license '%s' is no longer valid because the creator of the license is no longer enabled.", licenseId);
            }
            //check that user is in the role of this license
            //as long as this does not throw exception, everything is ok
            ar.setPossibleUser(up);
            getLicensedRoles();
        }
    }

    /**
     * License is for full member access if the name of the role is "Members"
     * and the user is a member or an owner.
     */
    private boolean hasFullMemberAccess() throws Exception {
        if (workspace==null || lic==null) {
            return false;
        }
        return lic.getRole().equalsIgnoreCase("Members") && ownerIsMemberofWorkspace();
    }

    private boolean ownerIsMemberofWorkspace() throws Exception {
        if (workspace==null || lic==null || licenseOwner==null) {
            return false;
        }
        return workspace.primaryOrSecondaryPermission(licenseOwner);
    }

    private List<NGRole> getLicensedRoles() throws Exception {
        List<NGRole> licensedRoles = new ArrayList<NGRole>();
        String restrictRole = lic.getRole();

        if (site==null) {
            throw WeaverException.newBasic("Program Logic Error: getLicensedRoles called before site is known");
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
                throw WeaverException.newBasic("The license (%s) is invalid because the user who created license is no longer a "
                        +"member of the role (%s)", licenseId, restrictRole);
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
