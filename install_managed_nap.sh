# ------------------------------------- UPGRADE OS + INSTALL packages ------------------------------------- #
# UPGRADE OS #
echo '*********************** UPGRADE OS ***********************'
yum -y update --exclude=WALinuxAgent && yum -y upgrade --exclude=WALinuxAgent

# INSTALL required packages #
echo '*********************** INSTALL required packages ***********************'
yum -y install epel-release
yum -y install wget ca-certificates curl sudo vim procps gnupg binutils net-tools git jq policycoreutils policycoreutils-python setools setools-console setroubleshoot


# ------------------------------------- GET NGINX+ license from Controller ------------------------------------- #
# Controller - get auth token for API access #
echo '*********************** get Controller auth token ***********************'
curl -sk -c cookie.txt -X POST --url "https://${EXTRA_NGINX_CONTROLLER_IP}/api/v1/platform/login" -H 'Content-Type: application/json' --data '{"credentials": {"type": "BASIC","username": "'"${EXTRA_NGINX_CONTROLLER_USERNAME}"'","password": "'"${EXTRA_NGINX_CONTROLLER_PASSWORD}"'"}}'

# Controller - Get API key for agent registration #
echo '***********************  get Controller API key ***********************'
export API_KEY=$(curl -X GET -b cookie.txt -sk -H 'Content-Type: application/json' "https://${EXTRA_NGINX_CONTROLLER_IP}/api/v1/platform/global" | jq .currentStatus.agentSettings.apiKey)
echo "${API_KEY}"

# Controller - get license keys #
echo '*********************** get Controller license keys ***********************'
LICENSE_PRIVATE_KEY=$(curl -X GET -b cookie.txt -sk -H 'Content-Type: application/json' "https://${EXTRA_NGINX_CONTROLLER_IP}/api/v1/platform/licenses/nginx-plus-licenses/controller-provided" | jq .currentStatus.privateKey)
echo "${LICENSE_PRIVATE_KEY}"
LICENSE_CERTIFICATE=$(curl -X GET -b cookie.txt -sk -H 'Content-Type: application/json' "https://${EXTRA_NGINX_CONTROLLER_IP}/api/v1/platform/licenses/nginx-plus-licenses/controller-provided" | jq .currentStatus.certKey)
echo "${LICENSE_CERTIFICATE}"

# COPY license #
echo '*********************** COPY license ***********************'
mkdir -p /etc/ssl/nginx
LICENSE_PRIVATE_KEY_1="${LICENSE_PRIVATE_KEY//\"/}"
echo "${LICENSE_PRIVATE_KEY_1}" | awk '{gsub(/\\r\\n/,"\n")}1' $1 > /etc/ssl/nginx/nginx-repo.key
LICENSE_CERTIFICATE_1="${LICENSE_CERTIFICATE//\"/}"
echo "${LICENSE_CERTIFICATE_1} "| awk '{gsub(/\\n/,"\n")}1' $1 > /etc/ssl/nginx/nginx-repo.crt


# ------------------------------------- INSTALL NGINX+ App Protect ------------------------------------- #
# COPY nginx file from repo #
echo '*********************** COPY file from repo ***********************'
mkdir -p /etc/nginx/conf.d/
cp ./nginx-plus-api.conf /etc/nginx/conf.d/
cp ./custom_log_format.json /etc/nginx/
cp ./centos.repo /etc/yum.repos.d/

# FETCH package repo #
echo '*********************** FETCH package repo ***********************'
export NGINX_GPGKEY=573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62
found=''
for server in \
  ha.pool.sks-keyservers.net \
  hkp://keyserver.ubuntu.com:80 \
  hkp://p80.pool.sks-keyservers.net:80 \
  pgp.mit.edu \
; do \
  echo "Fetching GPG key $NGINX_GPGKEY from $server"
  gpg --keyserver "$server" --recv-keys "0x${NGINX_GPGKEY}" && found=yes && break
done
test -z "$found" && echo >&2 "error: failed to fetch GPG key ${NGINX_GPGKEY}" && exit 1
wget -P /etc/yum.repos.d "https://cs.nginx.com/static/files/nginx-plus-7.4.repo"
wget -P /etc/yum.repos.d "https://cs.nginx.com/static/files/app-protect-7.repo"

# INSTALL NGINX Javascript module needed for APIM #
echo '*********************** INSTALL NGINX + NGINX Javascript module for APIM + brotli for compression ***********************'
yum -y update --exclude=WALinuxAgent && yum -y install "nginx-plus-${EXTRA_NGINX_PLUS_VERSION}*" "nginx-plus-module-njs-${EXTRA_NGINX_PLUS_VERSION}*" "nginx-plus-module-brotli"
systemctl enable nginx.service

# INSTALL NGINX App Protect #
echo '*********************** INSTALL NGINX App Protect ***********************'
wget -P /etc/yum.repos.d https://cs.nginx.com/static/files/dependencies.repo
yum -y install app-protect-26+3.890.0-1.el7.ngx app-protect-attack-signatures
sed -i "6 a load_module modules/ngx_http_app_protect_module.so;" /etc/nginx/nginx.conf

# UPDATE App Protect Attack Signatures + Threat Campaigns #
echo '*********************** UPDATE App Protect Attack Signatures + Threat Campaigns ***********************'
wget -P /etc/yum.repos.d https://cs.nginx.com/static/files/app-protect-7.repo
yum -y install app-protect-attack-signatures app-protect-threat-campaigns

# CLEAN #
echo '*********************** CLEAN ***********************'
gpg --list-keys
rm -f /etc/yum.repos.d/nginx-plus-7.4.repo \
&& gpg --batch --delete-keys ${NGINX_GPGKEY}


# ------------------------------------- INSTALL NGINX Controller agent ------------------------------------- #
# Controller - GET agent #
#echo '*********************** get Controller agent ***********************'
curl -k -sS -L https://${EXTRA_NGINX_CONTROLLER_IP}/install/controller-agent > install.sh
sed -i 's/^assume_yes=""/assume_yes="-y"/' install.sh
sed -i 's,-n "${NGINX_GPGKEY}",true,' install.sh

# Controller - SET agent specification #
echo '*********************** set Controller agent specification ***********************'
# Variables
### source: https://github.com/nginxinc/docker-nginx-controller/blob/master/centos/nap/entrypoint.sh
echo " ---> using api_key = ${API_KEY}"

HOSTNAME="$(hostname -f  | tr '[:upper:]' '[:lower:]')"
export instance_name=${HOSTNAME%\.*\.*\.*\.*\.*}
echo " ---> using instance_name = ${instance_name}"

export location=${EXTRA_LOCATION}
echo " ---> using location = ${location}"

export instance_group=${EXTRA_VMSS_NAME}
echo " ---> using instance group = ${instance_group}"

export STORE_UUID='True'
echo " ---> using STORE_UUID = ${STORE_UUID}"

# Controller - RUN agent #
echo '*********************** run NGINX ***********************'
systemctl start nginx
echo '*********************** run Controller agent ***********************'
bash ./install.sh -y --insecure --location-name "${location}" --instance-name "${instance_name}" --instance-group "${instance_group}"
echo '*********************** run App Protect agent ***********************'
/bin/su -s /bin/bash -c '/opt/app_protect/bin/bd_agent &' nginx
