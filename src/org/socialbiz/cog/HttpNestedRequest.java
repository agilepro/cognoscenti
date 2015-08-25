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

import java.io.IOException;
import java.io.BufferedReader;
import java.io.Reader;
import java.util.Enumeration;
import java.util.Hashtable;
import java.util.Map;
import java.util.Properties;
import java.util.Locale;
import java.util.Vector;
import javax.servlet.ServletInputStream;
import javax.servlet.http.Cookie;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.RequestDispatcher;
import javax.servlet.http.HttpSession;
import org.socialbiz.cog.exception.NGException;

public class HttpNestedRequest implements HttpServletRequest
{
    private Hashtable<String,Object> attribs = new Hashtable<String,Object>();
    private Properties props  = new Properties();
    private HttpServletRequest shadow;

    public String queryString;
    public String localPath;

    public HttpNestedRequest(String lPath, String qString, HttpServletRequest hiddenOne)
        throws Exception
    {
        queryString = qString;
        if (!lPath.startsWith("/"))
        {
            throw new NGException("nugen.exception.wrong.local.path",new Object[]{lPath});
        }
        localPath = lPath;
        shadow = hiddenOne;
    }

    public Object getAttribute(String name)
    {
        return attribs.get(name);
    }

    @SuppressWarnings("rawtypes")
    public Enumeration getAttributeNames()
    {
        return attribs.keys();
    }

    /**
    * Only support UTF-8
    */
    public String getCharacterEncoding()
    {
        return "UTF-8";
    }

    public void setCharacterEncoding(String env) throws java.io.UnsupportedEncodingException
    {
        //do nothing, encoding is always UTF-8
    }

    public int getContentLength()
    {
        //never any content, DummyRequest is always output
        return 0;
    }

    public String getContentType()
    {
        return "";
    }

    private class BogusInputStream extends ServletInputStream
    {
        public BogusInputStream()
        {
            super();
        }

        public int read() throws IOException
        {
            return -1;
        }
    }

    public ServletInputStream getInputStream() throws IOException
    {
        //there is no input, so return something that has not content
        return new BogusInputStream();
    }


    public String getParameter(String name)
    {
        return props.getProperty(name);
    }


    @SuppressWarnings("rawtypes")
    public Enumeration getParameterNames()
    {
        return props.propertyNames();
    }


    public String[] getParameterValues(String name)
    {
        String val = getParameter(name);
        if (val == null)
        {
            return new String[0];
        }
        return new String[] { val };
    }

    @SuppressWarnings("rawtypes")
    public Map getParameterMap()
    {
        return props;
    }

    public String getProtocol()
    {
        return "HTTP/1.1";
    }




    /**
     * Returns the name of the scheme used to make this request,
     * for example,
     * <code>http</code>, <code>https</code>, or <code>ftp</code>.
     * Different schemes have different rules for constructing URLs,
     * as noted in RFC 1738.
     *
     * @return      a <code>String</code> containing the name
     *          of the scheme used to make this request
     *
     */
    public String getScheme()
    {
        return "http";
    }

    /**
     * Returns the host name of the server to which the request was sent.
     * It is the value of the part before ":" in the <code>Host</code>
     * header value, if any, or the resolved server name, or the server IP address.
     *
     * @return      a <code>String</code> containing the name
     *          of the server
     */

    public String getServerName()
    {
        return "localhost";
    }


    /**
     * Returns the port number to which the request was sent.
     * It is the value of the part after ":" in the <code>Host</code>
     * header value, if any, or the server port where the client connection
     * was accepted on.
     *
     * @return      an integer specifying the port number
     *
     */

    public int getServerPort()
    {
        return 80;
    }



    /**
     * Retrieves the body of the request as character data using
     * a <code>BufferedReader</code>.  The reader translates the character
     * data according to the character encoding used on the body.
     * Either this method or {@link #getInputStream} may be called to read the
     * body, not both.
     *
     *
     * @return                  a <code>BufferedReader</code>
     *                      containing the body of the request
     *
     * @exception UnsupportedEncodingException  if the character set encoding
     *                      used is not supported and the
     *                      text cannot be decoded
     *
     * @exception IllegalStateException     if {@link #getInputStream} method
     *                      has been called on this request
     *
     * @exception IOException           if an input or output exception occurred
     *
     * @see                     #getInputStream
     *
     */

