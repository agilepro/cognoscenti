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

package org.socialbiz.cog.spring;

import java.util.ArrayList;
import java.util.List;

import org.w3c.tidy.TidyMessage;
import org.w3c.tidy.TidyMessageListener;



public class JTidyListener implements TidyMessageListener {

    static int count = 0;
    private List<XHTMLError> errorsNWarnings = new ArrayList<XHTMLError>();

    public void messageReceived(TidyMessage msg) {
        count++;
        XHTMLError error = new XHTMLError();
        error.setColumn(msg.getColumn());
        // dom is stripping the DOCTYPE line so in order to correct the line
        // no., subtract 1
        error.setLine(msg.getLine() - 1);
        error.setErrorMessage(msg.getMessage());
        String errorType = msg.getLevel().toString();
        error.setErrorType(errorType);
        errorsNWarnings.add(error);
    }

    public List<XHTMLError> getXHTMLErrors() {
        // dom is stripping the DOCTYPE line remove the first error
        if(errorsNWarnings.size()<2){
            return errorsNWarnings;
        }
       return errorsNWarnings.subList(1, errorsNWarnings.size());
    }

    public int getAllErrorCount() {
        return count;
    }

}
