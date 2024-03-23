package com.purplehillsbooks.weaver.test;

import java.io.File;
import java.util.List;

import org.junit.Test;

import com.purplehillsbooks.weaver.Cognoscenti;
import com.purplehillsbooks.weaver.NGBook;
import com.purplehillsbooks.weaver.NGPageIndex;
import com.purplehillsbooks.weaver.NGRole;
import com.purplehillsbooks.weaver.capture.WebFile;

import com.purplehillsbooks.testframe.TestDriver;
import com.purplehillsbooks.testframe.TestRecorder;
import com.purplehillsbooks.testframe.TestSet;
import com.purplehillsbooks.json.JSONObject;
import com.purplehillsbooks.json.JSONArray;


/**
 * Tests the basic building of a site from scratch using just the data
 * layer confirming that all data layer methods work correctly
 */
public class TestParser {

    @Test
    public void testit() throws Exception {
        File sample1 = new File("src/test/resource/webPage3737.json");
        if (!sample1.exists()) {
            throw new Exception("cant find: "+sample1.getAbsolutePath());
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
