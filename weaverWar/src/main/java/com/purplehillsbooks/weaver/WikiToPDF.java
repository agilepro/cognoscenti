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

import java.awt.Color;
import java.io.OutputStream;
import java.io.StringWriter;
import java.util.Vector;

import org.apache.pdfbox.pdmodel.common.PDRectangle;
import org.apache.pdfbox.pdmodel.font.PDType1Font;
import org.apache.pdfbox.pdmodel.graphics.color.PDGamma;
import org.apache.pdfbox.pdmodel.interactive.action.PDActionURI;
import org.apache.pdfbox.pdmodel.interactive.annotation.PDAnnotationLink;
import org.apache.pdfbox.pdmodel.interactive.annotation.PDBorderStyleDictionary;

import com.purplehillsbooks.streams.MemFile;

import com.purplehillsbooks.pdflayout.elements.ControlElement;
import com.purplehillsbooks.pdflayout.elements.PDFDoc;
import com.purplehillsbooks.pdflayout.elements.Frame;
import com.purplehillsbooks.pdflayout.elements.Orientation;
import com.purplehillsbooks.pdflayout.elements.PageFormat;
import com.purplehillsbooks.pdflayout.elements.Paragraph;
import com.purplehillsbooks.pdflayout.shape.Stroke;

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
    
    public final static char ESCAPE_CHAR = 'º';    

    protected AuthRequest ar;
    protected int majorState = 0;
    protected int majorLevel = 0;
    protected String userKey;

    //PDF Layout Object
    private PDFDoc document;
    
    
    private String printTime;

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
    protected int    pageNum = 1;

    private boolean includeDecisions;
    private boolean includeAttachments;
    private boolean includeComments;
    private boolean includeRoles;
    private boolean includeActionItems;

    boolean isNewPage;


    private class FontFamily {

        PDType1Font norm;
        PDType1Font bold;
        PDType1Font italic;
        PDType1Font boldItalic;

        public FontFamily(PDType1Font a, PDType1Font b, PDType1Font c, PDType1Font d) {
            norm = a; bold = b; italic = c; boldItalic = d;
        }

        public PDType1Font getFont(boolean aBold, boolean aItalic) {

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
    
    Color lightSkyBlue;

    protected boolean isBold = false;
    protected boolean isItalic = false;
    protected FontFamily currentFamily = helvetica;
    protected PDType1Font currentFont   = PDType1Font.HELVETICA;
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
        lightSkyBlue = Color.getColor("LightSkyBlue");
        if (lightSkyBlue==null) {
            lightSkyBlue = new Color(135,206,250);
        }
    }




    /**
    * This is a thack due to code trasition.
    * decodes the request parameters and then causes the PDF generation
    * try not to use this if possible.
    */
    public static void handlePDFRequest(AuthRequest ar, NGWorkspace ngp) throws Exception{
        ar.setPageAccessLevels(ngp);



        WikiToPDF wc = new WikiToPDF(ar);
        wc.writeWikiAsPDF(ngp, ar);
    }


    private String[] getVectorParam(String name) {
        String[] idArray = ar.req.getParameterValues(name);

        if (idArray==null) {
            idArray = new String[0];
        }
        return idArray;
    }

    public void writeWikiAsPDF(NGWorkspace ngp, AuthRequest ar)  throws Exception {
        
        includeDecisions = (ar.req.getParameter("decisions")!=null);
        includeAttachments = (ar.req.getParameter("attachments")!=null);
        includeComments = (ar.req.getParameter("comments")!=null);
        includeRoles = (ar.req.getParameter("roles")!=null);
        includeActionItems = (ar.req.getParameter("actionItems")!=null);

        Vector<TopicRecord> memberNotes = new Vector<TopicRecord>();
        for (String noteId : getVectorParam("publicNotes")) {
            TopicRecord lrt = ngp.getDiscussionTopic(noteId);
            if (lrt!=null) {
                memberNotes.add(lrt);
            }
        }

        Vector<MeetingRecord> meetings = new Vector<MeetingRecord>();
        for (String meetId : getVectorParam("meetings")) {
            MeetingRecord meet = ngp.findMeetingOrNull(meetId);
            if (meet!=null) {
                meetings.add(meet);
            }
        }
        
        //set up the print time for use in the footer
        printTime = convertDate(ar.nowTime);
        
        MemFile mf = new MemFile();
        
        PageFormat letterSizePage = new PageFormat(PDRectangle.LETTER, Orientation.Portrait, 
                (float)50.0, (float)50.0, (float)50.0, (float)50.0);
        document = new PDFDoc(letterSizePage);

        try {
            Frame tableOfContents = document.newInteriorFrame();
            if (memberNotes.size()>1 || meetings.size()>1 ||includeDecisions || includeAttachments) {
                writeTOCPage(tableOfContents, ngp, memberNotes, meetings);
            }
            
            document.add(ControlElement.NEWPAGE);
            
            int noteCount = 0;
            if(memberNotes.size() > 0){
                for (TopicRecord lr : memberNotes) {
                    Frame restOfDoc = document.newInteriorFrame();
                    noteCount++;
                    writeNoteToPDF(restOfDoc, ngp, lr, noteCount);
                    document.add(ControlElement.NEWPAGE);
                }
            }
            noteCount = 0;
            if(meetings.size() > 0){
                for (MeetingRecord meet : meetings) {
                    Frame restOfDoc = document.newInteriorFrame();
                    noteCount++;
                    writeMeetingToPDF(restOfDoc, ngp, meet, noteCount);
                    document.add(ControlElement.NEWPAGE);
                }
            }
            
            if (includeDecisions) {
                writeDecisionsToPDF(document.newInteriorFrame(), ngp);
            }
            if (includeAttachments) {
                writeAttachmentListToPDF(document.newInteriorFrame(), ngp);
            }
            if (includeActionItems) {
                writeActionItemsToPDF(document.newInteriorFrame(), ngp);
            }
            if (includeRoles) {
                writeRolesToPDF(document.newInteriorFrame(), ngp);
            }
            
            //This can throw an error, and we want to get that error before
            //we write anything to the real output stream, so buffer it
            document.saveToStream(mf.getOutputStream());
            
            String fileName = ngp.getKey() + ".pdf";
            ar.resp.setContentType("application/pdf");
            ar.resp.setHeader( "Content-Disposition", "attachment; filename=\"" + fileName + "\"" );
            OutputStream out = ar.resp.getOutputStream();
            mf.outToOutputStream(out);
            out.flush();
       }
        catch (Exception e) {
            throw new Exception("Failure while generating PDF file", e);
        }
    }
    
    public void writeWikiAsPDFzzz(NGWorkspace ngp, AuthRequest ar)  throws Exception {
/*
        Vector<TopicRecord> memberNotes = new Vector<TopicRecord>();
        Vector<MeetingRecord> meetings = new Vector<MeetingRecord>();

        String[] idArray = ar.req.getParameterValues("publicNotes");

        if (idArray==null) {
            idArray = new String[0];
        }

        for (String noteId : idArray) {
            TopicRecord lrt = ngp.getDiscussionTopic(noteId);
            if (lrt!=null) {
                memberNotes.add(lrt);
            }
        }

        idArray = ar.req.getParameterValues("meetings");

        if (idArray==null) {
            idArray = new String[0];
        }
        for (String meetId : idArray) {
            MeetingRecord meet = ngp.findMeetingOrNull(meetId);
            if (meet!=null) {
                meetings.add(meet);
            }
        }
        
        includeDecisions = (ar.req.getParameter("decisions")!=null);
        includeAttachments = (ar.req.getParameter("attachments")!=null);
        includeComments = (ar.req.getParameter("comments")!=null);
        includeRoles = (ar.req.getParameter("roles")!=null);
        includeActionItems = (ar.req.getParameter("actionItems")!=null);

        //pddoc = new PDDocument();

        //set up the print time for use in the footer
        printTime = convertDate(ar.nowTime);


        if (memberNotes.size()>1 || meetings.size()>1 ||includeDecisions || includeAttachments) {
            writeTOCPage(ngp, memberNotes, meetings);
        }

        int noteCount = 0;
        if(memberNotes.size() > 0){
            for (TopicRecord lr : memberNotes) {
                noteCount++;
                writeNoteToPDF(ngp, lr, noteCount);
            }
        }
        noteCount = 0;
        if(meetings.size() > 0){
            for (MeetingRecord meet : meetings) {
                noteCount++;
                writeMeetingToPDF(ngp, meet, noteCount);
            }
        }

        if (includeDecisions) {
            //writeDecisionsToPDF(ngp);
        }
        if (includeAttachments) {
            //writeAttachmentListToPDF(ngp);
        }
        if (includeActionItems) {
            //writeActionItemsToPDF(ngp);
        }
        if (includeRoles) {
            //writeRolesToPDF(ngp);
        }
        endPage();

        String fileName = ngp.getKey() + ".pdf";
        ar.resp.setContentType("application/pdf");
        ar.resp.setHeader( "Content-Disposition", "attachment; filename=\"" + fileName + "\"" );
        OutputStream out = ar.resp.getOutputStream();
        //pddoc.save(out);
        //pddoc.close();
        out.flush();
        */
    }


    private void writeTOCPage(Frame containingFrame, NGWorkspace ngp,
            Vector<TopicRecord> memberNoteList, 
            Vector<MeetingRecord> meetings)  throws Exception {
        headerText = "Topic report generated from Weaver";

        Frame frame = containingFrame.newInteriorFrame();
        frame.setPadding(36, 36, 0, 0);
        frame.setStartNewPage(true);

        String projectName = ngp.getFullName();
        setPFont();

        writeWrappedLine(frame.getNewParagraph(), "Workspace:");

        writeWrappedLine(frame.getNewParagraph(), projectName);

        int noteCount = 0;

        if(memberNoteList.size() > 0){
            setPFont();
            writeWrappedLine(frame.getNewParagraph(), "Discussion Topics: ");
            for (TopicRecord note : memberNoteList) {
                noteCount++;
                setPFont();
                writeWrappedLine(frame.getNewParagraph(), Integer.toString(noteCount)+". "+note.getSubject());
            }
        }
        noteCount = 0;
        if(meetings.size() > 0){
            setPFont();
            writeWrappedLine(frame.getNewParagraph(), "Meetings: ");
            for (MeetingRecord meet : meetings) {
                noteCount++;
                setPFont();
                indent=0;
                indent=15;
                writeWrappedLine(frame.getNewParagraph(), Integer.toString(noteCount)+". "+meet.getName());
            }
        }
        indent=0;

        if (includeDecisions) {
            writeWrappedLine(frame.getNewParagraph(), "Decisions");
        }
        if (includeAttachments) {
            writeWrappedLine(frame.getNewParagraph(), "Attached Documents");
        }
        if (includeActionItems) {
            writeWrappedLine(frame.getNewParagraph(), "Action Items");
        }
        if (includeRoles) {
            writeWrappedLine(frame.getNewParagraph(), "Roles");
        }
        endPage();
    }


    
    
    /**
    * Takes a block of data formatted in wiki format, and converts
    * it to HTML, outputting that to the AuthRequest that was
    * passed in when the object was constructed.
    */
    public void writeNoteToPDF(Frame mainframe, NGWorkspace ngp, TopicRecord note, int noteNum) throws Exception
    {
        NGBook book = ngp.getSite();

        String subject = stripBadCharacters(note.getSubject());
        UserRef lastEditor = note.getModUser();
        String editTime = convertDateAndTime(note.getLastEdited());

        headerText = "Topic "+noteNum+": "+subject;
        
        
        Frame titleBoxFrame = mainframe.newInteriorFrame();
        titleBoxFrame.setBorder(Color.blue, new Stroke());
        titleBoxFrame.setPadding(5, 5, 5, 5);
        titleBoxFrame.setMargin(0, 0, 20, 20);
        titleBoxFrame.setBackgroundColor(lightSkyBlue);
        titleBoxFrame.setStartNewPage(true);

        Paragraph para = titleBoxFrame.getNewParagraph();
        para.addTextCarefully(subject, 24, PDType1Font.HELVETICA);

        
        para = titleBoxFrame.getNewParagraph();
        para.addTextCarefully("Workspace: "+ngp.getFullName()+", Site: "+book.getFullName(), 8, PDType1Font.HELVETICA);
        
        para = titleBoxFrame.getNewParagraph();
        para.addTextCarefully("Last modified by:  "+lastEditor.getName()+" on "+editTime, 8, PDType1Font.HELVETICA);

        titleBoxFrame = mainframe.newInteriorFrame();
        writeWikiData(titleBoxFrame, note.getWiki());
        
        if (includeComments) {
            for (CommentRecord cr : note.getComments()) {
                writeComment(mainframe, cr);
            }
        }
    }
    
    public void writeMeetingToPDF(Frame frame, NGWorkspace ngp, MeetingRecord meet, int meetNum) throws Exception
    {
        NGBook site = ngp.getSite();

        String meetingName = stripBadCharacters(meet.getName());
        UserRef lastEditor = UserManager.lookupUserByAnyId(meet.getOwner());
        String startTime = convertDateAndTime(meet.getStartTime());

        headerText = "Meeting "+meetNum+": "+meetingName;
        if(!isNewPage){
            endPage();
            startPage();
        }
        indent=0;

        Frame titleBoxFrame = frame.newInteriorFrame();
        //titleBoxFrame.setBorder(Color.blue, new Stroke());
        titleBoxFrame.setPadding(5, 5, 5, 5);
        titleBoxFrame.setMargin(0, 0, 20, 20);
        titleBoxFrame.setBackgroundColor(lightSkyBlue);
        titleBoxFrame.removeLeadingEmptyVerticalSpace();

        Paragraph para = titleBoxFrame.getNewParagraph();
        para.addTextCarefully(meetingName, 24, PDType1Font.HELVETICA);

        para = titleBoxFrame.getNewParagraph();
        para.addTextCarefully("Workspace: "+ngp.getFullName()+", Site: "+site.getFullName(), 8, PDType1Font.HELVETICA);
        
        para = titleBoxFrame.getNewParagraph();
        para.addTextCarefully("Last modified by:  "+lastEditor.getName()+" on "+startTime, 8, PDType1Font.HELVETICA);


        writeWikiData(frame, meet.getMeetingDescription());
        int agendaNum = 0;
        for (AgendaItem ai : meet.getAgendaItems()) {
            
            Frame innerFrame = frame.newInteriorFrame();

            if (ai.isSpacer()) {
                continue;
                
            }
            agendaNum++;

            para = innerFrame.getNewParagraph();
            para.addTextCarefully(Integer.toString(agendaNum)+ ": " + ai.getSubject(), 16, PDType1Font.HELVETICA);

            
            innerFrame = frame.newInteriorFrame();
            innerFrame.setPaddingLeft(35);
            writeWikiData(innerFrame, ai.getDesc());
            
            if (includeComments) {
                for (CommentRecord cr : ai.getComments()) {
                    writeComment(innerFrame, cr);
                }
            }
        }
    }    
    
    private void writeComment(Frame frame, CommentRecord cr) throws Exception  {
        if (cr.getState() == CommentRecord.COMMENT_STATE_DRAFT) {
            return;
        }
        String content = cr.getContent();
        if (content.length()==0) {
            return;
        }
        long date = cr.getPostTime();
        if (date<100) {
            date = cr.getTime();
        }
        Frame commentBoxFrame = frame.newInteriorFrame();
        commentBoxFrame.setPadding(5, 5, 5, 5);
        commentBoxFrame.setMargin(0, 0, 20, 20);
        //commentBoxFrame.setBackgroundColor(Color.lightGray);
        commentBoxFrame.setBorder(Color.lightGray, new Stroke());
        commentBoxFrame.setStartNewPage(true);
        
        String dateStr = convertDateAndTime(date);

        setPFont();
        writeWrappedLine(commentBoxFrame.getNewParagraph(), "From:  "+cr.getUser().getName());
        writeWrappedLine(commentBoxFrame.getNewParagraph(), "Date: " + dateStr);
        setPFont();
        writeWikiData(commentBoxFrame, content);
    }
    
    
    private void writeWikiData(Frame frame, String wiki) throws Exception {
        Paragraph para = frame.getNewParagraph();
        LineIterator li = new LineIterator(wiki);
        while (li.moreLines()) {
            String thisLine = li.nextLine();
            para = formatText(frame, para, thisLine);
        }
        terminate();
    }


    private void pageTop(Frame frame, NGWorkspace ngp, String title) throws Exception {
        NGBook book = ngp.getSite();
        headerText = title;
        if(!isNewPage){
            endPage();
            startPage();
        }
        indent=0;

        setH1Font();
        writeWrappedLine(frame.getNewParagraph(), title);

        setH1Font();
        currentLineSize = 8;  //but really small
        writeWrappedLine(frame.getNewParagraph(), "Workspace: "+ngp.getFullName()+", Site: "+book.getFullName());

        //box(LEFT_MARGIN-2, TOP_MARGIN+2, RIGHT_MARGIN+2, (int) yPos-3);
    }

    /**
    * Takes all the decisions and makes a page(s) with them listed.
    */
    public void writeDecisionsToPDF(Frame frame, NGWorkspace ngp) throws Exception {
        pageTop(frame, ngp, "Decision List");

        for (DecisionRecord dr : ngp.getDecisions()) {
            Frame innerFrame = frame.newInteriorFrame();
            innerFrame.setBorderColor(Color.pink);
            currentLineSize = 30;
            currentLineSize = 12;
            setH1Font();
            writeWrappedLine(innerFrame.getNewParagraph(), "Decision #"+dr.getNumber()+" - "+convertDate(dr.getTimestamp()));
            writeWikiData(innerFrame, dr.getDecision());
        }
    }

    public void writeAttachmentListToPDF(Frame frame, NGWorkspace ngp) throws Exception {
        pageTop(frame, ngp, "Attachment Documents");

        int count = 0;
        for (AttachmentRecord att : ngp.getAllAttachments()) {
            Frame innerFrame = frame.newInteriorFrame();
            innerFrame.setBorderColor(lightSkyBlue);
            count++;
            currentLineSize = 16;
            setH3Font();
            writeWrappedLine(innerFrame.getNewParagraph(), ""+count+". "+att.getDisplayName());
            currentLineSize = 12;
            writeWikiData(innerFrame, att.getDescription());
        }
    }

    public void writeActionItemsToPDF(Frame frame, NGWorkspace ngp) throws Exception {
        pageTop(frame, ngp, "Action Items");

        int count = 0;
        for (GoalRecord actionItem : ngp.getAllGoals()) {
            Frame innerFrame = frame.newInteriorFrame();
            count++;
            currentLineSize = 16;
            setH3Font();
            writeWrappedLine(innerFrame.getNewParagraph(), ""+count+". "+actionItem.getSynopsis()
                    +" ("+GoalRecord.stateName(actionItem.getState())+")");
            currentLineSize = 12;
            StringBuilder sb = new StringBuilder();
            sb.append(actionItem.getDescription());
            sb.append("\n\n");
            for (AddressListEntry ale : actionItem.getAssigneeRole().getDirectPlayers()) {
                sb.append("* "+ale.getName()+"\n \n");
            }

            long date = actionItem.getDueDate();
            if (date>100) {
                sb.append("Due: "+convertDate(date)+", ");
            }
            date = actionItem.getStartDate();
            if (date>100) {
                sb.append("Started: "+convertDate(date)+", ");
            }
            date = actionItem.getEndDate();
            if (date>100) {
                sb.append("Completed: "+convertDate(date)+", ");
            }
            sb.append("\n\n");

            writeWikiData(innerFrame, sb.toString());
            makeHorizontalRule(innerFrame);
        }
    }

    public void writeRolesToPDF(Frame frame, NGWorkspace ngp) throws Exception {
        pageTop(frame, ngp, "Roles");

        int count = 0;
        for (CustomRole role : ngp.getAllRoles()) {
            Frame innerFrame = frame.newInteriorFrame();
            count++;
            currentLineSize = 16;
            setH3Font();
            writeWrappedLine(innerFrame.getNewParagraph(), ""+count+". "+role.getName());
            currentLineSize = 12;
            StringBuilder sb = new StringBuilder();
            sb.append(role.getDescription());
            sb.append("\n\n");
            sb.append(role.getRequirements());
            sb.append("\n\n");
            for (AddressListEntry ale : role.getDirectPlayers()) {
                sb.append("* "+ale.getName()+"\n \n");
            }

            writeWikiData(innerFrame, sb.toString());
            makeHorizontalRule(innerFrame);
        }
    }

    private void setH1Font()
    {
        isBold = false;
        isItalic = false;
        currentFamily = helvetica;
        currentFont = currentFamily.getFont(isBold, isItalic);
        currentLineSize = 18;
    }

    private void setH2Font()
    {
        isBold = false;
        isItalic = false;
        currentFamily = helvetica;
        currentFont = currentFamily.getFont(isBold, isItalic);
        currentLineSize = 16;
    }

    private void setH3Font()
    {
        isBold = false;
        isItalic = false;
        currentFamily = helvetica;
        currentFont = currentFamily.getFont(isBold, isItalic);
        currentLineSize = 14;
    }

    private void setPFont()
    {
        isBold = false;
        isItalic = false;
        currentFamily = times;
        currentFont = currentFamily.getFont(isBold, isItalic);
        currentLineSize = 12;
    }

    private void setPREFont()
    {
        isBold = false;
        isItalic = false;
        currentFamily = courier;
        currentFont = currentFamily.getFont(isBold, isItalic);
        currentLineSize = 12;
    }


    /**
    * Advance down the page by the current line size.  If this is below the
    * bottom margin, then force a new page feed and continue
    */
    private void newLine() throws Exception
    {
        Frame innerFrame = document.newInteriorFrame();
        innerFrame.setGivenHeight(12);
    }


    /**
    * adds vertical space, but does not attempt to create a new page or
    * anything at this level.
    */
    private void moveDown(float amt) throws Exception
    {
        Frame innerFrame = document.newInteriorFrame();
        innerFrame.setGivenHeight(amt);
    }


    /**
    * eliminate any chars > 128 because PDFBox can't handle them right now
    * also eliminate double white space characters to simulate HTML
    */
    private String stripBadCharacters(String text)  throws Exception
    {
        StringBuilder cleanedText = new StringBuilder();
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


    
    
    private void writeWrappedLine(Paragraph para, String text) throws Exception {
        para.addTextCarefully(text, currentLineSize, currentFont);
    }


    private void startPage()  throws Exception {
        /*
        pdpage = new PDPage();

        pdpage.setMediaBox(PDRectangle.LETTER);
        pddoc.addPage( pdpage );

        xPos = LEFT_MARGIN;
        yPos = TOP_MARGIN;   //but don't write here, do a newline first!

        contentStream = new PDPageContentStream(pddoc, pdpage, true, false);

        contentStream.beginText();
        //really small font for the header and footer
        contentStream.setFont(helvetica.getFont(false,false), 8);
        contentStream.moveTextPositionByAmount( xPos, yPos + 20 );
        contentStream.drawString(headerText);
        contentStream.moveTextPositionByAmount( 0, BOTTOM_MARGIN - TOP_MARGIN - 40 );
        contentStream.drawString("Generated: "+printTime+"  --  Page "+pageNum);
        contentStream.moveTextPositionByAmount( 0, TOP_MARGIN + 20 - BOTTOM_MARGIN );

        currentFont = currentFamily.getFont(isBold,isItalic);
        contentStream.setFont(currentFont, currentLineSize);

        isNewPage = true;
        lineRemainder = 0f;
        pageNum++;
        */
    }

    private void endPage()  throws Exception {
        lineRemainder = 0f;
    }


    protected Paragraph formatText(Frame frame, Paragraph para, String line) throws Exception
    {
        boolean isIndented = line.startsWith(" ");
        if (majorState != PREFORMATTED) {
            line = line.trim();
        }
        if (line.length() == 0) {
            if (majorState != PREFORMATTED) {
                terminate();
                para = frame.getNewParagraph();
            }
        } else if (line.equals("{{{")) {
            para = frame.getNewParagraph();
            startPRE();
        } else if (line.startsWith("}}}")) {
            terminate();
            para = frame.getNewParagraph();
        } else if (line.startsWith("!!!")) {
            para = frame.getNewParagraph();
            startHeader(para, line, 3);
        } else if (line.startsWith("!!")) {
            para = frame.getNewParagraph();
            startHeader(para, line, 2);
        } else if (line.startsWith("!")) {
            para = frame.getNewParagraph();
            startHeader(para, line, 1);
        } else if (line.startsWith("***")) {
            para = frame.getNewParagraph();
            startBullet(line, 3);
        } else if (line.startsWith("**")) {
            para = frame.getNewParagraph();
            startBullet(line, 2);
        } else if (line.startsWith("*")) {
            para = frame.getNewParagraph();
            startBullet(line, 1);
        } else if (line.startsWith(":")) {
            if (majorState == PARAGRAPH) {
                makeLineBreak();
            } else {
                para = frame.getNewParagraph();
                startParagraph();
            }
            scanForStyle(para, line, 1);
        } else if (line.startsWith("----")) {
            terminate();
            para = frame.getNewParagraph();
            makeHorizontalRule(frame);
        } else if (isIndented) {
            // continue whatever mode there is
            scanForStyle(para, line, skipSpaces(line,0));
        }else {

            if (majorState != PARAGRAPH && majorState != PREFORMATTED) {
                para = frame.getNewParagraph();
                startParagraph();
            }
            scanForStyle(para, line, 0);
        }
        return para;
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
        indent = 0;
    }

    protected void startParagraph() throws Exception
    {
        terminate();
        moveDown(8);   //space before the paragraph
        setPFont();
        indent = 0;
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

    protected void makeLineBreak() throws Exception {
        newLine();
    }

    protected void makeHorizontalRule(Frame frame) throws Exception {
        Frame lineFrame = frame.newInteriorFrame();
        lineFrame.setMargin(0, 0, 6, 6);
        lineFrame.setBorder(Color.gray, new Stroke());
    }

    private int skipSpaces(String line, int startPos) {
        while (startPos < line.length() && line.charAt(startPos)==' ') {
            startPos++;
        }
        return startPos;
    }


    protected void startBullet(String line, int level) throws Exception {
        /*
        if (majorState != BULLET) {
            terminate();
            majorState = BULLET;
        }
        else {
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
        */
    }

    protected void startHeader(Paragraph para, String line, int level)
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
        scanForStyle(para, line, skipSpaces(line, level));
    }

    protected void scanForStyle(Paragraph para, String line, int scanStart)
            throws Exception
    {
        int pos = scanStart;
        int last = line.length();
        StringBuilder toWrite = new StringBuilder();
        while (pos < last) {
            char ch = line.charAt(pos);
            switch (ch) {
            case '[':

                writeWrappedLine(para, toWrite.toString());
                toWrite = new StringBuilder();
                int pos2 = line.indexOf(']', pos);
                if (pos2 > pos + 1) {
                    String linkURL = line.substring(pos + 1, pos2);
                    outputProperLink(para, linkURL);
                    pos = pos2 + 1;
                } else if (pos2 == pos + 1) {
                    pos = pos + 2;
                } else {
                    pos = pos + 1;
                }
                continue;
            case '_':
                if (line.length() > pos + 1 && line.charAt(pos + 1) == '_') {
                    pos += 2;
                    writeWrappedLine(para, toWrite.toString());
                    toWrite = new StringBuilder();
                    isBold = !isBold;
                    currentFont = currentFamily.getFont(isBold, isItalic);
                    continue;
                }
                break;
            case '\'':
                if (line.length() > pos + 1 && line.charAt(pos + 1) == '\'') {
                    pos += 2;
                    writeWrappedLine(para, toWrite.toString());
                    toWrite = new StringBuilder();
                    isItalic = !isItalic;
                    currentFont = currentFamily.getFont(isBold, isItalic);
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
            toWrite.append(ch);
            pos++;
        }
        writeWrappedLine(para, toWrite.toString());
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


    public void outputProperLink(Paragraph para, String linkURL)
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

        para.addTextCarefully(linkName, currentLineSize, currentFont);

        /*
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
*/

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
        //txtLink.setColour(gamma);
        //List<PDAnnotation> annotations = pdpage.getAnnotations();
        //annotations.add(txtLink);
    }


    private String convertDateAndTime(long dateVal) throws Exception  {
        StringWriter out = new StringWriter(20);
        SectionUtil.nicePrintDateAndTime(out, dateVal);
        return out.toString();
    }
    private String convertDate(long dateVal) throws Exception  {
        StringWriter out = new StringWriter(20);
        SectionUtil.nicePrintDate(out, dateVal, null);
        return out.toString();
    }

}
