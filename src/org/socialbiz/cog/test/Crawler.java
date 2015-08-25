/*
 * Copyright 2013 Keith D Swenson
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * Contributors Include: Shamim Quader, Sameer Pradhan, Kumar Raja, Jim Farris,
 * Sandia Yang, CY Chen, Rajiv Onat, Neal Wang, Dennis Tam, Shikha Srivastava,
 * Anamika Chaudhari, Ajay Kakkar, Rajeev Rastogi
 */

package org.socialbiz.cog.test;

import org.socialbiz.cog.exception.ProgramLogicError;
import com.gargoylesoftware.htmlunit.BrowserVersion;
import com.gargoylesoftware.htmlunit.JavaScriptPage;
import com.gargoylesoftware.htmlunit.Page;
import com.gargoylesoftware.htmlunit.WebClient;
import com.gargoylesoftware.htmlunit.WebWindow;
import com.gargoylesoftware.htmlunit.html.ClickableElement;
import com.gargoylesoftware.htmlunit.html.HtmlAnchor;
import com.gargoylesoftware.htmlunit.html.HtmlForm;
import com.gargoylesoftware.htmlunit.html.HtmlPage;
import com.gargoylesoftware.htmlunit.html.HtmlSubmitInput;
import com.gargoylesoftware.htmlunit.html.HtmlTextInput;
import com.gargoylesoftware.htmlunit.xml.XmlPage;


import java.io.PrintWriter;
import java.lang.Comparable;
import java.net.URL;
import java.util.Enumeration;
import java.util.Iterator;
import java.util.List;
import java.util.ListIterator;
import java.util.Random;
import java.util.TreeSet;
import java.util.Vector;

public class Crawler {


    String baseUrl;     // e.g.: "http://spradhan-e8020:8080/nugen/" (the ending slash is important)
    String startPage;   // first page to scan
    String sitePath;    // any URL that starts with this is considered "part of the site"
    String userId;      // e.g.: "http://spradhan.myopenid.com"  (can be any string, it is not validated)
    PrintWriter out;
    Log    log;
    long   timeLimit;
    Random random;

    int mode;
    public static int MODE_URL = 0;
    public static int MODE_CLICK = 1;
    int yuiErrors;
    public static int YUI_SHOW = 0;
    public static int YUI_HIDE = 1;

    Vector<PageTestStatus> pagesToCrawl = new Vector<PageTestStatus>();
    BrowserVersion myBrowser = BrowserVersion.FIREFOX_3; // this is the only one for now. later, we can add emulation of other browsers
    Vector<String> errors = new Vector<String>();
    StringBuffer excludePages = new StringBuffer();

    public static void main(String[] args)
        throws Exception
    {
        String baseUrl = "http://localhost:8080/nugen/";
        String userId = "http://spradhan.myopenid.com";

        Crawler crawler = new Crawler(baseUrl, userId, new PrintWriter(System.out), Integer.parseInt(args[0]),
                        Integer.parseInt(args[1]), Integer.parseInt(args[2]), 9000);
        crawler.runTests();
    }

    /**
    * parameter "timeOut" is the maximum number of seconds that you want the test to run.
    * test will stop when that many seconds have passed (from constructing the object)
    */
    public Crawler(String baseUrl, String userId, PrintWriter out, int mode, int level, int yuiErrors, int timeOut)
    {
        this.baseUrl = baseUrl;
        this.userId  = userId;
        this.out     = out;
        this.mode    = mode;
        this.log     = new Log(out);
        this.log.setLevel(level);
        this.yuiErrors = yuiErrors;
        this.timeLimit = System.currentTimeMillis() + (timeOut*1000);
        random = new Random();
        setStartPage(baseUrl);
    }

    public void setStartPage(String newStartPage)
    {
        startPage = newStartPage;
        int slashPos = startPage.indexOf('/', 9);
        sitePath  = startPage.substring(0,slashPos);
    }

    public void runTests() throws Exception
    {
        test_HtmlUnitDependencies();
        test_crawl_no_login();

        //not sure if this is working today
        //test_crawl_with_login();

        printSummary();
    }

    public void test_HtmlUnitDependencies() throws Exception
    {
        log.prn(Log.ALL, "BEGIN TEST: test_HtmlUnitDependencies");
        final WebClient webClient = new WebClient(myBrowser);
        webClient.closeAllWindows();
        log.prn(Log.ALL, "COMPLETED TEST: test_HtmlUnitDependencies\n");
    }

