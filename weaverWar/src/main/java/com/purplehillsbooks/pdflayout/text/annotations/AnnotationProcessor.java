package com.purplehillsbooks.pdflayout.text.annotations;


import org.apache.pdfbox.pdmodel.PDDocument;

import com.purplehillsbooks.pdflayout.text.DrawContext;
import com.purplehillsbooks.pdflayout.text.Position;

/**
 * Processes an annotation.
 */
public interface AnnotationProcessor {

    /**
     * Called if an annotated object has been drawn.
     *
     * @param drawnObject
     *            the drawn object.
     * @param drawContext
     *            the drawing context.
     * @param upperLeft
     *            the upper left position the object has been drawn to.
     * @param width
     *            the width of the drawn object.
     * @param height
     *            the height of the drawn object.
     * @throws Exception
     *             by pdfbox.
     */
    void annotatedObjectDrawn(final Annotated drawnObject,
            final DrawContext drawContext, Position upperLeft, float width,
            float height) throws Exception;

    /**
     * Called before a page is drawn.
     *
     * @param drawContext
     *            the drawing context.
     * @throws Exception
     *             by pdfbox.
     */
    void beforePage(final DrawContext drawContext) throws Exception;

    /**
     * Called after a page is drawn.
     *
     * @param drawContext
     *            the drawing context.
     * @throws Exception
     *             by pdfbox.
     */
    void afterPage(final DrawContext drawContext) throws Exception;

    /**
     * Called after all rendering has been performed.
     *
     * @param document
     *            the document.
     * @throws Exception
     *             by pdfbox.
     */
    void afterRender(final PDDocument document) throws Exception;

}
