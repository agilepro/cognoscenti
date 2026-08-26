package com.purplehillsbooks.weaver.json;

import com.fasterxml.jackson.core.JsonGenerator;
import com.fasterxml.jackson.databind.SerializerProvider;
import com.fasterxml.jackson.databind.ser.std.StdSerializer;
import java.io.IOException;
import java.time.LocalDate;

/** Add the ability for Jackson to serialized java.time.LocalDate objects */
public class LocalDateSerializer extends StdSerializer<LocalDate> {

    public LocalDateSerializer() {
        super(LocalDate.class);
    }

    @Override
    public void serialize(
            LocalDate localDate, JsonGenerator jsonGenerator, SerializerProvider serializer)
            throws IOException {
        // Write this date as a string like "2023-10-01"
        jsonGenerator.writeString(
                localDate.format(java.time.format.DateTimeFormatter.ISO_LOCAL_DATE));
    }

    public static String getStringForCompare(LocalDate localDate) {
        return localDate.format(java.time.format.DateTimeFormatter.ISO_LOCAL_DATE);
    }
}
