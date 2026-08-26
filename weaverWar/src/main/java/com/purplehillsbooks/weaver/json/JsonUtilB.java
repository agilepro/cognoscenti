package com.purplehillsbooks.weaver.json;

import com.fasterxml.jackson.annotation.JsonAutoDetect;
import com.fasterxml.jackson.annotation.JsonInclude.Include;
import com.fasterxml.jackson.annotation.PropertyAccessor;
import com.fasterxml.jackson.core.Version;
import com.fasterxml.jackson.core.util.DefaultIndenter;
import com.fasterxml.jackson.core.util.DefaultPrettyPrinter;
import com.fasterxml.jackson.databind.MapperFeature;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.ObjectWriter;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.databind.json.JsonMapper;
import com.fasterxml.jackson.databind.module.SimpleModule;
import com.purplehillsbooks.weaver.exception.WeaverException;
import java.io.File;
import java.io.FileWriter;
import java.io.InputStream;
import java.io.StringWriter;
import java.io.Writer;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.Period;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

@SuppressWarnings("unchecked")
public class JsonUtilB {

    private static ObjectWriter prettyWriter;

    static {
        DefaultPrettyPrinter prettyPrinter = new DefaultPrettyPrinter();
        prettyPrinter.indentArraysWith(DefaultIndenter.SYSTEM_LINEFEED_INSTANCE);

        ObjectMapper objectMapper =
                JsonMapper.builder()
                        .configure(MapperFeature.SORT_PROPERTIES_ALPHABETICALLY, true)
                        .build();
        objectMapper.configure(SerializationFeature.ORDER_MAP_ENTRIES_BY_KEYS, true);
        objectMapper.setSerializationInclusion(Include.NON_NULL); // don't generate any null values
        // add specialized serializers
        SimpleModule module =
                new SimpleModule(
                        "CustomDurationSerializer", new Version(1, 0, 0, null, null, null));
        module.addSerializer(Duration.class, new DurationSerializer());
        module.addSerializer(LocalDateTime.class, new LocalDateTimeSerializer());
        module.addSerializer(LocalDate.class, new LocalDateSerializer());
        module.addSerializer(Period.class, new PeriodSerializer());
        module.addSerializer(LocalTime.class, new LocalTimeSerializer());
        module.addSerializer(Instant.class, new InstantSerializer());
        objectMapper.registerModule(module);

        prettyWriter = objectMapper.writer(prettyPrinter);
    }

    /**
     * Streams a JSON representation of the object using the generic Jackson object to JSON
     * conversions.
     *
     * <p>Will thrown an exception if there is a failure in either converting the object to JSON, or
     * if there is an IOException during the write.
     *
     * @param w the writer to stream the result to
     * @param rawObject any object that Jackson JSON converter can convert
     */
    public static void streamObjectAsJson(Writer w, Object rawObject) {
        try {
            prettyWriter.writeValue(w, rawObject);
        } catch (Exception e) {
            throw WeaverException.newWrap("Failure while attempting to convert value to JSON", e);
        }
    }

    public static String convertJsonToString(Object rawObject) {
        StringWriter sw = new StringWriter();
        streamObjectAsJson(sw, rawObject);
        return sw.toString();
    }

    public static void writeJsonToFile(File fileName, Object data) {
        try (FileWriter fw = new FileWriter(fileName, StandardCharsets.UTF_8)) {
            streamObjectAsJson(fw, data);
        } catch (Exception e) {
            throw WeaverException.newWrap(
                    "Failure while trying to write output file: %s", e, fileName.getAbsolutePath());
        }
    }

    public static <T extends Object> T loadJsonFile(File fileName, Class<T> desiredClass) {
        try {
            return new ObjectMapper()
                    .setVisibility(PropertyAccessor.FIELD, JsonAutoDetect.Visibility.ANY)
                    .readValue(fileName, desiredClass);
        } catch (Exception e) {
            throw WeaverException.newWrap(
                    "Unable to load JSON file %s", e, fileName.getAbsolutePath());
        }
    }

