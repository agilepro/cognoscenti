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

import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.workcast.json.JSONObject;

public class ResponseRecord extends DOMFace
{

    public ResponseRecord(Document definingDoc, Element definingElement,  DOMFace p) {
        super(definingDoc, definingElement, p);
    }

    public String getUserId() {
        return getAttribute("uid");
    }
    public void setUserId(String userId) {
        setAttribute("uid", userId);
    }

    public String getChoice() {
        return getScalar("choice");
    }
    public void setChoice(String content) {
        setScalar("choice", content);
    }

    public String getContent() {
        return getScalar("content");
    }
    public void setContent(String content) {
        setScalar("content", content);
    }

    public String getHtml(AuthRequest ar) throws Exception {
        return WikiConverterForWYSIWYG.makeHtmlString(ar, getContent());
    }
    public void setHtml(AuthRequest ar, String newHtml) throws Exception {
        setContent(HtmlToWikiConverter.htmlToWiki(ar.baseURL, newHtml));
    }

    public JSONObject getJSON(AuthRequest ar) throws Exception {
        JSONObject jo = new JSONObject();
        AddressListEntry ale = new AddressListEntry(getUserId());
        jo.put("user", ale.getUniversalId());
        jo.put("userName", ale.getName());
        jo.put("choice",  getChoice());
        jo.put("html", getHtml(ar));
        return jo;
    }

    public void updateFromJSON(JSONObject input, AuthRequest ar) throws Exception {
        //can not change the user id since that is the key field.
        //user name is not stored here either
        if (input.has("html")) {
            setHtml(ar, input.getString("html"));
        }
        if (input.has("choice")) {
            setChoice(input.getString("choice"));
        }
    }

}
