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

/**
 * This Throwable object is NOT used as an exception, but rather as a way
 * to jump out of execution of a current line of processing.
 * For example, in a servlet, you can send a "redirect" to the browser,
 * you then need to quit the logic, and not write anything else.
 * This is useful for "ASSERT" type logic where a condition is tested,
 * the browser is redirected, and you just want ot exit out of the rest.
 * It is useful for cases where an exception has been caught at the
 * top level, recorded, and then this is thrown to get the rest of the
 * way out.
 *
 * Throwing a ServletExit is like exiting a program, or quitting a program
 * only it does not kill the entire JVM, instead it it just quits the
 * handling of this particular browser request.
 *
 * This does not carry a message.  This class should never be used to wrap
 * another exception.  An exception should be handled or recorded, and
 * then this can be used to get the rest of the way out of the call stack.
 */
@SuppressWarnings("serial")
public class ServletExit extends Exception
{

    public ServletExit() {
        super();
    }


}
