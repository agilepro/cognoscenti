package com.purplehillsbooks.weaver;

import java.io.File;
import java.io.IOException;
import java.io.Writer;
import java.util.Iterator;
import java.util.Map.Entry;

import com.fasterxml.jackson.annotation.JsonInclude.Include;
import com.fasterxml.jackson.core.JacksonException;
import com.fasterxml.jackson.core.JsonGenerator;
import com.fasterxml.jackson.core.JsonParser;
import com.fasterxml.jackson.core.Version;
import com.fasterxml.jackson.core.util.DefaultPrettyPrinter;
import com.fasterxml.jackson.core.util.Separators;
import com.fasterxml.jackson.databind.DeserializationContext;
import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.MapperFeature;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.databind.SerializerProvider;
import com.fasterxml.jackson.databind.deser.std.StdDeserializer;
import com.fasterxml.jackson.databind.module.SimpleModule;
import com.fasterxml.jackson.databind.ser.std.StdSerializer;
import com.purplehillsbooks.json.JSONArray;
import com.purplehillsbooks.json.JSONObject;
import com.purplehillsbooks.weaver.exception.WeaverException;
import com.purplehillsbooks.weaver.util.AvoidCloseWriter;


/**
 * JsonUtil is for reading and writing files structured with JSON 
 */
public class JsonUtil {

    @SuppressWarnings("deprecation")
    private static ObjectMapper getMapper() {

        DefaultPrettyPrinter printer = new DefaultPrettyPrinter() {
            @Override
            public DefaultPrettyPrinter createInstance() {
                return new DefaultPrettyPrinter(this);
            }

            @Override
            public DefaultPrettyPrinter withSeparators(Separators separators) {
                _separators = separators;
                _objectFieldValueSeparatorWithSpaces = separators.getObjectFieldValueSeparator() + " ";
                return this;
            }
        };
        printer = printer.withSeparators(Separators.createDefaultInstance());

        // disable is deprecated, but not clear what the replacement is
        // except for using a builder which seems like pointless
        ObjectMapper mapper = new ObjectMapper();
        mapper.disable(MapperFeature.AUTO_DETECT_CREATORS,
                MapperFeature.AUTO_DETECT_GETTERS,
                MapperFeature.AUTO_DETECT_IS_GETTERS);
        mapper.enable(MapperFeature.SORT_PROPERTIES_ALPHABETICALLY);
        mapper.configure(MapperFeature.SORT_PROPERTIES_ALPHABETICALLY, true);
        mapper.enable(SerializationFeature.ORDER_MAP_ENTRIES_BY_KEYS);
        mapper.configure(SerializationFeature.ORDER_MAP_ENTRIES_BY_KEYS, true);
        mapper.configure(SerializationFeature.INDENT_OUTPUT, true);
        mapper.configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false);
        mapper.setSerializationInclusion(Include.NON_NULL);
        mapper.setDefaultPrettyPrinter(printer);

        // serialize any JSONObjects that appear
        SimpleModule module1 =  new SimpleModule("JSONObjectSerializer", new Version(1, 0, 0, null, null, null));
        module1.addSerializer(JSONObject.class, new JsonUtil.JSONObjectSerializer());
        module1.addDeserializer(JSONObject.class, new JsonUtil.JSONObjectDeserializer(mapper));
        mapper.registerModule(module1);

