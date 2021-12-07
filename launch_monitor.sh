#!/bin/sh
#
# This script launch the scale in monitor script.
#
COMMAND="env ENV_CONTROLLER_USERNAME=${ENV_CONTROLLER_USERNAME} ENV_CONTROLLER_PASSWORD=${ENV_CONTROLLER_PASSWORD} ENV_CONTROLLER_LOCATION=${ENV_CONTROLLER_LOCATION} ENV_CONTROLLER_INSTANCE_NAME=${ENV_CONTROLLER_INSTANCE_NAME} ENV_CONTROLLER_API_URL=${ENV_CONTROLLER_API_URL} bash ./scale_in_monitor.sh"

echo "${COMMAND}"

agent_pid=$(pidof nginx-controller-agent)
echo "launch -- agent_pid: ${agent_pid}"

su root -c "nohup ${COMMAND} > /var/log/bootstrap/scale_in_monitor.log 2>&1 &"
