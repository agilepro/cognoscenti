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

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.Writer;
import java.net.URLEncoder;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Vector;

import javax.servlet.http.HttpSession;

import com.purplehillsbooks.weaver.exception.ProgramLogicError;

import com.purplehillsbooks.streams.HTMLWriter;

public class UtilityMethods {
    public static String subString(String s, int pos, int len) throws Exception {
        try {
            return s.substring(pos, len);
        }
        catch (Exception e) {
            throw new ProgramLogicError("Substring exception: [" + s + "] (len " + s.length()
                    + ") at " + pos + " for len " + len + "; " + e.getMessage());
        }
    }

    /**
     * Split a string into an array.
     * This method NEVER returns a null.
     * If passed a null, or a zero length string, it returns an empty array
     *
     * @deprecated use {@link #splitString(String, char)} instead
     */
    static public String[] splitOnDelimiter(String str, char delim) {
        List<String> vec = splitString(str, delim);
        String[] result = new String[vec.size()];
        for (int i = 0; i < vec.size(); i++) {
            result[i] = (vec.get(i));
        }
        return result;
    }

    /**
     * Proper split string.
     * Returns a Vector (list) of string
     * Never returns a null, but will accept a null
     * Does not ever return a zero-length string.
     * Trims the string values of space next to delimiter
     * For example the results from splitString(val, ",")
     * <pre>
     *   "a,b,c"    gives   ["a","b","c"]
     *   "a,b,c,"   gives   ["a","b","c"]
     *   "a , b ,c" gives   ["a","b","c"]
     *   "a,,c"     gives   ["a","c"]
     *   "a,   ,c"  gives   ["a","c"]
     *   ",b,c"     gives   ["b","c"]
     *   ""         gives   []
     *   "     "    gives   []
     *   ","        gives   []
     * </pre>
     */
    static public List<String> splitString(String str, char delim) {
        ArrayList<String> vec = new ArrayList<String>();
        if (str==null) {
            return vec;
        }
        int pos = str.indexOf(delim);
        int start = 0;
        while (pos > start) {
            String val = str.substring(start, pos).trim();
            if (val.length()>0) {
                //might only be spaces, so only add after trim
                vec.add(val);
            }
            start = pos+1;
            pos = str.indexOf(delim, start);
        }
        if (start<str.length()) {
            String val = str.substring(start).trim();
            if (val.length()>0) {
                //might only be spaces, so only add after trim
                vec.add(val);
            }
        }
        return vec;
    }

    /**
     * Joins a vector of strings into a comma delimited list of values Make sure
     * this is done on sets of strings that do not have commas in them!
     */
    static public String joinStrings(List<String> strSet) {
        StringBuilder res = new StringBuilder();
        boolean needsComma = false;
        for (String val : strSet) {
            if (needsComma) {
                res.append(", ");
            }
            res.append(val);
            needsComma = true;
        }
        return res.toString();
    }

    /**
     * @deprecated use HTMLWriter.writeHtml() instead
     */
    public static void writeHtml(Writer out, String t) throws Exception {
        HTMLWriter.writeHtml(out, t);
    }

    public static void writeURLData(Writer w, String data) throws Exception {
        // avoid NPE.
        if (data == null || data.length() == 0) {
            return;
        }

        String encoded = URLEncoder.encode(data, "UTF-8");

        // here is the problem: URL encoding says that spaces can be encoded
        // using
        // a plus (+) character. But, strangely, sometimes this does not work,
        // either
        // in certain combinations of browser / tomcat version, using the plus
        // as a
        // space character does not WORK because the plus is not removed by
        // Tomcat
        // on the other side.
        //
        // Strangely, %20 will work, so we replace all occurrances of plus with
        // %20.
        //
        // I am not sure where the problem is, but if you see a URL with plus
        // symbols
        // in mozilla, and the same URL with %20, they look different. The %20
        // is
        // replaced with spaces in the status bar, but the plus is not.
        //
        int plusPos = encoded.indexOf("+");
        int startPos = 0;
        while (plusPos >= startPos) {
            if (plusPos > startPos) {
                // third parameter is length of span, not end character
                w.write(encoded, startPos, plusPos - startPos);
            }
            w.write("%20");
            startPos = plusPos + 1;
            plusPos = encoded.indexOf("+", startPos);
        }
        int last = encoded.length();
        if (startPos < last) {
            // third parameter is length of span, not end character
            w.write(encoded, startPos, last - startPos);
        }
    }

