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

package org.socialbiz.cog.rest;

import java.util.ArrayList;
import java.util.List;

import org.socialbiz.cog.AuthRequest;
import org.socialbiz.cog.DOMUtils;
import org.socialbiz.cog.UserManager;
import org.socialbiz.cog.UserProfile;
import org.socialbiz.cog.UtilityMethods;
import org.socialbiz.cog.ValueElement;
import org.socialbiz.cog.exception.NGException;
import org.socialbiz.cog.exception.ProgramLogicError;
import org.w3c.dom.Document;
import org.w3c.dom.Element;

public class ResourceUser implements NGResource
{
    private Document loutdoc;
    private Document lindoc;
    private String lid;
    private String ltype;
    private String lfile;
    private String lserverURL;
    private ResourceStatus lrstatus;
    private AuthRequest lar;
    private int statuscode = 200;
    private List<String> parsedPath;
    private String methodname = "";

    public ResourceUser(String serverURL, AuthRequest ar)
    {
        lserverURL = serverURL;
        lar = ar;
        parsedPath = ar.getParsedPath();
        methodname = ar.req.getMethod();
    }

    public String getType()
    {
        return ltype;
    }
    public Document getDocument()
    {
        return loutdoc;
    }
    public String getFilePath()
    {
        return lfile;
    }
    public int getStatusCode()
    {
        return statuscode;
    }

    public void executeRequest()throws Exception
    {
        String token2 = parsedPath.get(2);
        setId(parsedPath.get(1));

        if(parsedPath.size() != 3) {
            throw new ProgramLogicError("A request for user information needs exactly three values in the path.");
        }

        if("GET".equals(methodname))
        {
            if(NGResource.DATA_PROFILE_XML.equals(token2)){
                loadUesrProfile();
            } else if(token2.equals(NGResource.DATA_ALLTASK_XML)){
                loadTaskList(token2);
            }
            else if(token2.equals(NGResource.DATA_ACTIVETASK_XML)){
                loadTaskList(token2);
            }
            else if(token2.equals(NGResource.DATA_COMPLETETASK_XML)){
                loadTaskList(token2);
            }
            else if(token2.equals(NGResource.DATA_FUTURETASK_XML)){
                loadTaskList(token2);
            }else{
                throw new ProgramLogicError("Unable to perform GET operation to '"+token2+"'");
            }
        }else if("POST".equals(methodname)){
            if(NGResource.DATA_PROFILE_XML.equals(token2)){
                createUserProfile();
            }else {
                throw new ProgramLogicError("Unable to perform POST operation to '"+token2+"'");
            }
        }else if("PUT".equals(methodname)){
            if(NGResource.DATA_PROFILE_XML.equals(token2)){
                updateUserProfile();
            }else{
                throw new ProgramLogicError("Unable to perform PUT operation to '"+token2+"'");
            }
        }else{
            throw new ProgramLogicError("Unsupported method "+methodname+" on '"+token2+"'");
        }
    }

    public void setName(String name)
    {
    }

    public void setId(String id)
    {
        if(id != null) {
            lid = id.trim();
        }
    }

    public void setinput(Document doc)
    {
        lindoc = doc;
    }

    public void setResourceStatus(ResourceStatus rstatus)
    {
        lrstatus = rstatus;
    }

    private void loadUesrProfile()throws Exception
    {
        ltype = NGResource.TYPE_XML;
        UserProfile[] profiles = new UserProfile[0];;
        if("*".equals(lid)){
            profiles = UserManager.getAllUserProfiles();
        }else{
            UserProfile profile = UserManager.getUserProfileByKey(lid);
            if (profile == null) {
                lrstatus.setStatusCode(404);
                throw new NGException("nugen.exception.user.profile.not.found", new Object[]{lid});
            }
            profiles = new UserProfile[1];
            profiles[0] = profile;
        }
        String schema = lserverURL + NGResource.SCHEMA_USERPROFILE;
        loutdoc = DOMUtils.createDocument("userprofiles");
        Element element_profiles = loutdoc.getDocumentElement();
        DOMUtils.setSchemAttribute(element_profiles, schema);

        for(int i=0; i<profiles.length; i++)
        {
            UserProfile uprofile = profiles[i];
            Element element_uprofile = DOMUtils.createChildElement(loutdoc, element_profiles, "userprofile");
            element_uprofile.setAttribute("id", uprofile.getKey());
            DOMUtils.createChildElement(loutdoc, element_uprofile, "userid", uprofile.getUniversalId());
            DOMUtils.createChildElement(loutdoc, element_uprofile, "name", uprofile.getName());
            DOMUtils.createChildElement(loutdoc, element_uprofile, "description", uprofile.getDescription());

            //TODO: probably should not be sending ONE email since they have have many
            DOMUtils.createChildElement(loutdoc, element_uprofile, "email", uprofile.getPreferredEmail());

            String logindate = UtilityMethods.getXMLDateFormat(uprofile.getLastLogin());
            DOMUtils.createChildElement(loutdoc, element_uprofile, "lastlogin", logindate);
            String updatedate = UtilityMethods.getXMLDateFormat(uprofile.getLastUpdated());
            DOMUtils.createChildElement(loutdoc, element_uprofile, "lastupdated",updatedate);
            DOMUtils.createChildElement(loutdoc, element_uprofile, "homepage", uprofile.getHomePage());
            Element element_favlist = DOMUtils.createChildElement(loutdoc, element_uprofile, "favorites");
            ValueElement[] fList = uprofile.getFavorites();
            for(int k=0; k<fList.length; k++){
                Element element_fav = DOMUtils.createChildElement(loutdoc, element_favlist, "favorite");
                element_fav.setAttribute("name", fList[k].name);
                element_fav.setAttribute("address", fList[k].value);

            }

        }

    }

