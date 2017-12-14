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

import java.io.File;
import java.io.PrintWriter;
import java.net.URLEncoder;

import javax.servlet.ServletConfig;
import javax.servlet.ServletContext;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.socialbiz.cog.AuthRequest;
import org.socialbiz.cog.NGPageIndex;
import org.socialbiz.cog.NGWorkspace;
import org.socialbiz.cog.SectionAttachments;
import org.socialbiz.cog.exception.NGException;
import org.socialbiz.cog.exception.ProgramLogicError;
import com.purplehillsbooks.streams.HTMLWriter;

/**
 * This servlet serves up pages using the following URL format:
 *
 * http://machine:port/{application}/p/{pageid}/leaf.htm
 *
 * {application} is whatever you install the application to on Tomcat could be
 * multiple levels deep.
 *
 * "p" is fixed. This is the indicator within the nugen application that says
 * this servlet will be invoked.
 *
 * {pageid} unique identifier for the page. Obviously depends on the page
 *
 * leaf.htm is the resource-id of the main page presented as HTML page. This is
 * a fixed resource id for the page. There are other resources as well.
 *
 * http://machine:port/{application}/p/{pageid}/leaf.xml
 * http://machine:port/{application}/p/{pageid}/process.xml
 * http://machine:port/{application}/p/{pageid}/process.xpdl
 * http://machine:port/{application}/p/{pageid}/process.txt
 *
 * leaf.xml retrieves the page information as XML process.xml retrieves the
 * process on the page as xml process.xpdl represents that same process as xpdl
 *
 * There is a subspace for attachments using the name "a" Thus an attachment
 * "MyReport.doc" would be found at:
 *
 * http://machine:port/{application}/p/{pageid}/a/MyReport.doc
 *
 */
@SuppressWarnings("serial")
public class NGLeafServlet extends javax.servlet.http.HttpServlet {

    /**
    * if there is an exception during startup, it is recorded here.
    * TODO: eliminate this static variable
    */
    public static Exception initializationException;

        //
        // HISTORIC MARKER -
        // We used to have a tremendous amount of trouble with
        // HTTPServletResponse because the output stream can be reqeusted
        // only once.  Some of the JSP support classes needed to be able
        // to get the output stream from the response object.  When a
        // Servlet calls another Servlet, the only parameter is a request
        // and a response object, so if the first servlet gets the
        // output stream, the second Servlet is completely hosed because
        // it is unable to get the output stream, and there is no way to
        // pass the stream to it.  This is a serious limitation.
        //
        // This is made particularly difficult because the JSP methods
        // want to get a Writer, but our file attachment methods need
        // a stream.  You can't construct the writer until you know the
        // character encoding you are going to translate to.
        //
        // This is made even worse for handling exceptions.
        // You want to get the output stream before the beginning of
        // the try block, so that the same stream can be used for both
        // writing the page, and also writing an exception if it
        // occurs, but putting it outside the try block means you have to
        // to get it before you need it, and it prevents any down-stream
        // servlet from being the first to get it.  And you have to do this
        // before you can decide whether you want a Stream or a Writer.
        //
        // If you wait until you know whether you want a Stream or a
        // Writer, then you have a problem with the exception handling
        // code, because that code can not ask for the output stream
        // from the response object.
        //
        // A fairly bad solution is to declare a global stream variable
        // initialized to null, and whenever the code determines whether
        // it needs a Writer or a Stream, it puts it in that global.
        // Everyplace else in the code needs to check that global variable
        // to see if it is null or not, before it asks the request object.
        // IF the global is null, it can ask the request object.
        // But this does not work if you call another Servlet that uses
        // a different way of solving the problem or has its own global
        // variable.
        //
        // The real solution is HttpServletResponseWithoutBug which can
        // be used to wrap the original request object, and it allows
        // the stream to be fetched multiple times without problem.
        // This solves all the problems.  Now servlets can call servlets,
        // a servlet can call a JSP page, you can get the stream when you
        // need it and use it without worrying that this will prevent
        // exception code from doing the same.  It allows streams to be
        // gotten outside of try blocks, and both the try and the
        // catch block have access to a non-null variable.  You do not
        // need to test for null everywhere because code can assure
        // non-null up front.  It really solves a lot of problems
        //
    public void doGet(HttpServletRequest req, HttpServletResponse resp) {
        AuthRequest ar = AuthRequest.getOrCreate(req, resp);
        try {
            NGPageIndex.assertNoLocksOnThread();
            if (!ar.getCogInstance().isRunning()) {
                String go = ar.getRequestURL();
                String configDest = ar.retPath + "init/config.htm?go="+URLEncoder.encode(go,"UTF-8");
                resp.sendRedirect(configDest);
                return;
            }

            doAuthenticatedGet(ar);
        }
        catch (Exception e)
        {
            handleException(e, ar);
        }
        finally
        {
            NGPageIndex.clearLocksHeldByThisThread();
        }
        ar.logCompletedRequest();
    }

