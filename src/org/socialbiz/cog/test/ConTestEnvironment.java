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


import java.util.HashMap;
import java.util.Map;

/**
 *
 * Static environment of key-value pairs that allows tests to exchange test
 * parameters across component boundaries.
 */
public class ConTestEnvironment {

    private static Map<String,Object> m_globals = new HashMap<String,Object>();

    // Prevents instances of this purely static class to be created.
    private ConTestEnvironment() {
    }

    /**
     * Sets a parameter in the global scope.
     *
     * @param key
     *                The parameter's key.
     * @param value
     *                The parameter's value.
     */
    public static void setGlobal(String key, Object value) {
        m_globals.put(key.toLowerCase(), value);
    }

    /**
     * Attempts to retrieve a parameter from the <em>global</em> scope only.
     * @param key
     *                The parameter's key.
     * @return The parameter's value, if the parameter exists in the global
     *         scope, otherwise null.
     */
    public static Object getGlobal(String key) {
        Object value = m_globals.get(key.toLowerCase());
        return value;
    }

    /**
     * Removes a parameter from the global scope, if it exists.
     *
     * @param key
     *                The parameter's key.
     */
    public static void removeGlobal(String key) {
        m_globals.remove(key.toLowerCase());
    }



    }