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

package org.socialbiz.cog.util;

import java.awt.Color;
import java.io.IOException;
import java.io.OutputStream;
import java.io.StringWriter;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
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
import org.socialbiz.cog.AuthDummy;
import org.socialbiz.cog.AuthRequest;
import org.socialbiz.cog.IdGenerator;
import org.socialbiz.cog.LineIterator;
import org.socialbiz.cog.MimeTypes;
import org.socialbiz.cog.NGPage;
import org.socialbiz.cog.NGPageIndex;
import org.socialbiz.cog.NoteRecord;
import org.socialbiz.cog.SectionUtil;
import org.socialbiz.cog.SectionWiki;
import org.socialbiz.cog.UserProfile;

public class PDFUtil {

    boolean startWithBullet = false;
    float xPos = 200f;
    float yPos = 800f;
    float xShift = 0f;
    float yShift = 0f;

    float previousSubLineWidth = 0.0f;
    int notesIndex = 0;

    PDFont nbfont = PDType1Font.HELVETICA_BOLD;
    PDFont font = PDType1Font.TIMES_ROMAN;
    PDFont bfont = PDType1Font.TIMES_BOLD;
    PDDocument document;
    PDPage page;
    PDPageContentStream contentStream;

    int font_size = 10;
    int h1_font_size = 14;
    int h2_font_size = 12;
    int h3_font_size = 10;

    PDActionURI uri = new PDActionURI();
    PDBorderStyleDictionary borderULine = new PDBorderStyleDictionary();

    List<String> wrappedListOfLink = new ArrayList<String>();
    int wIndex = 0;

    AuthRequest ar = null;
    int restLineWidth = 120;
    boolean isNewPage = false;
    public PDFUtil(){
        document = null;
    }

    void initializeWrappedListOfLink(){
        wrappedListOfLink = new ArrayList<String>();
    }

    private void setCusrosrPosition(float nxShift, float nyShift)throws Exception{
        xShift = nxShift;
        yShift = nyShift;
        xPos = xPos + xShift;
        yPos = yPos + yShift;
        if(xPos >= 590){
            xPos = 40;
        }
        setPage();
    }

    private void setPage()throws Exception{
        if(document == null){ //Initialize
            document = new PDDocument();
            page = new PDPage();
            page.setMediaBox(PDPage.PAGE_SIZE_A4);
            document.addPage( page );
            contentStream = new PDPageContentStream(document, page, false, false);
            contentStream.beginText();
            contentStream.moveTextPositionByAmount( xPos, yPos );
            isNewPage = true;
        }else{
            if(yPos <= 40){  //Close the old page create new
                contentStream.endText();
                contentStream.close();
                page = new PDPage();
                page.setMediaBox(PDPage.PAGE_SIZE_A4);
                document.addPage( page );
                contentStream = new PDPageContentStream(document, page, false, false);
                yPos = 800;
                xShift = 0;
                yShift = 0;
                contentStream.beginText();
                contentStream.setFont( font, font_size );
                contentStream.moveTextPositionByAmount(xPos,yPos);
                isNewPage = true;
            }else{
                contentStream.moveTextPositionByAmount( xShift, yShift );
            }
        }
    }

