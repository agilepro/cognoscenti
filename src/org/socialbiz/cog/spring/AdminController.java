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

import java.util.List;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.socialbiz.cog.AuthRequest;
import org.socialbiz.cog.NGBook;
import org.socialbiz.cog.NGPage;
import org.socialbiz.cog.SectionWiki;
import org.socialbiz.cog.exception.NGException;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.workcast.json.JSONObject;

@Controller
public class AdminController extends BaseController {


    @RequestMapping(value = "/{siteId}/{pageId}/updateProjectInfo.json", method = RequestMethod.POST)
    public void updateProjectInfo(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try{
            NGPage ngp = ar.getCogInstance().getWorkspaceByKeyOrFail( pageId );
            ar.setPageAccessLevels(ngp);
            ar.assertAdmin("Must be an admin to change workspace info.");
            JSONObject newConfig = getPostedObject(ar);

            ngp.updateConfigJSON(ar, newConfig);

            //note: this save does not set the "last changed" metadata
            //configuration changes are not content changes and should not
            //appear as being updated.
            ngp.saveWithoutMarkingModified(ar.getBestUserId(), "Updating workspace settings", ar.getCogInstance());
            JSONObject repo = ngp.getConfigJSON();
            repo.write(ar.w, 2, 2);
            ar.flush();
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
            NGPage ngp = ar.getCogInstance().getWorkspaceByKeyOrFail( pageId );
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
            repo.write(ar.w, 2, 2);
            ar.flush();
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
            NGPage ngp = ar.getCogInstance().getWorkspaceByKeyOrFail( pageId );
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
            repo.write(ar.w, 2, 2);
            ar.flush();
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

            site.saveContent(ar, "Updating workspace settings");
            JSONObject repo = site.getConfigJSON();
            repo.write(ar.w, 2, 2);
            ar.flush();
        }catch(Exception ex){
            Exception ee = new Exception("Unable to update site information.", ex);
            streamException(ee, ar);
        }
    }





    //TODO: just update the list of names instead of separate operations to add and delete
    //TODO: change this to a JSON post
    @RequestMapping(value = "/{siteId}/{project}/deletePreviousProjectName.htm", method = RequestMethod.GET)
    public void deletePreviousAccountNameHandler(@PathVariable String siteId, @PathVariable String project,
            HttpServletRequest request,
            HttpServletResponse response)
    throws Exception {
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            ar.assertLoggedIn("User must be logged in to delete previous name of workspace.");
            NGPage ngp = ar.getCogInstance().getWorkspaceByKeyOrFail(project);
            ar.setPageAccessLevels(ngp);
            ar.assertAdmin("Unable to change the name of this page.");

            String oldName = ar.reqParam("oldName");

            List<String> nameSet = ngp.getPageNames();
            int oldPos = findString(nameSet, oldName);

            if (oldPos>=0) {
                nameSet.remove(oldPos);
                ngp.setPageNames(nameSet);
            }
            ngp.saveFile(ar, "Change Name Action");

            ar.resp.sendRedirect("admin.htm");
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.admin.delete.previous.project.name", new Object[]{project,siteId} , ex);
        }
    }


    // compare the sanitized versions of the names in the array, and if
    // the val equals one, return the index of that string, otherwise
    // return -1
    private int findString(List<String> array, String val)
    {
        String sanVal = SectionWiki.sanitize(val);
        for (int i=0; i<array.size(); i++)
        {
            String san2 = SectionWiki.sanitize(array.get(i));
            if (sanVal.equals(san2))
            {
                return i;
            }
        }
        return -1;
    }


}
