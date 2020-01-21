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

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.socialbiz.cog.AuthRequest;
import org.socialbiz.cog.NGBook;
import org.socialbiz.cog.NGWorkspace;
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
            NGWorkspace ngp = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
            ar.setPageAccessLevels(ngp);
            ar.assertAdmin("Must be an admin to change workspace info.");
            JSONObject newConfig = getPostedObject(ar);

            ngp.updateConfigJSON(ar, newConfig);

            //note: this save does not set the "last changed" metadata
            //configuration changes are not content changes and should not
            //appear as being updated.
            ngp.saveWithoutMarkingModified(ar.getBestUserId(), "Updating workspace settings", ar.getCogInstance());
            JSONObject repo = ngp.getConfigJSON();
            sendJson(ar, repo);
        }catch(Exception ex){
            Exception ee = new Exception("Unable to update project information.", ex);
            streamException(ee, ar);
        }
    }


    @RequestMapping(value = "/{siteId}/{pageId}/updateWorkspaceName.json", method = RequestMethod.POST)
    public void updateWorkspaceName(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try{
            NGWorkspace ngp = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
            ar.setPageAccessLevels(ngp);
            ar.assertAdmin("Must be an admin to change workspace info.");
            JSONObject newData = getPostedObject(ar);

            String newName = newData.getString("newName");
            ngp.setNewName(newName);

            //note: this save does not set the "last changed" metadata
            //configuration changes are not content changes and should not
            //appear as being updated.
            ngp.saveWithoutMarkingModified(ar.getBestUserId(), "Updating workspace name", ar.getCogInstance());
            JSONObject repo = ngp.getConfigJSON();
            sendJson(ar, repo);
        }catch(Exception ex){
            Exception ee = new Exception("Unable to save new name.", ex);
            streamException(ee, ar);
        }
    }
    @RequestMapping(value = "/{siteId}/{pageId}/deleteWorkspaceName.json", method = RequestMethod.POST)
    public void deleteWorkspaceName(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try{
            NGWorkspace ngp = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
            ar.setPageAccessLevels(ngp);
            ar.assertAdmin("Must be an admin to change workspace info.");
            JSONObject newData = getPostedObject(ar);

            String oldName = newData.getString("oldName");
            ngp.deleteOldName(oldName);

            //note: this save does not set the "last changed" metadata
            //configuration changes are not content changes and should not
            //appear as being updated.
            ngp.saveWithoutMarkingModified(ar.getBestUserId(), "Updating workspace name", ar.getCogInstance());
            JSONObject repo = ngp.getConfigJSON();
            sendJson(ar, repo);
        }catch(Exception ex){
            Exception ee = new Exception("Unable to save new name.", ex);
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
            ar.assertAdmin("Must be an admin to change site info.");
            JSONObject newConfig = getPostedObject(ar);

            site.updateConfigJSON(newConfig);

            //save changes but DONT change the date.   These kinds of meta-changes don't qualify as modifications.
            site.save();
            JSONObject repo = site.getConfigJSON();
            sendJson(ar, repo);
        }catch(Exception ex){
            Exception ee = new Exception("Unable to update site information.", ex);
            streamException(ee, ar);
        }
    }


}
