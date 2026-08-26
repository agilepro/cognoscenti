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

import java.io.PrintStream;
import java.io.Writer;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import com.purplehillsbooks.weaver.json.JsonUtil;

/**
 * WeaverException is a barebones exception supports conversion to JSON for logging and reporting.
 * It is a RuntimeException so that it can be thrown without being declared in the method signature.
 */
public class WeaverException extends RuntimeException {

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

    // TODO: is this redundant?
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
            if (colonPos > 0 && colonPos < 60) {
                String prefix = line.substring(0, colonPos);
                boolean strip = false;
                if (prefix.contains("WeaverException")) {
                    strip = true;
                }
                if (prefix.contains("Exception")) {
                    strip = true;
                }
                if (strip) {
                    line = line.substring(colonPos + 1);
                }
            }
            retMsg.append(line);
            retMsg.append("\n");
            e = e.getCause();
        }
        return retMsg.toString();
    }

    private static void findDetails(List<String> details, Throwable e) {
        String msg = e.getMessage();
        if (msg == null || msg.isEmpty()) {
            msg = e.toString();
        }
        details.add(msg);
        if (e.getCause() != null) {
            findDetails(details, e.getCause());
        }
    }

    /**
     * Converts a chain of exceptions (or any Throwable type) into a suitable JSON structure that
     * contains the chain of messages, as well as a trimmed stack trace. When this method is called
     * at a point in the code, only the stack "above" that point is included in the trace, because
     * the stack below that point is normally not relevant.
     *
     * @param e the exception chain to convert
     * @return a JSON formatted string
     */
    public static String getJsonForLog(Throwable e) {
        try {
            Map<String, Object> fieldMap = getJsonMapForLog(e);
            return JsonUtil.convertToJsonString(fieldMap);
        } catch (Exception failure) {
            // since this method is for handling/reporting exceptions,
            // we commit an anti-pattern:  we just ignore the exception in the
            // formatting of this response, and just do the best we can.
            return "UNABLE TO CONVERT EXCEPTION TO JSON: " + e.toString();
        }
    }

    public static Map<String, Object> getJsonMapForLog(Throwable e) {
        List<String> details = new ArrayList<>();
        findDetails(details, e);
        return Map.of(
                "details",
                details,
                "stackTrace",
                getTrace(e),
                "errorDescription",
                String.join("\n", details));
    }

    private static List<String> rawTrace(Throwable t) {
        List<String> trace = new ArrayList<>();
        String msg = t.getMessage();
        if (msg == null || msg.isEmpty()) {
            msg = t.getClass().getName();
        }
        trace.add(msg);
        for (StackTraceElement ste : t.getStackTrace()) {
            trace.add("  " + ste.toString());
        }
        return trace;
    }

    public static List<String> getTrace(Throwable exception) {
        return getTrace(exception, new Exception("just for getting tail"));
    }

    public static List<String> getTrace(Throwable exception, Exception tail) {
        List<String> justTail = rawTrace(tail);
        return captureTrace(exception, justTail);
    }

    /**
     * extracts the causal chain from the exception objects and converts to a list of string values,
     * removing the tail if there is one.
     */
    public static List<String> captureTrace(Throwable t, List<String> tail) {
        List<String> trace = rawTrace(t);
        Throwable cause = t.getCause();
        if (cause == null) {
            removeTail(trace, tail);
            return trace;
        }
        List<String> causeTrace = captureTrace(cause, trace);
        removeTail(trace, tail);
        causeTrace.addAll(trace);
        return causeTrace;
    }

    // What this allows if an exception stack has the tail removed of an exception
    // constructed at "this" point in the stack, will remain with only the stack
    // trace elements "above" this point, discarding the stack below this point
    // which is filled with the same elements every time and thus unimportant.
    private static void removeTail(List<String> upper, List<String> lower) {
        int offUpper = upper.size() - 1;
        int offLower = lower.size() - 1;
        String saveOne = null;
        while (offUpper > 0 && offLower > 0 && upper.get(offUpper).equals(lower.get(offLower))) {
            saveOne = upper.get(offUpper);
            upper.remove(offUpper);
            offUpper--;
            offLower--;
        }
        if (saveOne != null) {
            // retain the last removed string, the point in common on the traces
            upper.add(saveOne);
        }
    }

    public static void failWhen(boolean condition, String msg, Object... params) {
        if (condition) {
            throw WeaverException.newBasic(msg, params);
        }
    }

    public static boolean containsMessage(Throwable ex, String string) {
        Throwable runner = ex;
        while (runner != null) {
            String msg = runner.getMessage();
            if (msg == null || msg.isEmpty()) {
                msg = runner.toString();
            }
            if (msg.contains(string)) {
                return true;
            }
            runner = runner.getCause();
        }
        return false;
    }

    public static void traceException(PrintStream out, Throwable ex, String msg) {
        out.println(msg + "\n" + getJsonForLog(ex));
    }

    public static void traceException(Writer w, Throwable ex, String msg) {
        try {
            w.write(msg + "\n" + getJsonForLog(ex) + "\n");
        } catch (Exception e) {
            // should never get here, and if it does, there seems little that can be done.
            // this method is for logging exceptions, and if it fails, we just print to stdout and hope for the best.
            System.out.println("ERROR WRITING EXCEPTION TO WRITER: " + e.toString());
            System.out.println("ORIGINAL EXCEPTION: " + msg + "\n" + getJsonForLog(ex));
        }
    }
}
