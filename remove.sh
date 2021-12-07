# Authenticate to controller with credentials in order to get the Session Token
echo "ENV_CONTROLLER_USERNAME 2: ${ENV_CONTROLLER_USERNAME}"
echo "ENV_CONTROLLER_PASSWORD 2: ${ENV_CONTROLLER_PASSWORD}"
curl --connect-timeout 30 --retry 10 --retry-delay 5 -sk -c cookie.txt -X POST --url 'https://'${ENV_CONTROLLER_API_URL}'/api/v1/platform/login' --header 'Content-Type: application/json' --data '{"credentials": {"type": "BASIC","username": "'"${ENV_CONTROLLER_USERNAME}"'","password": "'"${ENV_CONTROLLER_PASSWORD}"'"}}'

# Remove the instance from infrastructure
curl --connect-timeout 30 --retry 10 --retry-delay 5  -sk -b cookie.txt -c cookie.txt  --header 'Content-Type: application/json' -X DELETE --url 'https://'${ENV_CONTROLLER_API_URL}'/api/v1/infrastructure/locations/'${ENV_CONTROLLER_LOCATION}'/instances/'${ENV_CONTROLLER_INSTANCE_NAME}
