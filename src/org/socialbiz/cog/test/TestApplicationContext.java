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

import org.springframework.context.ApplicationContext;
import org.springframework.context.support.FileSystemXmlApplicationContext;


/**
 *
 */
public class TestApplicationContext {

    private static ApplicationContext context = getInstance();

    /**
     * Empty contstructor that exists only to defeat instantiation.
     */
    private TestApplicationContext() {
        //Exists only to defeat instantiation.
    }

    public synchronized static ApplicationContext getContext() {
        return TestApplicationContext.context;
    }

    private synchronized static ApplicationContext getInstance() {
        String[] paths = {"webapp/WEB-INF/nugen-service.xml"};
        return new FileSystemXmlApplicationContext(paths);
    }
}
