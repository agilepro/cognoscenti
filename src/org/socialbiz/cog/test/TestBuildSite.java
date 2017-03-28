package org.socialbiz.cog.test;

import java.util.List;

import org.socialbiz.cog.Cognoscenti;
import org.socialbiz.cog.NGBook;
import org.socialbiz.cog.NGPageIndex;
import org.socialbiz.cog.NGRole;
import org.workcast.testframe.TestDriver;
import org.workcast.testframe.TestRecorder;
import org.workcast.testframe.TestSet;


/**
 * Tests the basic building of a site from scratch using just the data
 * layer confirming that all data layer methods work correctly
 */
public class TestBuildSite implements TestSet {


    //this becomes a 'reserved id' use by this test.   These must
    //be no site preexisting with this id, and it will create one.
    public final String siteKey = "Tst80808";

    public final String allPunct = "1234567890-=!@#$%^&*()_+][\\}{|;':\",./><?";

    private TestRecorder tr;
    private Cognoscenti cog;

    public TestBuildSite(Cognoscenti _cog) {
        cog = _cog;
    }

    public void runTests(TestRecorder _tr) throws Exception {
        tr = _tr;
        assureTestSiteNotThere();
        createNewSite(cog);

        setValuesOnSite();

        createTestProjects();
    }



    private void assureTestSiteNotThere() throws Exception {
        //check to see if there is a pre-existing site, and abort
        NGPageIndex testSiteCon = cog.getContainerIndexByKey(siteKey);
        if (testSiteCon==null) {
            return;
        }

        String name = testSiteCon.containerName;

        //to guard against destroying a real site, test to see that the name includes
        //a special symbol ''
        int pos = name.indexOf("!@#$%^&*");
        if (pos<0) {
            throw new Exception("Strange.  Found a site with the key '"+siteKey+"' but the name does not have special punctuation in it, so please delete this manually");
        }

        if (testSiteCon.isProject()) {
            throw new Exception("Strange.  Found a site with the key '"+siteKey+"' but it is not a NGBook .... don't know what to do with it.");
        }

        NGBook testSite = (NGBook) testSiteCon.getContainer();
        NGBook.destroySiteAndAllProjects(testSite, cog);
    }


    private NGBook createNewSite(Cognoscenti cog) throws Exception {
        String siteName = "Test Site "+siteKey+" "+allPunct;
        NGBook testSite = NGBook.createNewSite(siteKey, siteName, cog);
        testSite.save();

        testString("getFullName should return same name as set", testSite.getFullName(), siteName);
        testString("key member should return same key as set", testSite.key, siteKey);
        testString("getKey should return same key as set", testSite.getKey(), siteKey);

        //default value testing
        testString("getStyleSheet default should be empty string", testSite.getStyleSheet(), "PageViewer.css");
        testString("getLogo default should be empty string", testSite.getLogo(), "logo.gif");
        testString("getDescription default should be empty string", testSite.getDescription(), "");
        testString("getThemePath default", testSite.getDescription(), "");

        testStringArray("getContainerNames default", testSite.getContainerNames(), siteName+"|");
        testLong("getLastModifyTime default should be zero", testSite.getLastModifyTime(), 0);
        testBoolean("isDeleted default should be false", testSite.isDeleted(), false);
        testBoolean("isFrozen default should be false", testSite.isFrozen(), false);

        testNotNull("getSiteRootFolder should not be null", testSite.getSiteRootFolder());
        testBoolean("isSiteFolderStructure default should be true", testSite.isSiteFolderStructure(), true);

        //test the default role settings
        NGRole prim =  testSite.getPrimaryRole();
        assertNotNull("testSite.getPrimaryRole", prim);
        testString("primaryRole.getName test", prim.getName(), "Executives");

        NGRole sec =  testSite.getSecondaryRole();
        assertNotNull("testSite.getSecondaryRole", sec);
        testString("secondaryRole.getName test", sec.getName(), "Owners");

        //read the file again from disk
        testSite = NGBook.forceRereadSiteFile(siteKey);

        testString("getFullName should return same name as set", testSite.getFullName(), siteName);
        testString("key member should return same key as set", testSite.key, siteKey);
        testString("getKey should return same key as set", testSite.getKey(), siteKey);

        //default value testing
        testString("getStyleSheet default should be empty string", testSite.getStyleSheet(), "PageViewer.css");
        testString("getLogo default should be empty string", testSite.getLogo(), "logo.gif");
        testString("getDescription default should be empty string", testSite.getDescription(), "");
        testString("getThemePath default", testSite.getDescription(), "");

        testStringArray("getContainerNames default", testSite.getContainerNames(), siteName+"|");
        testLong("getLastModifyTime default should be zero", testSite.getLastModifyTime(), 0);
        testBoolean("isDeleted default should be false", testSite.isDeleted(), false);
        testBoolean("isFrozen default should be false", testSite.isFrozen(), false);

        testNotNull("getSiteRootFolder should not be null", testSite.getSiteRootFolder());
        testBoolean("isSiteFolderStructure default should be true", testSite.isSiteFolderStructure(), true);

        //test the default role settings
        prim =  testSite.getPrimaryRole();
        assertNotNull("testSite.getPrimaryRole", prim);
        testString("primaryRole.getName test", prim.getName(), "Executives");

        sec =  testSite.getSecondaryRole();
        assertNotNull("testSite.getSecondaryRole", sec);
        testString("secondaryRole.getName test", sec.getName(), "Owners");
        return testSite;
    }