    private class BogusReader extends Reader
    {
        public BogusReader()
        {
            super();
        }

        public int read(char[] cbuf,int off,int len)
        throws IOException
        {
            return -1;
        }

        public void close() throws IOException
        {
            //do nothing
        }
    }


    public BufferedReader getReader() throws IOException
    {
        return new BufferedReader(new BogusReader());
    }




    /**
     * Returns the Internet Protocol (IP) address of the client
     * or last proxy that sent the request.
     * For HTTP servlets, same as the value of the
     * CGI variable <code>REMOTE_ADDR</code>.
     *
     * @return      a <code>String</code> containing the
     *          IP address of the client that sent the request
     *
     */

    public String getRemoteAddr()
    {
        return "127.0.0.0";
    }




    /**
     * Returns the fully qualified name of the client
     * or the last proxy that sent the request.
     * If the engine cannot or chooses not to resolve the hostname
     * (to improve performance), this method returns the dotted-string form of
     * the IP address. For HTTP servlets, same as the value of the CGI variable
     * <code>REMOTE_HOST</code>.
     *
     * @return      a <code>String</code> containing the fully
     *          qualified name of the client
     *
     */

    public String getRemoteHost()
    {
        return "localhost";
    }




    /**
     *
     * Stores an attribute in this request.
     * Attributes are reset between requests.  This method is most
     * often used in conjunction with {@link RequestDispatcher}.
     *
     * <p>Attribute names should follow the same conventions as
     * package names. Names beginning with <code>java.*</code>,
     * <code>javax.*</code>, and <code>com.sun.*</code>, are
     * reserved for use by Sun Microsystems.
     *<br> If the object passed in is null, the effect is the same as
     * calling {@link #removeAttribute}.
     * <br> It is warned that when the request is dispatched from the
     * servlet resides in a different web application by
     * <code>RequestDispatcher</code>, the object set by this method
     * may not be correctly retrieved in the caller servlet.
     *
     *
     * @param name          a <code>String</code> specifying
     *                  the name of the attribute
     *
     * @param o             the <code>Object</code> to be stored
     *
     */

    public void setAttribute(String name, Object o)
    {
        attribs.put(name, o);
    }




    /**
     *
     * Removes an attribute from this request.  This method is not
     * generally needed as attributes only persist as long as the request
     * is being handled.
     *
     * <p>Attribute names should follow the same conventions as
     * package names. Names beginning with <code>java.*</code>,
     * <code>javax.*</code>, and <code>com.sun.*</code>, are
     * reserved for use by Sun Microsystems.
     *
     *
     * @param name          a <code>String</code> specifying
     *                  the name of the attribute to remove
     *
     */

    public void removeAttribute(String name)
    {
        attribs.remove(name);
    }




    /**
     *
     * Returns the preferred <code>Locale</code> that the client will
     * accept content in, based on the Accept-Language header.
     * If the client request doesn't provide an Accept-Language header,
     * this method returns the default locale for the server.
     *
     *
     * @return      the preferred <code>Locale</code> for the client
     *
     */

    public Locale getLocale()
    {
        return Locale.getDefault();
    }




    /**
     *
     * Returns an <code>Enumeration</code> of <code>Locale</code> objects
     * indicating, in decreasing order starting with the preferred locale, the
     * locales that are acceptable to the client based on the Accept-Language
     * header.
     * If the client request doesn't provide an Accept-Language header,
     * this method returns an <code>Enumeration</code> containing one
     * <code>Locale</code>, the default locale for the server.
     *
     *
     * @return      an <code>Enumeration</code> of preferred
     *                  <code>Locale</code> objects for the client
     *
     */

    @SuppressWarnings("rawtypes")
    public Enumeration getLocales()
    {
        Vector<Locale> v = new Vector<Locale>();
        v.add(getLocale());
        return v.elements();
    }




    /**
     *
     * Returns a boolean indicating whether this request was made using a
     * secure channel, such as HTTPS.
     *
     *
     * @return      a boolean indicating if the request was made using a
     *                  secure channel
     *
     */

