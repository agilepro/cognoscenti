package com.purplehillsbooks.weaver.schema;

import com.fasterxml.jackson.annotation.JsonAnySetter;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.purplehillsbooks.weaver.exception.WeaverException;

import java.math.BigDecimal;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.Period;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

public class JsonSchema {

    public static final String STRING_TYPE = "string";
    public static final String NUMBER_TYPE = "number";
    public static final String BOOLEAN_TYPE = "boolean";
    public static final String OBJECT_TYPE = "object";
    public static final String ARRAY_TYPE = "array";

    // the following types are actually stored in the $ref field
    public static final String TIMESTAMP_TYPE = "timestamp";
    public static final String DATE_TYPE = "date";
    public static final String TIME_TYPE = "time";
    public static final String DURATION_TYPE = "duration";
    public static final String PERIOD_TYPE = "period";

    // Set this flag to true in order to ALLOW the DMNs declared with
    // list of lists problem to accept data without the extra level of lists
    public static boolean SKIP_EXTRA_LEVEL_OF_LISTS = false;
    // either a type (string, number, boolean, object) or a $ref (user defined type)
    public String type;

    @JsonProperty("$ref")
    public String ref;

    public String description;

    @JsonProperty("enum")
    public List<Object> enumList;

    public List<JsonRange> anyOf;

    // used if type is 'array'
    public JsonSchema items;

    // used only if type is 'object'
    public JsonSchemaMap properties;
    public List<String> required;

    public static final Set<String> primitiveType =
            new HashSet<>(
                    Arrays.asList(STRING_TYPE, NUMBER_TYPE, BOOLEAN_TYPE, OBJECT_TYPE, ARRAY_TYPE));

    /*
     * We are using a list of JsonRange objects in an anyOf list,
     * overwriting what might have been there before.  You should never use
     * both the range list and the directly specified values at the same time.
     * */
    @JsonAnySetter
    public void getOtherAttributes(String key, Object value) {
        // code to handle
        if ("maximum".equals(key)) {
            JsonRange range = getFirstRange();
            range.maximum = FeelUtil.getDecimal(value);
        } else if ("minimum".equals(key)) {
            JsonRange range = getFirstRange();
            range.minimum = FeelUtil.getDecimal(value);
        } else if ("exclusiveMaximum".equals(key)) {
            JsonRange range = getFirstRange();
            range.exclusiveMaximum = FeelUtil.getDecimal(value);
        } else if ("exclusiveMinimum".equals(key)) {
            JsonRange range = getFirstRange();
            range.exclusiveMinimum = FeelUtil.getDecimal(value);
        }
    }

    public static JsonSchema createObjectSchema() {
        JsonSchema ret = new JsonSchema();
        ret.type = OBJECT_TYPE;
        ret.properties = new JsonSchemaMap();
        return ret;
    }

    public static JsonSchema createArraySchema() {
        JsonSchema ret = new JsonSchema();
        ret.type = ARRAY_TYPE;
        ret.items = null;
        return ret;
    }

    public boolean isType(String testType) {
        return testType.equals(type);
    }

    public JsonSchema getChild(String key) {
        if (properties != null) {
            return properties.get(key);
        }
        if (items != null) {
            // note is this is a list, then the key migth be any number
            // so just allow anything as the index.
            return items;
        }
        return null;
    }

    public void makeChild(String key, JsonSchema child) {
        if (isType(JsonSchema.OBJECT_TYPE)) {
            properties.put(key, child);
        } else if (isType(JsonSchema.ARRAY_TYPE)) {
            items = child;
        } else {
            throw WeaverException.newBasic(
                    "Attempt to make a child (%s) on a leaf type (%s)", key, type);
        }
    }

    private JsonRange getFirstRange() {
        if (anyOf == null) {
            anyOf = new ArrayList<>();
        }
        if (anyOf.isEmpty()) {
            anyOf.add(new JsonRange());
        }
        return anyOf.get(0);
    }

    public JsonSchema cloneDef() {
        JsonSchema newDef = new JsonSchema();
        newDef.type = type;
        newDef.ref = ref;
        newDef.description = description;
        newDef.enumList = enumList;
        if (items != null) {
            newDef.items = items.cloneDef();
        }
        if (required != null) {
            newDef.required = new ArrayList<>();
            newDef.required.addAll(required);
        }
        if (anyOf != null) {
            newDef.anyOf = new ArrayList<>();
            newDef.anyOf.addAll(anyOf);
        }
        if (properties != null) {
            newDef.properties = new JsonSchemaMap();
            for (Map.Entry<String, JsonSchema> entry : properties.entrySet()) {
                newDef.properties.put(entry.getKey(), entry.getValue().cloneDef());
            }
        }
        return newDef;
    }

