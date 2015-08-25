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

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.util.Properties;

import javax.activation.FileTypeMap;
import javax.activation.MimetypesFileTypeMap;

import org.socialbiz.cog.exception.NGException;


/**
* As a web server that serves up attachments, it is important that the correct
* mime type calue be sent along with the file.
*
* According to the IETF, the mime type is supposed to be the primary way that a
* content of a file is identified, overriding any indication from the file name.
* Microsoft screwed up on this point int he early versions of Internet Explorer
* which would ignore mime type, and use only the file extension, and this led to
* a number of problems.  Later versions of IE (6.0 and later) use mime type to
* determine the content of a file, and NEVER the extension.  In fact, IE 7.0 and
* later refuse to use the file extension when the mime type is ambiguous, and instead
* inspect the stream.  This leads IE to conclude that pptx and docx are zip files,
* because actually they are zip files, and inspection shows that.  The fact is
* that you really want pptx to launch PowerPoint not Win zip.  Part of the
* problem is that the Java system does not come initialized properly to deliver
* the Microsoft mime types, and the refusal to include the proper mime type map
* table with Java is part of the Java/Microsoft war.
*
* Java includes a way to configure the mime type table, but does it in an error
* prone way.  Instead of associating the table with a server or a service, it is
* associated with the entire Java system.  Thus when you install your TomCat
* application, there is NO WAY to set up the mime type mapping table.
*
* It gets worse: the Java system is not clear on exactly how it gets initialized.
* The documentation says to put the mime type table in the java home lib directory,
* and I have seen that work, but there are other places you can put it that override
* this file.  At the moment I am writing this, I have a correctly configured mime
* type map file that used to work, but the Java system no longer is reading it.
* It is impossible to ask the system where it THINKS it is initializing itself
* from.  Where it reads from depends upon the user that it is running as, and
* it depends upon whether some other module in the system has programmatically
* altered the settings.  My suspision is that some lib module, because the Java
* approach is so arcane, has taken it upon themselves to "patch" it up, and thereby
* disabling the normal documented means to get it to work.  For whatever reasons,
* the mime type map is not working.
*
* Which brings us to the purpose of this class.  The default mime type value is
* "application/octet-stream".  This is the values that will cause IE to screw up.
* This class will leverage the Java system if it is functioning correclty.  But,
* this class will provide a way to OVERRIDE the Java supplied mime type, in the
* very likely probability that it will supply the wrong value.  This is kept as a
* simple property file in the application space.  If the application does not specify
* a type, then the normal Java supplied type will be used.
*
* mime type configuration file WEB-INF/mimeTypes.properties
*/
public class MimeTypes
{
    private static FileTypeMap   javaSysMimeMap = null;
    private static Properties    extensionMap   = null;

    /**
    * Initialize by passing the path to the WEB-INF directory
    * without any slash at the end.  That is the folder
    * where the mime type property file is located and will
    * be read from.
    */
    public static void initialize(File basePath)
        throws Exception
    {
        File mapFile = new File(basePath,"mimeType.properties");
        try
        {
            Properties tprops = null;
            if (!mapFile.exists())
            {
                //mimeType.properties file should always exist, if not found
                //create it.
                tprops = new Properties();
                tprops.put("pptx", "application/vnd.openxmlformats-officedocument.presentationml.presentation");
                tprops.put("ppsx", "application/vnd.openxmlformats-officedocument.presentationml.slideshow");
                tprops.put("potx", "application/vnd.openxmlformats-officedocument.presentationml.template");
                tprops.put("xlsx", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
                tprops.put("xltx", "application/vnd.openxmlformats-officedocument.spreadsheetml.template");
                tprops.put("docx", "application/vnd.openxmlformats-officedocument.wordprocessingml.document");
                tprops.put("dotx", "application/vnd.openxmlformats-officedocument.wordprocessingml.template");
                FileOutputStream fos = new FileOutputStream(mapFile);
                tprops.store(fos, "Initialized from defaults");
                fos.close();
            }
            else
            {
                FileInputStream fis = new FileInputStream(mapFile);
                tprops = new Properties();
                tprops.load(fis);
                fis.close();
            }
            extensionMap = tprops;
            javaSysMimeMap = MimetypesFileTypeMap.getDefaultFileTypeMap();
        }
        catch (Exception e)
        {
            throw new NGException("nugen.exception.unable.to.initialize.mime.file", new Object[]{mapFile}, e);
        }
    }

    /**
    * Sometimes it is more convenient to send the entire file name in, and
    * have the extension pulled off within the method.
    */
    public static String getMimeType(String fileName)
        throws Exception
    {
        int lastDot = fileName.lastIndexOf(".");
        if (lastDot<0)
        {
            //this is the case that there is no dot, and no extension
            //return default value in this case
            return "application/octet-stream";
        }
        if (lastDot==fileName.length())
        {
            //this is the case that the file name ends with a dot, and has no extension
            //so to speak, so return default
            return "application/octet-stream";
        }
        return getMimeTypeFromExtension(fileName.substring(lastDot+1));
    }

    /**
    * Pass a file extension, and get a mime type back.
    */
    public static String getMimeTypeFromExtension(String extension)
        throws Exception
    {
        String lcext = extension.toLowerCase();
        String mt = extensionMap.getProperty(lcext);
        if (mt == null)
        {
            //java system is expecting something like a file name, so fabricate one
            mt = javaSysMimeMap.getContentType("xxx."+lcext);

            //store this for later use
            extensionMap.put(lcext, mt);
        }
        return mt;
    }



}
