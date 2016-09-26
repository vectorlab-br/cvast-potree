#!/bin/bash

set -e 

HELP_TEXT="
Arguments:  
runserver: Runs Potree in Nginx. Further expected commands: -i or --access_key_id, -k or --secret_access_key.
convert: Converts provided file into Potree format. Further optional commands: -f or --file: input pointcloud file. -n --name: output Potree page name.
-i or --access_key_id: The AWS Access Key ID of your AWS account  
-k or --secret_access_key: The AWS Secret Access Key of your AWS account  
-h or --help: Display help text
"

AWS_DEFAULT_REGION=us-east-1


display_help() {
	echo ${HELP_TEXT}
}


runserver(){
 	aws s3 sync s3://test-cvast-potree /var/www/potree/resources/pointclouds
	exec service nginx start
}

convert_file(){
	PotreeConverter ${POINTCLOUD_INPUT_FOLDER}/${INPUT_FILE} -o ${POTREE_WWW} -p ${OUTPUT_NAME}
}

 # Script parameters 

# Use -gt 1 to consume two arguments per pass in the loop (e.g. each
# argument has a corresponding value to go with it).
# Use -gt 0 to consume one or more arguments per pass in the loop (e.g.
# some arguments don't have a corresponding value to go with it, such as --help ).

while [[ $# -gt 0 ]]
do
	key="$1"

	case ${key} in
		convert)
			echo "Converting file into Potree format"
			CONVERT_FILE=True
			# No further option/value expected, this is a single command, so no 'shift'
		;;
		runserver)
			RUN_SERVER=True
			# No further option/value expected, this is a single command, so no 'shift'
		;;
		-f|--file)
			INPUT_FILE="$2"
			shift; # next argument
		;;
		-n|--name)
			OUTPUT_NAME="$2"
			shift # next argument
		;;
		bash)
			bash -c "${@:2}"
			exit 0
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


if [[ -z ${AWS_ACCESS_KEY_ID} ]]; then
	echo "Environment variable AWS_ACCESS_KEY_ID not set, exiting..."
	exit 1
fi

if [[ -z ${AWS_SECRET_ACCESS_KEY} ]]; then
	echo "Environment variable AWS_SECRET_ACCESS_KEY not set, exiting..."
	exit 1
fi
	
	
if [[ ${RUN_SERVER} == True ]]; then
	runserver
elif [[ ${CONVERT_FILE} == True ]]; then
	convert_file
fi