    public void test_crawl_with_login() throws Exception
    {
        log.prn(Log.ALL, "BEGIN TEST: test_crawl_with_login");

        pagesToCrawl.clear();
        String homepageAddr = startPage;

        final WebClient webClient = new WebClient();
        Page p =  webClient.getPage(homepageAddr);
        checkContentType(p);
        final HtmlPage homepage = (HtmlPage)p;

        // get the main form
        final HtmlForm form_loginForm = homepage.getFormByName("loginForm");

        // get "openid" textfield and set the value
        final HtmlTextInput textField_openid = (HtmlTextInput) form_loginForm.getInputByName("openid");
        textField_openid.setValueAttribute(userId);

        // get the submit button
        final HtmlSubmitInput button = (HtmlSubmitInput) form_loginForm.getInputByName("option");


        // Now submit the form by clicking the button and get back the second page.
        p = button.click();
        checkContentType(p);
        final HtmlPage page2 = (HtmlPage)p;
        //log.prn(Log.INFO, page2.asXml());

        crawl(page2, "mainpage", webClient);

        log.prn(Log.ALL, "COMPLETED TEST: test_crawl_with_login\n");
    }

    public void test_crawl_no_login() throws Exception
    {
        log.prn(Log.PROGRESS, "BEGIN TEST: test_crawl_no_login");
        log.prn(Log.PROGRESS, "SITE PATH: "+sitePath);

        pagesToCrawl.clear();
        URL startUrl = new URL(startPage);
        pagesToCrawl.add(new PageTestStatus(startUrl));

        final WebClient webClient = new WebClient();
        try
        {
            crawl(webClient);
        }
        finally
        {
            //closeAllWindows is supposed to shut everything down, but it doesn't.
            //If you have a background javascript that is invoking
            //itself time and again every 6 seconds, you need
            //to kill all the running jobs as well.  This is not guaranteed
            //to work.  Not sure how to completely shut HTMLUNIT down.
            List<WebWindow> windowList = webClient.getWebWindows();
            for (WebWindow ww : windowList)
            {
                log.prn(Log.ALL, "Killing threads on window '"+ww.getName()+"'");
//                ThreadManager tm = ww.getThreadManager();
//                tm.interruptAll();
            }

            //closeAllWindows is supposed to shut everything down, but it doesn't.
            //do it again just in case it helps
            webClient.closeAllWindows();
            log.prn(Log.ALL, "Closing all windows");

        }

        log.prn(Log.PROGRESS, "COMPLETED TEST: test_crawl_no_login\n");
    }

    public void crawl(HtmlPage homepage, String homepageAddr, WebClient webClient) throws Exception
    {
        log.prn(Log.PROGRESS, "STARTING SCAN AT: " + homepageAddr);
        log.prn(Log.PROGRESS, "SITE PATH: "+sitePath);
        getNewAnchors(homepage);

        while (timeLimit>System.currentTimeMillis())
        {
            PageTestStatus pts = findRandomPage();

            if (pts==null || errors.size()>20)
            {
                break;
            }

            String path= pts.getUrl().getPath();

            if (excludePages.toString().length() > 0 && excludePages.toString().indexOf(path) >= 0)
            {
                pts.markSkipped();
            }
            else
            {
                crawlOnePage(pts, webClient);
            }
        }
        dumpVector();
    }

    public void crawl(WebClient webClient) throws Exception
    {
        while (timeLimit>System.currentTimeMillis())
        {
            PageTestStatus pts = findRandomPage();

            if (pts==null)
            {
                break;
            }

            if (errors.size()>20)
            {
                break;
            }

            String path= pts.getUrl().getPath();

            if (excludePages.toString().length() > 0 && excludePages.toString().indexOf(path) >= 0)
            {
                pts.markSkipped();
            }
            else
            {
                crawlOnePage(pts, webClient);
            }
        }
        dumpVector();
    }



