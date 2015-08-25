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

package org.socialbiz.cog;

import org.socialbiz.cog.exception.ProgramLogicError;

/**
* This convenience class carries a URL, a username
* and a token, with the idea that you will use the username
* and token, passed in the header of the request, in order
* to access the resource that the url points at.
*
* The members of this class are public because there is no special
* magic behind them. This class is a bundle of three values: the
* url, the username, and the token.  These are three entirely independent
* values that can be changed at any time
*/
public class LicensedURL
{

    public String url;
    public String user;
    public String token;

    public LicensedURL(String nUrl, String nUser, String nToken)
    {
        if (nUrl == null)
        {
            throw new RuntimeException("Null value passed for URL in a LicensedURL.  Not allowed");
        }
        url = nUrl;
        user = nUser;
        token = nToken;
    }

    public LicensedURL(String nUrl)
    {
        if (nUrl == null)
        {
            throw new RuntimeException("Null value passed for URL in a LicensedURL.  Not allowed");
        }
        url = nUrl;
        user = null;
        token = null;
    }


    public static String addLicense(String url, String token)
        throws Exception
    {
        LicensedURL lu = new LicensedURL(url, null, token);
        return lu.getCombinedRepresentation();
    }


    /**
    * Adds the standard license parameter to the end of the URL.
    */
    public String getCombinedRepresentation()
        throws Exception
    {
        if (url == null)
        {
            throw new ProgramLogicError("LicensedURL has a null url value, that is not allowed.");
        }
        if (url.length()<6)
        {
            throw new ProgramLogicError("getCombinedRepresentation does not know how to handle url: "+url);
        }
        int pos = url.indexOf('?');
        char separator = '?';
        if (pos>0)
        {
            separator = '&';
        }
        return url + separator + "lic=" + token;
    }

    /**
    * When making a request to the subprocess, you need to pass a username
    * and a token (password).  is a format which includes the username and
    * token directly in the URL.  This format works in some versions of
    * browsers, but not all, and in fact may not be part of the standard.
    * This combined version is simply a wy to pack all three values togehter
    * so that a user can copy and paste all three values with a single operation.
    *
    * The format is
    * http://username:password@host:port/app/.....(rest of the url)
    *
    * This method composes the combined form from the three individual values.
    */
    public String getCombinedRepresentationOLD()
        throws Exception
    {
        if (url == null)
        {
            throw new ProgramLogicError("LicensedURL has a null url value, that is not allowed.");
        }
        if (url.length()<6)
        {
            throw new ProgramLogicError("getCombinedRepresentation does not know how to handle url: "+url);
        }
        StringBuffer res = new StringBuffer();
        int pos = 0;
        if (url.startsWith("http://"))
        {
            res.append("http://");
            pos = 7;
        }
        else if (url.startsWith("http://"))
        {
            res.append("https://");
            pos = 8;
        }
        else
        {
            throw new ProgramLogicError("getCobinedSub can only handle complete http URLs at this point.  Does not know how to handle "+url);
        }
        res.append(user);
        res.append(":");
        res.append(token);
        res.append("@");
        res.append(url.substring(pos));
        return res.toString();
    }

    /**
    * Parses the license token out of the URL combined representation
    * and returns a valid Licensed URL object back.
    */
    public static LicensedURL parseCombinedRepresentation(String newVal)
        throws Exception
    {
        int pos = newVal.indexOf("&lic=");
        if (pos < 0)
        {
            pos = newVal.indexOf("?lic=");
        }
        if (pos < 0)
        {
            throw new ProgramLogicError("can not parse this combined URL because no 'lic' parameter found");
        }
        int endPos = newVal.indexOf('&', pos+5);
        if (endPos<0)
        {
            String token = newVal.substring(pos+5);
            return new LicensedURL(newVal.substring(0, pos), null, token);
        }
        else
        {
            String token = newVal.substring(pos+5,endPos);
            String recomposedURL = newVal.substring(0,pos)+newVal.substring(endPos);
            return new LicensedURL(recomposedURL, null, token);
        }
    }

    /**
    * This method allows you to set the URL, username, and token with a single
    * call using the form where all three values are combined into a single
    * string value.
    *
    * returns an array of three strings: url, username, token
    */
    public static LicensedURL parseCombinedRepresentationOLD(String newVal)
        throws Exception
    {
        StringBuffer res = new StringBuffer();
        int pos = 0;
        if (newVal.startsWith("http://"))
        {
            res.append("http://");
            pos = 7;
        }
        else if (newVal.startsWith("http://"))
        {
            res.append("https://");
            pos = 8;
        }
        else
        {
            throw new ProgramLogicError("setCombinedSub can only handle complete http URLs at this point.  Does not know how to handle "+newVal);
        }
        int atpos = newVal.indexOf("@", pos);
        int slashpos = newVal.indexOf("/", pos);

        //if there is no @ sign before the next slash, then there is no
        //username/password encoded in this URL.  It is a normal URL.
        //Don't complain, just set username and token to null strings.
        if (atpos<0 || atpos>slashpos)
        {
            return new LicensedURL(newVal, "", "");
        }

        int colonpos = newVal.indexOf(":", pos);
        String token = "";
        String user = "";
        if (colonpos < atpos-1)
        {
            user = newVal.substring(pos, colonpos);
            token = newVal.substring(colonpos+1, atpos);
        }
        else
        {
            user = newVal.substring(pos, atpos);
        }
        res.append( newVal.substring(atpos+1) );
        return new LicensedURL(res.toString(), user, token);
    }

    public void setDOMElement(DOMFace child)
    {
        child.setTextContents(url);
        child.setAttribute("user", user);
        child.setAttribute("token", token);
    }

    public static LicensedURL parseDOMElement(DOMFace child)
    {
        if (child == null)
        {
            throw new RuntimeException("parseDOMElement requires a non-null argument");
        }
        String url = child.getTextContents();
        return new LicensedURL(url, child.getAttribute("user"), child.getAttribute("token"));
    }

}
