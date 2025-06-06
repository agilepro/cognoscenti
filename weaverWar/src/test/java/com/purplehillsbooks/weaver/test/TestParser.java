package com.purplehillsbooks.weaver.test;

import java.io.File;
import org.junit.Test;

import com.purplehillsbooks.weaver.JsonUtil;
import com.purplehillsbooks.weaver.capture.WebFile;
import com.purplehillsbooks.weaver.exception.WeaverException;
import com.purplehillsbooks.json.JSONObject;


/**
 * Tests the basic building of a site from scratch using just the data
 * layer confirming that all data layer methods work correctly
 */
public class TestParser {

    File outputFolder = new File("target/scenarios");

    @Test
    public void testit() throws Exception {
        File sample1 = new File("src/test/resource/webPage3737.json");
        if (!sample1.exists()) {
            throw WeaverException.newBasic("cant find: %s", sample1.getAbsolutePath());
        }
        System.out.println("SAMPLE1 at: "+sample1.getAbsolutePath());
        WebFile wf = WebFile.readOrCreate(sample1, "nowhere");
        JSONObject plines = wf.getSectionParagraphsAndSentences(24);
        if (!outputFolder.exists()) {
            outputFolder.mkdirs();
        }
        File dump1 = new File(outputFolder, "webPage3737.parsed.json");
        plines.writeToFile(dump1);
    }

    @Test
    public void testJacksonParser() throws Exception {
        File sample1 = new File("src/test/resource/webPage3737.json");
        JSONObject myObject = JsonUtil.loadJsonFile(sample1, JSONObject.class);
        
        if (!outputFolder.exists()) {
            outputFolder.mkdirs();
        }
        
        File dump1 = new File(outputFolder, "webPage3737.native.json");
        myObject.writeToFile(dump1);

        File dump2 = new File(outputFolder, "webPage3737.jackson.json");
        JsonUtil.saveJsonFile(dump2, myObject);
    }

}