    public static <T extends Object> T loadJsonFromInputStream(
            InputStream inputStream, Class<T> desiredClass) {
        try {
            return new ObjectMapper()
                    .setVisibility(PropertyAccessor.FIELD, JsonAutoDetect.Visibility.ANY)
                    .readValue(inputStream, desiredClass);
        } catch (Exception e) {
            throw WeaverException.newWrap("Unable to load JSON file from InputStream", e);
        }
    }

    /**
     * If you have converted JSON into a generic Map, this will test for a member and return a
     * sub-Map, throwing an exception if the member does not exist or is not itself a map. Purpose
     * is to create good, standard exceptions when something is wrong.
     */
    public static Map<String, Object> getMap(Map<String, Object> parent, String key) {

        if (!parent.containsKey(key)) {
            throw WeaverException.newBasic("Key (%s) is missing from the hash map", key);
        }
        Object val = parent.get(key);
        if (val == null) {
            throw WeaverException.newBasic("Key (%s) is missing from the hash map", key);
        }
        if (!(val instanceof Map<?, ?>)) {
            throw WeaverException.newBasic("Key (%s) is not a Map object", key);
        }
        return (Map<String, Object>) val;
    }

    /**
     * If you have converted JSON into a generic Map, this will test for a member and return a
     * sub-Map, or it will return an empty map if no map exists. Purpose is to return a useful
     * default when no value present.
     */
    public static Map<String, Object> optMap(Map<String, Object> parent, String key) {

        if (parent.containsKey(key)) {
            Object val = parent.get(key);
            if (val instanceof Map<?, ?>) {
                return (Map<String, Object>) val;
            }
        }
        return new HashMap<>();
    }

    /**
     * If you have some nested map objects, and you have a path to a string in that nested map, this
     * will find and return the string given a dot-delimited path
     */
    public static String getPathString(Map<String, Object> parent, String path) {
        Object value = getPathObject(parent, path);
        if (value == null) {
            return null;
        }
        if (value instanceof String) {
            return (String) value;
        }
        throw WeaverException.newBasic("Requested value member (%s) is not a String", path);
    }

    public static boolean getPathBoolean(Map<String, Object> parent, String path) {
        Object value = getPathObject(parent, path);
        if (value == null) {
            return false;
        }
        if (value instanceof Boolean) {
            return (Boolean) value;
        }
        throw WeaverException.newBasic("Requested value member (%s) is not a Boolean", path);
    }

    public static Map<String, Object> getPathMap(Map<String, Object> parent, String path) {
        Object value = getPathObject(parent, path);
        if (value == null) {
            return new HashMap<>();
        }
        if (value instanceof Map) {
            return (Map<String, Object>) value;
        }
        throw WeaverException.newBasic(
                "Requested value member (%s) is not a Map<String,Object>", path);
    }

    public static Object getPathObject(Map<String, Object> parent, String path) {
        if (parent == null) {
            throw WeaverException.newBasic("parent parameter for getPathObject must not be null");
        }
        try {
            int dotPos = path.indexOf(".");
            if (dotPos < 0) {
                return parent.get(path);
            } else {
                String firstPart = path.substring(0, dotPos);
                String lastPart = path.substring(dotPos + 1);
                Object rawVal = parent.get(firstPart);
                if (rawVal instanceof Map) {
                    Map<String, Object> value = (Map<String, Object>) rawVal;
                    return getPathObject(value, lastPart);
                }
                if (rawVal instanceof List) {
                    List<Object> value = (List<Object>) rawVal;
                    return getPathObject(value, lastPart);
                }
                // because there is more path beyond this, but this is not a map
                // or a list, then we can't access those and you get null
                return null;
            }
        } catch (Exception e) {
            throw WeaverException.newWrap("Failure getting (%s) from a Map", e, path);
        }
    }

