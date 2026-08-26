package com.purplehillsbooks.weaver.json;

import com.fasterxml.jackson.core.JsonGenerator;
import com.fasterxml.jackson.databind.SerializerProvider;
import com.fasterxml.jackson.databind.ser.std.StdSerializer;
import java.io.IOException;
import java.time.Instant;

/** InstantSerializer */
public class InstantSerializer extends StdSerializer<java.time.Instant> {

    public InstantSerializer() {
        super(Instant.class);
    }

    @Override
    public void serialize(Instant arg0, JsonGenerator arg1, SerializerProvider arg2)
            throws IOException {
        // TODO Auto-generated method stub
        throw new UnsupportedOperationException("Unimplemented method 'serialize'");
    }
}
