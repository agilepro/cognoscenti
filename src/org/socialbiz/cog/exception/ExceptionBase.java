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

import java.math.BigDecimal;
import java.text.DateFormat;
import java.text.DecimalFormat;
import java.text.NumberFormat;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.HashMap;
import java.util.Locale;
import java.util.MissingResourceException;
import java.util.ResourceBundle;

/**
 * This is an abstract base class for all exception classes that provide translateable
 * exception messages.
 *
 * Usage: create a subclass of ExceptionBase for every resource bundle of translatable
 * exception messages that you expect to use.   If all of your exception messages are in
 * a single resource bundle, then you need only one exception class.  If you are working
 * on three different modules that can all be installed separately, and have separate
 * resource bundles, then make three subclasses.
 *
 * In the subclass, you need only implement the constructor (like this one) and you
 * must implement the method "resourceBundleName".   This method returns the string
 * name of the resource bundle.
 *
 * If you wish to define a bunch of constant exception key string values, you may do that
 * in the subclass as well.  Use of Java constants is not really necessary, since the
 * resource bundle lists all of the valid values that can be used, and serves as a
 * registry of all the valid values.  Use of such constants is generally discouraged
 * because it increases the maintenance cost of the code, without significantly improving
 * quality or reliability.
 */
public class ExceptionBase extends Exception {


    /**
     * Constructs a ExceptionBase for the given property key and parameters.
     *
     * @param _propertyKey
     *            The property key to get the human readable text for
     *            from the resource bundle.   This property key should
     *            a short, technical, description of the problem.  It
     *            does not replace the English final message, but it should
     *            be similar to it.
     * @param _params
     *            An array of objects (usually strings) which provide specific
     *            information about the situation of the exception, and will be
     *            substituted into the error message.
     */
    public ExceptionBase(String _propertyKey, Object[] _params) {
        super();
        propertyKey = _propertyKey;
        params      = _params;
        initializeResourceBundle();
    }

    synchronized private static void initializeResourceBundle() {
        if (ibpmResourceBundles == null) {
            ibpmResourceBundles = new HashMap<String, ResourceBundle>();
        }
    }

    /**
     * Constructs a ExceptionBase for the given property key and parameters.
     *
     * @param propertyKey
     *            The property key to get the human readable text for
     *            from the resource bundle.   This property key should
     *            a short, technical, description of the problem.  It
     *            does not replace the English final message, but it should
     *            be similar to it.
     * @param _params
     *            An array of objects (usually strings) which provide specific
     *            information about the situation of the exception, and will be
     *            substituted into the error message.
     * @param e
     *            The wrapped exception that caused this exception.
     */
    public ExceptionBase(String _propertyKey, Object[] _params, Exception e) {
        super(e);
        propertyKey = _propertyKey;
        params      = _params;
        initializeResourceBundle();
    }


    /**
     * Avoid using this!
     * Return a string representation of this exception in the default locale of
     * the environment where this is running.  When constructing an internet
     * application, you normally want to use the locale of the client browser,
     * not the locale of the server that the code is running on.  Therefor is
     * is important that you use toString(Locale) method to get the message.
     * But, this method must be there because all exceptions have this method.
     *
     * @return The exception information.
     */
    public String toString() {
        return toString(null);
    }

    /**
     * Return the human readable representation of this exception in the locale
     * specified. This is the preferred way to get the message.
     *
     * @param locale
     *            The Locale to be used for getting the human readable message.
     */
    public String toString(Locale locale) {
        return fillTemplate(getTemplate(locale), locale);
    }


    /**
     * Return the name of the resource bundle used by this class.
     * This method should be reimplemented by every subclass in order
     * that the subclass can retrieve error messages from its own
     * resource bundle.
     */
    protected  String resourceBundleName() {
        return "BaseErrorMessage";
    }


    //--------------------------PRIVATE---------------------------------//
    private static final long serialVersionUID = 1L;
    private final static String DEFAULT_DATE_FORMAT = "EEE MMM dd HH:mm:ss zzz yyyy";

    /**
     * There are exactly two resource bundles which this class will represent.
     * Some of the methods take a boolean parameter to select between these two
     * bundles. A much cleaner implementation would use two of these classes,
     * with each class representing a different bundle, because then you would
     * not need to pass the boolean into each call to select between the two. A
     * far better approach is to have the GUIException class maintain its own
     * resource bundle, and not call this class at all. But this implementation
     * is hereby forced to be far more complex than it needs to be.
     *
     * List of resource bundles identified by the locale they belong to. The key
     * of the hashmap is the locale. The value related value is a list (
     * <code>Vector</code>) of resource bundles that are available for the
     * locale.
     */
    private static HashMap<String, ResourceBundle> ibpmResourceBundles = null;

