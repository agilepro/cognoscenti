# Error Handling Guidelines

Java has support for throwing and catching exceptions, however to get the most benefit from them the programmer needs to use them effectively. Good exception handling is a key to building robust, reliable systems. 

# TLDR -- Pattern Summary

If you don't have time to read the entire page, this section summarizes what you need to know, and is supported by details further down. First we consider the initial throwing of an exception due to a detected error, two examples one with and one without a parameter.

```java
public BigDecimal divide( BigDecimal numerator, BigDecimal denominator ) {
if (denominator == null) {
throw ComponentException.newBasic("divide method needs a non-null denominator");
}
if (denominator == 0) {
throw ComponentException.newBasic("Unable to divide numbers because denominator is %s", denominator.toString());
}
// . . . 
// . . .
}
```

Notice:
* The exception is thrown because the method can not do what it is supposed to do. (E-1)
* The exception describes what the whole method failed to do. (E-2)
* Details about the call, such as parameters, as included in the exception where appropriate(E-3)
* No display or log is made here. Nothing is written to the log at this level. (E-5)
* The exception thrown is an untracked exception (here some assumed exception defined in the component called `ComponentException`) so it is not mentioned in the method signature. (E-4)
* This method trusts that some other part of the code with catch and display the error in some appropriate way (E-6)

The other situation you need to handle is when you call a method that is reporting an error. For example, if you call `divide` then that error should say that you can not divide, but we need to add context of what the divide was for. In this case you add context to the exception by wrapping and rethrowing.

```java
public boolean isDriverOverAge( int requiredAge, Object person ) {
try {
boolean isOver = false
// . . . 
// . . . 
// . . . 
return isOver;
} catch (Exception e) {
throw ComponentException.newWrap("Unable to determine if the driver %s is over age %d", 
e, person.name, requiredAge);
}
}
```

Here are (high level) things to notice:

* The method purpose is implemented in logic in one big try block. The return is within the try block so that we are sure all logic is complete.(E-11)
* If anything in that block fails, it goes to the catch block
* The catch block wraps and rethrows with an context exception (E-8)
* The additional context describes what the whole method failed to do and wraps the causing exception (E-2)
* Parameters include method parameter values `expected age` and `person name` so that it is specific about the situation which helps the caller identify what the problem was. (E-3)
* The catch block is for all exceptions, because you want assurance that *all* exceptions will be caught even if a code change causes the possibility of a new exception to be thrown. All exceptions here need to be handled in exactly the same way, because there is no reason to *compensate* any specific error in this method. (E-12)
* If the error can be caught and compensated, do so in a separate catch block, but this is actually quite rare so not included in this example. 
* Nothing is written to the log at this level. (E-5)
* The exception thrown is an untracked exception so it is not mentioned in the method signature. (E-4)
* The exception class is conveniently designed to format a string with parameters following the String.format syntax. (E-14)
* The exception is not "swallowed" by failing to rethrow. (E-7)
* The exception is exceptional, and not carrying program logic information (E-1)

The hardest part about this pattern is knowing when it is appropriate to catch and wrap an exception. Not every routine should be like this, because there are a lot of methods that are really just small parts of the same conceptual function. Our purpose is not to reproduce the entire stack trace by mechanically adding these into every method. Some experience is needed to know when it is appropriate to sense that the method being called is a different goal from the method calling it. You soon get the feeling where having this clarifying context information will be useful to help the recipient understand what went wrong.

If every conceptually relevant function included this pattern, we would be well on the way to providing good error messages to recipients.

# Philosophy

## Understanding the Purpose of an Exception

An exception should never be used to carry program data out of a method. If the program is running correctly as designed and there are no problems with the operating environment, then the program should never throw exceptions. All return values should be return values. An exception throw should not be part of normal program behavior. Exceptions should be exceptional. 

However exceptions do carry information about the problem encountered. When a method or a program is unable to complete its goal, then it should report with as much detail as possible what it was not able to do. If the method was supposed to read a file, and it could not do so, it should report "Can't read file %s". If a method is supposed to evaluate an expression, and it fails, then it should report "Unable to evaluate expression" and possibly explain what expression it was that failed.

That is pretty easy to understand, but let me stress this with a second paragraph. The method should not report that something else failed. The method should not simply guess or assume what the problem is, and report that. I have seen methods that as supposed to read a file, and when they can't they report "the drive is off-line" when the method actually has no proof of that. The programmer ran into one situation where the drive was off line, assumed that was the only possible reason for failure, and reported that. This leads to bad error messages, so stick to the rule: report in your exception that the method did not achieve its goal, being as specific as possible about the goal. 

