/*
 * Copyright 2023 Keith D Swenson
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
 */

package com.purplehillsbooks.weaver.exception;

import com.purplehillsbooks.json.JSONException;

/**
 * WeaverException is a barebones exception that wraps the
 * JSONException with static factory methods.
 * Uses Java String.format style formatting
 */
public class WeaverException extends JSONException {

    /** Should never use this, but need to have default constructor */
    private WeaverException() {
        super("Unspecified WeaverException");
    }
    private WeaverException(String msg, Exception cause) {
        super(msg, cause);
    }
    public static WeaverException newBasic(String msg, Object... params) {
        return new WeaverException(String.format(msg, params), null);
    }
    public static WeaverException newWrap(String msg, Exception cause, Object... params) {
        return new WeaverException(String.format(msg, params), cause);
    }
    public static WeaverException newProgramLogicError(String msg, Object... params) {
        return newBasic(msg, params);
    }


    public static boolean contains(Throwable e, String searchToken) {
        while (e != null) {
            if (e.toString().contains(searchToken)) {
                return true;
            }
            e = e.getCause();
        }
        return false;
    }

    public static String getFullMessage(Throwable e) {
        StringBuilder retMsg = new StringBuilder();
        while (e != null) {
            String line = e.toString();
            int colonPos = line.indexOf(":");
            if (colonPos>0 && colonPos<60) {
                String prefix = line.substring(0, colonPos);
                boolean strip = false;
                if (prefix.contains("WeaverException")) {
                    strip = true;
                }
                if (prefix.contains("Exception")) {
                    strip = true;
                }
                if (strip) {
                    line = line.substring(colonPos+1);
                }
            }
            retMsg.append(line);
            retMsg.append("\n");
            e = e.getCause();
        }
        return retMsg.toString();
    }
  

}
