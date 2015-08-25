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

import java.util.ArrayList;
import java.util.List;

import org.apache.log4j.Level;
import org.apache.log4j.Logger;
import org.w3c.tidy.TidyMessage;
import org.w3c.tidy.TidyMessageListener;

/**
 * Listens to the validation errors.
 */
class TidyErrorsListener implements TidyMessageListener {

    private Logger log = Logger
            .getLogger("org.socialbiz.cog.test.TidyErrorListener");

    /**
     * The list of errors received from the validator.
     *
     * It is never null.
     */
    public List<TidyMessage> errors = new ArrayList<TidyMessage>();

    public boolean collectMessages = false;

    private int parseErrors;

    private int parseWarnings;

    private String htmlResult;

    private String report;

    private List<?> messages;

    /**
     * Called by tidy when a warning or error occurs.
     *
     * @param message
     *            The error/warning message. It cannot be null.
     */
    public void messageReceived(TidyMessage aMessage) {

        if (aMessage.getLevel().equals(org.w3c.tidy.TidyMessage.Level.ERROR)) {
            errors.add(aMessage);
        } else {
            log.log(Level.WARN, aMessage.getMessage());
        }

    }

    /**
     * Indicates if the filter found validation errors.
     *
     * @return true if there were validation errors.
     */
    public boolean hasErrors() {
        return !errors.isEmpty();
    }

    /**
     * Formats all the errors received into a string.
     *
     * @return The errors as a string, never returns null.
     */
    public String getErrorMessage() {
        StringBuilder output = new StringBuilder();
        for (TidyMessage message : errors) {
            output.append("line ").append(message.getLine()).append(" column ")
                    .append(message.getColumn()).append(" - ").append(
                            message.getLevel()).append(": ").append(
                            message.getMessage()).append("\n");
        }
        return output.toString();
    }

    /**
     * @return Returns the parseErrors.
     */
    public int getParseErrors() {
        return parseErrors;
    }

    /**
     * @param parseErrors
     *            The parseErrors to set.
     */
    public void setParseErrors(int parseErrors) {
        this.parseErrors = parseErrors;
    }

    /**
     * @return Returns the parseWarnings.
     */
    public int getParseWarnings() {
        return parseWarnings;
    }

    /**
     * @param parseWarnings
     *            The parseWarnings to set.
     */
    public void setParseWarnings(int parseWarnings) {
        this.parseWarnings = parseWarnings;
    }

    /**
     * @return Returns the report.
     */
    public String getReport() {
        return report;
    }

    /**
     * @param report
     *            The report to set.
     */
    public void setReport(String report) {
        this.report = report;
    }

    /**
     * @return Returns the messages.
     */
    public List<?> getMessages() {
        return messages;
    }

    /**
     * @return Returns the htmlResult.
     */
    public String getHtmlOutput() {
        return htmlResult;
    }

    /**
     * @param html
     *            The htmlResult to set.
     */
    public void setHtmlOutput(String html) {
        this.htmlResult = html;
    }

}
