package com.purplehillsbooks.pdflayout.text;

import java.util.ArrayList;
import java.util.List;

/**
 * A tagging interface describing some drawable text consisting of text
 * fragments.
 */
public abstract class TextSequence implements DrawableText, Iterable<TextFragment> {

    
    /**
     * Dissects the given sequence into {@link TextLine}s.
     *
     * @param text
     *            the text to extract the lines from.
     * @return the list of text lines.
     * @throws Exception
     *             by pdfbox
     */
    public List<TextLine> getLines()
            throws Exception {
        final List<TextLine> result = new ArrayList<TextLine>();

        TextLine line = new TextLine();
        for (TextFragment fragment : this) {
            if (fragment instanceof NewLine) {
                line.setNewLine((NewLine) fragment);
                result.add(line);
                line = new TextLine();
            } else if (fragment instanceof ReplacedWhitespace) {
                // ignore replaced whitespace
            } else {
                line.add((StyledText) fragment);
            }
        }
        if (!line.isEmpty()) {
            result.add(line);
        }
        return result;
    }


    
}
