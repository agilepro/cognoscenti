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

import java.io.OutputStream;
import java.io.PrintWriter;
import java.io.StringWriter;
import java.net.HttpURLConnection;
import java.net.URL;
import java.net.URLDecoder;
import java.util.ArrayList;
import java.util.List;
import java.util.StringTokenizer;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;

import org.socialbiz.cog.AuthRequest;
import org.socialbiz.cog.DOMUtils;
import org.socialbiz.cog.GoalRecord;
import org.socialbiz.cog.NGPage;
import org.socialbiz.cog.NGPageIndex;
import org.socialbiz.cog.SectionTask;
import org.socialbiz.cog.exception.NGException;
import org.socialbiz.cog.exception.ProgramLogicError;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.w3c.dom.traversal.DocumentTraversal;
import org.w3c.dom.traversal.NodeFilter;
import org.w3c.dom.traversal.NodeIterator;
import com.purplehillsbooks.streams.HTMLWriter;

public class ResourceLocater
{
    AuthRequest         ar;
    String              methodname;
    String              pathToResource;

    Document            linxml;
    NGResource          lresource;
    List<String>        parsedPath;
    String              serverURL;
    ResourceStatus      lrstatus;
    String              reqpath;

    private ResourceLocater(AuthRequest _ar)
    {
        ar = _ar;
        lrstatus = new ResourceStatus(ar);
    }

    /**
    * this is the main entry to handle all requests for xml
    * and properly reports all exceptions.
    * You should never have an exception thrown from this.
    */
    public static void handleRestRequest(AuthRequest ar) throws Exception {
        ResourceLocater rlocator = new ResourceLocater(ar);
        try {
            NGResource ngr = rlocator.getResource1();
            ar.resp.setStatus(ngr.getStatusCode());
            ar.resp.setContentType("text/xml;charset=UTF-8");
            DOMUtils.writeDom(ngr.getDocument(), ar.w);
            ar.flush();
        }
        catch (Exception e) {

            //slow down hacking attempts
            Thread.sleep(3000);

            ResourceStatus lrstat = rlocator.lrstatus;

            lrstat.setCommnets("Unable to handle a REST API request for "+ar.getCompleteURL());

            StringWriter sw = new StringWriter();
            PrintWriter w = new PrintWriter(new HTMLWriter(sw));
            e.printStackTrace(w);

            lrstat.setSuccess(NGResource.OP_FAILED);
            lrstat.setReason( sw.toString());

            if(lrstat.getStatusCode() != 200) {
                ar.resp.setStatus(lrstat.getStatusCode());
            }
            else {
                ar.resp.setStatus(500);
            }

            ar.resp.setContentType("text/xml;charset=UTF-8");
            DOMUtils.writeDom(lrstat.getDocument(), ar.w);
            ar.flush();

            ar.logException("Unable to handle a REST API request", e);
        }
    }


    private NGResource getResource1() throws Exception
    {
        methodname = ar.req.getMethod();
        parsePath();
        lrstatus.setOpenId(ar.getBestUserId());
        lrstatus.setServerURL(serverURL);
        lrstatus.setMethod(methodname);
        lrstatus.setRequestURL(ar.req.getRequestURL().toString());

        if("PUT".equals(methodname) || "POST".equals(methodname))
        {
            DocumentBuilderFactory dfactory = DocumentBuilderFactory.newInstance();
            DocumentBuilder db = dfactory.newDocumentBuilder();
            linxml = db.parse(ar.req.getInputStream());
        }
        return getResource2();
    }

    private NGResource getResource2() throws Exception
    {

        String token0 = parsedPath.get(0);
        try
        {
            //if it starts with a "b" it is a book
            if("b".equals(token0))
            {
                return ResourceBook.handleBookRequest(ar, serverURL, lrstatus, linxml);
            }
            //if it starts with a "p" is is a page
            else if("p".equals(token0))
            {
                String token2 = parsedPath.get(2);
                if(token2.startsWith(NGResource.RESOURCE_RELAY))
                {
                    return handleRelayRequest();
                }
                else
                {
                    return handlePageRequest();
                }
            }
            //if the first token is "s" it is a section request??
            else if("s".equals(token0))
            {
                return handleGlobalSectionRequest();
            }
            else if("u".equals(token0))
            {
                return handleUserRequest();
            }
            else
            {
                throw new ProgramLogicError("Can not understand the first token in that path: '"+token0+"'");
            }
        }
        catch (Exception e)
        {
            throw new ProgramLogicError("Unable to handle request for '"+pathToResource+"'", e);
        }
    }

