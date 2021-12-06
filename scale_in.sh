#!/bin/sh
#
# This script waits for NGINX Controller Agent to stop then unregisters instance from NGINX Controller.
#

handle_term()
{
    echo "received TERM signal"
    echo "stopping bd-socket-plugin"
    bd_socket_pid=$(pidof bd-socket-plugin)
    kill -TERM "${bd_socket_pid}" 2>/dev/null
    echo "stopping bd-agent"
    bd_agent_pid=$(pidof perl)
    kill -TERM "${bd_agent_pid}" 2>/dev/null
    echo "stopping controller-agent ..."
    agent_pid=$(pidof nginx-controller-agent)
    kill -TERM "${agent_pid}" 2>/dev/null
    echo "stopping nginx ..."
    nginx_pid=$(pidof "nginx: master process nginx -g daemon off;")
    kill -TERM "${nginx_pid}" 2>/dev/null
}

trap 'handle_term' TERM

wait_term()
{
    echo "waiting for nginx Controller agent to stop..."
    agent_pid=$(pidof nginx-controller-agent)
    tail --pid="${agent_pid}" -f /dev/null
    trap - TERM
    kill -QUIT "${nginx_pid}" 2>/dev/null
    echo "waiting for nginx to stop..."
    nginx_pid=$(pidof "nginx: master process nginx -g daemon off;")
    tail --pid="${nginx_pid}" -f /dev/null
    echo " UNREGISTER instance from Controller"
    sh remove.sh
    echo " UNREGISTER done"
}

wait_term

echo "controller-agent process has stopped, exiting."