Reference: [Bloch: Exception Handling](https://learning.oreilly.com/library/view/effective-java-3rd/9780134686097/ch10.xhtml#:-:text=Item%2069)

Additional Detail: [Gathering Error Report Information](https://agiletribe.purplehillsbooks.com/2013/02/15/gathering-error-report-information/)

## Reduce Support Costs & Increase Customer Satisfaction

A well written program will fail when something about the environment is not right, and the exception is the way to communicate the problem to the caller. 9 times our of 10, if the caller is given accurate information about what went wrong, they will be able to fix the problem without calling support.

The purpose of error reporting is then help solve the problem that caused the error. Recipients might solve the problem themselves, or they might pass the error report on to the support department. The contents of the error should:

* clearly explain the problem that the program experienced, and
* be complete enough that the information needed to solve the problem is there.

If the error message does not include enough information to solve the problem, then it has _failed_. If the caller has to call support, then the error message has _failed_. If multiple people have to spend time to understand what the error message means, it has _failed_.

A “problem” is simply a situation that the program is not able to handle. The program was designed to handle a wide variety of normal, expected situations. Anything that falls outside of these normal situations is a problem. Anything outside of the normal path is an exception.

This matches nicely with the programming concept of an Exception which is a programming language feature that not only stops the program operation, but also carries a message. The exception is the right mechanism to communicate error reports to the recipient. 

Additional Detail: [The Purpose of Error Reporting](https://agiletribe.purplehillsbooks.com/2013/02/14/the-purpose-of-error-reporting/)

## RulesLab Heritage

RulesLab aims to create a decision service that is **self-service**. To do so, we need precise, clear, and actionable error messages returned to the recipient. Following this practice has allowed the RulesLab authoring environment to be deployed and successfully used with astonishing little time spent support it. When a user does the wrong thing, a clear error message explains what the system was not able to do. 9 times out of 10 the recipient can correct the request without having to call anyone else.

Error messages are part of every user experience, but too often these messages are poor, cryptic, and insulting. Too often programmers do a half-hearted attempt at writing error messages, mostly because they mistakenly assume that recipients will never see them. Too often programmers misunderstand the potential that results from writing correct error messages. Error messages can be the key to usability. Error messages can help train users, and guide administrators. 

It turns out that using exceptions effectively is a way to carry important information to the recipient, allowing a clear and precise error message to be displayed. Remember that there are multiple recipients of the error; not just the user that caused the error, but also all of the coworkers and developers that are called into help out. A good error message helps all these. 

Additional Detail: [Gathering Error Report Information](https://agiletribe.purplehillsbooks.com/2013/02/15/gathering-error-report-information/)

## Just in Time Documentation

Raise your hand if you have had to support a customer who didn't read and internalize the complete documentation. Everyone? These are complex systems, and there are a lot of special details to know. Can I use file X in situation Y? Sometimes that is hard to determine purely from the documentation.

The problem of documenting is greatly reduced if the error messages are accurate. There can be a combination of conditions that are not obvious: when a particular configuration is chosen, and then if you do particular operations, there can be a necessary but non-obvious condition, and documenting all these special cases can make documentation onerous to read. Instead, make a clear error message, that is wrapped in a clear explanation of the context, and the recipient is delivered the right information at the time they need it, so they can respond and correct the problem.

Resist the temptation to return just an *error code* which must then be looked up in a reference manual to know what it means. Whatever explanation you wanted to put into the manual can be put directly into the exception throw and displayed directly to the user, eliminating a cryptic and bothersome additional step to access the details. Documenting directly in the code is easier to maintain accuracy when the code changes, and avoids the problem with out-of-date documentation.

## Collect Information Completely, but Display Judiciously

99% of these guidelines are about collecting correct and complete information about an error that just happened. That does **not** mean everything is dumped to every different recipient just because we have it. The delivery to the recipient *must depend on the needs* of that recipient. The **root level error handler** is the one place that decides what to deliver to a recipient depending on the situation. All the code in the project should help create a correct and complete report of what went wrong, so that the root level handler has everything it needs to deliver the correct amount for each recipient. 

Remember that there are different classes of recipients. 

* Project Developers: generally we will record everything in the log including a stack trace. Most of the benefit of an accurate message is realized by developers of the project itself, because an accurate error message makes it quick to find problems and easy to fix.
* API Callers: Will not get the stack trace, but still benefit from the complete text description of what went wrong. It is common for an API to be called incorrectly with incorrect data. The more the API can return about why that data is incorrect, the faster they will find the problem, and the more likely they can fix it on their own. Making them call the development team to get the detailed error wastes the time of multiple people. For example, we are expecting to receive DMN files from external sources, and if we find a problem with the DMN file, we want to be as specific as we can about the problem in that file. 
* Internal UI: Internal users use the system and may make mistakes. The more we can tell them about why their request is invalid, the faster they find the problem, and fix it hopefully without needing to call for support.
* Banking End Users: *None of this discussion should imply that these error messages are to be displayed to a banking customer.* The user interface for banking customers and highly crafted for a specific user experience, and all possible errors and responses carefully planned. Still, having an *accurate* internal error will always support getting an accurate crafted error display.

**Collection of error information, and deciding what to deliver are different jobs.** Code deep within the call stack can not know what the error information will be needed. The job of code within the stack is to simply to include as many accurate details as it can. It is then the root level error handler that takes that information, and determines what to send to each recipient. Different kinds of programs will return different things, in differing levels of detail. In some cases error patterns might be analyzed to identify common problems and improve the display for those common cases according to the purpose of the program, for example selecting from the 10 details the one that is most relevant for a particular situation.

The 1% of code that represents the root error handler is not covered in these guidelines, because each situation is different. The root error handler is one piece of code that can easily be adjusted over time to fit the need, but it depends on getting good error information from the rest (99%) of the code. 

Developer intuition is too often oriented to restricting delivery of error information. One recent real case was the DMN upload UI. A DMN can have many errors in it. During upload, the DMN validation will return a detailed message of why the DMN is invalid. For some reason the UI designer thought that was too much detail, and crafted a generic message: "Your DMN failed to upload" telling the recipient nothing about the reason why. This means that every time the DMN failed to upload, they had to call someone on our team to find out why. This customer has raised an issue, now tracked by management to get a better error message displayed. The irony is that a better error message was already available, but the Ui simply does not display it, because someone decided "they don't need to know this." We should strive to give more complete, and more accurate error message, until the users complain that they are getting too much, and then scale it back.

These guidelines allow the code to generate accurate and complete information about an error, so that the root error handler has the information it needs to pass on a suitable response to each recipient.

## Compensating Exception -- If You Can

Most of the examples in standard Java documentation is around catching exceptions in order to compensate the exception, that is, automate the response to do something else. The idea is that you call a method X, and method X fails, but you can do something else to compensate for that error. For example the code tries to read a file from a web service, and it fails, so it tries a second time. Another example is if you attempt to convert what the user entered to a number, and it fails to parse, then substitute a default value instead of alerting the user. The cases where you can compensate for an exception are quite rare.

The rule is: *if you can compensate for an exception, then do it.* Catch the exception, and perform the compensating action, and let the program continue.

If you write a method that has an error that is expected to be compensatable, then be sure to use a special unique checked exception for that error, so that it appears in the interface, and it is easy for the calling program to catch.

But most of the time (>95% of the time) there is nothing that the calling method can do to compensate for the error. If a method calls to read a file, and the file is corrupted, there is usually nothing to be done except report this problem to the recipient. If the method is to read something from a DB, and the DB is off line, there is nothing else to do except report the error. These instructions cover what to do when you can not compensate for the exception, which is most of the time. 

# Guidelines

## Item E-1: Exceptions should be exceptional

An exception should never be used to carry program data out of a method. Let's be clear about what we mean by program data. If the program is running correctly as designed and there are no problems with the operating environment, then program should never throw exceptions. All return values should be return values. An exception throw should not be part of normal program behavior. Exceptions should be exceptional. 

Examples I have seen in the past is a Reader object that expected you to read until you get an exception. The exception in this case was the signal to stop reading. This is an abuse of the exception pattern, because the end of a file is not an error. Every file has an end, and this exception would happen every time. There are a number of problems. For example, an exception might emerge that has nothing to do with the end of the file. This pattern encourages programmers to catch all exceptions, and then continue. Since the end of the file is expected, there is no problem making a return value that indicates the end of the file so that the caller can correctly identify that.

Exceptions should be used only in the case that something unexpected happens. The method is not able to do what it was supposed to do, and failed to produce the expected return value.

Reference: [Exceptions should be exceptional](https://learning.oreilly.com/library/view/effective-java-3rd/9780134686097/ch10.xhtml#:-:text=Item%2069)

## Item E-2: Report what the method failed to do.

If the method was supposed to do XXX, then the error should say that it failed to do XXX along with other details. This is so simple, but so often violated that it bears stressing. Don't throw an exception that speculates about what else might have gone wrong. The message needs to clearly say that this method failed to do. If the purpose of the method was to read a file, the error needs to say "Unable to read file %s". If the method was supposed to rotate a graphic by 90 degrees, it should say that it "Failed to rotate the graphic by 90 degrees." It is surprising how often this rule is violated.

Sometimes programmers try to guess what caused this method to fail. For example, instead of reporting that it failed to save the file, they report something like "the disk is offline". That might seem helpful itf it is correct, but in most cases the programmer has not uncovered all the possible reasons, inevitably the message will be occasionally wrong. Wrong messages are bad because they cause the recipient to do work solving a problem that never happened. We need accurate error messages, and that starts with explaining what is so obvious to the programmer: the current method failed to do what it was expected to do.

Even if you do take extra precaution and the code verifies the reason, you still need to report the context for that error. Say that the reason is that the disk is off-line, reporting that as the exception would leave the recipient wondering why it matters that the disk is offline. The context is missing. The error should report at the very least "the file could not be saved BECAUSE the disk is offline". That gives essential context to the problem. Always report the problem that this method actually failed to do.

Reference: [Bloch: Throw exceptions appropriate to the abstraction](https://learning.oreilly.com/library/view/effective-java-3rd/9780134686097/ch10.xhtml#:-:text=Throw%20exceptions%20appropriate%20to%20the%20abstraction)

Additional Detail: [Simple Rule for Exception](https://agiletribe.purplehillsbooks.com/2019/01/11/simple-rule-for-exception/) and [Exception Context](https://agiletribe.purplehillsbooks.com/2013/02/21/exceptions-speak-about-the-context-they-are-thrown-from/)

## Item E-3: Include details of the situation.

The goal of a message is to give the details that the recipient is going to need to resolve the problem. Too often programmers assume that the recipient of the error message is going to automatically know what was being done when the error occurred. The error message recipient is not always the user that caused the problem. They assume that when the program fails, the recipient will know what it was doing at the time of the failure, but from the outside of the program that is almost always not the case. That absolutely worst error message is one that is completely vague, with something like "operation failed". Recently I was re-installing windows on a computer, and after three hours of running, it simply said "installation failed" with absolutely no additional details of what I might even start to do something about it. 

Never assume that the recipient has insight into the program, the program structure, or the way it is running. Instead, give as many details as you can about what it is that failed. If for example, the method fails to read a file, then include the name of the file that it was trying to read. Sometimes it is simply that the user spelled something wrong and this detail can sometimes give them what they need to try again better. If the method is processing a record for a user, mention the user name or id. If the method is trying to reserve a seat on a flight and fails, then include the name or number of flight. If you are trying to reserve a table at a restaurant, include the time of the request into the failure message.

In general, if a method fails, it can be helpful to include the parameters of the method into the error message. You don't always have to include them all, and not all of them are useful, but still consider whether the parameters would give clarity to what went wrong.

Reference: [Bloch: Include failure-capture information in detail messages](https://learning.oreilly.com/library/view/effective-java-3rd/9780134686097/ch10.xhtml#:-:text=Include%20failure-capture%20information%20in%20detail%20messages)


## Item E-4: Use unchecked exceptions

Java offers checked exceptions that must be declared in the signature of the method, and unchecked exceptions that do not need to be. The ability to include the exceptions thrown in the method is a feature that seemed like a good idea at the time, but ended up being a large problem in any large system. Exceptions don't work the same way as parameters and return values, because exceptions can jump out multiple levels. You signature needs to include all exceptions classes from any method you call, and any method that it calls, etc recursively. At first this appears to be a bookkeeping problem until you consider that methods are packaged into libraries which have their own exception classes. A method in one library implementing something from an interface in another library may have the need to throw the library dependent exception but can't because that violates the signature defined by the interface in the other library.

In the end one does a lot of bookkeeping for no real value. In most cases all exceptions are just caught and wrapped. One can avoid the need to do a lot of bookkeeping by using unchecked exceptions. Interfaces become simpler because they don't need to declare the exception, and libraries can implement how they want, throwing the right exception for the error.

Knowing the exact exception that might be thrown is necessary only if you are able to compensate for a specific exception. If your method is throwing an exception that is likely to be compensated, then a checked exception might be appropriate. There are very few exceptions that can be compensated.

(Also see below: Use checked exceptions for compensatable errors)

Reference: [Bloch: Avoid unnecessary use of checked exceptions](https://learning.oreilly.com/library/view/effective-java-3rd/9780134686097/ch10.xhtml#:-:text=Item%2071%3A%20Avoid%20unnecessary%20use%20of%20checked%20exceptions)

Additional Detail: [Say ‘No’ to Checked Exceptions](https://agiletribe.purplehillsbooks.com/2023/07/13/say-no-to-checked-exceptions/)

## Item E-5: Don't log anything at throw site

The exception should be logged at the root level which will catch and report all exceptions in a consistent way. The method being asked to do something probably does not have any idea when reporting channels are appropriate. If this is a web service it will send an error response. If this is a web user interface, it might pop up an error dialog to show it to the user. hopefully the method at hand is written in such a way that if might be reused in each of these contexts. So never report anything to the log or to any kind of output because if you do it might be reported twice.

Some programs have not implemented this pattern, and so you might not be sure that the exception will actually be reported, so you log it out "just in case". That simply propagates a bad pattern. Insist that when the exception is thrown, that there must be a root level that takes on the responsibility of reporting it correctly. Only once this pattern is set can the programmer have confidence that everything will get reported properly, and then the pattern can be implemented properly.

All the information about the error should go into the exception object so that the final report can be complete. Writing a few things to system out, and then throwing an exception, is a waste, because now you have information in two different places. Keep it all together in the exception object.

## Item E-6: Report only at final catch site

During execution of such an case the wrapping and rethrowing continues all the out to the root-most level which is also known as the entry point for processing of the program. In a web service this would be at the level where the web request initially entered the code. For a program with a user interface, this is the place where the input events from the user are received to be handled. For a command line style program, the root level is the main routine.

At the root-most level the Exception can not be re-thrown because there is no program code below that level. The exception objects must be converted to some kind of an error message and displayed. How it is displayed depends on the particulars of the program. 

* The exception chain with all the causing exceptions is finally reflected in the log usually with all the stack traces to all the individual causal exceptions.
* if it is a web service, then the error response message is constructed around the exception, and returned to the requester.
* If this is a user interface, then some kind of error dialog is constructed to display the error as best possible with as much information as possible to the user.
* If this is a command line program the error is printed to standard out with as much detail as possible

Communicating the error in one root location assures that reporting is done consistently for every possible system exception. A development style I call "Error First Programming" encourages the error reporting mechanism to be the first thing built in any project. At first the only thing the program does is report a "Not Implemented" error. But that error is replaced incrementally with functioning code. During development, if there is any exception, you are assured that the exception will be reliably displayed, helping the programmer to address the problem quickly and effectively. 

In some cases the program might decide to hide the error message from the users. That decision on whether to hide or show should be made at the one location that the error is being displayed, and not by any of the routines that generates the exception chain. A given method does not know if the error will be exposed or not; it doesn't know if it is in a comment line, or a user interface, so a given method should not second-guess that. Each method should report what it failed to do (wrapping the cause if there is one) nothing more and nothing less.

## Item E-7: Never swallow exceptions

Never catch an exception and the continue the program without reporting anything. Never do this:

```java
try {
// . . .
// . . .
// . . .
}
catch (Exception e) {
// never do nothing here
}
```

Never simply catches and continues. When an exception is thrown from method A, then method B is not run. Whatever method B was supposed to do did not happen. Depending on what method B and the rest of the block needed to, there could be incorrect values in your variables. You might be creating a `time bomb` because the incorrect values may cause an error later. If the following code updates a database, it is possible that the code will write incorrect values to the DB. It is dangerous in general to continue after an exception is caught.

If you don't know what to do, then at least wrap and rethrow it. This prevents the `time bombs`.

There are cases where you know that a particular exception is being thrown when it should not be. Some third party methods throw exceptions in situations that are not exceptional. Sometimes the only solution is to wrap the method, and catch, and continue. Remember this is a special case and you should document in a comment how you know this is appropriate. You should catch only the exact class that is thrown in this case. You should not have anything else in the try block that needs to be run. Also, in most cases you should log the exception when you swallow and continue.

Reference: [Bloch: Don’t ignore exceptions](https://learning.oreilly.com/library/view/effective-java-3rd/9780134686097/ch10.xhtml#:-:text=Don%E2%80%99t%20ignore%20exceptions)

Additional Detail: [Never Catch and Continue](https://agiletribe.purplehillsbooks.com/2011/10/18/14-never-catch-and-continue/) and [Poor Exception Handling Examples](https://agiletribe.purplehillsbooks.com/2019/01/10/poor-exception-handling-examples/) and [Time Bombs](https://agiletribe.purplehillsbooks.com/2023/07/12/time-bombs/).

## Item E-8: Use wrap & rethrow to include context

Method A calls method B. When method B fails, it will throw an exception explaining that method B failed, but that explanation can sometimes be too detailed to do anything about the problem. Context needs to be added to the message to clarify that method A also failed because of the method B failure.

Say you have a method to "determine liability" for a customer, and to do that a file must be read. A failure to read the file is a detail error message, but it is also helpful to know that this file failure prevented the determination of liability. Including this detail in the exception chain makes it clear why reading the file was necessary. It also gives a clue as to what kind of file was supposed to be present, giving the recipient a greater chance to correct the problem. 

To fix the problem, you need both the detail and the context, and this is accomplished by wrapping the caught exception with another exception explaining the context. 

```java
public void methodA() {
try {
// . . .
callMethodB();
// . . .
}
catch (Exception exceptionFromB) {
throw ComponentException.newWrap("Unable to perform method A", exceptionFromB);
}
}
```

Note that the new ComponentException is constructed passing the causing exception as a construction parameter. This links the exception objects into a chain so that both are delivered and reported at to the root level. There could be more levels of nesting in the call path, and the exception might get a wrapper at each level, resulting in a chain of exceptions each explaining part of what went wrong. Since this correction is needed no matter what exception is thrown, this is an example of Item E-12 to catch the base `Exception` class.

"Wrapping an exception can provide extra information to the user by adding your own message (as in the example above), while still preserving the stack trace and message of the original exception. It also allows you to hide the implementation details of your code, which is the most important reason to wrap exceptions." - [Exception-Handling Antipatterns by Tim McCune](https://itblackbelt.wordpress.com/2006/04/17/exception-handling-antipatterns-by-tim-mccune/)

## Item E-9: Do not convert exceptions to string

A common anti-pattern is constructing a new exception after converting the old exception to a string. For example something like this:

```java
try {
// . . .
// . . .
// . . .
}
catch (Exception e) {
// never do this!
throw ComponentException.newBasic("Unable to perform method A because "+e.toString());
}
```

When you convert an exception to a string, you get the message of the exception, but you lose all the information about the stack trace. If a stack trace is going to be produced for the log, you want to preserve the trace to the original message. Wrapping the exception object will preserve this so it can be generated.

Wrapping an exception as an object is slightly more efficient because no conversion is needed. 

Additional Detail: [Never Convert Exception to String before Display Time](https://agiletribe.purplehillsbooks.com/2011/12/20/never-convert-exception-to-string-before-display-time/)

## Item E-10: Correcting third-party code

Many libraries do not conform to this pattern. Many libraries have poor exception messages that fail to include the necessary detail to know what it is that went wrong. Poor error messages can be addressed by wrapping that method call with a specific try-catch block to correct this, and to add context about what was happening.

```java
// . . .
try {
Library.callWithPoorErrorMessage(param1, param2);
}
catch (Exception e) {
// convert whatever was thrown into a better message
throw ComponentException.newWrap("Better explanation including %s and %s", e, param1, param2);
}
// . . .
```

If this method is used multiple times in the program, consider making this into a method itself and in your module use this version of the method with corrected error messaging, so that this try/catch does not have to be copied many times in the code. Since this correction is needed no matter what exception is thrown, this is an example of Item E-12 to catch the base `Exception` class.

## Item E-11: One big try block

The standard pattern is to put all the logic of the method into a single try block, with a single catch block at the bottom of the method. This assures that any and all calls within the method that produce exceptions will be handled consistently. If the method is catching and wrapping all exceptions with additional context that the method failed, this assures that all exceptions get the same wrapping. 

Some are tempted to make a large number of individual try blocks, one around each method that might fail, and each one with a catch block that wraps and rethrows. The main thing that is wrong with this is the unnecessary duplication of the catch and wrap logic. Why have it three times in the method, when a single time for the entire method is sufficient? The wrapping exception should say "This method failed" and in most cases it does not matter which method inside the try block failed. The easiest way to assure that all failures will be caught and wrapped is to put all the logic in a single big try block.

This means that the return statement, if there is one, should generally be within that one big try block.

The exception is when fixing a third party method with poor error messages as described in (E-10). In that case wrapping a single method is acceptable. Smaller try blocks are acceptable any time you can add extra context to the error explaining what was being done. But start with a single try block, and make smaller ones only when you have a good reason.

If the method is wrapping This is even recommended by Java teaching sites. If you have the need to do different things in each catch block, then separate catch blocks can be appropriate. But if you are doing the same thing in every catch block, you should not have this block duplicated.


## Item E-12: Catch the base exception type when need to handle all exceptions

Java allows a single catch block to declare exactly all the kinds of exceptions that are declared to be thrown in the try block. If your catch block is specialized to handle a particular kind of exception, then you should specify exactly the kind of exception to catch. You would never want that block acting on the wrong exception. But if your exception block is designed to handle **all** exceptions without regards to type you MUST catch all using the base class. If the catch handler has no dependence on the type of exception, but is dependent only on the fact that there was an exception, then catching the base class makes sense.

Consider the case of a web service handler that wants to be certain to either return a result or return an error. The pseudocode might be as below:

```
handleWebRequest( request, response ) {
try {
method1();
method2();
method3();
response.writeResponse(200, responseObject);
}
catch (Exception e) {
response.writeResponse(400, formErrorObject(e));
logError(e);
}
}
```

Some will argue that the catch block should only include exception classes that are documented by method1, method2, and method3 because those are all the can happen. So you make a list of method classes for specific exception that the methods can throw. There are a number of mistakes that could be made: programmer might forget a class, when that happens you will have a request that fails to report an error. Another bug can be introduced if a new method4 is added, which throws a different exception type, and the programmer forgets to include that in the exception block signature. A third possibility occurs when the exceptions thrown by method2 change from one exception type to another without the programmer of this block even knowing about it. Nothing changed in this block, however you need to modify the catch signature for every place that method2 is called. The chance of a bug creeping into the code over time is non zero. This entire problem is avoided by catching all exceptions using the base class. The reason is that you already know at the start that **no matter what exception is thrown**, you want to catch it and formulate an error response.

Or consider another case, you want to include details into an error message. This code:

```
executeDecision( intent, version ) {
try {
Model model = findModel( intent, version );
return model.executeResult();
}
catch (Exception e) {
throw DecisionFailure.newWrap("Failure executing intent (%s) version (%s)", e, intent, version);
}
}
```

The execute method will throw some error detailing what is wrong, but that entire module knows nothign about the concept of `intent` and `version` so that would not be mentioned in the error message. By wrapping this with an exception that tells both the intent and version the comined error message would tell not only what went wrong, but also what particular decision it occurred in. Both of these are needed so that the original rule author to do something about the problem. There is no reason to wrap only for particular exceptions. It literally does not matter what exception the execut model throws, they all must be wrapped in this way. For example, if a new version of the execute engine were to throw a new exception, you areadly know now that you want that new exception wrapped in the same way. There is no reason to catch specific exceptions, and if you did you run the risk of missing an exception and failing at runtime to include the details of the intent and version.

The logic is irrefutable: if you know that you want to catch and wrap **any and all** exceptions that comes out of the try block, then you MUST catch the base class `Exception` directly so that any new exceptions added in the future will be automatically included without fail. It is hard to stress how important it is that in the future all exceptions are handled reliably. 

Additional Detail: [Catching Generic Exception Classes](https://agiletribe.purplehillsbooks.com/2022/12/15/always-catch-the-generic-exception/).

## Item E-13: Standard web service error response

Any web service can fail and return an error response. All web services should use the same format for this error response, so that receiving and handling the error response is simplified. The standard form for an error response is:

```json
{
"error": {
"errorCode": "string",
"errorDescription": "string",
"errorDetail": [
"string"
]
}
}
```

The `errorDetail` is a list of strings, one string for each exception in the chain that was received. The `errorDescription` is usually a duplication of the lowest level exception string, but it might be something more elaborate if desired. The `errorCode` is an attempt to give a short symbolic classification of the error so that anything attempting to compensate for the error can easily identify the specific error.

Putting the entire structure into a block named `error` helps to avoid name conflicts between error fields and whatever else the engine wants to return with it (such as `requestID` or `transactionID` identifying the request).

The promise of micro services mesh is to have services calling services calling services. A failure in one service may be too detailed to understand without the additional context about the service that called it, and ultimately the service(s) that called that. To understand the problem that needs to be corrected, one might need information about what all the various services (in the call path) were intending to do. Assembly of this combined message is greatly simplified if every service uses the same format for error messages.

with about when you call a **web service** and that fails? In general, the error message should be packaged up as an exception, wrapped in a context exception, and thrown so that the proper layer can report it. This allows you to treat a web service call in very much the same way that you treat a method call. In a microservice world, web service calls are the new method calls.

Consider a service to combine and process three sets of data, while each data set is retrieved from secondary web services. Imagine that the call is improperly formed such that one of the secondary serices fail. Assuming the secondary service returns a good error message, it can be very useful to return this error back to the original caller. Then they can correct the name of the data set being processed. It should be clear that if the system can accomplish this, then the caller has a chance to correct the situation.

## Item E-14: Exception class should make it easy to include details

All exceptions should take a string as a description to clarify the situation of the error, but that is not always enough. If the failure was of opening a file, you will want to include the name of the file that was not opened. 

A good way to do this is to use the pattern of the `String.format()` method, where symbols such as `%s` and `%d` are replaced with values. If you then have a variable parameter method for including the values, it makes it easy. For example:

```
throw Exception.newBasic("Operation %s failed on %s", operationName, contextName);
```

it is easy to write this, and the final string is composed at runtime ONLY when the exception is needed. Don't use string concatenation because the above inclusion parameters are slightly more efficient.

Note: the pattern above conforms to the rule to consider static factory methods instead of constructor on the class. Obviously the same thing above could be done in a constructor, but consider using a static factory method instead.

Reference: [Bloch: Include failure-capture information in detail messages](https://learning.oreilly.com/library/view/effective-java-3rd/9780134686097/ch10.xhtml#:-:text=Include%20failure-capture%20information%20in%20detail%20messages)

## Item E-15: Trimmed stack trace

A stack trace includes the stack frame where the exception was constructed, the frame that called that, and the frame that called that. But how down should it go? The standard trace goes all the way down to the start of the thread or the start of the program. Many standard environments include a lot of layers of code setting up for execution. I have seen stack traces with 150 frames in it. Most of those frames are of no interest to anyone, since they are just setup, and not involved in the logic of the current problem.

For example, consider a web service. When Spring Boot starts, it runs though about 100 stack frames to get to the point of taking a web request. The programmer logic is only above that point. When a web request comes in to the service, this invokes the programmer code to handle the request. If there is a problem (or a bug) in handling that request, it will be in the stack frames above the request, and below the level of the throw. All of the stack frames below the point of receiving the request is always the same, and has nothingn to do with the problem.

Having an extra 100 stack frames reported for every exception adds a tremendous amount of clutter. Going from 10 lines to 110 lines can push beyond data transfer/storage limits. More importantly it increases the burden on everyone who has to look at it. It is harder to identify the problem. The long list is intimidating. It is far more comfortable to see the shorter list of what you need.

As it turns out, there is an easy solution: generate a stack trace down to the point where the code is that is generating the trace. For a web service, say it receives a request at stack frame 100. This is processed all the way up to stack frame 110 where an error occurs. The exception is thrown back down to stack frame 100 where an error response object is formed and the stack trace logged. The trace that is logged should include only levels 100 (the point doing the logging) thru 110 (the point where the error occurred). 

A good exception class will provide a method to generate a trace from the exception throw level down to the level that is calling for the trace to be generated.

Implementation: [A class with trimmed tracing method](https://github.cloud.capitalone.com/RuPol/rule-engine-component/blob/1f593180d4029d11d5bec600ba14add03af2bdd8/src/main/java/com/capitalone/rupol/ruleengine/exception/ComponentException.java#L156)

## Item E-16: Don't use `Either` class to report errors

Java offers a class that combines two classes together. `Either` represents a value of two possible types. An `Either` is either Either.Left or a Either.Right, and it is a templated class so you can declare what the two types are.

Never use this to return a value OR an exception. I have seen code where a method returned an `Either<Data,Exception>` instead of throwing an exception. This defeats the whole point about exceptions by forcing the calling code to explicitly check whether an error happened. Besides the clutter, if the calling code forgets to check you get incorrect results, possibly a `time bomb` when later it tries to use the missing `Data`.

The advantage of using the exception is that the caller does not need to check if the exception was returned. The code automatically jumps to the catch block. The regular logic is not cluttered with checks to see if an error occurred. The error handling is separated from the main logic into a block where only errors are handled. The result is easier to read and understand.

An `Either` class should be used when the proper execution of a method might conceivably return one or the other in normal program operations, but never for an exception situation.

## Item E-17: Use checked exceptions for compensatable errors

Here use the use term `compensate` to mean that the program can catch the exception, and automatically do something appropriate instead to fully compensate for the method that failed. Compensatable errors are also known as `recoverable` errors. Cases where you can do this are rare. 

For example, if you have some string data that might be a number, one approach is to call the method to convert it to a number, and if that method fails, then just use a default value, such as zero. The conversion routine will throw an exception, but if it does you don't really care and you don't need to report it to anyone. The value is not really needed and the default will do. In this case we know there are no side effects because the only thing being done was the conversion from string to number.

In the cases where you are designing a method, and it must throw an exception, but you think it is possible that the caller might be able to catch and automatically compensate for the error, then you should use a **checked exception**. Checked exceptions are indicated in the interface, alerting the programmer to the possibility of catching and compensating. The exception object thrown should be a new unique exception class, so that the catch expression can specify just that exception.

The vast majority of errors that occur that no caller can compensate, and in those cases the most important thing is to generate an exception response that accurately describes the situation, so that the recipient can take action.

* If a user enters an account id that does not exist, and a method throws an exception because the required account is not there, there is not much that the program can do other than show some kind of error (or rejection) to the recipient. There is no way the program could compensate for an incorrect account id.
* If a DB has gone offline, there is nothing the program can do to compensate for not having access to the data.
* If a web request fails because of lack of authorization, there is no way to automatically compensate in any normal program.
* If a file to be read is corrupted, there is normally no way to compensate for the corruption.

I am still looking for compelling cases where this can be used, but so far in my experience less than 1% of the errors being reported can be compensated in any manner.

Reference: [Bloch: Use checked exceptions for recoverable conditions](https://learning.oreilly.com/library/view/effective-java-3rd/9780134686097/ch10.xhtml#:-:text=Use%20checked%20exceptions%20fo,r%20recoverable%20conditions)

## Item E-18: Consider the x and x-or-fail pattern

A common pattern is a method that searches for data and returns a result. If the thing being looked for does not exist, it returns a null to indicate that there is no such thing. This pattern is important to allow other parts of the program to see if something exists. Yet there are two calling patterns: one for **optional** and one for **required**.

Optional pattern: For example, in the process of signing up a new account, the program might need to call `getExistingAccount()` with that user id, and if there are none then allow the use of that id for the new account. Some callers want to access something if it exists. 

Required Pattern: financial transfer between accounts must fail if either account does not exist. In this case you call `getExistingAccount()` and if the result is null, throw an exception.

The optional pattern requires a null return so you can test if a resource exists. If you have a lot of places with the required pattern, you have a lot of duplicate code spread around. More important is that each of the test and throw blocks has the possibility to send a different error message for the exact same problem.

Consider then making an "or fails" method for use in all the required patterns:

```java
public Account getExistingAccount(String id) {
// . . .
// . . .
// return either Account or null
}

public Account getExistingAccountOrFail(String id) {
Account account = getExistingAccount(id);
if (account == null) {
throw ComponentException.newBasic("The account for '%s' can not be found", id);
}
return account;
}
```

The second method simply tests for null and throws a **standard exception** for explaining what went wrong. The caller either calls the optional version or the required version depending on what they need. If the account is required, the caller does not need to check for null and throw an error, that is done, and the logic proceeds only if it gets a real account back. This eliminates redundant code. The exception can then be managed in a single place. If in the future the standard message needs to change, it will be changed for all of the required pattern callers.

This pattern should not be used all the time, but consider it whenever you have two or more places that are testing for null and throwing exceptions for the same underlying method call.

## Item E-19: Consider an `error-first` approach

The `Error First` design pattern is one where the first thing you write in any program is a try/catch block in the `main` method to catch any and all exceptions, and display them in the best manner to the recipient. Then, as you add code to the program, you have confidence that any routine can always throw an exception, and it will be reliably reported and logged. You start implementing functionality by writing methods that throw "not implemented yet" exceptions. You then replace those with the real functionality.

As you add any web service, the first thing you write is a block catching an exception, and returning a 4XX response with the exception in it (in JSON). This means that no matter how someone else calls the service, they are guaranteed to get either a correct result, or an error message describing the problem. The error is also reliably written to the log so you have assurance that all error are recorded. What you want to avoid is the situation where absolutely nothing is returned. Once you have the error handler in place, you can throw an exception from anywhere in the code, and be assured that the caller will get information about what went wrong.

If you are writing a user interface, the first thing you write is an ability to display an error to the user, and make a catch block at the basic level call this to display whatever exception occurs. That way, if anything goes wrong, at least the user gets some kind of description of what went wrong. You probably are also recording the error in the log output as well, and this approach assures that all errors get logged.

It does not actually cost anything to do this. You need to write the error display in any case, and rather than doing a job that is spread all around the code in various forms, you write one at the base of the call stack, and you get immediate assurance that all error will be displayed. While in development, the display of those error are incredibly useful. Quite often, when something fails, the developer will know immediately what to fix, saving a lot of research and debugging time. The key is though that there is really no additional effort, you just need to remember to write the basic error display code first.

Additional Detail: [Error-First Design in JSON/REST/AngularJS integration](https://agiletribe.purplehillsbooks.com/2015/12/04/error-first-design-in-jsonrestangularjs-integration/)
