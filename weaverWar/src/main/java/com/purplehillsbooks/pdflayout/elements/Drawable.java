package com.purplehillsbooks.pdflayout.elements;

import java.io.IOException;

import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDPageContentStream;

import com.purplehillsbooks.pdflayout.elements.render.Layout;
import com.purplehillsbooks.pdflayout.text.DrawListener;
import com.purplehillsbooks.pdflayout.text.Position;

/**
 * Common interface for drawable objects.
 */
public interface Drawable {

    /**
     * @return the width of the drawable.
     * @throws IOException
     *             by pdfbox
     */
    float getWidth() throws IOException;

    /**
     * @return the height of the drawable.
     * @throws IOException
     *             by pdfbox
     */
    float getHeight() throws IOException;

    /**
     * If an absolute position is given, the drawable will be drawn at this
     * position ignoring any {@link Layout}.
     *
     * @return the absolute position.
     * @throws IOException
     *             by pdfbox
     */
    Position getAbsolutePosition() throws IOException;

    /**
     * Draws the object at the given position.
     *
     * @param pdDocument
     *            the underlying pdfbox document.
     * @param contentStream
     *            the stream to draw to.
     * @param upperLeft
     *            the upper left position to start drawing.
     * @param drawListener
     *            the listener to
     *            {@link DrawListener#drawn(Object, Position, float, float) notify} on
     *            drawn objects.
     * @throws IOException
     *             by pdfbox
     */
    void draw(PDDocument pdDocument, PDPageContentStream contentStream,
            Position upperLeft, DrawListener drawListener) throws IOException;

    /**
     * @return a copy of this drawable where any leading empty vertical space is
     *         removed, if possible. This is useful for avoiding leading empty
     *         space on a new page.
     * @throws IOException
     *             by pdfbox
     */
    Drawable removeLeadingEmptyVerticalSpace() throws IOException;
}
