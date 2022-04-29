package com.purplehillsbooks.pdflayout.elements;


import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDPageContentStream;

import com.purplehillsbooks.pdflayout.text.DrawListener;
import com.purplehillsbooks.pdflayout.text.Position;

/**
 * A cutter transforms any Drawable element into a {@link Dividable}. It simply
 * <em>cuts</em> the drawable vertically into pieces matching the target height.
 */
public class Cutter implements Dividable, Drawable {

    private final Drawable undividable;
    private final float viewPortY;
    private final float viewPortHeight;

    public Cutter(Drawable undividableElement) throws Exception {
        this(undividableElement, 0, undividableElement.getHeight());
    }

    protected Cutter(Drawable undividable, float viewPortY, float viewPortHeight) {
        this.undividable = undividable;
        this.viewPortY = viewPortY;
        this.viewPortHeight = viewPortHeight;
    }

    @Override
    public Divided divide(float remainingHeight, final float pageHeight) {
        return new Divided(new Cutter(undividable, viewPortY, remainingHeight),
                new Cutter(undividable, viewPortY - remainingHeight,
                        viewPortHeight - remainingHeight));
    }

    @Override
    public float getWidth() throws Exception {
        return undividable.getWidth();
    }

    @Override
    public float getHeight() throws Exception {
        return viewPortHeight;
    }

    @Override
    public Position getAbsolutePosition() {
        return null;
    }

    @Override
    public void draw(PDDocument pdDocument, PDPageContentStream contentStream,
            Position upperLeft, DrawListener drawListener) throws Exception {
        Position viewPortOrigin = upperLeft.add(0, -viewPortY);
        undividable.draw(pdDocument, contentStream, viewPortOrigin, drawListener);
    }

    @Override
    public Drawable removeLeadingEmptyVerticalSpace() throws Exception {
        return new Cutter(undividable.removeLeadingEmptyVerticalSpace());
    }

}
