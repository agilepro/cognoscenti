package com.purplehillsbooks.pdflayout.text.annotations;

import java.util.List;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import com.purplehillsbooks.pdflayout.text.ControlCharacter;
import com.purplehillsbooks.pdflayout.text.ControlCharacters.ControlCharacterFactory;
import com.purplehillsbooks.pdflayout.text.annotations.Annotations.AnchorAnnotation;
import com.purplehillsbooks.pdflayout.text.annotations.Annotations.HyperlinkAnnotation;
import com.purplehillsbooks.pdflayout.text.annotations.Annotations.HyperlinkAnnotation.LinkStyle;
import com.purplehillsbooks.pdflayout.text.annotations.Annotations.UnderlineAnnotation;

/**
 * Container for annotation control characters.
 */
public class AnnotationCharacters {

    private final static List<AnnotationControlCharacterFactory<?>> FACTORIES = new CopyOnWriteArrayList<AnnotationControlCharacterFactory<?>>();

    static {
        register(new HyperlinkControlCharacterFactory());
        register(new AnchorControlCharacterFactory());
        register(new UnderlineControlCharacterFactory());
    }

    /**
     * Use this method to register your (custom) annotation control character
     * factory.
     *
     * @param factory
     *            the factory to register.
     */
    public static void register(
            final AnnotationControlCharacterFactory<?> factory) {
        FACTORIES.add(factory);
    }

    /**
     * @return all the default and custom annotation control character
     *         factories.
     */
    public static Iterable<AnnotationControlCharacterFactory<?>> getFactories() {
        return FACTORIES;
    }

    private static class HyperlinkControlCharacterFactory implements
            AnnotationControlCharacterFactory<HyperlinkControlCharacter> {

        private final static Pattern PATTERN = Pattern
                .compile("(?<!\\\\)(\\\\\\\\)*\\{link(:(ul|none))?(\\[(([^}]+))\\])?\\}");

        private final static String TO_ESCAPE = "{";

        @Override
        public HyperlinkControlCharacter createControlCharacter(String text,
                Matcher matcher, final List<CharSequence> charactersSoFar) {
            return new HyperlinkControlCharacter(matcher.group(5),
                    matcher.group(3));
        }

        @Override
        public Pattern getPattern() {
            return PATTERN;
        }

        @Override
        public String unescape(String text) {
            return text
                    .replaceAll("\\\\" + Pattern.quote(TO_ESCAPE), TO_ESCAPE);
        }

        @Override
        public boolean patternMatchesBeginOfLine() {
            return false;
        }

    }

    private static class AnchorControlCharacterFactory implements
            AnnotationControlCharacterFactory<AnchorControlCharacter> {

        private final static Pattern PATTERN = Pattern
                .compile("(?<!\\\\)(\\\\\\\\)*\\{anchor(:((\\w+)))?\\}");

        private final static String TO_ESCAPE = "{";

        @Override
        public AnchorControlCharacter createControlCharacter(String text,
                Matcher matcher, final List<CharSequence> charactersSoFar) {
            return new AnchorControlCharacter(matcher.group(3));
        }

        @Override
        public Pattern getPattern() {
            return PATTERN;
        }

        @Override
        public String unescape(String text) {
            return text
                    .replaceAll("\\\\" + Pattern.quote(TO_ESCAPE), TO_ESCAPE);
        }

        @Override
        public boolean patternMatchesBeginOfLine() {
            return false;
        }

    }

    private static class UnderlineControlCharacterFactory implements
            AnnotationControlCharacterFactory<UnderlineControlCharacter> {

        private static Pattern PATTERN = Pattern
                .compile("(?<!\\\\)(\\\\\\\\)*(__(\\{(-?\\d+(\\.\\d*)?)?\\:(-?\\d+(\\.\\d*)?)?\\})?)");

        private final static String TO_ESCAPE = "__";

        @Override
        public UnderlineControlCharacter createControlCharacter(String text,
                Matcher matcher, final List<CharSequence> charactersSoFar) {
            return new UnderlineControlCharacter(matcher.group(4),
                    matcher.group(6));
        }

        @Override
        public Pattern getPattern() {
            return PATTERN;
        }

        @Override
        public String unescape(String text) {
            return text
                    .replaceAll("\\\\" + Pattern.quote(TO_ESCAPE), TO_ESCAPE);
        }

        @Override
        public boolean patternMatchesBeginOfLine() {
            return false;
        }

    }

    /**
     * A <code>{link:#title1}</code> indicates an internal link to the
     * {@link AnchorControlCharacter anchor} <code>title1</code>. Any other link
     * (not starting with <code>#</code> will be treated as an external link. It
     * can be escaped with a backslash ('\').
     */
    public static class HyperlinkControlCharacter extends
            AnnotationControlCharacter<HyperlinkAnnotation> {
        private HyperlinkAnnotation hyperlink;

        protected HyperlinkControlCharacter(final String hyperlink,
                final String linkStyle) {
            super("HYPERLINK", HyperlinkControlCharacterFactory.TO_ESCAPE);
            if (hyperlink != null) {
                LinkStyle style = LinkStyle.ul;
                if (linkStyle != null) {
                    style = LinkStyle.valueOf(linkStyle);
                }
                this.hyperlink = new HyperlinkAnnotation(hyperlink, style);
            }
        }

        @Override
        public HyperlinkAnnotation getAnnotation() {
            return hyperlink;
        }

        @Override
        public Class<HyperlinkAnnotation> getAnnotationType() {
            return HyperlinkAnnotation.class;
        }
    }

