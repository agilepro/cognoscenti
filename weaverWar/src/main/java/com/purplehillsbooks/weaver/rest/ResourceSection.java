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
import com.purplehillsbooks.weaver.AttachmentRecord;
import com.purplehillsbooks.weaver.AuthRequest;
import com.purplehillsbooks.weaver.DOMFace;
import com.purplehillsbooks.weaver.DOMUtils;
import com.purplehillsbooks.weaver.GoalRecord;
import com.purplehillsbooks.weaver.HistoryRecord;
import com.purplehillsbooks.weaver.IdGenerator;
import com.purplehillsbooks.weaver.License;
import com.purplehillsbooks.weaver.LicensedURL;
import com.purplehillsbooks.weaver.NGPageIndex;
import com.purplehillsbooks.weaver.NGSection;
import com.purplehillsbooks.weaver.NGWorkspace;
import com.purplehillsbooks.weaver.ProcessRecord;
import com.purplehillsbooks.weaver.SectionForNotes;
import com.purplehillsbooks.weaver.SectionLink;
import com.purplehillsbooks.weaver.TopicRecord;
import com.purplehillsbooks.weaver.UtilityMethods;
import com.purplehillsbooks.weaver.exception.NGException;
import com.purplehillsbooks.weaver.exception.ProgramLogicError;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;

public class ResourceSection  implements NGResource
{
    private Document loutdoc;
    private Document lindoc;
    private String lname;
    private String lid;
    private String ltype;
    private String lfile;
    private String lserverURL;
    private ResourceStatus lrstatus;
    private AuthRequest lar;
    private String lpageid;
    private int statuscode = 200;
    private ResourcePage lrp;
    private String nlid = "";

