package com.purplehillsbooks.pdflayout.text;

import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDPage;
import org.apache.pdfbox.pdmodel.PDPageContentStream;

/**
 * Provides the current page and document to draw to.
 */
public interface DrawContext {

    /**
     * @return the document to draw to.
     */
    public PDDocument getPdDocument();

    /**
     * @return the current page to draw to.
     */
    public PDPage getCurrentPage();

    /**
     * @return the current page content stream.
     */
    public PDPageContentStream getCurrentPageContentStream();
}
