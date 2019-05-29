#!/bin/bash

export GRAALVM_HOME=/opt/graalvm-ce-1.0.0-rc16/

# Mac Native
# mvn package -Pnative

# Linux Native
mvn clean package -Pnative -Dnative-image.docker-build=true -DskipTests