    public boolean isSecure()
    {
        return false;
    }




    /**
     *
     * Returns a {@link RequestDispatcher} object that acts as a wrapper for
     * the resource located at the given path.
     * A <code>RequestDispatcher</code> object can be used to forward
     * a request to the resource or to include the resource in a response.
     * The resource can be dynamic or static.
     *
     * <p>The pathname specified may be relative, although it cannot extend
     * outside the current servlet context.  If the path begins with
     * a "/" it is interpreted as relative to the current context root.
     * This method returns <code>null</code> if the servlet container
     * cannot return a <code>RequestDispatcher</code>.
     *
     * <p>The difference between this method and {@link
     * ServletContext#getRequestDispatcher} is that this method can take a
     * relative path.
     *
     * @param path      a <code>String</code> specifying the pathname
     *                  to the resource. If it is relative, it must be
     *                  relative against the current servlet.
     *
     * @return          a <code>RequestDispatcher</code> object
     *                  that acts as a wrapper for the resource
     *                  at the specified path, or <code>null</code>
     *                  if the servlet container cannot return a
     *                  <code>RequestDispatcher</code>
     *
     * @see             RequestDispatcher
     * @see             ServletContext#getRequestDispatcher
     *
     */
    /*
    * Implementation notes: This is pretty ugly really, and if anyone can
    * come up with a better way that would be fine.
    * What happems is that we have two requests< the original "shadow"
    * request, and the new "this" request.  They have different paths
    * that they are displaying, PathA and PathB.  This method receives a relative path
    * relative to the PathB, and converts it to a path that is relative to
    * PathA for forwarding on to the nested shadow request.
    * To do this, it first takes the relative path, and makes a full
    * absolute path from it considering the context of PathB.
    * Then it takes the context of the shadow request PathA and creates
    * a relative path to that, which ends up pointing to the same resource.
    * Very ugly, and not very quick, but gets the job done.
    * If there was a way to simply use the absolute paths, that would
    * be better.
    */
    public RequestDispatcher getRequestDispatcher(String relPath)
    {
        //the problem exists when the shadow is at a different depth
        //from the current request.   Need to sort out the difference
        //here

        String mainContext = getParentContext(getRequestURI());
        String desiredPath = putTogether(mainContext, relPath);

        String destContext = getParentContext(shadow.getRequestURI());

        return shadow.getRequestDispatcher(getRelativePath(desiredPath, destContext));
    }


    private String putTogether(String base, String relPath)
    {
        while (relPath.startsWith("../"))
        {
            relPath = relPath.substring(3);
            base = getParentContext(base);
        }
        return base + "/" + relPath;
    }


    private String getParentContext(String path)
    {
        int pos = path.lastIndexOf("/");
        if (pos<0)
        {
            throw new RuntimeException("Trying to get the parent context, but there is none! ("+path+")");
        }
        return path.substring(0, pos);
    }

    private String getRelativePath(String desiredPath, String destContext)
    {
        //first the easy case, if the desired path is longer than the dest context
        //just return the extra i nthe path.
        if (desiredPath.startsWith(destContext))
        {
            return desiredPath.substring(destContext.length()+1);
        }
        String desiredContext = getParentContext(desiredPath);
        String trailer = desiredPath.substring(desiredContext.length()+1);

        if (destContext.equals(desiredContext))
        {
            return trailer;
        }
        if (desiredContext.length()>destContext.length())
        {
            if (!desiredContext.startsWith(destContext))
            {
                throw new RuntimeException("desired context is '"+desiredContext+"' and destContext is '"+destContext+"' (incompatible 1)");
            }
            String relPath = desiredContext.substring(destContext.length());
            return relPath + trailer;
        }
        if (!destContext.startsWith(desiredContext))
        {
            throw new RuntimeException("desired context is '"+desiredContext+"' and destContext is '"+destContext+"' (incompatible 2)");
        }
        String strOfInterest = destContext.substring(desiredContext.length());
        String relRez = "";
        for (int i=0; i<strOfInterest.length(); i++)
        {
            char ch = strOfInterest.charAt(i);
            if (ch == '/')
            {
                relRez = relRez + "../";
            }
        }
        relRez = relRez + trailer;
        return relRez;
    }