    public void addProperty(String name, JsonSchema prop) {
        if (properties == null) {
            properties = new JsonSchemaMap();
        }
        properties.put(name, prop);
    }

    /**
     * Sets a property on an object-style schema elements, without making that property a required
     * property. Initializes structures as needed.
     */
    public JsonSchema getProperty(String name) {
        if (properties == null) {
            return null;
        }
        return properties.get(name);
    }

    public void makePropertyRequired(String name) {
        if (required == null) {
            required = new ArrayList<>();
        }
        if (!required.contains(name)) {
            required.add(name);
        }
        Collections.sort(required);
    }

    public void makePropertyOptional(String name) {
        if (required == null) {
            // nothing is required so we are done.
            return;
        }
        if (required.contains(name)) {
            required.remove(name);
        }
        if (required.isEmpty()) {
            required = null;
        }
    }

    public boolean requiredProperty(String key) {
        if (required == null || properties == null) {
            return false;
        }
        return required.contains(key);
    }

    /**
     * the JsonSchema will EITHER have a type, or it will have a ref. This looks at the list of
     * standard types, and sets the type when it is appropriate, and sets the ref when not.
     */
    public void setTypeOrRef(String typeRef) {
        if (primitiveType.contains(typeRef)) {
            type = typeRef;
            ref = null;
        } else {
            ref = typeRef;
            type = null;
        }
    }

    /**
     * If the type is string, and there is a set of enum variables, then we need to treat the enum
     * values as strings. This accepts a string and compares to the set values as strings.
     *
     * @param value
     * @return
     */
    public boolean inStringSet(String value) {
        if (enumList == null || enumList.isEmpty()) {
            return true;
        }
        for (Object setVal : enumList) {
            if (value.equals(setVal)) {
                return true;
            }
        }
        return false;
    }

    /**
     * If the type is number, and there is a set of enum variables, then we need to treat the enum
     * values as numbers. This accepts a number (BigDecimal) and compares to the set values as
     * strings.
     */
    public boolean inNumberSet(BigDecimal value) {
        if (enumList == null || enumList.isEmpty()) {
            return true;
        }
        for (Object setVal : enumList) {
            if (value.equals(FeelUtil.getDecimal(setVal))) {
                return true;
            }
        }
        return false;
    }

    /**
     * there can be a set of valid ranges on the type, and this walks through the list of ranges and
     * returns true if the BigDecimal value is in any one of the ranges.
     */
    public boolean inRanges(BigDecimal bigValue) {
        if (anyOf == null || anyOf.isEmpty()) {
            // if there are no ranges, then any value is fine
            return true;
        }
        for (JsonRange oneRange : anyOf) {
            if (oneRange.isInRange(bigValue)) {
                return true;
            }
        }
        return false;
    }

    public static String getTypeFromObject(Object value) {
        if (value == null) {
            throw WeaverException.newBasic("getTypeFrom requires a non-null parameter");
        } else if ((value instanceof String)) {
            return STRING_TYPE;
        } else if (FeelUtil.isNumericType(value)) {
            return NUMBER_TYPE;
        } else if (value instanceof Boolean) {
            return BOOLEAN_TYPE;
        } else if (value instanceof Map) {
            return OBJECT_TYPE;
        } else if (value instanceof List) {
            return ARRAY_TYPE;
        } else if (value instanceof Duration) {
            // can only occur if DMN author uses a days and time duration in DMN
            return NUMBER_TYPE;
        } else if (value instanceof LocalTime) {
            // can only occur if DMN author uses a time() function in DMN
            return NUMBER_TYPE;
        } else if (value instanceof Period) {
            // can only occur if DMN author uses a years and months duration() function in DMN
            return STRING_TYPE;
        } else if (value instanceof LocalDate) {
            // can only occur if DMN author uses a date() function in DMN
            return NUMBER_TYPE;
        } else if (value instanceof LocalDateTime) {
            // can only occur if DMN author uses a date and time() function in DMN
            return NUMBER_TYPE;
        }
        throw WeaverException.newBasic(
                "Object has no corresponding schema type: (%s)", value.getClass().getName());
    }