    private void parsePath()throws Exception
    {
        parsedPath = ar.getParsedPath();

        //TODO: not sure if the rest of this is needed
        String ctxtroot = ar.req.getContextPath();
        String requrl = ar.req.getRequestURL().toString();
        int indx = requrl.indexOf(ctxtroot);
        serverURL = requrl.substring(0, indx) + ctxtroot + "/";

        int bindx = indx + ctxtroot.length() + 1;
        reqpath = requrl.substring(bindx);

        pathToResource = reqpath;
    }


    private String getPathElement(int index)
        throws Exception
    {
        if (parsedPath==null) {
            parsedPath = ar.getParsedPath();
        }
        if (index >= parsedPath.size()) {
            return null;
        }
        return parsedPath.get(index);
    }

    //TODO: this method should be within the ResourcePage class
    private NGResource handlePageRequest() throws Exception
    {
        if (parsedPath.size()<3) {
            throw new ProgramLogicError("resource paths that start with 'p' must have two slashes after the p.");
        }
        String token2 = parsedPath.get(2);     //resource within leaf

        //first check if it is a search request, which always has the form
        //     p/factory/search.xml?qs={query}
        //why is this inside a leaf?  Should be global search, and at global
        //level in the path.  (But I don't want to break things.)
        if(NGResource.DATA_SEARCH_XML.equals(token2))
        {
            return handleSearchRequest();
        }

        //everything else needs a page resource
        ResourcePage rp = new ResourcePage(serverURL,ar);
        rp.setId(parsedPath.get(1));
        rp.setResourceStatus(lrstatus);
        rp.setinput(linxml);


        String token3 = null;              //section name
        if (parsedPath.size()>3)
        {
            token3 = parsedPath.get(3);     //section name
        }

        //   p/{pagekey}/s/....  is a section request
        if(NGResource.RESOURCE_SECTION.equals(token2))
        {
            return handlePageSectionRequest(rp);
        }
        //   p/{pagekey}/relay/....  is a relay request
        if(NGResource.RESOURCE_RELAY.equals(token2))
        {
            return handleRelayRequest();
        }
        //   p/{pagekey}/l/....  is a license request
        //if leaf resource starts with "l" it is a license request
        //these have the form:
        //    p/{pagekey}/l/{licenseid}/license.xml
        //YYYY is the license id
        if(NGResource.RESOURCE_LICENCE.equals(token2))
        {
            if (parsedPath.size()<5)
            {
                throw new ProgramLogicError("A license request must have five elements in the resource path.");
            }
            if(!NGResource.DATA_LICENSE_XML.equals(parsedPath.get(4))) {
                throw new ProgramLogicError("A license request must have the resource 'license.xml' at the end of the path.");
            }

            rp.setLicenseId(parsedPath.get(3));
            if("GET".equals(methodname))
            {
                rp.loadLicense();
            }
            else if("POST".equals(methodname))
            {
                rp.createLicense();
            }
            else if("PUT".equals(methodname))
            {
                rp.updateLicense();
            }
            else if("DELETE".equals(methodname))
            {
                rp.deleteLicense();
            }
            else
            {
                throw new ProgramLogicError("Unable to perform "+methodname+" operation on license");
            }
            return rp;
        }


        if(parsedPath.size() != 3) {
            throw new ProgramLogicError("A page resource request must have exactly three elements in the path");
        }

        if("GET".equals(methodname))
        {
            //    p/{pagekey}/leaf.xml
            if(NGResource.DATA_PAGE_XML.equals(token2))
            {
                rp.loadContent();
            }
            //    p/{pagekey}/userlist.xml
            else if(NGResource.DATA_USERLIST.equals(token2))
            {
                rp.loadUserList();
            }
            //    p/{pagekey}/process.xml
            else if("process.xml".equals(token2) || "process.wfxml".equals(token2))
            {
                rp.loadProcess();
            }
            else if(token2.startsWith("act") && token2.endsWith(".xml"))
            {
                int typeindx = token2.indexOf(".xml");
                String activtyid = token2.substring(3,typeindx);
                rp.loadActivity(activtyid);
            }
            else
            {
                throw new ProgramLogicError("Unable to perform GET operation to '"+token2+"'");
            }
        }
        else if("POST".equals(methodname))
        {
            //    p/{pagekey}/leaf.xml
            if(NGResource.DATA_PAGE_XML.equals(token2))
            {
                rp.create();
            }
            else
            {
                throw new ProgramLogicError("Unable to perform POST operation to '"+token2+"'");
            }
        }
        else if("PUT".equals(methodname))
        {
            //    p/{pagekey}/leaf.xml
            if(NGResource.DATA_USERLIST.equals(token2))
            {
                rp.setLicenseId(token3);
                rp.updateuser();
            }
            else
            {
                throw new ProgramLogicError("Unable to perform PUT operation to '"+token2+"'");
            }
        }
        else if("DELETE".equals(methodname))
        {
            //    p/{pagekey}/leaf.xml
            if(NGResource.DATA_PAGE_XML.equals(token2))
            {
                rp.delete();
            }
            else
            {
                throw new ProgramLogicError("Unable to perform DELETE operation to '"+token2+"'");
            }
        }
        else
        {
            throw new ProgramLogicError("Unable to perform "+methodname+" operation to '"+token2+"'");
        }

        return rp;
    }