    public static void writeHtmlWithLines(Writer out, String t) throws Exception {
        if (t == null) {
            return; // treat it like an empty string
        }
        for (int i = 0; i < t.length(); i++) {

            char c = t.charAt(i);
            switch (c) {
            case '&':
                out.write("&amp;");
                continue;
            case '<':
                out.write("&lt;");
                continue;
            case '>':
                out.write("&gt;");
                continue;
            case '"':
                out.write("&quot;");
                continue;
            case '\n':
                out.write("<br/>\n");
                continue;
            default:
                out.write(c);
                continue;
            }

        }
    }

    public static String getSessionString(HttpSession session, String paramName, String defaultValue) {
        String val = (String) session.getAttribute(paramName);
        if (val == null) {
            session.setAttribute(paramName, defaultValue);
            return defaultValue;
        }
        return val;
    }

    public static int getSessionInt(HttpSession session, String paramName, int defaultValue) {
        Integer val = (Integer) session.getAttribute(paramName);
        if (val == null) {
            session.setAttribute(paramName, new Integer(defaultValue));
            return defaultValue;
        }
        return val.intValue();
    }

    public static void setSessionInt(HttpSession session, String paramName, int val) {
        session.setAttribute(paramName, new Integer(val));
    }

    public static String getXMLDateFormat(long ms) {
        if (ms <= 0) {
            return "";
        }
        SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'");
        Date dt = new Date(ms);
        return sdf.format(dt);
    }

    public static long getDateTimeFromXML(String date) throws Exception {
        if (date == null) {
            return 0;
        }
        if (date.trim().equals("")) {
            return 0;
        }
        SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'");
        return sdf.parse(date).getTime();
    }

