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

package com.purplehillsbooks.weaver.rest;

import java.util.ArrayList;
import java.util.List;

import com.purplehillsbooks.weaver.AddressListEntry;
import com.purplehillsbooks.weaver.AuthRequest;
import com.purplehillsbooks.weaver.DOMUtils;
import com.purplehillsbooks.weaver.IdGenerator;
import com.purplehillsbooks.weaver.License;
import com.purplehillsbooks.weaver.NGBook;
import com.purplehillsbooks.weaver.NGPageIndex;
import com.purplehillsbooks.weaver.NGSection;
import com.purplehillsbooks.weaver.NGWorkspace;
import com.purplehillsbooks.weaver.ProcessRecord;
import com.purplehillsbooks.weaver.SearchResultRecord;
import com.purplehillsbooks.weaver.TopicRecord;
import com.purplehillsbooks.weaver.UtilityMethods;
import com.purplehillsbooks.weaver.exception.NGException;
import com.purplehillsbooks.weaver.exception.ProgramLogicError;
import org.w3c.dom.Document;
import org.w3c.dom.Element;

public class ResourcePage implements NGResource
{

    private Document loutdoc;
    private Document lindoc;
    private String lid;
    private String ltype;
    private String lfile;
    private String lserverURL;
    private ResourceStatus lrstatus;
    private AuthRequest ar;
    private int statuscode = 200;
    private String licenseId;
    private License license;
    public ResourcePage(String serverURL, AuthRequest _ar)
    {
        lserverURL = serverURL;
        ar= _ar;
    }

