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

/**
 * Implements the Wiki formatting.
 * NOTE: this is NOT muti-thread safe!   Use on only one thread
 * at a time.  Usage pattern:
 *
 * WikiConverter wc = new WikiConverter(ar);
 * wc.writeWikiAsHtml(wikiData);
 *
 * writeWikiAsHtml can be called multiple times, but only from
 * a single thread.
 */
public class WikiConverter
{


    /**
    * Construct on the AuthRequest that output will be to
    */
    public WikiConverter(AuthRequest destination)
    {
        ar = destination;
        UserProfile up = ar.getUserProfile();
        if (up==null)
        {
            userKey = "xxxx";
        }
        else
        {
            userKey = up.getKey();
        }
    }

    /**
    * Static version create the object instance and then calls the
    * converter directly.   Convenience for the case where you are
    * going to use a converter only once, and only for HTML output.
    */
    public static void writeWikiAsHtml(AuthRequest destination, String tv) throws Exception
    {
        WikiConverter wc = new WikiConverter(destination);
        wc.writeWikiAsHtml(tv);
    }

    /**
    * Takes a block of data formatted in wiki format, and converts
    * it to HTML, outputting that to the AuthRequest that was
    * passed in when the object was constructed.
    */
    public void writeWikiAsHtml(String tv) throws Exception
    {
        LineIterator li = new LineIterator(tv);
        while (li.moreLines())
        {
            String thisLine = li.nextLine();
            formatText(thisLine);
        }
        terminate();
        ar.flush();
    }

    final static int NOTHING      = 0;
    final static int PARAGRAPH    = 1;
    final static int BULLET       = 2;
    final static int HEADER       = 3;
    final static int PREFORMATTED = 4;

    protected AuthRequest ar;
    protected int majorState = 0;
    protected int majorLevel = 0;
    protected boolean isBold = false;
    protected boolean isItalic = false;
    protected String userKey;

