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

import org.socialbiz.cog.AuthRequest;
import org.socialbiz.cog.DOMUtils;
import org.w3c.dom.Document;
import org.w3c.dom.Element;

public class ResourceStatus implements NGResource
{
    private Document loutdoc;
    private String lrequesturl;
    private String lmethod;
    private String lresourceurl;
    private String lresourceid;
    private String lsuccess;
    private String lcomment;
    private String lreason;
    private String lserverURL;
    private int statuscode = 200;

    public ResourceStatus(AuthRequest nar)
    {
    }
    public String getType()
    {
        return NGResource.TYPE_XML;
    }
    public Document getDocument() throws Exception
    {
        if (loutdoc==null) {
            makeDocumentInternal();
        }
        return loutdoc;
    }
    public String getFilePath()
    {
        return null;
    }

    public void setResourceURL(String resourceurl)
    {
        lresourceurl = resourceurl;

    }
    public void setRequestURL(String requesturl)
    {
        lrequesturl = requesturl;

    }

    public void setMethod(String method)
    {
        lmethod = method;

    }
    public void setResourceid(String resourceid)
    {
        lresourceid = resourceid;

    }
    public void setSuccess(String success)
    {
        lsuccess = success;

    }
    public void setCommnets(String commnent)
    {
        lcomment = commnent;

    }
    public void setReason(String reason)
    {
        lreason = reason;

    }

    public void setOpenId(String uopenid)
    {
    }

     public void setServerURL(String serverURL)
    {
        lserverURL = serverURL;
    }

    private void makeDocumentInternal() throws Exception
    {
        String schema = lserverURL + NGResource.SCHEMA_STATUS;
        loutdoc = DOMUtils.createDocument("status");
        Element element_root = loutdoc.getDocumentElement();
        DOMUtils.setSchemAttribute(element_root, schema);

        //Adding request element
        Element element_request = loutdoc.createElement("request");
        if(lrequesturl != null)
        {
            element_request.appendChild(loutdoc.createTextNode(lrequesturl));
        }
        element_root.appendChild(element_request);

        //Adding method element
        Element element_method = loutdoc.createElement("method");
        if(lmethod != null)
        {
            element_method.appendChild(loutdoc.createTextNode(lmethod));
        }
        element_root.appendChild(element_method);

         //Adding resourceid element
        Element element_resourceid = loutdoc.createElement("resourceid");
        if(lresourceid != null)
        {
            element_resourceid.appendChild(loutdoc.createTextNode(lresourceid));
        }
        element_root.appendChild(element_resourceid);

        //Adding reourceurl element
        Element element_resourceurl = loutdoc.createElement("resourceurl");
        if(lresourceurl != null)
        {
            element_resourceurl.appendChild(loutdoc.createTextNode(lresourceurl));
        }
        element_root.appendChild(element_resourceurl);

         //Adding success element
        Element element_success = loutdoc.createElement("result");
        if(lsuccess != null)
        {
            element_success.appendChild(loutdoc.createTextNode(lsuccess));
        }
        element_root.appendChild(element_success);

        //Adding success element
        Element element_comment = loutdoc.createElement("remark");
        if(lcomment != null)
        {
            element_comment.appendChild(loutdoc.createTextNode(lcomment));
        }
        element_root.appendChild(element_comment);

        //Adding success element
        Element element_reason = loutdoc.createElement("reason");
        if(lreason != null)
        {
            element_reason.appendChild(loutdoc.createTextNode(lreason));
        }
        element_root.appendChild(element_reason);
    }

    public int getStatusCode()
    {
        return statuscode;
    }

    public  void setStatusCode(int scode)
    {
        statuscode = scode;
    }
}