    public void setValuesOnSite() throws Exception {
        NGBook testSite = NGBook.forceRereadSiteFile(siteKey);
        String testVal = allPunct+allPunct+allPunct;
        testSite.setDescription(testVal);
        testString("getDescription test value", testSite.getDescription(), testVal);
        testVal = "<![CDATA[\"Me, Myself & <I>\"]]>";
        testSite.setDescription(testVal);
        testSite.setDescription(testVal);
        testString("getDescription CDATA value", testSite.getDescription(), testVal);

        testSite.save();
        testSite = NGBook.forceRereadSiteFile(siteKey);
        testString("getDescription CDATA value", testSite.getDescription(), testVal);
    }


    private void createTestProjects() {

    }






    ////////////////////////////


    private void testString(String id, String testVal, String expectedVal) {
        if (expectedVal.equals(testVal)) {
            tr.markPassed(id);
        }
        else {
            tr.markFailed(id, "String values do not match; expected '"+expectedVal+"' but got '"+testVal+"'");
        }
    }

    @SuppressWarnings("unused")
    private void testNull(String id, Object testVal) {
        if (null==testVal) {
            tr.markPassed(id);
        }
        else {
            tr.markFailed(id, "Expected a null value, but got a non-null instead");
        }
    }

    /**
     * For non-fatal nul values, check and report whether an object is null
     */
    private void testNotNull(String id, Object testVal) {
        if (null!=testVal) {
            tr.markPassed(id);
        }
        else {
            tr.markFailed(id, "Expected an object, but got a null instead");
        }
    }

    private void assertNotNull(String id, Object testVal) throws Exception {
        if (null==testVal) {
            throw new Exception(id + " Test object was null, further testing must be aborted.");
        }
    }

    private void testStringArray(String id, List<String> testVal, String expectedVal) throws Exception {
        assertNotNull(id, testVal);
        StringBuilder sb = new StringBuilder();
        for (String val : testVal) {
            sb.append(val);
            sb.append("|");
        }
        testString(id, sb.toString(), expectedVal);
    }

    private void testLong(String id, long testVal, long expectedVal) throws Exception {
        testString(id, Long.toString(testVal), Long.toString(expectedVal));
    }
    private void testBoolean(String id, boolean testVal, boolean expectedVal) throws Exception {
        testString(id, (testVal?"true":"false"), (expectedVal?"true":"false"));
    }

    public static void main(String[] args) {
        String[] newArgs = new String[1];
        newArgs[0] = "org.socialbiz.cog.test.TestBuildSite";
        TestDriver.main(newArgs);
    }

}