    /**
     *
     * @deprecated  As of Version 2.1 of the Java Servlet API,
     *          use {@link ServletContext#getRealPath} instead.
     *
     */

    public String getRealPath(String path)
    {
        return shadow.getRealPath(path);  //deprecated, so ignore this
    }


    /**
     * Returns the Internet Protocol (IP) source port of the client
     * or last proxy that sent the request.
     *
     * @return  an integer specifying the port number
     *
     * @since 2.4
     */
    public int getRemotePort()
    {
        return shadow.getRemotePort(); //no idea what to return here
    }


    /**
     * Returns the host name of the Internet Protocol (IP) interface on
     * which the request was received.
     *
     * @return  a <code>String</code> containing the host
     *      name of the IP on which the request was received.
     *
     * @since 2.4
     */
    public String getLocalName()
    {
        return shadow.getLocalName();
    }

    /**
     * Returns the Internet Protocol (IP) address of the interface on
     * which the request  was received.
     *
     * @return  a <code>String</code> containing the
     *      IP address on which the request was received.
     *
     * @since 2.4
     *
     */
    public String getLocalAddr()
    {
        return shadow.getLocalAddr();

    }


    /**
     * Returns the Internet Protocol (IP) port number of the interface
     * on which the request was received.
     *
     * @return an integer specifying the port number
     *
     * @since 2.4
     */
    public int getLocalPort()
    {
        return shadow.getLocalPort();
    }


    //public static final String BASIC_AUTH = "BASIC";
    //public static final String FORM_AUTH = "FORM";
    //public static final String CLIENT_CERT_AUTH = "CLIENT_CERT";
    //public static final String DIGEST_AUTH = "DIGEST";

    /**
     * Returns the name of the authentication scheme used to protect
     * the servlet. All servlet containers support basic, form and client
     * certificate authentication, and may additionally support digest
     * authentication.
     * If the servlet is not authenticated <code>null</code> is returned.
     *
     * <p>Same as the value of the CGI variable AUTH_TYPE.
     *
     *
     * @return      one of the static members BASIC_AUTH,
     *          FORM_AUTH, CLIENT_CERT_AUTH, DIGEST_AUTH
     *          (suitable for == comparison) or
     *          the container-specific string indicating
     *          the authentication scheme, or
     *          <code>null</code> if the request was
     *          not authenticated.
     *
     */

    public String getAuthType()
    {
        return "BASIC";
    }




    /**
     *
     * Returns an array containing all of the <code>Cookie</code>
     * objects the client sent with this request.
     * This method returns <code>null</code> if no cookies were sent.
     *
     * @return      an array of all the <code>Cookies</code>
     *          included with this request, or <code>null</code>
     *          if the request has no cookies
     *
     *
     */

    public Cookie[] getCookies()
    {
        return new Cookie[0];
    }




    /**
     *
     * Returns the value of the specified request header
     * as a <code>long</code> value that represents a
     * <code>Date</code> object. Use this method with
     * headers that contain dates, such as
     * <code>If-Modified-Since</code>.
     *
     * <p>The date is returned as
     * the number of milliseconds since January 1, 1970 GMT.
     * The header name is case insensitive.
     *
     * <p>If the request did not have a header of the
     * specified name, this method returns -1. If the header
     * can't be converted to a date, the method throws
     * an <code>IllegalArgumentException</code>.
     *
     * @param name      a <code>String</code> specifying the
     *              name of the header
     *
     * @return          a <code>long</code> value
     *              representing the date specified
     *              in the header expressed as
     *              the number of milliseconds
     *              since January 1, 1970 GMT,
     *              or -1 if the named header
     *              was not included with the
     *              request
     *
     * @exception   IllegalArgumentException    If the header value
     *                          can't be converted
     *                          to a date
     *
     */

    public long getDateHeader(String name)
    {
        return 0;
    }




    /**
     *
     * Returns the value of the specified request header
     * as a <code>String</code>. If the request did not include a header
     * of the specified name, this method returns <code>null</code>.
     * If there are multiple headers with the same name, this method
     * returns the first head in the request.
     * The header name is case insensitive. You can use
     * this method with any request header.
     *
     * @param name      a <code>String</code> specifying the
     *              header name
     *
     * @return          a <code>String</code> containing the
     *              value of the requested
     *              header, or <code>null</code>
     *              if the request does not
     *              have a header of that name
     *
     */