    /**
     * The properties key used to access the Resource bundle to get the human
     * readable text of this exception.  Every exception object has a single
     * key value, which is set at construction time, and can not be changed
     * after that.
     */
    private String propertyKey;

    /**
     * List of parameters that will be inserted into the error message.
     */
    private Object[] params;


    /**
     * Returns the human readable text for the property key (or error code) of
     * this exception object.
     *
     * @param locale
     *            The locale to be used to get the human readable text.
     * @return The String representation of the property key or error code
     */
    private String getTemplate(Locale locale) {
        return getString(propertyKey, locale);
    }

    /**
     * Core of getMessage(). Returns the text form of the message, substituting
     * in the data parameter values into the appropriate places in the specified
     * template. Can be called from subclasses which may provide the template
     * from a source other than the "Errormessage.properties" resource bundle.
     *
     * @param template
     *            The error message to be displayed that can containe
     *            placeholders for the parameters or causing exception.
     * @param locale
     *            The locale that was used to get the template.
     * @param withoutCause
     *            <code>true</code> if the causing exception shall not be added
     *            to the error message; <code>false</code> otherwise.
     *            Independent of this flag, the causing exception is added to
     *            the error message if the template contains a placeholer for
     *            the exception.
     * @return The String generated from the given template and the parameters
     *         associated with this exception.
     */
    private String fillTemplate(String template, Locale locale) {
        StringBuffer res = new StringBuffer();
        boolean used[] = null;
        if (params != null) {
            used = new boolean[params.length];
        }
        String errMsg = "";

        // Add the template to the result string.
        if (template != null && template.length() > 0) {
            int pos = 0;
            while (pos < template.length()) {
                int newPos = template.indexOf("<$", pos);

                if (newPos < 0) {
                    break;
                }

                res.append(template.substring(pos, newPos));
                pos = newPos + 2;

                newPos = template.indexOf(">", pos);
                if (newPos < 0) {
                    break;
                }

                String token = template.substring(pos, newPos);
                pos = newPos + 1;

                // handle the <$e> token
                if (token.equals("e")) {
                    res.append(getCauseMessage(locale));

                } else {
                    int i = intValue(token);
                    if (params != null && i < params.length
                            && params[i] != null) {
                        res.append(getParamText(i, locale));
                        used[i] = true;

                    } else {
                        res.append("(!)");
                    }
                }
            }

            // bring the 'rest' of the template along
            errMsg = template.substring(pos);
            res.append(errMsg);
        }

        // now check to make sure that all the params are present
        // in the displayed message. Add them to the end if not.
        // Only first 16 are significant.
        if (params != null) {
            int size = params.length;
            for (int i = 0; i < size; i++) {
                if (used[i] == false && params[i] != null) {
                    if (!params[i].equals(errMsg)) {
                        res.append(" (");
                        res.append(getParamText(i, locale));
                        res.append(")");
                    }
                }
            }
        }
        return res.toString();
    }

    /**
     * converts a string to the 'best' int, without ever throwing any
     * exceptions, because we do not want any exceptions flying out of our
     * routines that are displaying exceptions.
     *
     */
    private static int intValue(String token) {
        int pos = 0;
        int val = 0;
        while (pos < token.length()) {
            char ch = token.charAt(pos);
            if (ch >= '0' && ch <= '9') {
                val = val * 10 + (ch) - 48;
            }
            pos++;
        }
        return val;
    }

    private String getCauseMessage(Locale locale) {
        String message = null;
        Throwable causeExc = getCause();
        if (causeExc != null) {
            if (causeExc instanceof ExceptionBase) {
                ExceptionBase me = (ExceptionBase) causeExc;
                message = me.toString(locale);
            } else {
                // this MUST be "toString" because we don't know anything
                // about this exception. The JDK guildelines clearly say that
                // "getMessage" returns not the description of the exception,
                // but only the optional details about the message.
                message = causeExc.toString();
            }
        }

        if (message == null) {
            message = "";
        }
        return message;
    }

    /**
     * Returns the parameter value at the specified index.
     *
     * @param index
     *            The index of the parameter to be returned.
     * @return The parameter indicated by the given index.
     */
    private Object getParamObj(int index) {
        if (params == null || index < 0 || index >= params.length) {
            return null;
        } else {
            return params[index];
        }
    }

