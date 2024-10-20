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
 * Anamika Chaudhari, Ajay Kakkar, Rajeev Rastogi, Pawan Chopra
 */

package com.purplehillsbooks.weaver.spring;

import java.util.ArrayList;
import java.util.List;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import com.purplehillsbooks.weaver.AddressListEntry;
import com.purplehillsbooks.weaver.AuthRequest;
import com.purplehillsbooks.weaver.NGBook;
import com.purplehillsbooks.weaver.NGRole;
import com.purplehillsbooks.weaver.NGWorkspace;
import com.purplehillsbooks.weaver.UserProfile;
import com.purplehillsbooks.weaver.exception.WeaverException;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;

import com.purplehillsbooks.json.JSONArray;
import com.purplehillsbooks.json.JSONObject;

/**
 * This class will handle all requests that are coming to create a new Workspace.
 * Currently this is handling only requests that are coming to create a new
 * project from scratch. Later this can be extended to edit a project or to
 * create a project from Template.
 */
@Controller
public class CreateProjectController extends BaseController {

    @RequestMapping(value = "/{siteId}/$/createWorkspace.json", method = RequestMethod.POST)
    public void createWorkspaceAPI(@PathVariable String siteId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try{
            NGBook site = ar.getCogInstance().getSiteById(siteId);
            ar.setPageAccessLevels(site);
            site.assertSiteExecutive(ar.getUserProfile(), "Must be an executive of a site to create a new workspace");

            JSONObject newConfig = getPostedObject(ar);
            String workspaceName = newConfig.getString("newName");

            //first, if given a template, check to make sure it exists else error before creating workspace
            NGWorkspace templateWorkspace = null;
            if (newConfig.has("template")) {
                String template    = newConfig.getString("template");
                if (template.length()>0) {
                    templateWorkspace = ar.getCogInstance().getWSByCombinedKeyOrFail(template).getWorkspace();
                }
            }

            //now actually create it
            NGWorkspace newWorkspace = createWorkspace(ar, site, workspaceName);
            
            //temp name change in case the old name is used someplace
            if (newConfig.has("parent")) {
                newConfig.put("parentKey", newConfig.getString("parent"));
            }

            //handles parentKey, purpose, and frozen
            newWorkspace.updateConfigJSON(ar, newConfig);

            if (newConfig.has("members")) {
                //do the members if any specified
                JSONArray members  = newConfig.getJSONArray("members");
                if (members!=null) {
                    NGRole memberRole = newWorkspace.getRole("Members");
                    for (int i=0; i<members.length(); i++) {
                        JSONObject memberObj = members.getJSONObject(i);
                        String memberAddress = memberObj.getString("uid");
                        memberRole.addPlayerIfNotPresent(AddressListEntry.findOrCreate(memberAddress));
                    }
                }
            }

            //now apply template if found
            if (templateWorkspace!=null) {
                newWorkspace.injectTemplate(ar, templateWorkspace);
            }
            newWorkspace.saveModifiedWorkspace(ar, "Workspace created from web api");

            JSONObject repo = newWorkspace.getConfigJSON();
            sendJson(ar, repo);
        }
        catch(Exception ex){
            Exception ee = WeaverException.newWrap("Unable to create workspace in Site: %s", ex, siteId);
            streamException(ee, ar);
        }
    }



    ////////////////// HELPER FUNCTIONS /////////////////////////////////


    /**
     * Takes a nice display name and turns it into a
     * nice URL value.
     *
     * The input:  "My favorite, usual Hangout!"
     * produces:   "my-favorite-usual-hangout"
     *
     * All the letters are lower cased.
     * Only A-Z is supported with numerals
     * any gaps of other characters of any kind replaced with hyphen
     * hyphen avoided on either end
     */
    private static String makeGoodSearchableName(String source) {
        StringBuffer result = new StringBuffer();
        source = source.trim();
        int last = source.length();
        boolean betweenWords = false;
        for (int i=0; i<last; i++) {
            char ch = source.charAt(i);
            boolean addableChar = false;
            if (ch >= 'a' && ch <= 'z') {
                addableChar = true;
            }
            else if (ch >= '0' && ch <= '9') {
                addableChar = true;
            }
            else if (ch >= 'A' && ch <= 'Z') {
                ch = (char) (ch + 32);
                addableChar = true;
            }
            if (addableChar) {
                if (betweenWords) {
                    result.append('-');
                }
                result.append(ch);
                betweenWords = false;
            }
            else {
                //this avoid adding a hypen at the beginning if no
                //acceptable character has been seen yet.
                betweenWords = result.length()>0;
            }
        }
        return result.toString();
    }


    /**
     * Creates a workspace, but does not save it.
     * Caller must save the workspace ... otherwise bad things could happen.
     */
    private static NGWorkspace createWorkspace(AuthRequest ar, NGBook site, String workspaceName) throws Exception {
        UserProfile uProf = ar.getUserProfile();
        if (!site.primaryOrSecondaryPermission(uProf)) {
            throw WeaverException.newBasic("User does not have permission to create a workspace in site '%s'", site.getFullName());
        }

        String pageKey = makeGoodSearchableName(workspaceName);
        if (pageKey.length()>30) {
            pageKey = pageKey.substring(0,30);
        }

        //look for an alternate key if the easy one is not available
        pageKey = site.genUniqueWSKeyInSite(pageKey);

        NGWorkspace newWorkspace = site.createWorkspaceByKey(ar, pageKey);
        List<String> nameSet = new ArrayList<String>();
        nameSet.add(workspaceName);
        newWorkspace.setPageNames(nameSet);

        newWorkspace.setSite(site);

        ar.getCogInstance().makeIndexForWorkspace(newWorkspace);

        return newWorkspace;
    }



    @RequestMapping(value = "/NewSiteApplication.htm", method = RequestMethod.GET)
    public void NewSiteApplication(HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try{
            if (ar.isLoggedIn()) {
                redirectBrowser(ar, ar.getUserProfile().getKey()+"/NewSiteRequest.htm");
            }
            streamJSPAnon(ar, "NewSiteApplication.jsp");  /*needtest*/
        }
        catch(Exception ex){
            showDisplayException(ar, WeaverException.newWrap(
                "Unable to display the Register New Site page", ex));
        }
    }

    @RequestMapping(value = "/{userKey}/NewSiteRequest.htm", method = RequestMethod.GET)
    public void NewSiteRequest(HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try {
            if (!ar.isLoggedIn()) {
                redirectBrowser(ar, "../NewSiteApplication.htm");
            }
            UserProfile uProf = ar.getUserProfile();
            if (uProf == null) {
                // this should be impossible
                throw WeaverException.newBasic(
                        "Inconsistancy: user logged in but does not have a profile: %s", 
                        ar.getBestUserId());
            }
            String userKey = uProf.getKey();
            streamJSPUserLoggedIn(ar, userKey, "NewSiteRequest.jsp");
        } 
        catch (Exception ex) {
            showDisplayException(ar, WeaverException.newWrap(
                "Unable to display the Register New Site page", ex));
        }
    }


}
