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
import org.w3c.dom.Document;
import org.w3c.dom.Element;

public class PollRecord extends DOMFace
{
    public VoteRecord[] votes = null;


    public PollRecord(Document doc, Element ele, DOMFace p)
    {
        super(doc, ele, p);
        //some old polls have no id, so give them one....
        //a one will work if there is only one poll on a page
        //seems a reasonable assumption for now...
        String id = getId();
        if (id==null || id.length()==0)
        {
            setAttribute("id", "1");
        }
    }

    public String getProposition()
        throws Exception
    {
        return getScalar("proposition");
    }

    public String getId()
    {
        return getAttribute("id");
    }

    public String[] getChoices()
    {
        return new String[] {"Yes", "Maybe", "No"};
    }

    public long getEndDate()
        throws Exception
    {
        return safeConvertLong(getAttribute("endDate"));
    }

    public void setEndDate(long datetime)
        throws Exception
    {
        setAttribute("endDate", Long.toString(datetime));
    }


    public VoteRecord[] getVotes()
        throws Exception
    {
        if (votes!=null)
        {
            return votes;
        }
        Vector<VoteRecord> nl = getChildren("vote", VoteRecord.class);
        int last = nl.size();

        VoteRecord[] retVal = new VoteRecord[last];
        nl.copyInto(retVal);
        votes = retVal;
        return retVal;
    }

    public VoteRecord findVote(String name)
        throws Exception
    {
        if (votes==null)
        {
            getVotes();
        }
        int lastj = votes.length;
        for (int j=0; j<lastj; j++)
        {
            VoteRecord vote = votes[j];
            if (UserProfile.equalsOpenId(name, vote.getWho())) {
                return vote;
            }
        }
        return null;
    }

    public VoteRecord newVote(String name)
        throws Exception
    {
        VoteRecord vr = createChild("vote", VoteRecord.class);
        vr.setWho(name);
        vr.setTimestamp(System.currentTimeMillis());
        votes = null;   //clear out so recreated
        return vr;
    }

    public boolean voteRequired(UserProfile up)
        throws Exception
    {
        VoteRecord[] votes = getVotes();
        for (VoteRecord vote : votes)
        {
            if (up.hasAnyId(vote.getWho()))
            {
                return false;
            }
        }
        return true;
    }

}
