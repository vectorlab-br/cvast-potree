#!/bin/bash

set -e

### Global variables and Help

APP_OPTIONS="db|web|elasticsearch|nginx|potree"
DEFAULT_APPS_DEPLOYED="web|nginx"
ENVIRONMENT_OPTIONS="test|acc"

HELP_TEXT="
Arguments:  
-a or --app: Optional: CVAST app to be deployed, multiple allowed within quotes "" (options: ${APP_OPTIONS}). If --app not specified, these apps are deployed: ${DEFAULT_APPS_DEPLOYED}  
-e or --environment: The AWS environment to deploy on (options: ${ENVIRONMENT_OPTIONS})
-c or --commit: The build / commit number to tag the images with (e.g. the \$BUILD_NUMBER variable in Jenkins)
-i or --access_key_id: The AWS Access Key ID of your AWS account  
-k or --secret_access_key: The AWS Secret Access Key of your AWS account  
-h or --help: Display help text  
"

AWS_DEFAULT_REGION=us-east-1



	
####Functions####################################################################################################################


# Parameters: 
# $1 = app (web, db, elasticsearch, nginx)
build_image() {
	local APP_NAME=$1
	echo "Building Docker image:  $APP_NAME:$BUILD_NUMBER"
	
	if [[ ${APP_NAME} == "web" ]] || [[ ${APP_NAME} == "nginx" ]] || [[ ${APP_NAME} == "elasticsearch" ]] || [[ ${APP_NAME} == "db" ]]; then
		DOCKERFILE="Dockerfile-"${APP_NAME}
	else
		DOCKERFILE="Dockerfile"
	fi
	
	docker build -f ${DOCKERFILE} -t cvast/cvast-${APP_NAME}:${BUILD_NUMBER} .
}


# Parameters: 
# $1 = app (web, db, elasticsearch, nginx)
# Cleanup old images, keep latest 7
cleanup_old_image() {
	local APP_NAME=$1
	if [[ $(docker images -q cvast/cvast-$APP_NAME:$OLD_IMAGE_BUILD 2> /dev/null ) ]]; then
		echo "Removing old image:  $APP_NAME:$OLD_IMAGE_BUILD"
		docker rmi cvast/cvast-$APP_NAME:$OLD_IMAGE_BUILD
	fi
}


# Parameters: 
# $1 = app (web, db, elasticsearch, nginx)
push_to_registry() {
	local APP_NAME=$1
	echo "Pushing to private Docker registry:  $APP_NAME:$BUILD_NUMBER "
	docker push cvast/cvast-$APP_NAME:$BUILD_NUMBER
}


# parameters: 
# $1 = app (web, db, elasticsearch, nginx)
deploy_image() {
	local APP_NAME=$1
	echo "Deploying to AWS:  $APP_NAME:$BUILD_NUMBER"
	docker run \
		--env AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} \
		--env AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} \
		--env AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION} \
		cvast/cvast-arches-deploy \
		-c $BUILD_NUMBER -e ${ENVIRONMENT} -a $APP_NAME
}


# Check if value is in array
array_contains_element() {
	local e
	for e in "${@:2}"; do 
		[[ "$e" == "$1" ]] && return 0; 
	done
	return 1
}

# Check if value is not in array
array_not_contains_element() {
	local e
	for e in "${@:2}"; do 
		[[ "$e" == "$1" ]] && return 1; 
	done
	return 0
}

display_help() {
	echo "${HELP_TEXT}"
}

#################################################################################################################################



### Actual execution

# Script parameters 

# Use -gt 1 to consume two arguments per pass in the loop (e.g. each
# argument has a corresponding value to go with it).
# Use -gt 0 to consume one or more arguments per pass in the loop (e.g.
# some arguments don't have a corresponding value to go with it, such as --help ).

