source secret.env
source ./deploy_utils/transformSystemdService.sh

# TODO: exclude repeating parts to separate file, make this
# file easier to edit

# List of files that have to be deployed
read -r -d '' DEPLOYMENT_CONTENT << EOM
  package.json
  package-lock.json
  tsconfig.json
  src
EOM

# List of commands to execute in project directory after deployment
# note that it has to install packages if you prefer to not push them over network
# but don't run app itself using that - leave it to be handled by the service
read -r -d '' DEPLOYMENT_CMD << EOM
  npm i --frozen-lockfile
EOM

# Install dependencies
# TODO: Cut that out and make template for template
read -r -d '' DEPLOYMENT_DEPENDENCIES << EOM
  if ! command -v npm &> /dev/null
  then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.34.0/install.sh | bash
    . ~/.nvm/nvm.sh
    nvm install 16
  fi
EOM


# Check if dependencies are installed
ZIP_COMPAT="Zip 3.0 (July 5th 2008), by Info-ZIP"
if ! command -v zip &> /dev/null
then
  echo "zip could not be found, please install zip command compatible with ${ZIP_COMPAT}"
  exit
fi

systemdService=$(transformSystemdService) 
echo -e "..."
debugSystemdService "$systemdService"

# Creating a zip package with files needed for deployment
DEPLOYMENT_ZIP_LOCAL="./.deployment/.deploy.zip"
rm -rf ./.deployment
mkdir -p ./.deployment
echo "$systemdService" >> ./.deployment/${APP_NAME}.service
zip -rq ${DEPLOYMENT_ZIP_LOCAL} ${DEPLOYMENT_CONTENT} ./.deployment/${APP_NAME}.service

# Displaying data about deployment zip
echo -e "${F_BOLD}${C_GREY0}${C_WHEAT1}Deployment archive listing:\n ${NO_FORMAT}"
zip -sf ${DEPLOYMENT_ZIP_LOCAL} | while read line; do echo -e "${F_BOLD}${C_GREY0}${C_WHEAT1} ${NO_FORMAT} $line"; done
echo -e "${F_BOLD}${C_GREY0}${C_WHEAT1}.${NO_FORMAT}"
echo -e "${NO_FORMAT}"

# UID to not run into an issue with multiple deploys
UNIQUE_ID=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

# Ignoring fingerprints is generally a security risk, but I don't care here
# If you care - please do a PR to the repository
read -r -d '' SCP_ARGS << EOM
  -o UserKnownHostsFile=/dev/null
  -o StrictHostKeyChecking=no
  -i ${DEPLOYMENT_KEY_PATH}
EOM

read -r -d '' SSH_ARGS << EOM
  ${SCP_ARGS}
  ${DEPLOYMENT_USER}@${DEPLOYMENT_HOST} 
EOM

read -r -d '' PREPARE_DEPLOYMENT << EOM
  sudo mkdir -p /tmp/${APP_NAME}/${UNIQUE_ID}
  sudo mkdir -p /opt/deployedapps/${APP_NAME}
  sudo chown -R ${DEPLOYMENT_USER} /tmp/${APP_NAME}/${UNIQUE_ID}
  sudo chown -R ${DEPLOYMENT_USER} /opt/deployedapps/${APP_NAME}
EOM
ssh ${SSH_ARGS} "${PREPARE_DEPLOYMENT}"
scp ${SCP_ARGS} ${DEPLOYMENT_ZIP_LOCAL} ${DEPLOYMENT_USER}@${DEPLOYMENT_HOST}:/tmp/${APP_NAME}/${UNIQUE_ID}/deployment.zip

# TODO: Redirect "verbose" output to some log file and display
# user-friendly messages as the output while running this script
read -r -d '' EXTRACT_CMD << EOM
  cd /tmp/${APP_NAME}/${UNIQUE_ID}
  
  # Install unzip (assuming ec2)
  if ! command -v unzip &> /dev/null
  then
    sudo apt-get install unzip
  fi
  
  # Unzip deployment
  # mkdir unzip_dir - not needed
  sudo unzip deployment.zip -d unzip_dir

  # Stop service if running and replace new service file
  sudo systemctl stop ${APP_NAME}
  sudo systemctl disable ${APP_NAME}
  sudo rm /etc/systemd/system/${APP_NAME}.service
  sudo mv ./unzip_dir/.deployment/${APP_NAME}.service /etc/systemd/system/${APP_NAME}.service
  
  # Replace deployment
  sudo rm -rf /opt/deployedapps/${APP_NAME}
  sudo mv unzip_dir /opt/deployedapps/${APP_NAME}
  sudo chown -R ${DEPLOYMENT_USER} /opt/deployedapps/${APP_NAME}

  # Go into directory and execute install script
  cd /opt/deployedapps/${APP_NAME}
  ${DEPLOYMENT_DEPENDENCIES}
  ${DEPLOYMENT_CMD}

  # Enable new service
  sudo systemctl enable ${APP_NAME}.service
  sudo systemctl start ${APP_NAME}.service

  # Reroute ports
  sudo iptables -t nat -F
  sudo iptables -t nat -X
  sudo iptables -t nat -A PREROUTING -p tcp --dport 443 -j REDIRECT --to-port 3000
  sudo iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 3001

  # Clean the tmp folder
  sudo rm -rf /tmp/${APP_NAME}/${UNIQUE_ID}
EOM
ssh ${SSH_ARGS} "echo -e \"${EXTRACT_CMD}\" | sh"

# TODO: Listen for journalctl entries and try to curl/wget ${DEPLOYMENT_HOST}
# and notify user that app is ready under protocol://${DEPLOYMENT_HOST}/