    public String getHeader(String name)
    {
        return null;
    }




    /**
     *
     * Returns all the values of the specified request header
     * as an <code>Enumeration</code> of <code>String</code> objects.
     *
     * <p>Some headers, such as <code>Accept-Language</code> can be sent
     * by clients as several headers each with a different value rather than
     * sending the header as a comma separated list.
     *
     * <p>If the request did not include any headers
     * of the specified name, this method returns an empty
     * <code>Enumeration</code>.
     * The header name is case insensitive. You can use
     * this method with any request header.
     *
     * @param name      a <code>String</code> specifying the
     *              header name
     *
     * @return          an <code>Enumeration</code> containing
     *                      the values of the requested header. If
     *                      the request does not have any headers of
     *                      that name return an empty
     *                      enumeration. If
     *                      the container does not allow access to
     *                      header information, return null
     *
     */

    @SuppressWarnings("rawtypes")
    public Enumeration getHeaders(String name)
    {
        Vector<String> v = new Vector<String>();
        return v.elements();
    }





    /**
     *
     * Returns an enumeration of all the header names
     * this request contains. If the request has no
     * headers, this method returns an empty enumeration.
     *
     * <p>Some servlet containers do not allow
     * servlets to access headers using this method, in
     * which case this method returns <code>null</code>
     *
     * @return          an enumeration of all the
     *              header names sent with this
     *              request; if the request has
     *              no headers, an empty enumeration;
     *              if the servlet container does not
     *              allow servlets to use this method,
     *              <code>null</code>
     *
     *
     */

    @SuppressWarnings("rawtypes")
    public Enumeration getHeaderNames()
    {
        Vector<String> v = new Vector<String>();
        return v.elements();
    }




    /**
     *
     * Returns the value of the specified request header
     * as an <code>int</code>. If the request does not have a header
     * of the specified name, this method returns -1. If the
     * header cannot be converted to an integer, this method
     * throws a <code>NumberFormatException</code>.
     *
     * <p>The header name is case insensitive.
     *
     * @param name      a <code>String</code> specifying the name
     *              of a request header
     *
     * @return          an integer expressing the value
     *              of the request header or -1
     *              if the request doesn't have a
     *              header of this name
     *
     * @exception   NumberFormatException       If the header value
     *                          can't be converted
     *                          to an <code>int</code>
     */

    public int getIntHeader(String name)
    {
        return 0;
    }




    /**
     *
     * Returns the name of the HTTP method with which this
     * request was made, for example, GET, POST, or PUT.
     * Same as the value of the CGI variable REQUEST_METHOD.
     *
     * @return          a <code>String</code>
     *              specifying the name
     *              of the method with which
     *              this request was made
     *
     */

    public String getMethod()
    {
        return "GET";
    }




    /**
     *
     * Returns any extra path information associated with
     * the URL the client sent when it made this request.
     * The extra path information follows the servlet path
     * but precedes the query string and will start with
     * a "/" character.
     *
     * <p>This method returns <code>null</code> if there
     * was no extra path information.
     *
     * <p>Same as the value of the CGI variable PATH_INFO.
     *
     *
     * @return      a <code>String</code>, decoded by the
     *          web container, specifying
     *          extra path information that comes
     *          after the servlet path but before
     *          the query string in the request URL;
     *          or <code>null</code> if the URL does not have
     *          any extra path information
     *
     */

    public String getPathInfo()
    {
        return null;
    }




    /**
     *
     * Returns any extra path information after the servlet name
     * but before the query string, and translates it to a real
     * path. Same as the value of the CGI variable PATH_TRANSLATED.
     *
     * <p>If the URL does not have any extra path information,
     * this method returns <code>null</code> or the servlet container
     * cannot translate the virtual path to a real path for any reason
     * (such as when the web application is executed from an archive).
     *
     * The web container does not decode this string.
     *
     *
     * @return      a <code>String</code> specifying the
     *          real path, or <code>null</code> if
     *          the URL does not have any extra path
     *          information
     *
     *
     */

