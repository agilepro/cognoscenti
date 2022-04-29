package com.purplehillsbooks.pdflayout.elements.render;


import org.apache.pdfbox.pdmodel.PDPageContentStream;

import com.purplehillsbooks.pdflayout.elements.ControlElement;
import com.purplehillsbooks.pdflayout.elements.Cutter;
import com.purplehillsbooks.pdflayout.elements.Dividable;
import com.purplehillsbooks.pdflayout.elements.Dividable.Divided;
import com.purplehillsbooks.pdflayout.elements.Drawable;
import com.purplehillsbooks.pdflayout.elements.Element;
import com.purplehillsbooks.pdflayout.elements.PageFormat;
import com.purplehillsbooks.pdflayout.elements.VerticalSpacer;
import com.purplehillsbooks.pdflayout.text.Alignment;
import com.purplehillsbooks.pdflayout.text.Position;
import com.purplehillsbooks.pdflayout.text.WidthRespecting;
import com.purplehillsbooks.pdflayout.util.CompatibilityHelper;

/**
 * Layout implementation that stacks drawables vertically onto the page. If the
 * remaining height on the page is not sufficient for the drawable, it will be
 * {@link Dividable divided}. Any given {@link VerticalLayoutHint} will be taken
 * into account to calculate the position, width, alignment etc.
 */
public class VerticalLayout implements Layout {

    protected boolean removeLeadingEmptyVerticalSpace = true;

    /**
     * See {@link Drawable#removeLeadingEmptyVerticalSpace()}
     *
     * @return <code>true</code> if empty space (e.g. empty lines) should be
     *         removed at the begin of a page.
     */
    public boolean isRemoveLeadingEmptyVerticalSpace() {
        return removeLeadingEmptyVerticalSpace;
    }

    /**
     * Indicates if empty space (e.g. empty lines) should be removed at the
     * begin of a page. See {@link Drawable#removeLeadingEmptyVerticalSpace()}
     *
     * @param removeLeadingEmptyLines
     *            <code>true</code> if space should be removed.
     */
    public void setRemoveLeadingEmptyVerticalSpace(
            boolean removeLeadingEmptyLines) {
        this.removeLeadingEmptyVerticalSpace = removeLeadingEmptyLines;
    }

    /**
     * Turns to the next area, usually a page.
     *
     * @param renderContext
     *            the render context.
     * @throws Exception
     *             by pdfbox.
     */
    protected void turnPage(final RenderContext renderContext)
            throws Exception {
        renderContext.newPage();
    }

    /**
     * @param renderContext
     *            the render context.
     * @return the target width to draw to.
     */
    protected float getTargetWidth(final RenderContext renderContext) {
        float targetWidth = renderContext.getWidth();
        return targetWidth;
    }

    @Override
    public boolean render(RenderContext renderContext, Element element,
            LayoutHint layoutHint) throws Exception {
        if (element instanceof Drawable) {
            render(renderContext, (Drawable) element, layoutHint);
            return true;
        }
        if (element == ControlElement.NEWPAGE) {
            turnPage(renderContext);
            return true;
        }

        return false;
    }

    public void render(final RenderContext renderContext, Drawable drawable,
            final LayoutHint layoutHint) throws Exception {
        if (drawable.getAbsolutePosition() != null) {
            renderAbsolute(renderContext, drawable, layoutHint,
                    drawable.getAbsolutePosition());
        } else {
            renderReleative(renderContext, drawable, layoutHint);
        }
    }

    /**
     * Draws at the given position, ignoring all layouting rules.
     *
     * @param renderContext
     *            the context providing all rendering state.
     * @param drawable
     *            the drawable to draw.
     * @param layoutHint
     *            the layout hint used to layout.
     * @param position
     *            the left upper position to start drawing at.
     * @throws Exception
     *             by pdfbox
     */
    protected void renderAbsolute(final RenderContext renderContext,
            Drawable drawable, final LayoutHint layoutHint,
            final Position position) throws Exception {
        drawable.draw(renderContext.getPdDocument(),
                renderContext.getContentStream(), position, renderContext);
    }

    /**
     * Renders the drawable at the {@link RenderContext#getCurrentPosition()
     * current position}. This method is responsible taking any top or bottom
     * margin described by the (Vertical-)LayoutHint into account. The actual
     * rendering of the drawable is performed by
     * {@link #layoutAndDrawReleative(RenderContext, Drawable, LayoutHint)}.
     *
     * @param renderContext
     *            the context providing all rendering state.
     * @param drawable
     *            the drawable to draw.
     * @param layoutHint
     *            the layout hint used to layout.
     * @throws Exception
     *             by pdfbox
     */
    protected void renderReleative(final RenderContext renderContext,
            Drawable drawable, final LayoutHint layoutHint) throws Exception {
        VerticalLayoutHint verticalLayoutHint = null;
        if (layoutHint instanceof VerticalLayoutHint) {
            verticalLayoutHint = (VerticalLayoutHint) layoutHint;
            if (verticalLayoutHint.getMarginTop() > 0) {
                layoutAndDrawReleative(renderContext, new VerticalSpacer(
                        verticalLayoutHint.getMarginTop()), verticalLayoutHint);
            }
        }

        layoutAndDrawReleative(renderContext, drawable, verticalLayoutHint);

        if (verticalLayoutHint != null) {
            if (verticalLayoutHint.getMarginBottom() > 0) {
                layoutAndDrawReleative(renderContext, new VerticalSpacer(
                        verticalLayoutHint.getMarginBottom()),
                        verticalLayoutHint);
            }
        }
    }