    private void doAuthenticatedGet(AuthRequest ar)  throws Exception {

        try {

            String requrl = ar.getRequestURL();

            if (requrl.endsWith(".xml") || requrl.endsWith(".wfxml")) {
                handleRERequest(ar);
                return;
            }


            // QUESTION: why is it that every request with an authorization
            // header, regardless of the URL, is assumed to be a XML object?
            // That does not seem right.
            String auHeader = ar.req.getHeader("Authorization");
            if (auHeader != null) {
                handleRERequest(ar);
                return;
            }

            //apparently, this servlet is mapped with /p/*
            //getPathInfo return only the path AFTER the p
            //I would rather get the entire path here, and then
            //check that we got a "p" for sure in that part of the path
            String path = ar.req.getPathInfo();

            // TEST: check to see that the servlet path starts with /
            if (!path.startsWith("/")) {
                throw new ProgramLogicError("Path should start with / but instead it is: "
                                + path);
            }

            int slashPos = path.indexOf("/", 1);
            if (slashPos < 0) {
                throw new ProgramLogicError("Path needs to be of the form: /p/pageid/xxx.htm but instead is: "
                                + path);
            }


            String pageid = path.substring(1, slashPos);
            ar.req.setAttribute("p", pageid);

            //resource is anything after the book id, could a complex path
            //itself, if it involves attachments or subaddressing
            String resource = path.substring(slashPos + 1);


            NGPageIndex ngpi = ar.getCogInstance().getWSByCombinedKeyOrFail(pageid);
            if (ngpi == null) {
                // wait, did not find it. Look again for all lower case
                // there was a bug in teh system earlier that used to record
                // automatically generated ids using uppercase, and later
                // that was changed to lower case
                // but references to the old pages still exist upper case. This
                // should fix that at least temporarily.
                pageid = pageid.toLowerCase();
                ngpi = ar.getCogInstance().getWSByCombinedKeyOrFail(pageid);
                if (ngpi == null) {
                    throw new NGException("nugen.exception.project.not.found.check.link", new Object[]{pageid});
                }
            }
            if (!ngpi.isProject())
            {
                throw new NGException("nugen.exception.looking.for.project", new Object[]{pageid});
            }

            //get the relative path needed to get to the root the application

            //this is the default resource
            if (resource.length()==0) {
                resource = "frontPage.htm";
            }
            if (resource.equals("leaf.htm")) {
                //legacy migration, old links to leaf.htm should be converted.
                resource = "frontPage.htm";
            }

            // This code taks a request of the form xxx.htm
            // and looks for a jsp file named leaf_xxx.jsp
            // if it exists, then call it.
            if (resource.indexOf("/")==-1 && resource.endsWith(".htm")) {
                String jspName = "leaf_" + resource.substring(0, resource.length()-3)+"jsp";
                ServletContext sc = ar.req.getSession().getServletContext();
                File jspFile = new File(sc.getRealPath(jspName));
                if (jspFile.exists()) {
                    ar.invokeJSP(jspName);
                    return;
                }
            }

            if (resource.equals("process4.htm")) {
                ar.req.setAttribute("max", "4");
                ar.invokeJSP("leaf_process.jsp");
                return;
            }
            if (resource.startsWith("leaflet")) {
                //form has to be leafletXXXX.htm  where XXXX is a
                //four digit identifier
                int dotpos = resource.indexOf(".htm");
                if (resource.length()<15 || dotpos<0) {
                    throw new ProgramLogicError("Unidentified address, leaflet form not proper");
                }
                String lid = resource.substring(7,dotpos);
                ar.req.setAttribute("lid", lid);
                ar.invokeJSP("leaflet.jsp");
                return;
            }

            NGWorkspace ngw = ngpi.getWorkspace();
            ar.setPageAccessLevels(ngw);

            // see if this is an attachment
            if (resource.startsWith("a/")) {
                String attachmentName = resource.substring(2);
                SectionAttachments.serveUpFileNewUI(ar, ngw, attachmentName, -1);
                return;
            }
            if (resource.equals("process.xml")) {
                ngw.genProcessData(ar);
            } else if (resource.endsWith("wfxml")) {
                if (resource.equals("process.wfxml")) {
                    ngw.genProcessData(ar);
                } else if (resource.startsWith("act")) {
                    // format is act0000.wfxml where 0000 might be any 4
                    // digit identifier
                    String idstr = resource.substring(3, 7);

                    // check that it is four digits
                    for (int i = 0; i < 4; i++) {
                        if (idstr.charAt(i) < '0' || idstr.charAt(i) > '9') {
                            throw new NGException("nugen.exception.id.for.activity.invalid",null);
                        }
                    }
                    ngw.genActivityData(ar, idstr);
                } else {
                    throw new NGException("nugen.exception.non.understandable.request",null);
                }
            } else if (resource.equals("process.txt")) {
                ngw.writePlainText(ar);
                ar.flush();
            } else if (resource.startsWith("noteZoom")) {
                //stupid hack fix.  Some email was sent with the wrong path, and this
                //fixes the path.  Can remove after Sept 2016
                //there is no likelihood that email is sitting around after that.
                System.out.println("HACK: fixxing bad link in email message, redirecting to note zoom in new UI: "+resource);
                String relPath = "../../t/"+ngpi.wsSiteKey+"/"+ngpi.containerKey+"/"+resource;
                ar.resp.sendRedirect(relPath);
                return;
            } else {
                throw new NGException("nugen.exception.page.resouce.incorrect", new Object[]{resource});
            }

        } catch (Exception e) {
            handleException(e, ar);
        }
    }

