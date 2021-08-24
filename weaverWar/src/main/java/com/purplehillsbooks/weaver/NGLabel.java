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

import com.purplehillsbooks.json.JSONObject;

/**
 * Projects will have a set of labels to label documents, action items, and topics with.
 * This will put them into groups, and allow for a display somewhat like a folder.
 *
 * Two objects implement this: a pure label, and a NGRole object.
 * Roles act like labels in many contexts.  A role is a lable with
 * extra feature of having a bunch of members and descriptions.
 */
public interface NGLabel {

    public String getName();

    public void setName(String name);

    public String getColor();

    public void setColor(String color);

    public JSONObject getJSON() throws Exception;

}