    /**
     * TODO: This appears to be a duplicate method, eliminate this or the other
     */
    public void serveUpFile(AuthRequest ar, String pageId) throws Exception{
        NGPage ngp = ar.getCogInstance().getProjectByKeyOrFail(pageId);
        ar.setPageAccessLevels(ngp);

        Vector<NoteRecord> publicNotes = new Vector<NoteRecord>();
        Vector<NoteRecord> memberNotes = new Vector<NoteRecord>();

        List<String> publicNoteList = null;
        if(ar.req.getParameterValues("publicNotes")!= null){
            publicNoteList = Arrays.asList(ar.req.getParameterValues("publicNotes"));
            for (String noteId : publicNoteList) {
                publicNotes.add(ngp.getNote(noteId));
            }
        }

        List<String> memberNoteList = null;
        if(ar.isLoggedIn() && ar.req.getParameterValues("memberNotes") != null ){
            memberNoteList = Arrays.asList(ar.req.getParameterValues("memberNotes"));
            for (String noteId : memberNoteList) {
                memberNotes.add(ngp.getNote(noteId));
            }
        }

        this.ar = ar;
        setPage(); //Initialize
        String projectName = ngp.getFullName();
        contentStream.setFont(nbfont, h1_font_size );

        contentStream.drawString(projectName);
        setCusrosrPosition(-160 ,-40);

        if(publicNoteList != null && publicNoteList.size() > 0){
            contentStream.setFont( nbfont, h1_font_size );
            contentStream.drawString("Public Notes : ");
            setCusrosrPosition(0,-30);
            writeInPDF(ar, publicNotes);
        }

        if(memberNoteList != null && memberNoteList.size() > 0){
            notesIndex = 0;
            if(!isNewPage){
                yPos = 0;
                setPage();
            }
            contentStream.setFont( nbfont, h1_font_size );
            contentStream.drawString("Member Notes : ");
            setCusrosrPosition(0,-30);
            writeInPDF(ar, memberNotes);
        }

        contentStream.endText();
        contentStream.close();
        String fileName = IdGenerator.generateKey() + ".pdf";
        String mimeType=MimeTypes.getMimeType(fileName);
        ar.resp.setContentType(mimeType);
        //set expiration to about 1 year from now
        //ar.resp.setDateHeader("Expires", System.currentTimeMillis()+3000000);
        ar.resp.setHeader( "Content-Disposition", "attachment; filename=\"" + fileName + "\"" );
        OutputStream out = ar.resp.getOutputStream();
        document.save(out);
        document.close();
        out.flush();
    }

    private void writeInPDF(AuthRequest ar, Vector<NoteRecord> notes) throws Exception, IOException {

        for (NoteRecord lr : notes) {
            String data = lr.getWiki();

            String subject = lr.getSubject();
            if (subject == null || subject.length() == 0) {
                subject = "Untitled Note";
            }

            if(subject.length() > 45){
                subject = subject.substring(0,45)+"...";
            }
            String lastEditor = lr.getModUser().getName();
            String editTime = SectionUtil.getNicePrintTime(lr.getLastEdited(),  ar.nowTime).trim();
            setCusrosrPosition(10,-5);
            contentStream.setFont( nbfont, h2_font_size );
            String noteHeader =  String.valueOf(notesIndex+1) + ".  " + subject;
            contentStream.drawString(noteHeader);

            contentStream.setFont( font, font_size );

            addUserLinkAnnotation(xPos, yPos, 11, lastEditor, editTime);

            setCusrosrPosition(20,-25);
            contentStream.endText();
            contentStream.drawLine(xPos-20, yPos+20, 590, yPos+20);
            contentStream.beginText();
            contentStream.moveTextPositionByAmount( xPos, yPos );
            LineIterator li = new LineIterator(data);
            while (li.moreLines())
            {
                String thisLine = li.nextLine();
                if (thisLine.length() > 0){
                    isNewPage = false;
                    restLineWidth = 120;
                    previousSubLineWidth = 0;
                    parseAndWriteLine(thisLine);
                    startWithBullet = false;
                    setCusrosrPosition(0,-14);
                }
            }
            setCusrosrPosition(-30,-20);
            notesIndex++;
        }
    }

