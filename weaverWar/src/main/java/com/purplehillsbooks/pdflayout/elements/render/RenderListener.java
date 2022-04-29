package com.purplehillsbooks.pdflayout.elements.render;

/**
 * A render listener is called before and after a page has been rendered. It may
 * be used, to perform some custom operations (drawings) to the page.
 *
 */
public interface RenderListener {

    /**
     * Called before any rendering is performed to the page.
     *
     * @param renderContext the context providing all rendering state.
     * @throws Exception by pdfbox.
     */
    void beforePage(final RenderContext renderContext) throws Exception;

    /**
     * Called after any rendering is performed to the page.
     *
     * @param renderContext the context providing all rendering state.
     * @throws Exception by pdfbox.
     */
    void afterPage(final RenderContext renderContext) throws Exception;
}
