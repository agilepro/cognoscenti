
#####################################################################################################

#
# Java home
#
#####################################################################################################
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.151-5.b12.el7_4.x86_64/

#####################################################################################################
#
# Path to nugen source directory. Specify ONLY absolute directory.
#
#####################################################################################################

# export SOURCE_DIR=c:\sandbox\ps\nugen\
export COGNO_SOURCE_DIR=/var/lib/jenkinsStaging5050/apps/cognoscenti
export SOURCE_DIR=/var/lib/jenkinsStaging5050/apps/cognoscenti

#####################################################################################################
#
# Path to build directory. nugen.war will be created here.
# Specify ONLY absolute directory.
# WARNING - do not specify an already existing directory containing data.
#
#####################################################################################################
export TARGET_DIR=/var/lib/jenkinsStaging5050/apps/cognoscenti/target

#####################################################################################################
#
# Tomcat installed directory location.
#
#####################################################################################################
export CATALINA_HOME=/opt/tomcat

#####################################################################################################
#
# Optional deploy or not deploy
#
#####################################################################################################

export AUTO_DEPLOY=false


#####################################################################################################
#
# NOW test that these exporttings are correct, test that the folders exist
# and warn if they do not.  No user exporttings below here
#
#####################################################################################################