    private void parseAndWriteLine(String line)throws Exception{
        line = line.trim();
        if(line.length() == 0){
            return;
        }else if (line.equals("{{{")) {
            return;
        }else if (line.startsWith("}}}")) {
            if(line.length() > 3){
                line = line.substring(3).trim();
                writeRest(line);
            }
            return;
        } else if (line.startsWith("!!!")) {
            if(line.length() > 3){
                line = line.substring(3).trim();
                contentStream.setFont(bfont, h1_font_size);
                setCusrosrPosition(0,-2);
                writeRest(line);
                contentStream.setFont( font, font_size );
                return;
            }
        } else if (line.startsWith("!!")) {
            if(line.length() > 2){
                line = line.substring(2).trim();
                contentStream.setFont(bfont, h2_font_size);
                setCusrosrPosition(0,-2);
                writeRest(line);
                contentStream.setFont( font, font_size );
                return;
            }
        } else if (line.startsWith("!")) {
            if(line.length() > 1){
                line = line.substring(1).trim();
                contentStream.setFont(bfont, h3_font_size);
                setCusrosrPosition(0,-2);
                writeRest(line);
                contentStream.setFont( font, font_size );
                return;
            }
        } else if (line.startsWith("***")) {
            if(line.length() > 3){
                setCusrosrPosition(60,0);

                contentStream.setFont(nbfont, h1_font_size);
                writeString(".");
                contentStream.setFont( font, font_size );
                line = line.substring(3).trim();
                writeRest(line);
                setCusrosrPosition(-60,0);
                return;
            }
        } else if (line.startsWith("**")) {
            if(line.length() > 2){
                setCusrosrPosition(40,0);
                contentStream.setFont(nbfont, h1_font_size);
                writeString(". ");
                contentStream.setFont( font, font_size );
                line = line.substring(2).trim();
                writeRest(line);
                setCusrosrPosition(-40, 0);
                return;
            }
        } else if (line.startsWith("*")) {
            if(line.length() > 1){
                setCusrosrPosition(20,0);
                startWithBullet = true;
                contentStream.setFont(nbfont, h1_font_size);
                if(previousSubLineWidth > 0){
                    previousSubLineWidth += font.getStringWidth( ". " )/1000 * 10f;
                }else{
                    previousSubLineWidth += font.getStringWidth( "." )/1000 * 10f;
                }

                writeString(". ");
                contentStream.setFont( font, font_size );
                line = line.substring(1);
                writeRest(line);
                setCusrosrPosition(-20, 0);
                return;
            }
        } else if (line.startsWith(":")) {
            if(line.length() > 1){
                line = line.substring(1).trim();
                writeRest(line);
            }
        }else if (line.startsWith("----")) {
            contentStream.endText();
            contentStream.fillRect(xPos, yPos, 500, 0.5f);
            contentStream.beginText();
            contentStream.moveTextPositionByAmount( xPos, yPos );
            contentStream.setStrokingColor(Color.black);
            setCusrosrPosition(0,-15);
        }else{
            writeRest(line);
        }
    }

    private String checkForWiki(String line , int i){
        if((line.charAt(i) == '_' && line.startsWith("__''",i) && line.substring(i+4).contains("''__"))){
            return "bold_italic";
        }else if((line.charAt(i) == '\'' && line.startsWith("''__",i) && line.substring(i+4).contains("__''")) ){
            return "italic_bold";
        }else if(line.charAt(i) == '_' && (line.length() >= i+1) && line.charAt(i+1) == '_' && line.substring(2).contains("__")){
            return "bold";
        }else if(line.charAt(i) == '\'' && (line.length() >= i+1) && line.charAt(i+1) == '\''){
            return "italic";
        }else if(line.charAt(i) == '[' && line.contains("]")){
            return "hyperlink";
        }else{
            return "";
        }
    }

    private boolean checkMoreToken(String line){
        if(line.contains("__")|| line.contains("''") || (line.contains("'__"))
                || line.contains("__'")|| (line.contains("[") && line.contains("]"))){
            return true;
        }else{
            return false;
        }
    }

    private int getNextIndexOfChars(String line, String findText){
        if(line.contains(findText)){
            return line.indexOf(findText);
        }else{
            return -1;
        }
    }

