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

import java.util.Vector;
import java.util.Enumeration;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.socialbiz.cog.exception.NGException;

/**
* ReminderMgr manages the collection of reminders for a page
*/
public class ReminderMgr extends DOMFace
{

    public ReminderMgr(Document doc, Element definingElement, DOMFace p)
    {
        super (doc, definingElement, p);
    }


    public Vector<ReminderRecord> getAllReminders()
        throws Exception
    {
        Vector<ReminderRecord> vc = getChildren("reminder", ReminderRecord.class);
        return vc;
    }

    public Vector<ReminderRecord> getOpenReminders() throws Exception {
        Vector<ReminderRecord> vc = getChildren("reminder", ReminderRecord.class);
        Vector<ReminderRecord> v = new Vector<ReminderRecord>();
        for (ReminderRecord rRec : vc) {
            if (rRec.isOpen()) {
                v.add(rRec);
            }
        }
        return v;
    }

    public Vector<ReminderRecord> getUserReminders(UserProfile up)throws Exception
    {
        Vector<ReminderRecord> result = new Vector<ReminderRecord>();
        for (ReminderRecord reminderRecord : getAllReminders()) {
            if(reminderRecord.isOpen() && up != null && up.hasAnyId(reminderRecord.getAssignee())){
                result.add(reminderRecord);
            }
        }
        return result;
    }

    public ReminderRecord findReminderByID(String id) throws Exception {
        Vector<ReminderRecord> v = getAllReminders();
        Enumeration<ReminderRecord> e = v.elements();
        while (e.hasMoreElements()) {
            ReminderRecord rRec = e.nextElement();
            if (id.equals(rRec.getId())) {
                return rRec;
            }
        }
        return null;
    }

    public ReminderRecord findReminderByIDOrFail(String id) throws Exception {
        ReminderRecord ret =  findReminderByID( id );
        if (ret==null) {
            throw new NGException("nugen.exception.reminder.not.found",new Object[]{id});
        }
        return ret;
    }

    public ReminderRecord createReminder(String id) throws Exception {
        return createChildWithID("reminder",
            ReminderRecord.class, "id", id);
    }

    public boolean removeReminder(String id) throws Exception {
        Vector<ReminderRecord> vc = getChildren("reminder", ReminderRecord.class);
        for (ReminderRecord child : vc) {
            if (id.equals(child.getAttribute("id"))) {
                removeChild(child);
                return true;
            }
        }
        // maybe this should throw an exception?
        return false;
    }

}
