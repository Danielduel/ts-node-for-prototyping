source secret.env

# To make sure that remote terminal will understand our
# "special" keypresses like backspace or tab
# let's change terminal "protocol(?)" to something very old
# I don't know if it has some security drawbacks
TERM=vt100

SSH_CMD_BASE="ssh -i $DEPLOYMENT_KEY_PATH $DEPLOYMENT_USER@$DEPLOYMENT_HOST" 

case $1 in
  journal) $SSH_CMD_BASE "journalctl -u $APP_NAME.service";;
  "") $SSH_CMD_BASE;;
esac