    // handle resources like   p/{pagekey}/s/{secname}/...
    private NGResource handlePageSectionRequest(ResourcePage rp) throws Exception
    {
        if(!"p".equals(parsedPath.get(0))) {
            throw new ProgramLogicError("first element of path must be 'p'");
        }
        if(!"s".equals(parsedPath.get(2))) {
            throw new ProgramLogicError("third element of path must be 's'");
        }


        ResourceSection rs = new ResourceSection(serverURL,ar, rp, lrstatus, linxml);
        rs.setPageId(parsedPath.get(1));
        rs.setName(parsedPath.get(3));


        if (parsedPath.size()<5) {
            throw new ProgramLogicError("paths requesting information on a section must have a minimum of 5 segments in the path");
        }

        String token5 = getPathElement(5);

        String sectionLevelResource = parsedPath.get(4);

        //  if path is   p/{pagekey}/s/{secname}/section.xml
        // then deal with the section as a whole
        if (NGResource.DATA_SECTION_XML.equals(sectionLevelResource))
        {
            if("GET".equals(methodname))
            {
                rs.loadSection();
            }
            else if("POST".equals(methodname))
            {
                rs.createSection();
            }
            else if("PUT".equals(methodname))
            {
                rs.updateSection();
            }
            else if("DELETE".equals(methodname))
            {
                rs.deleteSection();
            }
            else
            {
                throw new ProgramLogicError("Unable to perform "+methodname+" operation on license");
            }
            return rs;
        }
        if (NGResource.DATA_HISTORY_XML.equals(sectionLevelResource))
        {
            if("GET".equals(methodname))
            {
                rs.loadHistory();
            }
            else
            {
                throw new ProgramLogicError("Unable to perform "+methodname+" operation on history");
            }
            return rs;
        }

        if (parsedPath.size()<6) {
            throw new ProgramLogicError("paths requesting information on a Tasks with id must have a minimum of 6 segments in the path");
        }

        rs.setId(token5);
        //it must be Tasks section, and there must be an "id" next
        if ("Tasks".equals(parsedPath.get(3)) && "id".equals(parsedPath.get(4)))
        {
            rs.setId(parsedPath.get(5));
            //this would be the place to handle tasks
        }

        String data_type =parsedPath.get(parsedPath.size()-1);

        if("GET".equals(methodname))
        {
            if(data_type.equals(NGResource.DATA_SECTION_XML)){
                rs.loadSection();
            }else if(data_type.equals(NGResource.DATA_SECCONTENT_XML)){
                rs.loadData();
            }else if(data_type.equals(NGResource.DATA_SUBPROCESS_XML)){
                rs.loadSubprocess();
            }else if(data_type.equals(NGResource.DATA_ALLTASK_XML)){
                rs.loadTaskList(data_type);
            }else if(data_type.equals(NGResource.DATA_ACTIVETASK_XML)){
                rs.loadTaskList(data_type);
            }else if(data_type.equals(NGResource.DATA_COMPLETETASK_XML)){
                rs.loadTaskList(data_type);
            }else if(data_type.equals(NGResource.DATA_FUTURETASK_XML)){
                rs.loadTaskList(data_type);
            }else{
                throw new ProgramLogicError("Unable to perform GET operation to '"+data_type+"'");
            }

        }
        else if("POST".equals(methodname)){
            if(data_type.equals(NGResource.DATA_SECTION_XML)){
                rs.createSection();
            }else if(data_type.equals(NGResource.DATA_SECCONTENT_XML)){
                rs.createData();
            }
            else{
                throw new ProgramLogicError("Unable to perform POST operation to '"+data_type+"'");
            }

        }else if("PUT".equals(methodname)){
            if(data_type.equals(NGResource.DATA_SECTION_XML)){
                rs.updateSection();
            }else if(data_type.equals(NGResource.DATA_SECCONTENT_XML)){
                rs.updateData();
            }else{
                throw new ProgramLogicError("Unable to perform PUT operation to '"+data_type+"'");
            }

        }else if("DELETE".equals(methodname)){
             if(data_type.equals(NGResource.DATA_SECTION_XML)){
                rs.deleteSection();
            }else if(data_type.equals(NGResource.DATA_SECCONTENT_XML)){
                rs.deleteData();
            }else{
                throw new ProgramLogicError("Unable to perform DELETE operation to '"+data_type+"'");
            }
        }

        return rs;
    }


