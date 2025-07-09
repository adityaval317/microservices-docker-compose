#!/bin/bash
#
# Run command using bash push-images.sh [build_version]

# This script pushes the Docker images for the microservices to a Docker registry.
REPOSITORY_ACCOUNT="adityaval317"
# Check if the build version is provided as an argument
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <arg1>"
  exit 1
fi
BUILD_VERSION=$1
current_dir=$(pwd)
echo "Current directory: $current_dir"
microservices=("accounts" "cards" "loans" "config-server" "eureka-server" "gateway-server" "notification-service")
# Navigate to each directory and run mvn compile jib:dockerBuild
for service in "${microservices[@]}"; do
  echo "Pushing Docker image for $service with version $BUILD_VERSION"
  docker push "$REPOSITORY_ACCOUNT/$service:$BUILD_VERSION"
done
