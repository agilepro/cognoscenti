package com.purplehillsbooks.weaver.schema;

import com.purplehillsbooks.weaver.exception.WeaverException;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;

@SuppressWarnings("unchecked")
public class JsonSchemaMap extends HashMap<String, JsonSchema> {

    private static final HashSet<String> PRIMITIVE_TYPES =
            new HashSet<>(
                    Arrays.asList(
                            JsonSchema.STRING_TYPE,
                            JsonSchema.NUMBER_TYPE,
                            JsonSchema.BOOLEAN_TYPE,
                            JsonSchema.DATE_TYPE,
                            JsonSchema.TIME_TYPE,
                            JsonSchema.TIMESTAMP_TYPE,
                            JsonSchema.PERIOD_TYPE,
                            JsonSchema.DURATION_TYPE));

    public void assertValidSchema() {
        for (Map.Entry<String, JsonSchema> entry : this.entrySet()) {
            assertTypeIsValid(entry.getKey(), entry.getValue());
        }
    }

    /**
     * @param path Path is included here just as a name of the schema item in order to explain in
     *     the exception message what it is that failed.
     * @param oneType the element being tested
     */
    public void assertTypeIsValid(String path, JsonSchema oneType) {
        String typeName = oneType.type;
        if (typeName == null) {
            // this has to be a referred type name
            assertReferredTypeValid(path, oneType);
        } else if (JsonSchema.OBJECT_TYPE.equals(typeName)) {
            // might want to test if the object has any properties and report error
            // because what good in an object without properties?
            if (oneType.properties != null) {
                for (Map.Entry<String, JsonSchema> entry : oneType.properties.entrySet()) {
                    assertTypeIsValid(path + "." + entry.getKey(), entry.getValue());
                }
            }
        } else if (JsonSchema.ARRAY_TYPE.equals(typeName)) {
            WeaverException.failWhen(
                    oneType.items == null,
                    "definition (%s) declared as an array but does not have any items definition",
                    path);
            assertTypeIsValid(path + ".#", oneType.items);
        } else if (PRIMITIVE_TYPES.contains(typeName)) {
            // this is a primitive type (string, boolean, etc) so there are no problems
        } else {
            throw WeaverException.newBasic(
                    "definition (%s) contains an unrecognized type name: %s", path, typeName);
        }
    }

    // had to break this out into a separate method to reduce complexity of the
    // above method for Sonar analysis
    private void assertReferredTypeValid(String path, JsonSchema oneType) {
        String referredType = oneType.ref;
        WeaverException.failWhen(
                referredType == null,
                "definition (%s) has neither a type setting nor a $ref setting",
                path);
        WeaverException.failWhen(
                !this.containsKey(referredType),
                "definition (%s) refers to a type (%s) which is not found in the schema",
                path,
                referredType);
    }

    public JsonSchema dereferenceIfNeeded(JsonSchema schema) {
        if (schema == null) {
            return null;
        }
        String refName = schema.ref;
        while (refName != null) {
            schema = this.get(refName);
            WeaverException.failWhen(
                    schema == null,
                    "Schema element contains a reference (%s) but that type does not exist",
                    refName);
            refName = schema.ref;
        }
        return schema;
    }

    public List<String> findAllPaths(JsonSchema schemaElem) {
        List<String> res = new ArrayList<>();
        schemaElem = dereferenceIfNeeded(schemaElem);
        if (JsonSchema.OBJECT_TYPE.equals(schemaElem.type)) {
            for (Map.Entry<String, JsonSchema> entry : schemaElem.properties.entrySet()) {
                findAllPathsInt(entry.getValue(), entry.getKey(), res, 15);
            }
        } else if (JsonSchema.ARRAY_TYPE.equals(schemaElem.type)) {
            findAllPathsInt(schemaElem.items, "#", res, 15);
        }
        return res;
    }

    private void findAllPathsInt(JsonSchema schemaElem, String path, List<String> res, int limit) {
        try {
            WeaverException.failWhen(limit < 0, "too many levels of recursion");
            schemaElem = dereferenceIfNeeded(schemaElem);
            if (JsonSchema.OBJECT_TYPE.equals(schemaElem.type)) {
                for (Map.Entry<String, JsonSchema> entry : schemaElem.properties.entrySet()) {
                    findAllPathsInt(entry.getValue(), path + "." + entry.getKey(), res, limit - 1);
                }
            } else if (JsonSchema.ARRAY_TYPE.equals(schemaElem.type)) {
                findAllPathsInt(schemaElem.items, path + ".#", res, limit - 1);
            } else {
                res.add(path);
            }
        } catch (Exception e) {
            throw WeaverException.newWrap("Failure searching schema path (%s)", e, path);
        }
    }

