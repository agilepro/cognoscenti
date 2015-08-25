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

import org.socialbiz.cog.exception.NGException;
import org.socialbiz.cog.AuthRequest;
import org.socialbiz.cog.DOMUtils;
import org.socialbiz.cog.License;
import org.socialbiz.cog.NGContainer;
import org.socialbiz.cog.NGPage;

import java.io.OutputStream;

import java.net.HttpURLConnection;
import java.net.URL;

import java.util.Vector;

import org.w3c.dom.Document;
import org.w3c.dom.Element;

public class TaskLinkHelper
{
    String subPageUrl = "";
    String subPagelicense = "";
    String userName = "";
    String userPassword = "";
    String pageUrl = "";
    String parentURL = "";
    String relayUrl = "";
    String taskId = "factory";
    String synopsis;
    String description;
    Document activityDoc;
    Document licenseDoc;

    public TaskLinkHelper(AuthRequest ar, NGPage ngp,String combinedURL) throws Exception
    {
        parseLicenceURL(combinedURL);
        subPageUrl = getSubPageUrl(ar,ngp);
        subPagelicense = getSubPageLicense(ar, ngp);
    }

    public void setTaskLink() throws Exception
    {
        constructInputDoc();
        Document doc = makeConnection("PUT", parentURL, activityDoc);
        String ex = DOMUtils.getChildText(doc.getDocumentElement(), "reason");
        if(ex != null && ex.length() >0){
            throw new NGException("nugen.exception.dynamic.data", new Object[]{ex});
        }
        if(subPagelicense != null && subPagelicense.length() >0){
            constructlicenseDoc();
            String licenseurl = pageUrl + "/relay"+ taskId + "/" + NGResource.DATA_LICENSE_XML;
            makeConnection("PUT", licenseurl, licenseDoc);
        }
    }

    public void creatTaskWithLink(String subject, String description)throws Exception
    {
        this.synopsis = subject;
        this.description = description;
        constructInputDoc();
        Document doc = makeConnection("POST", parentURL, activityDoc);
        String ex = DOMUtils.getChildText(doc.getDocumentElement(), "reason");
        if(ex != null && ex.length() >0){
            throw new NGException("nugen.exception.dynamic.data", new Object[]{ex});
        }
        taskId = DOMUtils.getChildText(doc.getDocumentElement(), "resourceid");
        if(subPagelicense != null && subPagelicense.length() >0){
            constructlicenseDoc();
            String licenseurl = pageUrl + "/relay"+ taskId + "/" + NGResource.DATA_LICENSE_XML;
            makeConnection("PUT", licenseurl, licenseDoc);
        }
    }

    private void parseLicenceURL(String licensedURL)throws Exception
    {
        int indx1 = licensedURL.indexOf('@');
        int indx2 = licensedURL.indexOf("//");
        String usercr = licensedURL.substring(indx2+2, indx1);
        int indx3 = usercr.indexOf(':');
        userName = usercr.substring(0, indx3);
        userPassword = usercr.substring(indx3+1);

        int indx4 = licensedURL.indexOf("/id/");
        if(indx4 > 0){
            int indx5 = licensedURL.indexOf('/', indx4 + 4);
            taskId = licensedURL.substring(indx4 + 4, indx5);
        }

        int indx6 = licensedURL.indexOf("/p/");

        int indx7 = licensedURL.indexOf('/', indx6 + 4);
        pageUrl = licensedURL.substring(0, indx2) + "//"
            + licensedURL.substring(indx1+1, indx7) ;
        parentURL = pageUrl + "/s/Tasks/id/" + taskId + "/data.xml";
    }

