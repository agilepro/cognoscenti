package com.purplehillsbooks.pdflayout.text;

import java.util.List;

import org.apache.pdfbox.pdmodel.PDPageContentStream;

import com.purplehillsbooks.pdflayout.util.Pair;
import com.purplehillsbooks.pdflayout.util.WordBreakerFactory;

/**
 * Utility methods for dealing with text sequences.
 */
public class TextSequenceUtil {



    /**
     * Word-wraps the given text sequence in order to fit the max width.
     *
     * @param text
     *            the text to word-wrap.
     * @param maxWidth
     *            the max width to fit.
     * @return the word-wrapped text.
     * @throws Exception
     *             by pdfbox
     */
    public static TextFlow wordWrap(final TextSequence text,
            final float maxWidth) throws Exception {

        float indentation = 0;
        TextFlow result = new TextFlow();
        float lineLength = indentation;
        boolean isWrappedLine = false;
        for (TextFragment fragment : text) {
            if (fragment instanceof NewLine) {
                isWrappedLine = fragment instanceof WrappingNewLine;
                result.add(fragment);
                lineLength = indentation;
                if (indentation > 0) {
                    result.add(new Indent(indentation).toStyledText());
                }
            } else if (fragment instanceof Indent) {
                if (indentation > 0) {
                    // reset indentation
                    result.removeLast();
                    indentation = 0;
                }
                indentation = fragment.getWidth();
                lineLength = fragment.getWidth();
                result.add(((Indent) fragment).toStyledText());
            } else {
                TextFlow words = splitWords(fragment);
                for (TextFragment word : words) {
                    WordWrapContext context = new WordWrapContext(word,
                            lineLength, indentation, isWrappedLine);
                    do {
                        context = wordWrap(context, maxWidth, result);
                    } while (context.isMoreToWrap());

                    indentation = context.getIndentation();
                    lineLength = context.getLineLength();
                    isWrappedLine = context.isWrappedLine();
                }
            }
        }
        return result;
    }

    private static WordWrapContext wordWrap(final WordWrapContext context,
            final float maxWidth, final TextFlow result) throws Exception {
        TextFragment word = context.getWord();
        TextFragment moreToWrap = null;
        float indentation = context.getIndentation();
        float lineLength = context.getLineLength();
        boolean isWrappedLine = context.isWrappedLine();

        if (isWrappedLine && lineLength == indentation) {
            // start of line, replace leading blanks if
            TextFragment[] replaceLeadingBlanks = replaceLeadingBlanks(word);
            word = replaceLeadingBlanks[0];
            if (replaceLeadingBlanks.length > 1) {
                result.add(replaceLeadingBlanks[1]);
            }
        }

        FontDescriptor fontDescriptor = word.getFontDescriptor();
        float length = word.getWidth();

        if (maxWidth > 0 && lineLength + length > maxWidth) {
            // word exceeds max width, so create new line

            // break hard, if the text does not fit in a full (next) line
            boolean breakHard = indentation + length > maxWidth;

            Pair<TextFragment> brokenWord = breakWord(word, length, maxWidth
                    - lineLength, maxWidth - indentation, breakHard);
            if (brokenWord != null) {
                // word is broken
                word = brokenWord.getFirst();
                length = word.getWidth();
                moreToWrap = brokenWord.getSecond();

                result.add(word);
                if (length > 0) {
                    lineLength += length;
                }

            } else {
                if (lineLength == indentation) {
                    // Begin of line and word could now be broke...
                    // Well, so we have to use it as it is,
                    // it won't get any better in the next line
                    result.add(word);
                    if (length > 0) {
                        lineLength += length;
                    }

                } else {
                    // give it another try in a new line, there
                    // will be more space.
                    moreToWrap = word;
                    if (result.getLast() != null) {
                        // since the current word is not used, take
                        // font descriptor of last line. Otherwise
                        // the line break might be to high
                        fontDescriptor = result.getLast().getFontDescriptor();
                    }
                }
            }

            // wrap line only if not empty
            if (lineLength > indentation) {
                // and terminate it with a new line
                result.add(new WrappingNewLine(fontDescriptor));
                isWrappedLine = true;
                if (indentation > 0) {
                    result.add(new Indent(indentation).toStyledText());
                }
                lineLength = indentation;
            }

        } else {
            // word fits, so just add it
            result.add(word);
            if (length > 0) {
                lineLength += length;
            }
        }

        return new WordWrapContext(moreToWrap, lineLength, indentation,
                isWrappedLine);
    }