    public static Object getPathObject(List<Object> parent, String path) {
        try {
            int dotPos = path.indexOf(".");
            if (dotPos < 0) {
                return safeAccessList(parent, parseIntBetter(path));
            } else {
                String firstPart = path.substring(0, dotPos);
                String lastPart = path.substring(dotPos + 1);
                Object rawVal = safeAccessList(parent, parseIntBetter(firstPart));
                if (rawVal instanceof Map) {
                    Map<String, Object> value = (Map<String, Object>) rawVal;
                    return getPathObject(value, lastPart);
                }
                if (rawVal instanceof List) {
                    List<Object> value = (List<Object>) rawVal;
                    return getPathObject(value, lastPart);
                }
                // because there is more path beyond this, but this is not a map
                // or a list, then we can't access those and you get null
                return null;
            }
        } catch (Exception e) {
            throw WeaverException.newWrap("Failure getting (%s) from a List", e, path);
        }
    }

    private static int parseIntBetter(String str) {
        try {
            return Integer.parseInt(str);
        } catch (Exception e) {
            // the generic exception from the Integer.parseInt method does not
            // mention the value that it fails to parse.  Knowing that value can
            // make it much easier to find the problem, so making a better
            // exception will help users find the problems they made.
            throw WeaverException.newBasic("unable to parse as integer: (%s)", str);
        }
    }

    private static Object safeAccessList(List<Object> list, int index) {
        if (index < 0) {
            throw WeaverException.newBasic(
                    "Negative index is invalid for accessing a list: (%d)", index);
        }
        if (index >= list.size()) {
            // we return null here because missing elements from list produce null and not an error
            return null;
        }
        return list.get(index);
    }

    public static void setPathValue(Map<String, Object> parent, String path, Object value) {
        if (parent.containsKey(path)) {
            parent.put(path, value);
            return;
        }
        int dotPos = path.indexOf(".");
        if (dotPos < 0) {
            parent.put(path, value);
            return;
        }
        String token = path.substring(0, dotPos);
        Object child = parent.get(token);
        if (child == null) {
            child = new HashMap<>();
            parent.put(token, child);
        }
        WeaverException.failWhen(
                child instanceof List, "setPathValue can not handle structures with Lists in them");
        WeaverException.failWhen(
                !(child instanceof Map),
                "setPathValue found a %s where a Map should be",
                child.getClass().getName());
        setPathValue((Map<String, Object>) child, path.substring(dotPos + 1), value);
    }

    public static List<Object> getList(Map<String, Object> parent, String key) {

        if (!parent.containsKey(key)) {
            throw WeaverException.newBasic("Unable to find list named (%s) in hash map", key);
        }
        Object val = parent.get(key);
        if (val == null) {
            throw WeaverException.newBasic("Unable to find list named (%s) in hash map", key);
        }
        if (!(val instanceof List<?>)) {
            throw WeaverException.newBasic("Key (%s) is not a List object", key);
        }
        return (List<Object>) val;
    }

    public static Map<String, Object> getMap(List<Object> parent, int index) {

        if (parent.size() <= index) {
            throw WeaverException.newBasic(
                    "List does not have element (%s)", Integer.toString(index));
        }
        Object val = parent.get(index);
        if (val == null) {
            throw WeaverException.newBasic(
                    "List does not have element (%s)", Integer.toString(index));
        }
        if (!(val instanceof Map<?, ?>)) {
            throw WeaverException.newBasic(
                    "List element (%s) is not a Map object", Integer.toString(index));
        }
        return (Map<String, Object>) val;
    }

    public static List<String> sortedKeys(Set<String> unsorted) {
        List<String> keys = new ArrayList<>();
        keys.addAll(unsorted);
        Collections.sort(keys);
        return keys;
    }

    public static List<String> findAllPaths(Map<String, Object> tree) {
        List<String> result = new ArrayList<>();
        if (tree != null) {
            for (Map.Entry<String, Object> entry : tree.entrySet()) {
                Object value = entry.getValue();
                if (value instanceof Map) {
                    findAllPathsRecursive((Map<String, Object>) value, entry.getKey(), result);
                } else if (value instanceof List) {
                    findAllPathsRecursive((List<Object>) value, entry.getKey(), result);
                } else {
                    result.add(entry.getKey());
                }
            }
        }
        return result;
    }