while [[ $# -gt 0 ]]
do
	key="$1"

	case ${key} in
		-a|--app)
			IFS=' ' read -r -a DEPLOY_THESE_APPS <<< "$2"
			shift; # next argument
		;;
		-e|--environment)
			ENVIRONMENT="$2"
			shift # next argument
		;;
		-c|--commit)
			BUILD_NUMBER="$2"
			shift # next argument
		;;
		-i|--access_key_id)
			AWS_ACCESS_KEY_ID="$2"
			shift # next argument
		;;
		-k|--secret_access_key)
			AWS_SECRET_ACCESS_KEY="$2"
			shift # next argument
		;;
		-h|--help)
			display_help
			exit 0
		;;
		*)
			echo "Unknown option: ${key}"
			display_help
			exit 1
		;;
	esac
	shift # next argument or value
done

if [[ ! -z ${DEPLOY_THESE_APPS} ]]; then
	for app in "${DEPLOY_THESE_APPS[@]}"; do
		eval "case ${app} in
			${APP_OPTIONS})
				echo \"Image set for deployment: ${app}\"
				;;
			*)			
				# Any other input
				echo \"Invalid option: -a|--app: ${app}\"
				display_help
				exit 1
				;;
		esac"
	done
else
	DEPLOY_THESE_APPS=$DEFAULT_APPS_DEPLOYED
fi




if [[ -z ${ENVIRONMENT} ]] ; then
	echo "ERROR! -e|--environment parameter not specified. Exiting..."
	display_help
	exit 1
fi

eval "case ${ENVIRONMENT} in
	${ENVIRONMENT_OPTIONS})
		echo \"Deploying on environment: ${ENVIRONMENT}\"
		;;
	*)			
		# Any other input
		echo \"Invalid option: -e|--environment ${ENVIRONMENT}\"
		display_help
		exit 1
		;;
esac"

if [[ -z ${BUILD_NUMBER} ]] ; then
	echo "ERROR! -c|--commit parameter not specified. Exiting..."
	display_help
	exit 1
else
	if [[ $BUILD_NUMBER -gt 7 ]]; then
		OLD_IMAGE_BUILD=`expr $BUILD_NUMBER - 7` # For cleaning up old junk
	else
		OLD_IMAGE_BUILD=0
	fi
fi


if [[ -z ${AWS_ACCESS_KEY_ID} ]] ; then
	echo "ERROR! -i|--access_key_id parameter not specified. Exiting..."
	display_help
	exit 1
fi

if [[ -z ${AWS_SECRET_ACCESS_KEY} ]] ; then
	echo "ERROR! -k|--secret_access_key parameter not specified. Exiting..."
	display_help
	exit 1
fi


# In order to make docker-compose work, we need all docker images to have this latest BUILD_NUMBER, 
# including images that are not explicitly built with this script (usually db & elasticsearch)
for app in "${APP_OPTIONS[@]}"; do
	if [[ $(array_not_contains_element $app ${DEPLOY_THESE_APPS}) ]]; then
		echo "Tagging latest jenkins build as cvast/cvast-$APP_NAME:$BUILD_NUMBER"
		docker tag cvast/cvast-$APP_NAME:jenkins-latest cvast/cvast-$APP_NAME:$BUILD_NUMBER
	fi
done


### Build all images
for app in "${DEPLOY_THESE_APPS[@]}"; do
	build_image $app
done


### Cleanup all old images, keep latest 7
for app in "${APP_OPTIONS[@]}"; do
	cleanup_old_image $app
done


### Run all containers (unit tests to be added)
echo "Starting all Docker containers..."
docker-compose up --force-recreate &
sleep 5 && echo "5"
sleep 5 && echo "10"
sleep 5 && echo "15"
sleep 5 && echo "20"
sleep 5 && echo "25"
sleep 5 && echo "30"
echo "Stopping all Docker containers..."
docker-compose down



### Push all images to Docker Private Registry
for app in "${DEPLOY_THESE_APPS[@]}"; do
	push_to_registry $app
done


### Deploy to AWS
docker pull cvast/cvast-arches-deploy
for app in "${DEPLOY_THESE_APPS[@]}"; do
	deploy_image $app
done
