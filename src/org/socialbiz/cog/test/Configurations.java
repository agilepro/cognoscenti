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


public final class Configurations {

    private static Properties prop = new Properties();

    public static String getStringProperty(String key, String defaultValue) {
        if (prop == null || prop.getProperty(key) == null) {
            return defaultValue;
        }
        return prop.getProperty(key);
    }

    public static int getIntProperty(String key, int defaultValue) {
        if (prop == null || prop.getProperty(key) == null) {
            return defaultValue;
        }
        return Integer.parseInt(prop.getProperty(key));
    }

    public static short getShortProperty(String key, short defaultValue) {
        if (prop == null || prop.getProperty(key) == null) {
            return defaultValue;
        }
        return Short.parseShort(prop.getProperty(key));
    }

    public static long getLongProperty(String key, long defaultValue) {
        if (prop == null || prop.getProperty(key) == null) {
            return defaultValue;
        }
        return Long.parseLong(prop.getProperty(key));
    }

    public static boolean getBooleanProperty(String key, boolean defaultValue) {
        if (prop == null || prop.getProperty(key) == null) {
            return defaultValue;
        }
        return prop.getProperty(key).toLowerCase().trim().equals("true");
    }

    static {
        try {
            prop.load(Configurations.class.getClassLoader()
                    .getResourceAsStream("crawal.properties"));
        } catch (Exception e) {
            prop = null;
            System.err.println("WARNING: Could not find test.config file in class path.Will use the default values.");
        }
    }
}
