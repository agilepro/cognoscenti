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

import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.Task;


public class JUnitTestSuiteTask extends Task {

    /*
     * (non-Javadoc)
     *
     * @see org.apache.tools.ant.Task#execute()
     */
    public void execute() throws BuildException {

        try {
            Project project = this.getProject();


            ConTestEnvironment
                    .setGlobal("basedir", project.getProperty("basedir"));

            // set admin user name and password in global variable
            // which can be used later on when test case param does not have
            // these values
            ConTestEnvironment.setGlobal("adminuser", project
                    .getProperty("adminuser"));
            ConTestEnvironment.setGlobal("adminpassword", project
                    .getProperty("adminpassword"));

            // set user name and password in global variable
            // which can be used later on when test case param does not have
            // these values
            ConTestEnvironment.setGlobal("cognosecntiuser", project
                    .getProperty("user"));
            ConTestEnvironment.setGlobal("password", project
                    .getProperty("userpassword"));

        } catch (Exception ex) {
            throw new BuildException("property not set",ex);

        }

    }

    public void setProperty(String property) {
    }



}