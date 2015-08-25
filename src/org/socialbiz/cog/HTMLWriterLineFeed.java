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
import java.io.IOException;

/**
* @see HTMLWriter
*
* Like HTMLWriter except that a newline character is converted to a BREAK tag
* Allows you write text to HTML, and for the line feed characters to insert
* break tags, which cause a new line to begin.
*
* This is useful in line oriented text, when placed into HTML, so that it is
* not all wrapped into a single paragraph.  Makes the linefeed characters (newline)
* significant over other kinds of white space.
*
*/
public class HTMLWriterLineFeed extends Writer
{
    private Writer wrapped;

    public HTMLWriterLineFeed(Writer _wrapped)
    {
        wrapped = _wrapped;
    }

    public void  write(int c)
        throws IOException
    {
        writeHtmlCharLF(wrapped, c);
    }

    public void write(char[] chs, int start, int len)
        throws IOException
    {
        if (start<0)
        {
            throw new RuntimeException("negative start position passed to HTMLWriter.write(char[], int, int)");
        }
        if (len<0)
        {
            throw new RuntimeException("negative len passed to HTMLWriter.write(char[], int, int)");
        }
        int last=start+len;
        if (last>chs.length)
        {
            throw new RuntimeException("start + len ("+last+") is longer than char array size ("+chs.length+") passed to HTMLWriter.write(char[], int, int)");
        }
        for (int i=start; i<last; i++)
        {
            writeHtmlCharLF(wrapped, chs[i]);
        }
    }

    public void  close()
        throws IOException
    {
        wrapped.close();
    }

    public void  flush()
        throws IOException
    {
        wrapped.flush();
    }


    private static void writeHtmlCharLF(Writer w, int ch)
        throws IOException
    {
        switch (ch)
        {
            case '&':
                w.write("&amp;");
                return;
            case '<':
                w.write("&lt;");
                return;
            case '>':
                w.write("&gt;");
                return;
            case '"':
                w.write("&quot;");
                return;
            case '\n':
                w.write("<br/>\n");
                return;
            default:
                w.write(ch);
                return;
        }
    }

}