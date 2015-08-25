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
 * limitations under the License.package org.socialbiz.cog.dms;
 *
 * Contributors Include: Shamim Quader, Sameer Pradhan, Kumar Raja, Jim Farris,
 * Sandia Yang, CY Chen, Rajiv Onat, Neal Wang, Dennis Tam, Shikha Srivastava,
 * Anamika Chaudhari, Ajay Kakkar, Rajeev Rastogi
 */

package org.socialbiz.cog.dms;

public class CVSConfig {
    private String root;
    private String repository;
    private String sandbox;

    public static String ATT_CVS_ROOT = "cvsRoot";
    public static String ATT_CVS_MODULE ="cvsModule";


    public CVSConfig(String root, String repository, String sandbox){
        this.root = root;
        this.repository = repository;
        this.sandbox = sandbox;
    }
    public String getRoot(){
        return root;
    }

    public void setRoot(String root){
        this.root = root;
    }

    public String getSandbox(){
        return sandbox;
    }

    public void setSandbox(String sandbox){
        this.sandbox = sandbox;
    }

    public String getRepository(){
        return repository;
    }

    public void setRepository(String repository){
        this.repository = repository;
    }


}