    private String getParamText(int index, Locale locale) {
        String text = null;
        Object o = getParamObj(index);

        if (o == null) {
            text = null;
        } else if (o instanceof Date) {
            text = getFormattedDate((Date) o, locale);
        } else if (o instanceof Long) {
            text = getFormattedNumber((Long) o, locale);
        } else if (o instanceof Integer) {
            text = getFormattedNumber((Integer) o, locale);
        } else if (o instanceof BigDecimal) {
            text = getFormattedDecimal((BigDecimal) o, locale);
        } else if (o instanceof Float) {
            text = getFormattedDecimal((Float) o, locale);
        } else {
            text = o.toString();
            //
            // Note: This code USED to attempt to localize each of the parameters
            // to the exception message.  This allows you to *build* a message
            // from a number of pieces that are all separately translated.
            // However, this is highly controversial.  Not all languages can be
            // composed the same way.  If you have a message with 5 specializations,
            // it is probably better to make 5 messages.  This is not always true,
            // and there is a need for some sort of status code which is translated.
            //
            // Attempting to translate all string parameters is overkill, and
            // causes needless warning messages in the log.  The warning messages are
            // useful to notify people of a missing resource.
            //
            // In conclusion, if you want a translatable resource, it should be
            // placed inside a class that can be recognized here, or it should have a
            // specific, unambiguous signature that can be easily detected.
            // We should not attempt to translate every parameter to every exception.
        }
        return text;
    }

    private String getFormattedNumber(Integer number, Locale locale) {
        return getFormattedNumber(new Long(number.intValue()), locale);
    }

    private String getFormattedNumber(Long number, Locale locale) {
        String text = null;
        if (number != null) {
            if (locale == null) {
                locale = Locale.getDefault();
            }
            NumberFormat nf = NumberFormat.getInstance(locale);
            text = nf.format(number.longValue());
        }
        return text;
    }

    private String getFormattedDecimal(BigDecimal decimal, Locale locale) {
        String text = null;
        if (decimal != null) {
            if (locale == null) {
                locale = Locale.getDefault();
            }
            NumberFormat nf = DecimalFormat.getInstance(locale);
            text = nf.format(decimal);
        }
        return text;
    }

    private String getFormattedDecimal(Float decimal, Locale locale) {
        String text = null;
        if (decimal != null) {
            if (locale == null) {
                locale = Locale.getDefault();
            }
            NumberFormat nf = DecimalFormat.getInstance(locale);
            text = nf.format(decimal.floatValue());
        }
        return text;
    }

    private String getFormattedDate(Date date, Locale locale) {
        String text = null;

        if (date != null) {
            if (locale == null) {
                locale = Locale.getDefault();
            }
            DateFormat df = new SimpleDateFormat(DEFAULT_DATE_FORMAT, locale);
            text = df.format(date);
        }
        return text;
    }

    /**
     * Returns the customer resource bundle or the ibpm specifiy bundle for the
     * specified locale. Internally, first it is checked if the bundle was
     * already loaded, if yes the stored one is returned. If the bundle was not
     * loaded until yet, this will be done automatically and added to the
     * internal storage.
     *
     * @param locale
     *            The locale for which the bundle shall be loaded
     * @return The customer specific or ibpm specific resource bundle for the
     *         specified locale.
     */
    private  ResourceBundle getResourceBundle(Locale locale) {
        ResourceBundle bundle = null;

        String bundleName = resourceBundleName();
        String bundleKey = bundleName+"_"+locale.getLanguage();
        if(ibpmResourceBundles != null && ibpmResourceBundles.containsKey(bundleKey)){
            bundle = ibpmResourceBundles.get(bundleKey);
        }

        if (bundle == null) {
            // the resource bundle for the specified locale was not loaded
            // yet, so load it now and add it to the cache
            try {
                bundle = ResourceBundle.getBundle(bundleName, locale);
                ibpmResourceBundles.put(bundleKey, bundle);
            } catch (MissingResourceException mre) {
                throw new RuntimeException("getResourceBundle: "
                        + "Failed to load resource bundle '"
                        + bundleName + "' for locale '" + locale.getDisplayName() + "'.  ",mre);
            }
        }
        return bundle;
    }

    /**
     * Returns the value of the text from the resource bundle associated with
     * the supplied property key, or the property key itself if there is no
     * entry in the resource bundle for that key for that locale.
     *
     * @param propKey
     *            Name of property to be returned.
     * @param locale
     *            Locale for which the value shall be returned.
     */
    protected  String getString(String propKey, Locale locale) {

        //the key itself is the default message
        String propValue = propKey;

        if (locale == null) {
            locale = Locale.getDefault();
        }
        try {
            ResourceBundle resourceBundle = getResourceBundle(locale);
            if (resourceBundle != null) {
                propValue = resourceBundle.getString(propKey);
            }
        }
        catch (Exception e) {
            // Here, there is a possibility that the exception occurs.
            // However, this exception is ignored, and the default
            // value of propKey is used.  This warnign printed to the log.
            System.out.println("Unable to find a text resource with the key ["
                  +propKey+"], using the untranslated key directly instead.  "
                  +"Perhaps the resource bundle is missing some entries? -- " + e.getMessage());
        }
        return propValue;
    }

}