    private void writeRest(String line) throws IOException, Exception {

        while(line.length()>0){
            if(checkMoreToken(line)){
                for (int i = 0; i < line.length(); i++) {
                    String wikiToken = checkForWiki(line , i);
                    if("bold".equals(wikiToken)){
                        line = formatAndWrite(line, i,PDType1Font.TIMES_BOLD, "__");
                        break;
                    }else if("italic".equals(wikiToken)){
                        line = formatAndWrite(line, i,PDType1Font.TIMES_ITALIC, "''");
                        break;
                    }else if("bold_italic".equals(wikiToken)){
                        line = formatAndWrite(line, i,PDType1Font.TIMES_BOLD_ITALIC, "''__");
                        break;
                    }else if("italic_bold".equals(wikiToken)){
                        line = formatAndWrite(line, i,PDType1Font.TIMES_BOLD_ITALIC, "__''");
                        break;
                    }else if("hyperlink".equals(wikiToken)){
                        wIndex = 0;
                        initializeWrappedListOfLink();
                        String preLink = line.substring(0,i);
                        if(preLink.length()>0){
                            writeRest(preLink+" ");
                        }
                        float preLinkWidth = previousSubLineWidth+font.getStringWidth( preLink.substring(wIndex))/1000*10f;
                        addLinkAnnotation(yPos-3,22, line, preLinkWidth,i);
                        contentStream.setNonStrokingColor(Color.black);
                        line = line.substring(line.indexOf("]")+1);
                        break;
                    }
                }
            }else{
                wrappedAndWriteString(line);
                break;
            }
        }
    }

    private String formatAndWrite(String line, int i, PDType1Font formattedFont, String endFormatText) throws Exception,
            IOException {

        String preLine = line.substring(0, i);
        previousSubLineWidth += font.getStringWidth( preLine )/1000 * 10f;
        wrappedAndWriteString(preLine);
        if(endFormatText.equals("''__") || endFormatText.equals("__''")){
            line = line.substring(i+4);
        }else{
            line = line.substring(i+2);
        }
        int tillIndex = getNextIndexOfChars(line, endFormatText);
        String formattedWords = line.substring(0, tillIndex).trim()+" ";

        contentStream.setFont( formattedFont  , 10 );
        wIndex = 0;
        writeRest(formattedWords);
        float fontSize = 10f;
        if(startWithBullet){
            fontSize = 10.8f;
        }
        if(wrappedListOfLink.size() > 0){
            previousSubLineWidth += font.getStringWidth(wrappedListOfLink.get(wrappedListOfLink.size()-1) )/1000 * fontSize;
        }
        contentStream.setFont( PDType1Font.TIMES_ROMAN , 10 );

        if(endFormatText.equals("''__") || endFormatText.equals("__''")){
            line = line.substring(tillIndex+4);
        }else{
            line = line.substring(tillIndex+2);
        }
        return line;
    }

    private String wrappedAndWriteString(String line)throws Exception{
        if(line.trim().length() == 0) {
            return line;
        }
        String nLine = line;
        if(nLine.length() <= restLineWidth){
            contentStream.drawString(line);
            restLineWidth -= line.length();
            wrappedListOfLink.add(line);
            return line;
        }else{
            String trancatedText =line.substring(0,restLineWidth);
            int wrappedIndex = trancatedText.lastIndexOf(" ");
            String wrappedText = trancatedText;
            if(wrappedIndex >= 0){
                wIndex = wrappedIndex;
                wrappedText = trancatedText.substring(0, wrappedIndex);
                nLine = line.substring(wrappedIndex);
            }else{
                nLine = line.substring(wrappedText.length());
                wIndex = line.indexOf(nLine);
            }
            contentStream.drawString(wrappedText);
            wrappedListOfLink.add(wrappedText);

            setCusrosrPosition(0,-14);
            restLineWidth = 120;
            previousSubLineWidth = 0;
            return wrappedAndWriteString(nLine);
        }

    }

    private void writeString(String line)throws Exception{
        if(line.trim().length() == 0) {
            return;
        }
        String nLine = line;
        if(nLine.length() <= 120){
            contentStream.drawString(line);
        }else{
            String trancatedText =line.substring(0,120);
            int wrappedIndex = trancatedText.lastIndexOf(" ");
            String wrappedText = trancatedText.substring(0, wrappedIndex);
            contentStream.drawString(wrappedText);
            nLine = line.substring(wrappedIndex);
            setCusrosrPosition(0,-12);
            writeString(nLine);
        }
    }