    private void createUserProfile() throws Exception
    {
        if(!lid.equals("factory"))
        {
            throw new NGException("nugen.exception.userid.must.be.factory", null);
        }
        if ( UserManager.findUserByAnyId(lar.getBestUserId()) != null) {
            lrstatus.setStatusCode(401);
            throw new ProgramLogicError("Profile already exists for user '" + lar.getBestUserId()
              + "' Use PUT to update the profile");
        }
        UserProfile profile = UserManager.createUserWithId(null, lar.getBestUserId());
        lclupdate(profile);

        lrstatus.setResourceid(profile.getKey());
        String profileAdd = lserverURL + "u/" + profile.getKey() + "/profile.xml";
        lrstatus.setResourceURL(profileAdd);
        lrstatus.setSuccess(NGResource.OP_SUCCEEDED);
        String cmsg = "User Profile is created for user '" + lar.getBestUserId() + "'.";
        lrstatus.setCommnets(cmsg);
        ltype = lrstatus.getType();
        loutdoc = lrstatus.getDocument();
    }

    private void updateUserProfile()throws Exception
    {
        UserProfile profile = UserManager.getUserProfileByKey(lid);
        if (profile == null)
        {
            lrstatus.setStatusCode(404);
            throw new NGException("nugen.exception.cant.update.user.profile", new Object[]{lid});
        }

        //check to see if the profile belongs to the logged in user
        if(!profile.hasAnyId(lar.getBestUserId()))
        {
            lrstatus.setStatusCode(401);
            throw new NGException("nugen.exception.userid.is.diff.with.openid", null);
        }
        lclupdate(profile);

        lrstatus.setResourceid(profile.getKey());
        String profileAdd = lserverURL + "u/" + profile.getKey() + "/profile.xml";
        lrstatus.setResourceURL(profileAdd);
        lrstatus.setSuccess(NGResource.OP_SUCCEEDED);
        String cmsg = "User Profile is updated for user '" + lar.getBestUserId() + "'.";
        lrstatus.setCommnets(cmsg);
        ltype = lrstatus.getType();
        loutdoc = lrstatus.getDocument();
    }

    private void lclupdate(UserProfile profile)throws Exception
    {
        Element element_uprofile = ResourceSection.findElement( lindoc.getDocumentElement(), "userprofile");

        String userId = DOMUtils.textValueOfChild(element_uprofile, "userid", true);
        if(userId != null && userId.length() > 0){
            if(!userId.equals(lar.getBestUserId()))
            {
                throw new NGException("nugen.exception.userid.not.matched.with.openid", null);
            }
        }
        String name  = DOMUtils.textValueOfChild(element_uprofile, "name", true);
        if(name != null && name.length() > 0){
            profile.setName(name);
        }
        String desc = DOMUtils.textValueOfChild(element_uprofile, "description", true);
        if(desc != null && desc.length() > 0){
            profile.setDescription(desc);
        }
        String email = DOMUtils.textValueOfChild(element_uprofile, "email", true);
        if(email != null && email.length() > 0){
            profile.addId(email);
        }
        String homePage = DOMUtils.textValueOfChild(element_uprofile, "homePage", true);
        if(homePage != null && homePage.length() > 0){
            profile.setHomePage(homePage);
        }
        Element element_favorites  = DOMUtils.getChildElement(element_uprofile, "favorites");
        List<ValueElement> favVect = new ArrayList<ValueElement>();
        for (Element element_fav : DOMUtils.getChildElementsList(element_favorites)) {
            String favname = element_fav.getAttribute("name");
            String favadd = element_fav.getAttribute("address");
            ValueElement fav = new ValueElement(favname, favadd);
            favVect.add(fav);
        }

        ValueElement[] favorites = favVect.toArray(new ValueElement[0]);
        profile.setFavorites(favorites);

        profile.setLastUpdated(lar.nowTime);
        UserManager.writeUserProfilesToFile();
    }

    private void loadTaskList(String filter)throws Exception
    {
        UserProfile profile = UserManager.getUserProfileByKey(lid);
        if (profile == null) {
            lrstatus.setStatusCode(404);
            throw new NGException("nugen.exception.unable.to.load.task",null);
        }

        ltype = NGResource.TYPE_XML;
        TaskHelper th = new TaskHelper(profile.getUniversalId(), lserverURL);
        th.scanAllTask(lar.getCogInstance());

        String schema = lserverURL + NGResource.SCHEMA_TASKLIST;
        loutdoc = DOMUtils.createDocument("activities");
        Element element_root = loutdoc.getDocumentElement();
        DOMUtils.setSchemAttribute(element_root, schema);

        th.fillInTaskList(loutdoc, element_root, filter);
    }

}