    protected void formatText(String line) throws Exception
    {
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
        } else if (line.startsWith("%%")) {
            fomatFontStyle(line);
        }else if (line.endsWith("%%")) {
            fomatFontStyle(line);
        }else {

            if (majorState != PARAGRAPH && majorState != PREFORMATTED) {
                startParagraph();
            }
            scanForStyle(line, 0);
        }
    }

    protected void terminate() throws Exception
    {
        if (isBold) {
            ar.write("</b>");
        }
        if (isItalic) {
            ar.write("</i>");
        }
        if (majorState == NOTHING) {
        } else if (majorState == PARAGRAPH) {
            ar.write("</p>\n");
        } else if (majorState == PREFORMATTED) {
            ar.write("</pre>\n");
        } else if (majorState == BULLET) {
            ar.write("</li>\n");
            while (majorLevel > 0) {
                ar.write("</ul>\n");
                majorLevel--;
            }
        } else if (majorState == HEADER) {
            switch (majorLevel) {
            case 1:
                ar.write("</h3>");
                break;
            case 2:
                ar.write("</h2>");
                break;
            case 3:
                ar.write("</h1>");
                break;
            }
        }
        majorState = NOTHING;
        majorLevel = 0;
        isBold = false;
        isItalic = false;
    }

    protected void startParagraph() throws Exception
    {
        terminate();
        ar.write("<p>\n");
        majorState = PARAGRAPH;
        majorLevel = 0;
    }

    protected void startPRE() throws Exception
    {
        terminate();
        ar.write("<pre>\n");
        majorState = PREFORMATTED;
        majorLevel = 0;
    }

    protected void makeLineBreak()
        throws Exception
    {
        ar.write("<br/>");
    }

    protected void makeHorizontalRule()
        throws Exception
    {
        ar.write("<hr/>");
    }

    protected void startBullet(String line, int level)
            throws Exception
    {
        if (majorState != BULLET) {
            terminate();
            majorState = BULLET;
        } else {
            ar.write("</li>\n");
        }
        while (majorLevel > level) {
            ar.write("</ul>\n");
            majorLevel--;
        }
        while (majorLevel < level) {
            ar.write("<ul>\n");
            majorLevel++;
        }
        ar.write("<li>\n");
        scanForStyle(line, level);
    }

    protected void startHeader(String line, int level)
            throws Exception
    {
        terminate();
        majorState = HEADER;
        majorLevel = level;
        switch (level) {
        case 1:
            ar.write("<h3>");
            break;
        case 2:
            ar.write("<h2>");
            break;
        case 3:
            ar.write("<h1>");
            break;
        }
        scanForStyle(line, level);
    }

    protected void scanForStyle(String line, int scanStart)
            throws Exception
    {
        int pos = scanStart;
        int last = line.length();
        while (pos < last) {
            char ch = line.charAt(pos);
            switch (ch) {
            case '&':
                ar.write("&amp;");
                pos++;
                continue;
            case '"':
                ar.write("&quot;");
                pos++;
                continue;
            case '<':
                ar.write("&lt;");
                pos++;
                continue;
            case '>':
                ar.write("&gt;");
                pos++;
                continue;
            case '[':

                int pos2 = line.indexOf(']', pos);
                if (pos2 > pos + 1) {
                    String linkURL = line.substring(pos + 1, pos2);
                    outputProperLink(linkURL);
                    pos = pos2 + 1;
                } else if (pos2 == pos + 1) {
                    pos = pos + 2;
                } else {
                    pos = pos + 1;
                }
                continue;
            case '#':
                int tagEnd = findIdentifierEnd(line, pos+1);
                String tagName = line.substring(pos+1,tagEnd);
                outputTagLink(tagName);
                pos = tagEnd;
                continue;
            case '_':
                if (line.length() > pos + 1 && line.charAt(pos + 1) == '_') {
                    pos += 2;
                    if (isBold) {
                        ar.write("</b>");
                    } else {
                        ar.write("<b>");
                    }
                    isBold = !isBold;
                    continue;
                }
                break;
            case '\'':
                if (line.length() > pos + 1 && line.charAt(pos + 1) == '\'') {
                    pos += 2;
                    if (isItalic) {
                        ar.write("</i>");
                    } else {
                        ar.write("<i>");
                    }
                    isItalic = !isItalic;
                    continue;
                }
                break;
            case 'º':
                if (line.length() > pos + 1) {
                    char escape = line.charAt(pos + 1);
                    if (escape == '[' || escape == '\'' || escape == '_'  || escape == 'º') {
                        //only these characters can be escaped at this time
                        //if one of these, eliminate the º, and output the following character without interpretation
                        ch = escape;
                        pos++;
                    }
                }
                break;
            }
            ar.write(ch);
            pos++;
        }
        ar.write("\n");
    }


    protected void outputTagLink(String tagName)
        throws Exception
    {
        ar.write("#");
        if (tagName.length()<3)
        {
            ar.writeHtml(tagName);
        }
        else
        {
            ar.write("<a href=\"");
            ar.write(ar.retPath);
            ar.write("v/");
            ar.write(userKey);
            ar.write("/TagLinks.htm?t=");
            ar.writeURLData(tagName);
            ar.write("\">");
            ar.writeHtml(tagName);
            ar.write("</a>");
        }
    }

    /**
    * Returns either the position of a white space, or it
    * returns the length of the line if no white space char found
    */
    public static int findIdentifierEnd(String line, int pos)
    {
        int last = line.length();
        while (pos < last)
        {
            char ch = line.charAt(pos);
            if (!Character.isLetterOrDigit(ch) && ch!='_')
            {
                return pos;
            }
            pos++;
        }
        return pos;
    }

    /**
    * Given a block of wiki formatted text, this will find all the
    * links within the block, and return a vector with just the
    * links in them.
    */
    public void findLinks(Vector<String> v, NGSection section) throws Exception
    {
        LineIterator li = new LineIterator(section.asText().trim());
        while (li.moreLines())
        {
            String thisLine = li.nextLine();
            scanLineForLinks(thisLine, v);
        }
    }

    protected void scanLineForLinks(String thisLine, Vector<String> v)
    {
        int bracketPos = thisLine.indexOf('[');
        int startPos = 0;
        while (bracketPos >= startPos) {
            int endPos = thisLine.indexOf(']', bracketPos);
            if (endPos <= startPos) {
                return; // could not find any more closing brackets, leave
            }
            String link = thisLine.substring(bracketPos + 1, endPos);
            v.add(link);
            startPos = endPos + 1;
            bracketPos = thisLine.indexOf('[', startPos);
        }
    }


    public void outputProperLink(String linkURL) throws Exception {
        outputLink(ar, linkURL);
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
    private static void outputLink(AuthRequest ar, String linkURL)
            throws Exception {
        boolean isImage = linkURL.startsWith("IMG:");

        int barPos = linkURL.indexOf("|");
        String linkName = linkURL.trim();
        String linkAddr = linkName;
        boolean userSpecifiedName = false;

        if (barPos >= 0) {
            linkName = linkURL.substring(0, barPos).trim();
            linkAddr = linkURL.substring(barPos + 1).trim();
            userSpecifiedName = true;
        }

        // We treat any address that has forward slashes in it as an external
        // address which is included literally into the href.
        boolean isExternal = (linkAddr.startsWith("http") && linkAddr.indexOf("/") >= 0);
        boolean pageExists = true;
        String specialGraphic = null;
        String target = null;
        String titleValue = linkURL;
        if (isExternal) {
            target = "_blank";
            titleValue = "This link leads to an external page";
        }

        // if the link is missing, then just write the name out
        // might also include an indicator of the problem ....
        if (linkAddr.length() == 0) {
            ar.writeHtml(linkName);
            return;
        }

        if (!isExternal) {
            // if the sanitized version of the link is empty, which might happen
            // if
            // the link was all punctuation, then just write the name out
            // might also include an indicator of the problem ....
            String sanitizedName = SectionWiki.sanitize(linkAddr);
            if (sanitizedName.length() == 0) {
                ar.writeHtml(linkName);
                return;
            }

            Vector<NGPageIndex> foundPages = ar.getCogInstance().getPageIndexByName(linkAddr);
            if (foundPages.size() == 1) {
                NGPageIndex foundPI = foundPages.firstElement();
                linkAddr = ar.baseURL
                        + ar.getResourceURL(foundPI, "notesList.htm");
                if (!userSpecifiedName) {
                    linkName = foundPI.containerName; // use the best name for
                                                        // page
                }
                titleValue = "Navigate to the project: " + linkName;
                pageExists = !foundPI.isDeleted;
                specialGraphic = "deletedLink.gif";
            } else if (foundPages.size() == 0) {
                pageExists = false;
                specialGraphic = "createicon.gif";
                NGPage sourcePage = (NGPage) ar.ngp;
                String bookName = "mainbook";
                String sourceName = "main";
                if (sourcePage != null) {
                    sourceName = sourcePage.getFullName();
                    NGBook ngb = sourcePage.getSite();
                    if (ngb != null) {
                        bookName = ngb.getKey();
                    }
                }
                titleValue = "Project does not exist, but click here to create one.";

                if (ar.isNewUI() && ar.isLoggedIn()) {
                    linkAddr = "javascript:brokenLink(" + isImage + ",'"
                            + linkName + "','" + linkAddr + "')";
                } else {
                    linkAddr = ar.retPath + "CreatePage.jsp?pt="
                            + SectionUtil.encodeURLData(linkAddr) + "&b="
                            + SectionUtil.encodeURLData(bookName) + "&s="
                            + SectionUtil.encodeURLData(sourceName);
                }
            } else {
                // this is the case where there is more than one page
                linkAddr = ar.retPath + "Disambiguate.jsp?n="
                        + SectionUtil.encodeURLData(linkAddr);
                titleValue = "There is more than one project named " + linkAddr;

            }
        }
        if (isImage) {
            linkName = linkName.substring(4);
            if (pageExists) {
                ar.write("<a href=\"");
                ar.writeHtml(linkAddr);
                ar.write("\" title=\"");
                ar.writeHtml(titleValue);
                ar.write("\">");
                ar.write("<img src=\"");
                ar.writeHtml(linkName);
                ar.write("\"/>");
                ar.write("</a>");
            } else {
                ar.write("<img src=\"");
                ar.writeHtml(linkName);
                ar.write("\"/>");
            }
        } else // not an image
        {
            if (pageExists) {
                ar.write("<a href=\"");
                ar.writeHtml(linkAddr);
                ar.write("\" title=\"");
                ar.writeHtml(titleValue);
                if (target != null) {
                    ar.write("\" target=\"");
                    ar.writeHtml(target);
                }
                ar.write("\">");
                ar.writeHtml(linkName);
                ar.write("</a>");
            } else if (!ar.isLoggedIn() || ar.isStaticSite()) {
                // if page does not exist, and you are not logged in, then
                // simply display
                // the name without making it a link. Anonymous people will only
                // see
                // links (within the wiki) that work.
                ar.writeHtml(linkName);
            } else {
                ar.write("<a href=\"");
                ar.writeHtml(linkAddr);
                ar.write("\" title=\"");
                ar.writeHtml(titleValue);
                ar.write("\">");
                ar.writeHtml(linkName);
                // the icon indicates condition of page
                ar.write("<img src=\"");
                ar.write(ar.retPath);
                ar.write(specialGraphic);
                ar.write("\"/>");
                ar.write("</a>");
            }
        }

    }

    /**
    * Given a block of wiki formatted text, this will strip out all the
    * formatting characters, but write out everything else as plain text.
    */
    public void writePlainText(String wikiData) throws Exception
    {
        LineIterator li = new LineIterator(wikiData);
        while (li.moreLines())
        {
            String thisLine = li.nextLine();
            removeWikiFormattings(thisLine);
            ar.write(" ");
        }
    }

    protected void removeWikiFormattings(String line)
            throws Exception
    {
        if (line == null || ((line = line.trim()).length()) == 0) {
            return;
        }

        if (line.startsWith("----"))
        {
            line = line.substring(4);
        }
        else if (line.startsWith("!!!") || (line.startsWith("***")))
        {
            line = line.substring(3);
        }
        else if (line.startsWith("!!") || (line.startsWith("**")))
        {
            line = line.substring(2);
        }
        else if (line.startsWith("!") || (line.startsWith("*")))
        {
            line = line.substring(1);
        }
        ar.write(line);
    }

    protected void fomatFontStyle(String line) throws Exception{
        boolean scan = false;
        if(line.startsWith("%%(")){
            int indx = line.indexOf(')');
            String attr = line.substring(3,indx);
            attr = attr.replaceAll(":", "=");
            ar.write("<FONT " + attr + ">");
            line = line.substring(indx + 1);
            scan = true;
        }
        if(line.endsWith("%%")){
            line = line.substring(0, line.lastIndexOf("%%"));
            scanForStyle(line, 0);
            scan = false;
            ar.write("</FONT>");
        }
        if(scan){
            scanForStyle(line, 0);
        }
    }

}
