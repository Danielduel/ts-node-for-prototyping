# Helpers to make debug output cleaner

NO_FORMAT="\033[0m"
F_BOLD="\033[1m"
C_AQUA="\033[48;5;14m"
C_GREY0="\033[38;5;16m"
C_WHEAT1="\033[48;5;229m"

function debug_reset {
  echo -e "${NO_FORMAT}"
}

function debug_bold_aqua {
  colored_string=$1
  noformat_suffix=$2
  
  echo -e "${F_BOLD}${C_GREY0}${C_AQUA}${colored_string}${NO_FORMAT}${noformat_suffix}"
}

function debug_bold_aqua_prepend {
  multilineString=$1

  echo -e "$multilineString" | while read line; do debug_bold_aqua " " "  $line"; done
}

