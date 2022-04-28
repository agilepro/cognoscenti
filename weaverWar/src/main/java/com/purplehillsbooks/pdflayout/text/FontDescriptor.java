package com.purplehillsbooks.pdflayout.text;

import org.apache.pdfbox.pdmodel.font.PDFont;

/**
 * Container for a Font and size.
 */
public class FontDescriptor {

    /**
     * the associated font.
     */
    private final PDFont font;

    /**
     * the font size.
     */
    private final float size;

    /**
     * Creates the descriptor the the given font and size.
     *
     * @param font the font.
     * @param size the size.
     */
    public FontDescriptor(final PDFont font, final float size) {
        this.font = font;
        this.size = size;
    }

    /**
     * @return the font.
     */
    public PDFont getFont() {
        return font;
    }

    /**
     * @return the size.
     */
    public float getSize() {
        return size;
    }

    @Override
    public String toString() {
        return "FontDescriptor [font=" + font + ", size=" + size + "]";
    }

    @Override
    public int hashCode() {
        final int prime = 31;
        int result = 1;
        result = prime * result + ((font == null) ? 0 : font.hashCode());
        result = prime * result + Float.floatToIntBits(size);
        return result;
    }

    @Override
    public boolean equals(final Object obj) {
        if (this == obj) {
            return true;
        }
        if (obj == null) {
            return false;
        }
        if (getClass() != obj.getClass()) {
            return false;
        }
        final FontDescriptor other = (FontDescriptor) obj;
        if (font == null) {
            if (other.font != null) {
                return false;
            }
        } else if (!font.equals(other.font)) {
            return false;
        }
        if (Float.floatToIntBits(size) != Float.floatToIntBits(other.size)) {
            return false;
        }
        return true;
    }

}