    private void addLinkAnnotation(float y, float hieght, String line, float preLinkWidth, int i) throws Exception{

        String link = line.substring(i+1, line.indexOf("]"));
        String linkName = outputLink(link);
        contentStream.setNonStrokingColor(Color.blue);
        wIndex = 0;
        initializeWrappedListOfLink();
        writeRest(linkName);

        float fontSize = 10f;
        float textWidth = (font.getStringWidth( linkName )/1000) * fontSize;
        if(startWithBullet){
            textWidth = (font.getStringWidth( linkName+" " )/1000) * fontSize;
        }
        if(previousSubLineWidth > 0){
            preLinkWidth += (font.getStringWidth( " " )/1000) * fontSize;
        }

        borderULine.setStyle(PDBorderStyleDictionary.STYLE_UNDERLINE);
        borderULine.setWidth(0.5f);
        float drawLinkStartingPoint = 0;
        int index = 0;
        for (String text_element : wrappedListOfLink) {
            textWidth = (font.getStringWidth( text_element )/1000) * fontSize;
            if(index == 0){
                drawLinkStartingPoint = xPos+ preLinkWidth+2;
                if(wrappedListOfLink.size() > 1){
                    previousSubLineWidth = 0;
                }else{
                    previousSubLineWidth = ((font.getStringWidth( text_element )/1000) * 10f) + preLinkWidth;
                }
            }else if(index == wrappedListOfLink.size()-1){
                drawLinkStartingPoint = xPos;
                previousSubLineWidth = (font.getStringWidth( text_element )/1000) * fontSize;
            }else{
                drawLinkStartingPoint = xPos;
                previousSubLineWidth = 0;
            }
            createLink(drawLinkStartingPoint, y+1, textWidth, 10, link);

            preLinkWidth = 0;
            index++;
            if(wrappedListOfLink.size() > 1){
                y -= 15;
            }
        }
    }

    private void addUserLinkAnnotation(float x,float y, float hieght, String userId, String editTime) throws Exception{

        StringWriter writer = new StringWriter();
        AuthRequest clone = new AuthDummy(ar.getUserProfile(), writer, ar.getCogInstance());
        clone.setNewUI(true);
        clone.retPath = ar.baseURL;
        UserProfile.writeLink(clone, userId);

        Map<String, String> userInfoMap = parseStringForUserInfo(writer.toString());
        String cleanName = "";
        if(userInfoMap.containsKey("cleanName")){
            cleanName = userInfoMap.get("cleanName");
        }

        String editedBy = "    Last edited by "+cleanName+" "+editTime;
        float rightMargin = 55f;
        if(editedBy.length() > 60){
            rightMargin = 20f;
        }else if(editedBy.length() < 30){
            rightMargin = 50f;
        }

        int alignFromRight = (int)((595 - (((font.getStringWidth( editedBy )/1000) * 10f)+rightMargin)));

        if(userId.length() == 0){
            alignFromRight -= 80;
        }
        setCusrosrPosition(alignFromRight,0);

        writeRest("    Last edited by ");
        contentStream.setNonStrokingColor(Color.blue);
        writeRest(cleanName);
        contentStream.setNonStrokingColor(Color.black);
        writeRest("  "+editTime);

        String link = "";
        if(userInfoMap.containsKey("link")){
            link = userInfoMap.get("link");
        }

        float textWidth = (font.getStringWidth( cleanName )/1000) * 10f;

        createLink(x+alignFromRight+((font.getStringWidth( "    Last edited by " )/1000) * 10f), yPos-2, textWidth, 11, link);

        setCusrosrPosition(-alignFromRight,0);

    }

    private void createLink(float x, float y, float textWidth, float height, String link) throws IOException{
        PDRectangle position = new PDRectangle();
        position.setLowerLeftX(x);
        position.setLowerLeftY(y); // down a couple of points
        position.setUpperRightX(x+ textWidth);
        position.setUpperRightY(y+height);

        uri = new PDActionURI();
        uri.setURI(link);

        PDAnnotationLink txtLink = new PDAnnotationLink();
        txtLink.setRectangle(position);
        txtLink.setAction(uri);
        txtLink.setBorderStyle(borderULine);
        PDGamma gamma = new PDGamma();
        gamma.setB(1);
        txtLink.setColour(gamma);
        @SuppressWarnings("unchecked")
        List<PDAnnotationLink> annotations = page.getAnnotations();
        annotations.add(txtLink);

    }

