package com.purplehillsbooks.pdflayout.text;


import org.apache.pdfbox.pdmodel.PDPageContentStream;

/**
 * Represents a drawable text.
 */
public interface DrawableText extends Area {

    /**
     * Draws the text of the (PdfBox-) cursor position.
     *
     * @param contentStream
     *            the content stream used to render.
     * @param upperLeft
     *            the upper left position to draw to.
     * @param alignment
     *            the text alignment.
     * @param drawListener
     *            the listener to
     *            {@link DrawListener#drawn(Object, Position, float, float)
     *            notify} on drawn objects.
     * @throws Exception
     *             by pdfbox.
     */
    void drawText(PDPageContentStream contentStream, Position upperLeft,
            Alignment alignment, DrawListener drawListener) throws Exception;
}
