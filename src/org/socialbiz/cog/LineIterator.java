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
/**
* This class walks through a block of text, and pulls out each
* line one at a time, handling return and line feed characters
* correctly.  Usage pattern is:
*
* <pre>
*     LineIterator li = new LineInterator(textBlock);
*     while (li.moreLines())
*     {
*         String line = li.nextLine();
*         //process the line here
*     }
* </pre>
*/
public class LineIterator
{
    String source;        //original string passed in
    String currentLine;   //buffered parsed line
    int    nextBegin;     //position in the original string

    public LineIterator(String newSource)
    {
        source = newSource;
        scanForNextBegin();  //find beginning of first line
        nextLine();          //actually get first line in buffer
    }

    public boolean moreLines()
    {
        return currentLine!=null;
    }

    public String nextLine()
    {
        String retVal = currentLine;

        //each value can be gotten only once
        currentLine = null;

        if (nextBegin<0)
        {
            return retVal;
        }

        int endPos = source.indexOf("\n", nextBegin);

        if (endPos<0)
        {
            if (nextBegin<source.length())
            {
                currentLine = source.substring(nextBegin);
            }
            nextBegin = -1;
            return retVal;
        }

        currentLine = source.substring(nextBegin, endPos);
        nextBegin = endPos + 1;
        scanForNextBegin();
        return retVal;
    }

    /**
    * Starting at the current pointer position, skip all of
    * the linefeed characters finding either a
    * character that is not one, or finding the end
    * of the text, and marking this iterator as finished.
    */
    private void scanForNextBegin()
    {
        while (true)
        {
            if (nextBegin>=source.length())
            {
                nextBegin = -1;
                return;
            }
            char ch = source.charAt(nextBegin);
            if (ch!='\r')
            {
                return;
            }
            nextBegin++;
        }
    }

}
