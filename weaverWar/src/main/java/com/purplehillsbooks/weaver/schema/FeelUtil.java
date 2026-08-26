package com.purplehillsbooks.weaver.schema;

import com.purplehillsbooks.weaver.exception.WeaverException;
import java.math.BigDecimal;
import java.util.List;

/**
 * This class is a library of functions useful for parsing, creating, and manipulating objects which
 * are associated with JSON streams.
 */
public class FeelUtil {
    public static final String STRING_FEEL_TYPE = "string";
    public static final String NUMBER_FEEL_TYPE = "number";
    public static final String BOOLEAN_FEEL_TYPE = "boolean";

    // Sonar requires this line to be here for no benefit at all
    private FeelUtil() {}

    public static boolean isNumericType(Object value) {
        return (value instanceof Integer
                || value instanceof Long
                || value instanceof Double
                || value instanceof Float
                || value instanceof BigDecimal);
    }

    public static String feelTypeFromJavaObject(Object value) {
        if (value instanceof String) {
            return STRING_FEEL_TYPE;
        }
        if (FeelUtil.isNumericType(value)) {
            return NUMBER_FEEL_TYPE;
        }
        if (value instanceof Boolean) {
            return BOOLEAN_FEEL_TYPE;
        }
        if (value instanceof List) {
            return "any";
        }
        if (value == null) {
            // not really a valid type, but we need to return something for a null
            // and this would be useful if this method is used to create a displayable value.
            return "null";
        }
        throw WeaverException.newBasic(
                "Cannot recognize data type of %s", value.getClass().getName());
    }

    public static BigDecimal getDecimal(Object value) {
        if (value == null) {
            return null;
        }
        if (value instanceof BigDecimal) {
            return (BigDecimal) value;
        }
        if (value instanceof Integer) {
            return BigDecimal.valueOf((Integer) value);
        }
        if (value instanceof Long) {
            return BigDecimal.valueOf((Long) value);
        }
        if (value instanceof Double) {
            return BigDecimal.valueOf((Double) value);
        }
        if (value instanceof Float) {
            return BigDecimal.valueOf((Float) value);
        }
        if (value instanceof String strValue) {
            try {
                return new BigDecimal(strValue);
            } catch (NumberFormatException e) {
                throw WeaverException.newBasic("Cannot convert string to a number: %s", strValue);
            }
        }
        throw WeaverException.newBasic(
                "Cannot recognize data type of %s", value.getClass().getName());
    }
}
