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
import java.util.Hashtable;
import java.util.List;

import org.socialbiz.cog.AddressListEntry;
import org.socialbiz.cog.AuthRequest;
import org.socialbiz.cog.DOMUtils;
import org.socialbiz.cog.NGBook;
import org.socialbiz.cog.NGPage;
import org.socialbiz.cog.NGPageIndex;
import org.socialbiz.cog.UtilityMethods;
import org.socialbiz.cog.exception.NGException;
import org.socialbiz.cog.exception.ProgramLogicError;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.NodeList;

public class ResourceBook implements NGResource
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
    private String[] parsedPath;

    public ResourceBook(String serverURL, AuthRequest _ar)
    {
        lserverURL = serverURL;
        ar = _ar;
        parsedPath = ar.getParsedPath();
    }


    // call this as soo as you know that the first element of the path is "b"
    public static NGResource handleBookRequest(AuthRequest ar, String serverURL,
                   ResourceStatus lrstatus, Document linxml)
        throws Exception
    {
        ResourceBook rb = new ResourceBook(serverURL, ar);
        rb.handleReq(lrstatus, linxml);
        return rb;
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

    public void create() throws Exception
    {
        if(!"factory".equals(lid)){
            lrstatus.setStatusCode(404);
            throw new NGException ("nugen.exception.factory.address.to.create.new.book",null);
        }
        Element element_book = findElement(lindoc.getDocumentElement(),"book");
        String name = DOMUtils.textValueOfChild(element_book, "name", true);
        if(name == null || name.length() == 0)
        {
            lrstatus.setStatusCode(404);
            throw new NGException ("nugen.exception.book.name.cant.be.empty",null);
        }
        throw new Exception("I don't think this old code ResourceBook.create is used any more");
        //should really come up with a better key than this,
        //but I don't think this old code is used any more so just keep it working.
        /*
        String key = IdGenerator.generateKey();
        NGBook ngb = NGBook.createNewSite(key, name);
        updateBook(ngb);
        ngb.saveSiteAs(ngb.getKey(), lar.getUserProfile(), "ResourceBook modification 2");

        //Create Status
        lrstatus.setResourceid(ngb.getKey());
        String bookAddr = lserverURL + "b/" + ngb.getKey() + "/book.xml";
        lrstatus.setResourceURL(bookAddr);
        lrstatus.setSuccess(NGResource.OP_SUCCEEDED);
        String cmsg = "A new book \"" + name + "\" is created";
        lrstatus.setCommnets(cmsg);
        ltype = lrstatus.getType();
        loutdoc = lrstatus.getDocument();
        */

    }

    public void update()throws Exception
    {
        //Authenticate Permission, if he is an admin

        Element element_book = findElement(lindoc.getDocumentElement(),"book");
        String id = element_book.getAttribute("id");

        if(!lid.equals(id)){
            lrstatus.setStatusCode(404);
            throw new NGException("nugen.exception.cant.update.id", new Object[]{id,lid});
        }
        NGBook ngb = ar.getCogInstance().getSiteByIdOrFail(id);
        if(!ngb.getKey().equals(id))
        {
            lrstatus.setStatusCode(404);
            throw new NGException("nugen.exception.cant.update.id.no.book", new Object[]{id});
        }

        updateBook(ngb);
        ngb.saveFile(ar, "ResourceBook modification 2");

         //Create Status
        lrstatus.setResourceid(ngb.getKey());
        String bookAddr = lserverURL + "b/" + ngb.getKey() + "/book.xml";
        lrstatus.setResourceURL(bookAddr);
        lrstatus.setSuccess(NGResource.OP_SUCCEEDED);
        String cmsg = "Book \"" + ngb.getKey() + " is updated";
        lrstatus.setCommnets(cmsg);
        ltype = lrstatus.getType();
        loutdoc = lrstatus.getDocument();
    }

    private void updateBook(NGBook ngb)throws Exception
    {
        Element element_book = findElement(lindoc.getDocumentElement(), "book");;

        String name = DOMUtils.textValueOfChild(element_book, "name", true);
        if(name != null && name.length() > 0){
            //this piece of code needs to do something differently
            //I think this is left over, unused functionality from when "books"
            //were transferred over a web protocol, but this is no longer used
            //if it IS used, then figure out the intend of this setting at that time.
            //it used to call 'setName' here.
            throw new Exception("There is no scalar name of a site any more, so attempt to set it should probably do something else.");
        }

        String logo = DOMUtils.textValueOfChild(element_book, "logo", true);
        if(logo != null && logo.length() > 0)
        {
            ngb.setLogo(logo);
        }

        String style = DOMUtils.textValueOfChild(element_book, "stylesheet", true);
        if(style != null && style.length() > 0)
        {
            ngb.setStyleSheet(style);
        }

        String descr = DOMUtils.textValueOfChild(element_book, "description", true);
        if(descr != null && descr.length() > 0)
        {
            ngb.setDescription(descr);
        }

        //Need to add element_author
        //TODO: Update the protocol to include ALL roles
        Element element_members = DOMUtils.getChildElement(element_book, "members");
        String[] members = DOMUtils.textValuesOfAll(element_members, "userid", true);
        for(String aMember : members)
        {
            ngb.getPrimaryRole().addPlayer(new AddressListEntry(aMember));
        }
    }

    public void loadContent() throws Exception
    {
        ltype = NGResource.TYPE_XML;
        List<NGBook> books  = new ArrayList<NGBook>();
        if("*".equals(lid)){
            books = NGBook.getAllSites();
        }
        else {
            NGBook book = ar.getCogInstance().getSiteByIdOrFail(lid);
            if(!book.getKey().equals(lid))
            {
                lrstatus.setStatusCode(404);
                throw new NGException("nugen.exception.cant.get.book", new Object[]{lid});
            }
            books.add(book);
        }

        String schema = lserverURL + NGResource.SCHEMA_BOOK;
        loutdoc = DOMUtils.createDocument("books");
        Element element_root = loutdoc.getDocumentElement();
        DOMUtils.setSchemAttribute(element_root, schema);

        for(int i=0; i<books.size();i++){
            NGBook ngb = books.get(i);
            Element element_book = DOMUtils.createChildElement(loutdoc, element_root, "book");
            element_book.setAttribute("id", ngb.getKey());

            //Adding name element
            DOMUtils.createChildElement(
                loutdoc, element_book, "name", ngb.getFullName());

            //Adding description element
            DOMUtils.createChildElement(
                loutdoc, element_book, "description", ngb.getDescription());

            //Adding stylesheet element
            DOMUtils.createChildElement(
                loutdoc, element_book, "stylesheet", ngb.getStyleSheet());

            //Adding logo element
            DOMUtils.createChildElement(
                loutdoc, element_book, "logo", ngb.getLogo());

        }
    }

    public void loadUserList() throws Exception
    {
        ltype = NGResource.TYPE_XML;
        NGBook ngb = ar.getCogInstance().getSiteByIdOrFail(lid);
        if(!ngb.getKey().equals(lid))
        {
            lrstatus.setStatusCode(404);
            throw new NGException("nugen.exception.cant.get.book", new Object[]{lid});
        }

        String schema = lserverURL + NGResource.SCHEMA_USERLIST;
        loutdoc = DOMUtils.createDocument("userlist");
        Element element_root = loutdoc.getDocumentElement();
        DOMUtils.setSchemAttribute(element_root, schema);


        //TODO: NEED TO ADD OWNERS
        for(AddressListEntry ale : ngb.getPrimaryRole().getDirectPlayers())
        {
            Element element_user =
                DOMUtils.createChildElement(loutdoc,element_root,"user");
            element_user.setAttribute("id", ale.getUniversalId());
            DOMUtils.createChildElement(loutdoc,element_user,
                    "accesslevel",NGResource.ACCESS_MEMBER);
        }
    }

    public static String ACCESS_AUTHOR = "A";
    public static String ACCESS_PAUTHOR = "PA";
    public static String ACCESS_MEMBER = "M";
    public static String ACCESS_PMEMBER = "PM";


    public void updateuser()throws Exception
    {
        NGBook ngb = ar.getCogInstance().getSiteByIdOrFail(lid);

        if(!ngb.getKey().equals(lid))
        {
            lrstatus.setStatusCode(404);
            throw new NGException("nugen.exception.cant.update.user", new Object[]{lid});
        }


        Element element_userlist = findElement(lindoc.getDocumentElement(), "userlist");
        for (Element element_user : DOMUtils.getChildElementsList(element_userlist)) {
            String userid = element_user.getAttribute("id").trim();
            String accesslevel = DOMUtils.textValueOfChild(element_user, "accesslevel", true);
            if(accesslevel.equals(ACCESS_AUTHOR)){
                throw new ProgramLogicError("updateuser function not programmed to handle Admin case.");
            }else if(accesslevel.equals(ACCESS_PAUTHOR)){
                throw new ProgramLogicError("updateuser function not programmed to handle Prospective Admin case.");
            }else if(accesslevel.equals(ACCESS_MEMBER)){
                ngb.getPrimaryRole().addPlayer(new AddressListEntry(userid));
            }
            else if(accesslevel.equals(ACCESS_PMEMBER)){
                throw new ProgramLogicError("updateuser function not programmed to handle Admin case.");
            }else if(accesslevel.equals(ACCESS_REMOVE)){
                ngb.getPrimaryRole().removePlayer(new AddressListEntry(userid));
            }
        }

        ngb.saveFile(ar, "ResourceBook modification 1");

         //Create Status
        lrstatus.setResourceid(ngb.getKey());
        String bookAddr = lserverURL + "b/" + ngb.getKey() + "/book.xml";
        lrstatus.setResourceURL(bookAddr);
        lrstatus.setSuccess(NGResource.OP_SUCCEEDED);
        String cmsg = "User of Book \"" + ngb.getKey() + " is updated";
        lrstatus.setCommnets(cmsg);
        ltype = lrstatus.getType();
        loutdoc = lrstatus.getDocument();
    }

    public void loadPage()throws Exception
    {
        NGPageIndex.assertNoLocksOnThread();
        ltype = NGResource.TYPE_XML;
        NGBook ngb = ar.getCogInstance().getSiteByIdOrFail(lid);
        if(!ngb.getKey().equals(lid))
        {
            lrstatus.setStatusCode(404);
            throw new NGException("nugen.exception.cant.get.book", new Object[]{lid});
        }

        String schema = lserverURL + NGResource.SCHEMA_PAGELIST;
        loutdoc = DOMUtils.createDocument("pagelist");
        Element element_root = loutdoc.getDocumentElement();
        DOMUtils.setSchemAttribute(element_root, schema);

        Hashtable<String, String> pageList = new Hashtable<String, String>();
        for (NGPageIndex ngpi : ar.getCogInstance().getAllProjectsInSite(ngb.getKey()))
        {
            NGPageIndex.clearLocksHeldByThisThread();

            if (!ngpi.isProject())
            {
                continue;
            }
            NGPage ngp = ngpi.getPage();
            String key = ngp.getKey();
            Object obj  = pageList.put(key, key);
            if(obj != null){
                continue;  //Page is already added.
            }
            String pageAddr = lserverURL + "p/" + key + "/leaf.xml";
            String comment = "";
            if (ngpi.isOrphan())
            {
                comment = "Orphaned";
            }
            else if (ngpi.requestWaiting)
            {
                comment = "Pending Requests";
            }

            Element element_pagerecord = DOMUtils.createChildElement(loutdoc,element_root,"pagerecord");
            DOMUtils.createChildElement(loutdoc,element_pagerecord,"pagename",ngpi.containerName);
            DOMUtils.createChildElement(loutdoc,element_pagerecord,"url", pageAddr);
            DOMUtils.createChildElement(loutdoc, element_pagerecord, "modifieduser" , ngp.getLastModifyUser());
            DOMUtils.createChildElement(loutdoc, element_pagerecord, "modifiedtime" , UtilityMethods.getXMLDateFormat(ngp.getLastModifyTime()));
            DOMUtils.createChildElement(loutdoc, element_pagerecord, "remark" , comment);
        }
        NGPageIndex.clearLocksHeldByThisThread();
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

    public int getStatusCode()
    {
        return statuscode;
    }

    private static Element findElement(Element parent, String expr) throws Exception
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

    public void handleReq(ResourceStatus lrstatus,  Document linxml)
        throws Exception
    {

        String token1 = parsedPath[1];
        String token2 = parsedPath[2];

        setResourceStatus(lrstatus);
        setinput(linxml);
        setId(token1);

        if(parsedPath.length != 3)
        {
            throw new ProgramLogicError("A request for book information needs exactly three values in the path.");
        }

        String methodname = ar.req.getMethod();

        if("GET".equals(methodname))
        {
            if(NGResource.DATA_BOOK_XML.equals(token2)){
                loadContent();
            }else if(NGResource.DATA_PAGELIST.equals(token2)){
                loadPage();
            }else if(NGResource.DATA_USERLIST.equals(token2)){
                loadUserList();
            }else{
                throw new ProgramLogicError("Unable to perform GET operation to '"+token2+"'");
            }
        }else if("POST".equals(methodname)){
            if(NGResource.DATA_BOOK_XML.equals(token2)){
                create();
            }else {
                throw new ProgramLogicError("Unable to perform POST operation to '"+token2+"'");
            }
        }else if("PUT".equals(methodname)){
            if(NGResource.DATA_BOOK_XML.equals(token2)){
                update();
            }else if(NGResource.DATA_USERLIST.equals(token2)){
                updateuser();
            }else{
                throw new ProgramLogicError("Unable to perform PUT operation to '"+token2+"'");
            }
        }else{
            throw new ProgramLogicError("Unsupported method "+methodname+" on '"+token2+"'");
        }
    }


}



