package com.purplehillsbooks.pdflayout.elements;


import java.awt.Color;
import java.util.List;

import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDPageContentStream;
import org.apache.pdfbox.pdmodel.font.PDType1Font;

import com.purplehillsbooks.pdflayout.text.Alignment;
import com.purplehillsbooks.pdflayout.text.DrawListener;
import com.purplehillsbooks.pdflayout.text.Position;
import com.purplehillsbooks.pdflayout.text.TextFlow;
import com.purplehillsbooks.pdflayout.text.TextLine;
import com.purplehillsbooks.pdflayout.text.TextSequenceUtil;
import com.purplehillsbooks.pdflayout.text.WidthRespecting;

/**
 * A paragraph is used as a container for {@link TextFlow text} that is drawn as
 * one element. A paragraph has a {@link #setAlignment(Alignment) (text-)
 * alignment}, and {@link WidthRespecting respects a given width} by applying
 * word-wrap.
 */
public class Paragraph extends TextFlow implements Drawable, Element,
        WidthRespecting, Dividable {

    private Position absolutePosition;
    private Alignment alignment = Alignment.Left;
    private float spaceBefore = 6;
    private float spaceAfter  = 6;

    @Override
    public Position getAbsolutePosition() {
        return absolutePosition;
    }

    @Override
    public float getHeight() throws Exception {
        if (isEmpty()) {
            //if empty, completely ignore this paragraph
            return 0;
        }
        float textHeight = super.getHeight();
        return textHeight + spaceBefore + spaceAfter;
    }
    
    
    public float getSpaceBefore() {
        return spaceBefore;
    }
    public void setSpaceBefore(float val) {
        spaceBefore = val;
    }
    public float getSpaceAfter() {
        return spaceAfter;
    }
    public void setSpaceAfter(float val) {
        spaceAfter = val;
    }
    
    /**
     * Sets the absolute position to render at.
     *
     * @param absolutePosition
     *            the absolute position.
     */
    public void setAbsolutePosition(Position absolutePosition) {
        this.absolutePosition = absolutePosition;
    }

    /**
     * @return the text alignment to apply. Default is left.
     */
    public Alignment getAlignment() {
        return alignment;
    }

    /**
     * Sets the alignment Left/Right/Center/Justified to apply.
     *
     * @param alignment
     *            the text alignment.
     */
    public void setAlignment(Alignment alignment) {
        this.alignment = alignment;
    }

    @Override
    public void draw(PDDocument pdDocument, PDPageContentStream contentStream,
            Position upperLeft, DrawListener drawListener) throws Exception {
        if (isEmpty()) {
            //if the paragraph has absolutely no text in it, then ignore it
            //so there is no extra white space or anything.
            return;
        }
        //we need to move the paragraph down by the amount of spaceBefore
        Position spacedPosition = upperLeft.add(0, -spaceBefore);
        drawText(contentStream, spacedPosition, getAlignment(), drawListener );
        
        //for debug make a rectangle
        /*
        float height = this.getHeight() - spaceBefore - spaceAfter;
        float width = this.getWidth();
        contentStream.setStrokingColor(Color.green);
        contentStream.setLineWidth(1);
        contentStream.addRect(spacedPosition.getX(), spacedPosition.getY() - height,
                width, height);
        contentStream.stroke();
        */
    }

    /**
     * Word-wraps and divides the given text sequence.
     *
     * @param text
     *            the text to divide.
     * @param maxWidth
     *            the max width used for word-wrapping.
     * @param maxHeight
     *            the max height for divide.
     * @return the Divided element containing the parts.
     */
    @Override
    public Divided divide(float remainingHeight, final float pageHeight) throws Exception {
        final float maxWidth = getMaxWidth();
        final float maxHeight = remainingHeight;
        TextFlow wrapped = TextSequenceUtil.wordWrap(this, maxWidth);
        List<TextLine> lines = wrapped.getLines();

        Paragraph first = new Paragraph();
        Paragraph tail = new Paragraph();
        
        first.setMaxWidth(this.getMaxWidth());
        first.setLineSpacing(this.getLineSpacing());
        first.setAlignment(this.getAlignment());
        first.setApplyLineSpacingToFirstLine(this.isApplyLineSpacingToFirstLine());
        first.setSpaceBefore(this.getSpaceBefore());
        first.setSpaceAfter(0);
        
        tail.setMaxWidth(this.getMaxWidth());
        tail.setLineSpacing(this.getLineSpacing());
        tail.setAlignment(this.getAlignment());
        tail.setApplyLineSpacingToFirstLine(this.isApplyLineSpacingToFirstLine());
        tail.setSpaceBefore(0);
        tail.setSpaceAfter(this.getSpaceAfter());

        int index = 0;
        while (index < lines.size() && first.getHeight() < maxHeight) {
            TextLine line = lines.get(index);
            float newHeight = line.getHeight();
            if (first.getHeight()+newHeight > maxHeight) {
                break;
            }
            first.add(line);
            ++index;
        }

        while (index < lines.size()) {
            tail.add(lines.get(index));
            ++index;
        }
        return new Divided(first, tail);
    }

    @Override
    public Paragraph removeLeadingEmptyVerticalSpace() throws Exception {
        return removeLeadingEmptyLines();
    }

    @Override
    public Paragraph removeLeadingEmptyLines() throws Exception {
        Paragraph result = (Paragraph) super.removeLeadingEmptyLines();
        result.setAbsolutePosition(this.getAbsolutePosition());
        result.setAlignment(this.getAlignment());
        return result;
    }

    @Override
    protected Paragraph createInstance() {
        return new Paragraph();
    }
    
    
    public Paragraph addTextCarefully(String text, float size, PDType1Font font) throws Exception {
        int start=0;
        for (int end=0; end<text.length(); end++) {
            int codePoint = text.codePointAt(end);
            if (!font.hasGlyph(font.codeToName(codePoint))) {
                if (start<end) {
                    String unprocessed = text.substring(start, end);
                    addText(unprocessed, size, font);
                }
                addText("?", size, font);
                start = end+1;
            }
        }
        if (start<text.length()) {
            String unprocessed = text.substring(start);
            addText(unprocessed, size, font);
        }
        return this;
    }

}
