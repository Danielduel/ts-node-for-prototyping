# Edit template variables here or
# load them from envs
APP_NAME="test"
APP_NAME_CAPITALIZED=${APP_NAME^}

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

# Helpers to make debug output cleaner
NO_FORMAT="\033[0m"
F_BOLD="\033[1m"
C_AQUA="\033[48;5;14m"
C_GREY0="\033[38;5;16m"
C_WHEAT1="\033[48;5;229m"

# Load systemd template into variable
# Then use sed to replace template content in memory
# Then output debug
systemdService=$(cat ./systemd.service.template)
systemdService=$(sed "s/\${app-name}/$APP_NAME/g" <<< $systemdService)
echo -e "${F_BOLD}${C_GREY0}${C_AQUA}Rendered systemd service file:\n ${NO_FORMAT}"
echo -e "$systemdService" | while read line; do echo -e "${F_BOLD}${C_GREY0}${C_AQUA} ${NO_FORMAT} $line"; done
echo -e "${F_BOLD}${C_GREY0}${C_AQUA}.${NO_FORMAT}"
echo -e "${NO_FORMAT}"

# Check if dependencies are installed
ZIP_COMPAT="Zip 3.0 (July 5th 2008), by Info-ZIP"
if ! command -v zcat &> /dev/null
then
  echo "zcat could not be found, please install zcat command compatible with ${ZIP_COMPAT}"
  exit
fi
if ! command -v zip &> /dev/null
then
  echo "zip could not be found, please install zip command compatible with ${ZIP_COMPAT}"
  exit
fi

# Creating a zip package with files needed for deployment
rm -rf ./.deployment
mkdir -p ./.deployment
echo "$systemdService" >> ./.deployment/${APP_NAME}.service
zip -rq ./.deployment/.deploy.zip ${DEPLOYMENT_CONTENT} ./.deployment/${APP_NAME}.service

# Displaying data about deployment zip
echo -e "${F_BOLD}${C_GREY0}${C_WHEAT1}Deployment archive listing:\n ${NO_FORMAT}"
zip -sf ./.deployment/.deploy.zip | while read line; do echo -e "${F_BOLD}${C_GREY0}${C_WHEAT1} ${NO_FORMAT} $line"; done
echo -e "${F_BOLD}${C_GREY0}${C_WHEAT1}.${NO_FORMAT}"
echo -e "${NO_FORMAT}"

# TODO: provision small ec2 instance and:
# 1. scp deployment zip
# 2. shut down service
# 3. ssh commands to resetup app
# 4. put service back online

