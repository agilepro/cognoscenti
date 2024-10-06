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

package com.purplehillsbooks.weaver.exception;

/**
 * This is a concrete exception class, that has exception messages stored in
 * a file called 'ErrorMessage'
 */
public class NGException extends ExceptionBase {

    private static final long serialVersionUID = 1L;

    public NGException(String _propertyKey, Object[] _params) {
        super(_propertyKey, _params);

    }

    public NGException(String _propertyKey, Object[] _params, Exception e) {
        super(_propertyKey, _params, e);

    }

    /**
     * Used by ExceptionBase to read the right resource bundle
     */
    protected  String resourceBundleName() {
        return "messages";
    }

}