    // handle resources like   /s/Tasks/f/...
    // this is not really a "section" but instead it is a tasklist
    private NGResource handleGlobalSectionRequest() throws Exception
    {
        if(!"s".equals(parsedPath.get(0)))
        {
            throw new ProgramLogicError("first element of path must be 's'");
        }
        if(!"Tasks".equals(parsedPath.get(1)))
        {
            throw new ProgramLogicError("second element of path must be 'Tasks'");
        }
        if(!"f".equals(parsedPath.get(2)))
        {
            throw new ProgramLogicError("third element of path must be 'f'");
        }

        ResourceSection rs = new ResourceSection(serverURL,ar,null, lrstatus, linxml);
        String data_type =getPathElement(parsedPath.size()-1);
        rs.setName("Tasks");
        if("GET".equals(methodname))
        {
            if(data_type.equals(NGResource.DATA_SECTION_XML))
            {
                rs.loadSection();
            }
            else if(data_type.equals(NGResource.DATA_SECCONTENT_XML))
            {
                rs.loadData();
            }
            else if(data_type.equals(NGResource.DATA_SUBPROCESS_XML))
            {
                rs.loadSubprocess();
            }
            else if(data_type.equals(NGResource.DATA_ALLTASK_XML))
            {
                rs.loadTaskList(data_type);
            }
            else if(data_type.equals(NGResource.DATA_ACTIVETASK_XML))
            {
                rs.loadTaskList(data_type);
            }
            else if(data_type.equals(NGResource.DATA_COMPLETETASK_XML))
            {
                rs.loadTaskList(data_type);
            }
            else if(data_type.equals(NGResource.DATA_FUTURETASK_XML))
            {
                rs.loadTaskList(data_type);
            }
            else if(data_type.equals(NGResource.DATA_HISTORY_XML))
            {
                rs.loadHistory();
            }
            else
            {
                throw new ProgramLogicError("Unable to perform GET operation");
            }
        }
        else if("POST".equals(methodname))
        {
            if(data_type.equals(NGResource.DATA_SECTION_XML))
            {
                rs.createSection();
            }
            else if(data_type.equals(NGResource.DATA_SECCONTENT_XML))
            {
                rs.createData();
            }
            else
            {
                throw new ProgramLogicError("Unable to perform POST operation");
            }
        }
        else if("PUT".equals(methodname))
        {
            if(data_type.equals(NGResource.DATA_SECTION_XML))
            {
                rs.updateSection();
            }
            else if(data_type.equals(NGResource.DATA_SECCONTENT_XML))
            {
                rs.updateData();
            }
            else
            {
                throw new ProgramLogicError("Unable to perform PUT operation");
            }
        }
        else if("DELETE".equals(methodname))
        {
            if(data_type.equals(NGResource.DATA_SECTION_XML))
            {
                rs.deleteSection();
            }
            else if(data_type.equals(NGResource.DATA_SECCONTENT_XML))
            {
                rs.deleteData();
            }
            else
            {
                throw new ProgramLogicError("Unable to perform DELETE operation");
            }
        }

        return rs;
    }

    private NGResource handleUserRequest()throws Exception
    {
        if(!"u".equals(parsedPath.get(0))) {
            throw new ProgramLogicError("first element of path must be 'u'");
        }

        ResourceUser ru = new ResourceUser(serverURL,ar);
        ru.setResourceStatus(lrstatus);
        ru.setinput(linxml);
        ru.executeRequest();
        return ru;
    }




