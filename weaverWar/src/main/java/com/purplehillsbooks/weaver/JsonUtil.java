package com.purplehillsbooks.weaver;

import java.io.File;
import java.io.IOException;
import java.io.Writer;

import com.fasterxml.jackson.annotation.JsonInclude.Include;
import com.fasterxml.jackson.core.JsonGenerator;
import com.fasterxml.jackson.core.PrettyPrinter;
import com.fasterxml.jackson.core.Version;
import com.fasterxml.jackson.core.util.DefaultPrettyPrinter;
import com.fasterxml.jackson.core.util.Separators;
import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.MapperFeature;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.databind.SerializerProvider;
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
        mapper.registerModule(module1);

        // serialize any JSONArray that appear
        SimpleModule module2 =  new SimpleModule("JSONArraySerializer", new Version(1, 0, 0, null, null, null));
        module2.addSerializer(JSONArray.class, new JsonUtil.JSONArraySerializer());
        mapper.registerModule(module2);     
        return mapper;   
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

}
