#!/bin/sh
#
# This script launch the scale in monitor script.
#
mkdir -p /var/log/bootstrap
COMMAND="env ENV_CONTROLLER_USERNAME=${ENV_CONTROLLER_USERNAME} ENV_CONTROLLER_PASSWORD=${ENV_CONTROLLER_PASSWORD} ENV_CONTROLLER_LOCATION=${ENV_CONTROLLER_LOCATION} ENV_CONTROLLER_INSTANCE_NAME=${ENV_CONTROLLER_INSTANCE_NAME} ENV_CONTROLLER_API_URL=${ENV_CONTROLLER_API_URL} bash ./scale_in_monitor.sh"
su root -c "nohup ${COMMAND} > /var/log/bootstrap/scale_in_monitor.log 2>&1 &"

