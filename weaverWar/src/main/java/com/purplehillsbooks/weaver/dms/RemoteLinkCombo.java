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


    public RemoteLinkCombo(String _userKey, String _folderId, String _rpath)
    {
        if (_userKey==null) {
            throw new RuntimeException("Can not create a Combo with a null user key");
        }
        userKey  = _userKey;
        folderId = _folderId;
        rpath    = _rpath;
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

    public UserPage getUserPage() throws Exception
    {
        return UserManager.getStaticUserManager().findOrCreateUserPage(userKey);
    }
}