    public void doPost(HttpServletRequest req, HttpServletResponse resp) {
        AuthRequest ar = AuthRequest.getOrCreate(req, resp);
        try {
            NGPageIndex.assertNoLocksOnThread();
            String auHeader = req.getHeader("Authorization");
            if (auHeader == null) {
                throw new NGException("nugen.exception.authorization.header.not.set",null);
            }
            handleRERequest(ar);
        } catch (Exception e) {
            handleException(e, ar);
        } finally {
            NGPageIndex.clearLocksHeldByThisThread();
        }
        ar.logCompletedRequest();
    }

    public void doPut(HttpServletRequest req, HttpServletResponse resp) {
        AuthRequest ar = AuthRequest.getOrCreate(req, resp);
        try {
            NGPageIndex.assertNoLocksOnThread();
            String auHeader = req.getHeader("Authorization");
            if (auHeader == null) {
                throw new NGException("nugen.exception.authorization.header.not.set",null);
            }
            handleRERequest(ar);
        } catch (Exception e) {
            handleException(e, ar);
        } finally {
            NGPageIndex.clearLocksHeldByThisThread();
        }
        ar.logCompletedRequest();
    }

    public void doDelete(HttpServletRequest req, HttpServletResponse resp) {
        AuthRequest ar = AuthRequest.getOrCreate(req, resp);
        try {
            NGPageIndex.assertNoLocksOnThread();
            String auHeader = req.getHeader("Authorization");
            if (auHeader == null) {
                throw new NGException("nugen.exception.authorization.header.not.set",null);
            }
            handleRERequest(ar);
        } catch (Exception e) {
            handleException(e, ar);
        } finally {
            NGPageIndex.clearLocksHeldByThisThread();
        }
        ar.logCompletedRequest();
    }

    public void init(ServletConfig config)
          throws ServletException
    {
        //don't initialize here.  Instead, initialize in SpringServlet!
    }

    private void handleException(Exception e, AuthRequest ar)
    {
        try
        {
            ar.logException("NG Leaf Servlet", e);

            ar.resp.setContentType("text/html;charset=UTF-8");
            ar.write("<html><body><ul><li>Exception: ");
            ar.writeHtml(e.toString());
            ar.write("</li></ul>\n");
            ar.write("<hr/>\n");
            ar.write("<a href=\"");
            ar.write(ar.retPath);
            ar.write("\" title=\"Access the root\">Main</a>\n");
            ar.write("<hr/>\n<pre>");
            e.printStackTrace(new PrintWriter(new HTMLWriter(ar.w)));
            ar.write("</pre></body></html>\n");
            ar.flush();
        } catch (Exception eeeee) {
            // nothing we can do here...
        }
    }

    private void handleRERequest(AuthRequest ar) throws Exception {
        ResourceLocater.handleRestRequest(ar);
    }

}