    private Map<String, String> parseStringForUserInfo(String writer) {
        Map<String, String> userInfoMap = new HashMap<String, String>();
        if(writer.contains("<a")){
            int beginIndex = writer.indexOf("href=\"")+6;
            String tmp =  writer.substring(beginIndex);

            int endIndex = tmp.indexOf("\"");

            String link =  writer.substring(beginIndex, beginIndex+endIndex);

            beginIndex = writer.indexOf("red\">")+5;
            endIndex = writer.indexOf("</span>");

            String cleanName =  writer.substring(beginIndex, endIndex);

            userInfoMap.put("link", link);
            userInfoMap.put("cleanName", cleanName);
        }else{
            userInfoMap.put("cleanName", writer);
        }
        return userInfoMap;
    }

    private String outputLink(String linkURL) throws Exception
    {
        boolean isImage = linkURL.startsWith("IMG:");

        int barPos = linkURL.indexOf("|");
        String linkName = linkURL.trim();
        String linkAddr = linkName;
        boolean userSpecifiedName = false;

        if (barPos >= 0)
        {
            linkName = linkURL.substring(0,barPos).trim();
            linkAddr = linkURL.substring(barPos+1).trim();
            userSpecifiedName = true;
        }

        // We treat any address that has forward slashes in it as an external
        // address which is included literally into the href.
        boolean isExternal = (linkAddr.startsWith("http") && linkAddr.indexOf("/")>=0);
        boolean pageExists = true;

        //if the link is missing, then just write the name out
        //might also include an indicator of the problem ....
        if (linkAddr.length()==0)
        {
            return linkName;
        }

        if (!isExternal)
        {
            //if the sanitized version of the link is empty, which might happen if
            //the link was all punctuation, then just write the name out
            //might also include an indicator of the problem ....
            String sanitizedName = SectionWiki.sanitize(linkAddr);
            if (sanitizedName.length()==0)
            {
                return linkName;
            }

            Vector<NGPageIndex> foundPages = ar.getCogInstance().getPageIndexByName(linkAddr);
            if (foundPages.size()==1)
            {
                NGPageIndex foundPI = foundPages.firstElement();
                linkAddr = ar.retPath + ar.getResourceURL(foundPI, "notesList.htm");
                if (!userSpecifiedName)
                {
                    linkName = foundPI.containerName;   //use the best name for page
                }
                pageExists = !foundPI.isDeleted;
            }
            else if (foundPages.size()==0)
            {
                linkAddr = ar.retPath + "";
            }
            else
            {
                //this is the case where there is more than one page
                linkAddr = ar.retPath + "Disambiguate.jsp?n="+SectionUtil.encodeURLData(linkAddr);

            }
        }
        if (isImage)
        {
            linkName = linkName.substring(4);
            if (pageExists)
            {
                uri = new PDActionURI();
                uri.setURI(linkAddr);
            }
        }
        else   //not an image
        {
            if (pageExists)
            {
                uri = new PDActionURI();
                uri.setURI(linkAddr);
            }
            else if (!ar.isLoggedIn() || ar.isStaticSite())
            {
                return linkName;
            }
            else
            {
                uri = new PDActionURI();
                uri.setURI(linkAddr);
            }
        }
        return linkName;
    }
    public static void main(String[] args){ //For test
        try{
            String path = args[0];
            PDDocument document = new PDDocument();
            PDPage page = new PDPage();
            page.setMediaBox(PDPage.PAGE_SIZE_A4);
            document.addPage( page );
            PDFont font = PDType1Font.HELVETICA;

            PDPageContentStream contentStream = new PDPageContentStream(document, page, false, false);
            contentStream.beginText();
            contentStream.setFont( font, 12 );
            contentStream.moveTextPositionByAmount( 100, 800 );
            String x = "hello world" ;
            contentStream.drawString( x);
            contentStream.moveTextPositionByAmount( -90, -15 );
            contentStream.setFont( font, 12 );
            contentStream.drawString( "Hello World3" );
            contentStream.endText();
            contentStream.close();
            document.save(path);
            document.close();
            System.out.println("DONE..");

        }catch(Exception e){
            e.printStackTrace();
        }
    }
}
