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

import java.util.Properties;

import junit.framework.TestCase;

import com.gargoylesoftware.htmlunit.WebClient;

public class CognoscentiBaseTestCase extends TestCase {

    protected static String username = null;

    protected static String password = null;

    public static final String ADMINUSERNAME = "adminuser";

    public static final String ADMINPASSWORD = "adminpassword";

    protected static Properties loginCredentials = null;

    public static final String GBL_LOGIN_CREDENTIALS = "logincredentials"; // maintained


    private WebClient browser;

    protected void setUp() throws Exception {
        super.setUp();
        browser = new WebClient();
    }

    protected void tearDown() {
        browser = null;
    }
    /**
     * @return
     */
    public WebClient getWebClient() {
        return browser;
    }

    /**
     * @param client
     */
    public void setWebClient(WebClient client) {
        browser = client;
    }


    public void login() throws Exception {


        username = ConTestEnvironment.getGlobal(ADMINUSERNAME).toString();
        password = ConTestEnvironment.getGlobal(ADMINPASSWORD).toString();

        if (null == (loginCredentials = (Properties) ConTestEnvironment .getGlobal(GBL_LOGIN_CREDENTIALS))) {
            loginCredentials = new Properties();
            loginCredentials.put(username, password);
            ConTestEnvironment.setGlobal(GBL_LOGIN_CREDENTIALS, loginCredentials);
        } else {
            loginCredentials.put(username, password);
        }


    }


}
