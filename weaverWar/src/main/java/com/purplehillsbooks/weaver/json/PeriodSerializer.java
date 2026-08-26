package com.purplehillsbooks.weaver.json;

import com.fasterxml.jackson.core.JsonGenerator;
import com.fasterxml.jackson.databind.SerializerProvider;
import com.fasterxml.jackson.databind.ser.std.StdSerializer;
import java.io.IOException;
import java.time.Period;

/** PeriodSerializer */
public class PeriodSerializer extends StdSerializer<Period> {

    public PeriodSerializer() {
        super(Period.class);
    }

    @Override
    public void serialize(Period period, JsonGenerator jsonGenerator, SerializerProvider serializer)
            throws IOException {
        jsonGenerator.writeString(period.toString());
    }
}
