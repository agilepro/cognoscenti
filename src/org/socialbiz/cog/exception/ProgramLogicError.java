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
 * ProgramLogicError is to be used to warn about mistakes that appear to be
 * errors in the programming logic.  These are problems that might occur when
 * programming the product, but should never be seen when the product is released.
 * How is it possible to assure this??
 *
 * There are a class of problems that are impossible for a user of the system
 * to cause.  For example, if a null is passed to a method that does not accept
 * a null, this is a program logic error.  A user might enter values, but they
 * can not enter a null!  The user might enter a value, which is passed to a lookup
 * routine than then returns a null.  This null must be screened before passing on.
 * If properly screened, then there will never be a program logic error.  IF a null
 * occurs, it will normally be found during development, and once properly screened,
 * will never happen for an actual customer.
 *
 * Because these are never seen in production, we do not need to handle these in
 * the way that normal error messages are: they don't need to be translatable, and
 * they don't need fancy data substitution mechanism.  A simple, english only string
 * will be fine.
 *
 * Program Logic Error can be used in the following situations:
 *
 * 1) Null passed to a parameter that does not allow null
 * 2) Wrong data type subclass passed as a paramter
 * 3) Wrong data type object in a collection
 * 4) Objects which appear to be improperly constructed and/or inconsistent
 * 5) Internal consistency checks for situations that should never happen according to logic maintained by the class
 * 6) Form posted data has missing or incorrect field names.
 * 7) empty collection passed when parameter requires that there be at least one value.
 * 8) Initialization order problems, detecting that another service not initializes correctly.
 *
 * The key here is that these are all errors that do not depend upon the data values that users type in.
 * Passing an object of the wrong TYPE is clearly caused by faulty code.  There is no value that could be entered
 * by a user to cause the wrong object to be constructed.  If a method requires a collection with three elements
 * in it, then it should check and throw a program logic error if there are not three elements.
 * If a form post handler requires 8 form elements to be present, then it is a program logic error if
 * any parts of the form are missing.  The point is that the error that is announced
 * is something that can not possibly, in any reasonable way, be caused by entering user data in.
 * Program Logic Error should be used when there is an Internal data structure constraint, which
 * must be enforced by code, and a test discovers that the data structure is incorrect.
 *
 * What should NOT use ProgramLogicError?
 * 1) Search and failure to find a particular record: user may have
 *    entered an incorrect search value, so a proper translatable error message is needed.
 * 2) String format not correct: e.g. string representing integer has question mark in it
 * 3) Parsing errors for anything entered or edited by a person
 * 4) Any CATCH and RETHROW must be translatable because it might be caused by user.
 * 5) Inability to contact a remote server for any reason
 * 6) Warning that an operation is not allowed on certain parts of a structure (e.g. user selected element)
 * 7) Access control restriction warnings or denials
 * 8) Illegal characters in a file name, or other character validation problems.
 *
 * Using ProgramLogicError makes it very clear to all programmers maintaining the code that this error does
 * NOT need to be translated & does NOT need the special handling normally associated with exception handling.
 */
public class ProgramLogicError extends RuntimeException
{

    private static final long serialVersionUID = 1L;
    String msg;


    public ProgramLogicError(String message) {
        super("Program Logic Error: "+message);
        msg = message;
    }


    public ProgramLogicError(String message, Exception e) {
        super("Program Logic Error: "+message, e);
        msg = "Program Logic Error: "+message;
    }

    public String toString()
    {
        return msg;
    }

}
