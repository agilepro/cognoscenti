package com.purplehillsbooks.pdflayout.shape;


import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDPageContentStream;

import com.purplehillsbooks.pdflayout.text.Position;

/**
 * A simple rectangular shape.
 */
public class Rect extends AbstractShape {

    @Override
    public void add(PDDocument pdDocument, PDPageContentStream contentStream,
            Position upperLeft, float width, float height) throws Exception {
        contentStream.addRect(upperLeft.getX(), upperLeft.getY() - height,
                width, height);
    }

}
