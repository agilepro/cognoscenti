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

import java.io.OutputStream;
import java.io.StringWriter;
import java.util.List;
import java.util.Vector;

import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDPage;
import org.apache.pdfbox.pdmodel.common.PDRectangle;
import org.apache.pdfbox.pdmodel.edit.PDPageContentStream;
import org.apache.pdfbox.pdmodel.font.PDFont;
import org.apache.pdfbox.pdmodel.font.PDType1Font;
import org.apache.pdfbox.pdmodel.graphics.color.PDGamma;
import org.apache.pdfbox.pdmodel.interactive.action.type.PDActionURI;
import org.apache.pdfbox.pdmodel.interactive.annotation.PDAnnotationLink;
import org.apache.pdfbox.pdmodel.interactive.annotation.PDBorderStyleDictionary;

/**
 * Takes the Wiki formated text, and produces PDF output.
 * NOTE: this is NOT muti-thread safe!   Use on only one thread
 * at a time.  Usage pattern:
 *
 * WikiConverter wc = new WikiConverter(ar);
 * wc.writeWikiAsHtml(wikiData);
 *
 * writeWikiAsHtml can be called multiple times, but only from
 * a single thread.
 */
public class WikiToPDF
{

    final static int NOTHING      = 0;
    final static int PARAGRAPH    = 1;
    final static int BULLET       = 2;
    final static int HEADER       = 3;
    final static int PREFORMATTED = 4;

    protected AuthRequest ar;
    protected int majorState = 0;
    protected int majorLevel = 0;
    protected String userKey;

    private PDDocument pddoc;
    private PDPage pdpage;
    private PDPageContentStream contentStream;
    float xPos = 200f;
    float yPos = 800f;
    float lineRemainder = 0f;
    int   paraTrailing = 0;
    int   indent = 0;

    final static int TOP_MARGIN = 725;    //Absolute top of text
    final static int BOTTOM_MARGIN = 60;  //Never print below this
    final static int LEFT_MARGIN = 75;    //Absolute left of text
    final static int RIGHT_MARGIN = 550;  //Absolute right of text

    protected String headerText = "Header here  --------------------- ";
    protected String footerText = "Footer here  --------------------- ";
    protected int    pageNum = 1;

    boolean isNewPage;


    private class FontFamily {

        PDFont norm;
        PDFont bold;
        PDFont italic;
        PDFont boldItalic;

        public FontFamily(PDFont a, PDFont b, PDFont c, PDFont d) {
            norm = a; bold = b; italic = c; boldItalic = d;
        }

        public PDFont getFont(boolean aBold, boolean aItalic) {

            if (aBold) {
                if (aItalic) {
                    return boldItalic;
                }
                else {
                    return bold;
                }
            }
            else {
                if (aItalic) {
                    return italic;
                }
                else {
                    return norm;
                }
            }
        }
    }

    protected FontFamily helvetica = new FontFamily(PDType1Font.HELVETICA,
        PDType1Font.HELVETICA_BOLD, PDType1Font.HELVETICA_OBLIQUE,
        PDType1Font.HELVETICA_BOLD_OBLIQUE);

    protected FontFamily times = new FontFamily(PDType1Font.TIMES_ROMAN,
        PDType1Font.TIMES_BOLD, PDType1Font.TIMES_ITALIC,
        PDType1Font.TIMES_BOLD_ITALIC);

    protected FontFamily courier = new FontFamily(PDType1Font.COURIER,
        PDType1Font.COURIER_BOLD, PDType1Font.COURIER_OBLIQUE,
        PDType1Font.COURIER_BOLD_OBLIQUE);

    protected boolean isBold = false;
    protected boolean isItalic = false;
    protected FontFamily currentFamily = helvetica;
    protected PDFont     currentFont   = PDType1Font.HELVETICA;
    protected int currentLineSize = 12;   //used for calculating the first line position when a new page feed
    protected int currentTrailingSpace = 0;  //how much space to add at the end of this paragraph.

    // The layout engine works like this.  A new page is set to a specific top coordinate
    // minus the current line size == font size. The top of text should be pretty consistent.
    //
    // When a new paragraph starts, it moves the trailing, then preceeding space of the next paragraph
    // type, then it figures whether it needs to move to the next page.
    //
    // Every new line does the same thing, advance by the amount of the line size, then
    // figure whether it needs to go to the next page.  Set the font BEFORE newline.



