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
import java.io.PrintWriter;
import java.io.OutputStreamWriter;
import javax.servlet.ServletOutputStream;
import javax.servlet.http.HttpServletResponse;

import org.socialbiz.cog.util.UnclosableWriter;

/**
* HttpServletResponse has this *strange* limitation that you can
* call getOutputStream() once, or getWriter() once, but not both.
*
* ONLY UTF-8 ENCODING!
*
* If any of the code, calls
* it a second time, it throws an exception telling you that it
* has already been called.  Here is the problem, it is impossible
* to know if a piece of code is the first time calling the method
* or not.  There are a lot of public libraries that help to handle
* responses, specifically the JSP page handlers, that assume they
* are the only thing needing access to the output stream.
* We end up writing elaborate code to attempt to track which bit of
* code needs the output handler, and avoiding getting it, and when
* getting it, putting it in a temporary variables, and forcing
* other code which is after that point to go to the variable, etc.
* It is all a lot of coding complication and involves setting in
* place patterns which the public libraries are not designed to handle.
*
* This class caches a copy of the output stream, and makes sure
* that getOutputStream on the super class is called only once
* and lets the method on this version be called more that once
* without throwing an exception.  This gives flexibility for a
* method that uses output stream for just a few moments to get it
* straint from the response class, and not worry whether it is
* the first routine making that request or not.
*
* We used to have a tremendous amount of trouble with
* HTTPServletResponse because the output stream can be reqeusted
* only once.  Some of the JSP support classes needed to be able
* to get the output stream from the response object.  When a
* Servlet calls another Servlet, the only parameter is a request
* and a response object, so if the first servlet gets the
* output stream, the second Servlet is completely hosed because
* it is unable to get the output stream, and there is no way to
* pass the stream to it.  This is a serious limitation.
*
* This is made particularly difficult because the JSP methods
* want to get a Writer, but our file attachment methods need
* a stream.  You can't construct the writer until you know the
* character encoding you are going to translate to.
*
* This is made even worse for handling exceptions.
* You want to get the output stream before the beginning of
* the try block, so that the same stream can be used for both
* writing the page, and also writing an exception if it
* occurs, but putting it outside the try block means you have to
* to get it before you need it, and it prevents any down-stream
* servlet from being the first to get it.  And you have to do this
* before you can decide whether you want a Stream or a Writer.
*
* If you wait until you know whether you want a Stream or a
* Writer, then you have a problem with the exception handling
* code, because that code can not ask for the output stream
* from the response object.
*
* A fairly bad solution is to declare a global stream variable
* initialized to null, and whenever the code determines whether
* it needs a Writer or a Stream, it puts it in that global.
* Everyplace else in the code needs to check that global variable
* to see if it is null or not, before it asks the request object.
* IF the global is null, it can ask the request object.
* But this does not work if you call another Servlet that uses
* a different way of solving the problem or has its own global
* variable.
*
* The real solution is HttpServletResponseWithoutBug which can
* be used to wrap the original request object, and it allows
* the stream to be fetched multiple times without problem.
* This solves all the problems.  Now servlets can call servlets,
* a servlet can call a JSP page, you can get the stream when you
* need it and use it without worrying that this will prevent
* exception code from doing the same.  It allows streams to be
* gotten outside of try blocks, and both the try and the
* catch block have access to a non-null variable.  You do not
* need to test for null everywhere because code can assure
* non-null up front.  It really solves a lot of problems
*/
public class HttpServletResponseWithoutBug extends javax.servlet.http.HttpServletResponseWrapper
{
    public ServletOutputStream out;
    public PrintWriter writer;


    public HttpServletResponseWithoutBug(HttpServletResponse nresp)
    {
        super(nresp);

        //There is some small chance that this may help solve another bug
        //which is that even though a form is specified with UTF-8 encoding
        //the browser does not always send the character set.
        //if the "writer" is fetched before you are able to set the encoding
        //then you are stuck with ISO-8859-1 even if the data is UTF-8 encoded.
        //This will assure that JSP servlet gets the right encoding.
        //I know it is a big heavy handed, but all of our code ALWAYS uses UTF-8
        //and ALWAYS received UTF-8.  There is no reason to support any other
        //character set, because UTF-8 is supported by all browsers, and it
        //holds all of the characters that can be expressed in Java.
        nresp.setCharacterEncoding("UTF-8");
    }

    /**
    * the only point of this method is to make sure that the method
    * getOutputStream is called only once.
    */
    public ServletOutputStream getOutputStream()
        throws IOException
    {
        if (out!=null)
        {
            return out;
        }
        out = super.getOutputStream();
        return out;
    }

    /**
    * the only point of this method is to make sure that the method
    * getWriter or getOutputStream is called only once.
    */
    public PrintWriter getWriter()
        throws IOException
    {
        if (writer!=null)
        {
            return writer;
        }
        if (out==null)
        {
            out = super.getOutputStream();
        }
        if (out!=null)
        {
            //note we REQUIRE UTF-8 at this point as well
            writer = new PrintWriter(new OutputStreamWriter(out, "UTF-8"));
        }

        //temporary test, always return an unclosable writer
        return new UnclosableWriter(writer);
    }


    /**
    * setWriter allow a program outside this class to change the writer
    * so that all writing goes someplace else.
    * This is NOT set the output stream, so watch out if you are using that
    */
    public void setWriter(PrintWriter newWriter)
    {
        writer = newWriter;
    }
}
