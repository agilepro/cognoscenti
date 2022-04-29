package com.purplehillsbooks.pdflayout.elements;


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
     * @return the width of the drawable in points
     */
    float getWidth() throws Exception;

    /**
     * @return the height of the drawable in points
     */
    float getHeight() throws Exception;

    /**
     * If an absolute position is given, the drawable will be drawn at this
     * position ignoring any {@link Layout}.
     *
     * @return the absolute position.
     */
    Position getAbsolutePosition() throws Exception;

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
     * @throws Exception
     *             by pdfbox
     */
    void draw(PDDocument pdDocument, PDPageContentStream contentStream,
            Position upperLeft, DrawListener drawListener) throws Exception;

    /**
     * @return a copy of this drawable where any leading empty vertical space is
     *         removed, if possible. This is useful for avoiding leading empty
     *         space on a new page.
     * @throws Exception
     *             by pdfbox
     */
    Drawable removeLeadingEmptyVerticalSpace() throws Exception;
}
