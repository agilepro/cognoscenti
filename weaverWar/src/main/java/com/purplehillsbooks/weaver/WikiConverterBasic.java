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

import java.io.Writer;

import com.purplehillsbooks.streams.HTMLWriter;

/**
 * use the single static method:  writeWikiAsHtml(Writer w, String tv, String baseUrl)
 * 
 * Writes the HTML to the supplied Writer class.  The string is the markdown text to 
 * be converted.   
 */
public class WikiConverterBasic
{
    final static int NOTHING      = 0;
    final static int PARAGRAPH    = 1;
    final static int BULLET       = 2;
    final static int HEADER       = 3;
    final static int PREFORMATTED = 4;
    
    public final static char ESCAPE_CHAR = 'º';   

    private Writer out;
    private int majorState = 0;
    private int majorLevel = 0;
    private boolean isBold = false;
    private boolean isItalic = false;



    /**
    * Construct on the AuthRequest that output will be to
    */
    private WikiConverterBasic(Writer wrin) {
    	out = wrin;
    }
    

    /**
    * Static version create the object instance and then calls the
    * converter directly.   Convenience for the case where you are
    * going to use a converter only once, and only for HTML output.
    */
    public static void writeWikiAsHtml(Writer w, String tv) throws Exception
    {
        WikiConverterBasic wc = new WikiConverterBasic(w);
        wc.writeWikiAsHtml(tv);
    }

    /**
    * Takes a block of data formatted in wiki format, and converts
    * it to HTML, outputting that to the AuthRequest that was
    * passed in when the object was constructed.
    */
    private void writeWikiAsHtml(String tv) throws Exception {
        LineIterator li = new LineIterator(tv);
        while (li.moreLines()) {
            String thisLine = li.nextLine();
            formatText(thisLine);
        }
        terminate();
        out.flush();
    }

    private void formatText(String line) throws Exception {
        boolean isIndented = line.startsWith(" ");
        if (majorState != PREFORMATTED) {
            line = line.trim();
        }
        if (line.length() == 0) {
            if (majorState != PREFORMATTED) {
                terminate();
            }
        } else if (line.equals("{{{")) {
            startPRE();
        } else if (line.startsWith("}}}")) {
            terminate();
        } else if (line.startsWith("!!!")) {
            startHeader(line, 3);
        } else if (line.startsWith("!!")) {
            startHeader(line, 2);
        } else if (line.startsWith("!")) {
            startHeader(line, 1);
        } else if (line.startsWith("*****")) {
            startBullet(line, 5);
        } else if (line.startsWith("****")) {
            startBullet(line, 4);
        } else if (line.startsWith("***")) {
            startBullet(line, 3);
        } else if (line.startsWith("**")) {
            startBullet(line, 2);
        } else if (line.startsWith("*")) {
            startBullet(line, 1);
        } else if (line.startsWith(":")) {
            if (majorState == PARAGRAPH) {
                makeLineBreak();
            } else {
                startParagraph();
            }
            scanForStyle(line, 1);
        } else if (line.startsWith("----")) {
            terminate();
            makeHorizontalRule();
        } else if (isIndented) {
            // continue whatever mode there is
            scanForStyle(line, 0);
        }else {

            if (majorState != PARAGRAPH && majorState != PREFORMATTED) {
                startParagraph();
            }
            scanForStyle(line, 0);
        }
    }

    private void terminate() throws Exception {
        if (isBold) {
            out.write("</b>");
        }
        if (isItalic) {
            out.write("</i>");
        }
        if (majorState == NOTHING) {
        } else if (majorState == PARAGRAPH) {
            out.write("</p>\n");
        } else if (majorState == PREFORMATTED) {
            out.write("</pre>\n");
        } else if (majorState == BULLET) {
            out.write("</li>\n");
            while (majorLevel > 0) {
                out.write("</ul>\n");
                majorLevel--;
            }
        } else if (majorState == HEADER) {
            switch (majorLevel) {
            case 1:
                out.write("</h3>");
                break;
            case 2:
                out.write("</h2>");
                break;
            case 3:
                out.write("</h1>");
                break;
            }
        }
        majorState = NOTHING;
        majorLevel = 0;
        isBold = false;
        isItalic = false;
    }

    private void startParagraph() throws Exception {
        terminate();
        out.write("<p>\n");
        majorState = PARAGRAPH;
        majorLevel = 0;
    }

    private void startPRE() throws Exception {
        terminate();
        out.write("<pre>\n");
        majorState = PREFORMATTED;
        majorLevel = 0;
    }

    private void makeLineBreak() throws Exception {
        out.write("<br/>");
    }

    private void makeHorizontalRule() throws Exception {
        out.write("<hr/>");
    }