    /**
     * takes a Java object holding a value, this method will check if the value in the Object is the
     * right type and valid, returnign a boolean value that reflects that.
     */
    public boolean objectIsValid(Object value) {
        if (value == null) {
            // a null is valid for any data type.  We can't say here whether this field
            // is required or not, but return true about data type.
            // However, the field can not have any valid ranges or enums
            if (enumList != null && !enumList.isEmpty()) {
                return false;
            }
            if (anyOf != null && !anyOf.isEmpty()) {
                return false;
            }
            return true;
        } else if (STRING_TYPE.equals(type)) {
            if (!(value instanceof String)) {
                return false;
            }
            String strValue = (String) value;
            return inStringSet(strValue);
        } else if (NUMBER_TYPE.equals(type)) {
            if (!(FeelUtil.isNumericType(value))) {
                return false;
            }
            BigDecimal bigValue = FeelUtil.getDecimal(value);
            if (!inNumberSet(bigValue)) {
                return false;
            }
            return inRanges(bigValue);
        } else if (BOOLEAN_TYPE.equals(type)) {
            return (value instanceof Boolean);
        } else if (OBJECT_TYPE.equals(type)) {
            return (value instanceof Map);
        } else if (ARRAY_TYPE.equals(type)) {
            return (value instanceof List);
        }
        if (ref != null) {
            throw WeaverException.newBasic(
                    "Can not validate value, schema element must be dereferenced: %s", ref);
        }
        throw WeaverException.newBasic("Can not validate value, unknown type: %s", type);
    }

    /**
     * Takes an object representing a value and tells you whether it is valid according to the
     * schema or not. If not, it throws a standard well formed message to explain why it was found
     * to be invalid.
     *
     * @param value is checked to see if valid, exception otherwise
     * @param path is used only when there is an exception to clarify which data item caused the
     *     exception
     */
    public void assertObjectValid(Object value, String path, JsonSchemaMap schemaMap) {

        // these lines are REQUIRED by sonar S2259 for no good reason at all, causing code
        // bloat and making the code more cumbersome.  I am adding them here to make sonar happy.
        if (schemaMap == null) {
            throw WeaverException.newBasic("SchemaMap is required for assertObjectValid");
        }
        // First we need to handle the null case.  Any data type can be null as long as the
        // value is not marked in the schema as being required.
        if (value == null) {
            // in JSON Schema we can not assure that a null is valid or not.   It is valid
            // from an object type perspective, but whether it is required depends on the parent
            if (enumList != null && !enumList.isEmpty()) {
                throw WeaverException.newBasic(
                        "Missing value is not in allowed set of values (%s)", path);
            }
            if (anyOf != null && anyOf.isEmpty()) {
                throw WeaverException.newBasic("Missing value is not in allowed ranges (%s)", path);
            }
            return;
        }
        if (STRING_TYPE.equals(type)) {
            if (!(value instanceof String)) {
                throw WeaverException.newBasic("Non-string value found at (%s)", path);
            }
            String strValue = (String) value;
            if (!inStringSet(strValue)) {
                if (strValue.length() > 20) {
                    strValue = strValue.substring(0, 20) + "...";
                }
                throw WeaverException.newBasic(
                        "String value (%s) is not in allowed set of values (%s)", strValue, path);
            }
        } else if (NUMBER_TYPE.equals(type)) {
            if (!(FeelUtil.isNumericType(value))) {
                throw WeaverException.newBasic("Non-numeric value found at (%s)", path);
            }
            BigDecimal bigValue = FeelUtil.getDecimal(value);
            if (!inNumberSet(bigValue)) {
                throw WeaverException.newBasic(
                        "Numeric value (%s) is not in allowed set of values (%s)",
                        bigValue.toString(), path);
            }
            if (!inRanges(bigValue)) {
                throw WeaverException.newBasic(
                        "Numeric value (%s) is not within allowed ranges (%s)",
                        bigValue.toString(), path);
            }
        } else if (BOOLEAN_TYPE.equals(type)) {
            if (!(value instanceof Boolean)) {
                throw WeaverException.newBasic("Non-boolean value found at (%s)", path);
            }
        } else if (OBJECT_TYPE.equals(type)) {
            if (!(value instanceof Map)) {
                throw WeaverException.newBasic("Non-object value found at (%s)", path);
            }
        } else if (ARRAY_TYPE.equals(type)) {
            if (!(value instanceof List)) {

                throw WeaverException.newBasic("Non-array value found at (%s)", path);
            }
        } else {
            if (ref != null) {
                throw WeaverException.newBasic(
                        "Can not validate value, schema element must be dereferenced: %s", ref);
            }
            throw WeaverException.newBasic("Can not validate value, unknown type: %s", type);
        }
    }

    public void assertObjectValid(
            Object value, String path, Object object, JsonSchemaMap jsonSchemaMap) {
        // TODO Auto-generated method stub
        throw new UnsupportedOperationException("Unimplemented method 'assertObjectValid'");
    }
}
