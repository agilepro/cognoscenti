package com.purplehillsbooks.weaver.json;

import com.fasterxml.jackson.core.JsonGenerator;
import com.fasterxml.jackson.databind.SerializerProvider;
import com.fasterxml.jackson.databind.ser.std.StdSerializer;
import java.io.IOException;
import java.time.LocalTime;

/** LocalTimeSerializer */
public class LocalTimeSerializer extends StdSerializer<LocalTime> {

    protected LocalTimeSerializer() {
        super(LocalTime.class);
    }

    @Override
    public void serialize(
            LocalTime localTime, JsonGenerator jsonGenerator, SerializerProvider serializer)
            throws IOException {
        jsonGenerator.writeString(
                localTime.format(java.time.format.DateTimeFormatter.ISO_LOCAL_TIME));
    }
}