    private NGResource handleSearchRequest()throws Exception
    {
        String searchText= ar.req.getParameter("qs");
        if(searchText == null) {
            throw new ProgramLogicError("Query to search on must be passed in a parameter 'qs'");
        }
        ResourcePage rp = new ResourcePage(serverURL,ar);
        rp.setResourceStatus(lrstatus);
        rp.setinput(linxml);

        if(parsedPath.size() != 3) {
            throw new ProgramLogicError("Invalid Request");
        }

        if("GET".equals(methodname)){
            rp.performSearch(searchText.trim());
        }
        else{
            throw new ProgramLogicError("Invalid Request");
        }

        return rp;
    }


    private String getRelayAddr(String token)
    {
        int indx = reqpath.indexOf(token);
        String relaypath = reqpath.substring(indx + token.length());
        return relaypath;
    }

    private NGResource handleRelayRequest() throws Exception
    {
        String token1 = getPathElement(1);
        String token2 = getPathElement(2);
        String token3 = getPathElement(3);
        NGPageIndex ngpi = ar.getCogInstance().getWSByCombinedKeyOrFail(token1);
        if (ngpi==null)
        {
            lrstatus.setStatusCode(404);
            throw new ProgramLogicError("Not able to find a workspace named '"+ token1
                           +"'.  Check the link and see if it is entered correctly.");
        }
        if (!ngpi.isProject())
        {
            throw new ProgramLogicError("Not able to find a workspace named '"+ token1
                           +"'.  Found some other container with that name.");
        }

        NGResource newRs = null;
        NGPage ngp = ngpi.getWorkspace();
        ar.setPageAccessLevels(ngp);

        String relayid = token2.substring(5);
        String relaypath = getRelayAddr(token2);

        GoalRecord tr = ngp.getGoalOrFail(relayid);
        String subPage = tr.getSub();
        if(subPage == null || subPage.length() == 0)
        {
            throw new ProgramLogicError("Failed to Relay Request, No subprocess is define for this task id:" + relayid);
        }
        int pindx1 = subPage.indexOf("/p/");
        int pidindx1 = subPage.indexOf('/', pindx1 + 3);

        String rcontextpath = subPage.substring(0, pindx1);
        String pageloc =  subPage.substring(0,pindx1 + 3);
        String pageid =   subPage.substring(pindx1 + 3,pidindx1);
        String pageadd = pageloc + pageid;
        String endurl;

        String lpAddress = serverURL + "p/" + ngp.getKey() + "/relay" + relayid;
        String lrAddress = lpAddress + "/~";

        String[] ostring = {pageadd, rcontextpath};
        String[] nstring = {lpAddress, lrAddress};


         if("GET".equals(methodname)){

            String freepass = tr.getFreePass();
            ar.req.setAttribute("lic", freepass);
            if(subPage.startsWith("http://") || subPage.startsWith("https://")){
                if(relaypath.startsWith("/~"))
                {
                    relaypath = relaypath.replaceFirst("/~", "");
                    endurl =    rcontextpath  + relaypath;
                }else{
                    endurl = pageloc  +  pageid  + relaypath;
                }
                URL rurl = new URL(endurl);
                HttpURLConnection rconn = (HttpURLConnection)rurl.openConnection();
                String ruserid = ar.getBestUserId() + ":" + freepass;
                rconn.setRequestProperty("Authorization", ruserid);
                Document doc = DOMUtils.convertInputStreamToDocument(rconn.getInputStream(), false, true);
                newRs = new ResourcePage(doc, NGResource.TYPE_XML);

            }else{
                if(relaypath.startsWith("/~"))
                {
                    relaypath = relaypath.replaceFirst("/~", "");
                    endurl =    rcontextpath  + relaypath;
                }else{
                    endurl = pageloc  +  pageid  + relaypath;
                }
                setRequestTokens(endurl);
                ar.licenseid = freepass;
                newRs = getResource2();
                String lcontextpath= serverURL.substring(0, serverURL.length()-1);
                String lpageadd =  lcontextpath + pageadd;
                ostring[0] = lpageadd;
                ostring[1] = lcontextpath;

            }
         }else if("PUT".equals(methodname)){
            boolean isEditable = false;
            try {
                isEditable = SectionTask.canEditTask(ngp,ar,relayid);
            }catch(Exception e){
                lrstatus.setStatusCode(401);
                throw e;
            }
            if(!isEditable)
            {
                lrstatus.setStatusCode(401);
                throw new NGException("nugen.exception.not.enough.permission",null);
            }
            if(NGResource.DATA_LICENSE_XML.equals(token3)){
                Element lele = ResourceSection.findElement(linxml.getDocumentElement(), "license");
                if(lele == null) {
                    throw new NGException("nugen.exception.invalid.xml.input",null);
                }
                String rlicence = lele.getAttribute("id");
                tr.setFreePass(rlicence);
                ngp.saveFile(ar, "Saving FreePass");

                 //Create Status
                lrstatus.setResourceid(ngp.getKey());
                String rAddr = serverURL + "p/" + ngp.getKey()
                     + "/relay" + relayid + "/process.xml";
                lrstatus.setResourceURL(rAddr);
                lrstatus.setSuccess(NGResource.OP_SUCCEEDED);
                String cmsg = "license is updated for relay" + relayid;
                lrstatus.setCommnets(cmsg);
                lresource = lrstatus;
                return lrstatus;
            }

            String freepass = tr.getFreePass();
            ar.req.setAttribute("lic", freepass);

            if(subPage.startsWith("http://") || subPage.startsWith("https://")){
                if(relaypath.startsWith("/~"))
                {
                    relaypath = relaypath.replaceFirst("/~", "");
                    endurl =    rcontextpath  + relaypath;
                }else{
                    endurl = pageloc  +  pageid  + relaypath;
                }
                URL rurl = new URL(endurl);
                HttpURLConnection rconn = (HttpURLConnection)rurl.openConnection();
                String ruserid = ar.getBestUserId() + ":" + freepass;
                rconn.setRequestProperty("Authorization", ruserid);
                rconn.setRequestMethod("POST");

                rconn.setDoOutput(true);
                rconn.setDoInput(true);
                rconn.setUseCaches(false);
                rconn.setAllowUserInteraction(false);
                rconn.setRequestProperty("Content-type", "text/xml; charset=UTF-8");

                OutputStream out = rconn.getOutputStream();
                DOMUtils.writeDom(linxml, out);
                out.flush();
                out.close();
                Document doc = DOMUtils.convertInputStreamToDocument(rconn.getInputStream(), false, true);
                newRs = new ResourcePage(doc, NGResource.TYPE_XML);

            }else{
                if(relaypath.startsWith("/~"))
                {
                    relaypath = relaypath.replaceFirst("/~", "");
                    endurl =    rcontextpath  + relaypath;
                }else{
                    endurl = pageloc  +  pageid  + relaypath;
                }
                setRequestTokens(endurl);
                ar.licenseid = freepass;
                newRs = getResource2();
                String lcontextpath= serverURL.substring(0, serverURL.length()-1);
                String lpageadd =  lcontextpath + pageadd;
                ostring[0] = lpageadd;
                ostring[1] = lcontextpath;
            }
         }

         transformRelayURL(newRs.getDocument(), ostring, nstring);
         return newRs;
    }

