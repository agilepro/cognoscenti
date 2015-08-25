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

import org.workcast.json.JSONObject;

/**
* supports comparing a local and remote project
*/
public class SyncStatus
{
    public static final int TYPE_DOCUMENT = 1;
    public static final int TYPE_NOTE     = 2;
    public static final int TYPE_TASK     = 3;

    ProjectSync    sync;
    public String  universalId;
    public int     type;

    //whether they exist or not, and non-global id
    public boolean isLocal;
    public boolean isRemote;
    public String  idLocal;
    public String  idRemote;

    //name like field: document name, task synopsis, note subject
    public String  nameLocal;
    public String  nameRemote;
    public String  descLocal;
    public String  descRemote;

    //timestamp information
    public long    timeLocal;
    public long    timeRemote;
    public String  editorLocal;
    public String  editorRemote;

    //documents have size, tasks put state here
    public long    sizeLocal;
    public long    sizeRemote;

    //documents have URL, notes use the URL for the note content
    //goals use this for the URL that the remote UI is at
    public String  urlLocal;
    public String  urlRemote;

    //these are for tasks/goals only
    public String  assigneeLocal;
    public String  assigneeRemote;
    public int     priorityLocal;

    public JSONObject remoteCopy;


    public SyncStatus(ProjectSync _sync, int _type, String _uid) throws Exception {

        sync = _sync;
        type = _type;
        universalId = _uid;

    }

}
