#!/usr/bin/env bash

APP=webmvc-tomcat
MAINCLASS=com.example.webmvc.WebmvcApplication
VERSION=0.0.1-SNAPSHOT

echo "================ BUILDING THE PROJECT AND UNPACKING THE FAT JAR =========="
cd ..
mvn -ntp clean package
cd agent
rm -rf unpack
unzip -q ../target/$APP-$VERSION.jar -d unpack
cd unpack/BOOT-INF/classes
cp -R ../../META-INF .
rm -rf graal
mkdir -p graal/META-INF/native-image

# Set the CP for the jars/code in the unpacked application, leaving us in the BOOT-INF/classes folder
export CP=`find ../../BOOT-INF/lib | tr "\n" ":"`

echo "============== RUNNING THE APPLICATION WITH THE AGENT TO POPULATE CONFIGURATION FILES ========="
echo "(for debug see agent-output.txt)"
echo "Running for 10 seconds"
java -cp .:$CP \
  -agentlib:native-image-agent=config-output-dir=graal/META-INF/native-image \
  $MAINCLASS > agent-output.txt 2>&1 &
PID=$!
sleep 10
../../../verify.sh
echo "Killing..."
kill ${PID}
KILLED=$?
if [[ $KILLED != 0 ]]
then
echo "Failed to kill it! (Process ${PID})"
exit 1
fi
sleep 3

# Run native image to compile the application
native-image \
  -Dspring.native.mode=agent \
  -H:Name=$APP-agent \
  -Dspring.native.remove-yaml-support=true \
  -Dspring.spel.ignore=true \
  -cp .:$CP:graal:../../../graal \
  $MAINCLASS 2>&1 | tee output.txt

# Test the application
# The test script will look for it in the current folder
cp ../../../verify.sh .
${PWD%/*samples/*}/scripts/test.sh $APP-agent .
mkdir -p ../../../target/native-image/
mv summary.csv ../../../target/native-image/
