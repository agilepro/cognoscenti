package com.purplehillsbooks.pdflayout.text;


/**
 * Defines an area with a width and height.
 */
public interface Area {

    /**
     * @return the width of the area.
     * @throws Exception by pdfbox
     */
    float getWidth() throws Exception;

    /**
     * @return the height of the area.
     * @throws Exception by pdfbox
     */
    float getHeight() throws Exception;
}
