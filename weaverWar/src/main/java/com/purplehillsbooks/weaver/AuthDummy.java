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

package com.purplehillsbooks.weaver;

import java.io.Writer;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Properties;

import com.purplehillsbooks.weaver.exception.NGException;
import com.purplehillsbooks.weaver.exception.ProgramLogicError;

import com.purplehillsbooks.streams.NullWriter;

/**
* AuthDummy is a dummy request object which can be used inside the server
* when there is no actual HTTPRequest to start with.   It will handle
* the authentication part of the job, but no actual output will
* be produced.
*/
public class AuthDummy extends AuthRequest
{

    private static AuthDummy theDummy = null;

    /**
    * This is the PREFERRED way to get an AuthRequest object for use in server background processing.
    * This will check to see if an AuthRequest object has been associated with this request.
    * If so, it is returned.
    * If not, one will be created and associated with request, then returned
    */
    public static AuthRequest serverBackgroundRequest() {
        return theDummy;
    }


    public static void clearStaticVariables() {
        theDummy = null;
    }

    public static void initializeDummyRequest(Cognoscenti cog) throws Exception {
        if (!cog.getConfig().isInitialized()) {
            throw new ProgramLogicError("ConfigFile class must be initialized before AuthDummy!");
        }
        Writer wr = new NullWriter();
        theDummy = new AuthDummy(wr, cog);
    }


    /**
    * constructor: if this object is constructed in a servlet, then pass
    * a NULL to the newWriter parameter, and the output stream will be
    * retrieved from the response object in a safe way.
    * If object is constructed in a JSP page, then getWriter has already
    * been called on the request, and you must pass the writer in here
    * so that we can avoid calling this method twice
    */
    public AuthDummy(Writer w, Cognoscenti cog) {
        super(w, cog);
    }

    /**
    * This is the constructor that create a fake request object for a
    * particular user, and with a particular writer.
    * This can be used for creating email messages and such.
    */
    public AuthDummy(UserProfile up, Writer w, Cognoscenti cog) {
        super(w, cog);
        user = up;
    }

    public NGSession getSession()
    {
        throw new RuntimeException("The AuthDummy does not have a session object and "
        + "so whatever method is calling for a session can not run in background.");
    }

    /**
    * take the relative path, split it on slash characters, and
    * and parse it into an array os string values, properly converting
    * each element of the array for URL encoding.
    */
    public List<String> getParsedPath() {
        return new ArrayList<String>();
    }

    @SuppressWarnings("unused")
    private void resolveUser() throws Exception
    {
        throw new ProgramLogicError("Not implemented on dummy auth request object: resolveUser");
    }


    public void setPageAccessLevelsWithoutVisit(NGContainer newNgp)
        throws Exception
    {
        //nothing to do, all access is author level
    }

    public void setPageAccessLevels(NGContainer newNgp)
        throws Exception
    {
        //nothing to do, all access is author level
    }

    /**
    * Set logged in user is a function of the user interface to record that someone
    * has just logged in, but the AuthDummy object is fully controlled by the
    * system.  Therefor this method should not be needed.
    */
    public void setLoggedInUser(UserProfile newUser, String loginId, String autoLogin, String openId)
        throws Exception
    {
        throw new ProgramLogicError("Not implemented on dummy auth request object: setLoggedInUser");
    }

    /**
    * The user interface for logging out should never be used with AuthDummy situations.
    */
    public void logOutUser()
    {
        throw new RuntimeException("Not implemented on dummy auth request object: logOutUser");
    }


    public void assertNotPost()
        throws Exception
    {
        //nothing to do, IO does not matter
    }

    public String getFormerId()
        throws Exception
    {
        throw new ProgramLogicError("Not implemented on dummy auth request object: getFormerId");
    }


    public String getRequestURL()
    {
        throw new RuntimeException("Not implemented on dummy auth request object: getRequestURL");
    }


    /**
    * Return the complete URL that got us here, including query parameters
    * so we can redirect back as necessary.
    */
    public String getCompleteURL() {
        return "DummyRequest";
    }




    /**
    * Get a paramter value from the local properties object on Dummy request
    * Note that reqParam depends upon defParam, so reqParam is not reimplemented
    * for the dummyAuth class..
    */
    public String defParam(String paramName, String defaultValue)
        throws Exception
    {
        String val = localProperties.getProperty(paramName);
        if (val!=null)
        {
            return val;
        }
        return defaultValue;
    }

    /**
    * Get a required parameter from the local properties on the DummyAuth request
    */
    public String reqParam(String paramName)
        throws Exception
    {
        String val = defParam(paramName, null);
        if (val == null || val.length()==0)
        {
            //The exception that is thrown will not be seen by users.  Once all of the pages
            //have proper URLs constricted for redirecting to other pages, this error will
            //not occur.  Therefor, there is no need to localize this exception.
            throw new NGException("nugen.exception.parameter.required",new Object[]{paramName,getRequestURL()});
        }
        return val;
    }


    /**
    * This is where the DummyAuth stores the parameters to the request
    */
    Properties localProperties = new Properties();

    public void setParam(String paramName, String paramValue)
        throws Exception
    {
        localProperties.setProperty(paramName, paramValue);
    }


    public void makeHonoraryMember()
    {
        //nothing to do, always full access
    }


    public Locale getLocale()
    {
        // for background operations, alwasys use the default locale for the machine
        return Locale.getDefault();
    }


    public void invokeJSP(String JSPName)
        throws Exception
    {
        //there is no real request object, so calling JSP is difficult
        throw new ProgramLogicError("Dummy Auth objects are not able to actually call JSP");
    }

}
