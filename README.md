# cognoscenti
Major Adaptive CaseManagement, Coordination, Communication, Collaboration System

# Prerequisites

You must have Java installed, preferably Java 21 or later.

You must have Maven installed and working with the Java.

You must have TomCat v10 or later installed.

You must have Mongo installed and running on the standard port for Mongo.

# Build

The project is built with MAven.  You only need to build from the weaverWar folder.  If you have java installed, all you have 

    cd weaverWar
    mvn clean package

This should produce a WAR file in the weaverWar/target folder
 
# Configure
 
You will find the configuration in the WEB-INF/config.txt file.   There are four settings of importance in there.

* libFolder - This is the place that all sites/workspaces are saved.  Attachments are stored in the same folder with the project file.  Make sure that this folder exists before you start.
* userFolder - This is the place that all user information is saved.  Make sure that this folder exists before you start.
* baseURL - This is the external web address of the application, outside of any proxies, using the DNS names that you want the users to use.
* identityProvider - This is how you log in.  Use the public identity server until you find you need test users, and then you might want to set up your own SSOFI server

That is enough to get the server up and going.  Once you have logged in once, you will have a "user key".  This is a 9-letter all caps value that will appear in the URL to your home page.  Go to your home page, and you find something like this:

    https://s06.circleweaver.com/weaver/v/JDVBRFKFH/UserHome.htm

The value "JDVBRFKFH" is the user key in this url. This user key will be different for every installation, you have to log in first to get the server to create it.

* superAdmin - set to the user key for the users you want to be administrators.  You can put multiple keys separated by commas.  Restart the server to get the server to read this.  You will know that administrator privilege has been enabled properly for your user when you see the "king" icon appear in the navigation bar at the top of the weaver page.

# Testing

If you are going to be doing a lot of testing, there are two more servers you will want to run.

POSTHOC - this is a small TomCat service that appears like a SMTP email server, but it also has a user interface for viewing email received.  PostHoc will never forward email to any real email inbox.  It holds it all, no matter what the email address.  This will prevent you from accidentally spamming a lot of people because of email addresses that happen to be in the test data.  Email will only to go PostHoc and no further.

SSOFI - if you run your own identity server then you can create test users as you need, and login to those users using whatever password you want to set up.  To set passwords, you need to send email, so be sure to have the POSTHOC email server configured so you can receive those email messages there.