    /**
    * Construct on the AuthRequest that output will be to
    */
    public WikiToPDF(AuthRequest newar) throws Exception {
        ar = newar;
        userKey = "xxxx";
        UserProfile up = ar.getUserProfile();
        if (up!=null) {
            userKey = up.getKey();
        }
    }




    /**
    * This is a thack due to code trasition.
    * decodes the request parameters and then causes the PDF generation
    * try not to use this if possible.
    */
    public static void handlePDFRequest(AuthRequest ar, NGPage ngp) throws Exception{
        ar.setPageAccessLevels(ngp);

        Vector<NoteRecord> publicNotes = new Vector<NoteRecord>();
        Vector<NoteRecord> memberNotes = new Vector<NoteRecord>();

        String[] publicNoteIDs = ar.req.getParameterValues("publicNotes");
        String[] memberNoteIDs = ar.req.getParameterValues("memberNotes");
        if (publicNoteIDs==null) {
            publicNoteIDs = new String[0];
        }
        if (memberNoteIDs==null) {
            memberNoteIDs = new String[0];
        }

        for (String noteId : publicNoteIDs) {
            NoteRecord lrt = ngp.getNote(noteId);
            if (lrt!=null) {
                if (lrt.getVisibility()==SectionDef.PUBLIC_ACCESS) {
                    publicNotes.add(lrt);
                }
                else {
                    memberNotes.add(lrt);
                }
            }
        }
        for (String noteId : memberNoteIDs) {
            NoteRecord lrt = ngp.getNote(noteId);
            if (lrt!=null) {
                if (lrt.getVisibility()==SectionDef.PUBLIC_ACCESS) {
                    publicNotes.add(lrt);
                }
                else {
                    memberNotes.add(lrt);
                }
            }
        }

        WikiToPDF wc = new WikiToPDF(ar);
        wc.writeWikiAsPDF(ngp, publicNotes, memberNotes);
    }



    public void writeWikiAsPDF(NGPage ngp, Vector<NoteRecord> publicNoteList,
            Vector<NoteRecord> memberNoteList)  throws Exception {

        if (publicNoteList == null) {
            throw new Exception("The publicNoteList parameter must not be null.  Send an empty collection instead");
        }
        if (memberNoteList == null) {
            throw new Exception("The memberNoteList parameter must not be null.  Send an empty collection instead");
        }

        int totalNotes = publicNoteList.size() + memberNoteList.size();
        pddoc = new PDDocument();

        if (totalNotes>1) {
            writeTOCPage(ngp, publicNoteList, memberNoteList);
        }

        int noteCount = 0;
        if(publicNoteList.size() > 0){
            for (NoteRecord lr : publicNoteList) {
                noteCount++;
                writeNoteToPDF(ngp, lr, noteCount);
            }
        }

        if(memberNoteList.size() > 0){
            for (NoteRecord lr : memberNoteList) {
                noteCount++;
                writeNoteToPDF(ngp, lr, noteCount);
            }
        }

        endPage();

        String fileName = ngp.getKey() + ".pdf";
        ar.resp.setContentType("application/pdf");
        ar.resp.setHeader( "Content-Disposition", "attachment; filename=\"" + fileName + "\"" );
        OutputStream out = ar.resp.getOutputStream();
        pddoc.save(out);
        pddoc.close();
        out.flush();
    }


    private void writeTOCPage(NGPage ngp, Vector<NoteRecord> publicNoteList,
            Vector<NoteRecord> memberNoteList)  throws Exception {
        headerText = "Topic report generated from Cognoscenti";
        footerText = "Generated: 2012-06-23  --  Page 1";

        startPage();

        String projectName = ngp.getFullName();
        setPFont();
        newLine();
        writeWrappedLine("Workspace:");

        setH1Font();
        newLine();
        writeWrappedLine(projectName);

        int noteCount = 0;

        if(publicNoteList.size() > 0){
            setPFont();
            newLine();
            newLine();
            writeWrappedLine("Public Topics in this report: ");
            for (NoteRecord note : publicNoteList) {
                noteCount++;
                setH2Font();
                newLine();
                writeWrappedLine(Integer.toString(noteCount)+": "+note.getSubject());
            }
        }

        if(memberNoteList.size() > 0){
            setPFont();
            newLine();
            newLine();
            writeWrappedLine("Member Topics: ");
            for (NoteRecord note : memberNoteList) {
                noteCount++;
                setH2Font();
                newLine();
                writeWrappedLine(Integer.toString(noteCount)+": "+note.getSubject());
            }
        }

        endPage();
    }


