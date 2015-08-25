:#####################################################################################################
:#
:# Java home
:#
:#####################################################################################################
set JAVA_HOME=c:\Program Files\Java\jdk1.6.0_29\

:#####################################################################################################
:#
:# Path to nugen source directory. Specify ONLY absolute directory.
:#
:#####################################################################################################
set SOURCE_DIR=c:\sandbox\ps\nugen\

:#####################################################################################################
:#
:# Path to build directory. nugen.war will be created here.
:# Specify ONLY absolute directory.
:# WARNING - do not specify an already existing directory containing data.
:#
:#####################################################################################################
set TARGET_DIR=c:\sandbuild\nugen\

:#####################################################################################################
:#
:# Tomcat installed directory location.
:#
:#####################################################################################################
set CATALINA_HOME=c:\ApacheTomcat 6\

:#####################################################################################################
:#
:# Optional deploy or not deploy
:#
:#####################################################################################################

set AUTO_DEPLOY=false


:#####################################################################################################
:#
:# NOW test that these settings are correct, test that the folders exist
:# and warn if they do not.  No user settings below here
:#
:#####################################################################################################

IF EXIST "%JAVA_HOME%" goto step2

echo off
echo ************************************************************
echo The Java home folder (%JAVA_HOME%) does not exist.
echo please change JAVA_HOME to a valid folder where Java is installed
echo ************************************************************
pause
echo on
goto exit1

:step2
IF EXIST "%SOURCE_DIR%" goto step3

echo off
echo ************************************************************
echo The source folder (%SOURCE_DIR%) does not exist.
echo please change SOURCE_DIR to a valid folder where source is to be read from
echo ************************************************************
pause
echo on
goto exit1

:step3
IF EXIST "%TARGET_DIR%" goto step4

echo off
echo ************************************************************
echo The build target folder (%TARGET_DIR%) does not exist.
echo please change TARGET_DIR to a valid folder where output is to go
echo ************************************************************
pause
echo on
goto exit1

:step4
IF EXIST "%CATALINA_HOME%" goto step5

echo off
echo ************************************************************
echo The Catalina home folder (%CATALINA_HOME%) does not exist.
echo please change CATALINA_HOME to a valid folder where Apache Tomcat is installed
echo ************************************************************
pause
echo on
goto exit1

:step5


:exit1