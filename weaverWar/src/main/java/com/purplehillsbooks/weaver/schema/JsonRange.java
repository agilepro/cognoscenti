package com.purplehillsbooks.weaver.schema;

import java.math.BigDecimal;

/** JsonRange */
public class JsonRange {

    public BigDecimal maximum;
    public BigDecimal minimum;
    public BigDecimal exclusiveMaximum;
    public BigDecimal exclusiveMinimum;

    public boolean isInRange(BigDecimal bigValue) {
        // TODO Auto-generated method stub
        throw new UnsupportedOperationException("Unimplemented method 'isInRange'");
    }
}