    private void crawlOnePage(PageTestStatus pts, WebClient webClient)
    {
        log.prn(Log.PROGRESS, "{{{Testing page: " +pts.getUrl());
        String path= pts.getUrl().getPath();
        Page pageToTest = null;
        long startTime = System.currentTimeMillis();

        try {
            if (mode == Crawler.MODE_URL) {
                log.prn(Log.PROGRESS, "     reading:");
                pageToTest = webClient.getPage(pts.getUrl());
                log.prn(Log.PROGRESS, "     received it");
            }
            else {
                pageToTest = pts.getClickableElement().click();
            }
            pts.setMilliseconds(System.currentTimeMillis()-startTime);
            checkContentType(pageToTest);
            //testPage(pageToTest);
            if (pageToTest instanceof HtmlPage)
            {
                getNewAnchors((HtmlPage)pageToTest);
            }
            else if (pageToTest instanceof XmlPage)
            {
                XmlPage xmlPage = (XmlPage)pageToTest;
                log.prn(Log.INFO, "Printing htmlunit.xml.XmlPage ["+pts.getPageId()+"]:");
                log.prn(Log.INFO, xmlPage.asXml());
            }
            else if (pageToTest instanceof JavaScriptPage)
            {
                JavaScriptPage javaScriptPage = (JavaScriptPage)pageToTest;
                log.prn(Log.INFO, "Printing htmlunit.JavaScriptPage ["+pts.getPageId()+"]:");
                log.prn(Log.INFO, javaScriptPage.getContent());
            }
            else
            {
                throw new ProgramLogicError("Page is not instance of HtmlPage, nor XmlPage, nor JavaScriptPage. Class:"+pageToTest.getClass().getName());
            }
            pageToTest.cleanUp();
            pts.markPassed();
        }
        catch (Exception e)
        {
            boolean isYuiError = e.toString().indexOf("/yui/")>=0;
            if (isYuiError)
            {
                pts.markYuiError();
            }
            else
            {
                pts.markFailed();
            }
            if (isYuiError && yuiErrors == Crawler.YUI_HIDE) {
                // print nothing
            }
            else {

                String summary = "EXCEPTION CAUGHT testing [<a href=\"" + pts.getUrl() + "\" target=\"_blank\">"+ pts.getUrl() + "</a>] : " + e.toString();
                log.prn(Log.ERROR, "<a name=\"e"+ (errors.size()+1) + "\"/>"+summary);
                e.printStackTrace(out);
                errors.add(summary);
                if (excludePages.toString().length() == 0 || excludePages.toString().indexOf(path) < 0)
                {
                    excludePages.append(pts.getUrl().getPath());
                    excludePages.append(",");
                }
            }
            if (pageToTest!=null)
            {
                try
                {
                    pageToTest.cleanUp();
                }
                catch (Exception e4)
                {
                    errors.add("EXCEPTION while attempting to clean up the page: "+e4.toString());
                }
            }
        }
        finally
        {
            webClient.closeAllWindows();
        }
        log.prn(Log.PROGRESS, "}}}Tested page:  " +pts.getUrl() + "\n");
    }

    private void dumpVector()
    {
        int untestedCount = 0;
        int passedCount = 0;
        int failedCount = 0;
        int yuiErrorCount = 0;
        int skippedCount = 0;
        int unknownResultCount = 0;

        log.prn(Log.ALL, "RESULT   \tPAGE_ID");
        TreeSet<PageTestStatus> ts = new TreeSet<PageTestStatus>(pagesToCrawl);
        Iterator<PageTestStatus> iter = ts.iterator();
        while (iter.hasNext())
        {
            PageTestStatus pts = iter.next();
            String result = pts.getResult();
            log.prn(Log.ALL, result + "\t"+pts.getPageId());

            if (result.equals(PageTestStatus.UNTESTED)) {
                untestedCount++;
            }
            else if (result.equals(PageTestStatus.PASSED)) {
                passedCount++;
            }
            else if (result.equals(PageTestStatus.FAILED)) {
                failedCount++;
            }
            else if (result.equals(PageTestStatus.YUIERROR)) {
                yuiErrorCount++;
            }
            else if (result.equals(PageTestStatus.SKIPPED)) {
                skippedCount++;
            }
            else {
                unknownResultCount++;
            }
        }
        log.prn(Log.ALL, "Total:["+ts.size()+"] Passed:["+passedCount+"] Failed:["+failedCount+"] YUI Error:["+yuiErrorCount+"] Skipped:["+skippedCount+"] Untested:["+untestedCount+"] Unknown result:["+unknownResultCount+"]\n");
    }

    private void printSummary()
    {
        log.prn(Log.ALL, "SUMMARY: Found ["+ errors.size() + "] exceptions");
        Enumeration<String> e = errors.elements();
        int i=1;
        while (e.hasMoreElements())
        {
            log.prn(Log.ALL, "<a href=\"#e" + i + "\">(" + i + ")</a> "+ e.nextElement());
            i++;
        }
        out.flush();
    }

