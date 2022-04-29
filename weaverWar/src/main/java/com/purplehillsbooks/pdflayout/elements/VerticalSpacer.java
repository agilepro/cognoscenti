package com.purplehillsbooks.pdflayout.elements;


import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDPageContentStream;

import com.purplehillsbooks.pdflayout.text.DrawListener;
import com.purplehillsbooks.pdflayout.text.Position;

/**
 * A drawable element that occupies some vertical space without any graphical
 * representation.
 */
public class VerticalSpacer implements Drawable, Element, Dividable {

    private float height;

    /**
     * Creates a vertical space with the given height.
     *
     * @param height
     *            the height of the space.
     */
    public VerticalSpacer(float height) {
        this.height = height;
    }

    @Override
    public float getWidth() throws Exception {
        return 0;
    }

    @Override
    public float getHeight() throws Exception {
        return height;
    }

    @Override
    public Position getAbsolutePosition() {
        return null;
    }

    @Override
    public void draw(PDDocument pdDocument, PDPageContentStream contentStream,
            Position upperLeft, DrawListener drawListener) throws Exception {
        if (drawListener != null) {
            drawListener.drawn(this, upperLeft, getWidth(), getHeight());
        }
    }

    @Override
    public Divided divide(float remainingHeight, final float pageHeight)
            throws Exception {
        return new Divided(new VerticalSpacer(remainingHeight),
                new VerticalSpacer(getHeight() - remainingHeight));
    }

    @Override
    public Drawable removeLeadingEmptyVerticalSpace() {
        return this;
    }

}