        // serialize any JSONArray that appear
        SimpleModule module2 =  new SimpleModule("JSONArraySerializer", new Version(1, 0, 0, null, null, null));
        module2.addSerializer(JSONArray.class, new JsonUtil.JSONArraySerializer());
        module1.addDeserializer(JSONArray.class, new JsonUtil.JSONArrayDeserializer(mapper));
        mapper.registerModule(module2);
        return mapper;   
    }

    public static <T extends Object> T loadOrCreateJsonFile(File filePath, Class<T> childClass) throws Exception {
        if (!filePath.exists()) {
            SearchManager.writeStringToFile("{}", filePath);
        }
        if (!filePath.exists()) {
            throw WeaverException.newBasic("Unable to create file %s for unknown reason", filePath.getAbsolutePath());
        }
        return loadJsonFile(filePath, childClass);
    }


    public static <T extends Object> T loadJsonFile(File filePath, Class<T> childClass) throws Exception {
        try {
            if (!filePath.exists()) {
                throw WeaverException.newBasic("Unable to load JSON file because the file does not exist");
            }
            ObjectMapper mapper = getMapper();
            T fileContents = mapper.readValue(filePath, childClass);
            return fileContents;
        }
        catch (Exception e) {
            throw WeaverException.newWrap("Failure reading JSON file: %s", 
                    e,  filePath.getAbsolutePath());
        }
    }

    public static <T extends Object> void saveJsonFile(File filePath, T contents) throws Exception {
        try {
            File fileTempPath = new File(filePath.getParentFile(), filePath.getName()+"~TMP~");
            if (fileTempPath.exists()) {
                fileTempPath.delete();
            }
            ObjectMapper mapper = getMapper();
            mapper.writeValue(fileTempPath, contents);
            
            if (filePath.exists()) {
                filePath.delete();
            }
            fileTempPath.renameTo(filePath);
        }
        catch (Exception e) {
            throw WeaverException.newWrap("Unable to save to file (%s)", 
                    e, filePath.getAbsolutePath());
        }
    }

    public static <T extends Object> void writeJson(Writer w, T contents) throws Exception {
        ObjectMapper mapper = getMapper();
        AvoidCloseWriter acw = new AvoidCloseWriter(w);
        mapper.writeValue(acw, contents);
    }

    private JsonUtil() {
    }

    public static <T extends Object> String convertToJsonString(T contents) throws Exception {
        try {
            ObjectMapper mapper = getMapper();
            return mapper.writeValueAsString(contents);
        }
        catch (Exception e) {
            throw WeaverException.newWrap("Unable to convert to JSON string", e);
        }
    }

    static class JSONObjectSerializer extends StdSerializer<JSONObject> {

        public JSONObjectSerializer() {
            super(JSONObject.class);
        }

        @Override
        public void serialize( JSONObject jo, JsonGenerator jsonGenerator, 
                SerializerProvider serializer) throws IOException {
            jsonGenerator.writeStartObject();
            for (String key : jo.sortedKeySet()) {
                jsonGenerator.writeObjectField(key, jo.get(key));
            }
            jsonGenerator.writeEndObject();
        }
    }
    static class JSONArraySerializer extends StdSerializer<JSONArray> {
    
        public JSONArraySerializer() {
            super(JSONArray.class);
        }

        @Override
        public void serialize( JSONArray ja, JsonGenerator jsonGenerator, 
                SerializerProvider serializer) throws IOException {
            jsonGenerator.writeStartArray();
            for (int index=0; index<ja.length(); index++) {
                jsonGenerator.writeObject(ja.get(index));
            }
            jsonGenerator.writeEndArray();
        }
    }

    static class JSONObjectDeserializer extends StdDeserializer<JSONObject> {
        ObjectMapper mapper;

        protected JSONObjectDeserializer(ObjectMapper _mapper) {
            super(JSONObject.class);
            mapper = _mapper;
        }

        @Override
        public JSONObject deserialize(JsonParser jp, DeserializationContext context)
                throws IOException, JacksonException {
            JsonNode node = jp.getCodec().readTree(jp);
            JSONObject jo = new JSONObject();
            for (Entry<String, JsonNode> prop : node.properties()) {
                JsonNode jn = prop.getValue();
                if (jn.isInt()) {
                    jo.put(prop.getKey(), jn.asInt());
                }
                else if (jn.isLong()) {
                    jo.put(prop.getKey(), jn.asLong());
                }
                else if (jn.isBigDecimal()) {
                    jo.put(prop.getKey(), jn.asDouble());
                }
                else if (jn.isBoolean()) {
                    jo.put(prop.getKey(), jn.asBoolean());
                }
                else if (jn.isObject()) {
                    jo.put(prop.getKey(), mapper.convertValue(jn, JSONObject.class));
                }
                else if (jn.isArray()) {
                    jo.put(prop.getKey(), mapper.convertValue(jn, JSONArray.class));
                }
                else {
                    jo.put(prop.getKey(), jn.asText());
                }
            }
            return jo;
        }
    }


    static class JSONArrayDeserializer extends StdDeserializer<JSONArray> {
        ObjectMapper mapper;

        protected JSONArrayDeserializer(ObjectMapper _mapper) {
            super(JSONArray.class);
            mapper = _mapper;
        }

        @Override
        public JSONArray deserialize(JsonParser jp, DeserializationContext context)
                throws IOException, JacksonException {
            JsonNode node = jp.getCodec().readTree(jp);
            JSONArray jo = new JSONArray();
            Iterator<JsonNode> elems = node.elements();
            while (elems.hasNext()) {
                JsonNode jn = elems.next();
                if (jn.isInt()) {
                    jo.put(jn.asInt());
                }
                else if (jn.isLong()) {
                    jo.put(jn.asLong());
                }
                else if (jn.isBigDecimal()) {
                    jo.put(jn.asDouble());
                }
                else if (jn.isBoolean()) {
                    jo.put(jn.asBoolean());
                }
                else if (jn.isObject()) {
                    jo.put(mapper.convertValue(jn, JSONObject.class));
                }
                else if (jn.isArray()) {
                    jo.put(mapper.convertValue(jn, JSONArray.class));
                }
                else {
                    jo.put(jn.asText());
                }
            }
            return jo;
        }
    }
}