    public JsonSchema getPathSchema(JsonSchema start, String path) {
        try {
            start = dereferenceIfNeeded(start);
            int dotPos = path.indexOf(".");
            if (dotPos < 0) {
                return start.getChild(path);
            }

            String firstPart = path.substring(0, dotPos);
            String lastPart = path.substring(dotPos + 1);
            JsonSchema child = start.getChild(firstPart);
            if (child != null) {
                return getPathSchema(child, lastPart);
            }
            return null;
        } catch (Exception e) {
            throw WeaverException.newWrap("Failure getting (%s) from a Schema", e, path);
        }
    }

    public boolean getPathRequired(JsonSchema start, String path) {
        try {
            start = dereferenceIfNeeded(start);
            int dotPos = path.indexOf(".");
            if (dotPos < 0) {
                return start.requiredProperty(path);
            } else {
                String firstPart = path.substring(0, dotPos);
                String lastPart = path.substring(dotPos + 1);
                if (JsonSchema.OBJECT_TYPE.equals(start.type)) {
                    if (!start.requiredProperty(firstPart)) {
                        return false;
                    }
                    JsonSchema child = start.getProperty(firstPart);
                    return getPathRequired(child, lastPart);
                } else if (JsonSchema.ARRAY_TYPE.equals(start.type)) {
                    return getPathRequired(start.items, lastPart);
                } else {
                    // undefined or invalid path, return not required
                    // maybe should thrown an exception here?
                    return false;
                }
            }
        } catch (Exception e) {
            throw WeaverException.newWrap("Failure getting (%s) from a Schema", e, path);
        }
    }

    public void setPathSchema(JsonSchema start, String path, JsonSchema element) {
        try {
            start = dereferenceIfNeeded(start);
            int dotPos = path.indexOf(".");

            // if there is no dot, then we are at the end of the path, and the new
            // element should be a child of the start element
            if (dotPos < 0) {
                start.makeChild(path, element);
                return;
            }

            // divide the path into the token for the current child
            // and the rest of the path that child will need
            String firstPart = path.substring(0, dotPos);
            String lastPart = path.substring(dotPos + 1);
            JsonSchema child = start.getChild(firstPart);
            // if the child does not exist, create it properly, either an array element
            // or an object element depending on the next part of the path
            if (child == null) {
                if (lastPart.startsWith("#")) {
                    child = JsonSchema.createArraySchema();
                } else {
                    child = JsonSchema.createObjectSchema();
                }
                start.makeChild(firstPart, child);
            }
            setPathSchema(child, lastPart, element);
        } catch (Exception e) {
            throw WeaverException.newWrap("Failure constructing schema element at (%s)", e, path);
        }
    }

    public void setPathRequired(JsonSchema start, String path, boolean required) {
        try {
            start = dereferenceIfNeeded(start);
            int dotPos = path.indexOf(".");
            if (dotPos < 0) {
                if (required) {
                    start.makePropertyRequired(path);
                } else {
                    start.makePropertyOptional(path);
                }
                return;
            }
            String firstPart = path.substring(0, dotPos);
            String lastPart = path.substring(dotPos + 1);
            JsonSchema child = start.getChild(firstPart);
            WeaverException.failWhen(
                    child == null,
                    "The path to a schema has to exist before it can be set required (%s)",
                    path);
            setPathRequired(child, lastPart, required);
        } catch (Exception e) {
            throw WeaverException.newWrap("Failure setting path (%s)", e, path);
        }
    }

    public boolean objectIsValid(JsonSchema schema, Object value) {
        schema = dereferenceIfNeeded(schema);
        return schema.objectIsValid(value);
    }

    public void assertValidData(JsonSchema schema, Object value, String path) {
        schema = dereferenceIfNeeded(schema);
        schema.assertObjectValid(value, path, null, this);
        if (value instanceof List) {
            List<Object> objectList = (List<Object>) value;
            for (int i = 0; i < objectList.size(); i++) {
                assertValidData(schema.items, objectList.get(i), path + "." + i);
            }
        } else if (value instanceof Map) {
            Map<String, Object> objectMap = (Map<String, Object>) value;
            // we only check the property values that are defined by the schema
            for (Map.Entry<String, JsonSchema> entry : schema.properties.entrySet()) {
                String key = entry.getKey();
                JsonSchema childType = entry.getValue();
                Object childValue = objectMap.get(key);
                if (childValue == null) {
                    WeaverException.failWhen(
                            schema.requiredProperty(key),
                            "Required property (%s) is missing from map (%s)",
                            key,
                            path);
                } else {
                    assertValidData(childType, childValue, path + "." + key);
                }
            }
        }
    }
}
