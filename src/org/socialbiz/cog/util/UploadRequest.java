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

package org.socialbiz.cog.util;

import java.util.Enumeration;
import java.util.Hashtable;
import org.socialbiz.cog.exception.NGException;

/* UploadRequest.java
 *
 * Support request for file uploader in new gen
 *
 * This is implemented as a hast table of hashtables.  But, the index of the
 * inner hashtable is always an integer.  The inner should be a Vector (or a ArrayList)
 * because that is indexed by number, instead of by a hash object.
 */

public class UploadRequest {

    UploadRequest() {
        m_parameters = new Hashtable<String, Hashtable<Integer, String>>();
    }

    protected void putParameter(String name, String value)
            throws Exception {
        if (name == null) {
            throw new NGException("nugen.exception.param.invalid",null);
        }

        if (m_parameters.containsKey(name)) {
            Hashtable<Integer, String> values = m_parameters.get(name);
            values.put(new Integer(values.size()), value);
        } else {
            Hashtable<Integer, String> values = new Hashtable<Integer, String>();
            values.put(new Integer(0), value);
            m_parameters.put(name, values);
        }
    }

    public String getParameter(String name) {
        if (name == null) {
            throw new IllegalArgumentException("The name does not exist.");
        }
        Hashtable<Integer, String> values = m_parameters.get(name);
        if (values == null) {
            return null;
        }
        else {
            return values.get(new Integer(0));
        }
    }

    public Enumeration<String> getParameterNames() {
        return m_parameters.keys();
    }

    public String[] getParameterValues(String name) {
        if (name == null) {
            throw new IllegalArgumentException("The name does not exist.");
        }
        Hashtable<Integer, String> values = m_parameters.get(name);
        if (values == null) {
            return null;
        }
        String strValues[] = new String[values.size()];
        for (int i = 0; i < values.size(); i++) {
            strValues[i] = values.get(new Integer(i));
        }

        return strValues;
    }

    private Hashtable<String, Hashtable<Integer, String>> m_parameters;
}