#!/bin/bash
#
# Run command using bash build-run-images.sh [old_build_version] [build_version] [profile]
# This script builds the Docker images for the microservices defined in the docker-compose.yml file.
REPOSITORY_ACCOUNT="adityaval317"

# Check if the build version is provided as an argument
if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <arg1> <arg2> <arg3>"
  exit 1
fi

OLD_BUILD_VERSION=$1
BUILD_VERSION=$2
MICROSERVICE_NAME=${3:-"all"}
PROFILE=${4:-"default"}

current_dir=$(pwd)
echo "Current directory: $current_dir"

cd "$current_dir"
stop_and_remove_all_containers=1
microservices=("accounts" "cards" "loans" "config-server" "eureka-server" "gateway-server" "notification-service")
# If the microservice name is provided, filter the list
if [ "$MICROSERVICE_NAME" != "all" ]; then
  microservices=("$MICROSERVICE_NAME")
  stop_and_remove_all_containers=0
fi

if docker ps | grep -w "$REPOSITORY_ACCOUNT*"; then
  echo "Waiting for Docker containers to stop..."
  cd "$current_dir/$PROFILE"
  if [ $stop_and_remove_all_containers -eq 0 ]; then
    # Stop and remove one or more specific microservices
    # CONTAINER_ID=$(docker ps --filter "ancestor=$REPOSITORY_ACCOUNT/${microservices[@]}:$OLD_BUILD_VERSION" --format "{{.ID}}")
    docker-compose rm "${microservices[@]}"
    # sleep 20
  else
    docker-compose down
  fi
  # sleep 20
fi
cd "$current_dir"
# Navigate to each directory and run mvn compile jib:dockerBuild
for service in "${microservices[@]}"; do
  # Check if docker containers are running and stop them

  # Check if a docker image exists with old version
  if docker images | grep "$REPOSITORY_ACCOUNT/$service:$OLD_BUILD_VERSION"; then
    echo "Removing old Docker image for $REPOSITORY_ACCOUNT/$service:$OLD_BUILD_VERSION"
    docker rmi "$REPOSITORY_ACCOUNT/$service:$OLD_BUILD_VERSION" || true
  fi
  echo "Building Docker image for $service with version $BUILD_VERSION"
  cd "../$service"
  mvn compile jib:dockerBuild -Dbuild.image.version=$BUILD_VERSION
  while ! docker images "$REPOSITORY_ACCOUNT/$service:$BUILD_VERSION" > /dev/null; do
    echo "Waiting for Docker image to be built for $REPOSITORY_ACCOUNT/$service:$BUILD_VERSION..."
    sleep 5
  done
done

echo "All Docker images built successfully."
# Start the Docker containers using docker-compose
echo "Starting Docker containers with docker-compose..."
# Navigate to the directory containing the docker-compose.yml file
echo "Using profile: $PROFILE"
echo "Current directory: $current_dir"
cd "$current_dir/$PROFILE"
BUILD_VERSION=$BUILD_VERSION docker-compose up -d

echo "Docker containers started successfully."
# List the running Docker containers
docker ps | grep "$REPOSITORY_ACCOUNT*"
echo "All services are up and running."