    public ResourcePage(Document outdoc, String type)
    {
        loutdoc = outdoc;
        ltype = type;
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

    public NGWorkspace getPageMustExist() throws Exception
    {
        if (lid==null || lid.length()==0) {
            lrstatus.setStatusCode(500);
            throw new Exception("ID for the page resource must be set before attempting to access the resource.");
        }

        NGPageIndex ngpi = ar.getCogInstance().getWSByCombinedKeyOrFail(lid);
        if (ngpi==null)
        {
            lrstatus.setStatusCode(404);
            throw new NGException("nugen.exception.page.not.found",new Object[]{lid});
        }
        if (!ngpi.isWorkspace())
        {
            lrstatus.setStatusCode(404);
            throw new NGException("nugen.exception.project.not.found",new Object[]{lid});
        }
        NGWorkspace ngp = ngpi.getWorkspace();
        if (ngp==null)
        {
            lrstatus.setStatusCode(404);
            throw new NGException("nugen.exception.page.not.found",new Object[]{lid});
        }

        ar.setPageAccessLevels(ngp);

        //now check that the proper license is included, all access to page must be checked
        String lic = ar.reqParam("lic");
        license = ngp.getLicense(lic);
        if (license==null) {
            throw new Exception("Can not access this page, license id is no longer valid: "+lic);
        }

        return ngp;
    }


    public NGWorkspace getPageIfExist()
        throws Exception
    {
        NGPageIndex ngpi = ar.getCogInstance().getWSByCombinedKeyOrFail(lid);
        if (ngpi==null)
        {
            return null;
        }
        NGWorkspace ngp = ngpi.getWorkspace();
        return ngp;
    }



    public void create() throws Exception
    {
        Element element_page = lindoc.getDocumentElement();
        String id = element_page.getAttribute("id");
        if(!"factory".equals(id))
        {
           lrstatus.setStatusCode(404);
           throw new NGException ("nugen.exception.page.address.invalid",null);
        }

        String bookid = DOMUtils.textValueOfChild(element_page, "bookurl", true);
        bookid = parsebookid(bookid);
        NGBook ngb = ar.getCogInstance().getSiteByIdOrFail(bookid);
        if(!ngb.primaryPermission(ar.getUserProfile())){
            lrstatus.setStatusCode(401);
            throw new NGException ("nugen.exception.user.not.executive", new Object[]{ngb.getKey()});
        }

        //TODO: surely we can do better than a purely random ID
        String pageAddress = IdGenerator.generateKey();
        NGWorkspace newWorkspace = ngb.createWorkspaceByKey(ar, pageAddress);

        String name = DOMUtils.textValueOfChild(element_page, "name", true);
        String abbreviation = DOMUtils.textValueOfChild(element_page, "abbreviation", true);
        List<String> nameSet = new ArrayList<String>();
        nameSet.add(name);
        if (abbreviation!=null) {
            nameSet.add(abbreviation);
        }

        newWorkspace.setPageNames(nameSet);
        newWorkspace.setSite(ngb);

        Element element_goal = DOMUtils.getChildElement(element_page, "goal");
        String synopsis = DOMUtils.textValueOfChild(element_goal, "synopsis", true);
        String description = DOMUtils.textValueOfChild(element_goal, "description", true);
        ProcessRecord process = newWorkspace.getProcess();
        process.setSynopsis(synopsis);
        process.setDescription(description);
        Element element_sections = DOMUtils.getChildElement(element_page, "sections");
        for (Element element_section : DOMUtils.getChildElementsList(element_sections)) {
            String sname =  DOMUtils.getChildText(element_section,"secname").trim();
            if(sname != null && sname.length()>0
                && newWorkspace.getSection(sname) == null){
                throw new Exception("Create section no longer allowed. Protocol can not any longer create sections");
            }

            NGSection ngs = newWorkspace.getSectionOrFail(sname);
            if(ngs.getName().equals("Description")
                    || ngs.getName().equals("Public Description")
                    || ngs.getName().equals("Notes")
                    || ngs.getName().equals("Member Content")
                    || ngs.getName().equals("Content")
                    || ngs.getName().equals("XXX Notes") ) {

                ResourceSection.updateWikiSection(newWorkspace, ngs,element_section, ar);

            }else if(ngs.getName().equals("Tasks")){
                ResourceSection.updateTaskSection(newWorkspace, ngs,element_section, ar);
            }else if(ngs.getName().equals("Attachments")){
                ResourceSection.updateAttachmentSection(newWorkspace, ngs,element_section, ar);
            }else if(ngs.getName().equals("Comments")){
                ResourceSection.updateCommentSection(newWorkspace, ngs,element_section, ar);
            }else if(ngs.getName().equals("Public Links")){
                ResourceSection.updateLinkSection(newWorkspace, ngs,element_section);
            }else if(ngs.getName().equals("See Also")
                || ngs.getName().equals("Public Comments")
                || ngs.getName().equals("Geospatial")
                || ngs.getName().equals("Author Notes")
                || ngs.getName().equals("Links")
                || ngs.getName().equals("Public Attachments")
                || ngs.getName().equals("Public Content")){
                throw new Exception("There should be NO section with this name: "+ngs.getName());
            }
        }

        newWorkspace.saveFile(ar, "Creating a page from a REST API request");
        ar.getCogInstance().makeIndexForWorkspace(newWorkspace);

        //Create Status
        lrstatus.setResourceid(newWorkspace.getKey());
        String pageAddr = lserverURL + "p/" + newWorkspace.getKey() + "/leaf.xml";
        lrstatus.setResourceURL(pageAddr);
        lrstatus.setSuccess(NGResource.OP_SUCCEEDED);
        String cmsg = "A new page \"" + newWorkspace.getKey() + "\" is created";
        lrstatus.setCommnets(cmsg);
        ltype = lrstatus.getType();
        loutdoc = lrstatus.getDocument();
    }

    public void delete() throws Exception
    {
        if (true) {
            throw new Exception("Deleting through this rest API no longer supported");
        }
    }

    public void loadContent() throws Exception
    {
        ltype = NGResource.TYPE_XML;
        NGWorkspace ngp = getPageMustExist();

        String schema = lserverURL + NGResource.SCHEMA_PAGE;
        loutdoc = DOMUtils.createDocument("page");
        Element element_root = loutdoc.getDocumentElement();
        element_root.setAttribute("id", ngp.getKey());
        DOMUtils.setSchemAttribute(element_root, schema);

        //Adding name element
        DOMUtils.createChildElement(loutdoc, element_root, "name", ngp.getFullName() );

        //Adding abbreviation element
        DOMUtils.createChildElement(loutdoc, element_root, "abbreviation", "sp" );


        DOMUtils.createChildElement(loutdoc, element_root, "accessRole", license.getRole());

         //Adding book element
        if (ar.isMember())
        {
            NGBook ngb = ngp.getSite();
            String bookAddr = lserverURL + "b/" + ngb.getKey() + "/book.xml";
            DOMUtils.createChildElement(loutdoc, element_root, "bookurl", bookAddr);
        }


        ProcessRecord process = ngp.getProcess();
        String pSynopsis = process.getSynopsis();
        String pdescription =  process.getDescription();
        Element element_goal = DOMUtils.createChildElement(loutdoc, element_root, "goal");
        DOMUtils.createChildElement(loutdoc, element_goal, "synopsis", pSynopsis);
        DOMUtils.createChildElement(loutdoc, element_goal, "description", pdescription);
        //Adding section element
        Element element_sections = DOMUtils.createChildElement(loutdoc, element_root, "sections");
        List<NGSection> sectionList = ngp.getAllSections();
        for (NGSection ngs : sectionList) {

            String secElname = ResourceSection.getSectionElementName(ngs.getName());
            if (secElname==null) {
                //if there is no translation, then skip this section
                continue;
            }
            Element element_section = DOMUtils.createChildElement(loutdoc, element_sections, secElname);
            element_section.setAttribute("id", ngs.getName());
            DOMUtils.createChildElement(loutdoc, element_section, "secname", ngs.getName());
            String secAddr = lserverURL + "p/" + ngp.getKey() + "/s/" + ngs.getName() + "/section.xml";
            DOMUtils.createChildElement(loutdoc, element_section, "url", secAddr);

            DOMUtils.createChildElement(loutdoc, element_section, "modifiedtime", UtilityMethods.getXMLDateFormat(ngs.getLastModifyTime()));
            DOMUtils.createChildElement(loutdoc, element_section, "modifieduser", String.valueOf(ngs.getLastModifyUser()));

            if("wikisection".equals(secElname)) {
                ResourceSection.loadWikiSection(loutdoc, ngs, element_section, ar, lserverURL);
            }else if("tasksection".equals(secElname)){
                ResourceSection.loadTaskSection(loutdoc, ngp, element_section, ar, lserverURL);
            }else if("attachsection".equals(secElname)){
                ResourceSection.loadAttachmentSection(loutdoc, ngs, element_section, ar, lserverURL,null);
            }else if("commentsection".equals(secElname)){
                loadSectionForNotes(loutdoc, ngs, element_section, ar, lserverURL);
            }else if("pollsection".equals(secElname)){
                ResourceSection.loadPollSection(loutdoc, ngs, element_section, ar, lserverURL);
            }else if("linksection".equals(secElname)){
                ResourceSection.loadLinkSection(loutdoc, ngs, element_section, ar, lserverURL);
            }else if("geospatialsection".equals(secElname)){
                ResourceSection.loadGeospatialSection(loutdoc, ngs, element_section, ar, lserverURL);
            }
         }

    }


    public void loadSectionForNotes(Document loutdoc, NGSection ngs, Element element_sec,
        AuthRequest au, String lserverURL)throws Exception
    {
        NGWorkspace ngc = ngs.parent;
        Element element_comments = DOMUtils.createChildElement(loutdoc, element_sec, "comments");
        for (TopicRecord note : ngc.getAllDiscussionTopics()) {

            if (note.isDraftNote()) {
                //never communicate drafts
                continue;
            }

            //can this topic be seen by the license?
            //currently the only topics that can be requested are Member and Public
            //may have other roles in the future, but for now only check if the
            //license is for Public or Member
            String licRole = license.getRole();
            int reqLevel = 1;
            if ("Members".equals(licRole)) {
                reqLevel = 2;
            }
            if (note.getVisibility()>reqLevel) {
                continue;
            }


            Element element_comment = DOMUtils.createChildElement(loutdoc, element_comments, "comment");
            element_comment.setAttribute("id",note.getId());

            String owner = note.getModUser().getUniversalId();
            if (owner==null || owner.length()==0) {
                owner = note.getOwner();
            }
            DOMUtils.createChildElement(loutdoc, element_comment, "who", owner);
            DOMUtils.createChildElement(loutdoc, element_comment, "time", UtilityMethods.getXMLDateFormat(note.getLastEdited()));
            DOMUtils.createChildElement(loutdoc, element_comment, "subject", note.getSubject());
            DOMUtils.createChildElement(loutdoc, element_comment, "content", note.getWiki());
            DOMUtils.createChildElement(loutdoc, element_comment, "universalid", note.getUniversalId());
        }
    }


    public void loadParent() throws Exception {
        ltype = NGResource.TYPE_XML;
        getPageMustExist();
        NGPageIndex ngpi = ar.getCogInstance().getWSByCombinedKeyOrFail(lid);

        String schema = lserverURL + NGResource.SCHEMA_PAGELIST;
        loutdoc = DOMUtils.createDocument("pagelist");
        Element element_root = loutdoc.getDocumentElement();
        DOMUtils.setSchemAttribute(element_root, schema);

        for (NGPageIndex pngpi : ngpi.getInLinkPages()) {
            String leafAddr = lserverURL + "p/" + pngpi.containerKey + "/leaf.xml";
            Element element_page = DOMUtils.createChildElement(loutdoc, element_root, "page");
            element_page.setAttribute("id", pngpi.containerKey);
            DOMUtils.createChildElement(loutdoc, element_page, "url", leafAddr);
        }
    }

    public void loadUserList() throws Exception
    {
        ltype = NGResource.TYPE_XML;
        NGWorkspace ngp = getPageMustExist();

        List<AddressListEntry> allUsers = ngp.getPrimaryRole().getExpandedPlayers(ngp);

        String schema = lserverURL + NGResource.SCHEMA_USERLIST;
        loutdoc = DOMUtils.createDocument("userlist");
        Element element_root = loutdoc.getDocumentElement();
        DOMUtils.setSchemAttribute(element_root, schema);

        for(AddressListEntry ale : allUsers){
            Element element_user = DOMUtils.createChildElement(loutdoc,element_root,"user");
            element_user.setAttribute("id",ale.getUniversalId());

            //This A and M notation is anachronistic.
            //This should be changed to represent members and admins in separate lists.
            if (ngp.secondaryPermission(ale))
            {
                DOMUtils.createChildElement(loutdoc,element_user,"accesslevel","A");
            }
            else
            {
                DOMUtils.createChildElement(loutdoc,element_user,"accesslevel","M");
            }
        }
    }

    public static String ACCESS_AUTHOR = "A";
    public static String ACCESS_MEMBER = "M";

    public void updateuser() throws Exception
    {
        NGWorkspace ngp = getPageMustExist();

        Element element_userlist = lindoc.getDocumentElement();
        for (Element element_user : DOMUtils.getChildElementsList(element_userlist)) {
            String userid = element_user.getAttribute("id");
            AddressListEntry ale = new AddressListEntry(userid);
            String accessreq = DOMUtils.textValueOfChild(element_user, "accesslevel", true);
            if(accessreq.equals(ACCESS_AUTHOR)
                    && ar.isAdmin()){
                ngp.addPlayerToRole("Administrators", userid);
            }
            else if(accessreq.equals(ACCESS_MEMBER)
                && ar.isMember()){
                ngp.addPlayerToRole("Members", userid);
            }
            else if(accessreq.equals(ACCESS_REMOVE)
                && ar.isAdmin()){
                //remove from both to be sure
                ngp.getSecondaryRole().removePlayer(ale);
                ngp.getPrimaryRole().removePlayer(ale);
            }
            else
            {
                throw new ProgramLogicError("update user does not understand access level: "+accessreq);
            }
        }

        ngp.saveFile(ar, "");

         //Create Status
        lrstatus.setResourceid(ngp.getKey());
        String pageAddr = lserverURL + "p/" + ngp.getKey() + "/leaf.xml";
        lrstatus.setResourceURL(pageAddr);
        lrstatus.setSuccess(NGResource.OP_SUCCEEDED);
        String cmsg = "User of Page \"" + ngp.getKey() + " is updated";
        lrstatus.setCommnets(cmsg);
        ltype = lrstatus.getType();
        loutdoc = lrstatus.getDocument();
    }

    public void performSearch(String searchText)throws Exception
    {
        ltype = NGResource.TYPE_XML;
        List<SearchResultRecord> records = DataFeedServlet.performLuceneSearchOperation(ar, searchText);
        loutdoc = DOMUtils.createDocument("searchresults");
        Element resultSetEle = loutdoc.getDocumentElement();
        String schema = lserverURL + NGResource.SCHEMA_SEARCH;
        DOMUtils.setSchemAttribute(resultSetEle, schema);
        DOMUtils.createChildElement(loutdoc,resultSetEle, "searchstring", searchText);
        DOMUtils.createChildElement(loutdoc,resultSetEle, "hitcount", String.valueOf(records.size()));
        for (SearchResultRecord sr : records) {
            Element resultEle = DOMUtils.createChildElement(loutdoc, resultSetEle, "searchrecord");
            DOMUtils.createChildElement(loutdoc, resultEle, "pagename" , sr.getPageName());
            String pageAddr = lserverURL + "p/" + sr.getPageKey() + "/leaf.xml";
            DOMUtils.createChildElement(loutdoc, resultEle, "url" , pageAddr);
            DOMUtils.createChildElement(loutdoc, resultEle, "modifieduser" , sr.getLastModifiedBy());
            DOMUtils.createChildElement(loutdoc, resultEle, "modifiedtime" , UtilityMethods.getXMLDateFormat(sr.getLastModifiedTime()));
        }

    }

    public void loadProcess() throws Exception
    {
        ltype = NGResource.TYPE_XML;
        NGWorkspace ngp = getPageMustExist();

        String schema = lserverURL + NGResource.SCHEMA_PAGE;

        ProcessRecord process = ngp.getProcess();
        loutdoc = DOMUtils.createDocument("process");
        DOMUtils.setSchemAttribute(loutdoc.getDocumentElement(), schema);
        Element processEle = loutdoc.getDocumentElement();
        String processurl = lserverURL + "p/" + ngp.getKey() + "/process.xml";
        process.fillInWfxmlProcess(loutdoc, processEle, ngp, processurl);
    }

    public void loadActivity(String activtyId) throws Exception
    {
        ltype = NGResource.TYPE_XML;
        NGWorkspace ngp = getPageMustExist();

        TaskHelper th = new TaskHelper(ar.getBestUserId(), lserverURL);
        String schema = lserverURL + NGResource.SCHEMA_TASKLIST;
        loutdoc = DOMUtils.createDocument("activities");
        Element element_root = loutdoc.getDocumentElement();
        DOMUtils.setSchemAttribute(element_root, schema);
        th.generateXPDLTaskInfo(ngp, loutdoc, element_root, activtyId);
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

    public void setResourceStatus(ResourceStatus rstatus){
        lrstatus = rstatus;
    }

    private String parsebookid(String bookaddr)
    {
        String bookid = bookaddr.trim();
        int indx1 = bookaddr.indexOf("/b/");
        int indx2 = bookaddr.indexOf("/book.xml");
        if(indx1 > 0 && indx2 > 0) {
            bookid = bookaddr.substring(indx1+3, indx2);
        }
        return bookid;
    }

    public int getStatusCode()
    {
        return statuscode;
    }

    public void loadLicense() throws Exception {
        ltype = NGResource.TYPE_XML;
        NGWorkspace ngp = getPageMustExist();

        ar.assertMember("");
        String schema = lserverURL + NGResource.SCHEMA_PAGE;
        loutdoc = DOMUtils.createDocument("licenses");
        Element element_root = loutdoc.getDocumentElement();
        DOMUtils.setSchemAttribute(element_root, schema);

        List<License> licenseList = new ArrayList<License>();
        if (licenseId == null) {
            throw new ProgramLogicError("LicenseId can not be null");
        }

        licenseId = licenseId.trim();
        if (licenseId.equals("*")) {
            licenseList = ngp.getLicenses();
        }
        else {
            List<String> lids = UtilityMethods.splitString(licenseId, ',');
            for (String id: lids) {
                License lr = ngp.getLicense(id);
                licenseList.add(lr);
            }
        }

        for (License tmpl : licenseList) {
            Element element_license = DOMUtils.createChildElement(loutdoc, element_root, "license");
            element_license.setAttribute("id", tmpl.getId());
            DOMUtils.createChildElement(loutdoc, element_license, "owner", tmpl.getCreator());
            String stime = UtilityMethods.getXMLDateFormat(tmpl.getTimeout());
            DOMUtils.createChildElement(loutdoc, element_license, "expired", stime);
            DOMUtils.createChildElement(loutdoc, element_license, "remark", tmpl.getNotes());
        }
    }

    public void createLicense() throws Exception
    {
        String newids = "";
        ltype = NGResource.TYPE_XML;
        NGWorkspace ngp = getPageMustExist();

        ar.assertMember("");

        if(licenseId == null || (!licenseId.equals("factory")))
        {
            lrstatus.setStatusCode(404);
            throw new ProgramLogicError ("To create a license you need to use factory address");
        }

        Element element_licenses = ResourceSection.findElement(lindoc.getDocumentElement(), "licenses");
        for (Element element_license : DOMUtils.getChildElementsList(element_licenses)) {
            String id = IdGenerator.generateKey();
            License lr = ngp.addLicense(id);
            lr.setCreator(ar.getBestUserId());
            String stime = DOMUtils.textValueOfChild(element_license, "expired", true);
            lr.setTimeout(UtilityMethods.getDateTimeFromXML(stime));
            String remark = DOMUtils.textValueOfChild(element_license, "remark", true);
            lr.setNotes(remark);
            newids = newids +"," + id;
            ngp.saveFile(ar, "Create License");
        }

        if(newids.startsWith(",")) {
            newids = newids.substring(1);
        }
         //Create Status
        lrstatus.setResourceid(ngp.getKey());
        String rAddr = lserverURL + "p/" + ngp.getKey()
             + "/" + NGResource.RESOURCE_LICENCE + newids
             + "/" + NGResource.DATA_LICENSE_XML;
        lrstatus.setResourceURL(rAddr);
        lrstatus.setSuccess(NGResource.OP_SUCCEEDED);
        String cmsg = "New license(s)  \"" + newids + "\" is created";
        lrstatus.setCommnets(cmsg);
        ltype = lrstatus.getType();
        loutdoc = lrstatus.getDocument();

    }

    public void deleteLicense()throws Exception {
        ltype = NGResource.TYPE_XML;
        NGWorkspace ngp = getPageMustExist();

        ar.assertMember("");

        if(licenseId == null) {
            lrstatus.setStatusCode(404);
            throw new ProgramLogicError ("To delete a license you need to use factory address");
        }

        List<String> lids = UtilityMethods.splitString(licenseId, ',');

        String newids = "";
        for(String id : lids) {
            ngp.removeLicense(id);
            newids = newids +"," + id;
        }
        if(newids.startsWith(",")) {
            newids = newids.substring(1);
        }

         //Create Status
        lrstatus.setResourceid(ngp.getKey());
        lrstatus.setSuccess(NGResource.OP_SUCCEEDED);
        String cmsg = "License(s)  \"" + newids + "\" is deleted";
        lrstatus.setCommnets(cmsg);
        ltype = lrstatus.getType();
        loutdoc = lrstatus.getDocument();
    }

    public void updateLicense() throws Exception
    {
        ltype = NGResource.TYPE_XML;
        NGWorkspace ngp = getPageMustExist();

        ar.assertMember("");
        String newids = "";

        if(licenseId == null)
        {
            lrstatus.setStatusCode(404);
            throw new ProgramLogicError ("To update a license you need to use factory address");
        }

        List<String> lids = UtilityMethods.splitString(licenseId, ',');

        Element element_licenses = ResourceSection.findElement(lindoc.getDocumentElement(), "licenses");
        for (Element element_license : DOMUtils.getChildElementsList(element_licenses)) {
            String id = element_license.getAttribute("id");
            boolean doupdate = false;
            for(String lid : lids) {
                if(lid.equals(id)) {
                    doupdate = true;
                    break;
                }
            }
            if(doupdate){
                License lr = ngp.getLicense(id);
                lr.setCreator(ar.getBestUserId());
                String stime = DOMUtils.textValueOfChild(element_license, "expired", true);
                lr.setTimeout(UtilityMethods.getDateTimeFromXML(stime));
                String remark = DOMUtils.textValueOfChild(element_license, "remark", true);
                lr.setNotes(remark);
                newids = newids +"," + id;
                ngp.saveFile(ar, "Create License");
            }
        }

        if(newids.startsWith(",")) {
            newids = newids.substring(1);
        }
         //Create Status
        lrstatus.setResourceid(ngp.getKey());
        String rAddr = lserverURL + "p/" + ngp.getKey()
             + "/" + NGResource.RESOURCE_LICENCE + newids
             + "/" + NGResource.DATA_LICENSE_XML;
        lrstatus.setResourceURL(rAddr);
        lrstatus.setSuccess(NGResource.OP_SUCCEEDED);
        String cmsg = "license(s)  \"" + newids + "\" is updated";
        lrstatus.setCommnets(cmsg);
        ltype = lrstatus.getType();
        loutdoc = lrstatus.getDocument();

    }

    public void setLicenseId(String id)
    {
        licenseId = id;
        if(licenseId != null) {
            licenseId = licenseId.trim();
        }
    }

}
