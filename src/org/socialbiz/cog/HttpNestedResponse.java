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

import java.io.PrintWriter;
import java.io.Writer;
import java.util.Vector;
import java.util.Locale;
import javax.servlet.ServletOutputStream;
import javax.servlet.http.Cookie;

/**
* HttpNestedResponse is for creating a response object that
* can write to a file, emulating a HTTP request where there is no real
* HTTP request.
*/
public class HttpNestedResponse implements javax.servlet.http.HttpServletResponse
{
    public PrintWriter writer;
    int status;
    String contentType;


    public HttpNestedResponse(Writer out)
    {
        if (out instanceof PrintWriter)
        {
            writer = (PrintWriter) out;
        }
        else
        {
            writer = new PrintWriter(out);
        }
    }

    public void addCookie(Cookie cookie)
    {
        //ignore cookies
    }
    public void addDateHeader(java.lang.String name, long date)
    {
        //ignore headers
    }
    public void    addHeader(java.lang.String name, java.lang.String value)
    {
        //ignore headers
    }
    public void addIntHeader(java.lang.String name, int value)
    {
        //ignore headers
    }
    public boolean containsHeader(java.lang.String name)
    {
        return false;
    }
    public java.lang.String encodeRedirectUrl(java.lang.String url)
    {
        throw new RuntimeException("encodeRedirectURL is not implemented in HttpNestedResponse");
    }
    public java.lang.String encodeRedirectURL(java.lang.String url)
    {
        throw new RuntimeException("encodeRedirectURL is not implemented in HttpNestedResponse");
    }
    public java.lang.String   encodeUrl(java.lang.String url)
    {
        throw new RuntimeException("encodeRedirectURL is not implemented in HttpNestedResponse");
    }
    public java.lang.String     encodeURL(java.lang.String url)
    {
        throw new RuntimeException("encodeRedirectURL is not implemented in HttpNestedResponse");
    }
    public java.lang.String   getHeader(java.lang.String name)
    {
        return null;
    }
    public java.util.Collection<java.lang.String>  getHeaderNames()
    {
        //return an empty vector
        return new Vector<java.lang.String>();
    }
    public java.util.Collection<java.lang.String>   getHeaders(java.lang.String name)
    {
        //return an empty vector
        return new Vector<java.lang.String>();
    }
    public int  getStatus()
    {
        return status;
    }
    public void    sendError(int sc)
    {
        //ignore this
    }
    public void     sendError(int sc, java.lang.String msg)
    {
        //ignore this
    }
    public void    sendRedirect(java.lang.String location)
    {
        //ignore this
    }
    public void    setDateHeader(java.lang.String name, long date)
    {
        //ignore this
    }
    public void     setHeader(java.lang.String name, java.lang.String value)
    {
        //ignore this
    }
    public void     setIntHeader(java.lang.String name, int value)
    {
        //ignore this
    }
    public void    setStatus(int sc)
    {
        status = sc;
    }
    public void   setStatus(int sc, java.lang.String sm)
    {
        status = sc;
    }
    public void     flushBuffer()
    {
        writer.flush();
    }
    public int     getBufferSize()
    {
        return 0;
    }
    public java.lang.String     getCharacterEncoding()
    {
        return "UTF-8";
    }
    public java.lang.String    getContentType()
    {
        return "";
    }
    public java.util.Locale    getLocale()
    {
        return Locale.getDefault();
    }
    public ServletOutputStream  getOutputStream()
    {
        throw new RuntimeException("getOutputStream is not implemented in HttpNestedResponse");
    }
    public java.io.PrintWriter  getWriter()
    {
        return writer;
    }
    public  boolean     isCommitted()
    {
        return false;
    }
    public void     reset()
    {
        //ignore this
    }
    public void     resetBuffer()
    {
        // ignore this
    }
    public void     setBufferSize(int size)
    {
        //ignore this
    }
    public void     setCharacterEncoding(java.lang.String charset)
    {
        //ignore this, we only support UTF-8
    }
    public void   setContentLength(int len)
    {
        //ignore this
    }
    public void     setContentType(java.lang.String type)
    {
        contentType = type;
    }
    public void     setLocale(java.util.Locale loc)
    {
        //ignore this
    }
}
