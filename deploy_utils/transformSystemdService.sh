source ./secret.env
source ./deploy_utils/debug_utils.sh

# Load systemd template into variable
# Then use sed to replace template content in memory
function transformSystemdService {
  systemdService=$(cat ./systemd.service.template)
  systemdService=$(sed "s~\${app-name}~$APP_NAME~g" <<< $systemdService)
  systemdService=$(sed "s~\${node-version}~$NODE_VERSION~g" <<< $systemdService)
  systemdService=$(sed "s~\${exec-start}~$EXEC_START~g" <<< $systemdService)

  echo -e "$systemdService"
}

function debugSystemdService {
  systemdService=$1
 
  debug_bold_aqua "Rendered systemd service file:\n "
  debug_bold_aqua " "
  debug_bold_aqua_prepend "$systemdService"
  debug_bold_aqua "."
  debug_reset
}