    public String getPathTranslated()
    {
        return null;
    }




    /**
     *
     * Returns the portion of the request URI that indicates the context
     * of the request.  The context path always comes first in a request
     * URI.  The path starts with a "/" character but does not end with a "/"
     * character.  For servlets in the default (root) context, this method
     * returns "". The container does not decode this string.
     *
     *
     * @return      a <code>String</code> specifying the
     *          portion of the request URI that indicates the context
     *          of the request
     *
     * This is the path of the base of the APPLICATION
     */

    public String getContextPath()
    {
        return shadow.getContextPath();
    }



    /**
     *
     * Returns the query string that is contained in the request
     * URL after the path. This method returns <code>null</code>
     * if the URL does not have a query string. Same as the value
     * of the CGI variable QUERY_STRING.
     *
     * @return      a <code>String</code> containing the query
     *          string or <code>null</code> if the URL
     *          contains no query string. The value is not
     *          decoded by the container.
     *
     */

    public String getQueryString()
    {
        return queryString;
    }




    /**
     *
     * Returns the login of the user making this request, if the
     * user has been authenticated, or <code>null</code> if the user
     * has not been authenticated.
     * Whether the user name is sent with each subsequent request
     * depends on the browser and type of authentication. Same as the
     * value of the CGI variable REMOTE_USER.
     *
     * @return      a <code>String</code> specifying the login
     *          of the user making this request, or <code>null</code>
     *          if the user login is not known
     *
     */

    public String getRemoteUser()
    {
        return null;
    }




    /**
     *
     * Returns a boolean indicating whether the authenticated user is included
     * in the specified logical "role".  Roles and role membership can be
     * defined using deployment descriptors.  If the user has not been
     * authenticated, the method returns <code>false</code>.
     *
     * @param role      a <code>String</code> specifying the name
     *              of the role
     *
     * @return      a <code>boolean</code> indicating whether
     *          the user making this request belongs to a given role;
     *          <code>false</code> if the user has not been
     *          authenticated
     *
     */

    public boolean isUserInRole(String role)
    {
        return false;
    }




    /**
     *
     * Returns a <code>java.security.Principal</code> object containing
     * the name of the current authenticated user. If the user has not been
     * authenticated, the method returns <code>null</code>.
     *
     * @return      a <code>java.security.Principal</code> containing
     *          the name of the user making this request;
     *          <code>null</code> if the user has not been
     *          authenticated
     *
     */

    public java.security.Principal getUserPrincipal()
    {
        return null;
    }




    /**
     *
     * Returns the session ID specified by the client. This may
     * not be the same as the ID of the current valid session
     * for this request.
     * If the client did not specify a session ID, this method returns
     * <code>null</code>.
     *
     *
     * @return      a <code>String</code> specifying the session
     *          ID, or <code>null</code> if the request did
     *          not specify a session ID
     *
     * @see     #isRequestedSessionIdValid
     *
     */

    public String getRequestedSessionId()
    {
        return null;
    }




    /**
     *
     * Returns the part of this request's URL from the protocol
     * name up to the query string in the first line of the HTTP request.
     * The web container does not decode this String.
     * For example:
     *
     *

     * <table summary="Examples of Returned Values">
     * <tr align=left><th>First line of HTTP request      </th>
     * <th>     Returned Value</th>
     * <tr><td>POST /some/path.html HTTP/1.1<td><td>/some/path.html
     * <tr><td>GET http://foo.bar/a.html HTTP/1.0
     * <td><td>/a.html
     * <tr><td>HEAD /xyz?a=b HTTP/1.1<td><td>/xyz
     * </table>
     *
     * <p>To reconstruct an URL with a scheme and host, use
     * {@link HttpUtils#getRequestURL}.
     *
     * @return      a <code>String</code> containing
     *          the part of the URL from the
     *          protocol name up to the query string
     *
     * @see     HttpUtils#getRequestURL
     *
     */

    public String getRequestURI()
    {
        return getContextPath() + localPath;
    }