    /**
     * Adjusts the width of the drawable (if it is {@link WidthRespecting}), and
     * divides it onto multiple pages if necessary. Actual drawing is delegated
     * to
     * {@link #drawReletivePartAndMovePosition(RenderContext, Drawable, LayoutHint, boolean)}
     * .
     *
     * @param renderContext
     *            the context providing all rendering state.
     * @param drawable
     *            the drawable to draw.
     * @param layoutHint
     *            the layout hint used to layout.
     * @throws Exception
     *             by pdfbox
     */
    protected void layoutAndDrawReleative(final RenderContext renderContext,
            Drawable drawable, final LayoutHint layoutHint) throws Exception {

        float targetWidth = getTargetWidth(renderContext);
        boolean movePosition = true;
        VerticalLayoutHint verticalLayoutHint = null;
        if (layoutHint instanceof VerticalLayoutHint) {
            verticalLayoutHint = (VerticalLayoutHint) layoutHint;
            targetWidth -= verticalLayoutHint.getMarginLeft();
            targetWidth -= verticalLayoutHint.getMarginRight();
            movePosition = !verticalLayoutHint.isResetY();
        }

        float oldMaxWidth = -1;
        if (drawable instanceof WidthRespecting) {
            WidthRespecting flowing = (WidthRespecting) drawable;
            oldMaxWidth = flowing.getMaxWidth();
            if (oldMaxWidth < 0) {
                flowing.setMaxWidth(targetWidth);
            }
        }

        Drawable drawablePart = removeLeadingEmptyVerticalSpace(drawable,
                renderContext);
        while (renderContext.getRemainingHeight() < drawablePart.getHeight()) {
            Dividable dividable = null;
            if (drawablePart instanceof Dividable) {
                dividable = (Dividable) drawablePart;
            } else {
                dividable = new Cutter(drawablePart);
            }
            Divided divided = dividable.divide(
                    renderContext.getRemainingHeight(),
                    renderContext.getHeight());
            drawReletivePartAndMovePosition(renderContext, divided.getFirst(),
                    layoutHint, true);

            // new page
            turnPage(renderContext);

            drawablePart = divided.getTail();
            drawablePart = removeLeadingEmptyVerticalSpace(drawablePart,
                    renderContext);
        }

        drawReletivePartAndMovePosition(renderContext, drawablePart,
                layoutHint, movePosition);

        if (drawable instanceof WidthRespecting) {
            if (oldMaxWidth < 0) {
                ((WidthRespecting) drawable).setMaxWidth(oldMaxWidth);
            }
        }
    }

    /**
     * Actually draws the (drawble) part at the
     * {@link RenderContext#getCurrentPosition()} and - depending on flag
     * <code>movePosition</code> - moves to the new Y position. Any left or
     * right margin is taken into account to calculate the position and
     * alignment.
     *
     * @param renderContext
     *            the context providing all rendering state.
     * @param drawable
     *            the drawable to draw.
     * @param layoutHint
     *            the layout hint used to layout.
     * @param movePosition
     *            indicates if the position should be moved (vertically) after
     *            drawing.
     * @throws Exception
     *             by pdfbox
     */
    protected void drawReletivePartAndMovePosition(
            final RenderContext renderContext, Drawable drawable,
            final LayoutHint layoutHint, final boolean movePosition)
            throws Exception {
        PDPageContentStream contentStream = renderContext.getContentStream();
        PageFormat pageFormat = renderContext.getPageFormat();
        float offsetX = 0;
        if (layoutHint instanceof VerticalLayoutHint) {
            VerticalLayoutHint verticalLayoutHint = (VerticalLayoutHint) layoutHint;
            Alignment alignment = verticalLayoutHint.getAlignment();
            float horizontalExtraSpace = getTargetWidth(renderContext)
                    - drawable.getWidth();
            switch (alignment) {
            case Right:
                offsetX = horizontalExtraSpace
                        - verticalLayoutHint.getMarginRight();
                break;
            case Center:
                offsetX = horizontalExtraSpace / 2f;
                break;
            default:
                offsetX = verticalLayoutHint.getMarginLeft();
                break;
            }
        }

        contentStream.saveGraphicsState();
        contentStream.addRect(0, pageFormat.getMarginBottom(), renderContext.getPageWidth(),
                renderContext.getHeight());
        CompatibilityHelper.clip(contentStream);

        drawable.draw(renderContext.getPdDocument(), contentStream,
                renderContext.getCurrentPosition().add(offsetX, 0),renderContext);

        contentStream.restoreGraphicsState();

        if (movePosition) {
            renderContext.movePositionBy(0, -drawable.getHeight());
        }
    }

    /**
     * Indicates if the current position is the top of page.
     *
     * @param renderContext
     *            the render context.
     * @return <code>true</code> if the current position is top of page.
     */
    protected boolean isPositionTopOfPage(final RenderContext renderContext) {
        return renderContext.getCurrentPosition().getY() == renderContext
                .getUpperLeft().getY();
    }

    /**
     * Removes empty space (e.g. empty lines) at the begin of a page. See
     * {@link Drawable#removeLeadingEmptyVerticalSpace()}
     *
     * @param drawable
     *            the drawable to process.
     * @param renderContext
     *            the render context.
     * @return the processed drawable
     * @throws Exception
     *             by pdfbox
     */
    protected Drawable removeLeadingEmptyVerticalSpace(final Drawable drawable,
            final RenderContext renderContext) throws Exception {
        if (isRemoveLeadingEmptyVerticalSpace()
                && isPositionTopOfPage(renderContext)) {
            return drawable.removeLeadingEmptyVerticalSpace();
        }
        return drawable;
    }

}
