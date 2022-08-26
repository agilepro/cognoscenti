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
import java.util.ArrayList;
import java.util.List;
import org.apache.pdfbox.pdmodel.common.PDRectangle;
import org.apache.pdfbox.pdmodel.font.PDType1Font;
import com.purplehillsbooks.streams.MemFile;
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
    
    public final static Color paleYellow = new Color(252,255,226);
    public final static Color lightBlue = new Color(178,229,255);

    protected AuthRequest ar;
    private NGWorkspace ngw;
    protected int majorState = 0;
    protected int majorLevel = 0;
    protected String userKey;

    //PDF Layout Object
    private PDFDoc document;
    
    
    private String printTime;

    float xPos = 200f;
    float yPos = 800f;
    float lineRemainder = 0f;
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
    private boolean debugLines = false;;


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
    public WikiToPDF(AuthRequest _ar, NGWorkspace _ngw) throws Exception {
        ar = _ar;
        ngw = _ngw;
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
    * This is a hack due to code transition.
    * decodes the request parameters and then causes the PDF generation
    * try not to use this if possible.
    */
    public static void handlePDFRequest(AuthRequest ar, NGWorkspace ngw) throws Exception{
        ar.setPageAccessLevels(ngw);

        WikiToPDF wc = new WikiToPDF(ar, ngw);
        wc.writeWikiAsPDF();
    }


    private String[] getVectorParam(String name) {
        String[] idArray = ar.req.getParameterValues(name);

        if (idArray==null) {
            idArray = new String[0];
        }
        return idArray;
    }

    private void writeWikiAsPDF()  throws Exception {
        
        includeDecisions = (ar.req.getParameter("decisions")!=null);
        includeAttachments = (ar.req.getParameter("attachments")!=null);
        includeComments = (ar.req.getParameter("comments")!=null);
        includeRoles = (ar.req.getParameter("roles")!=null);
        includeActionItems = (ar.req.getParameter("actionItems")!=null);
        debugLines = (ar.req.getParameter("debugLines")!=null);

        ArrayList<TopicRecord> allTopicPages = new ArrayList<TopicRecord>();
        for (String noteId : getVectorParam("publicNotes")) {
            TopicRecord lrt = ngw.getDiscussionTopic(noteId);
            if (lrt!=null) {
                allTopicPages.add(lrt);
            }
        }

        ArrayList<MeetingRecord> meetings = new ArrayList<MeetingRecord>();
        for (String meetId : getVectorParam("meetings")) {
            MeetingRecord meet = ngw.findMeetingOrNull(meetId);
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
        Frame fullDocInterior = document.newInteriorFrame();
        fullDocInterior.setPadding(1,1,1,1);
        if (debugLines) {
            fullDocInterior.setBorderColor(Color.green);
        }

        try {
            writeTOCPage(fullDocInterior, allTopicPages, meetings);
            
            
            int noteCount = 0;
            if(allTopicPages.size() > 0){
                for (TopicRecord lr : allTopicPages) {
                    noteCount++;
                    writeNoteToPDF(fullDocInterior, lr, noteCount);
                }
            }
            noteCount = 0;
            if(meetings.size() > 0){
                for (MeetingRecord meet : meetings) {
                    noteCount++;
                    writeMeetingToPDF(fullDocInterior, meet, noteCount);
                }
            }
            
            if (includeDecisions) {
                writeDecisionsToPDF(fullDocInterior);
            }
            if (includeAttachments) {
                writeAttachmentListToPDF(fullDocInterior);
            }
            if (includeActionItems) {
                writeActionItemsToPDF(fullDocInterior);
            }
            if (includeRoles) {
                writeRolesToPDF(fullDocInterior);
            }
            
            //determine the best name
            String defaultName = ngw.getFullName();
            if (allTopicPages.size()==1) {
                defaultName = allTopicPages.get(0).getSubject();
            }
            defaultName = SectionUtil.sanitize(defaultName) + ".pdf";
            
            //This can throw an error, and we want to get that error before
            //we write anything to the real output stream, so buffer it
            document.saveToStream(mf.getOutputStream());
            
            ar.resp.setContentType("application/pdf");
            ar.resp.setHeader( "Content-Disposition", "attachment; filename=\"" + defaultName + "\"" );
            OutputStream out = ar.resp.getOutputStream();
            mf.outToOutputStream(out);
            out.flush();
       }
        catch (Exception e) {
            throw new Exception("Failure while generating PDF file", e);
        }
    }
    


    private void writeTOCPage(Frame docInterior,
            List<TopicRecord> memberNoteList, 
            List<MeetingRecord> meetings)  throws Exception {
        
        Frame tocFrame = startNamedSection(docInterior, "Table of Contents");

        tocFrame.setPadding(36, 36, 0, 0);
        tocFrame.setStartNewPage(true);
        tocFrame.headerLeft = "Table of Contents";
        if (debugLines) {
            tocFrame.setBorderColor(Color.red);
        }

        String projectName = ngw.getFullName();
        setPFont();

        writeLineNoSpacing(tocFrame, "Workspace:" + projectName);

        int noteCount = 0;

        if(memberNoteList.size() > 0){
            setPFont();
            writeLineNoSpacing(tocFrame, "Discussion Topics: ");
            for (TopicRecord note : memberNoteList) {
                noteCount++;
                setPFont();
                writeLineNoSpacing(tocFrame, "   "+Integer.toString(noteCount)+".  "+note.getSubject());
            }
        }
        noteCount = 0;
        if(meetings.size() > 0){
            setPFont();
            writeLineNoSpacing(tocFrame, "Meetings: ");
            for (MeetingRecord meet : meetings) {
                noteCount++;
                setPFont();
                indent=0;
                indent=15;
                writeLineNoSpacing(tocFrame, "   "+Integer.toString(noteCount)+".  "+meet.getName());
            }
        }
        indent=0;

        if (includeDecisions) {
            writeLineNoSpacing(tocFrame, "Decisions");
        }
        if (includeAttachments) {
            writeLineNoSpacing(tocFrame, "Attached Documents");
        }
        if (includeActionItems) {
            writeLineNoSpacing(tocFrame, "Action Items");
        }
        if (includeRoles) {
            writeLineNoSpacing(tocFrame, "Roles");
        }
    }


    
    
    /**
    * Takes a block of data formatted in wiki format, and converts
    * it to HTML, outputting that to the AuthRequest that was
    * passed in when the object was constructed.
    */
    private void writeNoteToPDF(Frame fullDocContents, TopicRecord note, int noteNum) throws Exception
    {
        String subject = stripBadCharacters(note.getSubject());
        UserRef lastEditor = note.getModUser();
        String editTime = convertDateAndTime(note.getLastEdited());

        headerText = "Topic "+noteNum+": "+subject;
        
        
        Frame noteFrame = startNamedSection(fullDocContents, "Topic "+noteNum+": "+subject);


        Paragraph para = noteFrame.getNewParagraph();
        para.addTextCarefully("Last modified by:  "+lastEditor.getName()+" on "+editTime, 8, PDType1Font.HELVETICA);

        writeWikiData(noteFrame, note.getWiki());
        
        if (includeComments) {
            for (CommentRecord cr : note.getComments()) {
                writeComment(noteFrame, cr);
            }
        }
    }
    
    private void writeMeetingToPDF(Frame fullDocContents, MeetingRecord meet, int meetNum) throws Exception
    {

        String meetingName = stripBadCharacters(meet.getName());
        UserRef lastEditor = UserManager.getStaticUserManager().lookupUserByAnyId(meet.getOwner());
        String startTime = convertDateAndTime(meet.getStartTime());

        headerText = "Meeting "+meetNum+": "+meetingName;
        indent=0;

        Frame meetFrame = startNamedSection(fullDocContents, "Meeting: "+meetingName);

        Paragraph para = meetFrame.getNewParagraph();
        para.addTextCarefully("Last modified by:  "+lastEditor.getName()+" on "+startTime, 8, PDType1Font.HELVETICA);


        writeWikiData(meetFrame, meet.getMeetingDescription());
        int agendaNum = 0;
        for (AgendaItem ai : meet.getAgendaItems()) {
            
            Frame innerFrame = meetFrame.newInteriorFrame();

            if (ai.isSpacer()) {
                continue;
                
            }
            agendaNum++;

            para = innerFrame.getNewParagraph();
            para.addTextCarefully(Integer.toString(agendaNum)+ ": " + ai.getSubject(), 16, PDType1Font.HELVETICA);
            
            innerFrame = meetFrame.newInteriorFrame();
            innerFrame.setPaddingLeft(35);
            writeWikiData(innerFrame, ai.getDesc());
            
            innerFrame = meetFrame.newInteriorFrame();
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
        Frame commentBoxBorder = frame.newInteriorFrame();
        commentBoxBorder.setBorder(Color.lightGray, new Stroke());
        commentBoxBorder.setMargin(0, 0, 5, 5);
        
        long date = cr.getPostTime();
        if (date<100) {
            date = cr.getTime();
        }
        String dateStr = convertDateAndTime(date);

        Frame firstLineShaded = commentBoxBorder.newInteriorFrame();
        firstLineShaded.setPadding(5, 5, 5, 5);
        firstLineShaded.setBackgroundColor(Color.lightGray);
        setPFont();
        String commentType = cr.getTypeName();
        writeLineNoSpacing(firstLineShaded, dateStr + "  ("+commentType+")  "+cr.getUser().getName());

        Frame commentInterior = commentBoxBorder.newInteriorFrame();
        commentInterior.setPadding(5, 5, 5, 5);
        setPFont();
        writeWikiData(commentInterior, content);
        for (ResponseRecord rr : cr.getResponses()) {
            //print responses if any
            String statement = rr.getContent();
            String choice = rr.getChoice();
            if (choice==null || choice.length()==0) {
                if (statement==null || statement.length()==0) {
                    //skip if there is no choice and no statement
                    continue;
                }
            }
            String person = rr.getUserId();
            AddressListEntry responder = new AddressListEntry(person);
            Frame responseFrame = commentInterior.newInteriorFrame();
            responseFrame.setBorder(lightBlue, new Stroke());
            responseFrame.setMargin(0, 0, 5, 5);
            
            Frame responseTopFrame = responseFrame.newInteriorFrame();
            responseTopFrame.setBackgroundColor(lightBlue);
            responseTopFrame.setPadding(5, 5, 5, 5);
            writeLineNoSpacing(responseTopFrame, responder.getName() + " -- " + choice);
            
            Frame responseBodyFrame = responseFrame.newInteriorFrame();
            responseBodyFrame.setPadding(5, 5, 5, 5);
            writeWikiData(responseBodyFrame, statement);
        }
        String outcome = cr.getOutcome(ar);
        if (outcome != null && outcome.length()>0) {
            writeWikiData(commentInterior, outcome);
        }
    }
    
    
    private void writeWikiData(Frame frame, String wiki) throws Exception {
        if (wiki == null || wiki.length()==0) {
            //silently ignore nulls and empty text
            return;
        }
        Paragraph para = frame.getNewParagraph();
        LineIterator li = new LineIterator(wiki);
        while (li.moreLines()) {
            String thisLine = li.nextLine();
            para = formatText(frame, para, thisLine);
        }
        terminate();
    }


    private Frame startNamedSection(Frame entireDocContents, String title) throws Exception {
        //all sections should start on a new page, so make sure
        Frame sectionFrame = entireDocContents.newInteriorFrame();
        if (debugLines) {
            sectionFrame.setBackgroundColor(paleYellow);
            sectionFrame.setPadding(5, 5, 5, 5);
            sectionFrame.setBorder(Color.orange, new Stroke());
        }
        sectionFrame.setStartNewPage(true);
        sectionFrame.headerLeft = title;
        sectionFrame.footerRight = "Page {#}";
        sectionFrame.footerLeft = printTime;
        
        Frame titleBoxFrame = sectionFrame.newInteriorFrame();
        titleBoxFrame.setBorder(Color.blue, new Stroke());
        titleBoxFrame.setPadding(5, 5, 5, 5);
        titleBoxFrame.setMargin(0, 0, 0, 5);
        titleBoxFrame.setBackgroundColor(lightSkyBlue);
        titleBoxFrame.removeLeadingEmptyVerticalSpace();
        titleBoxFrame.headerLeft = title;

        NGBook book = ngw.getSite();
        headerText = title;
        indent=0;

        setH1Font();
        writeLineNoSpacing(titleBoxFrame, title);

        setH1Font();
        currentLineSize = 8;  //but really small
        writeLineNoSpacing(titleBoxFrame, "Site / Workspace: "+book.getFullName()+" / "+ngw.getFullName());
        
        return sectionFrame.newInteriorFrame();
    }

    /**
    * Takes all the decisions and makes a page(s) with them listed.
    */
    private void writeDecisionsToPDF(Frame fullDocContents) throws Exception {
        
        Frame decisionSection = startNamedSection(fullDocContents, "Decision List");

        decisionSection.headerLeft = "Decision List";

        for (DecisionRecord dr : ngw.getDecisions()) {
            Frame innerFrame = decisionSection.newInteriorFrame();
            if (debugLines) {
                innerFrame.setBorderColor(Color.pink);
            }
            innerFrame.setPadding(5, 5, 5, 5);
            setH1Font();
            writeLineNoSpacing(innerFrame, "Decision #"+dr.getNumber()+" - "+convertDate(dr.getTimestamp()));
            writeWikiData(innerFrame, dr.getDecision());
        }
    }

    private void writeAttachmentListToPDF(Frame fullDocContents) throws Exception {
        Frame attachmentsSection = startNamedSection(fullDocContents, "Attachment Documents");

        int count = 0;
        for (AttachmentRecord att : ngw.getAllAttachments()) {
            Frame innerFrame = attachmentsSection.newInteriorFrame();
            if (debugLines) {
                innerFrame.setBorderColor(lightSkyBlue);
            }
            innerFrame.setPadding(5, 5, 5, 5);
            count++;

            setH3Font();
            writeLineNoSpacing(innerFrame, ""+count+". "+att.getDisplayName());
            
            setPFont();
            writeWikiData(innerFrame, att.getDescription());
        }
    }

    private void writeActionItemsToPDF(Frame fullDocContents) throws Exception {
        Frame actionsSection = startNamedSection(fullDocContents, "Action Items");

        int count = 0;
        for (GoalRecord actionItem : ngw.getAllGoals()) {
            Frame innerFrame = actionsSection.newInteriorFrame();
            count++;

            setH3Font();
            writeLineNoSpacing(innerFrame, ""+count+". "+actionItem.getSynopsis()
                    +" ("+GoalRecord.stateName(actionItem.getState())+")");
            
            setPFont();
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

    private void writeRolesToPDF(Frame fullDocContents) throws Exception {
        Frame rolesSection = startNamedSection(fullDocContents, "Roles");

        int count = 0;
        for (CustomRole role : ngw.getAllRoles()) {
            Frame oneRoleFrame = rolesSection.newInteriorFrame();
            count++;

            setH3Font();
            writeLineNoSpacing(oneRoleFrame, ""+count+". "+role.getName());

            setPFont();
            writeWikiData(oneRoleFrame, role.getDescription());
            writeWikiData(oneRoleFrame, role.getRequirements());
            for (AddressListEntry ale : role.getDirectPlayers()) {
                writeLineNoSpacing(oneRoleFrame, "- "+ale.getName());
            }
            makeHorizontalRule(oneRoleFrame);
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
    private void writeLineNoSpacing(Frame frame, String text) throws Exception {
        Paragraph para = frame.getNewParagraph();
        para.setSpaceAfter(0);
        para.setSpaceBefore(0);
        para.addTextCarefully(text, currentLineSize, currentFont);
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
        } 
        else if (line.equals("{{{")) {
            para = frame.getNewParagraph();
            startPRE();
        } 
        else if (line.startsWith("}}}")) {
            terminate();
            para = frame.getNewParagraph();
        } 
        else if (line.startsWith("!!!")) {
            para = startHeader(frame, line, 3);
        } 
        else if (line.startsWith("!!")) {
            para = startHeader(frame, line, 2);
        } 
        else if (line.startsWith("!")) {
            para = startHeader(frame, line, 1);
        } 
        else if (line.startsWith("***")) {
            para = startBullet(frame, line, 3);
        } 
        else if (line.startsWith("**")) {
            para = startBullet(frame, line, 2);
        } 
        else if (line.startsWith("*")) {
            para = startBullet(frame, line, 1);
        } 
        else if (line.startsWith(":")) {
            para = startParagraph(frame);
            scanForStyle(para, line, 1);
        } else if (line.startsWith("----")) {
            terminate();
            makeHorizontalRule(frame);
            para = frame.getNewParagraph();
        } else if (isIndented) {
            // continue whatever mode there is
            scanForStyle(para, line, skipSpaces(line,0));
        }else {

            if (majorState != PARAGRAPH && majorState != PREFORMATTED) {
                para = startParagraph(frame);
            }
            scanForStyle(para, line, 0);
        }
        return para;
    }

    protected void terminate() throws Exception
    {
        majorState = NOTHING;
        majorLevel = 0;
        isBold = false;
        isItalic = false;
        indent = 0;
    }

    protected Paragraph startParagraph(Frame frame) throws Exception
    {
        terminate();
        
        Paragraph para = frame.getNewParagraph();
        para.setSpaceBefore(8);
        para.setSpaceAfter(8);
        setPFont();
        indent = 0;
        majorState = PARAGRAPH;
        majorLevel = 0;
        return para;
    }

    protected void startPRE() throws Exception
    {
        terminate();
        setPREFont();
        majorState = PREFORMATTED;
        majorLevel = 0;
        indent = 0;
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


    protected Paragraph startBullet(Frame container, String line, int level) throws Exception {
        
        if (majorState != BULLET) {
            terminate();
            majorState = BULLET;
        }

        setPFont();
        Frame indentedFrame = container.newInteriorFrame();
        indentedFrame.setMargin(20*level, 0, 0, 0);
        if (debugLines) {
            indentedFrame.setBorder(Color.magenta, new Stroke());
        }
        Paragraph para = indentedFrame.getNewParagraph();
        

        //scanForStyle(para, line, skipSpaces(line, level)); 
        //UNTIL REAL BULLETS CAN BE CREATED use the asterisks at bullet points
        scanForStyle(para, line, 0);
        return para;
    }

    protected Paragraph startHeader(Frame frame, String line, int level)
            throws Exception
    {
        terminate();
        Paragraph para = frame.getNewParagraph();
        indent = 0;
        majorState = HEADER;
        majorLevel = level;
        switch (level) {
        case 3:
            setH1Font();
            para.setSpaceBefore(24);
            para.setSpaceAfter(8);
            break;
        case 2:
            setH2Font();
            para.setSpaceBefore(18);
            para.setSpaceAfter(8);
            break;
        case 1:
            setH3Font();
            para.setSpaceBefore(12);
            para.setSpaceAfter(8);
            break;
        }
        scanForStyle(para, line, skipSpaces(line, level));
        return para;
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
    public void findLinks(List<String> v, NGSection section) throws Exception
    {
        LineIterator li = new LineIterator(section.asText().trim());
        while (li.moreLines())
        {
            String thisLine = li.nextLine();
            scanLineForLinks(thisLine, v);
        }
    }

    protected void scanLineForLinks(String thisLine, List<String> v)
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
        //String linkAddr = linkName;
        if (barPos >= 0)
        {
            linkName = linkURL.substring(0,barPos).trim();
            //linkAddr = linkURL.substring(barPos+1).trim();
        }

        //boolean isExternal = (linkAddr.startsWith("http") && linkAddr.indexOf("/")>=0);
        //boolean lookupOK = false;

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


    /*
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
    */


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
