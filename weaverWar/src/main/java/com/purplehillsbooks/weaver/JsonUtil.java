package com.purplehillsbooks.weaver;

import java.io.File;

import com.fasterxml.jackson.annotation.JsonInclude.Include;
import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.MapperFeature;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.purplehillsbooks.weaver.exception.WeaverException;


/**
 * JsonUtil is for reading and writing files structured with JSON 
 */
public class JsonUtil {

    @SuppressWarnings("deprecation")
    public static <T extends Object> T loadJsonFile(File filePath, Class<T> childClass) throws Exception {

        ObjectMapper mapper = new ObjectMapper();
        try {
            // disable is deprecated, but not clear what the replacement is
            // except for using a builder which seems like pointless
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
            
            if (!filePath.exists()) {
                throw WeaverException.newBasic("Unable to load JSON file because the file does not exist");
            }
            T fileContents = mapper.readValue(filePath, childClass);
            return fileContents;
        }
        catch (Exception e) {
            throw WeaverException.newWrap("Failure reading JSON file: %s", 
                    e,  filePath.getAbsolutePath());
        }
    }
    @SuppressWarnings("deprecation")
    public static <T extends Object> void saveJsonFile(File filePath, T contents) throws Exception {
        File fileTempPath = new File(filePath.getParentFile(), filePath.getName()+"~TMP~");
        if (fileTempPath.exists()) {
            fileTempPath.delete();
        }
        ObjectMapper mapper = new ObjectMapper();
        // disable is deprecated, but not clear what the replacement is
        // except for using a builder which seems like pointless
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
        
        mapper.writeValue(fileTempPath, contents);
        if (filePath.exists()) {
            filePath.delete();
        }
        fileTempPath.renameTo(filePath);
    }

    private JsonUtil() {
    }


}