    private void setRequestTokens(String path)
        throws Exception
    {
        //TODO: get rid of StringTokenizer
        StringTokenizer st = new StringTokenizer(path, "/");
        int tokencnt = st.countTokens();
        parsedPath = new ArrayList<String>();
        for(int i=0; i<tokencnt; i++)
        {
            try {
                String pathElement = st.nextToken();
                parsedPath.add(URLDecoder.decode(pathElement, "UTF-8"));
            }
            catch (java.io.UnsupportedEncodingException e){
                    //it is not possible that UTF-8 is not supported
                    //but in that case, leave it encoded.
            }
        }
    }

    private void transformRelayURL(Document doc, String[] opath, String[] npath) throws Exception
    {
        DocumentTraversal traversal = (DocumentTraversal)doc;
        NodeIterator iterator = traversal.createNodeIterator(
        doc.getDocumentElement(), NodeFilter.SHOW_TEXT, null, true);

        for (Node n = iterator.nextNode(); n != null; n = iterator.nextNode()) {

            if ("subkey".equals(n.getLocalName())||
                "subkey".equals(n.getNodeName())) {
                    continue;
            }
            String value = n.getNodeValue();
            for(int i=0; i<opath.length; i++){
                String oldPath = opath[i];
                String newPath = npath[i];
                if(value.startsWith(oldPath))
                {
                    String nvalue = value.replaceFirst(oldPath,newPath);
                    n.setNodeValue(nvalue);
                    break;
                }
            }
        }
    }

}
