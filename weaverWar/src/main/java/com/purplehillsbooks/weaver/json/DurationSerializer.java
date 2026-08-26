package com.purplehillsbooks.weaver.json;

import com.fasterxml.jackson.core.JsonGenerator;
import com.fasterxml.jackson.databind.SerializerProvider;
import com.fasterxml.jackson.databind.ser.std.StdSerializer;
import java.io.IOException;
import java.time.Duration;

/** DurationSerializer */
public class DurationSerializer extends StdSerializer<Duration> {

    public DurationSerializer() {
        super(Duration.class);
    }

    @Override
    public void serialize(
            Duration duration, JsonGenerator jsonGenerator, SerializerProvider serializer)
            throws IOException {
        jsonGenerator.writeString(duration.toString());
    }
}
