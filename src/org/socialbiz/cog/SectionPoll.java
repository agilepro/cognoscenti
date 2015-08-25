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

import java.io.Writer;

/**
* Deprecated Class to support Polls.  Instead, just use a note
*/
public class SectionPoll extends SectionUtil implements SectionFormat
{


    public SectionPoll()
    {

    }

    public String getName()
    {
        return "Poll Format";
    }


    public static void addPoll(NGSection section, String proposition)
    {
        throw new RuntimeException("Polls are no longer supported, and adding of them even less supported.");
    }

    public static PollRecord[] getPolls(NGSection section)
        throws Exception
    {
        throw new RuntimeException("Polls are no longer supported.");
    }


    public static PollRecord getPollById(NGSection section, String id)
        throws Exception
    {
        throw new RuntimeException("Polls are no longer supported.");
    }

    public void addVote(NGSection section, String id, String who, String choice,
                        String comment, long newTime)
        throws Exception
    {
        throw new RuntimeException("Polls are no longer supported.");
    }

    public void addVote(NGSection section, int pollnum, String who, String choice,
                        String comment, long newTime)
        throws Exception
    {

        throw new RuntimeException("Polls are no longer supported.");
    }

    public void addVote(NGSection section, PollRecord poll, String who, String choice,
                        String comment, long newTime)
        throws Exception
    {
        throw new RuntimeException("Polls are no longer supported.");
    }

    public void removePoll(String pollId, NGSection section)
    {
        throw new RuntimeException("Polls are no longer supported.");
    }

    public void writePlainText(NGSection section, Writer out) throws Exception
    {
        throw new RuntimeException("Polls are no longer supported.");
    }

    /**
    * returns null if there is no poll, or if all of the existing polls have
    * a vote from this user.  If there is a poll that needs an answer, this
    * wil return the string description of the first such poll.  If there are
    * two or more, there is nothing from the latter polls.
    */
    public static String responseRequired(AuthRequest ar, NGSection ngs, UserProfile up)
        throws Exception
    {
        throw new RuntimeException("Polls are no longer supported.");
    }


    /**
    * A poll times out at a particular time.  This can be set to date of now or
    * in the past in order to disable the prompting for answering a poll.
    */
    public static void setPollEndDate(NGSection ngs, int pollNum, long dateOfClosing)
        throws Exception
    {
        throw new RuntimeException("Polls are no longer supported.");
    }
}
