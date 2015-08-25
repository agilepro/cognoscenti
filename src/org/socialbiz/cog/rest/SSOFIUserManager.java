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

import javax.servlet.http.HttpSession;

import org.socialbiz.cog.Cognoscenti;
import org.socialbiz.cog.NGSession;
import org.socialbiz.cog.UserManager;
import org.socialbiz.cog.UserProfile;
import org.workcast.ssoficlient.interfaces.GlobalId;
import org.workcast.ssoficlient.service.LoginServlet;
import org.workcast.ssoficlient.service.SingleTenantManager;
import org.workcast.ssoficlient.service.StringGlobalId;

/**
 * Implementation of the user manager required by SSOFI, and translating to
 * the traditional UserManager that Cognoscenti has always had.
 * Cognoscenti has static methods for managing users, so there is no
 * instance object to wrap.
 */
public class  SSOFIUserManager implements org.workcast.ssoficlient.interfaces.UserManager {

    public static String emailProviderAddress = null;

    /**
    * Cognoscenti allows user to log in with either an openid OR an email address.
    * To accomplish the email address, a special openid Id provider is specified for
    * handling login by email address.  (A SSOFI provider in local mode)
    * There is only ONE such email provider, and it is the only one trusted.
    * furthermore, OpenID values from this provider are handled specially
    * in that the openId is converted to the email address for storage.
    * This means that the provider has to have a specific form:  the openid URL
    * must start with the specified value, and end with the email address.  Nothing else.
    * The result is that people will see in their profile email addresses and then
    * the other open ids.  They will never see the openid that results from this
    * provider, and will see only the email address.
    *
    * This method strips the email address out of the openid, but only when it is
    * from the email provider, otherwise it returns the openit unmodified.
    */
    public static String processEmailType(String openid) {
        if (emailProviderAddress!=null && openid.startsWith(emailProviderAddress)) {
            openid = openid.substring(emailProviderAddress.length());
        }
        return openid;
    }


    public SSOFIUserManager(Cognoscenti cog) {

        //This address is special in that it allows people to authenticate by email
        //address, and Cognoscenti will look up the user by email address, not by
        //the entire OpenID url.
        emailProviderAddress = cog.getConfig().getProperty("emailOpenIDProvider");
    }


    /**
     * This method is used to construct a GlobalId object from the provided String id address.
     */
    public GlobalId constructID(String id) {
        return new StringGlobalId(id);
    }

    /**
     * This method is used to search the user profile containing the provided global id. This method returns
     * the UserProfile object if the profile is found else return a null.
     * It return a single object of UserProfile because only one profile exists for one global id.
     */
    public org.workcast.ssoficlient.interfaces.UserProfile findUser(String globalId) throws Exception {
        UserProfile user = UserManager.findUserByAnyId(globalId);
        if (user==null) {
            //try again with the processed ID
            //TODO: determine if this is still needed.  Seems questionable.
            //current implementation requires that if you login with email provider
            //you MUST also have that email, and assumes that you do not have the
            //open id in the list.  Can that always be true?
            String id = processEmailType(globalId);
            user = UserManager.findUserByAnyId(id);
            if (user==null) {
                return null;
            }
        }
        return new SSOFIUserProfile(user);
    }

    /**
     * Method createUser is used to create a new user profile for the provided global id.
     * Implementation class should take care that only single user profile should exists for a
     * particular global id to avoid conflicts in future. So before calling this function it must
     * be checked if any UserProfile already exists associated with this id.
     */
    public org.workcast.ssoficlient.interfaces.UserProfile createUser(String key, String globalId)
            throws Exception {
        String emailOrId = processEmailType(globalId);
        UserProfile user =  UserManager.createUserWithId(key, emailOrId);
        if (user==null) {
            return null;
        }
        return new SSOFIUserProfile(user);
    }

    /**
     * This method is used to save a UserProfile after doing some changes in user's profile.
     * Its a kind of commit operation after making the changes.
     */
    public void saveUserProfiles() throws Exception {
        UserManager.writeUserProfilesToFile();
    }

    /**
     * Method isLoggedIn is used to check if there is any user logged in or not.
     * This method returns true if you have an actual logged in (authenticated) user
     * else returns false if current access is anonymous.
     * @return boolean
     */
    public boolean isLoggedIn(HttpSession session) throws Exception {
        NGSession ngs = NGSession.getNGSession(session);
        UserProfile user = ngs.findLoginUserProfile();
        return (user!=null);
    }

    /**
     * This method returns UserProfile object of logged in user and returns a null if no user is logged in.
     */
    public org.workcast.ssoficlient.interfaces.UserProfile loggedInUser(HttpSession session) throws Exception {
        NGSession ngs = NGSession.getNGSession(session);
        UserProfile user = ngs.findLoginUserProfile();
        if (user==null) {
            return null;
        }
        return new SSOFIUserProfile(user);
    }

    /**
     * This method is used to set the provided user profile as the current user of this object
     * and implementation class should also make some appropriate settings into the session so that
     * the next request will remember this as well.
     * Some more settings are also  need to be done in session like autoLogin flag, open id entered, confirmed id (open id after authentication)
     * Note: Most of the time confirmed id and open id remains the same but two variable are taken for some special
     * case like in case of Google and Yahoo confirmed id have some string appended with openid.
     */
    public void setLoggedInUser(HttpSession session, org.workcast.ssoficlient.interfaces.UserProfile up, String confirmedId) throws Exception {
        NGSession ngs = NGSession.getNGSession(session);
        UserProfile wrapped = ((SSOFIUserProfile)up).getWrappedUser();
        String id = processEmailType(confirmedId);
        ngs.setLoggedInUser(wrapped, id);
    }

    public static void initSSOFI(String baseURL, Cognoscenti cog) throws Exception {
        File configFile = cog.getConfig().getFile("ssofi.config");
        if (!configFile.exists()) {
            throw new Exception("The login configuration file is missing: "+configFile);
        }
        LoginServlet.initialize(new SingleTenantManager(new SSOFIUserManager(cog)), configFile);
    }

    public boolean canCreateUser() {
        return true;
    }
}
