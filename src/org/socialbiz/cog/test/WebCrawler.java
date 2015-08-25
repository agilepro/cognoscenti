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

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.MalformedURLException;
import java.net.URL;
import java.util.ArrayList;
import java.util.Hashtable;
import java.util.Iterator;
import java.util.List;
import java.util.Vector;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.w3c.dom.Document;

import org.socialbiz.cog.exception.NGException;
import org.socialbiz.cog.DOMFile;


    public class WebCrawler {

        private static Log log = LogFactory.getLog(WebCrawler.class.getName());

        public static final int SEARCH_LIMIT = 100; // Absolute max pages

        public static final int MAXSIZE = 200000; // Max size of file

        // URLs to be searched
        List<URL> newURLs;
        // Known URLs
        Hashtable<URL, Integer> knownURLs;
        // max number of pages to download
        int maxPages;

        // initializes data structures.

        public void initialize(String[] initdata) {
            URL url;
            knownURLs = new Hashtable<URL, Integer>();
            newURLs = new Vector<URL>();
            try {
                url = new URL(initdata[0]);
            } catch (MalformedURLException e) {
                System.out.println("Invalid starting URL " + initdata[0]);
                return;
            }
            knownURLs.put(url, new Integer(1));
            newURLs.add(url);

            System.out.println("Starting search: Initial URL " + url.toString());

            maxPages = SEARCH_LIMIT;
            if (initdata.length > 1) {
                int iPages = Integer.parseInt(initdata[1]);
                if (iPages < maxPages) {
                    maxPages = iPages;
                }
            }
            System.out.println("Maximum number of pages:" + maxPages);

        }

        // Adds new URL to the list. Accept only new URL's that end in
        // htm or html. oldURL is the context, newURLString is the link
        // (either an absolute or a relative URL).

        public void addNewUrl(URL oldURL, String newUrlString)

        {
            URL url;
            if (log.isDebugEnabled()) {
                log.debug("URL String " + newUrlString);
            }
            try {
                url = new URL(oldURL, newUrlString);
                if (!knownURLs.containsKey(url)) {
                    String filename = url.getFile();
                    int iSuffix = filename.lastIndexOf("htm");
                    if ((iSuffix == filename.length() - 3)
                            || (iSuffix == filename.length() - 4)) {
                        knownURLs.put(url, new Integer(1));
                        newURLs.add(url);
                        System.out.println("Found new URL " + url.toString());
                    }
                }
            } catch (MalformedURLException e) {
                return;
            }
        }

        /** Configures the list of patters for the urls that should be ignored on the
         * validation process.
         * @param theIgnoredUrlpatterns the list of url patterns, it cannot be null.
         */
        public void setIgnoredUrlpatterns(final List<String> theIgnoredUrlpatterns) {
        }

        // Download contents of URL
        public String getpage(InputStream urlStream)

        {
            try {
                // search the input stream for links first, read in the entire URL
                byte b[] = new byte[1000];
                int numRead = urlStream.read(b);
                if(numRead<0){
                    return "";
                }
                String content = new String(b, 0, numRead);

                while ((numRead != -1) && (content.length() < MAXSIZE)) {
                    numRead = urlStream.read(b);
                    if (numRead != -1) {
                        String newContent = new String(b, 0, numRead);
                        content += newContent;
                    }
                }

                return content;

            } catch (IOException e) {
                log.error("ERROR: couldn't open URL ");
                return "";
            }
        }

        // Go through page finding links to URLs. A link is mark by <a href=" and it ends with a close angle bracket

        public void processPage(URL url, String page)

        {
            String lcPage = page.toLowerCase(); // Page in lower case

            int index = 0; // position in page
            int iEndAngle, ihref, iURL, iCloseQuote, iHatchMark, iEnd;

            while ((index = lcPage.indexOf("<a", index)) != -1) {
                iEndAngle = lcPage.indexOf(">", index);
                ihref = lcPage.indexOf("href", index);

                if (ihref != -1) {
                    iURL = lcPage.indexOf("\"", ihref) + 1;
                    if ((iURL != -1) && (iEndAngle != -1) && (iURL < iEndAngle)) {
                        iCloseQuote = lcPage.indexOf("\"", iURL);
                        iHatchMark = lcPage.indexOf("#", iURL);
                        if ((iCloseQuote != -1) && (iCloseQuote < iEndAngle)) {
                            iEnd = iCloseQuote;
                            if ((iHatchMark != -1) && (iHatchMark < iCloseQuote)){
                                iEnd = iHatchMark;
                            }
                            String newUrlString = page.substring(iURL, iEnd);

                            addNewUrl(url, newUrlString);
                        }
                    }
                }
                index = iEndAngle;
            }
        }


        // Keep crawaling the url off newURLs, download
        // it, and accumulate new URLs

        public void run(String[] initdata) {
            initialize(initdata);
            InputStream in=null;
            for (int i = 0; i < maxPages; i++) {

                if (newURLs.isEmpty()){
                    break;
                }
                URL url = newURLs.get(0);
                newURLs.remove(0);

                if (log.isDebugEnabled()){
                    log.debug("Searching " + url.toString());
                }
                if(url.toString().indexOf("t/EmailLoginForm.htm")>0){
                    continue;
                }

                System.out.println("Starting search: URL " + url.toString());
               try{
                    // Open a HTTP connection to the URL
                    HttpURLConnection connection = (HttpURLConnection) url.openConnection();

                    connection.setDoOutput(true);
                    in = connection.getInputStream();
               }catch (IOException ioe) {
                   log.error("IO error occurs while creating the input stream." + ioe);
               }
                Page htmlpage=new Page();
                htmlpage.load(in, 0, false);

                if (log.isDebugEnabled()){
                    System.out.println(htmlpage.getHTML());
                }
                String page = htmlpage.getHTML();

                //Search for error
                String searchKeyword = "Exception";
                int start = page.indexOf(searchKeyword);
                int result = 0;
                int len = searchKeyword.length();

                while (start != -1) {
                result++;
                start = page.indexOf(searchKeyword, start+len);
                }
                if (log.isDebugEnabled()){
                    System.out.println("Search for Error"+result);
                }

                if (newURLs.isEmpty()){
                        processPage(url, page);
                }
                if (page.length() != 0){

                    try{
                        boolean isError=new XHTMLValidator().validateHTMLPage(url.toString(),in);
                        if(!isError){
                            processPage(url, page);
                         }else{
                             log.info("Invalidate XHTML content");
                         }
                    }catch (Exception ioe) {
                        log.error("IO error occurs while creating the input stream." + ioe);
                    }
                  }


            }
        }

        public static List<String> readUrlList(String templateURLFile,String baseURL)throws Exception{

            DOMFile urltemplate;
            List<String> urlList = new ArrayList<String>();
            try {
                File theFile = new File(templateURLFile);
                Document newDoc = DOMFile.readOrCreateFile(theFile,
                        "Url-template-lists");
                urltemplate = new DOMFile(theFile, newDoc);
                Iterator<TemplateURLRecord> url = urltemplate.getChildren("testable",
                        TemplateURLRecord.class).iterator();
                if (url != null) {
                    while (url.hasNext()) {
                        TemplateURLRecord record = url.next();
                        urlList.add(baseURL + record.getTestableUrl());
                    }
                }
            }
            catch (Exception e) {
                throw new NGException("nugen.exception.unable.to.read.xml.file",
                        new Object[] { templateURLFile }, e);
            }

            return urlList;
        }

        public static void main(String[] argv){


            try {
                //get the property value of the base URL and URLTemplate
                String urlTemplate=Configurations.getStringProperty("fetcher.url.list.location","./My Test Suite/URLTemplateLists.xml");
                String baseURL=Configurations.getStringProperty("fetcher.base.url","http://leaves.interstagebpm.com:8080/nugen");

                List<String> urlList=readUrlList(urlTemplate,baseURL);
                List<String> IgnoredUrlList=new ArrayList<String>();

                WebCrawler wc = new WebCrawler();
                IgnoredUrlList.add("Found new URL http://leaves.interstagebpm.com:8080/nugen/t/EmailLoginForm.htm?go=http%3A%2F%2Fleaves.interstagebpm.com%3A8080%2Fnugen%2Ft%2FEmailLoginForm.htm%3Bjsessionid%3D66DEA037C7EBDC9113D96A27AF1C8CCA%3Fmsg%3DMust%2520be%2520logged%2520in%2520to%2520open%2520public%2520page.%26go%3Dhttp%253A%252F%252Fleaves.interstagebpm.com%253A8080%252Fnugen%252Fv%252Fmainbook%252F%2524%252Fpublic.htm");

                wc.setIgnoredUrlpatterns(IgnoredUrlList);
                Iterator<String> it =urlList.iterator();
                while(it.hasNext()){
                   String newUrl=it.next();
                   wc.run(new String[] {newUrl,"50" });

                }

            } catch (Exception ex) {
                ex.printStackTrace();
            }

        }

    }


