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

import org.workcast.json.JSONObject;


/**
* A license is also known as a "free pass".  Actually there can be
* many kinds of license, some of which might be free.  The point is
* that an access using a license ID in the parameters will then give
* the requester the information that is specified as being allowed in
* the license.
* Initially a license will be used to give non-authenticated users
* access to a single page or to just the process on that page.
*/
public interface License
{

    public String getId() throws Exception;

    public String getNotes() throws Exception;
    public void setNotes(String newVal) throws Exception;

    public String getCreator() throws Exception;
    public void setCreator(String newVal) throws Exception;

    public long getTimeout() throws Exception;
    public void setTimeout(long timeout) throws Exception;

    public String getRole() throws Exception;
    public void setRole(String newRole) throws Exception;

    public boolean isReadOnly() throws Exception;
    public void setReadOnly(boolean isReadOnly) throws Exception;

    public JSONObject getJSON() throws Exception;
}