    /**
    * Takes a block of data formatted in wiki format, and converts
    * it to HTML, outputting that to the AuthRequest that was
    * passed in when the object was constructed.
    */
    public void writeNoteToPDF(NGPage ngp, NoteRecord note, int noteNum) throws Exception
    {
        NGBook book = ngp.getSite();

        String subject = stripBadCharacters(note.getSubject());
        UserRef lastEditor = note.getModUser();
        StringWriter out = new StringWriter();
        SectionUtil.nicePrintDateAndTime(out, note.getLastEdited());
        String editTime = out.toString();

        out = new StringWriter();
        SectionUtil.nicePrintDate(out, ar.nowTime);
        String printTime = out.toString();

        headerText = "Topic "+noteNum+": "+subject;
        footerText = "Generated: "+printTime+"  --  Page "+pageNum;
        if(!isNewPage){
            endPage();
            startPage();
        }
        indent=0;

        setH1Font();
        newLine();
        writeWrappedLine(subject);

        setH1Font();
        currentLineSize = 8;  //but really small
        newLine();
        writeWrappedLine("Workspace: "+ngp.getFullName()+", Site: "+book.getFullName());
        newLine();
        writeWrappedLine("Last modified by:  "+lastEditor.getName()+" on "+editTime);

        box(LEFT_MARGIN-2, TOP_MARGIN+2, RIGHT_MARGIN+2, (int) yPos-3);
        currentLineSize = 12;
        newLine();

        String data = note.getWiki();
        LineIterator li = new LineIterator(data);
        while (li.moreLines())
        {
            String thisLine = li.nextLine();
            formatText(thisLine);
        }
        terminate();
    }


    private void setH1Font()
    {
        isBold = false;
        isItalic = false;
        currentFamily = helvetica;
        currentFont = currentFamily.getFont(isBold, isItalic);
        currentLineSize = 16;
    }

    private void setH2Font()
    {
        isBold = false;
        isItalic = false;
        currentFamily = helvetica;
        currentFont = currentFamily.getFont(isBold, isItalic);
        currentLineSize = 14;
    }

    private void setH3Font()
    {
        isBold = false;
        isItalic = false;
        currentFamily = helvetica;
        currentFont = currentFamily.getFont(isBold, isItalic);
        currentLineSize = 12;
    }

    private void setPFont()
    {
        isBold = false;
        isItalic = false;
        currentFamily = times;
        currentFont = currentFamily.getFont(isBold, isItalic);
        currentLineSize = 10;
    }

    private void setPREFont()
    {
        isBold = false;
        isItalic = false;
        currentFamily = courier;
        currentFont = currentFamily.getFont(isBold, isItalic);
        currentLineSize = 10;
    }


    /**
    * Advance down the page by the current line size.  If this is below the
    * bottom margin, then force a new page feed and continue
    */
    private void newLine() throws Exception
    {
        if (yPos-currentLineSize<BOTTOM_MARGIN) {
            endPage();
            startPage();
        }
        yPos  -= currentLineSize;
        contentStream.moveTextPositionByAmount( LEFT_MARGIN+indent-xPos-20, -currentLineSize);
        //contentStream.drawString(">");
        contentStream.moveTextPositionByAmount( 20, 0);

        xPos = LEFT_MARGIN + indent;

        currentFont = currentFamily.getFont(isBold,isItalic);
        contentStream.setFont(currentFont, currentLineSize);
        isNewPage = false;
        lineRemainder = RIGHT_MARGIN - LEFT_MARGIN - indent;

    }


    /**
    * adds vertical space, but does not attempt to create a new page or
    * anything at this level.
    */
    private void moveDown(int amt) throws Exception
    {
        yPos  -= paraTrailing;
        contentStream.moveTextPositionByAmount( 0, -paraTrailing);
    }