    public ResourceSection(String serverURL,AuthRequest ar, ResourcePage rp, ResourceStatus rstatus, Document doc)
    {
        lserverURL = serverURL;
        lar= ar;
        lrp = rp;
        lrstatus = rstatus;
        lindoc = doc;
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

    public void setPageId(String id)
    {
        lpageid = id;
    }

    public void setName(String name)
    {
        lname = name;
    }

    public void setId(String id)
    {
        if(id != null) {
            lid = id.trim();
        }
    }


    public void loadSection() throws Exception
    {
        ltype = NGResource.TYPE_XML;
        NGPageIndex ngpi = lar.getCogInstance().getWSByCombinedKeyOrFail(lpageid);
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
        lar.setPageAccessLevels(ngp);

        NGSection ngs = ngp.getSection(lname);

        if(ngs == null)
        {
            lrstatus.setStatusCode(404);
            throw new NGException("nugen.exception.section.not.exist", new Object[]{lname});
        }

        String schema = lserverURL + getSchema(ngs.getName());
        String secElname = getSectionElementName(lname);
        if (null == secElname) {
            //there is no corresponding element for this section, so ignore it
            return;
        }
        loutdoc = DOMUtils.createDocument(secElname);
        Element element_section = loutdoc.getDocumentElement();
        element_section.setAttribute("id", ngs.getName());
        DOMUtils.setSchemAttribute(element_section, schema);

        DOMUtils.createChildElement(loutdoc, element_section, "secname", ngs.getName());
        String secAddr = lserverURL + "p/" + ngp.getKey() + "/s/" + ngs.getName() + "/section.xml";
        DOMUtils.createChildElement(loutdoc, element_section, "url", secAddr);
        DOMUtils.createChildElement(loutdoc, element_section, "modifiedtime", UtilityMethods.getXMLDateFormat(ngs.getLastModifyTime()));
        DOMUtils.createChildElement(loutdoc, element_section, "modifieduser", ngs.getLastModifyUser());

        loadDataContent(ngs,element_section,null);
    }

    public void createSection() throws Exception
    {
        ltype = NGResource.TYPE_XML;
        NGWorkspace ngp = lrp.getPageMustExist();
        lar.setPageAccessLevels(ngp);
        lar.assertAdmin("Must be an admin of the page in order to add a new section");
        if(lname != null && lname.length()>0
            && ngp.getSection(lname) == null){
                throw new Exception("code to create sections has been removed.  Protocol no longer supports creating sections");
        }

        NGSection ngs = ngp.getSectionOrFail(lname);

        Element element_section = lindoc.getDocumentElement();
        updateDataContent(ngp,ngs,element_section);

        ngp.saveFile(lar,"Section Created");

        //Create Status
        lrstatus.setResourceid(ngp.getKey());
        String secAddr = lserverURL + "p/" + ngp.getKey() + "/s/" + lname + "/section.xml";
        lrstatus.setResourceURL(secAddr);
        lrstatus.setSuccess(NGResource.OP_SUCCEEDED);
        String cmsg = "A new Section \"" + lname + "\" is created";
        lrstatus.setCommnets(cmsg);
        ltype = lrstatus.getType();
        loutdoc = lrstatus.getDocument();
    }


    public void updateSection() throws Exception
    {
        ltype = NGResource.TYPE_XML;
        NGWorkspace ngp = lrp.getPageMustExist();
        lar.setPageAccessLevels(ngp);
        if(!lar.isMember())
        {
            throw new NGException("nugen.exception.not.enough.permission", null);
        }

        NGSection ngs = ngp.getSectionOrFail(lname);
        Element element_section = lindoc.getDocumentElement();
        updateDataContent(ngp,ngs,element_section);

        ngp.saveFile(lar,"Update Section");
         //Create Status
        lrstatus.setResourceid(ngp.getKey());
        String secAddr = lserverURL + "p/" + ngp.getKey() + "/s/" + lname + "/section.xml";
        lrstatus.setResourceURL(secAddr);
        lrstatus.setSuccess(NGResource.OP_SUCCEEDED);
        String cmsg = "Section \"" + lname + "\" is modified.";
        lrstatus.setCommnets(cmsg);
        ltype = lrstatus.getType();
        loutdoc = lrstatus.getDocument();
    }

    public void loadData() throws Exception
    {
        ltype = NGResource.TYPE_XML;
        NGWorkspace ngp = lrp.getPageMustExist();
        lar.setPageAccessLevels(ngp);

        NGSection ngs = ngp.getSectionOrFail(lname);

        String schema = lserverURL + getSchema(ngs.getName());
        loutdoc = DOMUtils.createDocument("section");
        Element element_section = loutdoc.getDocumentElement();
        element_section.setAttribute("id", ngs.getName());
        DOMUtils.setSchemAttribute(element_section, schema);

        DOMUtils.createChildElement(loutdoc, element_section, "name", ngs.getName());
        String secAddr = lserverURL + "p/" + ngp.getKey() + "/s/" + ngs.getName() + "/section.xml";
        DOMUtils.createChildElement(loutdoc, element_section, "url", secAddr);
        DOMUtils.createChildElement(loutdoc, element_section, "modifiedtime", String.valueOf(ngs.getLastModifyTime()));
        DOMUtils.createChildElement(loutdoc, element_section, "modifieduser", String.valueOf(ngs.getLastModifyUser()));

        loadDataContent(ngs,element_section,lid);
    }

    public void createData() throws Exception
    {
        updateData();
    }
    public void updateData() throws Exception
    {
        ltype = NGResource.TYPE_XML;
        NGWorkspace ngp = lrp.getPageMustExist();
        NGSection ngs = ngp.getSection(lname);
        if(ngs == null){
            lrstatus.setStatusCode(404);
            throw new NGException("nugen.exception.section.not.exist", new Object[]{lname});
        }

        if(!lar.isLoggedIn())
        {
            lrstatus.setStatusCode(401);
            throw new NGException("nugen.exception.login.to.edit",null);
        }
        lar.setPageAccessLevels(ngp);
        boolean isEditable = ngp.primaryOrSecondaryPermission(lar.getUserProfile());
        if(!isEditable)
        {
            lrstatus.setStatusCode(401);
            throw new NGException("nugen.exception.not.enough.permission", null);
        }

        Element element_section = lindoc.getDocumentElement();
        updateDataContent(ngp,ngs,element_section);

        ngp.saveFile(lar,"Update Data");
         //Create Status
        if(nlid.length() >0){
            lrstatus.setResourceid(nlid);
        }else{
            lrstatus.setResourceid(ngp.getKey());
        }
        String secAddr = lserverURL + "p/" + ngp.getKey() + "/s/" + lname + "/section.xml";
        lrstatus.setResourceURL(secAddr);
        lrstatus.setSuccess(NGResource.OP_SUCCEEDED);
        String cmsg = "Section \"" + lname + " is modified for ids:" + lid;
        lrstatus.setCommnets(cmsg);
        ltype = lrstatus.getType();
        loutdoc = lrstatus.getDocument();
    }



    private void loadDataContent(NGSection ngs, Element element_section, String dataIds) throws Exception
    {
        NGWorkspace ngp = ngs.parent;

        //TODO: eliminate this since there are no more variable sections
         if(ngs.getName().equals("Description")
            || ngs.getName().equals("Public Description")
            || ngs.getName().equals("Notes")
            || ngs.getName().equals("Author Notes")
            || ngs.getName().equals("Public Content")
            || ngs.getName().equals("Member Content")
            || ngs.getName().equals("Content")
            || ngs.getName().equals("XXX Notes") ) {

            loadWikiSection(loutdoc, ngs, element_section, lar, lserverURL);

        }else if(ngs.getName().equals("Tasks")){
            if(dataIds != null){
                loadTaskData(dataIds);
            }else{
                ResourceSection.loadTaskSection(loutdoc, ngp, element_section, lar, lserverURL);
            }
        }else if(ngs.getName().equals("Attachments")
            || ngs.getName().equals("Public Attachments")){
            ResourceSection.loadAttachmentSection(loutdoc, ngs, element_section, lar, lserverURL, dataIds);
        }else if(ngs.getName().equals("Public Comments")
            || ngs.getName().equals("Comments")){
            lrp.loadSectionForNotes(loutdoc, ngs, element_section, lar, lserverURL);
        }else if(ngs.getName().equals("Poll")){
            ResourceSection.loadPollSection(loutdoc, ngs, element_section, lar, lserverURL);
        }else if(ngs.getName().equals("See Also")
            || ngs.getName().equals("Public Links")
            || ngs.getName().equals("Links")){
            ResourceSection.loadLinkSection(loutdoc, ngs, element_section, lar, lserverURL);
        }else if(ngs.getName().equals("Geospatial")){
            ResourceSection.loadGeospatialSection(loutdoc, ngs, element_section, lar, lserverURL);
        }
    }

    private void updateDataContent(NGWorkspace ngp, NGSection ngs, Element element_section) throws Exception
    {

        //TODO: change this to use the SectionDefinition/SectionFormat
        if(ngs.getName().equals("Description")
                || ngs.getName().equals("Public Description")
                || ngs.getName().equals("Notes")
                || ngs.getName().equals("Author Notes")
                || ngs.getName().equals("Public Content")
                || ngs.getName().equals("Member Content")
                || ngs.getName().equals("Content")
                || ngs.getName().equals("XXX Notes") ) {

                ResourceSection.updateWikiSection(ngp, ngs,element_section, lar);
        }else if(ngs.getName().equals("Tasks")){
            nlid = ResourceSection.updateTaskSection(ngp, ngs,element_section, lar);
        }else if(ngs.getName().equals("Attachments")
            || ngs.getName().equals("Public Attachments")){
            ResourceSection.updateAttachmentSection(ngp, ngs,element_section, lar);
        }else if(ngs.getName().equals("Public Comments")
            || ngs.getName().equals("Comments")){
            ResourceSection.updateCommentSection(ngp, ngs,element_section, lar);
        }else if(ngs.getName().equals("See Also")
            || ngs.getName().equals("Public Links")
            || ngs.getName().equals("Links")){
            ResourceSection.updateLinkSection(ngp, ngs,element_section);
        }
    }

    public void loadSubprocess() throws Exception {
    }

    public void loadTaskList(String filter) throws Exception {
        ltype = NGResource.TYPE_XML;
        TaskHelper th = new TaskHelper(lar.getBestUserId(), lserverURL);
        th.scanAllTask(lar.getCogInstance());

        String schema = lserverURL + NGResource.SCHEMA_TASKLIST;
        loutdoc = DOMUtils.createDocument("activities");
        Element element_root = loutdoc.getDocumentElement();
        DOMUtils.setSchemAttribute(element_root, schema);

        th.fillInTaskList(loutdoc, element_root, filter);
    }
    public void loadHistory()throws Exception
    {
        ltype = NGResource.TYPE_XML;
        ltype = NGResource.TYPE_XML;
        NGPageIndex ngpi = lar.getCogInstance().getWSByCombinedKeyOrFail(lpageid);
        if (ngpi==null)
        {
            throw new NGException("nugen.exception.page.not.found",new Object[]{lid});
        }
        if (!ngpi.isWorkspace())
        {
            throw new NGException("nugen.exception.project.not.found",new Object[]{lid});
        }
        NGWorkspace ngp = ngpi.getWorkspace();
        lar.setPageAccessLevels(ngp);

        String schema = lserverURL + NGResource.SCHEMA_SECTION_HISTORY;
        loutdoc = DOMUtils.createDocument("history");
        Element element_root = loutdoc.getDocumentElement();
        DOMUtils.setSchemAttribute(element_root, schema);
        String processurl = lserverURL + "p/" + ngp.getKey() + "/process.xml";
        DOMUtils.createChildElement(loutdoc, element_root, "processurl", processurl);

        List<HistoryRecord> histRecs = ngp.getAllHistory();
        for (HistoryRecord history : histRecs)
        {
            fillInWfxmlHistory(history, loutdoc, element_root);
        }
    }
    
    public static void fillInWfxmlHistory(HistoryRecord history, Document doc, Element histEle)  throws Exception
    {
        if (doc == null)
        {
            throw new ProgramLogicError("Null doc parameter passed to fillInWfxmlHistory");
        }
        if (histEle == null)
        {
            throw new ProgramLogicError("Null histEle parameter passed to fillInWfxmlHistory");
        }

        //this code constructs XML for the WfXML protocol
        Element eventEle = DOMUtils.createChildElement(doc, histEle, "event");
        eventEle.setAttribute("id", history.getId());
        DOMUtils.createChildElement(doc, eventEle, "type", String.valueOf(history.getEventType()));
        DOMUtils.createChildElement(doc, eventEle, "context", String.valueOf(history.getContext()));
        DOMUtils.createChildElement(doc, eventEle, "contexttype", String.valueOf(history.getContextType()));
        DOMUtils.createChildElement(doc, eventEle, "responsible", history.getResponsible());
        DOMUtils.createChildElement(doc, eventEle, "timestamp", UtilityMethods.getXMLDateFormat(history.getTimeStamp()));
        DOMUtils.createChildElement(doc, eventEle, "comments", String.valueOf(history.getComments()));
    }


    public static void loadWikiSection(Document loutdoc, NGSection ngs, Element element_sec,
        AuthRequest au, String lserverURL)throws Exception
    {
        String content = ngs.asText().trim();
        DOMUtils.createChildElement(loutdoc, element_sec, "content", content);
    }

    public static void loadGeospatialSection(Document loutdoc, NGSection ngs, Element element_sec,
        AuthRequest au, String lserverURL)throws Exception
    {
        Element element_geo = DOMUtils.getChildElement(ngs.getElement(), "geospatial");
        if(element_geo != null){
            Node tempNode = loutdoc.importNode(element_geo, true);
            element_sec.appendChild(tempNode);
        }
    }

    public static void loadAttachmentSection(Document loutdoc, NGSection ngs, Element element_sec,
        AuthRequest lar, String lserverURL, String dataIds)throws Exception
    {
        Element sec_attchments = DOMUtils.createChildElement(loutdoc, element_sec, "attachments");

        NGWorkspace ngw = (NGWorkspace) ngs.parent;

        List<AttachmentRecord> allAtts = ngw.getAllAttachments();

        for (AttachmentRecord arec : allAtts) {

            String id = arec.getId();
            if(!isRequested(id, dataIds)) {
                continue;
            }
            String attachmentType = arec.getType();
            if (!"FILE".equals(attachmentType) && !"URL".equals(attachmentType)) {
                //only include files and URL types.  do NOT include GONE, DELETED, or EXTRA files
                continue;
            }
            if (arec.isDeleted()) {
                //skip any deleted files
                continue;
            }


            Element sec_attchment = DOMUtils.createChildElement(loutdoc, sec_attchments, "attachment");
            sec_attchment.setAttribute("id", id);

            //TODO: temporary just get the very first license in the list ... do better later
            NGWorkspace ngp = (NGWorkspace)ngw;
            License lr = ngp.getLicenses().get(0);

            String permaLink = arec.getLicensedAccessURL(lar, (NGWorkspace)ngw, lr.getId());
            DOMUtils.createChildElement(loutdoc, sec_attchment, "address", permaLink);

            DOMUtils.createChildElement(loutdoc, sec_attchment, "universalid", arec.getUniversalId());
            DOMUtils.createChildElement(loutdoc, sec_attchment, "remark", arec.getDescription());
            DOMUtils.createChildElement(loutdoc, sec_attchment, "name", arec.getNiceName());

            if ("FILE".equals(attachmentType)) {
                String size = Long.toString(arec.getFileSize(ngw));
                DOMUtils.createChildElement(loutdoc, sec_attchment, "size", size);
            }

            String ftype = arec.getType();
            DOMUtils.createChildElement(loutdoc, sec_attchment, "type", ftype);

            long modDate = arec.getModifiedDate();
            String xmlDate = UtilityMethods.getXMLDateFormat(modDate);
            DOMUtils.createChildElement(loutdoc, sec_attchment, "modifiedtime", xmlDate);

            String modBy = arec.getModifiedBy();
            DOMUtils.createChildElement(loutdoc, sec_attchment, "modifieduser", modBy);

        }
    }

    public static void loadLinkSection(Document loutdoc, NGSection ngs, Element element_sec,
            AuthRequest ar, String lserverURL)throws Exception {
        Element element_links = DOMUtils.createChildElement(loutdoc, element_sec, "links");

        SectionLink secLnk = (SectionLink) ngs.getFormat();
        List<String> v = new ArrayList<String>();
        secLnk.findLinks(v,ngs);
        for(String thisLine : v) {
            makeLink(loutdoc, ngs, element_links, thisLine, lserverURL, ar);
        }
    }
    private static void makeLink(Document loutdoc, NGSection ngs, Element element_links,
        String linkURL, String lserverURL, AuthRequest ar) throws Exception
    {
        Element element_link = DOMUtils.createChildElement(loutdoc, element_links, "link");
        int barPos = linkURL.indexOf("|");
        String linkName = linkURL;
        String linkAddr = linkURL;

        if (barPos >= 0) {
            linkName = linkURL.substring(0,barPos);
            linkAddr = linkURL.substring(barPos+1);
        }
        boolean isExternal = linkAddr.startsWith("http");
        if (!isExternal)
        {
            NGPageIndex foundPI = ar.getCogInstance().getWSByCombinedKeyOrFail(linkAddr);
            if (foundPI!=null && foundPI.isWorkspace())
            {
                NGWorkspace ngp = foundPI.getWorkspace();
                linkAddr = lserverURL + "p/" + ngp.getKey() + "/leaf.xml";
            }
        }
        element_link.setAttribute("id", "");
        DOMUtils.createChildElement(loutdoc, element_link, "name", linkName);
        DOMUtils.createChildElement(loutdoc, element_link, "url", linkAddr);
    }


    public static void loadTaskSection(Document loutdoc, NGWorkspace ngp, Element element_sec,
        AuthRequest au, String lserverURL)throws Exception
    {
        ProcessRecord process = ngp.getProcess();
        Element element_process = DOMUtils.createChildElement(loutdoc, element_sec, "process");
        String processurl = lserverURL + "p/" + ngp.getKey() + "/process.xml";
        process.fillInWfxmlProcess(loutdoc,element_process, ngp, processurl);

    }

    public static void loadPollSection(Document loutdoc, NGSection ngs, Element element_sec,
        AuthRequest au, String lserverURL)throws Exception
    {
        Element element_polls = DOMUtils.createChildElement(loutdoc, element_sec, "polls");
        List<Element> polllist = DOMUtils.getNamedChildrenVector(ngs.getElement(), "poll");
        for (Element pollElement : polllist) {
            Element element_poll = DOMUtils.createChildElement(loutdoc, element_polls, "poll");
            String id = pollElement.getAttribute("id");
            element_poll.setAttribute("id", id);
            String proposition = DOMUtils.getChildText(pollElement, "proposition").trim();
            DOMUtils.createChildElement(loutdoc, element_poll, "proposition", proposition);

            NodeList nl = DOMUtils.findNodesOneLevel(pollElement, "vote");
            for (int i=0; i<nl.getLength(); i++) {
                Element element_vote = DOMUtils.createChildElement(loutdoc, element_poll, "vote");
                Element voteElement  = (Element)nl.item(i);
                if (voteElement == null) {
                    continue; // there are strange cases where it can be null
                }
                String who = DOMUtils.getChildText(voteElement, "who").trim();
                DOMUtils.createChildElement(loutdoc, element_vote, "who", who);
                String choice = DOMUtils.getChildText(voteElement, "choice").trim();
                DOMUtils.createChildElement(loutdoc, element_vote, "choice", choice);
                String comment = DOMUtils.getChildText(voteElement, "comment").trim();
                DOMUtils.createChildElement(loutdoc, element_vote, "comment", comment);
                String time = DOMUtils.getChildText(voteElement, "time").trim();
                DOMUtils.createChildElement(loutdoc, element_vote, "time", time);
            }
        }
    }


    private String getSchema(String name)
    {
        String schema_name = "";
        if(name.equals("Description")
            || name.equals("Public Description")
            || name.equals("Notes")
            || name.equals("Author Notes")
            || name.equals("Public Content")
            || name.equals("Member Content")
            || name.equals("Content")
            || name.equals("XXX Notes") ) {

            schema_name = NGResource.SCHEMA_SECTION_WIKI;
        }else if(name.equals("Tasks")){
            schema_name = NGResource.SCHEMA_SECTION_TASKS;
        }else if(name.equals("Attachments")
            || name.equals("Public Attachments")){
            schema_name = NGResource.SCHEMA_SECTION_ATTTACH;
        }else if(name.equals("Private")
            || name.equals("Private Locker")){
             schema_name = NGResource.SCHEMA_SECTION_WIKI;
        }else if(name.equals("Public Comments")
            || name.equals("Comments")){
             schema_name = NGResource.SCHEMA_SECTION_COMMENT;
        }else if(name.equals("Poll")){
            schema_name = NGResource.SCHEMA_SECTION_POLL;
        }else if(name.equals("See Also")
            || name.equals("Public Links")
            || name.equals("Links")){
            schema_name = NGResource.SCHEMA_SECTION_LINK;
        }else if(name.equals("Geospatial")){
            schema_name = NGResource.SCHEMA_GEOSPATIAL;
        }

        return schema_name;
    }

    public static void updateWikiSection(NGWorkspace ngp, NGSection ngs,
        Element secInput, AuthRequest ar) throws Exception
    {
        Element element_content = findElement(secInput, "content");
        if(element_content != null)
        {
            String content = DOMUtils.textValueOf(element_content, true);
            ngs.setScalar("wiki", content);
        }
    }

    public static void updateAttachmentSection(NGWorkspace ngp, NGSection ngs,
        Element secInput, AuthRequest ar) throws Exception
    {
        Element element_attachments = findElement(secInput, "attachments");

        if(element_attachments == null) {
            //nothing to do, so just return
            return;
        }
        for (Element element_attachment : DOMUtils.getChildElementsList(element_attachments)) {
            String id = element_attachment.getAttribute("id");
            String resource = DOMUtils.textValueOfChild(element_attachment, "address", true);
            String comment = DOMUtils.textValueOfChild(element_attachment, "remark", true);
            String name = DOMUtils.textValueOfChild(element_attachment, "name", true);
            String type = DOMUtils.textValueOfChild(element_attachment, "type", true);
            AttachmentRecord arecord = ngp.findAttachmentByID(id.trim());
            if(arecord == null) { // Need to create the attachment
                arecord = ngp.createAttachment();
                arecord.setDescription(comment);
                arecord.setModifiedBy(ar.getBestUserId());
                arecord.setModifiedDate(ar.nowTime);
            }

            if (name != null && name.length() > 0) {
                arecord.setDisplayName(name);
            }
            if(type != null && type.length() > 0) {
                arecord.setType(type);
            }
            if(comment != null && comment.length() > 0) {
                arecord.setDescription(comment);
            }
            if(resource != null && resource.length() > 0) {
                arecord.setURLValue(resource);
            }
            arecord.setModifiedBy(ar.getBestUserId());
            arecord.setModifiedDate(ar.nowTime);
        }
        ngs.setLastModify(ar);
    }

    public static String updateTaskSection(NGWorkspace ngp, NGSection ngs,
        Element secInput, AuthRequest ar) throws Exception
    {
        String newids = "";
        Element element_process = findElement(secInput, "process");
        if(element_process != null)
        {
            ProcessRecord process = ngp.getProcess();
            String synopsis = DOMUtils.textValueOfChild(element_process, "synopsis", true);
            if(synopsis != null && synopsis.length()> 0){
                process.setSynopsis(synopsis);
            }
            String description = DOMUtils.textValueOfChild(element_process, "description", true);
            if(description != null && description.length()> 0){
                process.setDescription(description);
            }
            String state = DOMUtils.textValueOfChild(element_process, "state", true);
            if(state != null && state.length()> 0){
                process.setState(Integer.parseInt(state));
            }
            String priority = DOMUtils.textValueOfChild(element_process, "priroty", true);
            if(priority != null && priority.length()> 0){
                process.setPriority(Integer.parseInt(priority));
            }
            String duedate = DOMUtils.textValueOfChild(element_process, "duedate", true);
            if(duedate != null && duedate.length()> 0){
                process.setDueDate(UtilityMethods.getDateTimeFromXML(duedate));
            }

            String startdate = DOMUtils.textValueOfChild(element_process, "startdate", true);
            if(startdate  != null && startdate.length()> 0){
                process.setStartDate(UtilityMethods.getDateTimeFromXML(startdate));
            }

            String enddate = DOMUtils.textValueOfChild(element_process, "enddate", true);
            if(enddate  != null && enddate.length()> 0){
                process.setEndDate(UtilityMethods.getDateTimeFromXML(enddate));
            }

            Element parentElem = DOMUtils.getChildElement(element_process, "parentprocesses");
            if(parentElem != null){
                List<String> purlList = new ArrayList<String>();
                for (Element element_url : DOMUtils.getChildElementsList(parentElem)) {
                    String purl = DOMUtils.textValueOf(element_url, true);
                    if(purl != null && purl.length() >0) {
                        purlList.add(purl);
                    }
                }
                LicensedURL[] lps = new LicensedURL[purlList.size()];
                int i=0;
                for (String oneUrl : purlList) {
                    lps[i++] = new LicensedURL(oneUrl);
                }
                process.setLicensedParents(lps);
            }

            ngs.setLastModify(ar);
        }

        Element element_activities = null;
        if(element_process != null){
            element_activities = DOMUtils.getChildElement(element_process,"activities");
        }else{
            element_activities =  findElement(secInput, "activities");
        }

        if(element_activities != null){
            for (Element element_task : DOMUtils.getChildElementsList(element_activities)) {
                String tid =  element_task.getAttribute("id");
                GoalRecord gr = null;
                if (tid == null || tid.length() == 0 || tid.equals("factory")) {
                    // Need to create the attachment
                    gr = ngp.createGoal(ar.getBestUserId());
                    gr.setState(GoalRecord.STATE_OFFERED);
                }
                else {
                    gr = ngp.getGoalOrFail(tid);
                }

                //synopsis,description,state,assignee,subprocess,actionscripts,
                //progress,priority,duedate,startdate,duration,enddate,rank,accomp
                newids = newids + ", " + gr.getId();
                String tsynopsis = defText(element_task, "synopsis", "");
                if(tsynopsis != null && tsynopsis.length()> 0){
                    gr.setSynopsis(tsynopsis );
                }
                String tdescription = defText(element_task,"description", "");
                if(tdescription != null && tdescription.length()> 0){
                    gr.setDescription(tdescription );
                }
                String tstate = defText(element_task, "state", "");
                if(tstate != null && tstate.length()> 0){
                     gr.setState(Integer.parseInt(tstate));
                }
                String tassignee = defText(element_task,"assignee", "");
                if(tassignee != null && tassignee.length()> 0){
                    gr.setAssigneeCommaSeparatedList(tassignee );
                }

                Element subEle = DOMUtils.getChildElement(element_task, "subprocess");
                String tsubkey = defText(subEle, "subkey", "");
                if(tsubkey != null && tsubkey.length()> 0){
                     gr.setSub(tsubkey);
                }
                String tascripts = defText(element_task, "actionscripts", "");
                if(tascripts != null && tascripts.length()> 0){
                    gr.setActionScripts(tascripts );
                }
                String tstatus = defText(element_task, "progress","");
                if(tstatus != null && tstatus.length()> 0){
                    gr.setStatus(tstatus );
                }
                String tpriority = defText(element_task, "priority", "");
                if(tpriority !=null && tpriority.length() >0){
                    gr.setPriority(Integer.parseInt(tpriority));
                }

                String tdueDate = defText(element_task, "duedate", "");
                if (tdueDate!=null && tdueDate.length()> 0 )
                {
                    gr.setDueDate(UtilityMethods.getDateTimeFromXML(tdueDate));
                }
                String tstartDate = defText(element_task, "startdate", "");
                if(tstartDate != null && tstartDate.length()> 0){
                     gr.setStartDate(UtilityMethods.getDateTimeFromXML(tstartDate));
                }
                String tendDate = defText(element_task, "enddate", "");
                if(tendDate != null && tendDate.length()> 0){
                     gr.setEndDate(UtilityMethods.getDateTimeFromXML(tendDate));
                }

                String trank = defText(element_task, "rank", "");
                if(trank !=null && trank.length() >0){
                    gr.setRank(Integer.parseInt(trank));
                }
                String duration = defText(element_task, "duration", "");
                if(duration !=null && duration.length() >0){
                    gr.setDuration(DOMFace.safeConvertLong(duration));
                }
                String creator = defText(element_task,"creator", "");
                if(creator != null && creator.length()> 0){
                    gr.setCreator(creator );
                }
            }
            ngs.setLastModify(ar);
        }

        if(newids.startsWith(",")) {
            newids = newids.substring(1);
        }

        return newids;
    }

    public static void updateCommentSection(NGWorkspace ngp, NGSection ngs,
        Element secInput, AuthRequest ar) throws Exception
    {
        Element element_cmts = findElement(secInput, "comments");

        if(element_cmts != null){
             for (Element element_cmt : DOMUtils.getChildElementsList(element_cmts)) {
                String id = element_cmt.getAttribute("id");
                String subject = DOMUtils.textValueOfChild(element_cmt, "subject", true);
                String data = DOMUtils.textValueOfChild(element_cmt, "content", true);

                TopicRecord note = ngp.getDiscussionTopic(id);
                if(note == null)
                {
                    addLeaflet(ar, ngs, subject, data);
                }
                else
                {
                    note.setLastEdited(ar.nowTime);
                    note.setSubject(subject);
                    note.setWiki(data);
                }
            }
        }
    }


    public static TopicRecord addLeaflet(AuthRequest ar, NGSection section,
            String subject, String data) throws Exception {
        String id = IdGenerator.generateKey();
        TopicRecord newNote = section.createChildWithID(
                SectionForNotes.LEAFLET_NODE_NAME, TopicRecord.class, "id", id);
        newNote.setOwner(ar.getBestUserId());
        newNote.setModUser(new AddressListEntry(ar.getBestUserId()));
        newNote.setLastEdited(ar.nowTime);
        newNote.setSubject(subject);
        newNote.setWiki(data);
        return newNote;
    }


    public static void updateLinkSection(NGWorkspace ngp, NGSection ngs,
        Element secInput) throws Exception
    {
        String linkText = "";
        Element element_links = findElement(secInput, "links");
        if(element_links != null){
            for (Element element_link : DOMUtils.getChildElementsList(element_links)) {
                String link = "";
                String name = DOMUtils.textValueOfChild(element_link, "name", true);
                if(name !=null && name.length() >0) {
                    link = link + name + "|";
                }
                link = link + DOMUtils.textValueOfChild(element_link, "url", true);
                if(linkText.length() == 0) {
                    linkText = link;
                }
                else{
                    linkText = linkText + "\n" + link;
                }
            }
        }
        ngs.setScalar("wiki", linkText);

    }

    private static String defText(Element pelem, String pelem_name, String defaultValue) throws Exception
    {
        String val = DOMUtils.textValueOfChild(pelem, pelem_name, true);
        if (val == null || val.length() == 0) {
            return defaultValue;
        }
        // this next line should not be needed, but I have seen this hack recommended
        // in many forums.
        String modVal = new String(val.getBytes("iso-8859-1"), "UTF-8");
        return modVal;
    }

    private static boolean isRequested(String id, String dataIds) throws Exception {
        if(dataIds == null) {
            return true;
        }
        List<String> idList = UtilityMethods.splitString(dataIds,',');
        for(String oneId : idList) {
            if(id.equalsIgnoreCase(oneId)) {
                return true;
            }
        }
        return false;
    }

    public int getStatusCode() {
        return statuscode;
    }

    public static String getSectionElementName(String name) throws Exception {
        if(name == null) {
            throw new ProgramLogicError("Section name can not be null.");
        }
        name = name.trim();
        if(name.equals("Description")
            || name.equals("Public Description")
            || name.equals("Notes")
            || name.equals("Author Notes")
            || name.equals("Public Content")
            || name.equals("Member Content")
            || name.equals("Content")
            || name.equals("XXX Notes") ) {
            return "wikisection";
        }else if(name.equals("Tasks")){
            return "tasksection";
        }else if(name.equals("Attachments")
            || name.equals("Public Attachments")){
            return "attachsection";
        }else if(name.equals("Private")
            || name.equals("Private Locker")){
             return "privatesection";
        }else if(name.equals("Public Comments")
            || name.equals("Comments")){
             return "commentsection";
        }else if(name.equals("Poll")){
            return "pollsection";
        }else if(name.equals("See Also")
            || name.equals("Public Links")
            || name.equals("Links")){
            return "linksection";
        }else if(name.equals("Geospatial")){
            return "geospatialsection";
        }
        else{
            return null;
        }
    }

    private  void loadTaskData(String dataIds) throws Exception {
        ltype = NGResource.TYPE_XML;
        NGPageIndex ngpi = lar.getCogInstance().getWSByCombinedKeyOrFail(lpageid);
        if (ngpi==null) {
            lrstatus.setStatusCode(404);
            throw new NGException("nugen.exception.page.not.found",new Object[]{lid});
        }
        if (!ngpi.isWorkspace()) {
            lrstatus.setStatusCode(404);
            throw new NGException("nugen.exception.project.not.found",new Object[]{lid});
        }
        NGWorkspace ngp = ngpi.getWorkspace();
        lar.setPageAccessLevels(ngp);

        TaskHelper th = new TaskHelper(lar.getBestUserId(), lserverURL);
        String schema = lserverURL + NGResource.SCHEMA_TASKLIST;
        loutdoc = DOMUtils.createDocument("activities");
        Element element_root = loutdoc.getDocumentElement();
        DOMUtils.setSchemAttribute(element_root, schema);
        th.generateXPDLTaskInfo(ngp, loutdoc, element_root, dataIds);
    }

    public static Element findElement(Element parent, String expr) throws Exception
    {
        String lclNm = parent.getLocalName() ;
        String fullNm = parent.getNodeName() ;
        if ((lclNm != null && lclNm.equals(expr)) ||
            (fullNm != null && fullNm.equals(expr))) {
                return parent;
        }
        Element child = DOMUtils.getChildElement(parent, expr);
        if(child != null){
            return child;
        }

        NodeList nList = DOMUtils.findNodesOneLevel(parent, expr);
        if(nList != null && nList.getLength() > 0){
            return (Element)nList.item(0);
        }else{
            return null;
        }
    }

}
