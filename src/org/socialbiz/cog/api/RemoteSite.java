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

package org.socialbiz.cog.api;

import java.net.URL;

import org.workcast.json.JSONObject;
import org.socialbiz.cog.RemoteJSON;

/**
* A remote site
*/
public class RemoteSite {
    public String urlStr;
    JSONObject guts;

    public RemoteSite(String s) throws Exception {
        urlStr = s;
    }

    public JSONObject getJSONObj() throws Exception {
        try {
            if (guts == null) {
                URL url = new URL(urlStr);
                guts = RemoteJSON.getFromRemote(url);
            }
            return guts;
        }
        catch (Exception e) {
            throw new Exception("Unable to get site detail from url=" + urlStr, e);
        }
    }

}
