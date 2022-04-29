package com.purplehillsbooks.pdflayout.elements.render;

import com.purplehillsbooks.pdflayout.elements.Element;

/**
 * A renderer is responsible for rendering certain, but not necessarily all
 * elements. The boolean return value indicates whether the element could be
 * processed by this renderer.
 */
public interface Renderer {

    /**
     * Renders an element.
     *
     * @param renderContext
     *            the render context.
     * @param element
     *            the element to draw.
     * @param layoutHint
     *            the associated layout hint
     * @return <code>true</code> if the layout is able to render the element.
     * @throws Exception
     *             by pdfbox
     */
    boolean render(final RenderContext renderContext, final Element element,
            final LayoutHint layoutHint) throws Exception;

}
