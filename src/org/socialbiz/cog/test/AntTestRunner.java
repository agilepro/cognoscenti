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
import java.io.File;

import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.ProjectHelper;
import org.socialbiz.cog.exception.NGException;


 class AntTestRunner {

    private Project cognoscenti;

    public void init(String _buildFile, String _baseDir) throws Exception {
        cognoscenti = new Project();
        try {
            cognoscenti.init();
        } catch (BuildException e) {
            throw new NGException("nugen.exception.task.list.not.loaded",null,e);
        }
        // Set the base directory. If none is given, "." is used.
        if (_baseDir == null) {
            _baseDir = new String(".");
        }
        try {
            cognoscenti.setBasedir(_baseDir);
        } catch (BuildException e) {
            throw new NGException("nugen.exception.basedir.not.exist",null,e);
        }
        if (_buildFile == null) {
            _buildFile = new String("a.xml");
        }
        try {

            ProjectHelper.getProjectHelper().parse(cognoscenti,
                    new File(_baseDir+_buildFile));
        } catch (BuildException e) {
            throw new NGException("nugen.exception.config.file.invalid",new Object[]{_buildFile},e);
        }
    }

    public void runTarget(String _target) throws Exception {
        // Test if the project exists
        if (cognoscenti == null) {
            throw new NGException("nugen.exception.no.target.launched",null);
        }
        // If no target is specified, run the default one.
        if (_target == null) {
            _target = cognoscenti.getDefaultTarget();
        }
        // Run the target
        try {
            cognoscenti.executeTarget(_target);
        } catch (Exception e) {
            throw new NGException("nugen.exception.cant.execute.target", new Object[]{_target}, e);
        }
    }

    public static void main(String[] args) {

        try {
            AntTestRunner unitTest = new AntTestRunner();
            unitTest.init("ReadOnlyModeTestsFile.xml", "./My Test Suite/");
            unitTest.runTarget("main");
        } catch (Exception e) {
            e.printStackTrace();
        }
    }


}