    /**
     * Replaces leading whitespace by {@link ReplacedWhitespace}.
     *
     * @param word
     *            the fragment to replace
     * @return
     */
    private static TextFragment[] replaceLeadingBlanks(final TextFragment word) {
        String text = word.getText();
        int splitIndex = 0;
        while (splitIndex < text.length()
                && Character.isWhitespace(text.charAt(splitIndex))) {
            ++splitIndex;
        }

        if (splitIndex == 0) {
            return new TextFragment[] { word };
        } else {
            ReplacedWhitespace whitespace = new ReplacedWhitespace(
                    text.substring(0, splitIndex), word.getFontDescriptor());
            StyledText newWord = null;
            if (word instanceof StyledText) {
                newWord = ((StyledText) word).inheritAttributes(text
                        .substring(splitIndex));
            } else {
                newWord = new StyledText(text.substring(splitIndex),
                        word.getFontDescriptor(), word.getColor());
            }
            return new TextFragment[] { newWord, whitespace };
        }
    }

    /**
     * De-wraps the given text, means any new lines introduced by wrapping will
     * be removed. Also all whitespace removed by wrapping are re-introduced.
     *
     * @param text
     *            the text to de-wrap.
     * @return the de-wrapped text.
     * @throws Exception
     *             by PDFBox
     */
    public static TextFlow deWrap(final TextSequence text) throws Exception {
        TextFlow result = new TextFlow();
        for (TextFragment fragment : text) {
            if (fragment instanceof WrappingNewLine) {
                // skip
            } else if (fragment instanceof ReplacedWhitespace) {
                result.add(((ReplacedWhitespace) fragment).toReplacedFragment());
            } else {
                result.add(fragment);
            }
        }

        if (text instanceof TextFlow) {
            result.setLineSpacing(((TextFlow) text).getLineSpacing());
        }
        return result;
    }

    /**
     * Convencience function that {@link #wordWrap(TextSequence, float)
     * word-wraps} into {@link TextSequence#getLines()}.
     *
     * @param text
     *            the text to word-wrap.
     * @param maxWidth
     *            the max width to fit.
     * @return the word-wrapped text lines.
     * @throws Exception
     *             by pdfbox
     */
    public static List<TextLine> wordWrapToLines(final TextSequence text,
            final float maxWidth) throws Exception {
        TextFlow wrapped = wordWrap(text, maxWidth);
        List<TextLine> lines = wrapped.getLines();
        return lines;
    }

    /**
     * Splits the fragment into words.
     *
     * @param text
     *            the text to split.
     * @return the words as a text flow.
     */
    public static TextFlow splitWords(final TextFragment text) {
        TextFlow result = new TextFlow();
        if (text instanceof NewLine) {
            result.add(text);
        } else {
            float leftMargin = 0;
            float rightMargin = 0;
            if (text instanceof StyledText && ((StyledText) text).hasMargin()) {
                leftMargin = ((StyledText) text).getLeftMargin();
                rightMargin = ((StyledText) text).getRightMargin();
            }

            String[] words = text.getText().split(" ", -1);
            for (int index = 0; index < words.length; ++index) {
                String newWord = index == 0 ? words[index] : " " + words[index];

                float currentLeftMargin = 0;
                float currentRightMargin = 0;
                if (index == 0) {
                    currentLeftMargin = leftMargin;
                }
                if (index == words.length - 1) {
                    currentRightMargin = rightMargin;
                }
                TextFragment derived = deriveFromExisting(text, newWord,
                        currentLeftMargin, currentRightMargin);
                result.add(derived);
            }
        }
        return result;
    }

    /**
     * Derive a new TextFragment from an existing one, means use attributes like
     * font, color etc.
     *
     * @param toDeriveFrom
     *            the fragment to derive from.
     * @param text
     *            the new text.
     * @param leftMargin
     *            the new left margin.
     * @param rightMargin
     *            the new right margin.
     * @return the derived text fragment.
     */
    protected static TextFragment deriveFromExisting(
            final TextFragment toDeriveFrom, final String text,
            final float leftMargin, final float rightMargin) {
        if (toDeriveFrom instanceof StyledText) {
            return ((StyledText) toDeriveFrom).inheritAttributes(text,
                    leftMargin, rightMargin);
        }
        return new StyledText(text, toDeriveFrom.getFontDescriptor(),
                toDeriveFrom.getColor(), 0, leftMargin, rightMargin);
    }