    /**
    * low level routine, be careful.  String must be clean, and you
    * must check before hand that you have enough room to write it.
    */
    private void writeText(String text) throws Exception {
        contentStream.drawString(text);
        lineRemainder = lineRemainder - (currentFont.getStringWidth(text)*currentLineSize)/1000f;
    }


    /**
    * eliminate any chars > 128 because PDFBox can't handle them right now
    * also eliminate double white space characters to simulate HTML
    */
    private String stripBadCharacters(String text)  throws Exception
    {
        StringBuffer cleanedText = new StringBuffer();
        boolean alreadyWhite = false;
        for (int i=0; i<text.length(); i++) {
            char ch = text.charAt(i);
            if (ch==' ' || ch=='\t' || ch=='\n') {
                if (!alreadyWhite) {
                    cleanedText.append(' ');
                }
                alreadyWhite = true;
            }
            else if (ch > ' ' && ch <= (char)127) {
                cleanedText.append(ch);
                alreadyWhite = false;
            }
            else if (ch==8211) {
                //microsoft fancy hyphen character
                cleanedText.append('-');
                alreadyWhite = false;
            }
            else if (ch==8216 || ch==8217) {
                //microsoft fancy quote characters
                cleanedText.append('\'');
                alreadyWhite = false;
            }
            else if (ch==8230) {
                //microsoft fancy elipsis character
                cleanedText.append("...");
                alreadyWhite = false;
            }
            else if (ch==8220 || ch==8221) {
                //microsoft fancy double quote characters
                cleanedText.append('\"');
                alreadyWhite = false;
            }
            else {
                //cleanedText.append("{");
                //cleanedText.append(Integer.toString(ch));
                //cleanedText.append("}");
                cleanedText.append("?");
                alreadyWhite = false;
            }
        }
        return cleanedText.toString();
    }


    private void writeWrappedLine(String text) throws Exception {
        if (isNewPage) {
            throw new Exception("don't write a line until after NewLine is called at least once.");
        }
        contentStream.setFont(currentFont, currentLineSize);

        text = stripBadCharacters(text);


        //see if it can be output completely
        float textWidth = (currentFont.getStringWidth(text)*currentLineSize) /1000f;
        if (textWidth <= lineRemainder) {
            writeText(text);
            return;
        }

        //line is too long, and we need to wrap it down.  Start by finding
        //word breaks that might do
        for (int i=text.length()-1; i>0; --i) {

            if (text.charAt(i)==' ') {
                String try1 = text.substring(0,i).trim();
                String rest = text.substring(i).trim();
                textWidth = (currentFont.getStringWidth(try1)*currentLineSize) /1000f;
                if (textWidth<=lineRemainder) {
                    writeText(try1+" ");
                    newLine();
                    writeWrappedLine(rest);
                    return;
                }
            }

        }

        //if we get here, it is because there was NO suitable wordwrap point
        //so do it again, but just chop the line in the middle of a word.
        //yet only if have at least 10 characters to add.
        for (int i=text.length()-8; i>10; --i) {

            String try1 = text.substring(0,i);
            String rest = text.substring(i);
            textWidth = (currentFont.getStringWidth(try1)*currentLineSize) /1000f;
            if (textWidth<=lineRemainder) {
                writeText(try1+" ");
                newLine();
                writeWrappedLine(rest);
                return;
            }
        }

        //can't even find a good place to split a word, so just wrap the whole
        //thing to the next line, and hope this is not an endless loop
        newLine();
        writeWrappedLine(text);
        return;

    }


    private void box(int x1, int y1, int x2, int y2) throws Exception {
        contentStream.drawLine(x1, y1, x2, y1);
        contentStream.drawLine(x1, y1, x1, y2);
        contentStream.drawLine(x2, y1, x2, y2);
        contentStream.drawLine(x1, y2, x2, y2);
    }