    /**
     *
     * Reconstructs the URL the client used to make the request.
     * The returned URL contains a protocol, server name, port
     * number, and server path, but it does not include query
     * string parameters.
     *
     * <p>Because this method returns a <code>StringBuffer</code>,
     * not a string, you can modify the URL easily, for example,
     * to append query parameters.
     *
     * <p>This method is useful for creating redirect messages
     * and for reporting errors.
     *
     * @return      a <code>StringBuffer</code> object containing
     *          the reconstructed URL
     *
     */
    public StringBuffer getRequestURL()
    {
        StringBuffer fullUrl = new StringBuffer();

        //calculate the full path to base of application
        fullUrl.append(getApplicationBaseAddress());
        fullUrl.append(localPath);

        return fullUrl;
    }

    private String getApplicationBaseAddress()
    {
        String originalURL = shadow.getRequestURL().toString();
        String originalPath = shadow.getServletPath();
        return originalURL.substring(0, originalURL.length()-originalPath.length());
    }


    /**
     *
     * Returns the part of this request's URL that calls
     * the servlet. This path starts with a "/" character
     * and includes either the servlet name or a path to
     * the servlet, but does not include any extra path
     * information or a query string. Same as the value of
     * the CGI variable SCRIPT_NAME.
     *
     * <p>This method will return an empty string ("") if the
     * servlet used to process this request was matched using
     * the "/*" pattern.
     *
     * @return      a <code>String</code> containing
     *          the name or path of the servlet being
     *          called, as specified in the request URL,
     *          decoded, or an empty string if the servlet
     *          used to process the request is matched
     *          using the "/*" pattern.
     *
     */

    public String getServletPath()
    {
        return localPath;
    }




    /**
     *
     * Returns the current <code>HttpSession</code>
     * associated with this request or, if there is no
     * current session and <code>create</code> is true, returns
     * a new session.
     *
     * <p>If <code>create</code> is <code>false</code>
     * and the request has no valid <code>HttpSession</code>,
     * this method returns <code>null</code>.
     *
     * <p>To make sure the session is properly maintained,
     * you must call this method before
     * the response is committed. If the container is using cookies
     * to maintain session integrity and is asked to create a new session
     * when the response is committed, an IllegalStateException is thrown.
     *
     *
     *
     *
     * @param create    <code>true</code> to create
     *          a new session for this request if necessary;
     *          <code>false</code> to return <code>null</code>
     *          if there's no current session
     *
     *
     * @return      the <code>HttpSession</code> associated
     *          with this request or <code>null</code> if
     *          <code>create</code> is <code>false</code>
     *          and the request has no valid session
     *
     * @see #getSession()
     *
     *
     */

    public HttpSession getSession(boolean create)
    {
        return shadow.getSession(create);
    }





    /**
     *
     * Returns the current session associated with this request,
     * or if the request does not have a session, creates one.
     *
     * @return      the <code>HttpSession</code> associated
     *          with this request
     *
     * @see #getSession(boolean)
     *
     */

    public HttpSession getSession()
    {
        return shadow.getSession();
    }






    /**
     *
     * Checks whether the requested session ID is still valid.
     *
     * @return          <code>true</code> if this
     *              request has an id for a valid session
     *              in the current session context;
     *              <code>false</code> otherwise
     *
     * @see         #getRequestedSessionId
     * @see         #getSession
     * @see         HttpSessionContext
     *
     */

    public boolean isRequestedSessionIdValid()
    {
        return false;
    }



    /**
     *
     * Checks whether the requested session ID came in as a cookie.
     *
     * @return          <code>true</code> if the session ID
     *              came in as a
     *              cookie; otherwise, <code>false</code>
     *
     *
     * @see         #getSession
     *
     */

    public boolean isRequestedSessionIdFromCookie()
    {
        return false;
    }




    /**
     *
     * Checks whether the requested session ID came in as part of the
     * request URL.
     *
     * @return          <code>true</code> if the session ID
     *              came in as part of a URL; otherwise,
     *              <code>false</code>
     *
     *
     * @see         #getSession
     *
     */

    public boolean isRequestedSessionIdFromURL()
    {
        return false;
    }





    /**
     *
     * @deprecated      As of Version 2.1 of the Java Servlet
     *              API, use {@link #isRequestedSessionIdFromURL}
     *              instead.
     *
     */

    public boolean isRequestedSessionIdFromUrl()
    {
        return false;
    }



}