    private void constructInputDoc() throws Exception
    {
        activityDoc = DOMUtils.createDocument("activities");
        Element root = activityDoc.getDocumentElement();
        Element actel = DOMUtils.createChildElement(activityDoc,root,"activity");
        actel.setAttribute("id", taskId);

        DOMUtils.createChildElement(activityDoc,actel,"processurl");
        DOMUtils.createChildElement(activityDoc,actel,"processurl");
        DOMUtils.createChildElement(activityDoc,actel,"key");
        DOMUtils.createChildElement(activityDoc,actel,"dispaly");
        if(synopsis != null) {
            DOMUtils.createChildElement(activityDoc,actel,"synopsis", synopsis);
        }
        else {
            DOMUtils.createChildElement(activityDoc,actel,"synopsis");
        }
        if(description != null) {
            DOMUtils.createChildElement(activityDoc,actel,"description", description);
        }
        else {
            DOMUtils.createChildElement(activityDoc,actel,"description");
        }
        DOMUtils.createChildElement(activityDoc,actel,"state");
        DOMUtils.createChildElement(activityDoc,actel,"assignee");
        Element subEle = DOMUtils.createChildElement(activityDoc,actel,"subprocess");
        DOMUtils.createChildElement(activityDoc,subEle,"subkey",subPageUrl);
        DOMUtils.createChildElement(activityDoc,subEle,"relayurl");
        DOMUtils.createChildElement(activityDoc,actel,"progress");
        DOMUtils.createChildElement(activityDoc,actel,"duration");
        DOMUtils.createChildElement(activityDoc,actel,"enddate");
        DOMUtils.createChildElement(activityDoc,actel,"rank");
    }

    private void constructlicenseDoc() throws Exception
    {
        licenseDoc = DOMUtils.createDocument("licenses");
        Element root = licenseDoc.getDocumentElement();
        Element lelm = DOMUtils.createChildElement(licenseDoc,root,"license");
        lelm.setAttribute("id", subPagelicense);
        DOMUtils.createChildElement(licenseDoc,lelm,"owner");
        DOMUtils.createChildElement(licenseDoc,lelm,"expired");
        DOMUtils.createChildElement(licenseDoc,lelm,"remark");

    }

    private Document makeConnection(String methodName, String endurl, Document inputDoc)throws Exception
    {
        URL rurl = new URL(endurl);
        HttpURLConnection rconn = (HttpURLConnection)rurl.openConnection();
        String ruserid = userName + ":" + userPassword;
        rconn.setRequestProperty("Authorization", ruserid);
        rconn.setRequestMethod(methodName);

        rconn.setDoOutput(true);
        rconn.setDoInput(true);
        rconn.setUseCaches(false);
        rconn.setAllowUserInteraction(false);
        rconn.setRequestProperty("Content-type", "text/xml; charset=UTF-8");

        OutputStream out = rconn.getOutputStream();
        DOMUtils.writeDom(inputDoc, out);
        out.flush();
        out.close();
        try {
            return DOMUtils.convertInputStreamToDocument(rconn.getInputStream(), false, true);
        }catch(Exception e){
            //If status code is more than 404 HttpURLConnection
            //getInputStream throw FileNotFounExcption. The original Exception can
            //not be retrieved from Staus.xml
            //So regenerating Exception based on status code.
            throw getException(rconn.getResponseCode(), e);
        }
    }

    public String getSubPageUrl(AuthRequest ar, NGContainer ngp)
    {
        String ctxtroot = ar.req.getContextPath();
        String requrl = ar.req.getRequestURL().toString();
        int indx = requrl.indexOf(ctxtroot);
        String pServer = requrl.substring(0, indx) + ctxtroot + "/";

        int indx2 = this.pageUrl.indexOf("/p/");
        String cServer = pageUrl.substring(0,indx2) + "/";

        String subpageurl = "";
        if(cServer.equals(pServer)) {
            subpageurl = "/p/" + ngp.getKey() + "/process.xml";
        }
        else {
            subpageurl = pServer + "p/" + ngp.getKey() + "/process.xml";
        }

        return subpageurl;
    }

    public String getSubPageLicense(AuthRequest ar, NGPage ngp) throws Exception
    {
        String subLicense = null;
        Vector<License> v  = ngp.getLicenses();
        if(!v.isEmpty()){
            License ls = v.firstElement();
            subLicense = ls.getId();
        }
        return subLicense;
    }

    private Exception getException(int statusCode, Exception e) throws Exception
    {
        Exception nexcp = e;
        if(statusCode == 401){
            nexcp = new Exception("Failed to Authorize. Please chack the license", e);
        }else if(statusCode == 404){
            nexcp = new Exception("Failed to find the resource, Please check the id", e);
        }else if(statusCode == 500){
            nexcp = new Exception("Server encounter internal problem, while processing the rquest", e);
        }
        return nexcp;
    }
}