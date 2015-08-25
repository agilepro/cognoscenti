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

import org.socialbiz.cog.UserProfile;
import org.workcast.ssoficlient.interfaces.GlobalId;

/**
 * implementation of the UserProfile interface required by SSOFI
 * as a wrapper on the cognoscenti UserProfile class
 */
public class SSOFIUserProfile implements org.workcast.ssoficlient.interfaces.UserProfile {

    //This is the Cognoscenti user profile
    private UserProfile user;

    public SSOFIUserProfile(UserProfile _user) {
        user = _user;
    }

    public UserProfile getWrappedUser() {
        return user;
    }

    /**
     * User key is unique identification key of a user profile.
     *
     */
    public String getUserKey() {
        return user.getKey();
    }

    /**
     * Display name can represent the first name
     * or the combination of first name and last which depends upon the implementation class
     *
     */

    public String getDisplayName() {
        return user.getName();
    }

    /**
     * This method checks whether the user profile contains the provided global id.
     * If it contains then return true else return a false.
     *
     */
    public boolean hasID(GlobalId globalId) {
        String id = SSOFIUserManager.processEmailType(globalId.getValue());
        return user.hasAnyId(id);
    }

    /**
     * This method is to add the provided global id to a user profile.
     * Method returns a true when the id is successfully added and false if not. The implementation class
     * should check that if provided global id already exists in user's profile then it should not
     * perform any further operation and return false.
     */
    public boolean addID(GlobalId globalId) {
        String id = SSOFIUserManager.processEmailType(globalId.getValue());
        try {
            user.addId(id);
            return true;
        }
        catch (Exception e) {
            throw new RuntimeException(e);
        }
    }

    /**
     * This method is to remove the provided global id to a user profile.
     * Method returns a true when the id is successfully removed and false if not. The implementation class
     * should check that if provided global id exists in user's profile or not if exists then only it should
     * perform the operation else return false.
     */
    public boolean removeID (GlobalId globalId) {
        String id = SSOFIUserManager.processEmailType(globalId.getValue());
        try {
            user.removeId(id);
            return true;
        }
        catch (Exception e) {
            throw new RuntimeException(e);
        }
    }

    @Override
    public void setDisplayName(String newName) {
        user.setName(newName);
    }

    @Override
    public void setEmail(String newEmail) {
        try {
            user.addId(newEmail);
        }
        catch (Exception e) {
            e.printStackTrace();
            //must swallow to fit the interface pattern
        }
    }


}
