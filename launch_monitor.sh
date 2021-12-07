#!/bin/sh
#
# This script launch the scale in monitor script.
#
echo " ---> using ENV_CONTROLLER_USERNAME = ${ENV_CONTROLLER_USERNAME}"
echo " ---> using ENV_CONTROLLER_PASSWORD = ${ENV_CONTROLLER_PASSWORD}"
echo " ---> using ENV_CONTROLLER_LOCATION = ${ENV_CONTROLLER_LOCATION}"
echo " ---> using ENV_CONTROLLER_INSTANCE_NAME = ${ENV_CONTROLLER_INSTANCE_NAME}"
echo " ---> using ENV_CONTROLLER_API_URL = ${ENV_CONTROLLER_API_URL}"

COMMAND="env ENV_CONTROLLER_USERNAME=${ENV_CONTROLLER_USERNAME} ENV_CONTROLLER_PASSWORD=${ENV_CONTROLLER_PASSWORD} ENV_CONTROLLER_LOCATION=${ENV_CONTROLLER_LOCATION} ENV_CONTROLLER_INSTANCE_NAME=${ENV_CONTROLLER_INSTANCE_NAME} ENV_CONTROLLER_API_URL=${ENV_CONTROLLER_API_URL} bash ./scale_in_monitor.sh"
su root -c "${COMMAND} > /var/log/bootstrap/scale_in_monitor.log 2>&1 &"
