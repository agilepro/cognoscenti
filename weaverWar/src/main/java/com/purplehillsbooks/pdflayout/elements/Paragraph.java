package com.purplehillsbooks.pdflayout.elements;

import java.io.IOException;

import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDPageContentStream;
import org.apache.pdfbox.pdmodel.font.PDType1Font;

import com.purplehillsbooks.pdflayout.text.Alignment;
import com.purplehillsbooks.pdflayout.text.DrawListener;
import com.purplehillsbooks.pdflayout.text.Position;
import com.purplehillsbooks.pdflayout.text.TextFlow;
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

    @Override
    public Position getAbsolutePosition() {
        return absolutePosition;
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
     * Sets the alignment to apply.
     *
     * @param alignment
     *            the text alignment.
     */
    public void setAlignment(Alignment alignment) {
        this.alignment = alignment;
    }

    @Override
    public void draw(PDDocument pdDocument, PDPageContentStream contentStream,
            Position upperLeft, DrawListener drawListener) throws IOException {
        drawText(contentStream, upperLeft, getAlignment(), drawListener );
    }

    @Override
    public Divided divide(float remainingHeight, final float pageHeight)
            throws IOException {
        return TextSequenceUtil.divide(this, getMaxWidth(), remainingHeight);
    }

    @Override
    public Paragraph removeLeadingEmptyVerticalSpace() throws IOException {
        return removeLeadingEmptyLines();
    }

    @Override
    public Paragraph removeLeadingEmptyLines() throws IOException {
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
