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

package com.purplehillsbooks.weaver;

public final class ValueElement {

    public String name;
    public String value;

    public ValueElement() {
    }

    public ValueElement(String name, String value) {
        this.name = name;
        this.value = value;
    }

    public String toString()
    {
        final java.lang.StringBuilder _ret = new java.lang.StringBuilder(
                "org.socialbiz.cog.ValueElement {");
        _ret.append("String name=");
        _ret.append(name);
        _ret.append("\n");
        _ret.append("String value=");
        _ret.append(value);
        _ret.append("}");
        return _ret.toString();
    }

    public boolean equals(Object o) {
        if (!(o instanceof ValueElement)) {
            return false;
        }

        ValueElement ve = (ValueElement) o;
        if (name.equals(ve.name) == false || value.equals(ve.value) == false) {
            return false;
        }
        return true;
    }

}