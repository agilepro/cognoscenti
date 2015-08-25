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

package org.socialbiz.cog.exception;

import java.util.Locale;

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

    /**
    * @deprecated, use the other getFullMessage
    */
    public String getFullMessage(Locale locale){
        return getFullMessage(this, locale);
    }


    /**
    * Walks through a chain of exception objects, from the first, to each
    * "cause" in turn, creating a single combined string message from all
    * the exception objects in the chain, with newline characters between
    * each exception message.
    *
    * If you don't have a locale handy, use Locale.getDefault()  to get default
    */
    public static String getFullMessage(Throwable e, Locale locale)
    {
        StringBuffer retMsg = new StringBuffer();
        while (e != null)
        {
            if (e instanceof ExceptionBase)
            {
                retMsg.append(((ExceptionBase)e).toString(locale));
            }
            else
            {
                retMsg.append(e.toString());
            }
            retMsg.append("\n");
            e = e.getCause();
        }
        return retMsg.toString();
    }


    /**
    * Uses default locale ... but don't be lazy!  This should only be
    * used for background processes where there is no user locale available.
    */
    public static String getFullMessage(Throwable e)
    {
        return getFullMessage(e, Locale.getDefault());
    }

}
