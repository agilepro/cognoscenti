package com.purplehillsbooks.weaver.test;

import java.io.File;
import org.junit.Test;

import com.purplehillsbooks.weaver.capture.WebFile;
import com.purplehillsbooks.weaver.exception.WeaverException;
import com.purplehillsbooks.json.JSONObject;


/**
 * Tests the basic building of a site from scratch using just the data
 * layer confirming that all data layer methods work correctly
 */
public class TestParser {

    @Test
    public void testit() throws Exception {
        File sample1 = new File("src/test/resource/webPage3737.json");
        if (!sample1.exists()) {
            throw WeaverException.newBasic("cant find: %s", sample1.getAbsolutePath());
        }
        System.out.println("SAMPLE1 at: "+sample1.getAbsolutePath());
        WebFile wf = WebFile.readOrCreate(sample1, "nowhere");
        JSONObject plines = wf.getSectionParagraphsAndSentences(24);
        File outputFolder = new File("target/scenarios");
        if (!outputFolder.exists()) {
            outputFolder.mkdirs();
        }
        File dump1 = new File(outputFolder, "webPage3737.parsed.json");
        plines.writeToFile(dump1);
    }

}
