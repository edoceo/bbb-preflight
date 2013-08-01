#!/bin/bash -x

# echo " "
# echo "jQuery AS3 Web Camera by Sergey Shilko"
# echo "To make you need open-source Adobe FLEX SDK version 3.6+ with flash player 9 libraries and Java 6"
# echo "Compilation is made with native AS3 compiler 'mxmlc'"
# echo " "
# 
# ME="`whoami`"
# FLEX_SDK_HOME="/opt/flex-4.6/"
# JAVA6_PATH=$(which java) # "/usr/lib/jvm/java-6-sun/bin/java"
# MAKE="$JAVA6_PATH -jar $FLEX_SDK_HOME/lib/mxmlc.jar +flexlib=$FLEX_SDK_HOME/frameworks sAS3Cam.as"
# 
# MAKE="/opt/flex-4.6/bin/mxmlc sAS3Cam.as"
# 
# echo "Executing:"
# echo $MAKE
# echo " "
# echo `$MAKE`
#


/opt/flex-4.6/bin/mxmlc \
    -as3=true \
    -contributor "Edoceo" \
    -creator "Edoceo, Inc" \
    -publisher "Edoceo, Inc" \
    -title "Preflight" \
    -debug=false \
    -default-size 320 320 \
    -incremental=true \
    -static-link-runtime-shared-libraries \
    -output preflight.swf \
    Preflight.as

# mv preflight.swf  /var/www/bbb-preflight.swf