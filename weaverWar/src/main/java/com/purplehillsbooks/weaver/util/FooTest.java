package com.purplehillsbooks.weaver.util;

public class FooTest {

    public FooTest() {
        // added this constructor in the second level
    }

    public int method111() {
        return 111;
    }

    public void aDifferentMethod() {
        // added this method in the master level
        // added a second comment line in the master level
    }

}
