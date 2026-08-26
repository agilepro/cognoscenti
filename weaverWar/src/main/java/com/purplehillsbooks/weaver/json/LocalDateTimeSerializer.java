package com.purplehillsbooks.weaver.json;

import com.fasterxml.jackson.core.JsonGenerator;
import com.fasterxml.jackson.databind.SerializerProvider;
import com.fasterxml.jackson.databind.ser.std.StdSerializer;
import java.io.IOException;
import java.time.LocalDateTime;

/** LocalDateTimeSerializer */
public class LocalDateTimeSerializer extends StdSerializer<LocalDateTime> {

    protected LocalDateTimeSerializer() {
        super(LocalDateTime.class);
    }

    @Override
    public void serialize(
            LocalDateTime timestamp, JsonGenerator jsonGenerator, SerializerProvider serializer)
            throws IOException {
        jsonGenerator.writeString(
                timestamp.format(java.time.format.DateTimeFormatter.ISO_LOCAL_DATE_TIME));
    }
}