    private void startPage()  throws Exception {
        pdpage = new PDPage();

        pdpage.setMediaBox(PDPage.PAGE_SIZE_LETTER);
        pddoc.addPage( pdpage );

        xPos = LEFT_MARGIN;
        yPos = TOP_MARGIN;   //but don't write here, do a newline first!

        contentStream = new PDPageContentStream(pddoc, pdpage, true, false);

        /*    draw a boundary box at margins
        box(LEFT_MARGIN, TOP_MARGIN, RIGHT_MARGIN, BOTTOM_MARGIN);
        */

        contentStream.beginText();
        //really small font for the header and footer
        contentStream.setFont(helvetica.getFont(false,false), 8);
        contentStream.moveTextPositionByAmount( xPos, yPos + 20 );
        contentStream.drawString(headerText);
        contentStream.moveTextPositionByAmount( 0, BOTTOM_MARGIN - TOP_MARGIN - 40 );
        contentStream.drawString(footerText);
        contentStream.moveTextPositionByAmount( 0, TOP_MARGIN + 20 - BOTTOM_MARGIN );

        currentFont = currentFamily.getFont(isBold,isItalic);
        contentStream.setFont(currentFont, currentLineSize);

        isNewPage = true;
        lineRemainder = 0f;
        pageNum++;
    }