    private static void findAllPathsRecursive(
            Map<String, Object> tree, String path, List<String> result) {
        if (tree != null) {
            for (String key : tree.keySet()) {
                Object val = tree.get(key);
                String fullPath = path + "." + key;
                if (val instanceof Map) {
                    findAllPathsRecursive((Map<String, Object>) val, fullPath, result);
                } else if (val instanceof List) {
                    findAllPathsRecursive((List<Object>) val, fullPath, result);
                } else {
                    // this is now a leaf node, so add path to results, if not already there
                    if (!result.contains(fullPath)) {
                        result.add(fullPath);
                    }
                }
            }
        }
    }

    private static void findAllPathsRecursive(List<Object> list, String path, List<String> result) {
        for (int i = 0; i < list.size(); i++) {
            Object val = list.get(i);
            String fullPath = path + "." + i;
            if (val instanceof Map) {
                findAllPathsRecursive((Map<String, Object>) val, fullPath, result);
            } else if (val instanceof List) {
                findAllPathsRecursive((List<Object>) val, fullPath, result);
            } else {
                // this is now a leaf node, so add path to results, if not already there
                if (!result.contains(fullPath)) {
                    result.add(fullPath);
                }
            }
        }
    }

    public static List<String> findAllCommonPaths(
            Map<String, Object> expected, Map<String, Object> actual) {
        List<String> result = findAllPaths(expected);
        for (String path : findAllPaths(actual)) {
            if (!result.contains(path)) {
                result.add(path);
            }
        }
        Collections.sort(result);
        return result;
    }

    public static List<CompareResult> compareTree(
            Map<String, Object> expected, Map<String, Object> actual) {
        List<String> allPaths = JsonUtilB.findAllCommonPaths(expected, actual);
        List<CompareResult> result = new ArrayList<>();
        for (String path : allPaths) {
            Object expectedObj = JsonUtilB.getPathObject(expected, path);
            Object actualObj = JsonUtilB.getPathObject(actual, path);

            // handle extended primitive types
            actualObj = convertExoticTypes(actualObj);

            CompareResult oneRes = new CompareResult();
            oneRes.path = path;
            oneRes.expected = String.valueOf(expectedObj);
            oneRes.actual = String.valueOf(actualObj);
            oneRes.isEqual = checkMatch(expectedObj, actualObj);

            result.add(oneRes);
        }
        return result;
    }

    private static Object convertExoticTypes(Object actualObj) {
        // TODO Auto-generated method stub
        throw new UnsupportedOperationException("Unimplemented method 'convertExoticTypes'");
    }

    public static boolean checkMatch(Object expectedObj, Object actualObj) {
        if (expectedObj == null) {
            // in this case, don't ever fail, the null here means that the
            // scenario is not asking for this to be compared
            return true;
        }
        if ("~Null~".equals(expectedObj)) {
            // actual must be null
            return (actualObj == null);
        }
        if ("~NotNull~".equals(expectedObj)) {
            // actual must be null
            return (actualObj != null);
        }
        if ("~Empty~".equals(expectedObj)) {
            // actual must be null, an empty object, or an empty list
            if (actualObj == null) {
                return true;
            }
            if (actualObj instanceof Map) {
                return ((Map<String, Object>) actualObj).size() == 0;
            }
            if (actualObj instanceof List) {
                return ((List<Object>) actualObj).size() == 0;
            }
            if (actualObj instanceof String) {
                return ((String) actualObj).length() == 0;
            }
            return false;
        }
        String expectedStr = String.valueOf(expectedObj);
        String actualStr = String.valueOf(actualObj);

        return expectedStr.equals(actualStr);
    }

    public static class CompareResult {
        public String path;
        public String expected;
        public String actual;
        public boolean isEqual;
    }
}
