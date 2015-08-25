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

import java.io.StringReader;
import java.io.Writer;
import java.util.List;

import org.w3c.tidy.Tidy;



public class JTidyValidator {

    private static final Tidy tidy = new Tidy();
    private static Writer w =null;

    static {
        tidy.setQuiet(true);
        tidy.setShowWarnings(true);
        tidy.setOnlyErrors(true);
        tidy.setXHTML(true);
        // tidy.setXmlTags(true);
        tidy.setXmlOut(true);
        //tidy.setForceOutput(true);
    }


    public List<XHTMLError> getXHTMLErrors(String dom, String errorFileName)
            throws Exception {
        List<XHTMLError> errors = getXHTMLErrors(dom);
        return errors;
    }

    /*
    private void writeErrors(List<XHTMLError> errors, String errorFileName) throws IOException {

        for (XHTMLError error : errors) {
            w.write("Line : ");

            w.write(error.getLine());
            w.write(" Column : ");
            w.write(error.getColumn());
            w.write(" - ");
            w.write(error.getErrorMessage());
            w.write("\n");
        }
        w.write("\n\n\t Total Error on this Page = " + errors.size());
    }
    */

    public List<XHTMLError> getXHTMLErrors(String dom) throws Exception {
        // tidy.setErrout(new PrintWriter(new FileWriter("error.txt"), true));
        JTidyListener jTidyListener = new JTidyListener();
        tidy.setMessageListener(jTidyListener);
        StringReader reader = new StringReader(dom);
        tidy.parseDOM(reader, w);
        return jTidyListener.getXHTMLErrors();
    }

    public List<XHTMLError> validate(String dom, Writer out) throws Exception {
        w = out;
        return getXHTMLErrors(dom,"test.output");

    }

}