    private void endPage()  throws Exception {
        if (contentStream!=null) {
            contentStream.endText();
            contentStream.close();
        }
        contentStream = null;
        pdpage = null;
        lineRemainder = 0f;
    }


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
            scanForStyle(line, skipSpaces(line,0));
        }else {

            if (majorState != PARAGRAPH && majorState != PREFORMATTED) {
                startParagraph();
            }
            scanForStyle(line, 0);
        }
    }

    protected void terminate() throws Exception
    {
        if (majorState == NOTHING) {
            //nothing to do
        } else if (majorState == PARAGRAPH) {
            //nothing to do
        } else if (majorState == PREFORMATTED) {
            //nothing to do
        } else if (majorState == BULLET) {
            //nothing to do
            while (majorLevel > 0) {
                //nothing to do
                majorLevel--;
            }
        } else if (majorState == HEADER) {
            switch (majorLevel) {
            case 1:
                //nothing to do
                break;
            case 2:
                //nothing to do
                break;
            case 3:
                //nothing to do
                break;
            }
        }

        //add any additional space after paragraph end
        moveDown(paraTrailing);
        paraTrailing = 0;

        majorState = NOTHING;
        majorLevel = 0;
        isBold = false;
        isItalic = false;
    }

    protected void startParagraph() throws Exception
    {
        terminate();
        moveDown(8);   //space before the paragraph
        setPFont();
        indent = 0;
        newLine();     //gets you to the beginning of the line
        paraTrailing = 8;  //will be at end
        majorState = PARAGRAPH;
        majorLevel = 0;
    }

    protected void startPRE() throws Exception
    {
        terminate();
        setPREFont();
        majorState = PREFORMATTED;
        majorLevel = 0;
        indent = 0;
    }

    protected void makeLineBreak()
        throws Exception
    {
        newLine();
    }

    protected void makeHorizontalRule()
        throws Exception
    {
        newLine();
        writeText("---------------------------------------------------------------");
    }

    private int skipSpaces(String line, int startPos) {
        while (startPos < line.length() && line.charAt(startPos)==' ') {
            startPos++;
        }
        return startPos;
    }


    protected void startBullet(String line, int level)
            throws Exception
    {
        if (majorState != BULLET) {
            terminate();
            majorState = BULLET;
        } else {
            //nothing needed at end of bullet line
        }
        setPFont();
        moveDown(3);   //space before the paragraph
        paraTrailing = 3;  //no space after bullets
        indent = 20*level;
        newLine();     //gets you to the beginning of the line
        contentStream.moveTextPositionByAmount( -10, 0);
        contentStream.setFont(PDType1Font.ZAPF_DINGBATS, 6);
        contentStream.drawString("l");
        contentStream.moveTextPositionByAmount( 10, 0);
        contentStream.setFont(currentFont, currentLineSize);
        scanForStyle(line, skipSpaces(line, level));
    }

    protected void startHeader(String line, int level)
            throws Exception
    {
        terminate();
        indent = 0;
        majorState = HEADER;
        majorLevel = level;
        switch (level) {
        case 3:
            moveDown(24);       //space before the paragraph
            setH1Font();
            paraTrailing = 8;  //will be at end
            break;
        case 2:
            moveDown(18);   //space before the paragraph
            setH2Font();
            paraTrailing = 8;  //will be at end
            break;
        case 1:
            moveDown(12);   //space before the paragraph
            setH3Font();
            paraTrailing = 8;  //will be at end
            break;
        }
        newLine();     //gets you to the beginning of the line
        scanForStyle(line, skipSpaces(line, level));
    }

    protected void scanForStyle(String line, int scanStart)
            throws Exception
    {
        int pos = scanStart;
        int last = line.length();
        StringBuffer toWrite = new StringBuffer();
        while (pos < last) {
            char ch = line.charAt(pos);
            switch (ch) {
            case '[':

                writeWrappedLine(toWrite.toString());
                toWrite = new StringBuffer();
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
                writeWrappedLine(toWrite.toString());
                toWrite = new StringBuffer();
                int tagEnd = findIdentifierEnd(line, pos+1);
                String tagName = line.substring(pos+1,tagEnd);
                outputTagLink(tagName);
                pos = tagEnd;
                continue;
            case '_':
                if (line.length() > pos + 1 && line.charAt(pos + 1) == '_') {
                    pos += 2;
                    writeWrappedLine(toWrite.toString());
                    toWrite = new StringBuffer();
                    isBold = !isBold;
                    currentFont = currentFamily.getFont(isBold, isItalic);
                    continue;
                }
                break;
            case '\'':
                if (line.length() > pos + 1 && line.charAt(pos + 1) == '\'') {
                    pos += 2;
                    writeWrappedLine(toWrite.toString());
                    toWrite = new StringBuffer();
                    isItalic = !isItalic;
                    currentFont = currentFamily.getFont(isBold, isItalic);
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
            toWrite.append(ch);
            pos++;
        }
        writeWrappedLine(toWrite.toString());
    }


    protected void outputTagLink(String tagName)
        throws Exception
    {
        writeWrappedLine("#" + tagName);
        /*
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
        */
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


    public void outputProperLink(String linkURL)
        throws Exception
    {
        int barPos = linkURL.indexOf("|");
        String linkName = linkURL.trim();
        String linkAddr = linkName;
        if (barPos >= 0)
        {
            linkName = linkURL.substring(0,barPos).trim();
            linkAddr = linkURL.substring(barPos+1).trim();
        }

        boolean isExternal = (linkAddr.startsWith("http") && linkAddr.indexOf("/")>=0);
        boolean lookupOK = false;

        if (!isExternal) {


            String sanitizedName = SectionWiki.sanitize(linkAddr);
            if (sanitizedName.length()>0) {
                Vector<NGPageIndex> foundPages = ar.getCogInstance().getPageIndexByName(linkAddr);
                if (foundPages.size()==1)
                {
                    NGPageIndex foundPI = foundPages.firstElement();
                    if (!foundPI.isDeleted) {
                        linkAddr = ar.baseURL + ar.getResourceURL(foundPI, "frontPage.htm");
                        linkName = foundPI.containerName;   //use the best name for page

                        lookupOK = true;
                    }
                }
            }

        }

        if (isExternal || lookupOK) {
            float x1 = RIGHT_MARGIN - lineRemainder;
            float y1 = yPos;

            float height = currentLineSize;
            float width = (currentFont.getStringWidth(linkName)*currentLineSize) /1000f;
            if (width>lineRemainder) {
                width = lineRemainder;
            }

            // Note: this makes a single box, but the text might be wrapped down.
            // a different approach should be used to create boxes for every piece of link

            createLink(x1, y1, width, height, linkAddr);
        }
        writeWrappedLine(linkName);

    }


    private void createLink(float x, float y, float textWidth, float height, String link) throws Exception{
        PDBorderStyleDictionary borderULine = new PDBorderStyleDictionary();
        borderULine.setStyle(PDBorderStyleDictionary.STYLE_UNDERLINE);
        borderULine.setWidth(0.5f);

        PDRectangle position = new PDRectangle();
        position.setLowerLeftX(x);
        position.setLowerLeftY(y-1);//must be a bit lower than the text
        position.setUpperRightX(x+textWidth);
        position.setUpperRightY(y+height+1);

        PDActionURI uri = new PDActionURI();
        uri.setURI(link);

        PDAnnotationLink txtLink = new PDAnnotationLink();
        txtLink.setRectangle(position);
        txtLink.setAction(uri);
        txtLink.setBorderStyle(borderULine);
        PDGamma gamma = new PDGamma();
        gamma.setB(1);
        txtLink.setColour(gamma);
        @SuppressWarnings("unchecked")
        List<PDAnnotationLink> annotations = pdpage.getAnnotations();
        annotations.add(txtLink);
    }

}
