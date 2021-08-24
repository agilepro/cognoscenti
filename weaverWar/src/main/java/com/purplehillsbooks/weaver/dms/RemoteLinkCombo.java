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
 * limitations under the License.package com.purplehillsbooks.weaver.dms;
 *
 * Contributors Include: Shamim Quader, Sameer Pradhan, Kumar Raja, Jim Farris,
 * Sandia Yang, CY Chen, Rajiv Onat, Neal Wang, Dennis Tam, Shikha Srivastava,
 * Anamika Chaudhari, Ajay Kakkar, Rajeev Rastogi
 */

package com.purplehillsbooks.weaver.dms;

import com.purplehillsbooks.weaver.UserManager;
import com.purplehillsbooks.weaver.UserPage;
import com.purplehillsbooks.weaver.exception.ProgramLogicError;

/**
* This class parses and composes a special "combo" string value that used to be
* used to describe a folder.
*
* The string is a combination of
*
*     USER_KEY @ FOLDER_ID / RELATIVE_PATH
*
*
* Sometimes this combo value is called a folderId, so this can be confusing.
* We should phase this combo value out of use, but for now we have to support.
*/
public class RemoteLinkCombo
{
    public String userKey;
    public String folderId;
    public String rpath;

    public static RemoteLinkCombo parseLink(String rLink) throws Exception
    {
        if (rLink==null || rLink.length()==0) {
            return new RemoteLinkCombo("", "", "");
        }
        int atPos = rLink.indexOf('@');
        if (atPos<0)
        {
            throw new ProgramLogicError("Error parsing remote link: there is no @ present in ("+rLink+")  "
                +"Format is {user}@{folder}/{path}.  "
                +"This is probably an indication of a corrupted data file.");
        }

        int slashPos = rLink.indexOf('/', atPos);
        if (slashPos<0)
        {
            throw new ProgramLogicError("Error parsing remote link: there is no slash present after the @.  "
                +"Format is {user}@{folder}/{path}.  "
                +"This is probably an indication of a corrupted data file.");
        }

        String userKey  = rLink.substring(0, atPos);
        String folderId = rLink.substring(atPos+1, slashPos);
        String rpath    = rLink.substring(slashPos);

        return new RemoteLinkCombo(userKey, folderId, rpath);
    }

    public static RemoteLinkCombo fromFullPath(String _userKey, String _folderId, String fullPath)
        throws Exception
    {
        UserPage uPage = UserManager.getStaticUserManager().findOrCreateUserPage(_userKey);
        ConnectionType cType = uPage.getConnectionOrFail(_folderId);
        String internalPath = cType.getInternalPathOrFail(fullPath);
        return new RemoteLinkCombo(_userKey, _folderId, internalPath);
    }

    public RemoteLinkCombo(String _userKey, String _folderId, String _rpath)
    {
        if (_userKey==null) {
            throw new RuntimeException("Can not create a Combo with a null user key");
        }
        userKey  = _userKey;
        folderId = _folderId;
        rpath    = _rpath;
    }

    public RemoteLinkCombo(String _userKey, ResourceEntity ent) throws Exception
    {
        if (_userKey==null) {
            throw new ProgramLogicError("Can not create a Combo with a null user key");
        }
        userKey  = _userKey;
        folderId = ent.getFolderId();
        rpath    = ent.getPath();
    }

    /**
    * A single string value that represents all three values,
    * the user id, an @ sign, and then the "symbol" which is
    * the connection number followed by the relative path.
    */
    public String getComboString()
    {
        return userKey + "@" + folderId + rpath;
    }

    /**
    * Represents a remote file (only) with a combination of the connection id
    * and the path within the connection to the file/folder.
    */
    public String getSymbol()
    {
        return folderId + rpath;
    }

    /**
    * Returns the resource entity that represents the remote file that
    * this combo points to.
    */
    public ResourceEntity getResource() throws Exception
    {
        UserPage uPage = UserManager.getStaticUserManager().findOrCreateUserPage(userKey);
        return uPage.getResource(folderId, rpath);
    }

    public ResourceEntity getResourceOrNull() throws Exception
    {
        UserPage uPage = UserManager.getStaticUserManager().findOrCreateUserPage(userKey);
        ResourceEntity re = uPage.getResourceOrNull(folderId, rpath);
        if(re!=null){
            return re;
        }else{
            return null;
        }
    }

    public UserPage getUserPage() throws Exception
    {
        return UserManager.getStaticUserManager().findOrCreateUserPage(userKey);
    }
}

