#!/bin/sh
#
# This script waits for NGINX Controller Agent to stop then unregisters instance from NGINX Controller.
#

agent_pid=$(pidof nginx-controller-agent)

wait_term()
{
    tail --pid="${agent_pid}" -f /dev/null
    trap - TERM
    echo " UNREGISTER instance from Controller"
    sh remove.sh
    echo " UNREGISTER done"
}

wait_term

echo "controller-agent process has stopped, exiting."

