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
import java.util.ArrayList;
import java.util.Enumeration;
import java.util.Hashtable;
import java.util.List;

import javax.servlet.ServletContext;
import javax.servlet.http.HttpSession;

import org.socialbiz.cog.api.AuthStatus;
import org.socialbiz.cog.exception.ProgramLogicError;

/**
* Holds things that are persistent for a user across a session
*/
public class NGSession
{
    public List<RUElement> recentlyVisited = new ArrayList<RUElement>();

    /**
    * table of page ids that this session is an honorary member of
    * because of using a special license.  This persists for the
    * duration of the session.
    */
    private Hashtable<String,String> honorarium = new Hashtable<String,String>();

    /**
    * This is the wrapped session object
    */
    private HttpSession session;

    private AuthStatus aStat;
    

    /**
     * The proper way to get the NGSession instance that is assocaited with a
     * given HttpSession instance.
     */
    public static NGSession getNGSession(HttpSession session) throws Exception {
        NGSession ngs = (NGSession) session.getAttribute("ngsession");
        if (ngs==null)
        {
            ngs = new NGSession(session);
            session.setAttribute("ngsession", ngs);
        }
        return ngs;
    }

    /**
    * Construct an NGSession object to hold information for this
    * browser session.
    *
    * Why not pass the http session to it and store a reference?
    * The reason is that the HttpSession object will be serialized out
    * and then serialized back in again.  Will the reference be preserved
    * through that?  I don't think so.
    */
    private NGSession(HttpSession n_session) throws Exception {
        session = n_session;
        aStat = AuthStatus.getAuthStatus(n_session);


        //if the server has been shut down and restarted, then the session string attribute
        //will be preserved, but not the NGSession object, so read the user id that
        //was preserved and reset the session so the user is logged in.
        String key = (String) session.getAttribute("userKey");
        if (key!=null) {
            UserProfile oldUser = UserManager.findUserByAnyId(key);
            if (oldUser!=null) {
                setLoggedInUser(oldUser, key);
            }
        }
    }



    public void addVisited(NGWorkspace ngp, long currentTime) {
        if (ngp==null) {
            throw new ProgramLogicError("addVisited was called with a null parameter.  That should not happen");
        }
        RUElement rue = new RUElement(ngp.getFullName(), ngp.getKey(), ngp.getSiteKey(),  currentTime);
        RUElement.addToRUVector(recentlyVisited, rue, currentTime, 12);
    }


    /**
    * Configuration values are cached, but this method will clear the
    * cache and force the config to be read from disk again.
    * This can be called at any time, and only effect performance.
    */
    public void flushConfigCache()
    {
    }


    /**
    * pass in the simple file name of a file that exists in the server's
    * local config file, and this will return a File object with the
    * full path to that file (whether it exists or not).
    */
    public File getConfigDirFile(String fileName)
    {
        ServletContext sc = session.getServletContext();
        String configPath = sc.getRealPath("WEB-INF/"+fileName);
        return new File(configPath);
    }


    public void addHonoraryMember(String pageId)
    {
        honorarium.put(pageId, pageId);
    }

    public boolean isHonoraryMember(String pageId)
    {
        return (honorarium.get(pageId)!=null);
    }

    /**
    * Get rid of all marks in the session about this user or any
    * rights or capabilities that the usr might have, including:
    *    session.setAttribute("userKey", null);
    *    session.removeAttribute("specialAccessUser");
    *
    * This method gets rid of ALL attributes...
    */
    public void deleteAllSpecialSessionAccess(){
        @SuppressWarnings("unchecked")
        Enumeration<String> e = session.getAttributeNames();
        while (e.hasMoreElements()) {
            String attribute = e.nextElement();
            session.removeAttribute(attribute);
        }

        //force the construction of a new, empty AuthStatus object
        aStat = AuthStatus.getAuthStatus(session);
    }

    /**
    * Get the user profile of the currently logged in user (if there is any)
    * or return null if not.
    */
    public UserProfile findLoginUserProfile() {
        String userGlobalId =  aStat.getId();
        if (userGlobalId==null) {
            return null;
        }
        return UserManager.findUserByAnyId(userGlobalId);
    }

    /**
    * make the proper markings in the session to remember who the logged
    * in user is.  This should only be called when the user is POSITIVELY
    * identified, such as after logging in.
    */
    public void setLoggedInUser(UserProfile user, String loginId) throws Exception {
        aStat.setId(loginId);
        aStat.setName(user.getName());

        //TODO: Remove this line.
        //why is it here?  There is some code somewhere that is reading this,
        //and it breaks when this is removed.  So ... to maintain the functionality
        //the user key is DUPLICATED into this session variable.
        session.setAttribute("userKey", user.getKey());

        user.setLastLogin(System.currentTimeMillis(), loginId);
        UserManager.writeUserProfilesToFile();
    }

    private long lastError=0;
    /**
     * It is possible for a hacker to probe and get information from a server 
     * by observing what makes an error and what does not.  The dange of this is 
     * greatly reduced if errors a slow.  If an error takes a few seconds, then
     * it takes too long to mine the errors for useful information.   If you are
     * a legitimate user, then a delay of a few seconds does not matter.  
     * ONLY, it is a much nicer user interface if the error response is immediate.
     * The compromise is this.  The FIRST error will be fast, very fast.
     * Subsequent errors -- within a give time span -- should be slower.  A 
     * simple rule:  Never give another error message until 5 seconds after
     * the last.  This will never slow the FIRST error, but only subsequent ones.
     * Once you have gone 5 seconds without an error, you are back to fast 
     * errors again.  
     */
    public long getErrorResponseDelay() {
        long now = System.currentTimeMillis();
        long delay = lastError + 5000 - now;
        lastError = now;
        if (delay<0) {
            return 0;
        }
        return delay;
    }
    
}