    public void getNewAnchors(HtmlPage htmlPage)
        throws Exception
    {
        int newAnchorCount = 0;
        List<HtmlAnchor> anchorList = htmlPage.getAnchors();
        ListIterator<HtmlAnchor> anchorIter = anchorList.listIterator();
        while(anchorIter.hasNext())
        {
            HtmlAnchor anchor = anchorIter.next();
            String href = anchor.getHrefAttribute();

            //strip off anything after the hash mark (since that is addressing a
            //portion of the page, and we only read entire pages, all parts are tested).
            int hashPos = href.indexOf("#");
            if (hashPos>0)
            {
                href = href.substring(0,hashPos);
            }
            URL url = htmlPage.getFullyQualifiedUrl(href);
            //checkUrl(url);

            if(isInternalLink(url))
            {
                PageTestStatus pts = null;
                if (mode == Crawler.MODE_URL) {
                    pts = new PageTestStatus(url);
                }
                else {
                    pts = new PageTestStatus(url, anchor);
                }

                if(!pagesToCrawl.contains(pts))
                {
                    pagesToCrawl.add(pts);
                    newAnchorCount++;
                    log.prn(Log.INFO, "\tfound anchor (new anchor added):\t" + pts.getPageId());
                }
                else
                {
                    log.prn(Log.INFO, "\tfound anchor (anchor already known):\t" + href);
                }
            }
            else
            {
                log.prn(Log.INFO, "\tfound anchor (ignored external):\t" + href);
            }
        }
        log.prn(Log.INFO, "\tFound ["+ newAnchorCount + "] new anchors");
    }

    
    
    private void checkContentType(Page pageToTest) throws Exception
    {
        String contentType = pageToTest.getWebResponse().getContentType();
        log.prn(Log.PROGRESS, "\tContent Type:"+contentType);
        if (contentType == null || contentType.trim().equals(""))
        {
            throw new ProgramLogicError("Page has improper blank 'Content Type' http header");
        }
    }

    private boolean isInternalLink(URL url)
    {
        String urlPath = url.getPath();
        if(urlPath.indexOf("LogoutAction.jsp")>=0)
        {
            return false;
        }
        if(urlPath.indexOf("HookLink.jsp")>=0)
        {
            return false;
        }
        if(urlPath.indexOf("RunTests.jsp")>=0)
        {
            return false;
        }
        if(urlPath.indexOf("Run%54ests.jsp")>=0)
        {
            return false;
        }
        if(urlPath.indexOf("Action.jsp")>=0)
        {
            return false;
        }
        if(urlPath.indexOf("MyActiveTask.htm")>=0)
        {
            return false;
        }
        if(urlPath.indexOf("MyFutureTask.htm")>=0)
        {
            return false;
        }
        if(urlPath.indexOf("MyCompltedTask.htm")>=0)
        {
            return false;
        }
        if(urlPath.indexOf("AllMyTask.htm")>=0)
        {
            return false;
        }
        if(urlPath.indexOf("EmailLoginForm.htm")>=0)
        {
            return false;
        }

        if(urlPath.indexOf("/a/")>=0)
        {   // need not open any attachment
            return false;
        }

        if (url.toExternalForm().startsWith(sitePath))
        {
            return true;
        }
        return false;
    }

    private PageTestStatus findRandomPage()
    {
        int knownPages = pagesToCrawl.size();

        //first try to find a page from a random location
        int checkPage = random.nextInt(knownPages);
        while (checkPage<knownPages)
        {
            PageTestStatus possible = pagesToCrawl.elementAt(checkPage);
            if (!possible.isTested())
            {
                return possible;
            }
            checkPage++;
        }

        //second try to find a page from the beginning (looping around once)
        checkPage=0;
        while (checkPage<knownPages)
        {
            PageTestStatus possible = pagesToCrawl.elementAt(checkPage);
            if (!possible.isTested())
            {
                return possible;
            }
            checkPage++;
        }

        //finally, give up
        return null;
    }



    class PageTestStatus implements Comparable<Object>
    {
        private URL url;
        private ClickableElement clickableElement;
        private String pageId;

        private boolean tested;
        private String result;
        private long milliseconds;

        static final String UNTESTED = "Untested   ";
        static final String PASSED   = "Passed     ";
        static final String FAILED   = "FAILED     ";
        static final String SKIPPED  = "Skipped    ";
        static final String YUIERROR = "YUI Error  ";


        public PageTestStatus(URL url)
        {
            this(url, null);
        }
        public PageTestStatus(URL nurl, ClickableElement clickableElement)
        {
            this.url = nurl;
            this.clickableElement = clickableElement;
            pageId = url.getFile();
            tested = false;
            result = PageTestStatus.UNTESTED;
        }

        public URL getUrl()
        {
            return url;
        }

        public void setMilliseconds(long millis)
        {
            milliseconds = millis;
        }