    static char[] hexchars = { '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C',
            'D', 'E', 'F' };
    static int[] hexvalue = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 3,
            4, 5, 6, 7, 8, 9, 0, 0, 0, 0, 0, 0, 0, 10, 11, 12, 13, 14, 15, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 10, 11, 12, 13, 14, 15, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };

    /**
     * Encodes a single <code>String</code> value to a JavaScript literal
     * expression.
     *
     * <p>
     * If you are constructing a JavaScript expression and you have a String
     * value that you want to be expressed as a String literal in the
     * JavaScript, you must use this method to scan the String and convert any
     * embedded problematic characters into their escaped equivalents. The
     * result of the conversion is written into the String buffer that you pass
     * in. This routine also adds start and end quotes.
     * </p>
     *
     * <p>
     * <b>Do NOT simply paste quotes before and after the string!</b>
     * </p>
     *
     * @param res
     *            The <code>StringBuilder</code> object to which the encoded
     *            String value is added.
     * @param val
     *            The <code>String</code> value to encode.
     * @return The JavaScript literal expression encoded from the supplied
     *         value.
     */
    public static void quote4JS(StringBuilder res, String val) {
        // passing a null in results a no output, no quotes, nothing
        if ((val == null) || (res == null)) {
            return;
        }
        int len = val.length();
        int startPos = 0;
        String trans = null;
        res.append("\"");
        for (int i = 0; i < len; i++) {
            char ch = val.charAt(i);
            switch (ch) {
            case '\"':
                trans = "\\\"";
                break;
            case '\\':
                trans = "\\\\";
                break;
            case '\'':
                trans = "\\\'";
                break;
            case '\n':
                trans = "\\n";
                break;
            case '\t':
                trans = "\\t";
                break;
            case '\r':
                trans = "\\r";
                break;
            case '\f':
                trans = "\\f";
                break;
            case '\b':
                trans = "\\b";
                break;
            default:
                if (ch < 128) {
                    continue;
                }
                if (ch < 256) {
                    char firstHex = hexchars[(ch / 16) % 16];
                    char secondHex = hexchars[ch % 16];
                    trans = "\\x" + firstHex + secondHex;
                }
                else {
                    char firstHex = hexchars[(ch / 4096) % 16];
                    char secondHex = hexchars[(ch / 256) % 16];
                    char thirdHex = hexchars[(ch / 16) % 16];
                    char fourthHex = hexchars[ch % 16];
                    trans = "\\u" + firstHex + secondHex + thirdHex + fourthHex;
                }
            }
            if (trans != null) {
                if (i > startPos) {
                    res.append(val.substring(startPos, i));
                }
                res.append(trans);
                startPos = i + 1;
                trans = null;
            }
        }
        // now write out whatever is left
        if (len > startPos) {
            res.append(val.substring(startPos));
        }
        res.append("\"");
    }

    /**
     * Takes a single JavaScript literal and converts it back to a String value,
     * removing the start and end quotes, and then converting any backslash
     * escaped value into its actual value.
     *
     * <p>
     * Note: This method does not recognize the terminating quote in any
     * position except the last. It allows characters in the String that
     * JavaScript will not allow. This means you can "trick" this conversion by
     * passing an invalid literal, such as:
     * </p>
     *
     * <table>
     * <tr>
     * <td>"abc" + "def"</td>
     * <td>(this is an expression not a single literal)</td>
     * </tr>
     * <tr>
     * <td>"abc</td>
     * <td></td>
     * </tr>
     * <tr>
     * <td>def"</td>
     * <td>(invalid line end in literal not detected)</td>
     * </tr>
     * <tr>
     * <td>"abc"def"</td>
     * <td>(invalid quote in middle not detected)</td>
     * </tr>
     * </table>
     *
     * @param res
     *            The <code>StringBuilder</code> object to which the converted
     *            literalString is added.
     * @param literalString
     *            The JavaScript literal to be converted.
     * @return The String value generated from the supplied JavaScript literal.
     * @exception Exception
     *                Thrown if the supplied <em>literalString</em> value is
     *                empty, <code>null</code> or not surrounded by double
     *                quotes. Furthermore this exception is thrown if the
     *                supplied <em>res</em> value is null.
     */
    public static void unquote4JS(StringBuilder res, String literalString) throws Exception {
        if ((res == null) || (literalString == null)) {
            throw new ProgramLogicError("null parameter passed to unquote4JS");
        }
        if (literalString.length() == 0) {
            throw new ProgramLogicError("Empty string was passed to unquote4JS");
        }
        if ((literalString.charAt(0) != '\"')
                || (literalString.charAt(literalString.length() - 1) != '\"')) {
            throw new ProgramLogicError(
                    "Literal expression passed to unquote4JS must start and end with a quote character");
        }
        int lenMinusTwo = literalString.length() - 2;
        int startPos = 1;
        int pos = 0;
        while (pos < lenMinusTwo) {
            pos++;
            char ch = literalString.charAt(pos);
            if (ch != '\\') {
                continue; // skip over normal characters
            }

            // ok, we got a slash, check the next character, but first check an
            // error condition
            if (pos >= lenMinusTwo) {
                throw new ProgramLogicError(
                        "Error decoding a JS expression, the last character is a backslash");
            }

            // are there any normal characters to copy that we skipped over
            if (pos > startPos) {
                res.append(literalString.substring(startPos, pos));
            }
            pos++;
            ch = literalString.charAt(pos);

            // convert to the coded value. Quote and slash don't need this
            // conversion
            switch (ch) {
            case 'n':
                ch = '\n';
                break;
            case 't':
                ch = '\t';
                break;
            case 'r':
                ch = '\r';
                break;
            case 'f':
                ch = '\f';
                break;
            case 'b':
                ch = '\b';
                break;
            case 'x':
                int i1 = hexvalue[literalString.charAt(++pos)];
                int i2 = hexvalue[literalString.charAt(++pos)];
                ch = (char) (i1 * 16 + i2);
                break;
            case 'u':
                int u1 = hexvalue[literalString.charAt(++pos)];
                int u2 = hexvalue[literalString.charAt(++pos)];
                int u3 = hexvalue[literalString.charAt(++pos)];
                int u4 = hexvalue[literalString.charAt(++pos)];
                ch = (char) (u1 * 4096 + u2 * 256 + u3 * 16 + u4);
                break;
            }
            res.append(ch);
            startPos = pos + 1;
        }
        // now write out whatever is left of normal characters skipped, except
        // not the final quote!
        if (startPos <= lenMinusTwo) {
            res.append(literalString.substring(startPos, lenMinusTwo + 1));
        }
    }

    /**
     * Encodes a single <code>String</code> value to a JavaScript literal
     * expression.
     *
     * @param val
     *            The <code>String</code> value to encode.
     * @return The JavaScript literal expression encoded from the supplied
     *         value.
     */
    public static String quote4JS(String val) {
        StringBuilder sb = new StringBuilder();
        quote4JS(sb, val);
        return sb.toString();
    }

    /**
     * Converts a single JavaScript literal back to a String value.
     *
     * <p>
     * The conversion starts with removing the start and end quotes and then
     * converting any backslash escaped value into its actual value.
     * </p>
     *
     * <p>
     * Note: This method does not recognize the terminating quote in any
     * position except the last. It allows characters in the String that
     * <code>JavaScript</code> will not allow. This means you can "trick" this
     * conversion by passing an invalid literal, such as:
     * </p>
     *
     * <table>
     * <tr>
     * <td>"abc" + "def"</td>
     * <td>(this is an expression not a single literal)</td>
     * </tr>
     * <tr>
     * <td>"abc</td>
     * <td></td>
     * </tr>
     * <tr>
     * <td>def"</td>
     * <td>(invalid line end in literal not detected)</td>
     * </tr>
     * <tr>
     * <td>"abc"def"</td>
     * <td>(invalid quote in middle not detected)</td>
     * </tr>
     * </table>
     *
     * @param val
     *            The JavaScript literal to be converted.
     * @return The String value generated from the supplied JavaScript literal.
     * @exception Exception
     *                Thrown if the supplied value is not surrounded by double
     *                quotes or if the value is <code>null</code>.
     */
    public static String unquote4JS(String val) throws Exception {
        StringBuilder sb = new StringBuilder();
        unquote4JS(sb, val);
        return sb.toString();
    }

    /**
     * This method is to calculate duration between two time periods and return
     * value in number of days.
     *
     * @param newTime
     * @param existingTime
     * @return
     */
    public static long getDurationInDays(long newTime, long existingTime) {
        long timeInterval = newTime - existingTime;
        return timeInterval / (24L * 60 * 60 * 1000);
    }

    public static void copyFileContents(File source, File dest) throws Exception {
        if (dest.exists()) {
            dest.delete();
        }
        FileOutputStream fos = new FileOutputStream(dest);
        streamFileContents(source, fos);
        fos.close();
    }

    public static void streamFileContents(File source, OutputStream os) throws Exception {
        FileInputStream fis = new FileInputStream(source);
        streamToStream(fis,os);
        fis.close();
    }

    public static void streamToStream(InputStream fis, OutputStream os) throws Exception {
        byte[] buf = new byte[6000];
        int amt = fis.read(buf);
        while (amt > 0) {
            os.write(buf, 0, amt);
            amt = fis.read(buf);
        }
        os.flush();
    }

}