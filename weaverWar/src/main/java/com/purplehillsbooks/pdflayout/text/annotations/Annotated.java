package com.purplehillsbooks.pdflayout.text.annotations;


/**
 * Marker interface for annotated objects.
 */
public interface Annotated extends Iterable<Annotation> {

    /**
     * Gets the annotations of a specific type.
     *
     * @param type
     *            the type of interest.
     * @return the annotations of that type, or an empty collection.
     * @param <T>
     *            the annotation type.
     */
    <T extends Annotation> Iterable<T> getAnnotationsOfType(Class<T> type);

}
