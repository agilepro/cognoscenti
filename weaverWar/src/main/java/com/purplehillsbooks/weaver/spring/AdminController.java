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

package com.purplehillsbooks.weaver.spring;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import com.purplehillsbooks.weaver.AuthRequest;
import com.purplehillsbooks.weaver.NGBook;
import com.purplehillsbooks.weaver.NGWorkspace;
import com.purplehillsbooks.weaver.exception.WeaverException;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import com.purplehillsbooks.json.JSONObject;

@Controller
public class AdminController extends BaseController {


    @RequestMapping(value = "/{siteId}/{pageId}/updateProjectInfo.json", method = RequestMethod.POST)
    public void updateProjectInfo(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try{
            NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
            ar.setPageAccessLevels(ngw);
            ar.assertAdmin("update workspace info for "+ngw.getFullName());
            //ar.assertNotFrozen(ngp);
            JSONObject newConfig = getPostedObject(ar);

            ngw.updateConfigJSON(ar, newConfig);

            //note: this save does not set the "last changed" metadata
            //configuration changes are not content changes and should not
            //appear as being updated.
            ngw.saveWithoutMarkingModified(ar.getBestUserId(), "Updating workspace settings", ar.getCogInstance());
            JSONObject repo = ngw.getConfigJSON();
            sendJson(ar, repo);
        }
        catch(Exception ex){
            Exception ee = WeaverException.newWrap("Unable to update project information.", ex);
            streamException(ee, ar);
        }
    }


    @RequestMapping(value = "/{siteId}/{pageId}/updateWorkspaceName.json", method = RequestMethod.POST)
    public void updateWorkspaceName(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try{
            NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
            ar.setPageAccessLevels(ngw);
            ar.assertAdmin("change workspace name.");
            
            //NOTE: this operation is ALLOWED on a frozen workspace because sometimes the name
            //      of a frozen workspace needs to be changed to differentiate from newer workspaces.
            
            JSONObject newData = getPostedObject(ar);

            String newName = newData.getString("newName");
            ngw.setNewName(newName);

            //note: this save does not set the "last changed" metadata
            //configuration changes are not content changes and should not
            //appear as being updated.
            ngw.saveWithoutMarkingModified(ar.getBestUserId(), "Updating workspace name", ar.getCogInstance());
            JSONObject repo = ngw.getConfigJSON();
            sendJson(ar, repo);
        }
        catch(Exception ex){
            Exception ee = WeaverException.newWrap("Unable change workspace name for '%s'", ex, pageId);
            streamException(ee, ar);
        }
    }



    // this can be deleted
    @RequestMapping(value = "/{siteId}/{pageId}/deleteWorkspaceName.json", method = RequestMethod.POST)
    public void deleteWorkspaceName(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try{
            throw WeaverException.newBasic("deleteWorkspaceName is no longer implemented, no longer needed");
        }
        catch(Exception ex){
            Exception ee = WeaverException.newWrap("Unable to save new name.", ex);
            streamException(ee, ar);
        }
    }


    @RequestMapping(value = "/{siteId}/$/updateSiteInfo.json", method = RequestMethod.POST)
    public void updateSiteInfo(@PathVariable String siteId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try{
            NGBook site = ar.getCogInstance().getSiteByIdOrFail(siteId);
            ar.setPageAccessLevels(site);
            ar.assertAdmin("update site info.");
            //even when frozen, need to be able to unfreeze
            //ar.assertNotFrozen(site);
            JSONObject newConfig = getPostedObject(ar);

            site.updateConfigJSON(newConfig);
            
            //allow updates for super admin things only if super admin
            if (ar.isSuperAdmin()) {
                site.updateAdminConfigJSON(newConfig);
            }

            //save changes but DONT change the date.   These kinds of meta-changes don't qualify as modifications.
            site.save();
            JSONObject repo = site.getConfigJSON();
            sendJson(ar, repo);
        }
        catch(Exception ex){
            Exception ee = WeaverException.newWrap("Unable to update site information.", ex);
            streamException(ee, ar);
        }
    }


}