        public void markPassed()
        {
            tested = true;
            result = PageTestStatus.PASSED;
            clickableElement = null;
        }

        public void markFailed()
        {
            tested = true;
            result = PageTestStatus.FAILED;
            clickableElement = null;
        }

        public void markSkipped()
        {
            tested = true;
            result = PageTestStatus.SKIPPED;
            clickableElement = null;
        }

        public void markYuiError()
        {
            tested = true;
            result = PageTestStatus.YUIERROR;
            clickableElement = null;
        }

        public boolean isTested()
        {
            return tested;
        }

        public String getResult()
        {
            if (milliseconds==0)
            {
                return result + "\t    ";
            }
            int seconds = (int) (milliseconds/1000);
            int tenths = (int) (milliseconds - (seconds*1000))/100;
            return result + "\t" + seconds + "." + tenths + " ";
        }

        public String getPageId()
        {
            return pageId;
        }

        public ClickableElement getClickableElement()
        {
            return clickableElement;
        }

        public int compareTo(Object otherObj)
        {
            PageTestStatus other = (PageTestStatus)otherObj;
            return this.pageId.compareTo(other.getPageId());
        }

        public boolean equals(Object otherObj)
        {
            PageTestStatus other = (PageTestStatus)otherObj;
            return this.pageId.equals(other.getPageId());
        }
    }


    /***************************************************************************************************************/
    /*** NOTE: DO NOT DELETE BELOW METHODS
    /*** They will not normally be called.
    /*** But they may be used when this program is modified to test if the test is correct
    /***************************************************************************************************************/

    /*
    private void checkUrl(URL url) throws Exception
    {
        log.prn(Log.INFO, "");
        log.prn(Log.INFO, "toString="+url.toString());         // toString=http://spradhan-e8020:8080/nugen/BookInfo.jsp?b=BILVKOQVF&dummy=pqr#abc
        log.prn(Log.INFO, "getProtocol="+url.getProtocol());   // getProtocol=http
        log.prn(Log.INFO, "getAuthority="+url.getAuthority()); // getAuthority=spradhan-e8020:8080
        log.prn(Log.INFO, "getHost="+url.getHost());           // getHost=spradhan-e8020
        log.prn(Log.INFO, "getPort="+url.getPort());           // getPort=8080
        log.prn(Log.INFO, "getFile="+url.getFile());           // getFile=/nugen/BookInfo.jsp?b=BILVKOQVF&dummy=pqr
        log.prn(Log.INFO, "getPath="+url.getPath());           // getPath=/nugen/BookInfo.jsp
        log.prn(Log.INFO, "getQuery="+url.getQuery());         // getQuery=b=BILVKOQVF&dummy=pqr
        log.prn(Log.INFO, "getRef="+url.getRef());             // getRef=abc
        log.prn(Log.INFO, "toExternalForm="+url.toExternalForm()); // toExternalForm=http://spradhan-e8020:8080/nugen/BookInfo.jsp?b=BILVKOQVF&dummy=pqr#abc
        log.prn(Log.INFO, "toURI="+url.toURI());               // toURI=http://spradhan-e8020:8080/nugen/BookInfo.jsp?b=BILVKOQVF&dummy=pqr#abc
        log.prn(Log.INFO, "getUserInfo="+url.getUserInfo());   // getUserInfo=null
        log.prn(Log.INFO, "");
    }
    */

    /********************* End: utility methods to check correctness of this test program ************************/


    class Log {
        static final int ALL = -1;
        static final int ERROR = 0;
        static final int PROGRESS = 1;
        static final int INFO = 2;

        int currLevel;
        PrintWriter out;
        long startTime;

        public Log(PrintWriter out)
        {
            this.out = out;
            startTime = System.currentTimeMillis();
            currLevel = 1;
            //this.out.println("["+startTime+"] get from url\n");
            //this.out.println("["+startTime+"] null after testing\n");
        }

        public void setLevel(int level)
        {
            if (level >= -1 && level <= 2) {
                currLevel = level;
            }
        }

        public void prn(int level, String msg)
        {
            prnInternal(level, msg, true);
        }

        public void prn2(int level, String msg)
        {
            prnInternal(level, msg, false);
        }

        private void prnInternal(int level, String msg, boolean newline)
        {
            if (level <= currLevel)
            {
                float now = ((float)(System.currentTimeMillis() - startTime))/1000;
                out.print("[");
                out.printf("%4.3f", now);
                out.print("] ");
                if (newline)
                {
                    out.println(msg);
                }
                else
                {
                    out.print(msg);
                }
                out.flush();
            }
        }
    }
}
