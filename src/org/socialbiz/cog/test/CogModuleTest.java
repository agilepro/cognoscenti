package org.socialbiz.cog.test;

import java.io.File;

import com.purplehillsbooks.json.JSONException;

public class CogModuleTest {

    public CogModuleTest(String path) throws Exception {
        File folder = new File(path);
        if (!folder.exists()) {
            throw new Exception("The test data folder does not exist: "+path);
        }
        //re-enable line below once figured out how to do it.
        //Cognoscenti.initializeAll(folder, null);
        throw new Exception("Text disabled due to unsure it is being used.");
    }

    public void runTests() {
        TestBuildSite.main(new String[0]);
    }

    public static void main(String[] args) {
        try {
            CogModuleTest cmt = new CogModuleTest("c:/ApacheTomcat7/webapps/cog/");
            cmt.runTests();
        }
        catch (Exception e) {
            System.out.print("\n\nFATAL ERROR EXIT PROGRAM:\n");
            JSONException.traceException(System.out, e, "FATAL ERROR EXIT PROGRAM");
        }
    }
}
