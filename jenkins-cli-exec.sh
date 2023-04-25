#!/bin/bash

JENKINS_URL="http://192.168.66.100:8080/"
java -jar jenkins-cli.jar -s $JENKINS_URL -auth jenkins_user:jenkins_user_token "$@"
