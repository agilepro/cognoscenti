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


/**
 * This is a Constant class for whose sole job is to define widely-used constants.
 * TODO: eliminate classes like this.  Constants should be defined in the class
 * that they are most used in.
 */

public class Constant {

    public static final String FAILURE = "failure";
    public static final String SUCCESS = "success";

    public static final String YES = "yes";
    public static final String No = "no";

    public static final String MSG_TYPE = "msgType";
    public static final String MESSAGE = "msg";
    public static final String MSG_DETAIL = "msgDetail";
    public static final String COMMENTS = "comments";

 // PRIVATE //

  /**
   The caller references the constants using <tt>Constant.FORWARD_REQUEST_URI_ATTRIBUTE</tt>,
   and so on. Thus, the caller should be prevented from constructing objects of
   this class, by declaring this private constructor.
  */
  private Constant(){
    //this prevents even the native class from calling this constructor as well :
    throw new AssertionError();
  }

}