    /**
     * An <code>{color:#ee22aa}</code> indicates switching the color in markup,
     * where the color is given as hex RGB code (ee22aa in this case). It can be
     * escaped with a backslash ('\').
     */
    public static class AnchorControlCharacter extends
            AnnotationControlCharacter<AnchorAnnotation> {
        private AnchorAnnotation anchor;

        protected AnchorControlCharacter(final String anchor) {
            super("ANCHOR", AnchorControlCharacterFactory.TO_ESCAPE);
            if (anchor != null) {
                this.anchor = new AnchorAnnotation(anchor);
            }
        }

        @Override
        public AnchorAnnotation getAnnotation() {
            return anchor;
        }

        @Override
        public Class<AnchorAnnotation> getAnnotationType() {
            return AnchorAnnotation.class;
        }

    }

    /**
     * Control character for underline. It can be escaped with a backslash
     * ('\').
     */
    public static class UnderlineControlCharacter extends
            AnnotationControlCharacter<UnderlineAnnotation> {

        /**
         * constant for the system property
         * <code>pdfbox.layout.underline.baseline.offset.scale.default</code>.
         */
        public final static String UNDERLINE_DEFAULT_BASELINE_OFFSET_SCALE_PROPERTY = "pdfbox.layout.underline.baseline.offset.scale.default";

        private static Float defaultBaselineOffsetScale;
        private UnderlineAnnotation line;

        protected UnderlineControlCharacter() {
            this(null, null);
        }

        protected UnderlineControlCharacter(String baselineOffsetScaleValue,
                String lineWeightValue) {
            super("UNDERLINE", UnderlineControlCharacterFactory.TO_ESCAPE);

            float baselineOffsetScale = parseFloat(baselineOffsetScaleValue,
                    getdefaultBaselineOffsetScale());
            float lineWeight = parseFloat(lineWeightValue, 1f);
            line = new UnderlineAnnotation(baselineOffsetScale, lineWeight);
        }

        @Override
        public UnderlineAnnotation getAnnotation() {
            return line;
        }

        @Override
        public Class<UnderlineAnnotation> getAnnotationType() {
            return UnderlineAnnotation.class;
        }

        private static float parseFloat(String text, float defaultValue) {
            if (text == null) {
                return defaultValue;
            }
            try {
                return Float.parseFloat(text);
            } catch (NumberFormatException e) {
                return defaultValue;
            }
        }

        private static float getdefaultBaselineOffsetScale() {
            if (defaultBaselineOffsetScale == null) {
                defaultBaselineOffsetScale = Float
                        .parseFloat(System
                                .getProperty(
                                        UNDERLINE_DEFAULT_BASELINE_OFFSET_SCALE_PROPERTY,
                                        "-0.1"));
            }
            return defaultBaselineOffsetScale;
        }

    }

    /**
     * Specialized interface for control character factories for annotations.
     *
     * @param <T>
     *            the type of the annotation control character.
     */
    public static interface AnnotationControlCharacterFactory<T extends AnnotationControlCharacter<? extends Annotation>>
            extends ControlCharacterFactory {
        public T createControlCharacter(String text, Matcher matcher,
                final List<CharSequence> charactersSoFar);

    };

    /**
     * Common base class for annotation control characters.
     */
    public static abstract class AnnotationControlCharacter<T extends Annotation>
            extends ControlCharacter {

        protected AnnotationControlCharacter(final String description,
                final String charaterToEscape) {
            super(description, charaterToEscape);
        }

        /**
         * @return the associated annotation.
         */
        public abstract T getAnnotation();

        /**
         * @return the type of the annotation.
         */
        public abstract Class<T> getAnnotationType();

    }

    public static void main(String[] args) {
        Pattern PATTERN = Pattern
                .compile("(?<!\\\\)(\\\\\\\\)*(__(\\{(-?\\d+(\\.\\d*)?)?\\:(-?\\d+(\\.\\d*)?)?\\})?)");
        Matcher matcher = PATTERN.matcher("__");
        System.out.println("matches: " + matcher.find());
        if (!matcher.matches()) {
            System.err.println("exit");
            return;
        }
        System.out.println("start: " + matcher.start());
        System.out.println("end: " + matcher.end());
        System.out.println("groups: " + matcher.groupCount());
        for (int i = 0; i < matcher.groupCount(); i++) {
            System.out.println("group " + i + ": '" + matcher.group(i) + "'");
        }
        // 2 - -> 1: blanks, 4: size, 5: unit
        // 7 + -> 6: blanks, 9: sign, 10: size, 11: unit
        // 11 # -> 12: blanks, 15: number-sign, 16: size, 18: unit
    }

}