    private static Pair<TextFragment> breakWord(TextFragment word,
            float wordWidth, final float remainingLineWidth, float maxWidth,
            boolean breakHard) throws Exception {

        float leftMargin = 0;
        float rightMargin = 0;
        if (word instanceof StyledText) {
            StyledText styledText = (StyledText) word;
            leftMargin = styledText.getLeftMargin();
            rightMargin = styledText.getRightMargin();
        }

        Pair<String> brokenWord = WordBreakerFactory.getWorkBreaker()
                .breakWord(word.getText(), word.getFontDescriptor(),
                        remainingLineWidth - leftMargin, breakHard);
        if (brokenWord == null) {
            return null;
        }

        // break at calculated index
        TextFragment head = deriveFromExisting(word,
                brokenWord.getFirst(), leftMargin, 0);
        TextFragment tail = deriveFromExisting(word,
                brokenWord.getSecond(), 0, rightMargin);

        return new Pair<TextFragment>(head, tail);
    }

    /**
     * Returns the width of the character <code>M</code> in the given font.
     * @param fontDescriptor font and size.
     * @return the width of <code>M</code>.
     * @throws Exception by pdfbox
     */
    public static float getEmWidth(final FontDescriptor fontDescriptor)
            throws Exception {
        return getStringWidth("M", fontDescriptor);
    }

    /**
     * Returns the width of the given text in the given font.
     * @param text the text to measure.
     * @param fontDescriptor font and size.
     * @return the width of given text.
     * @throws Exception by pdfbox
     */
    public static float getStringWidth(final String text,
            final FontDescriptor fontDescriptor) throws Exception {
        return fontDescriptor.getSize()
                * fontDescriptor.getFont().getStringWidth(text) / 1000;
    }


    /**
     * Gets the (left) offset of the line with respect to the target width and
     * alignment.
     *
     * @param textLine
     *            the text
     * @param targetWidth
     *            the target width
     * @param alignment
     *            the alignment of the line.
     * @return the left offset.
     * @throws Exception
     *             by pdfbox
     */
    public static float getOffset(final TextSequence textLine,
            final float targetWidth, final Alignment alignment)
            throws Exception {
        switch (alignment) {
        case Right:
            return targetWidth - textLine.getWidth();
        case Center:
            return (targetWidth - textLine.getWidth()) / 2f;
        default:
            return 0;
        }
    }

    /**
     * Calculates the max width of all text lines.
     *
     * @param lines
     *            the lines for which to calculate the max width.
     * @return the max width of the lines.
     * @throws Exception
     *             by pdfbox.
     */
    public static float getMaxWidth(final Iterable<TextLine> lines)
            throws Exception {
        float max = 0;
        for (TextLine line : lines) {
            max = Math.max(max, line.getWidth());
        }
        return max;
    }

    /**
     * Calculates the width of the text
     *
     * @param textSequence
     *            the text.
     * @param maxWidth
     *            if &gt; 0, the text may be word-wrapped to match the width.
     * @return the width of the text.
     * @throws Exception
     *             by pdfbox.
     */
    public static float getWidth(final TextSequence textSequence,
            final float maxWidth) throws Exception {
        List<TextLine> lines = wordWrapToLines(textSequence, maxWidth);
        float max = 0;
        for (TextLine line : lines) {
            max = Math.max(max, line.getWidth());
        }
        return max;
    }

    /**
     * Calculates the height of the text
     *
     * @param textSequence
     *            the text.
     * @param maxWidth
     *            if &gt; 0, the text may be word-wrapped to match the width.
     * @param lineSpacing
     *            the line spacing factor.
     * @param applyLineSpacingToFirstLine
     *            indicates if the line spacing should be applied to the first
     *            line also. Makes sense in most cases to do so.
     * @return the height of the text.
     * @throws Exception
     *             by pdfbox
     */
    public static float getHeight(final TextSequence textSequence,
            final float maxWidth, final float lineSpacing,
            final boolean applyLineSpacingToFirstLine) throws Exception {
        List<TextLine> lines = wordWrapToLines(textSequence, maxWidth);
        float sum = 0;
        for (int i = 0; i < lines.size(); i++) {
            TextLine line = lines.get(i);
            float lineHeight = line.getHeight();
            if (i > 0 || applyLineSpacingToFirstLine) {
                lineHeight *= lineSpacing;
            }
            sum += lineHeight;
        }
        return sum;
    }

    private static class WordWrapContext {
        private TextFragment word;
        private float lineLength;
        private float indentation;
        boolean isWrappedLine;

        public WordWrapContext(TextFragment word, float lineLength,
                float indentation, boolean isWrappedLine) {
            this.word = word;
            this.lineLength = lineLength;
            this.indentation = indentation;
            this.isWrappedLine = isWrappedLine;
        }

        public TextFragment getWord() {
            return word;
        }

        public float getLineLength() {
            return lineLength;
        }

        public float getIndentation() {
            return indentation;
        }

        public boolean isWrappedLine() {
            return isWrappedLine;
        }

        public boolean isMoreToWrap() {
            return getWord() != null;
        }

    }
}