    private void startBullet(String line, int level) throws Exception {
        if (majorState != BULLET) {
            terminate();
            majorState = BULLET;
        } 
        else {
            out.write("</li>\n");
        }
        while (majorLevel > level) {
            out.write("</ul>\n");
            majorLevel--;
        }
        while (majorLevel < level) {
            out.write("<ul>\n");
            majorLevel++;
        }
        out.write("<li>\n");
        scanForStyle(line, level);
    }

    private void startHeader(String line, int level) throws Exception {
        terminate();
        majorState = HEADER;
        majorLevel = level;
        switch (level) {
        case 1:
            out.write("<h3>");
            break;
        case 2:
            out.write("<h2>");
            break;
        case 3:
            out.write("<h1>");
            break;
        }
        scanForStyle(line, level);
    }

    private void scanForStyle(String line, int scanStart) throws Exception {
        int pos = scanStart;
        int last = line.length();
        while (pos < last) {
            char ch = line.charAt(pos);
            switch (ch) {
            case '&':
                out.write("&amp;");
                pos++;
                continue;
            case '"':
                out.write("&quot;");
                pos++;
                continue;
            case '<':
                out.write("&lt;");
                pos++;
                continue;
            case '>':
                out.write("&gt;");
                pos++;
                continue;
            case '[':

                int pos2 = line.indexOf(']', pos);
                if (pos2 > pos + 1) {
                    String linkURL = line.substring(pos + 1, pos2);
                    outputLink(out, linkURL);
                    pos = pos2 + 1;
                } 
                else if (pos2 == pos + 1) {
                    pos = pos + 2;
                } 
                else {
                    pos = pos + 1;
                }
                continue;
            case '_':
                if (line.length() > pos + 1 && line.charAt(pos + 1) == '_') {
                    pos += 2;
                    if (isBold) {
                        out.write("</b>");
                    } 
                    else {
                        out.write("<b>");
                    }
                    isBold = !isBold;
                    continue;
                }
                break;
            case '\'':
                if (line.length() > pos + 1 && line.charAt(pos + 1) == '\'') {
                    pos += 2;
                    if (isItalic) {
                        out.write("</i>");
                    } 
                    else {
                        out.write("<i>");
                    }
                    isItalic = !isItalic;
                    continue;
                }
                break;
            case ESCAPE_CHAR:
                if (line.length() > pos + 1) {
                    char escape = line.charAt(pos + 1);
                    if (escape == '[' || escape == '\'' || escape == '_'  || escape == ESCAPE_CHAR) {
                        //only these characters can be escaped at this time
                        //if one of these, eliminate the ยบ, and output the following character without interpretation
                        ch = escape;
                        pos++;
                    }
                }
                break;
            }
            out.write(ch);
            pos++;
        }
        out.write("\n");
    }



    /**
    * outputLink does the job of parsing the "wiki link" value and
    * producing a valid HTML link to the desire thing.
    * Wiki Link values may have a vertical bar character separating the
    * display name of the link from the address.  If that vertical bar is
    * not there, then the entire thing is taken as an address.
    *
    * Either    [ link-name | link-address ]
    * or        [ link-address ]
    *
    * The address can either be the name of another page, or an HTTP hyperlink.
    * If the address is missing or invalid (no page can be named that)
    * then the display name is written without being a hyper link.
    * If the address is to an external page, then a normal hyperlink is made.
    * If the address is the name of a wiki page, then a hyperlink to that
    * page is made.  If the address is a valid name, but no page exists
    * with that name, then a link to the "CreatePage" function is created.
    *
    * The name part of the link
    */
    private void outputLink(Writer ar, String linkURL) throws Exception {

        int barPos = linkURL.indexOf("|");
        String linkName = linkURL.trim();
        String linkAddr = linkName;

        if (barPos >= 0) {
            linkName = linkURL.substring(0, barPos).trim();
            linkAddr = linkURL.substring(barPos + 1).trim();
        }

        // We treat any address that has forward slashes in it as an external
        // address which is included literally into the href.
        String titleValue = "This link leads to an external page";
        String target = "_blank";

        // if the link is missing, then just write the name out
        // might also include an indicator of the problem ....
        if (linkAddr.length() == 0) {
        	HTMLWriter.writeHtml(ar, linkName);
            return;
        }

        ar.write("<a href=\"");
        HTMLWriter.writeHtml(ar, linkAddr);
        ar.write("\" title=\"");
        HTMLWriter.writeHtml(ar, titleValue);
        if (target != null) {
            ar.write("\" target=\"");
            HTMLWriter.writeHtml(ar, target);
        }
        ar.write("\">");
        HTMLWriter.writeHtml(ar, linkName);
        ar.write("</a>");

    }

}
